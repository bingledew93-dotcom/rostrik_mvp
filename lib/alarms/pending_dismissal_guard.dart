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
/// The fail-safe is a flat ledger file (`pending_dismissals`) in the app's
/// native files directory. **One line per dismissed ALARM OCCURRENCE**:
///
/// ```
///   <shiftId>|<appAlarmId>
/// ```
///
/// The appAlarmId is what makes the dismissal SURGICAL: a shift can have
/// several linked alarms (a 60-min lead, a 30-min lead, an exact-time ring),
/// and dismissing the first must resolve only that ring — never disarm the
/// siblings. The replay records the id in [Shift.dismissedAlarmIds]; the
/// projection then drops exactly that ring. A LEGACY bare `<shiftId>` line
/// (written by an older build, or a fire intent that predates the
/// appAlarmId extra) has no alarm identity to target, so it degrades to the
/// old whole-shift `isAcknowledged` ack — conservative, but never silent.
///
/// Both ids are `|`-free by the payload contract, so the split is safe.
///
///   * **Written natively by [AlarmActivity] / [AlarmAudioService]** with a
///     SYNCHRONOUS kernel write (append + flush + fsync). Once that syscall
///     returns the data survives process death unconditionally
///     (commit()-grade durability — stronger than
///     `SharedPreferences.apply()`, whose queued disk write is lost on a
///     hard kill).
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
/// Why a file and not literal `SharedPreferences`: the dismiss happens in the
/// native `AlarmActivity` (Kotlin), which writes this ledger directly with a
/// synchronous flushed write — the most durable native store available, and the
/// one store both the native side AND the Dart isolates touch with zero new
/// dependencies.
const String pendingDismissalsFileName = 'pending_dismissals';

/// One parsed dismissal ledger entry. [appAlarmId] is the dismissed ring's
/// owning AppAlarm rule id, or '' for a legacy line with no alarm identity
/// (→ whole-shift ack).
class PendingDismissal {
  const PendingDismissal(this.shiftId, this.appAlarmId);

  final String shiftId;
  final String appAlarmId;

  /// Whether this entry can target a single ring. False → legacy blanket ack.
  bool get isTargeted => appAlarmId.isNotEmpty;
}

/// Parses one ledger line (`<shiftId>|<appAlarmId>` or legacy `<shiftId>`)
/// into a [PendingDismissal], or null for blank / sentinel / malformed lines.
/// Shared by the Dart file reader below AND the MethodChannel drain in
/// `main.dart`, so both ingestion paths decode identically.
PendingDismissal? parsePendingDismissalLine(String rawLine) {
  final line = rawLine.trim();
  if (line.isEmpty) return null;
  final parts = line.split('|');
  final shiftId = parts[0];
  if (shiftId.isEmpty || shiftId == noShiftPayloadSentinel) return null;
  final appAlarmId = parts.length > 1 ? parts[1] : '';
  return PendingDismissal(shiftId, appAlarmId);
}

/// The ledger file inside [appSupportDir] (Android: `context.filesDir`).
File pendingDismissalsFileIn(Directory appSupportDir) =>
    File('${appSupportDir.path}/$pendingDismissalsFileName');

/// Appends one occurrence's dismissal with a SYNCHRONOUS, flushed write — the
/// whole point is that the data is in the kernel before the OS can reap the
/// isolate. Pass the ring's owning [appAlarmId] whenever it is known: that is
/// what keeps the dismissal scoped to ONE ring. The `NONE` sentinel
/// (shift-less one-time/weekly alarms) is never recorded: there is no shift
/// row to acknowledge, and a sentinel entry could not be mapped back to a
/// single alarm occurrence.
void markPendingDismissal(
  Directory appSupportDir,
  String shiftId, {
  String appAlarmId = '',
}) {
  if (shiftId.isEmpty || shiftId == noShiftPayloadSentinel) return;
  final line = appAlarmId.isEmpty ? shiftId : '$shiftId|$appAlarmId';
  pendingDismissalsFileIn(appSupportDir).writeAsStringSync(
    '$line\n',
    mode: FileMode.append,
    flush: true,
  );
}

/// Reads the ledger — parsed, blank/sentinel lines dropped, de-duplicated
/// (rapid double-taps append twice; the replay must ack once). Missing file or
/// any read error reads as "nothing pending" rather than throwing: this runs
/// on the boot path and a corrupt ledger must never block app start.
List<PendingDismissal> readPendingDismissals(Directory appSupportDir) {
  final file = pendingDismissalsFileIn(appSupportDir);
  try {
    if (!file.existsSync()) return const [];
    final seen = <String>{};
    final out = <PendingDismissal>[];
    for (final raw in file.readAsLinesSync()) {
      final parsed = parsePendingDismissalLine(raw);
      if (parsed == null) continue;
      if (!seen.add('${parsed.shiftId}|${parsed.appAlarmId}')) continue;
      out.add(parsed);
    }
    return out;
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

/// Replays native-store dismissals into Hive — exactly the write the reaped
/// isolate would have made. Returns how many shifts were actually updated.
///
/// **Targeted entry** (`shiftId|appAlarmId`) → appends the alarm rule id to
/// [Shift.dismissedAlarmIds]. Only that ring is suppressed; sibling alarms on
/// the same shift keep firing, which is the whole point of the per-occurrence
/// ledger. `snoozedUntil` is deliberately LEFT ALONE: it may belong to a
/// sibling's still-active snooze, and the projection suppresses the dismissed
/// ring before the snooze pin regardless, so a stale value can never
/// resurrect it.
///
/// **Legacy entry** (bare `shiftId`, no alarm identity) → the old whole-shift
/// `isAcknowledged` ack, clearing any pending snooze (dismiss-all is final).
///
/// Idempotent and tolerant by design: sentinel/empty ids, vanished shifts,
/// already-acknowledged shifts and already-recorded rings are all skipped —
/// replaying the same ledger twice writes nothing the second time.
Future<int> ackPendingDismissalsInHive({
  required ShiftRepository shifts,
  required List<PendingDismissal> dismissals,
}) async {
  var acked = 0;
  for (final d in dismissals) {
    if (d.shiftId.isEmpty || d.shiftId == noShiftPayloadSentinel) continue;
    final shift = await shifts.getById(d.shiftId);
    if (shift == null || shift.isAcknowledged) continue;
    if (d.isTargeted) {
      if (shift.dismissedAlarmIds.contains(d.appAlarmId)) continue;
      await shifts.upsert(shift.copyWith(
        dismissedAlarmIds: [...shift.dismissedAlarmIds, d.appAlarmId],
      ));
    } else {
      await shifts.upsert(
        shift.copyWith(isAcknowledged: true, clearSnoozedUntil: true),
      );
    }
    acked++;
  }
  return acked;
}
