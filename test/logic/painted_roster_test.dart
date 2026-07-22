import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/painted_roster.dart';

void main() {
  PaintedShiftBlock block(
    ShiftType type,
    Set<int> days, {
    int start = 7 * 60,
    int end = 15 * 60,
  }) =>
      PaintedShiftBlock(
        type: type,
        startMinutes: start,
        endMinutes: end,
        dayIndices: days,
      );

  group('foldPaintedBlocks', () {
    test('un-painted positions become Off; painted runs merge', () {
      // 7-day cycle: Day shift on days 0,1,2; the rest Off.
      final folded = foldPaintedBlocks(7, [block(ShiftType.day, {0, 1, 2})]);
      // Expect: Day×3, Off×4.
      expect(folded.map((b) => b.type).toList(), [
        ShiftType.day,
        ShiftType.off,
      ]);
      expect(folded[0].consecutiveDays, 3);
      expect(folded[0].startMinutes, 7 * 60);
      expect(folded[0].endMinutes, 15 * 60);
      expect(folded[1].type, ShiftType.off);
      expect(folded[1].consecutiveDays, 4);
    });

    test('total folded days always equals the cycle length', () {
      final folded = foldPaintedBlocks(14, [
        block(ShiftType.day, {0, 1, 2, 3}),
        block(ShiftType.night, {7, 8, 9}, start: 19 * 60, end: 7 * 60),
      ]);
      final total = folded.fold<int>(0, (n, b) => n + b.consecutiveDays);
      expect(total, 14);
    });

    test('non-contiguous painted days split into separate runs', () {
      // Day on 0,1 and 4,5 → Day×2, Off×2, Day×2, Off×1 over a 7-day cycle.
      final folded = foldPaintedBlocks(7, [block(ShiftType.day, {0, 1, 4, 5})]);
      expect(
        folded.map((b) => (b.type, b.consecutiveDays)).toList(),
        [
          (ShiftType.day, 2),
          (ShiftType.off, 2),
          (ShiftType.day, 2),
          (ShiftType.off, 1),
        ],
      );
    });

    test('adjacent blocks of different types stay distinct runs', () {
      final folded = foldPaintedBlocks(4, [
        block(ShiftType.day, {0, 1}),
        block(ShiftType.night, {2, 3}, start: 19 * 60, end: 7 * 60),
      ]);
      expect(folded.map((b) => b.type).toList(),
          [ShiftType.day, ShiftType.night]);
      expect(folded.every((b) => b.consecutiveDays == 2), isTrue);
    });

    test('an all-Off cycle (no blocks) folds to a single Off run', () {
      final folded = foldPaintedBlocks(5, const []);
      expect(folded, hasLength(1));
      expect(folded.single.type, ShiftType.off);
      expect(folded.single.consecutiveDays, 5);
    });
  });

  group('claimedDayIndices', () {
    test('unions every block, and excludes the one being edited', () {
      final a = block(ShiftType.day, {0, 1});
      final b = block(ShiftType.night, {5, 6});
      expect(claimedDayIndices([a, b]), {0, 1, 5, 6});
      expect(claimedDayIndices([a, b], exclude: a), {5, 6});
    });
  });

  group('hasAnyPaintedDay', () {
    test('false only when no block paints a day', () {
      expect(hasAnyPaintedDay(const []), isFalse);
      expect(hasAnyPaintedDay([block(ShiftType.day, <int>{})]), isFalse);
      expect(hasAnyPaintedDay([block(ShiftType.day, {3})]), isTrue);
    });
  });

  group('formatDayIndexRanges', () {
    test('compresses consecutive runs, 1-based', () {
      expect(formatDayIndexRanges({0, 1, 2}), '1–3');
      expect(formatDayIndexRanges({0, 1, 2, 7, 9, 10, 11}), '1–3, 8, 10–12');
      expect(formatDayIndexRanges({4}), '5');
      expect(formatDayIndexRanges(<int>{}), '—');
    });
  });
}
