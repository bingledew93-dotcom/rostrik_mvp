import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/adhoc_archive.dart';

import '../alarms/fakes.dart';

void main() {
  // Reference "now". Grace is 24h, so the archive cutoff is 2026-06-11 10:00 —
  // an ad-hoc shift is archived only if its END is strictly before that.
  final now = DateTime(2026, 6, 12, 10, 0);

  late FakeShiftRepository shifts;

  setUp(() => shifts = FakeShiftRepository());
  tearDown(() => shifts.dispose());

  Shift adhoc({
    required String id,
    required DateTime date,
    int start = 7 * 60,
    int end = 15 * 60,
    ShiftType type = ShiftType.day,
    bool archived = false,
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: start,
        endMinutes: end,
        isAdHoc: true,
        isArchived: archived,
      );

  group('archiveExpiredAdHocShifts', () {
    test('archives an ad-hoc shift whose end is >24h past', () async {
      // Ends 2026-06-11 09:00 — 25h before now, before the 10:00 cutoff.
      await shifts.upsert(
        adhoc(id: 'expired', date: DateTime(2026, 6, 11), start: 7 * 60, end: 9 * 60),
      );

      final count = await archiveExpiredAdHocShifts(shifts, now: now);

      expect(count, 1);
      final loaded = await shifts.getById('expired');
      expect(loaded, isNotNull, reason: 'archive must NEVER delete the record');
      expect(loaded!.isArchived, isTrue);
      expect(loaded.isAdHoc, isTrue, reason: 'ad-hoc marker is preserved');
    });

    test('leaves an ad-hoc shift still inside the 24h grace untouched',
        () async {
      // Ends 2026-06-11 15:00 — only 19h ago, after the 10:00 cutoff.
      await shifts.upsert(
        adhoc(id: 'fresh', date: DateTime(2026, 6, 11), start: 11 * 60, end: 15 * 60),
      );

      final count = await archiveExpiredAdHocShifts(shifts, now: now);

      expect(count, 0);
      expect((await shifts.getById('fresh'))!.isArchived, isFalse);
    });

    test('a shift ending EXACTLY at the cutoff is NOT archived (strictly >)',
        () async {
      // endDateTime == cutoff (2026-06-11 10:00). "More than 24h past" is
      // strict, so the boundary shift is kept.
      await shifts.upsert(
        adhoc(id: 'boundary', date: DateTime(2026, 6, 11), start: 8 * 60, end: 10 * 60),
      );

      final count = await archiveExpiredAdHocShifts(shifts, now: now);

      expect(count, 0);
      expect((await shifts.getById('boundary'))!.isArchived, isFalse);
    });

    test('never touches a non-ad-hoc (rotation) shift, however old', () async {
      // Ancient, but isAdHoc=false → permanent roster, never swept.
      await shifts.upsert(Shift(
        id: 'rotation',
        date: DateTime(2024, 1, 1),
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
        cycleId: 'cycle-1',
      ));

      final count = await archiveExpiredAdHocShifts(shifts, now: now);

      expect(count, 0);
      expect((await shifts.getById('rotation'))!.isArchived, isFalse);
    });

    test('never archives a future-dated ad-hoc shift', () async {
      await shifts.upsert(adhoc(id: 'future', date: DateTime(2026, 6, 13)));

      final count = await archiveExpiredAdHocShifts(shifts, now: now);

      expect(count, 0);
      expect((await shifts.getById('future'))!.isArchived, isFalse);
    });

    test('uses endDateTime (overnight +1 day), not the shift date', () async {
      // Night shift on 06-10, 22:00→06:00 ends 2026-06-11 06:00 — before the
      // 10:00 cutoff, so it archives. (The shift DATE is 06-10; the END is what
      // matters, and the overnight roll is resolved by Shift.endDateTime.)
      await shifts.upsert(adhoc(
        id: 'overnight',
        date: DateTime(2026, 6, 10),
        type: ShiftType.night,
        start: 22 * 60,
        end: 6 * 60,
      ));

      final count = await archiveExpiredAdHocShifts(shifts, now: now);

      expect(count, 1);
      expect((await shifts.getById('overnight'))!.isArchived, isTrue);
    });

    test('is idempotent — a second pass archives nothing', () async {
      await shifts.upsert(
        adhoc(id: 'expired', date: DateTime(2026, 6, 10)),
      );

      expect(await archiveExpiredAdHocShifts(shifts, now: now), 1);
      expect(await archiveExpiredAdHocShifts(shifts, now: now), 0,
          reason: 'already-archived shifts are skipped');
    });

    test('preserves the full record (no deletions, count unchanged)', () async {
      await shifts.upsert(adhoc(id: 'a', date: DateTime(2026, 6, 10)));
      await shifts.upsert(adhoc(id: 'b', date: DateTime(2026, 6, 13))); // future
      await shifts.upsert(Shift(
        id: 'c',
        date: DateTime(2025, 1, 1),
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      )); // rotation

      await archiveExpiredAdHocShifts(shifts, now: now);

      // Every record still present — only one flag flipped.
      expect((await shifts.getAll()).map((s) => s.id).toSet(), {'a', 'b', 'c'});
    });

    test('archives only the expired subset and reports the count', () async {
      await shifts.upsert(adhoc(id: 'old1', date: DateTime(2026, 6, 9)));
      await shifts.upsert(adhoc(id: 'old2', date: DateTime(2026, 6, 10)));
      await shifts.upsert(adhoc(id: 'fresh', date: DateTime(2026, 6, 13)));

      final count = await archiveExpiredAdHocShifts(shifts, now: now);

      expect(count, 2);
      expect((await shifts.getById('old1'))!.isArchived, isTrue);
      expect((await shifts.getById('old2'))!.isArchived, isTrue);
      expect((await shifts.getById('fresh'))!.isArchived, isFalse);
    });
  });
}
