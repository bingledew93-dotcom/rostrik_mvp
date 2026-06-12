import 'dart:io';

import '../data/repositories/shift_repository.dart';
import 'alarm_sync_service.dart' show noShiftPayloadSentinel;

/// Native dismiss fail-safe ledger — the killed-app Dismiss path that does
/// NOT depend on the headless Flutter isolate living long enough to boot
/// Hive.
///
/// Physical testing (Pixel 9 Pro XL, Android 14) showed the OS reaping the
/// background engine BEFORE the slow-path Hive write (binding → path_provider
/// → box open → put → flush, hundreds of ms on a cold headless engine) could
/// land — leaving the database believing the alarm was still ringing and a
/// later cold boot raising a silent, dead WakeUpScreen.
///
/// The fail-safe is a flat ledger file (`pending_dismissals`, one shift id
/// per line) in the app's native files directory:
///   * **Written as the FIRST instruction** of the background handler — one
///     path_provider hop, then a SYNCHRONOUS kernel write
///     (`writeAsStringSync(flush: true)`). Once that syscall returns the data
///     survives process death unconditionally (commit()-grade durability —
///     stronger than `SharedPreferences.apply()`, whose queued disk write is
///     lost on a hard kill). The dismiss action's own Hive write still runs
///     afterwards as the primary path; this ledger is the parachute.
///   * **Read + cleared natively by Kotlin** (`MainActivity` answers
///     `getPendingDismissals` / `clearPendingDismissals` on the alarm-routing
///     channel with plain synchronous `java.io.File` ops — the directory is
///     `context.filesDir`, the exact native dir `path_provider` maps
///     `getApplicationSupportDirectory()` to on Android).
///   * **Replayed into Hive on boot** ([ackPendingDismissalsInHive]) before
///     the first reconcile and before any wake-route decision, then cleared.
///     Replay-then-clear ordering makes a crash between the two re-replay on
///     the next boot — idempotent — rather than ever losing a dismissal.
///
/// Why a file and not literal `SharedPreferences`: the Dismiss action's
/// BroadcastReceiver is flutter_local_notifications' own compiled
/// `ActionBroadcastReceiver` — no Rostrik Kotlin runs before the engine
/// spawn without forking the plugin. From the engine's first instruction,
/// the synchronous file write is the most durable native store available,
/// and it is the one store both the headless engine AND Kotlin can touch
/// with zero new dependencies.
const String pendingDismissalsFileName = 'pending_dismissals';

/// The ledger file inside [appSupportDir] (Android: `context.filesDir`).
File pendingDismissalsFileIn(Directory appSupportDir) =>
    File('${appSupportDir.path}/$pendingDismissalsFileName');

/// Appends [shiftId] to the ledger with a SYNCHRONOUS, flushed write — the
/// whole point is that the data is in the kernel before the OS can reap the
/// isolate. The `NONE` sentinel (shift-less one-time/weekly alarms) is never
/// recorded: there is no shift row to acknowledge, and a sentinel entry
/// could not be mapped back to a single alarm occurrence.
void markPendingDismissal(Directory appSupportDir, String shiftId) {
  if (shiftId.isEmpty || shiftId == noShiftPayloadSentinel) return;
  pendingDismissalsFileIn(appSupportDir).writeAsStringSync(
    '$shiftId\n',
    mode: FileMode.append,
    flush: true,
  );
}

/// Reads the ledger — trimmed, blank lines dropped, de-duplicated (rapid
/// double-taps append twice; the replay must ack once). Missing file or any
/// read error reads as "nothing pending" rather than throwing: this runs on
/// the boot path and a corrupt ledger must never block app start.
List<String> readPendingDismissals(Directory appSupportDir) {
  final file = pendingDismissalsFileIn(appSupportDir);
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

/// Deletes the ledger. Best-effort — called only AFTER the Hive replay has
/// landed, so a failed delete merely re-replays (idempotently) next boot.
void clearPendingDismissals(Directory appSupportDir) {
  try {
    final file = pendingDismissalsFileIn(appSupportDir);
    if (file.existsSync()) file.deleteSync();
  } catch (_) {
    // Harmless: the replay is idempotent.
  }
}

/// Replays native-store dismissals into Hive: each shift in [shiftIds] is
/// marked `isAcknowledged` (clearing any pending snooze — Dismiss means
/// fully handled), exactly what the background isolate would have written
/// had it survived. Returns how many shifts were actually updated.
///
/// Idempotent and tolerant by design: sentinel/empty ids, vanished shifts,
/// and already-acknowledged shifts are all skipped — replaying the same
/// ledger twice writes nothing the second time.
Future<int> ackPendingDismissalsInHive({
  required ShiftRepository shifts,
  required List<String> shiftIds,
}) async {
  var acked = 0;
  for (final id in shiftIds) {
    if (id.isEmpty || id == noShiftPayloadSentinel) continue;
    final shift = await shifts.getById(id);
    if (shift == null || shift.isAcknowledged) continue;
    await shifts.upsert(
      shift.copyWith(isAcknowledged: true, clearSnoozedUntil: true),
    );
    acked++;
  }
  return acked;
}
