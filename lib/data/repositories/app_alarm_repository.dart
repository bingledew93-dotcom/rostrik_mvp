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

/// Deletes [appAlarmId] from [alarms] iff it resolves to an auto-delete
/// one-time alarm (see [shouldAutoDeleteOnDismiss]). Shared by the in-app
/// (WakeUpScreen) and foreground (NotificationActionDispatcher) dismiss paths
/// so the "delete a fired one-time alarm at the dismissal instant" rule lives
/// in exactly one place; the killed-app background isolate runs the same logic
/// against a raw Hive box (it has no repository handle). No-op when the payload
/// carried no rule id, the rule is already gone, or it isn't eligible — all
/// idempotent, so concurrent dismiss paths can't double-fault.
Future<void> deleteAlarmIfAutoDelete(
  AppAlarmRepository alarms,
  String appAlarmId,
) async {
  if (appAlarmId.isEmpty) return;
  final alarm = await alarms.getById(appAlarmId);
  if (!shouldAutoDeleteOnDismiss(alarm)) return;
  await alarms.delete(appAlarmId);
}
