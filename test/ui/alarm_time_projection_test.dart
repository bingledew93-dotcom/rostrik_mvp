import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/ui/alarm_time_projection.dart';
import 'package:rostrik_mvp/ui/shift_format.dart';

void main() {
  final now = DateTime(2026, 6, 2, 12, 0); // fixed "now" for determinism

  Shift shift(
    ShiftType type,
    DateTime date,
    int startMinutes,
  ) =>
      Shift(
        id: '$type-${date.toIso8601String()}',
        date: date,
        type: type,
        startMinutes: startMinutes,
        endMinutes: (startMinutes + 8 * 60) % 1440,
      );

  group('rosterStartMinutesForType', () {
    test('returns null when no shift of that type exists', () {
      final roster = [shift(ShiftType.night, DateTime(2026, 6, 3), 22 * 60)];
      expect(rosterStartMinutesForType(roster, ShiftType.day, now: now), isNull);
    });

    test('prefers the NEXT upcoming shift of the type', () {
      final roster = [
        shift(ShiftType.day, DateTime(2026, 6, 1), 6 * 60), // past, 06:00
        shift(ShiftType.day, DateTime(2026, 6, 5), 9 * 60), // future, 09:00
        shift(ShiftType.day, DateTime(2026, 6, 10), 7 * 60), // farther future
      ];
      // The soonest upcoming Day shift (Jun 5, 09:00) wins.
      expect(rosterStartMinutesForType(roster, ShiftType.day, now: now), 9 * 60);
    });

    test('falls back to the most recent past shift when none upcoming', () {
      final roster = [
        shift(ShiftType.day, DateTime(2026, 5, 20), 5 * 60),
        shift(ShiftType.day, DateTime(2026, 5, 30), 8 * 60), // latest past
      ];
      expect(rosterStartMinutesForType(roster, ShiftType.day, now: now), 8 * 60);
    });
  });

  group('resolveShiftStartMinutes', () {
    test('uses the roster value when present', () {
      final roster = [shift(ShiftType.day, DateTime(2026, 6, 5), 6 * 60)];
      expect(resolveShiftStartMinutes(roster, ShiftType.day, now: now), 6 * 60);
    });

    test('falls back to the per-type default for an empty roster', () {
      expect(resolveShiftStartMinutes(const [], ShiftType.day, now: now),
          kDefaultShiftStartMinutes[ShiftType.day]);
      expect(resolveShiftStartMinutes(const [], ShiftType.night, now: now),
          22 * 60);
      expect(resolveShiftStartMinutes(const [], ShiftType.afternoon, now: now),
          15 * 60);
    });
  });

  group('fireClockMinutes', () {
    test('subtracts the lead from the shift start', () {
      expect(fireClockMinutes(7 * 60, 90), 5 * 60 + 30); // 07:00 − 1h30 = 05:30
      expect(fireClockMinutes(7 * 60, 60), 6 * 60); // 07:00 − 1h = 06:00
    });

    test('wraps across midnight when the lead crosses 00:00', () {
      // 00:30 shift, 90-min lead → 23:00 the previous day.
      expect(fireClockMinutes(30, 90), 23 * 60);
      // Exactly midnight start, 1-min lead → 23:59.
      expect(fireClockMinutes(0, 1), 23 * 60 + 59);
    });

    test('a zero lead returns the shift start itself', () {
      expect(fireClockMinutes(22 * 60, 0), 22 * 60);
    });
  });

  group('formatClock12h', () {
    test('formats AM/PM with a zero-padded hour', () {
      expect(formatClock12h(4 * 60 + 30), '04:30 AM');
      expect(formatClock12h(0), '12:00 AM'); // midnight
      expect(formatClock12h(12 * 60), '12:00 PM'); // noon
      expect(formatClock12h(13 * 60 + 5), '01:05 PM');
      expect(formatClock12h(22 * 60), '10:00 PM');
    });

    test('normalises out-of-range / negative minutes into the day', () {
      expect(formatClock12h(1440), '12:00 AM'); // wraps to midnight
      expect(formatClock12h(-30), '11:30 PM'); // wraps to previous day
    });
  });
}
