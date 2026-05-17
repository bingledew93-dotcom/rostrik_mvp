import 'package:flutter/foundation.dart';

import '../data/models/cycle_block.dart';
import '../data/models/shift_type.dart';

/// Result of resolving which [CycleBlock] covers a target date in an
/// anchored cycle. Carries enough context for the caller to build a
/// `Shift` (block.type + block.startMinutes/endMinutes), format a
/// "Day 3 of 4 — Day shift" label, or compute an offset-based alarm
/// fire time within the block.
@immutable
class CycleResolution {
  const CycleResolution({
    required this.block,
    required this.blockIndex,
    required this.dayWithinBlock,
    required this.dayWithinCycle,
  });

  final CycleBlock block;

  /// Index of [block] within the cycle's `blocks` list (0-based).
  final int blockIndex;

  /// 0-based offset inside [block]. Range: `0 .. block.consecutiveDays - 1`.
  final int dayWithinBlock;

  /// 0-based offset inside the full cycle. Range: `0 .. cycleLength - 1`.
  final int dayWithinCycle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleResolution &&
          runtimeType == other.runtimeType &&
          block == other.block &&
          blockIndex == other.blockIndex &&
          dayWithinBlock == other.dayWithinBlock &&
          dayWithinCycle == other.dayWithinCycle;

  @override
  int get hashCode =>
      Object.hash(block, blockIndex, dayWithinBlock, dayWithinCycle);

  @override
  String toString() => 'CycleResolution(block: $block, '
      'blockIndex: $blockIndex, dayWithinBlock: $dayWithinBlock, '
      'dayWithinCycle: $dayWithinCycle)';
}

/// Resolves which [CycleBlock] (and the offset inside it) covers
/// [target] for the given anchor + ordered blocks.
///
/// Bidirectionally infinite: dates *before* [anchor] wrap correctly via
/// `((diff % len) + len) % len`, so a user who picks "today is Day 1"
/// gets a meaningful answer for yesterday too (it lands on the last
/// block of the previous cycle).
///
/// Returns `null` only when [blocks] is empty (an invalid cycle config).
///
/// DST safety: day diff is computed via calendar-math reconstruction of
/// midnight on both dates rather than `target.difference(anchor).inDays`,
/// which would round across DST boundaries by ±1.
CycleResolution? resolveShiftBlockForDate({
  required DateTime target,
  required DateTime anchor,
  required List<CycleBlock> blocks,
}) {
  if (blocks.isEmpty) return null;
  final cycleLen = blocks.fold<int>(0, (n, b) => n + b.consecutiveDays);
  if (cycleLen <= 0) return null;

  final diff = _calendarDayDiff(anchor, target);
  // Dart's int `%` returns a non-negative remainder for positive
  // divisors, so `diff % cycleLen` is already in `[0, cycleLen)` even
  // when diff < 0. The `+ cycleLen) % cycleLen` belt-and-braces guards
  // against a future refactor to BigInt / Duration / a custom `%` that
  // returns the truncated-toward-zero remainder (which CAN be negative).
  final dayWithinCycle = ((diff % cycleLen) + cycleLen) % cycleLen;

  var running = 0;
  for (var i = 0; i < blocks.length; i++) {
    final b = blocks[i];
    if (b.consecutiveDays <= 0) continue;
    final next = running + b.consecutiveDays;
    if (dayWithinCycle < next) {
      return CycleResolution(
        block: b,
        blockIndex: i,
        dayWithinBlock: dayWithinCycle - running,
        dayWithinCycle: dayWithinCycle,
      );
    }
    running = next;
  }
  // Unreachable while cycleLen > 0 (guarded above) and all
  // consecutiveDays values are non-negative. Returning null is the
  // defensive fall-through for a malformed `blocks` list (e.g. every
  // block has 0 days). Callers already handle null for empty input.
  return null;
}

/// Sugar for callers that only want the ShiftType. Equivalent to
/// `resolveShiftBlockForDate(...).block.type` with null propagation.
ShiftType? resolveShiftTypeForDate({
  required DateTime target,
  required DateTime anchor,
  required List<CycleBlock> blocks,
}) =>
    resolveShiftBlockForDate(
      target: target,
      anchor: anchor,
      blocks: blocks,
    )?.block.type;

/// Whole-calendar-day difference `target - from`, computed by reducing
/// both dates to midnight and dividing the absolute-time delta by 24h.
/// Avoids `Duration.inDays` on raw DateTimes, which rounds wrong across
/// DST boundaries (a "1 day apart" pair separated by spring-forward is
/// 23h absolute; `.inDays` returns 0).
///
/// Negative when [target] is before [from].
int _calendarDayDiff(DateTime from, DateTime target) {
  final f = DateTime.utc(from.year, from.month, from.day);
  final t = DateTime.utc(target.year, target.month, target.day);
  // UTC midnight dates have no DST — the delta is always an exact
  // multiple of 24h, so .inDays is safe and exact here.
  return t.difference(f).inDays;
}
