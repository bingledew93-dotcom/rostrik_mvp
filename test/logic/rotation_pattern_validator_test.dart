import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/rotation_pattern.dart';
import 'package:rostrik_mvp/logic/rotation_pattern_validator.dart';

void main() {
  group('validateRotationPattern', () {
    test('a curated pattern from kAllPatterns reports no errors', () {
      for (final p in kAllPatterns) {
        expect(
          validateRotationPattern(p),
          isEmpty,
          reason: 'shipped preset "${p.id}" should be valid',
        );
      }
    });

    test('empty blocks list is rejected', () {
      const p = RotationPattern(
        id: 'empty', label: 'Empty', summary: 'no blocks', blocks: [],
      );
      expect(validateRotationPattern(p), contains('Pattern has no blocks.'));
    });

    test('zero-day block is rejected', () {
      const p = RotationPattern(
        id: 'zero-day', label: 'Bad', summary: '',
        blocks: [
          RotationBlock(
            type: ShiftType.day,
            consecutiveDays: 0,
            startMinutes: 7 * 60,
            endMinutes: 15 * 60,
          ),
        ],
      );
      expect(
        validateRotationPattern(p),
        contains(predicate<String>((m) => m.contains('zero or negative days'))),
      );
    });

    test('zero-duration non-OFF block is rejected', () {
      const p = RotationPattern(
        id: 'zero-dur', label: 'Bad', summary: '',
        blocks: [
          RotationBlock(
            type: ShiftType.day,
            consecutiveDays: 3,
            startMinutes: 8 * 60,
            endMinutes: 8 * 60,
          ),
        ],
      );
      expect(
        validateRotationPattern(p),
        contains(predicate<String>(
            (m) => m.contains('same start and end time'))),
      );
    });

    test('zero-duration OFF block is accepted (OFF has no time range)', () {
      const p = RotationPattern(
        id: 'ok-off', label: 'OK', summary: '',
        blocks: [RotationBlock(type: ShiftType.off, consecutiveDays: 7)],
      );
      expect(validateRotationPattern(p), isEmpty);
    });

    test('out-of-range start/end minutes rejected', () {
      const p = RotationPattern(
        id: 'oob', label: 'Bad', summary: '',
        blocks: [
          RotationBlock(
            type: ShiftType.day,
            consecutiveDays: 1,
            startMinutes: -10,
            endMinutes: 1500,
          ),
        ],
      );
      final errors = validateRotationPattern(p);
      expect(
        errors,
        contains(predicate<String>((m) => m.contains('start time is out of range'))),
      );
      expect(
        errors,
        contains(predicate<String>((m) => m.contains('end time is out of range'))),
      );
    });
  });

  group('timeIntervalsOverlap', () {
    // Standard half-open: aEnd == bStart does NOT overlap.
    test('touching ranges (14:00–18:00 / 18:00–22:00) do not overlap', () {
      expect(timeIntervalsOverlap(14 * 60, 18 * 60, 18 * 60, 22 * 60), isFalse);
      // Symmetric.
      expect(timeIntervalsOverlap(18 * 60, 22 * 60, 14 * 60, 18 * 60), isFalse);
    });

    test('identical ranges overlap', () {
      expect(timeIntervalsOverlap(9 * 60, 17 * 60, 9 * 60, 17 * 60), isTrue);
    });

    test('partial overlap (8–12 vs 10–14) is detected', () {
      expect(timeIntervalsOverlap(8 * 60, 12 * 60, 10 * 60, 14 * 60), isTrue);
    });

    test('fully-disjoint ranges (6–10 vs 15–19) do not overlap', () {
      expect(timeIntervalsOverlap(6 * 60, 10 * 60, 15 * 60, 19 * 60), isFalse);
    });

    test('one range fully containing the other overlaps', () {
      expect(timeIntervalsOverlap(8 * 60, 18 * 60, 10 * 60, 12 * 60), isTrue);
    });
  });

  group('findTimeOverlaps', () {
    Shift mk({
      required String id,
      required DateTime date,
      required int start,
      required int end,
      ShiftType type = ShiftType.day,
    }) =>
        Shift(
          id: id,
          date: date,
          type: type,
          startMinutes: start,
          endMinutes: end,
        );

    final d1 = DateTime(2026, 5, 1);
    final d2 = DateTime(2026, 5, 2);

    test('returns empty for a single-shift roster', () {
      final shifts = [mk(id: 'a', date: d1, start: 7 * 60, end: 15 * 60)];
      expect(findTimeOverlaps(shifts), isEmpty);
    });

    test('split shifts on the same date with disjoint times do not flag', () {
      // 06:00–10:00 + 15:00–19:00 is the explicit "allowed" case from
      // the user's task brief.
      final shifts = [
        mk(id: 'a', date: d1, start: 6 * 60, end: 10 * 60),
        mk(id: 'b', date: d1, start: 15 * 60, end: 19 * 60),
      ];
      expect(findTimeOverlaps(shifts), isEmpty);
    });

    test('same-date time-overlapping shifts are flagged', () {
      final shifts = [
        mk(id: 'a', date: d1, start: 8 * 60, end: 12 * 60),
        mk(id: 'b', date: d1, start: 10 * 60, end: 14 * 60),
      ];
      final conflicts = findTimeOverlaps(shifts);
      expect(conflicts, hasLength(1));
      expect(conflicts.first.$1.id, anyOf('a', 'b'));
      expect(conflicts.first.$2.id, anyOf('a', 'b'));
    });

    test('different-date pairs are never flagged', () {
      final shifts = [
        mk(id: 'a', date: d1, start: 9 * 60, end: 17 * 60),
        mk(id: 'b', date: d2, start: 9 * 60, end: 17 * 60),
      ];
      expect(findTimeOverlaps(shifts), isEmpty);
    });

    test('OFF shifts are skipped (no time to conflict with)', () {
      final shifts = [
        mk(id: 'a', date: d1, start: 9 * 60, end: 17 * 60),
        mk(id: 'b', date: d1, start: 0, end: 0, type: ShiftType.off),
      ];
      expect(findTimeOverlaps(shifts), isEmpty);
    });
  });
}
