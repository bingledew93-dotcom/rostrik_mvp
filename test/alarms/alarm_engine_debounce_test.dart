import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_engine.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

import 'fakes.dart';

/// Stress test for the stream-driven debounce.
///
/// Without coalescing, a 6-month roster import (~180 shifts) would emit
/// one Hive `BoxEvent` per row and drive ~180 full reconcile cycles, each
/// hitting the OS notification bridge. On budget Android devices that's
/// severe UI jank. The engine debounces stream emissions into a single
/// reconcile after a quiet window.
void main() {
  late FakeShiftRepository shifts;
  late FakeAlarmSettingsRepository settings;
  late FakeAlarmScheduler scheduler;
  late InMemoryNotificationIdMap idMap;
  late FrozenClock clock;

  // Short window keeps the test fast while still being long enough that the
  // microtask-driven burst comfortably finishes within it.
  const debounce = Duration(milliseconds: 50);

  final now = DateTime(2026, 5, 1, 9);

  setUp(() {
    shifts = FakeShiftRepository();
    settings = FakeAlarmSettingsRepository();
    scheduler = FakeAlarmScheduler();
    idMap = InMemoryNotificationIdMap();
    clock = FrozenClock(now);
  });

  tearDown(() async {
    await shifts.dispose();
    await settings.dispose();
  });

  AlarmEngine buildEngine() => AlarmEngine(
        shifts: shifts,
        alarmSettings: settings,
        scheduler: scheduler,
        idMap: idMap,
        clock: clock,
        debounceWindow: debounce,
      );

  test(
    '7 rapid stream emissions coalesce into exactly one reconcile cycle',
    () async {
      final engine = buildEngine();
      await engine.start();
      // start() did one initial reconcile against an empty roster.
      expect(scheduler.callLog, isEmpty,
          reason: 'initial reconcile schedules nothing for an empty roster');

      // Burst-insert 7 day shifts. Each upsert lands an event on the change
      // stream, which the engine's listener turns into a debounce reset.
      for (var i = 0; i < 7; i++) {
        await shifts.upsert(_dayShift(
          id: 'd$i',
          date: now.add(Duration(days: i + 1)),
        ));
      }

      // Critical assertion #1: mid-burst, the debounce window has not
      // elapsed, so NO reconcile has run. If the listeners were calling
      // reconcile() directly, the call log would already contain ~7
      // schedule entries here.
      expect(scheduler.callLog, isEmpty,
          reason: 'no reconcile may fire before the debounce window elapses');

      // Wait past the debounce window.
      await Future<void>.delayed(debounce * 3);

      // Critical assertion #2: exactly one reconcile cycle ran. Seven
      // schedule calls (one per shift), zero cancels (nothing was ever
      // desired-then-undesired), seven distinct ids in the scheduler.
      final scheduleCalls =
          scheduler.callLog.where((l) => l.startsWith('schedule:')).length;
      final cancelCalls =
          scheduler.callLog.where((l) => l.startsWith('cancel')).length;
      expect(scheduleCalls, 7,
          reason: 'one coalesced reconcile scheduled all 7 shifts');
      expect(cancelCalls, 0,
          reason: 'no spurious cancellations from intermediate states');
      expect(scheduler.scheduled, hasLength(7));

      await engine.stop();
    },
  );

  test(
    'a settings emission within the same window also coalesces',
    () async {
      // Heterogeneous burst: a roster change AND a lead-time change inside
      // the same window must still resolve to a single reconcile.
      final engine = buildEngine();
      await engine.start();

      await shifts.upsert(_dayShift(id: 'a', date: now.add(const Duration(days: 1))));
      await settings.write(const AlarmSettings(leadTime: Duration(minutes: 30)));
      await shifts.upsert(_dayShift(id: 'b', date: now.add(const Duration(days: 2))));

      expect(scheduler.callLog, isEmpty,
          reason: 'mixed-source burst must not fire a reconcile mid-window');

      await Future<void>.delayed(debounce * 3);

      final scheduleCalls =
          scheduler.callLog.where((l) => l.startsWith('schedule:')).length;
      expect(scheduleCalls, 2,
          reason: 'one coalesced reconcile picks up both shifts at the new lead time');
      // Lead time was 30 min when the reconcile ran → fireAt is start - 30 min.
      // Day shift starts at 07:00, so fireAt should be 06:30.
      final entries = scheduler.scheduled.values.toList();
      expect(entries.map((e) => e.fireAt.minute).toSet(), {30});

      await engine.stop();
    },
  );

  test(
    'stop() cancels a pending debounce so the reconcile never fires',
    () async {
      final engine = buildEngine();
      await engine.start();

      await shifts.upsert(_dayShift(id: 'a', date: now.add(const Duration(days: 1))));

      // Stop while the debounce timer is still pending.
      await engine.stop();

      // Wait well past the window — the cancelled timer must not fire.
      await Future<void>.delayed(debounce * 3);
      expect(scheduler.callLog, isEmpty,
          reason: 'debounce timer must be cancelled by stop()');
    },
  );
}

Shift _dayShift({required String id, required DateTime date}) => Shift(
      id: id,
      date: date,
      type: ShiftType.day,
      startMinutes: 7 * 60,
      endMinutes: 15 * 60,
    );
