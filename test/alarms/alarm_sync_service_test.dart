import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/alarms/alarm_sync_service.dart';

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
}
