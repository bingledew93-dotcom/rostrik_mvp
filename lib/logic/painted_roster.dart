import 'package:flutter/foundation.dart';

import '../data/models/shift_type.dart';
import 'shift_block.dart';

/// One shift "painted" onto a set of cycle-day positions — the data the
/// redesigned roster builder collects per "Add Shift Block".
///
/// A painted block owns an arbitrary SET of 0-based day positions, so a worker
/// can tap days 0,1,2 AND 7,8,9 for the same Day shift in one block. Two blocks
/// MAY cover the same day — that's a split shift (e.g. a morning block plus an
/// evening block on the same cycle day); the generator rejects only blocks
/// whose TIMES overlap on a shared day.
@immutable
class PaintedShiftBlock {
  const PaintedShiftBlock({
    required this.type,
    required this.startMinutes,
    required this.endMinutes,
    required this.dayIndices,
  });

  /// Never [ShiftType.off] — Off is the ABSENCE of a block (any un-painted day
  /// resolves to Off), so it is never an explicit block the user adds.
  final ShiftType type;
  final int startMinutes;
  final int endMinutes;

  /// 0-based cycle-day positions this block paints (0..cycleLength-1).
  final Set<int> dayIndices;

  PaintedShiftBlock copyWith({
    ShiftType? type,
    int? startMinutes,
    int? endMinutes,
    Set<int>? dayIndices,
  }) =>
      PaintedShiftBlock(
        type: type ?? this.type,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
        dayIndices: dayIndices ?? this.dayIndices,
      );
}

/// Flattens the builder's painted [blocks] into the positional [ShiftBlock]
/// list the generator materialises — one single-day [ShiftBlock] per painted
/// day. Two painted blocks that share a day therefore become two same-position
/// ShiftBlocks, i.e. a SPLIT SHIFT (both materialise on that calendar day). The
/// generator's time-overlap validator is what forbids a split whose times
/// actually clash; non-overlapping splits (morning + evening) pass.
///
/// Per-day (not compressed to ranges) keeps this trivially correct — the
/// generator's own `_foldCustomBlocksToCycleBlocks` re-merges consecutive
/// identical days for the anchored projection anyway. Pure/testable.
List<ShiftBlock> paintedBlocksToShiftBlocks(List<PaintedShiftBlock> blocks) {
  final out = <ShiftBlock>[];
  for (final b in blocks) {
    for (final day in b.dayIndices) {
      out.add(ShiftBlock(
        type: b.type,
        startDayIndex: day,
        endDayIndex: day,
        startMinutes: b.startMinutes,
        endMinutes: b.endMinutes,
      ));
    }
  }
  return out;
}

/// The set of cycle-day positions covered by other [blocks] — the paintbrush
/// grid marks these as "already has a shift" so the user knows a tap there
/// creates a SPLIT (rather than locking them out). [exclude] omits the block
/// currently being edited so its own days aren't flagged against itself.
Set<int> claimedDayIndices(
  List<PaintedShiftBlock> blocks, {
  PaintedShiftBlock? exclude,
}) {
  final claimed = <int>{};
  for (final b in blocks) {
    if (identical(b, exclude)) continue;
    claimed.addAll(b.dayIndices);
  }
  return claimed;
}

/// Whether [blocks] paint at least one working day — the guard the builder's
/// "Create Roster" uses (an all-Off roster would arm no alarms and is almost
/// certainly a mistake).
bool hasAnyPaintedDay(List<PaintedShiftBlock> blocks) =>
    blocks.any((b) => b.dayIndices.isNotEmpty);

/// "1–3, 8, 10–12" — compresses a set of 0-based day positions into 1-based
/// human ranges for a block summary. Empty → "—". Pure/testable.
String formatDayIndexRanges(Set<int> days) {
  if (days.isEmpty) return '—';
  final sorted = days.toList()..sort();
  final parts = <String>[];
  var runStart = sorted.first;
  var prev = sorted.first;
  for (var i = 1; i <= sorted.length; i++) {
    final atEnd = i == sorted.length;
    if (!atEnd && sorted[i] == prev + 1) {
      prev = sorted[i];
      continue;
    }
    // 1-based for display.
    parts.add(runStart == prev ? '${runStart + 1}' : '${runStart + 1}–${prev + 1}');
    if (!atEnd) {
      runStart = sorted[i];
      prev = sorted[i];
    }
  }
  return parts.join(', ');
}
