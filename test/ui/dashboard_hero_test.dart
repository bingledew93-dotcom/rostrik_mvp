import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/cycle_block.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_cycle.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/ui/dashboard_hero.dart';

void main() {
  Shift shift({
    required String id,
    required DateTime date,
    required ShiftType type,
    required int startMin,
    required int endMin,
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: startMin,
        endMinutes: endMin,
      );

  group('buildDashboardHero — Tier A (next / in-progress shift)', () {
    test('upcoming work shift mirrors the Dashboard countdown card', () {
      final now = DateTime(2026, 8, 10, 12, 0);
      final hero = buildDashboardHero(
        shifts: [
          shift(
            id: 'd',
            date: DateTime(2026, 8, 11),
            type: ShiftType.day,
            startMin: 6 * 60,
            endMin: 14 * 60,
          ),
        ],
        cycles: const [],
        now: now,
        use24Hour: false,
      );
      expect(hero.badge, '☀️ Day shift');
      expect(hero.mainText, 'Starts in 18h'); // 12:00 → next-day 06:00
      expect(hero.subtitle, 'Starts tomorrow at 06:00 AM');
      expect(hero.shiftType, ShiftType.day);
    });

    test('Afternoon shift gets its own badge + accent type', () {
      final now = DateTime(2026, 8, 10, 12, 0);
      final hero = buildDashboardHero(
        shifts: [
          shift(
            id: 'a',
            date: DateTime(2026, 8, 11),
            type: ShiftType.afternoon,
            startMin: 14 * 60,
            endMin: 22 * 60,
          ),
        ],
        cycles: const [],
        now: now,
        use24Hour: false,
      );
      expect(hero.badge, '🌇 Afternoon shift');
      expect(hero.shiftType, ShiftType.afternoon);
    });

    test('an in-progress shift shows "Ends in" + a "Started" subtitle', () {
      final now = DateTime(2026, 8, 10, 12, 0);
      final hero = buildDashboardHero(
        shifts: [
          shift(
            id: 'n',
            date: DateTime(2026, 8, 10),
            type: ShiftType.night,
            startMin: 8 * 60, // started 08:00
            endMin: 16 * 60, // ends 16:00
          ),
        ],
        cycles: const [],
        now: now,
        use24Hour: false,
      );
      expect(hero.badge, '🌙 Night shift');
      expect(hero.mainText, 'Ends in 4h');
      expect(hero.subtitle, 'Started today at 08:00 AM');
      expect(hero.shiftType, ShiftType.night);
    });

    test('honours the 24-hour preference in the subtitle', () {
      final now = DateTime(2026, 8, 10, 12, 0);
      final hero = buildDashboardHero(
        shifts: [
          shift(
            id: 'd',
            date: DateTime(2026, 8, 11),
            type: ShiftType.day,
            startMin: 6 * 60,
            endMin: 14 * 60,
          ),
        ],
        cycles: const [],
        now: now,
        use24Hour: true,
      );
      expect(hero.subtitle, 'Starts tomorrow at 06:00');
    });
  });

  group('buildDashboardHero — Tier B (rotation fallback, no next shift)', () {
    // 2 Day then 2 Off, anchored Aug 10. Aug 12 is the first OFF day.
    final cycle = ShiftCycle(
      id: 'c',
      label: 'x',
      summary: 'x',
      startDate: DateTime(2026, 8, 10),
      endDate: DateTime(2026, 8, 20),
      createdAt: DateTime(2026, 8, 1),
      anchorDate: DateTime(2026, 8, 10),
      blocks: const [
        CycleBlock(
          type: ShiftType.day,
          consecutiveDays: 2,
          startMinutes: 6 * 60,
          endMinutes: 14 * 60,
        ),
        CycleBlock(type: ShiftType.off, consecutiveDays: 2),
      ],
    );

    test('currently OFF → "Day X of Y — Off" + "Back on in N days"', () {
      final now = DateTime(2026, 8, 12, 12, 0);
      final hero = buildDashboardHero(
        shifts: const [],
        cycles: [cycle],
        now: now,
        use24Hour: false,
      );
      expect(hero.badge, '🛌 Off / RDO');
      expect(hero.mainText, 'Day 1 of 2 — Off');
      expect(hero.subtitle, 'Back on in 2 days');
      expect(hero.shiftType, ShiftType.off);
    });
  });

  group('buildDashboardHero — Tier C (nothing scheduled)', () {
    test('empty roster → rest-day fallback', () {
      final hero = buildDashboardHero(
        shifts: const [],
        cycles: const [],
        now: DateTime(2026, 8, 10, 12, 0),
        use24Hour: false,
      );
      expect(hero.badge, '🛌 Off / RDO');
      expect(hero.mainText, 'No upcoming shifts');
      expect(hero.subtitle, 'Enjoy your time off.');
      expect(hero.shiftType, ShiftType.off);
    });
  });

  group('formatHeroCountdown', () {
    test('minutes / hours / days rounding (always down)', () {
      expect(formatHeroCountdown(const Duration(minutes: 23)), '23m');
      expect(formatHeroCountdown(const Duration(hours: 14, minutes: 22)),
          '14h 22m');
      expect(formatHeroCountdown(const Duration(hours: 6)), '6h');
      expect(
        formatHeroCountdown(const Duration(days: 3, hours: 14)),
        '3d 14h',
      );
      expect(formatHeroCountdown(const Duration(days: 6, hours: 1)), '6d 1h');
      expect(formatHeroCountdown(const Duration(seconds: -5)), '0m');
    });
  });

  group('heroBadge', () {
    test('emoji + label per type', () {
      expect(heroBadge(ShiftType.day), '☀️ Day shift');
      expect(heroBadge(ShiftType.afternoon), '🌇 Afternoon shift');
      expect(heroBadge(ShiftType.night), '🌙 Night shift');
      expect(heroBadge(ShiftType.off), '🛌 Off / RDO');
    });
  });
}
