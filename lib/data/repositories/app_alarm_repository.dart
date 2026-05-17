import '../models/app_alarm.dart';

/// Pure data-access contract for [AppAlarm] records.
///
/// `upsert` (not separate create/update) because alarms are routinely
/// flipped on/off via the AlarmsScreen Switch — that's the same
/// in-place mutation an edit flow would do. Idempotent on the id.
abstract class AppAlarmRepository {
  Future<void> upsert(AppAlarm alarm);

  /// Idempotent — no-op if the id is unknown.
  Future<void> delete(String id);

  Future<AppAlarm?> getById(String id);

  /// Snapshot of every alarm. No ordering guarantee at the repo layer;
  /// the UI sorts on `minutesOfDay` if it cares about display order.
  Future<List<AppAlarm>> getAll();

  /// Emits the current snapshot, then a fresh snapshot on every change.
  Stream<List<AppAlarm>> watch();
}
