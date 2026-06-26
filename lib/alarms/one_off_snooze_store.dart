import 'package:hive_ce_flutter/hive_flutter.dart';

/// Snooze state for shift-less ("one-off") alarms — `oneTime` and `weekly`
/// rules that have no linked [Shift] to carry `snoozedUntil`.
///
/// Stored in the always-open generic `settings` Hive box as a `Map<String,int>`
/// (AppAlarm id → snoozedUntil epoch millis). The `settings` box is the one
/// store reachable from BOTH the foreground isolate AND the headless background
/// sync isolate, mirroring how `AlarmSyncService` persists `_scheduledFireAt`.
///
/// All shift-less alarms share the `'NONE'` shiftId sentinel, so the AppAlarm id
/// is the only stable discriminator — it's plumbed natively (the snooze ledger
/// records it) and used as the key here and in `projectAlarmRings`.
///
/// Entries are pruned on every read and write, so the map stays bounded by the
/// set of currently-active one-off snoozes.
const String oneOffSnoozesSettingsKey = 'alarm_sync.one_off_snoozes';

/// The live one-off snoozes (AppAlarm id → snoozedUntil), dropping any entry
/// already elapsed by [now]. Best-effort: a closed/missing box reads empty (the
/// test harness never opens `settings`).
Map<String, DateTime> readOneOffSnoozes({DateTime? now}) {
  final clock = now ?? DateTime.now();
  try {
    if (!Hive.isBoxOpen('settings')) return const {};
    final raw = Hive.box('settings').get(oneOffSnoozesSettingsKey);
    if (raw is! Map) return const {};
    final out = <String, DateTime>{};
    raw.forEach((dynamic k, dynamic v) {
      final id = k?.toString();
      final ms = (v is int) ? v : int.tryParse(v.toString());
      if (id == null || id.isEmpty || ms == null) return;
      final until = DateTime.fromMillisecondsSinceEpoch(ms);
      if (until.isAfter(clock)) out[id] = until; // prune elapsed
    });
    return out;
  } catch (_) {
    return const {};
  }
}

/// Records [appAlarmId]'s snooze (latest-wins), rewriting the map with elapsed
/// entries pruned so it never grows unbounded. No-op when the box is closed or
/// [appAlarmId] is empty.
Future<void> upsertOneOffSnooze(
  String appAlarmId,
  DateTime until, {
  DateTime? now,
}) async {
  if (appAlarmId.isEmpty) return;
  final clock = now ?? DateTime.now();
  try {
    if (!Hive.isBoxOpen('settings')) return;
    final box = Hive.box('settings');
    final raw = box.get(oneOffSnoozesSettingsKey);
    final next = <String, int>{};
    if (raw is Map) {
      raw.forEach((dynamic k, dynamic v) {
        final id = k?.toString();
        final ms = (v is int) ? v : int.tryParse(v.toString());
        if (id == null || id.isEmpty || ms == null) return;
        if (DateTime.fromMillisecondsSinceEpoch(ms).isAfter(clock)) next[id] = ms;
      });
    }
    final ms = until.millisecondsSinceEpoch;
    final existing = next[appAlarmId];
    if (existing == null || ms > existing) next[appAlarmId] = ms;
    await box.put(oneOffSnoozesSettingsKey, next);
  } catch (_) {
    // Best-effort: a failed write just means the one-off snooze isn't persisted;
    // the native re-arm still fires, it's only the reconcile-suppression we lose.
  }
}
