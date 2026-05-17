import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/rotation_pattern_validator.dart';
import 'package:rostrik_mvp/logic/shift_block.dart';
import 'package:rostrik_mvp/logic/shift_generator.dart';

import '../alarms/fakes.dart';

void main() {
  late FakeShiftRepository shifts;
  late FakeShiftCycleRepository cycles;
  late ShiftGenerator generator;

  setUp(() {
    shifts = FakeShiftRepository();
    cycles = FakeShiftCycleRepository();
    generator = ShiftGenerator(shifts: shifts, cycles: cycles);
  });

  tearDown(() async {
    await shifts.dispose();
    await cycles.dispose();
  });

  group('validateCustomRoster', () {
    test('non-empty single-day block passes', () {
      const block = ShiftBlock(
        type: ShiftType.day,
        startDayIndex: 0,
        endDayIndex: 0,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      );
      expect(validateCustomRoster(1, [block]), isEmpty);
    });

    test('zero cycle length rejected', () {
      expect(
        validateCustomRoster(0, const [
          ShiftBlock(
            type: ShiftType.day,
            startDayIndex: 0,
            endDayIndex: 0,
            startMinutes: 7 * 60,
            endMinutes: 15 * 60,
          ),
        ]),
        contains(predicate<String>((m) => m.contains('at least 1 day'))),
      );
    });

    test('empty blocks list rejected', () {
      expect(
        validateCustomRoster(7, const []),
        contains(predicate<String>((m) => m.contains('at least one block'))),
      );
    });

    test('start day past cycle length rejected', () {
      const b = ShiftBlock(
        type: ShiftType.day,
        startDayIndex: 7,
        endDayIndex: 7,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      );
      expect(
        validateCustomRoster(7, [b]),
        contains(predicate<String>((m) => m.contains('start day'))),
      );
    });

    test('end day before start day rejected', () {
      const b = ShiftBlock(
        type: ShiftType.day,
        startDayIndex: 3,
        endDayIndex: 1,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      );
      expect(
        validateCustomRoster(7, [b]),
        contains(predicate<String>((m) => m.contains('end day is before'))),
      );
    });

    test('zero-duration work block rejected; zero-duration OFF allowed', () {
      const work = ShiftBlock(
        type: ShiftType.day,
        startDayIndex: 0,
        endDayIndex: 0,
        startMinutes: 8 * 60,
        endMinutes: 8 * 60,
      );
      const off = ShiftBlock(
        type: ShiftType.off,
        startDayIndex: 0,
        endDayIndex: 0,
        startMinutes: 0,
        endMinutes: 0,
      );
      expect(
        validateCustomRoster(1, [work]),
        contains(predicate<String>(
            (m) => m.contains('same start and end time'))),
      );
      expect(validateCustomRoster(1, [off]), isEmpty);
    });
  });

  group('generateAndPersistCustom — happy path', () {
    test(
      'a 1-day cycle with two non-overlapping blocks produces 2 shifts per repeat',
      () async {
        const a = ShiftBlock(
          type: ShiftType.day,
          startDayIndex: 0,
          endDayIndex: 0,
          startMinutes: 6 * 60,
          endMinutes: 10 * 60,
        );
        const b = ShiftBlock(
          type: ShiftType.day,
          startDayIndex: 0,
          endDayIndex: 0,
          startMinutes: 15 * 60,
          endMinutes: 19 * 60,
        );
        final generated = await generator.generateAndPersistCustom(
          label: 'Split shifts',
          startDate: DateTime(2026, 6, 1),
          cycleLengthDays: 1,
          repeatCount: 3,
          blocks: const [a, b],
        );

        expect(generated, hasLength(6));
        // Two shifts per calendar day across three days.
        final byDate = <DateTime, int>{};
        for (final s in generated) {
          byDate[s.date] = (byDate[s.date] ?? 0) + 1;
        }
        expect(byDate.values, everyElement(equals(2)));
        // Every child carries the same cycleId.
        final cycleIds = generated.map((s) => s.cycleId).toSet();
        expect(cycleIds, hasLength(1));
        expect(cycleIds.single, isNotNull);
      },
    );

    test('multi-day cycle: blocks position correctly within the cycle',
        () async {
      const day = ShiftBlock(
        type: ShiftType.day,
        startDayIndex: 0,
        endDayIndex: 1,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      );
      const off = ShiftBlock(
        type: ShiftType.off,
        startDayIndex: 2,
        endDayIndex: 3,
        startMinutes: 0,
        endMinutes: 0,
      );
      final generated = await generator.generateAndPersistCustom(
        label: 'DDOff cycle',
        startDate: DateTime(2026, 6, 1),
        cycleLengthDays: 4,
        repeatCount: 2,
        blocks: const [day, off],
      );

      // 4-day cycle × 2 repeats = 8 calendar days × 1 block each = 8 shifts.
      expect(generated, hasLength(8));
      expect(
        generated.map((s) => s.type),
        [
          ShiftType.day, ShiftType.day, ShiftType.off, ShiftType.off,
          ShiftType.day, ShiftType.day, ShiftType.off, ShiftType.off,
        ],
      );
    });

    test('a ShiftCycle parent is created with the generator-supplied label',
        () async {
      const b = ShiftBlock(
        type: ShiftType.day,
        startDayIndex: 0,
        endDayIndex: 0,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      );
      await generator.generateAndPersistCustom(
        label: 'My roster',
        startDate: DateTime(2026, 6, 1),
        cycleLengthDays: 1,
        repeatCount: 1,
        blocks: const [b],
      );

      final all = await cycles.getAll();
      expect(all, hasLength(1));
      expect(all.single.label, 'My roster');
    });
  });

  group('generateAndPersistCustom — time-overlap rejection', () {
    test('two blocks on the same day with overlapping times throw, write nothing',
        () async {
      const a = ShiftBlock(
        type: ShiftType.day,
        startDayIndex: 0,
        endDayIndex: 0,
        startMinutes: 8 * 60,
        endMinutes: 12 * 60,
      );
      const b = ShiftBlock(
        type: ShiftType.day,
        startDayIndex: 0,
        endDayIndex: 0,
        startMinutes: 10 * 60,
        endMinutes: 14 * 60,
      );
      expect(
        () => generator.generateAndPersistCustom(
          label: 'Conflict',
          startDate: DateTime(2026, 6, 1),
          cycleLengthDays: 1,
          repeatCount: 1,
          blocks: const [a, b],
        ),
        throwsA(isA<RosterGenerationException>()),
      );
      // No partial writes — the generator throws before any persistence.
      expect(await cycles.getAll(), isEmpty);
      expect(
        await shifts.getInRange(
            DateTime(2026, 6, 1), DateTime(2026, 6, 30)),
        isEmpty,
      );
    });

    test('split shifts (touching edge) are allowed', () async {
      // 14:00–18:00 abutting 18:00–22:00 must NOT trigger an overlap —
      // standard half-open interval semantics, exercised by the
      // validator's boundary test in rotation_pattern_validator_test.
      const a = ShiftBlock(
        type: ShiftType.day,
        startDayIndex: 0,
        endDayIndex: 0,
        startMinutes: 14 * 60,
        endMinutes: 18 * 60,
      );
      const b = ShiftBlock(
        type: ShiftType.day,
        startDayIndex: 0,
        endDayIndex: 0,
        startMinutes: 18 * 60,
        endMinutes: 22 * 60,
      );
      final generated = await generator.generateAndPersistCustom(
        label: 'Back-to-back',
        startDate: DateTime(2026, 6, 1),
        cycleLengthDays: 1,
        repeatCount: 1,
        blocks: const [a, b],
      );
      expect(generated, hasLength(2));
    });

    test('a new cycle overlapping existing roster on time is rejected',
        () async {
      // Pre-seed an existing 8–12 shift on June 1.
      await generator.generateAndPersist(
        startDate: DateTime(2026, 6, 1),
        startMinutes: 8 * 60,
        endMinutes: 12 * 60,
        consecutiveDays: 1,
        shiftType: ShiftType.day,
      );
      final before = await cycles.getAll();
      expect(before, hasLength(1));

      // Try to add another cycle whose first day's block overlaps.
      const b = ShiftBlock(
        type: ShiftType.day,
        startDayIndex: 0,
        endDayIndex: 0,
        startMinutes: 10 * 60,
        endMinutes: 14 * 60,
      );
      expect(
        () => generator.generateAndPersistCustom(
          label: 'Conflicting',
          startDate: DateTime(2026, 6, 1),
          cycleLengthDays: 1,
          repeatCount: 1,
          blocks: const [b],
        ),
        throwsA(isA<RosterGenerationException>()),
      );

      // No second cycle row was written.
      final after = await cycles.getAll();
      expect(after, hasLength(1));
    });
  });

  test('zero repeatCount throws RosterGenerationException, writes nothing',
      () async {
    const b = ShiftBlock(
      type: ShiftType.day,
      startDayIndex: 0,
      endDayIndex: 0,
      startMinutes: 7 * 60,
      endMinutes: 15 * 60,
    );
    expect(
      () => generator.generateAndPersistCustom(
        label: 'X',
        startDate: DateTime(2026, 6, 1),
        cycleLengthDays: 1,
        repeatCount: 0,
        blocks: const [b],
      ),
      throwsA(isA<RosterGenerationException>()),
    );
    expect(await cycles.getAll(), isEmpty);
  });
}
