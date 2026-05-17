import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/rotation_pattern.dart';
import 'package:rostrik_mvp/logic/shift_block.dart';
import 'package:rostrik_mvp/logic/shift_generator.dart';

import '../alarms/fakes.dart';

/// DST-safety regression tests for the three generator paths.
///
/// Every generator path now advances the calendar cursor via
/// `DateTime(y, m, d + N)` instead of `cursor.add(Duration(days: N))`,
/// so a 5-year expansion across multiple spring-forward / fall-back
/// boundaries cannot accumulate drift. These tests pin the contract:
///
///   - Every generated shift's `date` is at local midnight.
///   - Across any range, the dates are strictly contiguous (no gap, no
///     duplicate, no day skipped).
///   - Each shift's `startDateTime` resolves to the configured local
///     hour/minute regardless of which calendar day it lands on.
void main() {
  late FakeShiftRepository repo;
  late FakeShiftCycleRepository cycles;
  late ShiftGenerator generator;

  setUp(() {
    repo = FakeShiftRepository();
    cycles = FakeShiftCycleRepository();
    generator = ShiftGenerator(shifts: repo, cycles: cycles);
  });

  tearDown(() async {
    await repo.dispose();
    await cycles.dispose();
  });

  group('pattern path crosses DST boundaries cleanly', () {
    const allDay = RotationPattern(
      id: 'all-day',
      label: 'All day',
      summary: 'every-day day shift fixture',
      blocks: [
        RotationBlock(
          type: ShiftType.day,
          consecutiveDays: 1,
          startMinutes: 7 * 60,
          endMinutes: 15 * 60,
        ),
      ],
    );

    test(
      'a 365-day range produces exactly 365 strictly-contiguous calendar days',
      () async {
        // Spans every DST boundary that occurs in 2026 (US, EU, AU…)
        // depending on the test runner's local zone. If any boundary
        // were mishandled, the day count would be off, or a duplicate
        // / skipped date would land in the sequence.
        final start = DateTime(2026, 1, 1);
        final end = DateTime(2027, 1, 1);
        final shifts = await generator.generateAndPersistPattern(
          pattern: allDay,
          startDate: start,
          endDate: end,
        );
        expect(shifts, hasLength(365));
        for (var i = 0; i < shifts.length; i++) {
          // Every generated date is local midnight by construction.
          expect(shifts[i].date.hour, 0);
          expect(shifts[i].date.minute, 0);
          expect(shifts[i].date.second, 0);
          // Calendar-day step: dayOfYear matches the index (1-indexed).
          final daysSinceStart =
              shifts[i].date.difference(start).inDays;
          // `difference.inDays` truncates on a DST shift; assert with
          // a tolerance of 0 because the new code's `date` is local
          // midnight on each consecutive calendar day, which differ by
          // EXACTLY 23, 24, or 25 absolute hours — never enough to
          // shift the integer day count if we're comparing midnight to
          // midnight in the same local zone.
          expect(daysSinceStart, i,
              reason: 'shift[$i] should be exactly $i days after start');
        }
      },
    );

    test(
      'startDateTime reads back the configured local hour on every shift',
      () async {
        final start = DateTime(2026, 3, 1);
        final end = DateTime(2026, 4, 1);
        final shifts = await generator.generateAndPersistPattern(
          pattern: allDay,
          startDate: start,
          endDate: end,
        );
        for (final s in shifts) {
          expect(s.startDateTime.hour, 7,
              reason: 'shift on ${s.date} lost its local hour');
          expect(s.startDateTime.minute, 0);
        }
      },
    );
  });

  group('template path: generateAndPersist', () {
    test('14 consecutive shifts cover 14 contiguous calendar days', () async {
      final start = DateTime(2026, 3, 1);
      final shifts = await generator.generateAndPersist(
        startDate: start,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
        consecutiveDays: 14,
        shiftType: ShiftType.day,
      );
      expect(shifts, hasLength(14));
      for (var i = 0; i < shifts.length; i++) {
        // Calendar-math advancement, mirrored against the same helper.
        final expected = DateTime(start.year, start.month, start.day + i);
        expect(shifts[i].date, expected);
        // Local hour preserved by `startDateTime`.
        expect(shifts[i].startDateTime.hour, 7);
      }
    });
  });

  group('custom path: generateAndPersistCustom', () {
    test(
      'a multi-cycle custom expansion produces contiguous local-midnight dates',
      () async {
        const block = ShiftBlock(
          type: ShiftType.day,
          startDayIndex: 0,
          endDayIndex: 0,
          startMinutes: 7 * 60,
          endMinutes: 15 * 60,
        );
        final start = DateTime(2026, 3, 1);
        final shifts = await generator.generateAndPersistCustom(
          label: 'DST test',
          startDate: start,
          cycleLengthDays: 1,
          repeatCount: 30,
          blocks: const [block],
        );
        expect(shifts, hasLength(30));
        for (var i = 0; i < shifts.length; i++) {
          final expected = DateTime(start.year, start.month, start.day + i);
          expect(shifts[i].date, expected);
          // The hero point of the audit: alarm fire time on every day
          // resolves to the configured 07:00 local.
          expect(shifts[i].startDateTime.hour, 7);
        }
      },
    );
  });
}
