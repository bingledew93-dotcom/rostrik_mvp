import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import 'shift_type.dart';

part 'cycle_block.g.dart';

/// One contiguous run of same-type shifts inside an anchored
/// [ShiftCycle]. Sequential — block N starts on the calendar day after
/// block N-1 ends. Modulo arithmetic on `(target - anchor) % cycleLen`
/// picks the active block for any date past or future.
///
/// Structurally identical to `RotationBlock` in `lib/logic/`, but kept
/// separate to preserve the data/logic split: `lib/data/` owns Hive
/// concerns, `lib/logic/` stays pure. Convert with [fromRotationBlock]
/// at the boundary if a [RotationPattern] preset needs persisting.
@HiveType(typeId: 7)
@immutable
class CycleBlock {
  const CycleBlock({
    required this.type,
    required this.consecutiveDays,
    this.startMinutes = 0,
    this.endMinutes = 0,
  });

  @HiveField(0)
  final ShiftType type;

  @HiveField(1)
  final int consecutiveDays;

  @HiveField(2)
  final int startMinutes;

  @HiveField(3)
  final int endMinutes;

  CycleBlock copyWith({
    ShiftType? type,
    int? consecutiveDays,
    int? startMinutes,
    int? endMinutes,
  }) =>
      CycleBlock(
        type: type ?? this.type,
        consecutiveDays: consecutiveDays ?? this.consecutiveDays,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleBlock &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          consecutiveDays == other.consecutiveDays &&
          startMinutes == other.startMinutes &&
          endMinutes == other.endMinutes;

  @override
  int get hashCode =>
      Object.hash(type, consecutiveDays, startMinutes, endMinutes);

  @override
  String toString() => 'CycleBlock(type: $type, '
      'consecutiveDays: $consecutiveDays, '
      'startMinutes: $startMinutes, endMinutes: $endMinutes)';
}
