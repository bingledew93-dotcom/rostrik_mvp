import '../data/models/shift.dart';
import '../data/models/shift_type.dart';
import 'rotation_pattern.dart';
import 'shift_block.dart';

/// Validates a [RotationPattern]'s structural shape — empty pattern, zero-
/// day blocks, zero-duration work blocks, out-of-range minute fields.
///
/// Returns human-readable error strings; an empty list means "valid".
/// Surfaced verbatim in the picker's SnackBar on failure, so phrasing
/// matters: each message reads as a sentence to a user, not a developer.
///
/// The "two blocks on the same cycle day" overlap check the task brief
/// describes is structurally vacuous against this codebase's linear
/// [RotationBlock] model — blocks lay out sequentially across the
/// cycle, so they cannot share a day. [timeIntervalsOverlap] is exposed
/// anyway for the actually-useful application: catching same-date
/// conflicts at SHIFT-generation time, when an in-flight new pattern
/// could overlap an existing one already in the roster.
List<String> validateRotationPattern(RotationPattern pattern) {
  final errors = <String>[];
  if (pattern.blocks.isEmpty) {
    errors.add('Pattern has no blocks.');
    return errors;
  }
  for (var i = 0; i < pattern.blocks.length; i++) {
    final b = pattern.blocks[i];
    final label = 'Block ${i + 1}';
    if (b.consecutiveDays <= 0) {
      errors.add('$label has zero or negative days.');
    }
    if (b.startMinutes < 0 || b.startMinutes >= 1440) {
      errors.add('$label start time is out of range.');
    }
    if (b.endMinutes < 0 || b.endMinutes >= 1440) {
      errors.add('$label end time is out of range.');
    }
    if (b.type != ShiftType.off && b.startMinutes == b.endMinutes) {
      // A zero-length work block expands into shifts with `startMinutes ==
      // endMinutes`, which `Shift.isOvernight` treats as overnight (the
      // `<=` branch) but with `durationMinutes == 1440` — clearly a bug.
      // Catch it here rather than at shift-fired time.
      errors.add('$label has the same start and end time.');
    }
  }
  return errors;
}

/// Standard half-open interval overlap: `[aStart, aEnd)` vs `[bStart, bEnd)`.
/// Touching ranges (aEnd == bStart) do NOT overlap — a 14:00–18:00 shift
/// can sit right next to an 18:00–22:00 shift without conflict.
///
/// Caller responsibility: same-date framing. Two shifts on different
/// calendar days never overlap regardless of what this returns.
bool timeIntervalsOverlap(int aStartMin, int aEndMin, int bStartMin, int bEndMin) {
  return aStartMin < bEndMin && aEndMin > bStartMin;
}

/// Pairs of shifts on the same calendar date whose time intervals
/// overlap by [timeIntervalsOverlap]. OFF shifts are skipped (they have
/// no time range to conflict with). Overnight shifts are normalised
/// onto the start date with an end of `startMinutes + durationMinutes`
/// — i.e. an overnight shift's tail does NOT compare against the next
/// day's shifts via this function. Catching cross-day overnight
/// conflicts is a separate problem deferred until the model warrants it.
List<(Shift a, Shift b)> findTimeOverlaps(Iterable<Shift> shifts) {
  // Group by normalised date so we only do O(k^2) inside each bucket,
  // where k is the shift count per day — typically 1–2.
  final byDate = <DateTime, List<Shift>>{};
  for (final s in shifts) {
    if (s.type == ShiftType.off) continue;
    (byDate[s.date] ??= []).add(s);
  }
  final out = <(Shift, Shift)>[];
  for (final bucket in byDate.values) {
    if (bucket.length < 2) continue;
    for (var i = 0; i < bucket.length; i++) {
      final a = bucket[i];
      final aStart = a.startMinutes;
      final aEnd = a.startMinutes + a.durationMinutes;
      for (var j = i + 1; j < bucket.length; j++) {
        final b = bucket[j];
        final bStart = b.startMinutes;
        final bEnd = b.startMinutes + b.durationMinutes;
        if (timeIntervalsOverlap(aStart, aEnd, bStart, bEnd)) {
          out.add((a, b));
        }
      }
    }
  }
  return out;
}

/// Thrown by `ShiftGenerator` when a Generate request would either
/// produce a structurally invalid pattern or land same-date conflicts
/// against the existing roster. UI catches this and surfaces [message]
/// in a SnackBar; no shifts or cycle are written.
class RosterGenerationException implements Exception {
  RosterGenerationException(this.message);
  final String message;

  @override
  String toString() => 'RosterGenerationException: $message';
}

/// Structural validation for the custom-builder path. Same return shape
/// as [validateRotationPattern] (list of human-readable errors; empty
/// means valid), so the picker UI can render either with the same
/// SnackBar plumbing.
///
/// Intra-cycle time-overlap rejection is NOT done here — multiple
/// [ShiftBlock]s on the same cycle day are explicitly allowed (that's
/// what enables split shifts). Time-overlap detection runs downstream
/// against the EXPANDED shifts via [findTimeOverlaps], where overnight
/// shifts are normalised and the cross-day shape is correct.
List<String> validateCustomRoster(
  int cycleLengthDays,
  List<ShiftBlock> blocks,
) {
  final errors = <String>[];
  if (cycleLengthDays <= 0) {
    errors.add('Cycle length must be at least 1 day.');
    return errors;
  }
  if (blocks.isEmpty) {
    errors.add('Add at least one block to the roster.');
    return errors;
  }
  for (var i = 0; i < blocks.length; i++) {
    final b = blocks[i];
    final label = 'Block ${i + 1}';
    if (b.startDayIndex < 0 || b.startDayIndex >= cycleLengthDays) {
      errors.add('$label start day is out of the cycle range.');
    }
    if (b.endDayIndex < 0 || b.endDayIndex >= cycleLengthDays) {
      errors.add('$label end day is out of the cycle range.');
    }
    if (b.startDayIndex > b.endDayIndex) {
      errors.add('$label end day is before its start day.');
    }
    if (b.startMinutes < 0 || b.startMinutes >= 1440) {
      errors.add('$label start time is out of range.');
    }
    if (b.endMinutes < 0 || b.endMinutes >= 1440) {
      errors.add('$label end time is out of range.');
    }
    if (b.type != ShiftType.off && b.startMinutes == b.endMinutes) {
      errors.add('$label has the same start and end time.');
    }
  }
  return errors;
}
