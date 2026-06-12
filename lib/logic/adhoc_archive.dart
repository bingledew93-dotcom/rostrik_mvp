import '../data/models/shift.dart';
import '../data/repositories/shift_repository.dart';

/// Grace window after an ad-hoc shift's END before the init-time sweep archives
/// it. Deliberately non-zero so a shift the user is still working — or only just
/// finished — is never archived out from under the live UI.
const Duration kAdHocArchiveGrace = Duration(hours: 24);

/// Self-cleaning sweep for Phase-3 ad-hoc shifts. ARCHIVES (never deletes)
/// every ad-hoc shift whose end is more than [grace] in the past, keeping the
/// active roster/alarm set lean as one-off shifts accumulate.
///
/// **Archive, not delete — by design.** Shifts are immutable history: the
/// calendar is the record shift workers verify payslips against, and ad-hoc
/// shifts are explicitly backfillable a year into the past. A delete-on-a-timer
/// would erase exactly those records. Instead we flip [Shift.isArchived], so the
/// alarm engine drops the shift from its active desired set while the record
/// stays in Hive and keeps rendering in the historical timeline.
///
/// **Keyed strictly on [Shift.isAdHoc]** — never `cycleId` — so only
/// user-inserted one-off shifts are ever touched; rotation shifts are the
/// permanent roster and are left alone regardless of age.
///
/// **Idempotent.** Already-archived shifts are skipped, so running this on every
/// cold start is a no-op once steady state is reached. Returns the number of
/// shifts archived on THIS pass.
///
/// Past-by-construction safety: an archived shift ended >[grace] ago, so its
/// alarm fire time is already behind `now` and the engine would skip it anyway —
/// archiving never disarms a live alarm. Writes go through [ShiftRepository.upsert]
/// so the change persists and (harmlessly) flows through the normal shift stream.
Future<int> archiveExpiredAdHocShifts(
  ShiftRepository shifts, {
  required DateTime now,
  Duration grace = kAdHocArchiveGrace,
}) async {
  final cutoff = now.subtract(grace);
  final all = await shifts.getAll();
  var archived = 0;
  for (final shift in all) {
    if (!shift.isAdHoc) continue; // never touch rotation shifts
    if (shift.isArchived) continue; // idempotent — already swept
    // `endDateTime` already resolves the overnight (+1 day) case.
    if (!shift.endDateTime.isBefore(cutoff)) continue; // within grace — keep
    await shifts.upsert(shift.copyWith(isArchived: true));
    archived++;
  }
  return archived;
}
