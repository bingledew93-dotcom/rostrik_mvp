import 'package:flutter/foundation.dart';

import '../data/models/shift_type.dart';

/// One positional block inside a custom (non-preset) roster.
///
/// Distinct from [RotationBlock] in `rotation_pattern.dart`:
///
///   * [RotationBlock] is **sequential** — `consecutiveDays` is a count,
///     blocks lay out one after another along the cycle and never share
///     a day. That's what the curated `kDayPatterns` / `kNightPatterns`
///     / `kRotatingPatterns` lists need.
///   * [ShiftBlock] is **positional** — `startDayIndex`/`endDayIndex` are
///     0-indexed positions WITHIN the cycle, inclusive. Two blocks can
///     share the same day position, which is what the custom builder
///     needs to express same-day split shifts (06:00–10:00 plus
///     15:00–19:00 on the same cycle day).
///
/// `startMinutes` / `endMinutes` are minute-of-day (0..1439), same shape
/// the [Shift] model uses. For [ShiftType.off] both are ignored at
/// expansion time (the resulting Shift gets 0/0).
@immutable
class ShiftBlock {
  const ShiftBlock({
    required this.type,
    required this.startDayIndex,
    required this.endDayIndex,
    required this.startMinutes,
    required this.endMinutes,
  });

  final ShiftType type;
  final int startDayIndex;
  final int endDayIndex;
  final int startMinutes;
  final int endMinutes;

  ShiftBlock copyWith({
    ShiftType? type,
    int? startDayIndex,
    int? endDayIndex,
    int? startMinutes,
    int? endMinutes,
  }) =>
      ShiftBlock(
        type: type ?? this.type,
        startDayIndex: startDayIndex ?? this.startDayIndex,
        endDayIndex: endDayIndex ?? this.endDayIndex,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftBlock &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          startDayIndex == other.startDayIndex &&
          endDayIndex == other.endDayIndex &&
          startMinutes == other.startMinutes &&
          endMinutes == other.endMinutes;

  @override
  int get hashCode => Object.hash(
        type,
        startDayIndex,
        endDayIndex,
        startMinutes,
        endMinutes,
      );

  @override
  String toString() =>
      'ShiftBlock(type: $type, day $startDayIndex..$endDayIndex, '
      'time $startMinutes..$endMinutes)';
}
