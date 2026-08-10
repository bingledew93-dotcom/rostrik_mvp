import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/painted_roster.dart';
import 'package:rostrik_mvp/logic/rotation_pattern_validator.dart'
    show RosterGenerationException;
import 'package:rostrik_mvp/logic/shift_block.dart';
import 'package:rostrik_mvp/logic/shift_generator.dart';

import '../alarms/fakes.dart';

/// Covers the EDIT/replace path's safety valve: regenerating a roster over its
/// own current dates must not self-clash when the old cycle is excluded from the
/// overlap check (the UI generates-new-then-deletes-old).
void main() {
  late FakeShiftRepository repo;
  late FakeShiftCycleRepository cycleRepo;
  late ShiftGenerator generator;

  setUp(() {
    repo = FakeShiftRepository();
    cycleRepo = FakeShiftCycleRepository();
    generator = ShiftGenerator(shifts: repo, cycles: cycleRepo);
  });

  tearDown(() async {
    await repo.dispose();
    await cycleRepo.dispose();
  });

  // A Day block covering both days of a 2-day cycle → every day is a Day shift.
  List<ShiftBlock> dayBlocks() => paintedBlocksToShiftBlocks(const [
        PaintedShiftBlock(
          type: ShiftType.day,
          startMinutes: 360,
          endMinutes: 840,
          dayIndices: {0, 1},
        ),
      ]);

  Future<String> makeRoster({String label = 'A'}) async {
    await generator.generateAndPersistCustom(
      label: label,
      startDate: DateTime(2026, 5, 1),
      cycleLengthDays: 2,
      blocks: dayBlocks(),
      materialiseTo: DateTime(2026, 5, 5),
      fillOffDays: true,
    );
    return (await cycleRepo.getAll()).first.id;
  }

  test('regenerating over the same dates clashes WITHOUT the exclude', () async {
    await makeRoster();
    expect(
      () => generator.generateAndPersistCustom(
        label: 'A-again',
        startDate: DateTime(2026, 5, 1),
        cycleLengthDays: 2,
        blocks: dayBlocks(),
        materialiseTo: DateTime(2026, 5, 5),
        fillOffDays: true,
      ),
      throwsA(isA<RosterGenerationException>()),
    );
  });

  test('excludeCycleIdFromOverlap lets a roster regenerate over its own dates',
      () async {
    final oldId = await makeRoster();
    final shifts = await generator.generateAndPersistCustom(
      label: 'A-edited',
      startDate: DateTime(2026, 5, 1),
      cycleLengthDays: 2,
      blocks: dayBlocks(),
      materialiseTo: DateTime(2026, 5, 5),
      fillOffDays: true,
      excludeCycleIdFromOverlap: oldId,
    );
    expect(shifts, isNotEmpty);
  });
}
