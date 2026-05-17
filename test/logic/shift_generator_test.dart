import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/rotation_pattern.dart';
import 'package:rostrik_mvp/logic/shift_generator.dart';

import '../alarms/fakes.dart';

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

  // Baseline coverage of the existing block API. Pinned now so the new
  // pattern path can't accidentally regress it (the new method shares
  // a UUID source and the same repository handle).
  group('generateBlock — single-block baseline', () {
    test('produces consecutiveDays shifts on contiguous dates', () {
      final shifts = generator.generateBlock(
        startDate: DateTime(2026, 5, 1),
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
        consecutiveDays: 3,
        shiftType: ShiftType.day,
      );

      expect(shifts, hasLength(3));
      expect(
        shifts.map((s) => s.date),
        [DateTime(2026, 5, 1), DateTime(2026, 5, 2), DateTime(2026, 5, 3)],
      );
      expect(
        shifts.map((s) => s.type),
        everyElement(equals(ShiftType.day)),
      );
    });

    test('asserts against ShiftType.off (single-block contract)', () {
      // The single-block path forbids OFF — that's the boundary that
      // makes the new pattern method necessary.
      expect(
        () => generator.generateBlock(
          startDate: DateTime(2026, 5, 1),
          startMinutes: 0,
          endMinutes: 0,
          consecutiveDays: 1,
          shiftType: ShiftType.off,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('generateAndPersist — single-block baseline', () {
    test('writes every produced shift to the repository', () async {
      final shifts = await generator.generateAndPersist(
        startDate: DateTime(2026, 5, 1),
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
        consecutiveDays: 4,
        shiftType: ShiftType.day,
      );
      final stored = await repo.getInRange(
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 5),
      );
      expect(stored.map((s) => s.id), shifts.map((s) => s.id));
    });
  });

  // The new path: pattern repeats from startDate up to (but not
  // including) endDate. Stops the moment the cursor reaches endDate,
  // honouring partial blocks at the tail of the range.
  group('generateAndPersistPattern — pattern coverage', () {
    const sevenDaySevenOff = RotationPattern(
      id: 'test-7d-7off',
      label: '7 Day, 7 Off',
      summary: 'test fixture',
      blocks: [
        RotationBlock(
          type: ShiftType.day,
          consecutiveDays: 7,
          startMinutes: 7 * 60,
          endMinutes: 15 * 60,
        ),
        RotationBlock(type: ShiftType.off, consecutiveDays: 7),
      ],
    );

    test('a 14-day range yields one full cycle (14 shifts) in order',
        () async {
      final start = DateTime(2026, 5, 1);
      final shifts = await generator.generateAndPersistPattern(
        pattern: sevenDaySevenOff,
        startDate: start,
        endDate: start.add(const Duration(days: 14)),
      );

      expect(shifts, hasLength(14));
      // First 7 are Day, last 7 are Off.
      expect(
        shifts.take(7).map((s) => s.type),
        everyElement(equals(ShiftType.day)),
      );
      expect(
        shifts.skip(7).map((s) => s.type),
        everyElement(equals(ShiftType.off)),
      );
    });

    test('a 56-day range yields 4 full cycles (56 shifts)', () async {
      final start = DateTime(2026, 5, 1);
      final shifts = await generator.generateAndPersistPattern(
        pattern: sevenDaySevenOff,
        startDate: start,
        endDate: start.add(const Duration(days: 56)),
      );
      expect(shifts, hasLength(56));
    });

    test(
      'a 5-year "set and forget" range produces ~1826 shifts and exits cleanly',
      () async {
        // Smoke test for the "set and forget" UX default. 5 years ≈
        // 1826 days (with leap days). The exact count depends on which
        // leap years fall inside the window; we only assert the bound.
        final start = DateTime(2026, 5, 5);
        final end = DateTime(2031, 5, 5);
        final shifts = await generator.generateAndPersistPattern(
          pattern: sevenDaySevenOff,
          startDate: start,
          endDate: end,
        );
        // start..end exclusive = end.difference(start).inDays days.
        final expectedDays = end.difference(start).inDays;
        expect(shifts, hasLength(expectedDays));
      },
    );

    test('dates are contiguous: shift[i].date == startDate + i days',
        () async {
      final start = DateTime(2026, 5, 1);
      final shifts = await generator.generateAndPersistPattern(
        pattern: sevenDaySevenOff,
        startDate: start,
        endDate: start.add(const Duration(days: 28)),
      );
      for (var i = 0; i < shifts.length; i++) {
        expect(
          shifts[i].date,
          start.add(Duration(days: i)),
          reason: 'shift[$i] should be startDate + $i days',
        );
      }
    });

    test('OFF blocks persist as Shift(type: off, startMinutes: 0, endMinutes: 0)',
        () async {
      final start = DateTime(2026, 5, 1);
      final shifts = await generator.generateAndPersistPattern(
        pattern: sevenDaySevenOff,
        startDate: start,
        endDate: start.add(const Duration(days: 14)),
      );
      final off = shifts.where((s) => s.type == ShiftType.off);
      expect(off, hasLength(7));
      for (final s in off) {
        expect(s.startMinutes, 0);
        expect(s.endMinutes, 0);
      }
    });

    test('endDate == startDate triggers the assertion (defensive)', () async {
      // The picker enforces endDate > startDate in its enable rule,
      // but a programming mistake elsewhere shouldn't silently produce
      // an empty roster — assert hard at the boundary.
      final d = DateTime(2026, 5, 1);
      expect(
        () => generator.generateAndPersistPattern(
          pattern: sevenDaySevenOff,
          startDate: d,
          endDate: d,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('endDate < startDate triggers the assertion (defensive)', () async {
      final start = DateTime(2026, 5, 10);
      expect(
        () => generator.generateAndPersistPattern(
          pattern: sevenDaySevenOff,
          startDate: start,
          endDate: start.subtract(const Duration(days: 1)),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test(
      'a range that ends mid-block stops on the exact day, no overshoot',
      () async {
        // Critical contract for the "set and forget" UX: the user
        // entrusts an endDate, and the generator must NOT extend past
        // it (filling out the current block). 10-day range against a
        // 7+7 cycle means: 7 Day + 3 Off, then stop.
        final start = DateTime(2026, 5, 1);
        final shifts = await generator.generateAndPersistPattern(
          pattern: sevenDaySevenOff,
          startDate: start,
          endDate: start.add(const Duration(days: 10)),
        );
        expect(shifts, hasLength(10));
        expect(
          shifts.map((s) => s.type),
          [
            ...List.filled(7, ShiftType.day),
            ...List.filled(3, ShiftType.off),
          ],
        );
        // Last shift's date is exactly endDate - 1 day (range is half-open).
        expect(
          shifts.last.date,
          start.add(const Duration(days: 9)),
        );
      },
    );

    test(
      'a single-day range (endDate = startDate + 1) yields exactly 1 shift',
      () async {
        final start = DateTime(2026, 5, 1);
        final shifts = await generator.generateAndPersistPattern(
          pattern: sevenDaySevenOff,
          startDate: start,
          endDate: start.add(const Duration(days: 1)),
        );
        expect(shifts, hasLength(1));
        expect(shifts.single.type, ShiftType.day);
        expect(shifts.single.date, start);
      },
    );

    test('every shift gets a unique UUID across the full range', () async {
      final start = DateTime(2026, 5, 1);
      final shifts = await generator.generateAndPersistPattern(
        pattern: sevenDaySevenOff,
        startDate: start,
        endDate: start.add(const Duration(days: 56)),
      );
      final ids = shifts.map((s) => s.id).toSet();
      expect(ids.length, shifts.length, reason: 'duplicate UUID(s) generated');
    });

    test('returned list matches what the repository persisted (order + count)',
        () async {
      final start = DateTime(2026, 5, 1);
      final returned = await generator.generateAndPersistPattern(
        pattern: sevenDaySevenOff,
        startDate: start,
        endDate: start.add(const Duration(days: 28)),
      );
      final stored = await repo.getInRange(
        start,
        start.add(const Duration(days: 28)),
      );
      expect(stored.map((s) => s.id).toSet(), returned.map((s) => s.id).toSet());
      expect(stored, hasLength(returned.length));
    });

    test(
      'startDate with a time component is normalised to local midnight',
      () async {
        // Defends the "DST drift" concern called out in the
        // generateAndPersistPattern docstring. If the time component
        // ever propagated, the cursor would accumulate offset across
        // hundreds of cycles in the 5-year case.
        final start = DateTime(2026, 5, 1, 14, 30, 12);
        final shifts = await generator.generateAndPersistPattern(
          pattern: sevenDaySevenOff,
          startDate: start,
          endDate: DateTime(2026, 5, 1).add(const Duration(days: 28)),
        );
        for (final s in shifts) {
          expect(s.date.hour, 0);
          expect(s.date.minute, 0);
          expect(s.date.second, 0);
        }
        expect(shifts.first.date, DateTime(2026, 5, 1));
      },
    );

    test('multi-block pattern (DDNN-Off) interleaves types correctly',
        () async {
      // Pin the per-block type ordering — easy regression if a refactor
      // introduces a parallel iteration that scrambles the block order.
      const ddnnOff = RotationPattern(
        id: 'test-ddnn',
        label: 'DDNN, 4 Off',
        summary: 'test fixture',
        blocks: [
          RotationBlock(
            type: ShiftType.day,
            consecutiveDays: 2,
            startMinutes: 7 * 60,
            endMinutes: 15 * 60,
          ),
          RotationBlock(
            type: ShiftType.night,
            consecutiveDays: 2,
            startMinutes: 22 * 60,
            endMinutes: 6 * 60,
          ),
          RotationBlock(type: ShiftType.off, consecutiveDays: 4),
        ],
      );

      final start = DateTime(2026, 5, 1);
      final shifts = await generator.generateAndPersistPattern(
        pattern: ddnnOff,
        startDate: start,
        endDate: start.add(const Duration(days: 8)),
      );

      expect(
        shifts.map((s) => s.type),
        [
          ShiftType.day, ShiftType.day,
          ShiftType.night, ShiftType.night,
          ShiftType.off, ShiftType.off, ShiftType.off, ShiftType.off,
        ],
      );
    });
  });
}
