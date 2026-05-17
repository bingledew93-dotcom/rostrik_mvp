import 'dart:async';

import 'package:hive_ce/hive.dart';

import '../models/app_alarm.dart';
import 'app_alarm_repository.dart';

class HiveAppAlarmRepository implements AppAlarmRepository {
  HiveAppAlarmRepository(this._box);

  static const String boxName = 'alarms';

  final Box<AppAlarm> _box;

  @override
  Future<void> upsert(AppAlarm alarm) => _box.put(alarm.id, alarm);

  @override
  Future<void> delete(String id) => _box.delete(id);

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
