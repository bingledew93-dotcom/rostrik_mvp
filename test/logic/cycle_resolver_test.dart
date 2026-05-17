import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/cycle_block.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/cycle_resolver.dart';

void main() {
  // The user-supplied "industry standard" cycle from the upgrade brief:
  // 4D / 5OFF / 5N / 5OFF / 5D / 4OFF / 4D / 5OFF — total 37 days.
  // Block index map (inclusive day ranges within one cycle):
  //   0: D    days 0..3    (4)
  //   1: OFF  days 4..8    (5)
  //   2: N    days 9..13   (5)
  //   3: OFF  days 14..18  (5)
  //   4: D    days 19..23  (5)
  //   5: OFF  days 24..27  (4)
  //   6: D    days 28..31  (4)
  //   7: OFF  days 32..36  (5)
  const industryCycle = <CycleBlock>[
    CycleBlock(type: ShiftType.day, consecutiveDays: 4,
        startMinutes: 7 * 60, endMinutes: 15 * 60),
    CycleBlock(type: ShiftType.off, consecutiveDays: 5),
    CycleBlock(type: ShiftType.night, consecutiveDays: 5,
        startMinutes: 22 * 60, endMinutes: 6 * 60),
    CycleBlock(type: ShiftType.off, consecutiveDays: 5),
    CycleBlock(type: ShiftType.day, consecutiveDays: 5,
        startMinutes: 7 * 60, endMinutes: 15 * 60),
    CycleBlock(type: ShiftType.off, consecutiveDays: 4),
    CycleBlock(type: ShiftType.day, consecutiveDays: 4,
        startMinutes: 7 * 60, endMinutes: 15 * 60),
    CycleBlock(type: ShiftType.off, consecutiveDays: 5),
  ];

  // Anchor at a non-DST date so per-day asserts can't be polluted by
  // off-by-one drift in the test fixture itself. (The DST-specific
  // tests below pick their own anchor.)
  final anchor = DateTime(2026, 1, 1);

  CycleResolution resolveAt(int dayOffset) {
    final target = DateTime(anchor.year, anchor.month, anchor.day + dayOffset);
    final r = resolveShiftBlockForDate(
      target: target,
      anchor: anchor,
      blocks: industryCycle,
    );
    expect(r, isNotNull,
        reason: 'resolver returned null for dayOffset=$dayOffset');
    return r!;
  }

  group('industry-standard 37-day cycle', () {
    test('cycle length is 37 days', () {
      final total = industryCycle.fold<int>(0, (n, b) => n + b.consecutiveDays);
      expect(total, 37);
    });

    test('first day of cycle (day 0) is the first Day block', () {
      final r = resolveAt(0);
      expect(r.block.type, ShiftType.day);
      expect(r.blockIndex, 0);
      expect(r.dayWithinBlock, 0);
      expect(r.dayWithinCycle, 0);
    });

    test('day 3 (last day of first D block) is still Day', () {
      final r = resolveAt(3);
      expect(r.block.type, ShiftType.day);
      expect(r.blockIndex, 0);
      expect(r.dayWithinBlock, 3);
    });

    test('day 4 transitions to the first OFF block', () {
      final r = resolveAt(4);
      expect(r.block.type, ShiftType.off);
      expect(r.blockIndex, 1);
      expect(r.dayWithinBlock, 0);
    });

    test('day 9 transitions to the Night block', () {
      final r = resolveAt(9);
      expect(r.block.type, ShiftType.night);
      expect(r.blockIndex, 2);
      expect(r.dayWithinBlock, 0);
    });

    test('day 13 is the last day of Night block', () {
      final r = resolveAt(13);
      expect(r.block.type, ShiftType.night);
      expect(r.blockIndex, 2);
      expect(r.dayWithinBlock, 4);
    });

    test('day 23 is the last day of the 5-day Day block (block 4)', () {
      final r = resolveAt(23);
      expect(r.block.type, ShiftType.day);
      expect(r.blockIndex, 4);
      expect(r.dayWithinBlock, 4);
    });

    test('day 28 is the first day of the second 4-day Day block (block 6)', () {
      final r = resolveAt(28);
      expect(r.block.type, ShiftType.day);
      expect(r.blockIndex, 6);
      expect(r.dayWithinBlock, 0);
    });

    test('day 36 is the last day of the final OFF block', () {
      final r = resolveAt(36);
      expect(r.block.type, ShiftType.off);
      expect(r.blockIndex, 7);
      expect(r.dayWithinBlock, 4);
    });

    test('day 37 wraps to the first Day block of cycle 2', () {
      final r = resolveAt(37);
      expect(r.block.type, ShiftType.day);
      expect(r.blockIndex, 0);
      expect(r.dayWithinBlock, 0);
      expect(r.dayWithinCycle, 0);
    });

    test('deep wrap: 3 cycles + 9 days lands on Night block', () {
      // 3 * 37 + 9 = 120 days from anchor.
      final r = resolveAt(120);
      expect(r.block.type, ShiftType.night);
      expect(r.blockIndex, 2);
      expect(r.dayWithinBlock, 0);
      expect(r.dayWithinCycle, 9);
    });
  });

  group('bidirectional (target before anchor)', () {
    test('day -1 wraps to the last day of the previous cycle (OFF)', () {
      final r = resolveAt(-1);
      expect(r.block.type, ShiftType.off);
      expect(r.blockIndex, 7);
      expect(r.dayWithinBlock, 4);
      expect(r.dayWithinCycle, 36);
    });

    test('day -37 (exactly one cycle back) is the same block as day 0', () {
      final r0 = resolveAt(0);
      final rPrev = resolveAt(-37);
      expect(rPrev.block, r0.block);
      expect(rPrev.blockIndex, r0.blockIndex);
      expect(rPrev.dayWithinBlock, r0.dayWithinBlock);
      expect(rPrev.dayWithinCycle, r0.dayWithinCycle);
    });

    test('day -10 wraps to day 27 of previous cycle (last day of block 5 OFF)',
        () {
      final r = resolveAt(-10);
      // -10 mod 37 = 27. Block 5 (OFF) covers 24..27.
      expect(r.dayWithinCycle, 27);
      expect(r.blockIndex, 5);
      expect(r.dayWithinBlock, 3);
      expect(r.block.type, ShiftType.off);
    });
  });

  group('edge cases', () {
    test('empty blocks returns null', () {
      final r = resolveShiftBlockForDate(
        target: DateTime(2026, 6, 1),
        anchor: anchor,
        blocks: const [],
      );
      expect(r, isNull);
    });

    test('single-block cycle covers every day', () {
      const oneBlock = <CycleBlock>[
        CycleBlock(type: ShiftType.day, consecutiveDays: 7,
            startMinutes: 7 * 60, endMinutes: 15 * 60),
      ];
      for (final offset in [0, 1, 3, 6, 7, 13, 14, 100, -1, -8]) {
        final r = resolveShiftBlockForDate(
          target: DateTime(anchor.year, anchor.month, anchor.day + offset),
          anchor: anchor,
          blocks: oneBlock,
        );
        expect(r, isNotNull);
        expect(r!.blockIndex, 0);
        expect(r.block.type, ShiftType.day);
        // dayWithinCycle should land in 0..6
        expect(r.dayWithinCycle, inInclusiveRange(0, 6));
      }
    });

    test('resolveShiftTypeForDate sugar returns just the ShiftType', () {
      final type = resolveShiftTypeForDate(
        target: DateTime(anchor.year, anchor.month, anchor.day + 9),
        anchor: anchor,
        blocks: industryCycle,
      );
      expect(type, ShiftType.night);
    });

    test('resolveShiftTypeForDate returns null when blocks empty', () {
      final type = resolveShiftTypeForDate(
        target: DateTime(2026, 6, 1),
        anchor: anchor,
        blocks: const [],
      );
      expect(type, isNull);
    });
  });

  group('DST safety', () {
    // Spring-forward in most US zones for 2026 is Mar 8. In Sydney
    // (the project's `tz.local` candidate for many tests) the boundary
    // is Apr 5 2026 (fall-back). Picking dates that straddle Mar 8 is
    // the standard Dart DST-on-host test; the resolver uses UTC
    // reduction to sidestep it. The assertion: a 7-day cycle straddling
    // Mar 8 still produces correct per-day blocks with no off-by-one.
    test('7-day cycle straddling Mar 8 2026 has no off-by-one', () {
      const weeklyCycle = <CycleBlock>[
        CycleBlock(type: ShiftType.day, consecutiveDays: 7,
            startMinutes: 7 * 60, endMinutes: 15 * 60),
      ];
      final dstAnchor = DateTime(2026, 3, 5);
      // Day 0 should be Mar 5; day 3 should be Mar 8; day 6 should be
      // Mar 11. Crucially the resolver must report dayWithinCycle = N
      // for offset N regardless of the DST jump.
      for (var offset = 0; offset < 14; offset++) {
        final target = DateTime(
          dstAnchor.year,
          dstAnchor.month,
          dstAnchor.day + offset,
        );
        final r = resolveShiftBlockForDate(
          target: target,
          anchor: dstAnchor,
          blocks: weeklyCycle,
        );
        expect(r, isNotNull, reason: 'null at offset=$offset');
        expect(r!.dayWithinCycle, offset % 7,
            reason: 'wrong dayWithinCycle at offset=$offset (target=$target)');
      }
    });
  });
}
