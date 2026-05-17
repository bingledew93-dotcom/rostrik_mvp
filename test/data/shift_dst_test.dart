import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

/// DST-safety regression tests for `Shift.startDateTime` / `endDateTime`.
///
/// The properties asserted hold regardless of the test runner's local
/// timezone. The OLD `date.add(Duration(minutes: M))` implementation
/// would fail these on a DST boundary day (1-hour offset in the local
/// hour/minute fields); the new explicit-constructor implementation
/// preserves the local hour/minute by construction.
void main() {
  group('Shift.startDateTime preserves local hour/minute', () {
    test('on an arbitrary non-DST date', () {
      final s = Shift(
        id: 'a',
        date: DateTime(2026, 6, 15),
        type: ShiftType.day,
        startMinutes: 7 * 60 + 30, // 07:30
        endMinutes: 15 * 60,
      );
      expect(s.startDateTime.hour, 7);
      expect(s.startDateTime.minute, 30);
      expect(s.startDateTime.year, 2026);
      expect(s.startDateTime.month, 6);
      expect(s.startDateTime.day, 15);
    });

    test('on US spring-forward day (2026-03-08)', () {
      // 2026-03-08 is the US DST spring-forward day; clocks jump from
      // 02:00 to 03:00 local. A 07:00 alarm on that date must still
      // resolve to 07:00 local — that's what the alarm engine and the
      // wake-up screen depend on.
      final s = Shift(
        id: 'spring',
        date: DateTime(2026, 3, 8),
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      );
      expect(s.startDateTime.hour, 7);
      expect(s.startDateTime.minute, 0);
      expect(s.startDateTime.day, 8);
    });

    test('on EU spring-forward day (2026-03-29)', () {
      final s = Shift(
        id: 'eu-spring',
        date: DateTime(2026, 3, 29),
        type: ShiftType.day,
        startMinutes: 6 * 60,
        endMinutes: 14 * 60,
      );
      expect(s.startDateTime.hour, 6);
      expect(s.startDateTime.minute, 0);
      expect(s.startDateTime.day, 29);
    });

    test('on US fall-back day (2026-11-01)', () {
      // The "ambiguous" hour. Dart picks one of the two 01:00 local
      // instants; we don't care which — what matters is the hour field
      // reads back exactly as input.
      final s = Shift(
        id: 'fall',
        date: DateTime(2026, 11, 1),
        type: ShiftType.day,
        startMinutes: 1 * 60 + 30, // 01:30
        endMinutes: 9 * 60,
      );
      expect(s.startDateTime.hour, 1);
      expect(s.startDateTime.minute, 30);
    });
  });

  group('Shift.endDateTime preserves local hour/minute', () {
    test('non-overnight: end stays on the same calendar day', () {
      final s = Shift(
        id: 'normal',
        date: DateTime(2026, 6, 15),
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      );
      expect(s.endDateTime.day, 15);
      expect(s.endDateTime.hour, 15);
      expect(s.endDateTime.minute, 0);
    });

    test('overnight: end rolls onto the next calendar day with correct time',
        () {
      final s = Shift(
        id: 'night',
        date: DateTime(2026, 6, 15),
        type: ShiftType.night,
        startMinutes: 22 * 60,
        endMinutes: 6 * 60, // 06:00 next day
      );
      expect(s.endDateTime.day, 16);
      expect(s.endDateTime.hour, 6);
      expect(s.endDateTime.minute, 0);
    });

    test(
      'overnight rolling into a DST spring-forward day keeps the local hour',
      () {
        // Shift on 2026-03-07 ending on 2026-03-08 at 06:00 local. The
        // OLD `date.add(Duration(days: 1, minutes: 360))` math added 24
        // wall-clock hours + 6 hours = 30 absolute hours, which lands
        // an hour off across the lost hour. The fix uses
        // `DateTime(2026, 3, 8, 6, 0)` and resolves to 06:00 local
        // regardless of the DST jump.
        final s = Shift(
          id: 'night-into-spring',
          date: DateTime(2026, 3, 7),
          type: ShiftType.night,
          startMinutes: 22 * 60,
          endMinutes: 6 * 60,
        );
        expect(s.endDateTime.year, 2026);
        expect(s.endDateTime.month, 3);
        expect(s.endDateTime.day, 8);
        expect(s.endDateTime.hour, 6);
        expect(s.endDateTime.minute, 0);
      },
    );

    test('month rollover via day overflow (Jan 31 → Feb 1)', () {
      final s = Shift(
        id: 'rollover',
        date: DateTime(2026, 1, 31),
        type: ShiftType.night,
        startMinutes: 22 * 60,
        endMinutes: 6 * 60,
      );
      expect(s.endDateTime.year, 2026);
      expect(s.endDateTime.month, 2);
      expect(s.endDateTime.day, 1);
      expect(s.endDateTime.hour, 6);
    });

    test('year rollover (Dec 31 → Jan 1)', () {
      final s = Shift(
        id: 'eoy',
        date: DateTime(2026, 12, 31),
        type: ShiftType.night,
        startMinutes: 22 * 60,
        endMinutes: 6 * 60,
      );
      expect(s.endDateTime.year, 2027);
      expect(s.endDateTime.month, 1);
      expect(s.endDateTime.day, 1);
    });
  });
}
