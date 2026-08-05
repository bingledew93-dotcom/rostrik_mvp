import '../data/models/shift.dart';
import '../data/models/shift_type.dart';

/// Filename for the work-history CSV export — the name the native share sheet
/// surfaces (email attachment / Drive upload).
const String kWorkHistoryCsvFilename = 'rostrik_work_history.csv';

/// Header row for the work-history CSV. Kept as a constant so the export and
/// its tests reference one source of truth.
const String kWorkHistoryCsvHeader =
    'Date,Start Time,End Time,Total Hours,Shift Type,Status';

/// CSV / badge label for a regular rostered shift.
const String kRotationShiftLabel = 'Rotation';

/// CSV / badge label for a one-off ("Add Custom Shift") shift — i.e. overtime
/// the user picked up. The label the export uses so a payslip-checker can
/// filter overtime in one spreadsheet click.
const String kAdHocShiftLabel = 'Ad-Hoc';

/// Human label for a shift's provenance — `Ad-Hoc` for a one-off, `Rotation`
/// for a rostered shift. Shared by the CSV's "Shift Type" column and the
/// on-screen badge so the two never diverge.
String workHistoryShiftTypeLabel(Shift s) =>
    s.isAdHoc ? kAdHocShiftLabel : kRotationShiftLabel;

/// Minutes counted toward PAYROLL: ZERO for a paused shift — the user didn't
/// work it (sick / leave / holiday) even though the record is still shown —
/// otherwise the shift's full duration. The single source of truth the CSV's
/// "Total Hours", the per-tile hours, and the summary total all use, so a
/// paused day can never inflate hours worked.
int workedMinutes(Shift s) => s.isPaused ? 0 : s.durationMinutes;

/// CSV "Status" value: `Active` for a normal shift, or `Paused: <reason>`
/// (just `Paused` when there's no reason) for a paused one. Free text, so the
/// CSV writer escapes it ([_csvField]).
String workHistoryStatus(Shift s) {
  if (!s.isPaused) return 'Active';
  final reason = s.pauseReason?.trim();
  return (reason == null || reason.isEmpty) ? 'Paused' : 'Paused: $reason';
}

/// The user's completed work history for payslip verification: **every** shift
/// that has already finished — rotation AND ad-hoc — oldest → newest. A partial
/// (ad-hoc-only) timesheet is a liability for payslip verification, so the full
/// roster is included; the CSV's "Shift Type" column lets the user split out
/// overtime themselves.
///
/// Scope decisions (documented because they shape what the user sees/exports):
///   * **Completed only** (`endDateTime` strictly before [now]) — a shift you
///     have not finished working can't be verified against a payslip. This
///     deliberately keys on *completed*, NOT `isArchived`: an ad-hoc shift that
///     ended in the last 24h has not yet been flipped to `isArchived` by the
///     cold-start sweep, and keying off "archived" alone would silently
///     truncate the current pay period. (Archived ⇒ completed; archived is a
///     strict subset.)
///   * **OFF days excluded** — a `ShiftType.off` entry has no hours to verify
///     and would just be 00:00–00:00 / 0.00h noise in the export.
///
/// Sorted ascending by absolute start instant (then start-of-day) — natural
/// ledger order for a CSV. The screen reverses this for a newest-first view.
List<Shift> workHistoryShifts(List<Shift> all, {required DateTime now}) {
  final out = all
      .where((s) => s.type != ShiftType.off && s.endDateTime.isBefore(now))
      .toList()
    ..sort((a, b) {
      final byStart = a.startDateTime.compareTo(b.startDateTime);
      return byStart != 0 ? byStart : a.startMinutes.compareTo(b.startMinutes);
    });
  return out;
}

/// Total worked hours as a payroll-friendly 2dp decimal (e.g. 480 → "8.00",
/// 510 → "8.50"). Decimal hours map directly onto payslip pay math; the screen
/// shows the same value so what the user verifies on-screen matches the export.
String formatDecimalHours(int durationMinutes) =>
    (durationMinutes / 60).toStringAsFixed(2);

/// Renders [shifts] as a CSV string with columns
/// `Date,Start Time,End Time,Total Hours,Shift Type,Status`.
///
///   * Date is ISO `YYYY-MM-DD` — sorts and parses cleanly in any spreadsheet,
///     unlike the human "Mon, May 4" shown on screen.
///   * Times are 24-hour `HH:mm` — unambiguous for payroll (no AM/PM).
///   * Total Hours is decimal WORKED hours (see [workedMinutes] /
///     [formatDecimalHours]); a PAUSED shift is `0.00` so it never inflates pay.
///     The hours are overnight-aware via [Shift.durationMinutes].
///   * Shift Type is `Rotation` or `Ad-Hoc` (see [workHistoryShiftTypeLabel]) —
///     lets the user filter overtime out of their roster in one Excel click.
///   * Status is `Active`, or `Paused: <reason>` / `Paused` (see
///     [workHistoryStatus]).
///
/// CRLF line endings + a trailing newline for RFC-4180 / Excel friendliness.
/// The Status field carries a free-text pause reason, so every field is run
/// through RFC-4180 [_csvField] escaping (comma/quote-safe). An empty [shifts]
/// yields the header alone.
String workHistoryCsv(List<Shift> shifts) {
  final rows = <String>[kWorkHistoryCsvHeader];
  for (final s in shifts) {
    rows.add(
      [
        _csvDate(s.date),
        _csvTime(s.startMinutes),
        _csvTime(s.endMinutes),
        formatDecimalHours(workedMinutes(s)),
        workHistoryShiftTypeLabel(s),
        workHistoryStatus(s),
      ].map(_csvField).join(','),
    );
  }
  return '${rows.join('\r\n')}\r\n';
}

/// RFC-4180 field escaping: when a value contains a comma, double-quote, or
/// newline, wrap it in double-quotes and double any internal quotes. Idempotent
/// for the safe columns; load-bearing for the free-text Status reason.
String _csvField(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// ISO `YYYY-MM-DD` (zero-padded). [Shift.date] is already midnight-normalised.
String _csvDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 24-hour `HH:mm` from a minutes-of-day value (0..1439).
String _csvTime(int minutesOfDay) =>
    '${(minutesOfDay ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutesOfDay % 60).toString().padLeft(2, '0')}';
