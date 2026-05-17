import 'package:hive_ce/hive.dart';

import 'cycle_block.dart';

part 'shift_cycle.g.dart';

/// Parent record for a batch of [Shift]s emitted by `ShiftGenerator`.
///
/// Created once per pattern / template Generate; child shifts carry this
/// cycle's [id] in their `cycleId` field so `CycleService.deleteCycle`
/// can locate them without the cycle maintaining its own child list.
///
/// Lifetime: created on Generate, deleted only via cascade-delete from
/// the saved-rosters screen. Never edited — labels / dates are a
/// snapshot of the inputs at generation time.
@HiveType(typeId: 4)
class ShiftCycle {
  ShiftCycle({
    required this.id,
    required this.label,
    required this.summary,
    required DateTime startDate,
    required DateTime endDate,
    required this.createdAt,
    this.patternId,
    DateTime? anchorDate,
    this.blocks,
  })  : startDate = DateTime(startDate.year, startDate.month, startDate.day),
        endDate = DateTime(endDate.year, endDate.month, endDate.day),
        anchorDate = anchorDate == null
            ? null
            : DateTime(anchorDate.year, anchorDate.month, anchorDate.day);

  @HiveField(0)
  final String id;

  /// Short human-readable name. From `RotationPattern.label` on the
  /// pattern path, or `"<Type> block · <n> day(s)"` on the template path.
  @HiveField(1)
  final String label;

  /// One-line summary (e.g. "7 on / 7 off" or the generated block's
  /// time range). Surfaced on the cycles list card subtitle.
  @HiveField(2)
  final String summary;

  /// First generated calendar day (midnight). Inclusive.
  @HiveField(3)
  final DateTime startDate;

  /// Last generated calendar day (midnight). Inclusive — display-side
  /// range "Mon 1 Jan – Sun 7 Jan" reads naturally.
  @HiveField(4)
  final DateTime endDate;

  /// Wall-clock instant of the Generate call. Sort key for the saved
  /// list (most-recent first).
  @HiveField(5)
  final DateTime createdAt;

  /// `RotationPattern.id` if generated from the pattern picker; null if
  /// generated from the bare-block template screen. Surfaced for debug /
  /// future "re-run this pattern" flows.
  @HiveField(6)
  final String? patternId;

  /// "Day 1" of the cycle for the anchored path. Null on legacy cycles
  /// (pattern/template/custom paths) and on cycles created before this
  /// field existed — those records still load via Hive's additive-field
  /// semantics with `anchorDate == null`.
  @HiveField(7)
  final DateTime? anchorDate;

  /// The ordered sequence of [CycleBlock]s that defines one full repeat
  /// of the cycle. Together with [anchorDate] this is what the modulo
  /// resolver needs to derive the ShiftType for any past or future date.
  /// Null on legacy cycles for the same reason as [anchorDate].
  @HiveField(8)
  final List<CycleBlock>? blocks;

  /// True iff this cycle was generated via the anchored path and carries
  /// the data the modulo resolver needs. Call sites that want to compute
  /// future ShiftTypes on-demand should gate on this rather than reading
  /// the persisted `Shift` records.
  bool get isAnchored =>
      anchorDate != null && blocks != null && blocks!.isNotEmpty;

  /// Total calendar days in one full repeat of the cycle. Null when the
  /// cycle is not anchored (no `blocks` to sum).
  int? get cycleLengthDays =>
      blocks?.fold<int>(0, (n, b) => n + b.consecutiveDays);

  ShiftCycle copyWith({
    String? id,
    String? label,
    String? summary,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    String? patternId,
    DateTime? anchorDate,
    List<CycleBlock>? blocks,
  }) =>
      ShiftCycle(
        id: id ?? this.id,
        label: label ?? this.label,
        summary: summary ?? this.summary,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        createdAt: createdAt ?? this.createdAt,
        patternId: patternId ?? this.patternId,
        anchorDate: anchorDate ?? this.anchorDate,
        blocks: blocks ?? this.blocks,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftCycle &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          summary == other.summary &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          createdAt == other.createdAt &&
          patternId == other.patternId &&
          anchorDate == other.anchorDate &&
          _listEquals(blocks, other.blocks);

  @override
  int get hashCode => Object.hash(
        id,
        label,
        summary,
        startDate,
        endDate,
        createdAt,
        patternId,
        anchorDate,
        blocks == null ? null : Object.hashAll(blocks!),
      );

  @override
  String toString() =>
      'ShiftCycle(id: $id, label: $label, summary: $summary, '
      'startDate: $startDate, endDate: $endDate, '
      'createdAt: $createdAt, patternId: $patternId, '
      'anchorDate: $anchorDate, blocks: $blocks)';
}

/// Order-sensitive list equality. `List.==` is identity, which makes
/// two different lists with the same elements compare unequal — the
/// wrong semantic for a value type like [ShiftCycle].
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
