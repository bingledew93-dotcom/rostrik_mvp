import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/shift_block.dart';
import 'package:rostrik_mvp/logic/shift_generator.dart';
import 'package:rostrik_mvp/state/draft_roster_controller.dart';

import '../alarms/fakes.dart';

/// A complete, generator-ready block on its own cycle day.
ShiftBlock _block(ShiftType type, int day, {int start = 6 * 60, int end = 18 * 60}) =>
    ShiftBlock(
      type: type,
      startDayIndex: day,
      endDayIndex: day,
      startMinutes: type == ShiftType.off ? 0 : start,
      endMinutes: type == ShiftType.off ? 0 : end,
    );

/// A bare scanned time: working type, end == start (the zero-duration
/// placeholder [ScannedRosterInjection.map] produces) → flagged needsEndTime.
ShiftBlock _bare(int day, {int start = 9 * 60}) => ShiftBlock(
      type: ShiftType.day,
      startDayIndex: day,
      endDayIndex: day,
      startMinutes: start,
      endMinutes: start,
    );

void main() {
  final anchor = DateTime(2026, 6, 1);

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

  DraftRosterController make(List<ShiftBlock> blocks) => DraftRosterController(
        generator: generator,
        anchorDate: anchor,
        initialBlocks: blocks,
      );

  group('draft state derivation', () {
    test('days are dated from the anchor by position', () {
      final c = make([
        _block(ShiftType.day, 0),
        _block(ShiftType.off, 1),
        _block(ShiftType.night, 2, start: 18 * 60, end: 6 * 60),
      ]);
      final days = c.days;
      expect(days.map((d) => d.date), [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 2),
        DateTime(2026, 6, 3),
      ]);
      expect(days.map((d) => d.id).toSet(), hasLength(3)); // stable, unique
    });

    test('attentionCount + canCommit track needsEndTime', () {
      final c = make([_block(ShiftType.day, 0), _bare(1)]);
      expect(c.attentionCount, 1);
      expect(c.canCommit, isFalse);

      c.setEndMinutes(1, 17 * 60);
      expect(c.attentionCount, 0);
      expect(c.canCommit, isTrue);
    });

    test('an empty draft cannot be committed', () {
      final c = make([_block(ShiftType.day, 0)]);
      c.removeAt(0);
      expect(c.isEmpty, isTrue);
      expect(c.canCommit, isFalse);
    });
  });

  group('mutations', () {
    test('removeAt returns the row and re-dates the survivors', () {
      final c = make([
        _block(ShiftType.day, 0),
        _block(ShiftType.off, 1),
        _block(ShiftType.night, 2, start: 18 * 60, end: 6 * 60),
      ]);
      var notifications = 0;
      c.addListener(() => notifications++);

      final removed = c.removeAt(1); // delete the Off in the middle
      expect(removed.index, 1);
      expect(removed.block.type, ShiftType.off);
      expect(notifications, 1);

      // The night shift slid up onto June 2.
      expect(c.days.map((d) => d.block.type), [ShiftType.day, ShiftType.night]);
      expect(c.days[1].date, DateTime(2026, 6, 2));
    });

    test('insertAt undoes a removal at the same position', () {
      final c = make([_block(ShiftType.day, 0), _block(ShiftType.night, 1)]);
      final removed = c.removeAt(0);
      c.insertAt(removed.index, removed.block);
      expect(c.days.map((d) => d.block.type), [ShiftType.day, ShiftType.night]);
    });

    test('setType: Off → working seeds the standard band (clears the flag)', () {
      final c = make([_block(ShiftType.off, 0)]);
      c.setType(0, ShiftType.night);
      final b = c.days.single.block;
      expect(b.type, ShiftType.night);
      expect(b.startMinutes, 18 * 60);
      expect(b.endMinutes, 6 * 60);
      expect(c.days.single.needsEndTime, isFalse);
    });

    test('setType: working → working keeps the scanned times', () {
      final c = make([_block(ShiftType.day, 0, start: 7 * 60, end: 15 * 60)]);
      c.setType(0, ShiftType.afternoon);
      final b = c.days.single.block;
      expect(b.type, ShiftType.afternoon);
      expect(b.startMinutes, 7 * 60);
      expect(b.endMinutes, 15 * 60);
    });

    test('setType: working → Off clears the times to 0/0', () {
      final c = make([_block(ShiftType.day, 0)]);
      c.setType(0, ShiftType.off);
      final b = c.days.single.block;
      expect(b.startMinutes, 0);
      expect(b.endMinutes, 0);
    });
  });

  group('commit', () {
    test('persists the sequence on consecutive dates and returns true',
        () async {
      final c = make([
        _block(ShiftType.day, 0),
        _block(ShiftType.off, 1),
        _block(ShiftType.night, 2, start: 18 * 60, end: 6 * 60),
      ]);
      final ok = await c.commit();
      expect(ok, isTrue);
      expect(await cycles.getAll(), hasLength(1));

      final written =
          await shifts.getInRange(DateTime(2026, 6, 1), DateTime(2026, 6, 4));
      expect(written, hasLength(3));
      expect(written.map((s) => s.date), [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 2),
        DateTime(2026, 6, 3),
      ]);
    });

    test('re-normalises day indices after a delete (no gap in dates)', () async {
      final c = make([
        _block(ShiftType.day, 0),
        _block(ShiftType.off, 1),
        _block(ShiftType.night, 2, start: 18 * 60, end: 6 * 60),
      ]);
      c.removeAt(1); // remove the middle day

      final ok = await c.commit();
      expect(ok, isTrue);
      final written =
          await shifts.getInRange(DateTime(2026, 6, 1), DateTime(2026, 6, 4));
      expect(written.map((s) => s.type), [ShiftType.day, ShiftType.night]);
      expect(written.map((s) => s.date), [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 2), // night compacted onto day 2, not day 3
      ]);
    });

    test('refuses to commit while a row still needs an end time', () async {
      final c = make([_block(ShiftType.day, 0), _bare(1)]);
      final ok = await c.commit();
      expect(ok, isFalse);
      expect(await cycles.getAll(), isEmpty);
    });

    test('surfaces a generator rejection via commitError, writes nothing',
        () async {
      // Pre-seed an 08:00–12:00 shift on the anchor date.
      await generator.generateAndPersist(
        startDate: anchor,
        startMinutes: 8 * 60,
        endMinutes: 12 * 60,
        consecutiveDays: 1,
        shiftType: ShiftType.day,
      );
      final cyclesBefore = (await cycles.getAll()).length;

      // A draft whose first day overlaps 10:00–14:00 on the same date.
      final c = make([_block(ShiftType.day, 0, start: 10 * 60, end: 14 * 60)]);
      final ok = await c.commit();

      expect(ok, isFalse);
      expect(c.commitError, isNotNull);
      expect((await cycles.getAll()).length, cyclesBefore); // no new cycle
    });
  });
}
