import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_engine.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

import 'fakes.dart';

void main() {
  late FakeShiftRepository shifts;
  late FakeAlarmSettingsRepository settings;
  late FakeAlarmScheduler scheduler;
  late InMemoryNotificationIdMap idMap;
  late FrozenClock clock;
  late AlarmEngine engine;

  // A pinned "now" so every test reasons against the same calendar.
  final now = DateTime(2026, 5, 1, 9); // 09:00 on may 1

  setUp(() {
    shifts = FakeShiftRepository();
    settings = FakeAlarmSettingsRepository();
    scheduler = FakeAlarmScheduler();
    idMap = InMemoryNotificationIdMap();
    clock = FrozenClock(now);
    engine = AlarmEngine(
      shifts: shifts,
      alarmSettings: settings,
      scheduler: scheduler,
      idMap: idMap,
      clock: clock,
    );
  });

  group('reconcile — empty / negative cases', () {
    test('empty roster schedules nothing', () async {
      await engine.reconcile();
      expect(scheduler.scheduled, isEmpty);
    });

    test('only OFF shifts schedule nothing', () async {
      await shifts.upsert(_shift(
        id: 'off-1',
        date: DateTime(2026, 5, 2),
        type: ShiftType.off,
        start: 0,
        end: 0,
      ));
      await engine.reconcile();
      expect(scheduler.scheduled, isEmpty);
    });

    test('only muted shifts schedule nothing', () async {
      await shifts.upsert(_dayShift(
        id: 'muted-1',
        date: DateTime(2026, 5, 2),
      ).copyWith(isMuted: true));
      await engine.reconcile();
      expect(scheduler.scheduled, isEmpty);
    });

    test('shifts whose fireAt has already passed are skipped', () async {
      // 07:00 today, lead time 60 min → fireAt 06:00, now is 09:00. Past.
      await shifts.upsert(_dayShift(
        id: 'past-today',
        date: DateTime(2026, 5, 1),
      ));
      await engine.reconcile();
      expect(scheduler.scheduled, isEmpty);
    });

    test('shifts beyond the 60-day horizon are skipped', () async {
      await shifts.upsert(_dayShift(
        id: 'far-future',
        date: now.add(const Duration(days: 90)),
      ));
      await engine.reconcile();
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('reconcile — basic scheduling', () {
    test('schedules an upcoming shift at startDateTime - leadTime', () async {
      // Day shift on may 2, 07:00. Lead 60min → fireAt may 2, 06:00.
      await shifts.upsert(_dayShift(
        id: 'tomorrow',
        date: DateTime(2026, 5, 2),
      ));
      await engine.reconcile();

      expect(scheduler.scheduled, hasLength(1));
      final entry = scheduler.scheduled.values.single;
      expect(entry.fireAt, DateTime(2026, 5, 2, 6));
      expect(entry.title, 'Day shift coming up');
      expect(entry.body, 'Starts at 07:00');
    });

    test('uses absolute startDateTime so overnight shifts schedule correctly',
        () async {
      // Night shift on may 2: 22:00–06:00. Lead 60min → fireAt may 2, 21:00
      // (NOT may 1, 21:00 — the date is may 2 and start is 22:00 same day).
      await shifts.upsert(_shift(
        id: 'overnight',
        date: DateTime(2026, 5, 2),
        type: ShiftType.night,
        start: 22 * 60,
        end: 6 * 60,
      ));
      await engine.reconcile();

      final entry = scheduler.scheduled.values.single;
      expect(entry.fireAt, DateTime(2026, 5, 2, 21));
      expect(entry.title, 'Night shift coming up');
      expect(entry.body, 'Starts at 22:00');
    });

    test('schedules each non-OFF shift exactly once when interleaved with OFF',
        () async {
      await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
      await shifts.upsert(_shift(
        id: 'b-off',
        date: DateTime(2026, 5, 3),
        type: ShiftType.off,
      ));
      await shifts.upsert(_shift(
        id: 'c',
        date: DateTime(2026, 5, 4),
        type: ShiftType.afternoon,
        start: 15 * 60,
        end: 23 * 60,
      ));

      await engine.reconcile();

      expect(scheduler.scheduled, hasLength(2));
      final shiftIdsScheduled = scheduler.scheduled.values
          .map((a) => a.title)
          .toList();
      expect(shiftIdsScheduled, contains('Day shift coming up'));
      expect(shiftIdsScheduled, contains('Afternoon shift coming up'));
    });

    test('respects a custom lead time from settings', () async {
      await settings.write(
        const AlarmSettings(leadTime: Duration(minutes: 30)),
      );
      await shifts.upsert(_dayShift(
        id: 'tomorrow',
        date: DateTime(2026, 5, 2),
      ));
      await engine.reconcile();

      final entry = scheduler.scheduled.values.single;
      expect(entry.fireAt, DateTime(2026, 5, 2, 6, 30)); // 07:00 minus 30 min
    });
  });

  group('reconcile — diff-and-converge', () {
    test('idempotent: second call produces zero scheduler mutations', () async {
      await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
      await shifts.upsert(_dayShift(id: 'b', date: DateTime(2026, 5, 3)));

      await engine.reconcile();
      final firstLog = List<String>.from(scheduler.callLog);
      expect(firstLog.where((l) => l.startsWith('schedule:')), hasLength(2));

      scheduler.clearLog();
      await engine.reconcile();
      expect(scheduler.callLog, isEmpty);
    });

    test('cancels pending alarms when their shift is deleted', () async {
      await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
      await shifts.upsert(_dayShift(id: 'b', date: DateTime(2026, 5, 3)));
      await engine.reconcile();
      expect(scheduler.scheduled, hasLength(2));

      final idForA = await idMap.idFor('a');
      await shifts.delete('a');
      scheduler.clearLog();
      await engine.reconcile();

      expect(scheduler.callLog, ['cancel:$idForA']);
      expect(scheduler.scheduled.containsKey(idForA), isFalse);
      expect(scheduler.scheduled, hasLength(1));
    });

    test('schedules newly-added shifts on a follow-up reconcile', () async {
      await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
      await engine.reconcile();
      expect(scheduler.scheduled, hasLength(1));

      await shifts.upsert(_dayShift(id: 'b', date: DateTime(2026, 5, 3)));
      scheduler.clearLog();
      await engine.reconcile();

      expect(scheduler.callLog.where((l) => l.startsWith('schedule:')),
          hasLength(1));
      expect(scheduler.scheduled, hasLength(2));
    });

    test('lead-time change reschedules pending alarms with the new fireAt',
        () async {
      // Initial: 60-min lead. Day shift on may 2 at 07:00 → fireAt may 2 06:00.
      await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
      await engine.reconcile();
      final id = scheduler.scheduled.keys.single;
      expect(scheduler.scheduled[id]!.fireAt, DateTime(2026, 5, 2, 6));

      // User shrinks the global lead time to 30 min. Reconcile must update
      // the already-pending alarm so it fires 30 min before the shift now,
      // not 60 min before.
      await settings.write(
        const AlarmSettings(leadTime: Duration(minutes: 30)),
      );
      scheduler.clearLog();
      await engine.reconcile();

      // Same notification id, new fireAt — the scheduler contract says
      // scheduleAt with an existing id replaces in place.
      expect(scheduler.scheduled[id]!.fireAt, DateTime(2026, 5, 2, 6, 30));
      expect(scheduler.callLog, contains('schedule:$id'));
      // No spurious cancel — replace is atomic via scheduleAt.
      expect(
        scheduler.callLog.where((l) => l.startsWith('cancel:')),
        isEmpty,
      );
    });

    test('lead-time change reschedules every pending alarm, not just one',
        () async {
      await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
      await shifts.upsert(_dayShift(id: 'b', date: DateTime(2026, 5, 3)));
      await shifts.upsert(_dayShift(id: 'c', date: DateTime(2026, 5, 4)));
      await engine.reconcile();
      final ids = scheduler.scheduled.keys.toSet();
      expect(ids, hasLength(3));

      await settings.write(
        const AlarmSettings(leadTime: Duration(minutes: 15)),
      );
      scheduler.clearLog();
      await engine.reconcile();

      // Every id must have been re-scheduled with the new fireAt.
      for (final id in ids) {
        expect(scheduler.callLog, contains('schedule:$id'));
      }
      expect(scheduler.scheduled[ids.first]!.fireAt, DateTime(2026, 5, 2, 6, 45));
    });

    test('reconcile is still idempotent after a lead-time change settles',
        () async {
      await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
      await engine.reconcile();
      await settings.write(
        const AlarmSettings(leadTime: Duration(minutes: 30)),
      );
      await engine.reconcile(); // applies the new lead time

      scheduler.clearLog();
      await engine.reconcile(); // nothing changed since the settle
      expect(scheduler.callLog, isEmpty);
    });

    test('id stability — same shift gets the same notification id across reconciles',
        () async {
      await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
      await engine.reconcile();
      final firstId = scheduler.scheduled.keys.single;

      await shifts.delete('a');
      await engine.reconcile();
      expect(scheduler.scheduled, isEmpty);

      // Re-add the SAME shift id. Engine should reuse the same notification id.
      await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
      await engine.reconcile();
      expect(scheduler.scheduled.keys.single, firstId);
    });
  });

  group('reconcile — mute / unmute', () {
    test('muting an already-scheduled shift cancels its alarm', () async {
      await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
      await engine.reconcile();
      final id = scheduler.scheduled.keys.single;

      // Mute via the canonical UI path: upsert the same shift with the flag.
      await shifts.upsert((await shifts.getById('a'))!.copyWith(isMuted: true));
      scheduler.clearLog();
      await engine.reconcile();

      expect(scheduler.callLog, ['cancel:$id']);
      expect(scheduler.scheduled, isEmpty);
    });

    test('unmuting reschedules with the same notification id', () async {
      // Schedule, mute, reconcile-cancel, then unmute and confirm the alarm
      // comes back under the same id (id stability is contracted via
      // NotificationIdMap.idFor).
      await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
      await engine.reconcile();
      final id = scheduler.scheduled.keys.single;

      await shifts.upsert((await shifts.getById('a'))!.copyWith(isMuted: true));
      await engine.reconcile();
      expect(scheduler.scheduled, isEmpty);

      await shifts.upsert((await shifts.getById('a'))!.copyWith(isMuted: false));
      scheduler.clearLog();
      await engine.reconcile();

      expect(scheduler.callLog, ['schedule:$id']);
      expect(scheduler.scheduled.keys.single, id);
      expect(scheduler.scheduled[id]!.fireAt, DateTime(2026, 5, 2, 6));
    });

    test(
      'reconcile is idempotent while a shift stays muted',
      () async {
        await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
        await engine.reconcile();

        await shifts.upsert(
          (await shifts.getById('a'))!.copyWith(isMuted: true),
        );
        await engine.reconcile(); // settles to "no scheduled alarm"

        scheduler.clearLog();
        await engine.reconcile(); // should produce zero scheduler calls
        expect(scheduler.callLog, isEmpty);
      },
    );

    test(
      'muting one shift in a multi-shift roster only cancels that one',
      () async {
        await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
        await shifts.upsert(_dayShift(id: 'b', date: DateTime(2026, 5, 3)));
        await shifts.upsert(_dayShift(id: 'c', date: DateTime(2026, 5, 4)));
        await engine.reconcile();
        expect(scheduler.scheduled, hasLength(3));

        final idForB = scheduler.scheduled.entries
            .firstWhere(
              (e) => e.value.fireAt == DateTime(2026, 5, 3, 6),
            )
            .key;

        await shifts.upsert(
          (await shifts.getById('b'))!.copyWith(isMuted: true),
        );
        scheduler.clearLog();
        await engine.reconcile();

        expect(scheduler.callLog, ['cancel:$idForB']);
        expect(scheduler.scheduled, hasLength(2));
        expect(scheduler.scheduled.containsKey(idForB), isFalse);
      },
    );

    test(
      'lead-time change while a shift is muted does not resurrect it',
      () async {
        // Regression guard: the lead-time path re-iterates desired shifts.
        // If isMuted ever stops being respected on the rescheduling branch,
        // a global lead-time change could re-introduce a cancelled alarm
        // — which would be a silent reliability bug.
        await shifts.upsert(_dayShift(id: 'a', date: DateTime(2026, 5, 2)));
        await engine.reconcile();
        await shifts.upsert(
          (await shifts.getById('a'))!.copyWith(isMuted: true),
        );
        await engine.reconcile();
        expect(scheduler.scheduled, isEmpty);

        await settings.write(
          const AlarmSettings(leadTime: Duration(minutes: 30)),
        );
        scheduler.clearLog();
        await engine.reconcile();

        expect(scheduler.callLog, isEmpty);
        expect(scheduler.scheduled, isEmpty);
      },
    );

    test(
      'a shift that was created already-muted never schedules',
      () async {
        await shifts.upsert(
          _dayShift(id: 'a', date: DateTime(2026, 5, 2))
              .copyWith(isMuted: true),
        );
        await engine.reconcile();
        expect(scheduler.scheduled, isEmpty);
        expect(scheduler.callLog.where((l) => l.startsWith('schedule:')),
            isEmpty);
      },
    );
  });

  group('reconcile — horizon and cap', () {
    test('caps at maxScheduled by ascending fireAt', () async {
      // Build a custom engine with a tiny cap to make the math obvious.
      engine = AlarmEngine(
        shifts: shifts,
        alarmSettings: settings,
        scheduler: scheduler,
        idMap: idMap,
        clock: clock,
        maxScheduled: 3,
      );

      // 5 future day shifts on consecutive days.
      for (var i = 1; i <= 5; i++) {
        await shifts.upsert(_dayShift(
          id: 'd$i',
          date: now.add(Duration(days: i)),
        ));
      }
      await engine.reconcile();

      expect(scheduler.scheduled, hasLength(3));
      // The earliest 3 must be scheduled — fireAt = (day i, 06:00)
      final fireAts = scheduler.scheduled.values
          .map((a) => a.fireAt)
          .toList()
        ..sort();
      expect(fireAts, [
        DateTime(2026, 5, 2, 6),
        DateTime(2026, 5, 3, 6),
        DateTime(2026, 5, 4, 6),
      ]);
    });

    test('shifts ON the horizon edge (date == now + horizon) are excluded',
        () async {
      // getInRange is [from, to) — exclusive upper bound.
      final horizonDate = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 60));
      await shifts.upsert(_dayShift(id: 'edge', date: horizonDate));
      await engine.reconcile();
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('reconcile — tick-of-time edges', () {
    test('a shift whose fireAt equals exactly `now` is excluded (strict >)',
        () async {
      // now is 09:00. Lead 60min. Need start = 10:00. Day shift today 10:00…
      await shifts.upsert(_shift(
        id: 'edge',
        date: DateTime(2026, 5, 1),
        type: ShiftType.day,
        start: 10 * 60,
        end: 18 * 60,
      ));
      await engine.reconcile();
      expect(scheduler.scheduled, isEmpty);
    });

    test('a shift whose fireAt is one minute after now is included', () async {
      await settings.write(
        const AlarmSettings(leadTime: Duration(minutes: 60)),
      );
      // start = 10:01 → fireAt = 09:01, now = 09:00.
      await shifts.upsert(_shift(
        id: 'edge+1',
        date: DateTime(2026, 5, 1),
        type: ShiftType.day,
        start: 10 * 60 + 1,
        end: 18 * 60,
      ));
      await engine.reconcile();
      expect(scheduler.scheduled, hasLength(1));
    });
  });
}

// -----------------------------------------------------------------------------
// helpers
// -----------------------------------------------------------------------------

Shift _shift({
  required String id,
  required DateTime date,
  ShiftType type = ShiftType.day,
  int start = 7 * 60,
  int end = 15 * 60,
  String? note,
}) =>
    Shift(
      id: id,
      date: date,
      type: type,
      startMinutes: start,
      endMinutes: end,
      note: note,
    );

Shift _dayShift({required String id, required DateTime date}) =>
    _shift(id: id, date: date, type: ShiftType.day, start: 7 * 60, end: 15 * 60);
