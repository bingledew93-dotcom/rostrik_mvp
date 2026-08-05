import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/work_history.dart';

void main() {
  // "Now" for the completed/future split. Anything ending before this is
  // history; anything ending at/after is still upcoming.
  final now = DateTime(2026, 6, 12, 10, 0);

  Shift mk({
    required String id,
    required DateTime date,
    int start = 7 * 60,
    int end = 15 * 60,
    ShiftType type = ShiftType.day,
    bool isAdHoc = true,
    bool isArchived = false,
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: start,
        endMinutes: end,
        isAdHoc: isAdHoc,
        isArchived: isArchived,
      );

  group('workHistoryShifts', () {
    test('includes a completed ad-hoc shift', () {
      final s = mk(id: 'done', date: DateTime(2026, 6, 1));
      expect(
        workHistoryShifts([s], now: now).map((x) => x.id),
        ['done'],
      );
    });

    test('includes a recently-completed ad-hoc shift NOT yet archived', () {
      // Ended this morning (<24h ago), so the cold-start sweep has not flipped
      // isArchived yet. It must still appear — keying off "archived" alone
      // would truncate the current pay period.
      final s = mk(
        id: 'fresh',
        date: DateTime(2026, 6, 12),
        start: 0,
        end: 8 * 60, // ends 08:00, before now (10:00)
        isArchived: false,
      );
      expect(workHistoryShifts([s], now: now).map((x) => x.id), ['fresh']);
    });

    test('includes an archived ad-hoc shift', () {
      final s = mk(
        id: 'archived',
        date: DateTime(2026, 5, 1),
        isArchived: true,
      );
      expect(workHistoryShifts([s], now: now).map((x) => x.id), ['archived']);
    });

    test('includes a completed rotation (non-ad-hoc) shift', () {
      // Full timesheet: rotation hours are the bulk of a payslip and must be
      // present, not just ad-hoc overtime.
      final s = mk(id: 'rota', date: DateTime(2025, 1, 1), isAdHoc: false);
      expect(workHistoryShifts([s], now: now).map((x) => x.id), ['rota']);
    });

    test('excludes a future / not-yet-finished ad-hoc shift', () {
      final s = mk(id: 'future', date: DateTime(2026, 6, 20));
      expect(workHistoryShifts([s], now: now), isEmpty);
    });

    test('excludes an in-progress ad-hoc shift (end is still ahead)', () {
      // Today, 09:00 → 17:00. Started, but ends at 17:00 > now (10:00).
      final s = mk(id: 'wip', date: DateTime(2026, 6, 12), start: 9 * 60, end: 17 * 60);
      expect(workHistoryShifts([s], now: now), isEmpty);
    });

    test('excludes an OFF ad-hoc entry (no hours to verify)', () {
      final s = mk(
        id: 'off',
        date: DateTime(2026, 6, 1),
        type: ShiftType.off,
        start: 0,
        end: 0,
      );
      expect(workHistoryShifts([s], now: now), isEmpty);
    });

    test('counts a completed overnight shift via endDateTime', () {
      // 22:00 on 06-10 → 06:00 on 06-11; both before now.
      final s = mk(
        id: 'night',
        date: DateTime(2026, 6, 10),
        type: ShiftType.night,
        start: 22 * 60,
        end: 6 * 60,
      );
      expect(workHistoryShifts([s], now: now).map((x) => x.id), ['night']);
    });

    test('sorts ascending by start instant (ledger order)', () {
      final a = mk(id: 'a', date: DateTime(2026, 6, 3));
      final b = mk(id: 'b', date: DateTime(2026, 6, 1));
      final c = mk(id: 'c', date: DateTime(2026, 6, 2));
      expect(
        workHistoryShifts([a, b, c], now: now).map((x) => x.id),
        ['b', 'c', 'a'],
      );
    });
  });

  group('formatDecimalHours', () {
    test('whole and half hours', () {
      expect(formatDecimalHours(8 * 60), '8.00');
      expect(formatDecimalHours(8 * 60 + 30), '8.50');
    });

    test('zero and sub-hour', () {
      expect(formatDecimalHours(0), '0.00');
      expect(formatDecimalHours(45), '0.75');
    });
  });

  group('workedMinutes (payroll protection)', () {
    test('an active shift counts its full duration', () {
      expect(
        workedMinutes(mk(id: 'a', date: DateTime(2026, 6, 1))), // 07:00–15:00
        8 * 60,
      );
    });

    test('a paused shift counts ZERO worked minutes', () {
      final paused =
          mk(id: 'p', date: DateTime(2026, 6, 1)).copyWith(isPaused: true);
      expect(workedMinutes(paused), 0);
    });
  });

  group('workHistoryStatus', () {
    test('active shift → Active', () {
      expect(workHistoryStatus(mk(id: 'a', date: DateTime(2026, 6, 1))),
          'Active');
    });

    test('paused without reason → Paused', () {
      final s = mk(id: 'p', date: DateTime(2026, 6, 1)).copyWith(isPaused: true);
      expect(workHistoryStatus(s), 'Paused');
    });

    test('paused with reason → Paused: <reason>', () {
      final s = mk(id: 'p', date: DateTime(2026, 6, 1))
          .copyWith(isPaused: true, pauseReason: 'Annual Leave');
      expect(workHistoryStatus(s), 'Paused: Annual Leave');
    });
  });

  group('workHistoryShiftTypeLabel', () {
    test('ad-hoc → Ad-Hoc, rotation → Rotation', () {
      expect(
        workHistoryShiftTypeLabel(mk(id: 'a', date: DateTime(2026, 6, 1))),
        kAdHocShiftLabel,
      );
      expect(
        workHistoryShiftTypeLabel(
          mk(id: 'r', date: DateTime(2026, 6, 1), isAdHoc: false),
        ),
        kRotationShiftLabel,
      );
    });
  });

  group('workHistoryCsv', () {
    test('empty list yields the header alone (with trailing CRLF)', () {
      expect(workHistoryCsv(const []), '$kWorkHistoryCsvHeader\r\n');
    });

    test(
        'emits Date(ISO), Start, End (24h), Total Hours, Shift Type, Status '
        'per row', () {
      final s = mk(id: 'r', date: DateTime(2026, 5, 4), start: 7 * 60, end: 15 * 60);
      final csv = workHistoryCsv([s]);
      expect(
        csv,
        '$kWorkHistoryCsvHeader\r\n'
        '2026-05-04,07:00,15:00,8.00,Ad-Hoc,Active\r\n',
      );
    });

    test('the Shift Type column reflects isAdHoc (Rotation vs Ad-Hoc)', () {
      final rota = mk(id: 'rota', date: DateTime(2026, 5, 4), isAdHoc: false);
      final extra = mk(id: 'extra', date: DateTime(2026, 5, 5), isAdHoc: true);
      final csv = workHistoryCsv([rota, extra]);
      expect(csv.contains('2026-05-04,07:00,15:00,8.00,Rotation,Active'), isTrue);
      expect(csv.contains('2026-05-05,07:00,15:00,8.00,Ad-Hoc,Active'), isTrue);
    });

    test('overnight hours total is correct even though end < start clock', () {
      final s = mk(
        id: 'n',
        date: DateTime(2026, 5, 4),
        type: ShiftType.night,
        start: 22 * 60,
        end: 6 * 60,
      );
      // 22:00 → 06:00 = 8.00h; the End column still shows the clock time.
      expect(
        workHistoryCsv([s])
            .contains('2026-05-04,22:00,06:00,8.00,Ad-Hoc,Active'),
        isTrue,
      );
    });

    test('a PAUSED shift exports 0.00 hours + a Paused status', () {
      final s = mk(id: 'p', date: DateTime(2026, 5, 4))
          .copyWith(isPaused: true, pauseReason: 'Sick');
      // Hours forced to 0.00 (payroll protection); Status carries the reason.
      expect(
        workHistoryCsv([s]).contains('2026-05-04,07:00,15:00,0.00,Ad-Hoc,Paused: Sick'),
        isTrue,
      );
    });

    test('a paused shift with no reason exports just "Paused"', () {
      final s = mk(id: 'p', date: DateTime(2026, 5, 4)).copyWith(isPaused: true);
      expect(workHistoryCsv([s]).contains(',0.00,Ad-Hoc,Paused\r\n'), isTrue);
    });

    test('a comma in the pause reason is RFC-4180 quoted (comma-safe)', () {
      final s = mk(id: 'p', date: DateTime(2026, 5, 4))
          .copyWith(isPaused: true, pauseReason: 'Family, personal');
      // The Status field is wrapped in quotes so the comma doesn't break columns.
      expect(
        workHistoryCsv([s]).contains('"Paused: Family, personal"'),
        isTrue,
      );
    });

    test('half-hour shift formats to 8.50', () {
      final s = mk(id: 'h', date: DateTime(2026, 5, 4), start: 7 * 60, end: 15 * 60 + 30);
      expect(workHistoryCsv([s]).contains(',8.50'), isTrue);
    });

    test('rows follow the passed order', () {
      final rows = workHistoryShifts(
        [
          mk(id: 'a', date: DateTime(2026, 6, 3)),
          mk(id: 'b', date: DateTime(2026, 6, 1)),
        ],
        now: now,
      );
      final csv = workHistoryCsv(rows);
      final lines = csv.trimRight().split('\r\n');
      expect(lines.first, kWorkHistoryCsvHeader);
      expect(lines[1], startsWith('2026-06-01')); // earliest first
      expect(lines[2], startsWith('2026-06-03'));
    });
  });
}
