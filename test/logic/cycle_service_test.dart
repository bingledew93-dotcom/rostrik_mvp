import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_scheduler.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_cycle.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/cycle_service.dart';

import '../alarms/fakes.dart';

void main() {
  late FakeShiftRepository shifts;
  late FakeShiftCycleRepository cycles;
  late FakeAlarmScheduler scheduler;
  late InMemoryNotificationIdMap idMap;
  late CycleService service;

  setUp(() {
    shifts = FakeShiftRepository();
    cycles = FakeShiftCycleRepository();
    scheduler = FakeAlarmScheduler();
    idMap = InMemoryNotificationIdMap();
    service = CycleService(
      cycles: cycles,
      shifts: shifts,
      scheduler: scheduler,
      idMap: idMap,
    );
  });

  tearDown(() async {
    await shifts.dispose();
    await cycles.dispose();
  });

  ShiftCycle mkCycle(String id, {DateTime? start, DateTime? end}) => ShiftCycle(
        id: id,
        label: 'Cycle $id',
        summary: 'test fixture',
        startDate: start ?? DateTime(2026, 5, 1),
        endDate: end ?? DateTime(2026, 5, 7),
        createdAt: DateTime(2026, 5, 1),
      );

  Shift mkShift(String id, String? cycleId) => Shift(
        id: id,
        date: DateTime(2026, 5, 1),
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
        cycleId: cycleId,
      );

  test('deleteCycle removes the cycle row + its child shifts', () async {
    await cycles.create(mkCycle('c1'));
    await shifts.upsert(mkShift('s1', 'c1'));
    await shifts.upsert(mkShift('s2', 'c1'));
    await shifts.upsert(mkShift('orphan', null));
    await shifts.upsert(mkShift('other', 'c2'));

    await service.deleteCycle('c1');

    expect(await cycles.getById('c1'), isNull);
    expect(await shifts.getById('s1'), isNull);
    expect(await shifts.getById('s2'), isNull);
    expect(await shifts.getById('orphan'), isNotNull,
        reason: 'shifts without a cycleId must NOT be cascade-deleted');
    expect(await shifts.getById('other'), isNotNull,
        reason: 'shifts belonging to a different cycle are untouched');
  });

  test('deleteCycle cancels each child notification via the scheduler',
      () async {
    await cycles.create(mkCycle('c1'));
    await shifts.upsert(mkShift('s1', 'c1'));
    await shifts.upsert(mkShift('s2', 'c1'));
    // Pre-allocate ids so `idMap.has` returns true; mirrors what the
    // engine's reconcile would have done at scheduling time.
    final id1 = await idMap.idFor('s1');
    final id2 = await idMap.idFor('s2');
    await scheduler.scheduleAt(
      id: id1,
      fireAt: DateTime(2026, 5, 1, 6),
      title: 't',
      body: 'b',
    );
    await scheduler.scheduleAt(
      id: id2,
      fireAt: DateTime(2026, 5, 2, 6),
      title: 't',
      body: 'b',
    );

    await service.deleteCycle('c1');

    expect(scheduler.callLog, containsAll(<String>['cancel:$id1', 'cancel:$id2']));
    expect(await scheduler.pendingIds(), isEmpty);
    // idMap entries released so a future shift with the same UUID (or a
    // re-generated cycle) starts fresh.
    expect(idMap.has('s1'), isFalse);
    expect(idMap.has('s2'), isFalse);
  });

  test('deleteCycle is safe when the cycle has zero children', () async {
    await cycles.create(mkCycle('c1'));
    await service.deleteCycle('c1');
    expect(await cycles.getById('c1'), isNull);
    expect(scheduler.callLog, isEmpty,
        reason: 'no scheduler calls when no children exist');
  });

  test('deleteCycle is idempotent (re-calling after success is a no-op)',
      () async {
    await cycles.create(mkCycle('c1'));
    await shifts.upsert(mkShift('s1', 'c1'));
    await service.deleteCycle('c1');
    // Second call must not throw and must not modify anything further.
    await service.deleteCycle('c1');
    expect(await cycles.getById('c1'), isNull);
  });

  test('deleteCycle survives a scheduler.cancel that throws', () async {
    final throwingScheduler = _ThrowingScheduler();
    final svc = CycleService(
      cycles: cycles,
      shifts: shifts,
      scheduler: throwingScheduler,
      idMap: idMap,
    );
    await cycles.create(mkCycle('c1'));
    await shifts.upsert(mkShift('s1', 'c1'));
    await idMap.idFor('s1');

    // Must complete normally — the Hive write is the load-bearing
    // side effect; a flaky plugin must not block the cascade.
    await svc.deleteCycle('c1');

    expect(await cycles.getById('c1'), isNull);
    expect(await shifts.getById('s1'), isNull);
    expect(idMap.has('s1'), isFalse);
  });
}

/// Scheduler that always throws on `cancel`. Used to confirm `CycleService`
/// continues the cascade rather than aborting on a single OS-layer flake.
class _ThrowingScheduler implements AlarmScheduler {
  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime fireAt,
    required String title,
    required String body,
    String? payload,
  }) async {}

  @override
  Future<void> cancel(int id) async {
    throw StateError('boom');
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<Set<int>> pendingIds() async => const {};
}
