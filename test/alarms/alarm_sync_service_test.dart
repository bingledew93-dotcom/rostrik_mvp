import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/alarms/alarm_sync_service.dart';
import 'package:rostrik_mvp/alarms/pending_dismissal_guard.dart';

import 'fakes.dart';

void main() {
  late FakeAppAlarmRepository alarms;
  late FakeShiftRepository shifts;
  late FakeShiftCycleRepository cycles;
  late FakeAlarmSettingsRepository settings;
  late FakeAlarmScheduler scheduler;
  late InMemoryNotificationIdMap idMap;
  late FrozenClock clock;
  late AlarmSyncService service;

  setUp(() {
    alarms = FakeAppAlarmRepository();
    shifts = FakeShiftRepository();
    cycles = FakeShiftCycleRepository();
    settings = FakeAlarmSettingsRepository(); // defaults to 60-min lead time
    scheduler = FakeAlarmScheduler();
    idMap = InMemoryNotificationIdMap();
    clock = FrozenClock(DateTime(2026, 6, 1, 5, 0));
    service = AlarmSyncService(
      alarms: alarms,
      shifts: shifts,
      cycles: cycles,
      alarmSettings: settings,
      scheduler: scheduler,
      idMap: idMap,
      clock: clock,
    );
  });

  tearDown(() async {
    await service.stop();
    await alarms.dispose();
    await shifts.dispose();
    await cycles.dispose();
    await settings.dispose();
  });

  /// Sets the global lead time the service reads each sync.
  Future<void> setGlobalLead(int minutes) =>
      settings.write(AlarmSettings(leadTime: Duration(minutes: minutes)));

  AppAlarm oneTime({
    String id = 'one',
    int minutesOfDay = 7 * 60,
    String label = 'One-time',
    bool enabled = true,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: minutesOfDay,
        label: label,
        repeatType: AppAlarmRepeatType.oneTime,
        enabled: enabled,
      );

  /// A follows-rotation alarm. `relativeOffsetMinutes == null` (the default)
  /// means "use the global lead time"; a value is a per-alarm override.
  /// `minutesOfDay` is irrelevant for this repeat type but the model still
  /// carries it, so it's fixed here.
  AppAlarm followsRotation({
    String id = 'fr',
    String label = 'Wake Up',
    ShiftType? linkedShiftType = ShiftType.day,
    bool enabled = true,
    int? relativeOffsetMinutes,
    bool isCriticalShift = false,
    String soundKey = 'classic',
    String? customRingtoneUri,
    bool isExactTime = false,
    int? exactTimeMinutes,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: 6 * 60,
        label: label,
        repeatType: AppAlarmRepeatType.followsRotation,
        enabled: enabled,
        linkedShiftType: linkedShiftType,
        relativeOffsetMinutes: relativeOffsetMinutes,
        isCriticalShift: isCriticalShift,
        soundKey: soundKey,
        customRingtoneUri: customRingtoneUri,
        ringtoneSource: customRingtoneUri == null
            ? RingtoneSource.classic
            : RingtoneSource.vault,
        isExactTime: isExactTime,
        exactTimeMinutes: exactTimeMinutes,
      );

  Shift mkShift({
    required String id,
    required DateTime date,
    required ShiftType type,
    int startMin = 7 * 60,
    int endMin = 15 * 60,
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: startMin,
        endMinutes: endMin,
      );

  /// A weekly alarm. `weekdaysBitmask` packs ISO weekdays (bit 0 = Monday).
  /// `now` in setUp is Monday 2026-06-01 05:00, so a Monday-only weekly fires
  /// today first.
  AppAlarm weekly({
    String id = 'wk',
    int minutesOfDay = 6 * 60,
    int weekdaysBitmask = 1, // Monday
    bool enabled = true,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: minutesOfDay,
        label: 'Weekly',
        repeatType: AppAlarmRepeatType.weekly,
        enabled: enabled,
        weekdaysBitmask: weekdaysBitmask,
      );

  group('one-time alarms', () {
    test('today if minutesOfDay is still after now', () async {
      await alarms.upsert(oneTime(minutesOfDay: 7 * 60));
      await service.syncAlarms();

      expect(scheduler.scheduled.values, hasLength(1));
      expect(scheduler.scheduled.values.single.fireAt,
          DateTime(2026, 6, 1, 7, 0));
    });

    test('tomorrow if minutesOfDay has already passed today', () async {
      await alarms.upsert(oneTime(minutesOfDay: 4 * 60 + 30));
      await service.syncAlarms();
      expect(scheduler.scheduled.values.single.fireAt,
          DateTime(2026, 6, 2, 4, 30));
    });

    test('disabled one-time alarm produces no OS schedule', () async {
      await alarms.upsert(oneTime(enabled: false));
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('follows-rotation alarms (global lead time)', () {
    test('one OS alarm per matching shift, fired at shiftStart - leadTime',
        () async {
      // Global lead is 60 min; matching Day shifts start at 07:00, so each
      // fires at 06:00. The Night shift is skipped.
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await shifts.upsert(
        mkShift(
          id: 'n1',
          date: DateTime(2026, 6, 3),
          type: ShiftType.night,
          startMin: 22 * 60,
          endMin: 6 * 60,
        ),
      );
      await shifts.upsert(
        mkShift(id: 'd2', date: DateTime(2026, 6, 4), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();

      final fireAts = scheduler.scheduled.values.map((e) => e.fireAt).toSet();
      expect(fireAts, hasLength(2));
      expect(fireAts.contains(DateTime(2026, 6, 2, 6, 0)), isTrue);
      expect(fireAts.contains(DateTime(2026, 6, 4, 6, 0)), isTrue);
      expect(fireAts.contains(DateTime(2026, 6, 3, 6, 0)), isFalse);
    });

    test('a custom global lead time is honoured (orphaned-setting fix)',
        () async {
      // The bug this engine fix closes: the global lead time must actually
      // drive scheduling. 75 min before an 07:00 shift = 05:45.
      await setGlobalLead(75);
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();
      expect(scheduler.scheduled.values.single.fireAt,
          DateTime(2026, 6, 2, 5, 45));
    });

    test('alarm with no linkedShiftType is skipped', () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation(linkedShiftType: null));
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty);
    });

    test('past fireAt on the SAME day as now is filtered out', () async {
      // Now is 05:00 on 2026-06-01; a Day shift today at 07:00 with a 150-min
      // override fires at 04:30 — already past, skip.
      await shifts.upsert(
        mkShift(id: 'today', date: DateTime(2026, 6, 1), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation(relativeOffsetMinutes: 150));
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty);
    });

    test('shifts outside the 14-day horizon are not picked up', () async {
      await shifts.upsert(
        mkShift(id: 'far', date: DateTime(2027, 8, 1), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('follows-rotation alarms (per-alarm override)', () {
    test('an explicit offset overrides the global lead time', () async {
      // Global is 75, but this alarm overrides with 30 → 06:30, not 05:45.
      await setGlobalLead(75);
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation(relativeOffsetMinutes: 30));
      await service.syncAlarms();
      expect(scheduler.scheduled.values.single.fireAt,
          DateTime(2026, 6, 2, 6, 30));
    });

    test('a 45-min offset before an 08:00 Night shift fires at 07:15',
        () async {
      await shifts.upsert(
        mkShift(
          id: 'n1',
          date: DateTime(2026, 6, 3),
          type: ShiftType.night,
          startMin: 8 * 60,
          endMin: 16 * 60,
        ),
      );
      await alarms.upsert(followsRotation(
        linkedShiftType: ShiftType.night,
        relativeOffsetMinutes: 45,
      ));
      await service.syncAlarms();
      expect(scheduler.scheduled.values.single.fireAt,
          DateTime(2026, 6, 3, 7, 15));
    });

    test('an offset that crosses midnight lands on the previous calendar day',
        () async {
      // Day shift starts at 04:00; a 6-hour lead fires at 22:00 the previous
      // evening. Calendar-math subtraction handles the day rollover (and is
      // DST-safe, unlike Duration subtraction).
      await shifts.upsert(
        mkShift(
          id: 'd1',
          date: DateTime(2026, 6, 5),
          type: ShiftType.day,
          startMin: 4 * 60,
          endMin: 12 * 60,
        ),
      );
      await alarms.upsert(followsRotation(relativeOffsetMinutes: 6 * 60));
      await service.syncAlarms();
      expect(scheduler.scheduled.values.single.fireAt,
          DateTime(2026, 6, 4, 22, 0));
    });
  });

  group('follows-rotation alarms (exact time)', () {
    test('fires at the exact clock on the shift date, ignoring the lead',
        () async {
      // Day shift 2 Jun starts 07:00. An exact-time alarm at 04:15 must fire at
      // 04:15 on that date — NOT 06:00 (07:00 − the 60-min global lead).
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(
        followsRotation(isExactTime: true, exactTimeMinutes: 4 * 60 + 15),
      );
      await service.syncAlarms();
      expect(scheduler.scheduled.values.single.fireAt,
          DateTime(2026, 6, 2, 4, 15));
    });

    test('exact time wins even when a per-alarm offset is also present',
        () async {
      // A malformed-but-possible record carrying BOTH a 30-min offset and exact
      // mode: exact-time takes precedence, so it fires at 04:15, not 06:30.
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation(
        isExactTime: true,
        exactTimeMinutes: 4 * 60 + 15,
        relativeOffsetMinutes: 30,
      ));
      await service.syncAlarms();
      expect(scheduler.scheduled.values.single.fireAt,
          DateTime(2026, 6, 2, 4, 15));
    });

    test('one OS alarm per matching shift, each at the same exact clock',
        () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await shifts.upsert(
        mkShift(id: 'd2', date: DateTime(2026, 6, 5), type: ShiftType.day),
      );
      await alarms.upsert(
        followsRotation(isExactTime: true, exactTimeMinutes: 5 * 60),
      );
      await service.syncAlarms();
      final fireAts = scheduler.scheduled.values.map((e) => e.fireAt).toSet();
      expect(fireAts, {
        DateTime(2026, 6, 2, 5, 0),
        DateTime(2026, 6, 5, 5, 0),
      });
    });

    test('an exact time already past on today is filtered out', () async {
      // Now is 05:00 on 1 Jun; a Day shift today with an exact time of 04:00 is
      // already past, so nothing is scheduled for it.
      await shifts.upsert(
        mkShift(id: 'today', date: DateTime(2026, 6, 1), type: ShiftType.day),
      );
      await alarms.upsert(
        followsRotation(isExactTime: true, exactTimeMinutes: 4 * 60),
      );
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('shift-level state filtering', () {
    test('isMuted shift produces no OS schedule', () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day)
            .copyWith(isMuted: true),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty,
          reason: 'muted shifts must never schedule alarms');
    });

    test('isAcknowledged shift produces no OS schedule', () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day)
            .copyWith(isAcknowledged: true),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty,
          reason: 'acknowledged shifts must never re-schedule alarms');
    });

    test('snoozed POST-fire alarm is pinned to snoozedUntil', () async {
      // Day shift today at 07:00, global lead 60 → normal fireAt 06:00. "Now"
      // is 06:05 (alarm already fired); the user snoozed to 06:09. Reconcile
      // must converge to the snooze instant, not the now-past 06:00.
      clock.set(DateTime(2026, 6, 1, 6, 5));
      await shifts.upsert(
        mkShift(id: 'today', date: DateTime(2026, 6, 1), type: ShiftType.day)
            .copyWith(snoozedUntil: DateTime(2026, 6, 1, 6, 9)),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();
      expect(scheduler.scheduled.values.single.fireAt,
          DateTime(2026, 6, 1, 6, 9),
          reason: 'post-fire alarm with active snooze must pin to snoozedUntil');
    });

    // ── The two-snooze invariant ────────────────────────────────────────────
    //
    // Under AlarmKit a snooze is served TWICE over: AlarmKit re-alerts by
    // itself after `CountdownDuration.postAlert`, and Dart also re-arms from
    // the snooze ledger. Verified on device 2026-08-27 — both happened, and the
    // user got ONE alarm.
    //
    // That is not luck, but it is fragile, and it rests on two things this
    // group pins. Both mechanisms must target the SAME INSTANT, and Dart must
    // re-arm under the SAME ID: AlarmKit refuses to schedule over a live id, so
    // `AlarmKitBackend.schedule` cancels first — which is precisely what
    // discards AlarmKit's pending countdown and collapses the two into one. Let
    // Dart allocate a fresh id and the cancel would miss, leaving AlarmKit's
    // countdown armed alongside the new alarm: two alarms, minutes apart, for
    // one snooze.
    test('a snoozed alarm re-arms under the SAME id, so the two snooze '
        'mechanisms collapse into one alarm', () async {
      clock.set(DateTime(2026, 6, 1, 5, 30));
      await shifts.upsert(
        mkShift(id: 'today', date: DateTime(2026, 6, 1), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();

      final idBefore = scheduler.scheduled.keys.single;
      expect(scheduler.scheduled[idBefore]!.fireAt, DateTime(2026, 6, 1, 6, 0));

      // The alarm fires and the user snoozes to 06:09.
      clock.set(DateTime(2026, 6, 1, 6, 5));
      await shifts.upsert(
        mkShift(id: 'today', date: DateTime(2026, 6, 1), type: ShiftType.day)
            .copyWith(snoozedUntil: DateTime(2026, 6, 1, 6, 9)),
      );
      await service.syncAlarms();

      expect(scheduler.scheduled, hasLength(1),
          reason: 'a snooze must never leave two alarms armed');
      expect(scheduler.scheduled.keys.single, idBefore,
          reason: 'a re-armed snooze MUST reuse the id — a new one would leave '
              "AlarmKit's own countdown armed alongside it");
      expect(scheduler.scheduled[idBefore]!.fireAt, DateTime(2026, 6, 1, 6, 9),
          reason: 'both mechanisms must target the same instant');
    });

    test('snoozed PRE-fire sibling alarm keeps its original fireAt', () async {
      // Same shift, TWO alarms: wake-up uses the global lead (60 → 06:00) and
      // leave-for-work overrides with 30 (→ 06:30). "Now" is 06:05; wake-up
      // has fired and been snoozed (06:09). Leave-for-work has NOT fired — its
      // 06:30 must NOT be dragged forward.
      clock.set(DateTime(2026, 6, 1, 6, 5));
      await shifts.upsert(
        mkShift(id: 'today', date: DateTime(2026, 6, 1), type: ShiftType.day)
            .copyWith(snoozedUntil: DateTime(2026, 6, 1, 6, 9)),
      );
      await alarms.upsert(followsRotation(id: 'wake'));
      await alarms.upsert(
        followsRotation(id: 'leave', relativeOffsetMinutes: 30),
      );
      await service.syncAlarms();

      final fireAts = scheduler.scheduled.values.map((e) => e.fireAt).toSet();
      expect(fireAts, hasLength(2));
      expect(fireAts, contains(DateTime(2026, 6, 1, 6, 9)),
          reason: 'snoozed wake-up resurrected at snoozedUntil');
      expect(fireAts, contains(DateTime(2026, 6, 1, 6, 30)),
          reason: 'sibling leave-for-work keeps its own pre-fire schedule');
    });

    test('snoozedUntil in the past is ignored (no resurrection)', () async {
      clock.set(DateTime(2026, 6, 1, 6, 30));
      await shifts.upsert(
        mkShift(id: 'today', date: DateTime(2026, 6, 1), type: ShiftType.day)
            .copyWith(snoozedUntil: DateTime(2026, 6, 1, 6, 9)),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty);
    });
  });

  // Field report, 2026-08-30 (Samsung S25 FE): "I went to change the alarm,
  // but the sound is still playing the previous one... if I fully delete the
  // alarm and make a new one it will change."
  //
  // The reconcile gate compared only the FIRE TIME, so editing any other
  // property left the armed OS alarm untouched. Deleting and recreating worked
  // because a new rule gets a new notification id, which has no prior entry.
  //
  // These pin every property that reaches the OS. The gate now compares a
  // signature of all of them, so a property added to `scheduleAt` without being
  // added to the signature will fail here rather than silently becoming
  // uneditable.
  group('editing an armed alarm actually reaches the OS', () {
    Future<void> armDayAlarm(AppAlarm alarm) async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(alarm);
      await service.syncAlarms();
    }

    test('changing the tone re-arms with the new sound — the reported bug',
        () async {
      await armDayAlarm(followsRotation(soundKey: 'classic'));
      expect(scheduler.scheduled.values.single.soundKey, 'classic');

      scheduler.clearLog();
      await alarms.upsert(followsRotation(soundKey: 'siren'));
      await service.syncAlarms();

      expect(scheduler.callLog, isNotEmpty,
          reason: 'a tone change must re-issue the alarm');
      expect(scheduler.scheduled.values.single.soundKey, 'siren',
          reason: 'the OS must hold the tone the user chose, not the old one');
    });

    test('renaming the alarm re-arms with the new title', () async {
      await armDayAlarm(followsRotation(label: 'Wake Up'));
      final before = scheduler.scheduled.values.single.title;

      await alarms.upsert(followsRotation(label: 'Start of night shift'));
      await service.syncAlarms();

      expect(scheduler.scheduled.values.single.title, isNot(before));
    });

    test('toggling Critical shift re-arms — it changes dismiss mechanics',
        () async {
      await armDayAlarm(followsRotation(isCriticalShift: false));
      scheduler.clearLog();

      await alarms.upsert(followsRotation(isCriticalShift: true));
      await service.syncAlarms();

      expect(scheduler.callLog, isNotEmpty,
          reason: 'critical rides the payload, so the alarm must be replaced');
    });

    test('choosing a custom ringtone re-arms', () async {
      await armDayAlarm(followsRotation());
      scheduler.clearLog();

      await alarms.upsert(
        followsRotation(customRingtoneUri: 'content://media/42'),
      );
      await service.syncAlarms();

      expect(scheduler.callLog, isNotEmpty);
    });

    // Vibration is a GLOBAL setting, not a per-alarm one, and rides the same
    // payload — so switching it off has to reach alarms that are already armed.
    test('toggling global vibration re-arms already-armed alarms', () async {
      await armDayAlarm(followsRotation());
      scheduler.clearLog();

      await settings.write(const AlarmSettings(
        leadTime: Duration(minutes: 60),
        vibrationEnabled: false,
      ));
      await service.syncAlarms();

      expect(scheduler.callLog, isNotEmpty);
    });

    // The property the old gate existed to protect. Widening it must not turn
    // every reconcile into a re-arm storm — on a dense roster that is 50
    // platform-channel calls for nothing, which is what the fire-time check was
    // avoiding in the first place.
    test('an unchanged alarm still issues no calls', () async {
      await armDayAlarm(followsRotation());
      scheduler.clearLog();
      await service.syncAlarms();
      expect(scheduler.callLog, isEmpty);
    });
  });

  group('idempotency + cancel-orphans contract', () {
    test('running sync twice with identical input produces no extra calls',
        () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();
      scheduler.clearLog();
      await service.syncAlarms();
      expect(scheduler.callLog, isEmpty);
    });

    test('deleting an alarm cancels its pending OS notifications on next sync',
        () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await shifts.upsert(
        mkShift(id: 'd2', date: DateTime(2026, 6, 4), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();
      expect(scheduler.scheduled, hasLength(2));

      await alarms.delete('fr');
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty,
          reason: 'orphans must be cancelled when the source alarm is gone');
    });

    test('changing the per-alarm offset reschedules the same id', () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation(relativeOffsetMinutes: 60));
      await service.syncAlarms();
      final firstId = scheduler.scheduled.keys.single;
      expect(scheduler.scheduled[firstId]!.fireAt, DateTime(2026, 6, 2, 6, 0));

      // Same alarm id + same fire date → same composite id, new fireAt.
      await alarms.upsert(followsRotation(relativeOffsetMinutes: 90));
      await service.syncAlarms();
      expect(scheduler.scheduled, hasLength(1));
      expect(scheduler.scheduled[firstId]!.fireAt, DateTime(2026, 6, 2, 5, 30));
    });
  });

  group('critical-shift + sound payload', () {
    test(
        'payload is 6-field: code (3) + sound (4) + appAlarmId (5) + ringtone (6)',
        () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation(
        id: 'crit',
        isCriticalShift: true,
        soundKey: 'siren',
      ));
      await alarms.upsert(followsRotation(
        id: 'norm',
        isCriticalShift: false,
        soundKey: 'classic',
      ));
      await service.syncAlarms();

      final fields = scheduler.scheduled.values
          .map((e) => e.payload!.split('|'))
          .toList();
      expect(fields, hasLength(2));
      // Every payload is
      // <shiftId>|<id>|<code>|<soundKey>|<appAlarmId>|<ringtone>|<vibrate>.
      expect(fields.every((f) => f.length == 7), isTrue,
          reason: 'canonical payload has 7 fields');
      // Critical alarm: code 'c' + 'siren' tone + its rule id in field 5.
      expect(
        fields.any((f) => f[2] == 'c' && f[3] == 'siren' && f[4] == 'crit'),
        isTrue,
        reason: 'critical alarm encodes c + sound + appAlarmId',
      );
      // Normal alarm: code 'n' + 'classic' tone + its rule id in field 5.
      expect(
        fields.any((f) => f[2] == 'n' && f[3] == 'classic' && f[4] == 'norm'),
        isTrue,
        reason: 'normal alarm encodes n + sound + appAlarmId',
      );
    });

    test('a per-alarm custom ringtone rides field 6 of the payload', () async {
      // The engine now reads the URI off the AppAlarm being scheduled (it
      // migrated off the global AlarmSettings) and threads it into the payload.
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(
        followsRotation(id: 'a', customRingtoneUri: '/support/ringtones/midnight.mp3'),
      );
      await service.syncAlarms();

      final fields = scheduler.scheduled.values.single.payload!.split('|');
      expect(fields.length, 7);
      expect(fields[5], '/support/ringtones/midnight.mp3');
      expect(fields[6], '1', reason: 'vibration defaults on (field 7)');
    });

    test('a null custom ringtone leaves field 6 empty', () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation(id: 'a'));
      await service.syncAlarms();

      final fields = scheduler.scheduled.values.single.payload!.split('|');
      expect(fields.length, 7);
      expect(fields[5], '');
      expect(fields[6], '1', reason: 'vibration defaults on (field 7)');
    });

    test('scheduleAt receives the alarm soundKey', () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation(id: 'a', soundKey: 'digital'));
      await service.syncAlarms();

      expect(
        scheduler.scheduled.values.single.soundKey,
        'digital',
        reason: 'the per-tone channel is selected from this key',
      );
    });
  });

  group('weekly alarms', () {
    test('one OS alarm per due weekday inside the 14-day horizon', () async {
      // now = Mon 2026-06-01 05:00; horizon → 2026-06-15 05:00. A Monday-only
      // weekly at 06:00 fires today (06-01) and next Monday (06-08); the
      // following Monday (06-15) at 06:00 is past the horizon end.
      await alarms.upsert(weekly(weekdaysBitmask: 1));
      await service.syncAlarms();

      final fireAts = scheduler.scheduled.values.map((e) => e.fireAt).toSet();
      expect(fireAts, {
        DateTime(2026, 6, 1, 6, 0),
        DateTime(2026, 6, 8, 6, 0),
      });
    });

    test('multi-day mask schedules every matching weekday', () async {
      // Mon (bit 0) + Wed (bit 2) → 06-01, 06-03, 06-08, 06-10.
      await alarms.upsert(weekly(weekdaysBitmask: 1 | 1 << 2));
      await service.syncAlarms();

      final fireAts = scheduler.scheduled.values.map((e) => e.fireAt).toSet();
      expect(fireAts, {
        DateTime(2026, 6, 1, 6, 0),
        DateTime(2026, 6, 3, 6, 0),
        DateTime(2026, 6, 8, 6, 0),
        DateTime(2026, 6, 10, 6, 0),
      });
    });

    test('today\'s occurrence is dropped once its time has passed', () async {
      // now is 05:00; a weekly Monday alarm at 04:30 already passed today, so
      // the first scheduled occurrence is next Monday.
      await alarms.upsert(weekly(minutesOfDay: 4 * 60 + 30, weekdaysBitmask: 1));
      await service.syncAlarms();

      final fireAts = scheduler.scheduled.values.map((e) => e.fireAt).toList();
      expect(fireAts, isNot(contains(DateTime(2026, 6, 1, 4, 30))));
      expect(fireAts, contains(DateTime(2026, 6, 8, 4, 30)));
    });

    test('an empty weekday mask schedules nothing', () async {
      await alarms.upsert(weekly(weekdaysBitmask: 0));
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty);
    });

    test('a disabled weekly alarm schedules nothing', () async {
      await alarms.upsert(weekly(enabled: false));
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty);
    });

    test('weekly payload carries the NONE shift sentinel + its appAlarmId',
        () async {
      await alarms.upsert(weekly(id: 'wk7', weekdaysBitmask: 1));
      await service.syncAlarms();

      final fields = scheduler.scheduled.values.first.payload!.split('|');
      expect(fields.length, 7);
      expect(fields[0], noShiftPayloadSentinel);
      expect(fields[4], 'wk7');
    });
  });

  group('isAlarmSkipped (early-bird skip)', () {
    test('a skipped shift produces no OS schedule', () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day)
            .copyWith(isAlarmSkipped: true),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty,
          reason: 'skipped shifts must not schedule alarms');
    });

    test('skipping one shift leaves sibling shifts armed', () async {
      // Two Day shifts; skip only the first. The second still arms — the master
      // rule stays enabled.
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day)
            .copyWith(isAlarmSkipped: true),
      );
      await shifts.upsert(
        mkShift(id: 'd2', date: DateTime(2026, 6, 4), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();

      final fireAts = scheduler.scheduled.values.map((e) => e.fireAt).toSet();
      expect(fireAts, {DateTime(2026, 6, 4, 6, 0)});
    });
  });

  group('start() wires the watch streams', () {
    test('an alarm upserted AFTER start() triggers a sync (debounced)',
        () async {
      await service.start();
      expect(scheduler.scheduled, isEmpty);

      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation());
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(scheduler.scheduled, hasLength(1));
    });

    test('changing the global lead time AFTER start() re-arms the alarm',
        () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation());
      await service.start();
      final id = scheduler.scheduled.keys.single;
      expect(scheduler.scheduled[id]!.fireAt, DateTime(2026, 6, 2, 6, 0));

      // Bump the global lead time → the settings watch must trigger a re-sync
      // that moves the fireAt. This is the wiring whose absence orphaned the
      // Settings slider. 120 min before 07:00 = 05:00.
      await setGlobalLead(120);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(scheduler.scheduled[id]!.fireAt, DateTime(2026, 6, 2, 5, 0));
    });
  });

  group('Holiday Mode (global pause)', () {
    AlarmSyncService pausableService(bool Function() isPaused) {
      final s = AlarmSyncService(
        alarms: alarms,
        shifts: shifts,
        cycles: cycles,
        alarmSettings: settings,
        scheduler: scheduler,
        idMap: idMap,
        clock: clock,
        isPaused: isPaused,
      );
      addTearDown(s.stop);
      return s;
    }

    test('paused from cold: schedules nothing', () async {
      final service = pausableService(() => true);
      await alarms.upsert(followsRotation());
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );

      await service.syncAlarms();

      expect(scheduler.scheduled, isEmpty);
      expect(
        scheduler.callLog.where((c) => c.startsWith('schedule:')),
        isEmpty,
      );
    });

    test('pausing cancels the pending set but leaves roster + rules intact',
        () async {
      var paused = false;
      final service = pausableService(() => paused);
      await alarms.upsert(followsRotation());
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );

      await service.syncAlarms();
      expect(scheduler.scheduled, isNotEmpty); // armed while active

      paused = true;
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty); // disarmed — pending torn down

      // The whole point of Holiday Mode: data is silenced, NOT deleted.
      expect(await alarms.getAll(), isNotEmpty);
      expect(
        await shifts.getInRange(
          clock.now(),
          clock.now().add(const Duration(days: 14)),
        ),
        isNotEmpty,
      );

      // Un-pausing re-arms from the untouched roster.
      paused = false;
      await service.syncAlarms();
      expect(scheduler.scheduled, isNotEmpty);
    });
  });

  group('ad-hoc shifts — immutable history, ephemeral triggers (Phase 3)', () {
    test('an ad-hoc (cycle-less) shift arms its matching rotation alarm',
        () async {
      // mkShift never stamps a cycleId — exactly what the Manage tab's
      // "Add Custom Shift" editor writes. The reconcile must treat it like
      // any rostered shift: one OS alarm at shiftStart − lead.
      await alarms.upsert(followsRotation());
      await shifts.upsert(
        mkShift(id: 'adhoc', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await service.syncAlarms();

      final scheduled = scheduler.scheduled.values.single;
      expect(scheduled.fireAt, DateTime(2026, 6, 2, 6, 0));
      expect(scheduled.payload, contains('adhoc'));
    });

    test('an ARCHIVED ad-hoc shift is excluded from the desired set even when '
        'future-dated', () async {
      // The self-cleaning sweep flips `isArchived` on expired ad-hoc shifts;
      // the reconcile must skip them. Using a FUTURE date proves the guard is
      // honoured independently of the `fireAt > now` time gate — an archived
      // shift never arms an alarm regardless of when it falls.
      await alarms.upsert(followsRotation());
      await shifts.upsert(Shift(
        id: 'archived',
        date: DateTime(2026, 6, 2), // future relative to the 2026-06-01 clock
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
        isAdHoc: true,
        isArchived: true,
      ));
      await service.syncAlarms();

      expect(scheduler.scheduled, isEmpty,
          reason: 'archived shifts are out of the active desired set');
      expect(idMap.keys, isEmpty,
          reason: 'no trigger bookkeeping is allocated for an archived shift');
      // …and the record is untouched — archiving never deletes.
      expect(await shifts.getById('archived'), isNotNull);
    });

    test('a PAUSED shift is excluded from the desired set (no alarm fires)',
        () async {
      // Exception layer: the user marked this day off (sick/leave/holiday). The
      // reconcile must skip it like the other suppressions — but keep the
      // record (history).
      await alarms.upsert(followsRotation());
      await shifts.upsert(Shift(
        id: 'paused',
        date: DateTime(2026, 6, 2), // future relative to the 2026-06-01 clock
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
        isPaused: true,
        pauseReason: 'Sick',
      ));
      await service.syncAlarms();

      expect(scheduler.scheduled, isEmpty,
          reason: 'paused shifts never arm an alarm');
      expect(idMap.keys, isEmpty);
      expect(await shifts.getById('paused'), isNotNull,
          reason: 'pausing never deletes the shift');
    });

    test('start time passes → trigger leaves the OS window; the Shift '
        'record survives untouched', () async {
      await alarms.upsert(followsRotation());
      await shifts.upsert(
        mkShift(id: 'adhoc', date: DateTime(2026, 6, 1), type: ShiftType.day),
      );
      await service.syncAlarms();
      expect(scheduler.scheduled, hasLength(1)); // armed at 06:00

      // 08:00 — the 07:00 start has passed. The next reconcile must purge
      // the trigger from the rolling window (no fireAt in the past is ever
      // desired; the orphan pass cancels whatever the OS still holds)…
      clock.set(DateTime(2026, 6, 1, 8, 0));
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty,
          reason: 'past trigger purged from the 14-day window');

      // …but the shift itself is IMMUTABLE HISTORY — still in Hive for the
      // calendar view. Nothing in the engine may ever delete a Shift.
      expect(await shifts.getById('adhoc'), isNotNull,
          reason: 'shifts are immutable history');
    });

    test('the id-map bookkeeping is released the day after the fire date '
        '(queue-bloat purge)', () async {
      await alarms.upsert(followsRotation());
      await shifts.upsert(
        mkShift(id: 'adhoc', date: DateTime(2026, 6, 1), type: ShiftType.day),
      );
      await service.syncAlarms();
      expect(idMap.has('fr@2026-06-01'), isTrue);

      // Later the same day: the OS entry is already torn down, but the
      // id-map entry keeps one day of slack (cross-midnight snooze edge).
      clock.set(DateTime(2026, 6, 1, 8, 0));
      await service.syncAlarms();
      expect(idMap.has('fr@2026-06-01'), isTrue);

      // Next day: the fire date is strictly past — entry released. Without
      // this, the ledger grows by one row per alarm-occurrence forever.
      clock.set(DateTime(2026, 6, 2, 5, 0));
      await service.syncAlarms();
      expect(idMap.has('fr@2026-06-01'), isFalse,
          reason: 'ephemeral trigger bookkeeping must not outlive its date');
      expect(await shifts.getById('adhoc'), isNotNull,
          reason: 'the purge touches the id ledger ONLY, never the roster');
    });

    test('a backfilled PAST shift never arms a legacy alarm', () async {
      // Payslip-verification backfill: the editor now allows dates up to a
      // year back. A historical shift must be inert — the engine's shift
      // window starts at `now`, so it never even enters the desired-set
      // computation, and no id-map entry is allocated for it.
      await alarms.upsert(followsRotation());
      await shifts.upsert(
        mkShift(id: 'old1', date: DateTime(2026, 5, 20), type: ShiftType.day),
      );
      await shifts.upsert(
        // Yesterday — the nearest possible backfill, still strictly past.
        mkShift(id: 'old2', date: DateTime(2026, 5, 31), type: ShiftType.day),
      );
      await service.syncAlarms();

      expect(scheduler.scheduled, isEmpty,
          reason: 'historical shifts must never resurrect alarms');
      expect(idMap.keys, isEmpty,
          reason: 'no trigger bookkeeping is ever allocated for the past');
      // And the records themselves are untouched — immutable history.
      expect(await shifts.getById('old1'), isNotNull);
      expect(await shifts.getById('old2'), isNotNull);
    });

    test('the purge spares future-dated keys and unknown key shapes',
        () async {
      // A pre-Phase-5 plain-UUID key (no @date suffix) must be left alone —
      // the purge only reasons about keys whose shape it understands.
      await idMap.idFor('legacy-plain-shift-uuid');
      await alarms.upsert(followsRotation());
      await shifts.upsert(
        mkShift(id: 's1', date: DateTime(2026, 6, 1), type: ShiftType.day),
      );
      await shifts.upsert(
        mkShift(id: 's2', date: DateTime(2026, 6, 3), type: ShiftType.day),
      );
      await service.syncAlarms();
      expect(idMap.has('fr@2026-06-01'), isTrue);
      expect(idMap.has('fr@2026-06-03'), isTrue);

      clock.set(DateTime(2026, 6, 2, 5, 0));
      await service.syncAlarms();

      expect(idMap.has('fr@2026-06-01'), isFalse); // past → released
      expect(idMap.has('fr@2026-06-03'), isTrue); // future → kept
      expect(idMap.has('legacy-plain-shift-uuid'), isTrue,
          reason: 'unknown key shapes are never purged');
    });
  });

  group('per-occurrence dismissal — the blanket-cancel regression', () {
    // The field bug: a day shift with several alarms; the FIRST alarm fires
    // and is dismissed (shake or slide), and the reconcile then cancelled
    // EVERY remaining OS alarm for that shift, because the dismissal was a
    // whole-shift `isAcknowledged` write. The fix records the dismissal
    // per-ring (`Shift.dismissedAlarmIds`), so only the fired ring leaves the
    // desired set. This test drives the REAL replay path
    // (`ackPendingDismissalsInHive`, exactly what the boot/resume drain runs)
    // and asserts at the scheduler boundary.
    test('dismissing the first fired alarm leaves the shift\'s later OS '
        'alarms scheduled', () async {
      // Two alarms for the same Day shift: 60-min lead (06:00) + 30-min lead
      // (06:30) ahead of the 07:00 start.
      await alarms.upsert(followsRotation(id: 'lead60'));
      await alarms.upsert(
          followsRotation(id: 'lead30', relativeOffsetMinutes: 30));
      await shifts.upsert(
        mkShift(id: 's1', date: DateTime(2026, 6, 1), type: ShiftType.day),
      );
      await service.syncAlarms();

      final id60 = await idMap.idFor('lead60@2026-06-01');
      final id30 = await idMap.idFor('lead30@2026-06-01');
      expect(scheduler.scheduled.keys, containsAll([id60, id30]));

      // 06:05 — lead60 has fired natively; the user shakes/slides it away.
      // The native ledger line `s1|lead60` is replayed into Hive.
      clock.set(DateTime(2026, 6, 1, 6, 5));
      await ackPendingDismissalsInHive(
        shifts: shifts,
        dismissals: const [PendingDismissal('s1', 'lead60')],
      );
      await service.syncAlarms();

      expect(scheduler.scheduled.containsKey(id60), isFalse,
          reason: 'the fired + dismissed ring is torn down');
      expect(scheduler.scheduled[id30]?.fireAt, DateTime(2026, 6, 1, 6, 30),
          reason: 'THE regression: the shift\'s later alarm must survive the '
              'reconcile that follows a dismissal');
      expect((await shifts.getById('s1'))!.isAcknowledged, isFalse,
          reason: 'no whole-shift ack may be written for a targeted dismiss');
    });

    test('a targeted dismissal never disturbs the same alarm\'s ring on '
        'OTHER shifts', () async {
      await alarms.upsert(followsRotation(id: 'lead60'));
      await shifts.upsert(
        mkShift(id: 's1', date: DateTime(2026, 6, 1), type: ShiftType.day),
      );
      await shifts.upsert(
        mkShift(id: 's2', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await service.syncAlarms();
      final idTomorrow = await idMap.idFor('lead60@2026-06-02');

      clock.set(DateTime(2026, 6, 1, 6, 5));
      await ackPendingDismissalsInHive(
        shifts: shifts,
        dismissals: const [PendingDismissal('s1', 'lead60')],
      );
      await service.syncAlarms();

      expect(scheduler.scheduled[idTomorrow]?.fireAt,
          DateTime(2026, 6, 2, 6, 0),
          reason: 'the dismissal is scoped to s1\'s occurrence only');
    });

    test('a LEGACY whole-shift ledger entry still tears down every ring for '
        'that shift (documented degradation)', () async {
      await alarms.upsert(followsRotation(id: 'lead60'));
      await alarms.upsert(
          followsRotation(id: 'lead30', relativeOffsetMinutes: 30));
      await shifts.upsert(
        mkShift(id: 's1', date: DateTime(2026, 6, 1), type: ShiftType.day),
      );
      await service.syncAlarms();
      final id30 = await idMap.idFor('lead30@2026-06-01');

      clock.set(DateTime(2026, 6, 1, 6, 5));
      await ackPendingDismissalsInHive(
        shifts: shifts,
        dismissals: const [PendingDismissal('s1', '')], // no alarm identity
      );
      await service.syncAlarms();

      expect(scheduler.scheduled.containsKey(id30), isFalse,
          reason: 'without an alarm identity the conservative whole-shift '
              'ack applies — an old build\'s ledger entry must still land');
    });

    test('a weekly skippedThrough watermark cancels ONLY the covered '
        'occurrence — next week\'s OS alarm stays armed', () async {
      // Monday-only weekly at 06:00; now is Mon 2026-06-01 05:00, so the
      // 14-day window holds two occurrences: today and Mon 06-08.
      final rule = weekly();
      await alarms.upsert(rule);
      await service.syncAlarms();
      final idToday = await idMap.idFor('wk@2026-06-01');
      final idNextWeek = await idMap.idFor('wk@2026-06-08');
      expect(scheduler.scheduled.keys, containsAll([idToday, idNextWeek]));

      // The Dashboard early-skip write: watermark = today's fire instant.
      await alarms.upsert(
        rule.copyWith(skippedThrough: DateTime(2026, 6, 1, 6, 0)),
      );
      await service.syncAlarms();

      expect(scheduler.scheduled.containsKey(idToday), isFalse,
          reason: 'the skipped occurrence\'s OS alarm is torn down');
      expect(scheduler.scheduled[idNextWeek]?.fireAt,
          DateTime(2026, 6, 8, 6, 0),
          reason: 'occurrences after the watermark are untouched');
    });
  });
}
