import 'dart:async';

import 'package:hive_ce/hive.dart';

import '../models/app_alarm.dart';
import 'app_alarm_repository.dart';

class HiveAppAlarmRepository implements AppAlarmRepository {
  HiveAppAlarmRepository(this._box);

  static const String boxName = 'alarms';

  final Box<AppAlarm> _box;

  @override
  Future<void> upsert(AppAlarm alarm) async {
    await _box.put(alarm.id, alarm);
    // Force the write to disk before resolving. Hive's put completes once the
    // frame is queued/written to the OS, but an aggressive OEM process-reap can
    // still drop an un-flushed frame — flushing here guarantees a created/edited
    // alarm survives an immediate kill. Writes are infrequent, so the fsync cost
    // is irrelevant.
    await _box.flush();
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
    // Same durability guarantee as upsert: a deleted alarm must not resurrect
    // after a kill-before-flush. Idempotent — deleting an unknown id is a no-op.
    await _box.flush();
  }

  @override
  Future<AppAlarm?> getById(String id) async => _box.get(id);

  @override
  Future<List<AppAlarm>> getAll() async => _box.values.toList();

  @override
  Stream<List<AppAlarm>> watch() {
    // Same explicit-controller pattern as HiveShiftCycleRepository —
    // broadcast-stream cancellation doesn't propagate cleanly out of
    // an `await for` inside an async* generator.
    late StreamController<List<AppAlarm>> controller;
    StreamSubscription<BoxEvent>? sub;
    var cancelled = false;

    Future<void> emit() async {
      if (cancelled || controller.isClosed) return;
      final snapshot = await getAll();
      if (cancelled || controller.isClosed) return;
      controller.add(snapshot);
    }

    controller = StreamController<List<AppAlarm>>(
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
