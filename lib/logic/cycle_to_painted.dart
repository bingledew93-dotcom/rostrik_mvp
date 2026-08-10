import '../data/models/shift_cycle.dart';
import '../data/models/shift_type.dart';
import 'painted_roster.dart';

/// Reconstructs the roster builder's painted-block state from a saved
/// [ShiftCycle] so a preset roster can be reopened for editing — the inverse of
/// `ShiftGenerator._foldCustomBlocksToCycleBlocks`.
///
/// Pure/testable: takes the persisted cycle and hands back exactly what
/// `CustomBuilderScreen` needs to pre-fill (cycle length + painted blocks),
/// with no Flutter / repo dependency.

/// Longest cycle the builder supports — MUST mirror
/// `CustomBuilderScreen._maxCycleDays`. Template cycles carry a 365-day Off pad,
/// so their cycle length blows past this and they aren't builder-editable.
const int kMaxEditableCycleDays = 60;

/// Whether [cycle] can be reopened in the builder: it must be anchored (carry
/// `blocks` + `anchorDate`) and have a cycle length within the builder's range.
///
/// Excludes: legacy non-anchored cycles (no blocks to reconstruct) and template
/// "single block · N days" cycles (their 365-day Off pad makes the cycle length
/// far exceed [kMaxEditableCycleDays]). Those keep the delete-and-rebuild path.
bool isCycleEditable(ShiftCycle cycle) {
  final len = cycle.cycleLengthDays;
  return cycle.isAnchored && len != null && len >= 1 && len <= kMaxEditableCycleDays;
}

/// The builder state reconstructed from a cycle.
class ReconstructedRoster {
  const ReconstructedRoster({
    required this.cycleLengthDays,
    required this.blocks,
  });

  final int cycleLengthDays;
  final List<PaintedShiftBlock> blocks;
}

/// Rebuilds the painted blocks + cycle length from an editable [cycle], or null
/// when it isn't [isCycleEditable].
///
/// Walks the cycle's sequential [CycleBlock]s, assigning consecutive 0-based day
/// positions, and emits one [PaintedShiftBlock] per non-Off block (Off blocks
/// just advance the position — an un-painted day is Off in the builder).
ReconstructedRoster? reconstructRosterFromCycle(ShiftCycle cycle) {
  if (!isCycleEditable(cycle)) return null;
  final blocks = cycle.blocks!;
  final painted = <PaintedShiftBlock>[];
  var pos = 0;
  for (final b in blocks) {
    if (b.type != ShiftType.off && b.consecutiveDays > 0) {
      painted.add(PaintedShiftBlock(
        type: b.type,
        startMinutes: b.startMinutes,
        endMinutes: b.endMinutes,
        dayIndices: {for (var d = 0; d < b.consecutiveDays; d++) pos + d},
      ));
    }
    pos += b.consecutiveDays;
  }
  return ReconstructedRoster(
    cycleLengthDays: cycle.cycleLengthDays!,
    blocks: painted,
  );
}
