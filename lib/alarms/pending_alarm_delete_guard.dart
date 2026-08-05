import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/repositories/app_alarm_repository.dart';

/// Native "fired one-time alarm" fail-safe ledger — the post-fire cleanup
/// counterpart to [pendingDismissalsFileName] and [pendingSnoozesFileName].
///
/// A one-time alarm fires exactly once. Left in Hive after firing, the engine's
/// daily next-occurrence projection re-arms it every following day — a one-shot
/// alarm silently turning into a daily cycle. The OLD
/// (`flutter_local_notifications`) dismiss handlers deleted such a rule AT the
/// dismissal instant; the native AlarmManager path that replaced them has no
/// Dart isolate guaranteed alive at fire time, so the delete is deferred through
/// this durable ledger instead.
///
/// The native [AlarmActivity] dismiss (and the [AlarmAudioService] 15-minute
/// battery auto-timeout) append the fired alarm's owning `appAlarmId` here with
/// a SYNCHRONOUS flushed + fsync'd write, so the record survives an immediate
/// process reap. Dart drains it on cold start / resume / background re-sync,
/// BEFORE the reconcile, and deletes any entry that resolves to a one-time alarm
/// ([deleteAlarmAfterFiring] — a no-op for recurring rules). Read → apply →
/// clear ordering makes a crash between apply and clear re-apply idempotently
/// rather than ever leaking a stale one-time rule.
const String pendingAlarmDeletesFileName = 'pending_alarm_deletes';

File _pendingAlarmDeletesFileIn(Directory appSupportDir) =>
    File('${appSupportDir.path}/$pendingAlarmDeletesFileName');

/// Reads the ledger — trimmed, blank lines dropped, de-duplicated (a rapid
/// double-tap appends twice; one delete is enough). Missing file or any read
/// error reads as "nothing pending" rather than throwing: this runs on the
/// boot/resume path and a corrupt ledger must never block app start.
List<String> readPendingAlarmDeletes(Directory appSupportDir) {
  final file = _pendingAlarmDeletesFileIn(appSupportDir);
  try {
    if (!file.existsSync()) return const [];
    return file
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toSet()
        .toList();
  } catch (_) {
    return const [];
  }
}

/// Deletes the ledger. Best-effort — called only AFTER the Hive apply has
/// landed, so a failed delete merely re-applies (idempotently) next time.
void clearPendingAlarmDeletes(Directory appSupportDir) {
  try {
    final file = _pendingAlarmDeletesFileIn(appSupportDir);
    if (file.existsSync()) file.deleteSync();
  } catch (_) {
    // Harmless: the apply is idempotent.
  }
}

/// Replays native-store fired-alarm ids into Hive: each id in [appAlarmIds] is
/// deleted iff it resolves to a one-time alarm ([deleteAlarmAfterFiring], which
/// no-ops a recurring rule, an already-deleted id, or an empty id). Returns how
/// many rules were actually deleted.
///
/// Idempotent and tolerant by design: unknown/recurring/empty ids are all
/// skipped — replaying the same ledger twice deletes nothing the second time.
Future<int> applyPendingAlarmDeletesInHive({
  required AppAlarmRepository alarms,
  required List<String> appAlarmIds,
}) async {
  var deleted = 0;
  for (final id in appAlarmIds) {
    if (await deleteAlarmAfterFiring(alarms, id)) deleted++;
  }
  return deleted;
}

/// Composes the path_provider hop + read + apply + clear. Shared by `main()`
/// (cold start + resume) AND the background-sync isolate, so all three contexts
/// drain the same way without depending on the alarm-routing MethodChannel
/// (which the headless background engine doesn't have).
///
/// Ordering is load-bearing: read → apply → clear, so a crash between apply and
/// clear re-applies (idempotently) rather than leaking a stale one-time rule.
/// Returns the number of rules deleted.
Future<int> drainPendingAlarmDeletesIntoHive(AppAlarmRepository alarms) async {
  final Directory dir;
  try {
    dir = await getApplicationSupportDirectory();
  } catch (_) {
    return 0; // no platform dir (e.g. widget tests) — nothing to drain
  }
  final ids = readPendingAlarmDeletes(dir);
  if (ids.isEmpty) return 0;
  final deleted = await applyPendingAlarmDeletesInHive(
    alarms: alarms,
    appAlarmIds: ids,
  );
  clearPendingAlarmDeletes(dir);
  return deleted;
}
