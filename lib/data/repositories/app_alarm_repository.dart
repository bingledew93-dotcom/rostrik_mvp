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

/// Deletes [appAlarmId] from [alarms] iff it resolves to a one-time alarm that
/// should be cleaned up after firing (see [shouldDeleteAfterFiring]). The native
/// [AlarmActivity] dismiss / auto-timeout records every fired alarm's id in the
/// `pending_alarm_deletes` ledger; the Dart drain replays them through here, so
/// the "a one-time alarm fires once, then is gone" rule lives in exactly one
/// place. Returns true iff a rule was actually deleted. No-op (false) when the
/// id is empty, the rule is already gone, or it's a recurring alarm — all
/// idempotent, so a re-drained ledger can't double-fault.
Future<bool> deleteAlarmAfterFiring(
  AppAlarmRepository alarms,
  String appAlarmId,
) async {
  if (appAlarmId.isEmpty) return false;
  final alarm = await alarms.getById(appAlarmId);
  if (!shouldDeleteAfterFiring(alarm)) return false;
  await alarms.delete(appAlarmId);
  return true;
}
