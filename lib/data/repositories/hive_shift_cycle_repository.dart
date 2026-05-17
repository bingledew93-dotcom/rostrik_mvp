import 'dart:async';

import 'package:hive_ce/hive.dart';

import '../models/shift_cycle.dart';
import 'shift_cycle_repository.dart';

class HiveShiftCycleRepository implements ShiftCycleRepository {
  HiveShiftCycleRepository(this._box);

  static const String boxName = 'cycles';

  final Box<ShiftCycle> _box;

  @override
  Future<void> create(ShiftCycle cycle) {
    if (_box.containsKey(cycle.id)) {
      throw StateError(
        'ShiftCycle id ${cycle.id} already exists. Cycle ids are UUIDs; '
        'a duplicate indicates a generator regression.',
      );
    }
    return _box.put(cycle.id, cycle);
  }

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<ShiftCycle?> getById(String id) async => _box.get(id);

  @override
  Future<List<ShiftCycle>> getAll() async {
    final list = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Stream<List<ShiftCycle>> watch() {
    // Same explicit-controller pattern as HiveShiftRepository.watchInRange —
    // broadcast-stream cancellation does not propagate cleanly out of an
    // `await for` inside an async* generator, and we want clean teardown
    // when the StreamProvider unsubscribes.
    late StreamController<List<ShiftCycle>> controller;
    StreamSubscription<BoxEvent>? sub;
    var cancelled = false;

    Future<void> emit() async {
      if (cancelled || controller.isClosed) return;
      final snapshot = await getAll();
      if (cancelled || controller.isClosed) return;
      controller.add(snapshot);
    }

    controller = StreamController<List<ShiftCycle>>(
      onListen: () async {
        await emit();
        if (cancelled) return;
        sub = _box.watch().listen((_) => emit());
      },
      onCancel: () async {
        cancelled = true;
        await sub?.cancel();
      },
    );

    return controller.stream;
  }
}
