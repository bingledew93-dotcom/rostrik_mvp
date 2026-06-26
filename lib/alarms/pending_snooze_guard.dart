import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/repositories/shift_repository.dart';
import 'alarm_sync_service.dart' show noShiftPayloadSentinel;
import 'one_off_snooze_store.dart';

/// Native snooze fail-safe ledger — the counterpart to
/// [pendingDismissalsFileName]. The native `AlarmActivity` Snooze button:
///   1. re-arms the SAME AlarmManager alarm 9 minutes out (reusing the original
///      notification id), and
///   2. appends `<shiftId>|<untilMillis>` to this file.
///
/// Step 2 is what lets Dart set [Shift.snoozedUntil] when it next runs — and,
/// crucially, BEFORE any reconcile. Without it a reconcile would see an
/// unacknowledged shift whose normal fire time is already past (so it has no
/// future ring), find the just-re-armed alarm's id is no longer desired, and
/// CANCEL it as a ledger orphan. With `snoozedUntil` set, `projectAlarmRings`
/// resurrects the ring at that instant, so the reconcile converges to exactly
/// one alarm: it REPLACES the native one in place (same-day, projection computes
/// the same id) or cancels + reschedules at the identical instant (cross-
/// midnight, projection computes a new id and the native id becomes the orphan).
const String pendingSnoozesFileName = 'pending_snoozes';

/// One parsed snooze ledger entry. [shiftId] drives shift-based snoozes
/// (→ `Shift.snoozedUntil`); [appAlarmId] drives shift-less 'NONE' alarms
/// (→ the one-off snooze map). Exactly one is meaningful per line.
class PendingSnooze {
  const PendingSnooze(this.shiftId, this.appAlarmId, this.until);
  final String shiftId;
  final String appAlarmId;
  final DateTime until;
}

File _pendingSnoozesFileIn(Directory appSupportDir) =>
    File('${appSupportDir.path}/$pendingSnoozesFileName');

/// Reads the ledger: trimmed, blank/malformed lines dropped. Any error reads as
/// "nothing pending" — this runs on the boot/resume path and a corrupt ledger
/// must never throw.
List<PendingSnooze> readPendingSnoozes(Directory appSupportDir) {
  final file = _pendingSnoozesFileIn(appSupportDir);
  try {
    if (!file.existsSync()) return const [];
    final out = <PendingSnooze>[];
    for (final raw in file.readAsLinesSync()) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      // Current: `<shiftId>|<appAlarmId>|<millis>` (ids are '|'-free by the
      // payload contract). Backward-tolerant: a legacy `<shiftId>|<millis>`
      // line (no appAlarmId) still parses as shift-only.
      final parts = line.split('|');
      final String shiftId;
      final String appAlarmId;
      final int? millis;
      if (parts.length >= 3) {
        shiftId = parts[0];
        appAlarmId = parts[1];
        millis = int.tryParse(parts[2]);
      } else if (parts.length == 2) {
        shiftId = parts[0];
        appAlarmId = '';
        millis = int.tryParse(parts[1]);
      } else {
        continue;
      }
      if (millis == null) continue;
      out.add(PendingSnooze(
        shiftId,
        appAlarmId,
        DateTime.fromMillisecondsSinceEpoch(millis),
      ));
    }
    return out;
  } catch (_) {
    return const [];
  }
}

/// Deletes the ledger. Best-effort — called only AFTER the Hive apply lands, so
/// a failed delete merely re-applies (idempotently) next time.
void clearPendingSnoozes(Directory appSupportDir) {
  try {
    final file = _pendingSnoozesFileIn(appSupportDir);
    if (file.existsSync()) file.deleteSync();
  } catch (_) {
    // Harmless: the apply is idempotent.
  }
}

/// Applies snoozes to Hive: each shift's [Shift.snoozedUntil] is set to the
/// LATEST future `until` recorded for it. Idempotent and tolerant:
///   * empty / 'NONE' shift ids are skipped — there's no shift row to update
///     (the native re-arm is the only snooze a shift-less alarm gets);
///   * a snooze already elapsed by [now] is skipped (the alarm has re-fired);
///   * an already-acknowledged (dismissed) shift is skipped — dismiss is final;
///   * a shift already at that exact `snoozedUntil` is skipped, so we never kick
///     the reconcile for a no-op write.
/// Returns how many shifts were updated.
Future<int> applyPendingSnoozesInHive({
  required ShiftRepository shifts,
  required List<PendingSnooze> snoozes,
  DateTime? now,
}) async {
  final clock = now ?? DateTime.now();

  // Collapse to the latest `until` per shift AND per one-off AppAlarm id — a
  // re-snooze appends a new line. A line is shift-based when its shiftId is a
  // real id (not empty / not the 'NONE' sentinel); otherwise it's one-off and
  // keyed by appAlarmId.
  final latestShift = <String, DateTime>{};
  final latestOneOff = <String, DateTime>{};
  for (final s in snoozes) {
    final isShift = s.shiftId.isNotEmpty && s.shiftId != noShiftPayloadSentinel;
    if (isShift) {
      final existing = latestShift[s.shiftId];
      if (existing == null || s.until.isAfter(existing)) {
        latestShift[s.shiftId] = s.until;
      }
    } else if (s.appAlarmId.isNotEmpty) {
      final existing = latestOneOff[s.appAlarmId];
      if (existing == null || s.until.isAfter(existing)) {
        latestOneOff[s.appAlarmId] = s.until;
      }
    }
  }

  var applied = 0;

  // Shift-based → Shift.snoozedUntil (skips elapsed, already-acknowledged, and
  // no-op writes so the reconcile isn't kicked for nothing).
  for (final entry in latestShift.entries) {
    if (!entry.value.isAfter(clock)) continue;
    final shift = await shifts.getById(entry.key);
    if (shift == null || shift.isAcknowledged) continue;
    if (shift.snoozedUntil == entry.value) continue;
    await shifts.upsert(shift.copyWith(snoozedUntil: entry.value));
    applied++;
  }

  // One-off ('NONE') → the settings-box one-off snooze map, keyed by AppAlarm id.
  // The reconciler reads this map and pins the alarm to its snooze instant, so
  // it isn't cancelled as an orphan inside the window.
  for (final entry in latestOneOff.entries) {
    if (!entry.value.isAfter(clock)) continue;
    await upsertOneOffSnooze(entry.key, entry.value, now: clock);
    applied++;
  }

  return applied;
}

/// Composes the path_provider hop + read + apply + clear. Shared by `main()`
/// (cold start + resume) AND the background-sync isolate, so all three contexts
/// drain the same way without depending on the alarm-routing MethodChannel
/// (which the headless background engine doesn't have).
///
/// Ordering is load-bearing: read → apply → clear, so a crash between apply and
/// clear re-applies (idempotently) rather than losing a snooze. Returns the
/// number of shifts updated.
Future<int> drainPendingSnoozesIntoHive(
  ShiftRepository shifts, {
  DateTime? now,
}) async {
  final Directory dir;
  try {
    dir = await getApplicationSupportDirectory();
  } catch (_) {
    return 0; // no platform dir (e.g. widget tests) — nothing to drain
  }
  final snoozes = readPendingSnoozes(dir);
  if (snoozes.isEmpty) return 0;
  final applied = await applyPendingSnoozesInHive(
    shifts: shifts,
    snoozes: snoozes,
    now: now,
  );
  clearPendingSnoozes(dir);
  return applied;
}
