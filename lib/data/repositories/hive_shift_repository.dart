import 'dart:async';

import 'package:hive_ce/hive.dart';

import '../models/shift.dart';
import 'shift_repository.dart';

class HiveShiftRepository implements ShiftRepository {
  HiveShiftRepository(this._box);

  static const String boxName = 'shifts';

  final Box<Shift> _box;

  @override
  Future<void> upsert(Shift shift) => _box.put(shift.id, shift);

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  Future<Shift?> getById(String id) async => _box.get(id);

  @override
  Future<List<Shift>> getInRange(
    DateTime fromInclusive,
    DateTime toExclusive,
  ) async {
    final from = _normalize(fromInclusive);
    final to = _normalize(toExclusive);
    final result = _box.values
        .where((s) => !s.date.isBefore(from) && s.date.isBefore(to))
        .toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.startMinutes.compareTo(b.startMinutes);
      });
    return result;
  }

  @override
  Future<Shift?> getNextAfter(DateTime now) async {
    Shift? best;
    DateTime? bestStart;
    for (final s in _box.values) {
      final start = s.startDateTime;
      if (!start.isAfter(now)) continue;
      if (bestStart == null || start.isBefore(bestStart)) {
        best = s;
        bestStart = start;
      }
    }
    return best;
  }

  @override
  Stream<List<Shift>> watchInRange(
    DateTime fromInclusive,
    DateTime toExclusive,
  ) {
    // Explicit StreamController instead of async* + await-for over box.watch().
    // Broadcast-stream cancellation does not propagate cleanly out of an
    // `await for` inside an async* generator, which leaks the subscription
    // and hangs the consumer's `cancel()` future.
    late StreamController<List<Shift>> controller;
    StreamSubscription<BoxEvent>? sub;
    var cancelled = false;

    Future<void> emit() async {
      if (cancelled || controller.isClosed) return;
      final snapshot = await getInRange(fromInclusive, toExclusive);
      if (cancelled || controller.isClosed) return;
      controller.add(snapshot);
    }

    controller = StreamController<List<Shift>>(
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

  @override
  Future<List<Shift>> getByCycleId(String cycleId) async {
    final out = <Shift>[];
    for (final s in _box.values) {
      if (s.cycleId == cycleId) out.add(s);
    }
    return out;
  }

  @override
  Future<Shift?> getLatestForCycle(String cycleId) async {
    Shift? best;
    for (final s in _box.values) {
      if (s.cycleId != cycleId) continue;
      if (best == null || s.date.isAfter(best.date)) best = s;
    }
    return best;
  }

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
