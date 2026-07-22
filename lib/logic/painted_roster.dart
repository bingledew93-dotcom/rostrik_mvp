import 'package:flutter/foundation.dart';

import '../data/models/cycle_block.dart';
import '../data/models/shift_type.dart';

/// One shift "painted" onto a set of cycle-day positions — the data the
/// redesigned roster builder collects per "Add Shift Block".
///
/// Unlike the legacy positional [ShiftBlock] (contiguous
/// `startDayIndex..endDayIndex`), a painted block owns an arbitrary SET of
/// 0-based day positions, so a worker can tap days 0,1,2 AND 7,8,9 for the same
/// Day shift in one block. The builder guarantees each day position belongs to
/// at most ONE block (a day already claimed by another block isn't selectable),
/// so there are never same-day split shifts to fold — every position resolves
/// to exactly one shift or Off.
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

/// Folds the builder's [blocks] into the sequential [CycleBlock] list the
/// anchored generator + modulo resolver consume.
///
/// For each cycle position `0..cycleLength-1`:
///   * the block whose [PaintedShiftBlock.dayIndices] contains it supplies the
///     (type, start, end) — the builder enforces at-most-one, but if two ever
///     claimed the same day the FIRST in [blocks] wins (deterministic);
///   * an un-painted position resolves to an OFF day (0/0 times).
/// Consecutive positions with an identical (type, start, end) merge into one
/// [CycleBlock] run, so the resolver's "Day 3 of 4" reads naturally.
///
/// Pure (no Flutter, no Hive) so it unit-tests directly. Returns an unmodifiable
/// list; [cycleLength] must be positive.
List<CycleBlock> foldPaintedBlocks(
  int cycleLength,
  List<PaintedShiftBlock> blocks,
) {
  assert(cycleLength > 0, 'cycleLength must be positive');
  final merged = <CycleBlock>[];
  for (var pos = 0; pos < cycleLength; pos++) {
    PaintedShiftBlock? hit;
    for (final b in blocks) {
      if (b.dayIndices.contains(pos)) {
        hit = b;
        break;
      }
    }
    final type = hit?.type ?? ShiftType.off;
    final start = hit?.startMinutes ?? 0;
    final end = hit?.endMinutes ?? 0;
    if (merged.isNotEmpty &&
        merged.last.type == type &&
        merged.last.startMinutes == start &&
        merged.last.endMinutes == end) {
      merged[merged.length - 1] = merged.last.copyWith(
        consecutiveDays: merged.last.consecutiveDays + 1,
      );
    } else {
      merged.add(CycleBlock(
        type: type,
        consecutiveDays: 1,
        startMinutes: start,
        endMinutes: end,
      ));
    }
  }
  return List<CycleBlock>.unmodifiable(merged);
}

/// The set of cycle-day positions already claimed across [blocks] — what the
/// paintbrush grid greys out (and forbids) so each day maps to one shift.
/// [exclude] omits the block currently being edited so its own days stay
/// tappable.
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
