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

  group('paintedBlocksToShiftBlocks', () {
    test('emits one single-day ShiftBlock per painted day, carrying the times',
        () {
      final out =
          paintedBlocksToShiftBlocks([block(ShiftType.day, {0, 1, 2})]);
      expect(out, hasLength(3));
      expect(out.map((b) => b.startDayIndex).toSet(), {0, 1, 2});
      // Each block is single-day and same type/time.
      for (final b in out) {
        expect(b.startDayIndex, b.endDayIndex);
        expect(b.type, ShiftType.day);
        expect(b.startMinutes, 7 * 60);
        expect(b.endMinutes, 15 * 60);
      }
    });

    test('two blocks sharing a day both emit at that position (a split shift)',
        () {
      final out = paintedBlocksToShiftBlocks([
        block(ShiftType.day, {0}, start: 6 * 60, end: 10 * 60),
        block(ShiftType.afternoon, {0}, start: 15 * 60, end: 19 * 60),
      ]);
      // Both land on day 0 → the generator will materialise two shifts there.
      final atDay0 = out.where((b) => b.startDayIndex == 0).toList();
      expect(atDay0, hasLength(2));
      expect(atDay0.map((b) => b.type).toSet(),
          {ShiftType.day, ShiftType.afternoon});
    });

    test('non-contiguous days each become their own block', () {
      final out =
          paintedBlocksToShiftBlocks([block(ShiftType.day, {0, 1, 4})]);
      expect(out.map((b) => b.startDayIndex).toSet(), {0, 1, 4});
    });

    test('no painted days → no blocks', () {
      expect(paintedBlocksToShiftBlocks(const []), isEmpty);
      expect(paintedBlocksToShiftBlocks([block(ShiftType.day, <int>{})]),
          isEmpty);
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
