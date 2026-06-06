import '../data/models/shift_type.dart';
import '../logic/shift_block.dart' as builder;
import 'shift_block.dart' as ocr;

/// Bridges the OCR layer's time-only [ocr.ShiftBlock]s to the Custom Roster
/// Builder's positional [builder.ShiftBlock]s.
///
/// The two types share a name but not a shape: the OCR block is a single
/// time (nullable end, optional type) read off one roster cell, whereas the
/// builder block is positioned on a cycle day. This is the only place the two
/// meet, so both are imported with prefixes.
///
/// Mapping rules:
///   * One scanned block → one builder block on its own sequential cycle day,
///     starting at `fromDayIndex` (so a scan/append lands the new cells right
///     after the existing ones). `startDayIndex == endDayIndex == day`.
///   * `type` defaults to [ShiftType.day] when the scan only found a time
///     (the image doesn't reveal the shift type for a bare time); the user
///     can re-classify it in the builder.
///   * A null end time (a single 24h/12h token) is materialised as
///     `endMinutes == startMinutes` — a deliberately INVALID zero-duration
///     placeholder. The builder detects that (`type != off && start == end`),
///     flags the card, and blocks Generate until the user sets a real end
///     ([validateCustomRoster] would reject it anyway). See [needsEndTime].
///   * An Off block keeps `0/0` and is never flagged (Off is valid at 0/0).
class ScannedRosterInjection {
  ScannedRosterInjection._();

  /// Maps a freshly-scanned sequence to builder blocks, one per sequential
  /// cycle day beginning at [fromDayIndex] (0 for a fresh scan, the current
  /// block count for an append).
  static List<builder.ShiftBlock> map(
    List<ocr.ShiftBlock> scanned, {
    int fromDayIndex = 0,
  }) {
    final out = <builder.ShiftBlock>[];
    for (var i = 0; i < scanned.length; i++) {
      out.add(_mapOne(scanned[i], fromDayIndex + i));
    }
    return out;
  }

  static builder.ShiftBlock _mapOne(ocr.ShiftBlock s, int dayIndex) {
    final type = s.type ?? ShiftType.day;
    if (type == ShiftType.off) {
      return builder.ShiftBlock(
        type: ShiftType.off,
        startDayIndex: dayIndex,
        endDayIndex: dayIndex,
        startMinutes: 0,
        endMinutes: 0,
      );
    }
    return builder.ShiftBlock(
      type: type,
      startDayIndex: dayIndex,
      endDayIndex: dayIndex,
      startMinutes: s.startMinutes,
      // Placeholder == start when the end is unknown; flagged by [needsEndTime].
      endMinutes: s.endMinutes ?? s.startMinutes,
    );
  }

  /// True when [block] still needs the user to supply an end time — i.e. a
  /// non-Off block left at the zero-duration placeholder. Shared by the
  /// builder (to flag the card + gate Generate) and the tests so the
  /// "incomplete" definition lives in exactly one place.
  static bool needsEndTime(builder.ShiftBlock block) =>
      block.type != ShiftType.off && block.startMinutes == block.endMinutes;
}
