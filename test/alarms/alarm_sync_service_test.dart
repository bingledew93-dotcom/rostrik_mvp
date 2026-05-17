import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_sync_service.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

import 'fakes.dart';

void main() {
  late FakeAppAlarmRepository alarms;
  late FakeShiftRepository shifts;
  late FakeShiftCycleRepository cycles;
  late FakeAlarmScheduler scheduler;
  late InMemoryNotificationIdMap idMap;
  late FrozenClock clock;
  late AlarmSyncService service;

  setUp(() {
    alarms = FakeAppAlarmRepository();
    shifts = FakeShiftRepository();
    cycles = FakeShiftCycleRepository();
    scheduler = FakeAlarmScheduler();
    idMap = InMemoryNotificationIdMap();
    clock = FrozenClock(DateTime(2026, 6, 1, 5, 0));
    service = AlarmSyncService(
      alarms: alarms,
      shifts: shifts,
      cycles: cycles,
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
  });

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

  AppAlarm followsRotation({
    String id = 'fr',
    int minutesOfDay = 6 * 60,
    String label = 'Wake Up',
    ShiftType? linkedShiftType = ShiftType.day,
    bool enabled = true,
    bool isRelativeTime = false,
    int relativeOffsetMinutes = 90,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: minutesOfDay,
        label: label,
        repeatType: AppAlarmRepeatType.followsRotation,
        enabled: enabled,
        linkedShiftType: linkedShiftType,
        isRelativeTime: isRelativeTime,
        relativeOffsetMinutes: relativeOffsetMinutes,
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

  group('one-time alarms', () {
    test('today if minutesOfDay is still after now', () async {
      // Now is 05:00 on 2026-06-01; alarm at 07:00 fires today.
      await alarms.upsert(oneTime(minutesOfDay: 7 * 60));
      await service.syncAlarms();

      expect(scheduler.scheduled.values, hasLength(1));
      final entry = scheduler.scheduled.values.single;
      expect(entry.fireAt, DateTime(2026, 6, 1, 7, 0));
    });

    test('tomorrow if minutesOfDay has already passed today', () async {
      // Now is 05:00; alarm at 04:30 already passed today → tomorrow 04:30.
      await alarms.upsert(oneTime(minutesOfDay: 4 * 60 + 30));
      await service.syncAlarms();

      final entry = scheduler.scheduled.values.single;
      expect(entry.fireAt, DateTime(2026, 6, 2, 4, 30));
    });

    test('disabled one-time alarm produces no OS schedule', () async {
      await alarms.upsert(oneTime(enabled: false));
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('follows-rotation alarms', () {
    test('one OS alarm per matching shift in the 365-day window', () async {
      // Three shifts: 2 Day, 1 Night. The Day-linked alarm should
      // emit two OS alarms — one per Day shift — and skip the Night.
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
      await alarms.upsert(followsRotation(minutesOfDay: 6 * 60));
      await service.syncAlarms();

      final fireAts =
          scheduler.scheduled.values.map((e) => e.fireAt).toSet();
      expect(fireAts, hasLength(2));
      expect(fireAts.contains(DateTime(2026, 6, 2, 6, 0)), isTrue);
      expect(fireAts.contains(DateTime(2026, 6, 4, 6, 0)), isTrue);
      // Night shift not picked up.
      expect(fireAts.contains(DateTime(2026, 6, 3, 6, 0)), isFalse);
    });

    test('alarm with no linkedShiftType is skipped', () async {
      // Misconfigured — repeatType says followsRotation but link is null.
      // Service must defensively skip rather than crash or pick all shifts.
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation(linkedShiftType: null));
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty);
    });

    test('past fireAt on the SAME day as now is filtered out', () async {
      // Now is 05:00 on 2026-06-01; a Day shift today + alarm at 04:00
      // produces a fireAt of 04:00 today — already past, skip.
      await shifts.upsert(
        mkShift(id: 'today', date: DateTime(2026, 6, 1), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation(minutesOfDay: 4 * 60));
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty);
    });

    test('shifts outside the 365-day horizon are not picked up', () async {
      // ~14 months from the frozen "now" (2026-06-01) — beyond the
      // 365-day default horizon.
      await shifts.upsert(
        mkShift(
          id: 'far',
          date: DateTime(2027, 8, 1),
          type: ShiftType.day,
        ),
      );
      await alarms.upsert(followsRotation());
      await service.syncAlarms();
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('follows-rotation alarms — relative time', () {
    test(
      'fireAt is computed as shiftStart - relativeOffsetMinutes',
      () async {
        // Day shift starts at 07:00 on 2026-06-02. With a 90-min
        // relative offset, the alarm must fire at 05:30 on 2026-06-02.
        await shifts.upsert(
          mkShift(
            id: 'd1',
            date: DateTime(2026, 6, 2),
            type: ShiftType.day,
            startMin: 7 * 60,
            endMin: 15 * 60,
          ),
        );
        await alarms.upsert(followsRotation(
          isRelativeTime: true,
          relativeOffsetMinutes: 90,
        ));
        await service.syncAlarms();

        final entry = scheduler.scheduled.values.single;
        expect(entry.fireAt, DateTime(2026, 6, 2, 5, 30));
      },
    );

    test(
      'a 45-min offset before an 08:00 Night shift fires at 07:15',
      () async {
        // Different shift type + non-hour-boundary offset to confirm
        // the math handles minute-level granularity.
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
          isRelativeTime: true,
          relativeOffsetMinutes: 45,
        ));
        await service.syncAlarms();

        final entry = scheduler.scheduled.values.single;
        expect(entry.fireAt, DateTime(2026, 6, 3, 7, 15));
      },
    );

    test(
      'an offset that crosses midnight lands on the previous calendar day',
      () async {
        // Day shift starts at 04:00; with a 6-hour offset the alarm
        // fires at 22:00 the previous evening. This is the "alarm on
        // the day BEFORE the shift" edge case that the engine's
        // payload format used to call out — calendar-math subtraction
        // handles it cleanly.
        await shifts.upsert(
          mkShift(
            id: 'd1',
            date: DateTime(2026, 6, 5),
            type: ShiftType.day,
            startMin: 4 * 60,
            endMin: 12 * 60,
          ),
        );
        await alarms.upsert(followsRotation(
          isRelativeTime: true,
          relativeOffsetMinutes: 6 * 60,
        ));
        await service.syncAlarms();

        final entry = scheduler.scheduled.values.single;
        expect(entry.fireAt, DateTime(2026, 6, 4, 22, 0));
      },
    );

    test(
      'isRelativeTime is ignored for the exact-time path (default)',
      () async {
        // Belt-and-braces: defaulting to isRelativeTime=false should
        // use the alarm's minutesOfDay regardless of what
        // relativeOffsetMinutes is set to.
        await shifts.upsert(
          mkShift(
            id: 'd1',
            date: DateTime(2026, 6, 2),
            type: ShiftType.day,
            startMin: 7 * 60,
            endMin: 15 * 60,
          ),
        );
        await alarms.upsert(followsRotation(
          minutesOfDay: 6 * 60,
          relativeOffsetMinutes: 180, // would imply 04:00 if used
        ));
        await service.syncAlarms();
        final entry = scheduler.scheduled.values.single;
        expect(entry.fireAt, DateTime(2026, 6, 2, 6, 0));
      },
    );
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
      // No schedule and no cancel — the desired set matches what's
      // already pending.
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

    test('changing minutesOfDay reschedules the same id at the new fireAt',
        () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation(minutesOfDay: 6 * 60));
      await service.syncAlarms();
      final firstId = scheduler.scheduled.keys.single;
      expect(scheduler.scheduled[firstId]!.fireAt,
          DateTime(2026, 6, 2, 6, 0));

      // Re-upsert at a different time. The composite id-map key is
      // `(alarmId, dateKey)` — same alarm, same date, so the same int
      // id, with a new fireAt. The scheduler's contract is to replace
      // the existing entry.
      await alarms.upsert(followsRotation(minutesOfDay: 5 * 60));
      await service.syncAlarms();
      expect(scheduler.scheduled, hasLength(1));
      expect(scheduler.scheduled[firstId]!.fireAt,
          DateTime(2026, 6, 2, 5, 0));
    });
  });

  group('start() wires the watch streams', () {
    test('an alarm upserted AFTER start() triggers a sync (debounced)',
        () async {
      await service.start();
      // First sync runs synchronously in start(); confirm baseline.
      expect(scheduler.scheduled, isEmpty);

      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation());

      // Wait past the debounce window.
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(scheduler.scheduled, hasLength(1));
    });
  });
}
