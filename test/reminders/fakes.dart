import 'dart:async';

import 'package:rostrik_mvp/data/models/calendar_activity.dart';
import 'package:rostrik_mvp/data/repositories/calendar_activity_repository.dart';
import 'package:rostrik_mvp/reminders/activity_reminder_scheduler.dart';

/// In-memory [CalendarActivityRepository] for reminder-service and activity-UI
/// tests. Mirrors the Hive impl's contract: idempotent delete, `watch` emits the
/// current snapshot on subscribe and on every subsequent change.
class FakeCalendarActivityRepository implements CalendarActivityRepository {
  final Map<String, CalendarActivity> _activities = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final List<String> callLog = [];

  Future<void> dispose() => _changes.close();

  @override
  Future<void> upsert(CalendarActivity activity) async {
    _activities[activity.id] = activity;
    callLog.add('upsert:${activity.id}');
    if (_changes.hasListener) _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    if (_activities.remove(id) != null) {
      callLog.add('delete:$id');
      if (_changes.hasListener) _changes.add(null);
    }
  }

  @override
  Future<CalendarActivity?> getById(String id) async => _activities[id];

  @override
  Future<List<CalendarActivity>> getAll() async => _activities.values.toList();

  @override
  Stream<List<CalendarActivity>> watch() {
    late StreamController<List<CalendarActivity>> controller;
    StreamSubscription<void>? sub;

    Future<void> emit() async {
      if (controller.isClosed) return;
      controller.add(await getAll());
    }

    controller = StreamController<List<CalendarActivity>>(
      onListen: () {
        sub = _changes.stream.listen((_) => emit());
        emit();
      },
      onCancel: () async {
        await sub?.cancel();
      },
    );

    return controller.stream;
  }
}

/// Records every reminder scheduling call for assertion.
class FakeReminderScheduled {
  FakeReminderScheduled({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;

  @override
  String toString() =>
      'FakeReminderScheduled(id: $id, at: $at, title: "$title", body: "$body")';
}

class FakeActivityReminderScheduler implements ActivityReminderScheduler {
  final Map<int, FakeReminderScheduled> _scheduled = {};
  final List<String> callLog = [];

  Map<int, FakeReminderScheduled> get scheduled => Map.unmodifiable(_scheduled);

  void clearLog() => callLog.clear();

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    _scheduled[id] =
        FakeReminderScheduled(id: id, at: at, title: title, body: body);
    callLog.add('schedule:$id');
  }

  @override
  Future<void> cancel(int id) async {
    _scheduled.remove(id);
    callLog.add('cancel:$id');
  }
}
