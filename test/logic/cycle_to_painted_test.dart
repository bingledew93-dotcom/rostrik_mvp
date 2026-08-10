import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/cycle_block.dart';
import 'package:rostrik_mvp/data/models/shift_cycle.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/cycle_to_painted.dart';

/// Pure tests for reconstructing builder state from a saved cycle.
void main() {
  ShiftCycle cycle(List<CycleBlock> blocks, {DateTime? anchor}) => ShiftCycle(
        id: 'c1',
        label: 'Roster',
        summary: 'x',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        createdAt: DateTime(2026, 1, 1),
        anchorDate: anchor ?? DateTime(2026, 1, 1),
        blocks: blocks,
      );

  test('reconstructs painted blocks with correct day positions', () {
    // 4 Day (06-14), then 4 Off → an 8-day 4-on/4-off cycle.
    final r = reconstructRosterFromCycle(cycle([
      const CycleBlock(
          type: ShiftType.day, consecutiveDays: 4, startMinutes: 360, endMinutes: 840),
      const CycleBlock(
          type: ShiftType.off, consecutiveDays: 4, startMinutes: 0, endMinutes: 0),
    ]))!;

    expect(r.cycleLengthDays, 8);
    expect(r.blocks, hasLength(1)); // Off is not a painted block
    final block = r.blocks.single;
    expect(block.type, ShiftType.day);
    expect(block.startMinutes, 360);
    expect(block.endMinutes, 840);
    expect(block.dayIndices, {0, 1, 2, 3});
  });

  test('assigns positions across multiple non-Off blocks, skipping Off runs', () {
    // Day×2, Off×1, Night×2  → positions 0,1 (Day), 2 (Off), 3,4 (Night); len 5.
    final r = reconstructRosterFromCycle(cycle([
      const CycleBlock(
          type: ShiftType.day, consecutiveDays: 2, startMinutes: 360, endMinutes: 840),
      const CycleBlock(
          type: ShiftType.off, consecutiveDays: 1, startMinutes: 0, endMinutes: 0),
      const CycleBlock(
          type: ShiftType.night, consecutiveDays: 2, startMinutes: 1320, endMinutes: 360),
    ]))!;

    expect(r.cycleLengthDays, 5);
    expect(r.blocks, hasLength(2));
    expect(r.blocks[0].type, ShiftType.day);
    expect(r.blocks[0].dayIndices, {0, 1});
    expect(r.blocks[1].type, ShiftType.night);
    expect(r.blocks[1].dayIndices, {3, 4});
  });

  test('isCycleEditable: true for a normal anchored cycle', () {
    expect(
      isCycleEditable(cycle([
        const CycleBlock(
            type: ShiftType.day, consecutiveDays: 4, startMinutes: 360, endMinutes: 840),
        const CycleBlock(
            type: ShiftType.off, consecutiveDays: 4, startMinutes: 0, endMinutes: 0),
      ])),
      isTrue,
    );
  });

  test('isCycleEditable: false for a template cycle (365-day Off pad)', () {
    final template = cycle([
      const CycleBlock(
          type: ShiftType.day, consecutiveDays: 3, startMinutes: 360, endMinutes: 840),
      const CycleBlock(
          type: ShiftType.off, consecutiveDays: 365, startMinutes: 0, endMinutes: 0),
    ]);
    expect(isCycleEditable(template), isFalse); // 368 > kMaxEditableCycleDays
    expect(reconstructRosterFromCycle(template), isNull);
  });

  test('isCycleEditable: false for a legacy non-anchored cycle', () {
    final legacy = ShiftCycle(
      id: 'legacy',
      label: 'Old',
      summary: 'x',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 7),
      createdAt: DateTime(2026, 1, 1),
      // no anchorDate / blocks
    );
    expect(isCycleEditable(legacy), isFalse);
    expect(reconstructRosterFromCycle(legacy), isNull);
  });
}
