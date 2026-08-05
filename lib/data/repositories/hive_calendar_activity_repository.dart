import 'dart:async';

import 'package:hive_ce/hive.dart';

import '../models/calendar_activity.dart';
import 'calendar_activity_repository.dart';

class HiveCalendarActivityRepository implements CalendarActivityRepository {
  HiveCalendarActivityRepository(this._box);

  static const String boxName = 'calendar_activities';

  final Box<CalendarActivity> _box;

  @override
  Future<void> upsert(CalendarActivity activity) async {
    await _box.put(activity.id, activity);
    // Force the write to disk before resolving — same durability guarantee the
    // AppAlarm repo makes (an aggressive OEM reap can drop an un-flushed frame,
    // which on this project's Pixel would silently lose a just-added activity).
    await _box.flush();
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
    await _box.flush();
  }

  @override
  Future<CalendarActivity?> getById(String id) async => _box.get(id);

  @override
  Future<List<CalendarActivity>> getAll() async => _box.values.toList();

  @override
  Stream<List<CalendarActivity>> watch() {
    // Explicit-controller pattern (same as HiveAppAlarmRepository): an async*
    // generator over a broadcast box.watch() leaks subscriptions on cancel.
    late StreamController<List<CalendarActivity>> controller;
    StreamSubscription<BoxEvent>? sub;
    var cancelled = false;

    Future<void> emit() async {
      if (cancelled || controller.isClosed) return;
      final snapshot = await getAll();
      if (cancelled || controller.isClosed) return;
      controller.add(snapshot);
    }

    controller = StreamController<List<CalendarActivity>>(
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
