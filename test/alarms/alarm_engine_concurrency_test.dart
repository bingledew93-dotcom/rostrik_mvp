import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_engine.dart';
import 'package:rostrik_mvp/alarms/notification_id_map.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

import 'fakes.dart';

/// Regression suite for the concurrency bug exposed by SimulationInjector.
///
/// In production, `AlarmEngine.start()` subscribes to `_shifts.watchInRange`
/// and `_alarmSettings.watch` and uses `listen((_) => reconcile())` —
/// fire-and-forget. A burst of stream emissions (e.g. bulk shift import)
/// would fire several reconciles concurrently, racing on:
///   - `HiveNotificationIdMap.idFor` — non-atomic counter read-modify-write
///     across an `await _box.put`. Concurrent calls for distinct shift ids
///     could allocate the same int to multiple shifts.
///   - The engine's `_scheduledFireAt` map and the scheduler's pending set
///     — both mutated mid-reconcile.
///
/// The harness saw 18 distinct ids allocated for 7 shifts and chronic
/// schedule/cancel thrashing. The fix is `AlarmEngine`'s in-flight queue:
/// every reconcile chains onto the previous one. These tests guard that
/// invariant.
void main() {
  late FakeShiftRepository shifts;
  late FakeAlarmSettingsRepository settings;
  late FakeAlarmScheduler scheduler;
  late FrozenClock clock;

  final now = DateTime(2026, 5, 1, 9);

  setUp(() {
    shifts = FakeShiftRepository();
    settings = FakeAlarmSettingsRepository();
    scheduler = FakeAlarmScheduler();
    clock = FrozenClock(now);
  });

  AlarmEngine buildEngine(NotificationIdMap idMap) => AlarmEngine(
        shifts: shifts,
        alarmSettings: settings,
        scheduler: scheduler,
        idMap: idMap,
        clock: clock,
      );

  Future<void> seedNightShifts(int count) async {
    for (var i = 0; i < count; i++) {
      await shifts.upsert(_nightShift(
        id: 'night-$i',
        date: DateTime(2026, 5, 3 + i),
      ));
    }
  }

  group('reconcile — concurrency', () {
    test(
      '5 concurrent reconciles against a non-atomic id map produce '
      '7 unique alarms with no id duplication',
      () async {
        // _RacyNotificationIdMap mirrors HiveNotificationIdMap's
        // production semantics — a yield between counter read and write.
        // This is the exact shape that broke the SimulationInjector run.
        final idMap = _RacyNotificationIdMap();
        final engine = buildEngine(idMap);

        await seedNightShifts(7);

        // Fire 5 reconciles in parallel. Pre-fix this produces id
        // thrashing; post-fix the queue serializes them.
        await Future.wait(List.generate(5, (_) => engine.reconcile()));

        expect(scheduler.scheduled.length, 7,
            reason: 'expected one OS-level alarm per shift');
        expect(scheduler.scheduled.keys.toSet().length, 7,
            reason: 'no duplicate ids in the scheduler');

        final pending = await scheduler.pendingIds();
        expect(pending.length, 7);

        // Every shift should have been allocated exactly one id, and that
        // id should be the same one currently held in the scheduler.
        final allocatedIds = <int>{};
        for (var i = 0; i < 7; i++) {
          allocatedIds.add(await idMap.idFor('night-$i'));
        }
        expect(allocatedIds.length, 7, reason: 'no shifts share an id');
        expect(allocatedIds, equals(scheduler.scheduled.keys.toSet()));
      },
    );

    test(
      '20 concurrent no-op reconciles produce zero scheduler mutations '
      'after the first',
      () async {
        // Even with stable, fast id allocation, parallel reconciles could
        // still race on `_scheduledFireAt` and re-issue scheduleAt calls.
        // With the queue, only the first reconcile mutates; the next 19
        // see _scheduledFireAt already populated and become true no-ops.
        final engine = buildEngine(InMemoryNotificationIdMap());

        await seedNightShifts(7);

        await Future.wait(List.generate(20, (_) => engine.reconcile()));

        final scheduleCalls =
            scheduler.callLog.where((c) => c.startsWith('schedule:')).length;
        final cancelCalls =
            scheduler.callLog.where((c) => c.startsWith('cancel')).length;

        expect(scheduleCalls, 7,
            reason: 'each shift scheduled exactly once across 20 reconciles');
        expect(cancelCalls, 0,
            reason: 'nothing was ever desired-then-undesired');
      },
    );

    test(
      'a throwing reconcile does not poison the queue',
      () async {
        // Sanity: the catchError on _inFlight is what stops a single
        // failed reconcile from blocking every subsequent one.
        final engine = buildEngine(_ThrowOnceNotificationIdMap());

        await seedNightShifts(3);

        // First reconcile throws on the first idFor call; we expect to
        // observe that error.
        await expectLater(engine.reconcile(), throwsA(isA<StateError>()));

        // Queue must still be drainable. Second reconcile should run
        // normally and converge to 3 scheduled alarms.
        await engine.reconcile();
        expect(scheduler.scheduled.length, 3);
      },
    );
  });
}

Shift _nightShift({required String id, required DateTime date}) => Shift(
      id: id,
      date: date,
      type: ShiftType.night,
      startMinutes: 18 * 60, // 18:00
      endMinutes: 6 * 60, // 06:00 (next day, overnight)
    );

/// Mirrors `HiveNotificationIdMap`'s production semantics: a yield between
/// the counter read and the put. Two concurrent calls for distinct shift
/// ids will read the same counter value and both be assigned the same int
/// unless the engine serializes them.
class _RacyNotificationIdMap implements NotificationIdMap {
  final Map<String, int> _map = {};
  int _counter = 0;

  @override
  Future<int> idFor(String shiftId) async {
    final existing = _map[shiftId];
    if (existing != null) return existing;
    final next = _counter + 1;
    // Yield. In production this is `await _box.put(_counterKey, next)`.
    await Future<void>.delayed(Duration.zero);
    _counter = next;
    _map[shiftId] = next;
    return next;
  }

  @override
  Future<void> release(String shiftId) async {
    _map.remove(shiftId);
  }

  @override
  bool has(String shiftId) => _map.containsKey(shiftId);
}

class _ThrowOnceNotificationIdMap implements NotificationIdMap {
  final Map<String, int> _map = {};
  int _counter = 0;
  bool _shouldThrow = true;

  @override
  Future<int> idFor(String shiftId) async {
    if (_shouldThrow) {
      _shouldThrow = false;
      throw StateError('first call fails — queue must keep draining');
    }
    return _map.putIfAbsent(shiftId, () => ++_counter);
  }

  @override
  Future<void> release(String shiftId) async {
    _map.remove(shiftId);
  }

  @override
  bool has(String shiftId) => _map.containsKey(shiftId);
}
