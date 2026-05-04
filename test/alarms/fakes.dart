import 'dart:async';

import 'package:rostrik_mvp/alarms/alarm_scheduler.dart';
import 'package:rostrik_mvp/alarms/notification_id_map.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/repositories/alarm_settings_repository.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/util/clock.dart';

/// Records every scheduling call for assertion-friendly inspection.
class FakeScheduledAlarm {
  FakeScheduledAlarm({
    required this.id,
    required this.fireAt,
    required this.title,
    required this.body,
    this.payload,
  });

  final int id;
  final DateTime fireAt;
  final String title;
  final String body;
  final String? payload;

  @override
  String toString() =>
      'FakeScheduledAlarm(id: $id, fireAt: $fireAt, title: "$title")';
}

class FakeAlarmScheduler implements AlarmScheduler {
  final Map<int, FakeScheduledAlarm> _scheduled = {};
  final List<String> callLog = [];

  Map<int, FakeScheduledAlarm> get scheduled => Map.unmodifiable(_scheduled);

  void clearLog() => callLog.clear();

  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime fireAt,
    required String title,
    required String body,
    String? payload,
  }) async {
    _scheduled[id] = FakeScheduledAlarm(
      id: id,
      fireAt: fireAt,
      title: title,
      body: body,
      payload: payload,
    );
    callLog.add('schedule:$id');
  }

  @override
  Future<void> cancel(int id) async {
    _scheduled.remove(id);
    callLog.add('cancel:$id');
  }

  @override
  Future<void> cancelAll() async {
    _scheduled.clear();
    callLog.add('cancelAll');
  }

  @override
  Future<Set<int>> pendingIds() async => _scheduled.keys.toSet();
}

/// In-memory ShiftRepository for engine tests. `getNextAfter` still throws
/// because the engine never calls it — we want a loud failure if a future
/// test starts relying on it. `watchInRange` is a real broadcast stream so
/// tests can drive the engine through its actual subscription path (needed
/// to exercise the debounce).
class FakeShiftRepository implements ShiftRepository {
  final Map<String, Shift> _shifts = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Future<void> dispose() => _changes.close();

  @override
  Future<void> upsert(Shift shift) async {
    _shifts[shift.id] = shift;
    if (_changes.hasListener) _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    _shifts.remove(id);
    if (_changes.hasListener) _changes.add(null);
  }

  @override
  Future<Shift?> getById(String id) async => _shifts[id];

  @override
  Future<List<Shift>> getInRange(
    DateTime fromInclusive,
    DateTime toExclusive,
  ) async {
    final from = DateTime(
      fromInclusive.year,
      fromInclusive.month,
      fromInclusive.day,
    );
    final to = DateTime(toExclusive.year, toExclusive.month, toExclusive.day);
    final result = _shifts.values
        .where((s) => !s.date.isBefore(from) && s.date.isBefore(to))
        .toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0
            ? byDate
            : a.startMinutes.compareTo(b.startMinutes);
      });
    return result;
  }

  @override
  Future<Shift?> getNextAfter(DateTime now) async =>
      throw UnimplementedError('not used by AlarmEngine.reconcile');

  @override
  Stream<List<Shift>> watchInRange(
    DateTime fromInclusive,
    DateTime toExclusive,
  ) {
    // Wire the inner subscription synchronously inside onListen so no
    // mutation events can slip through between subscription start and the
    // initial-snapshot emit. The engine's `.skip(1)` then drops the initial.
    late StreamController<List<Shift>> controller;
    StreamSubscription<void>? sub;

    Future<void> emit() async {
      if (controller.isClosed) return;
      controller.add(await getInRange(fromInclusive, toExclusive));
    }

    controller = StreamController<List<Shift>>(
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

class FakeAlarmSettingsRepository implements AlarmSettingsRepository {
  AlarmSettings _value = AlarmSettings.defaults;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Future<void> dispose() => _changes.close();

  @override
  Future<AlarmSettings> read() async => _value;

  @override
  Future<void> write(AlarmSettings settings) async {
    _value = settings;
    if (_changes.hasListener) _changes.add(null);
  }

  @override
  Stream<AlarmSettings> watch() {
    late StreamController<AlarmSettings> controller;
    StreamSubscription<void>? sub;

    void emit() {
      if (controller.isClosed) return;
      controller.add(_value);
    }

    controller = StreamController<AlarmSettings>(
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

/// Pure-Dart NotificationIdMap; no Hive setup required for engine tests.
class InMemoryNotificationIdMap implements NotificationIdMap {
  final Map<String, int> _map = {};
  int _counter = 0;

  @override
  Future<int> idFor(String shiftId) async =>
      _map.putIfAbsent(shiftId, () => ++_counter);

  @override
  Future<void> release(String shiftId) async {
    _map.remove(shiftId);
  }

  @override
  bool has(String shiftId) => _map.containsKey(shiftId);
}

class FrozenClock implements Clock {
  FrozenClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);

  void set(DateTime t) => _now = t;
}
