import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/services/widget_forecast.dart';
import 'package:rostrik_mvp/ui/dashboard_hero.dart';

/// The forecast is what stops the home-screen widget freezing, so these tests
/// mostly guard one property: the segment covering an instant must render the
/// same thing the Dashboard hero would render AT that instant — not at the
/// instant the forecast happened to be built.
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

  /// Mirrors `RostrikWidgetProvider.currentSegment` — linear scan for the
  /// window containing [at].
  WidgetHeroSegment? segmentAt(List<WidgetHeroSegment> f, DateTime at) {
    for (final s in f) {
      if (!at.isBefore(s.from) && at.isBefore(s.to)) return s;
    }
    return null;
  }

  group('buildWidgetForecast — coverage', () {
    test('segments tile [now, horizon) with no gaps and no overlaps', () {
      final now = DateTime(2026, 8, 10, 12, 0);
      final forecast = buildWidgetForecast(
        shifts: [
          shift(
            id: 'a',
            date: DateTime(2026, 8, 11),
            type: ShiftType.day,
            startMin: 6 * 60,
            endMin: 14 * 60,
          ),
          shift(
            id: 'b',
            date: DateTime(2026, 8, 12),
            type: ShiftType.night,
            startMin: 22 * 60,
            endMin: 6 * 60, // overnight: 22:00 -> 06:00 next day
          ),
        ],
        cycles: const [],
        now: now,
        use24Hour: true,
        horizonDays: 7,
      );

      expect(forecast, isNotEmpty);
      expect(forecast.first.from, now);
      expect(forecast.last.to, DateTime(2026, 8, 17));
      for (var i = 0; i < forecast.length; i++) {
        expect(forecast[i].to.isAfter(forecast[i].from), isTrue,
            reason: 'segment $i is empty or inverted');
        if (i + 1 < forecast.length) {
          expect(forecast[i].to, forecast[i + 1].from,
              reason: 'gap/overlap between segments $i and ${i + 1}');
        }
      }
    });

    test('an empty roster still yields one covering segment', () {
      final now = DateTime(2026, 8, 10, 12, 0);
      final forecast = buildWidgetForecast(
        shifts: const [],
        cycles: const [],
        now: now,
        use24Hour: true,
        horizonDays: 3,
      );
      expect(forecast, hasLength(1));
      expect(forecast.single.staticMain, 'No upcoming shifts');
      expect(forecast.single.countdownTo, isNull);
    });
  });

  group('buildWidgetForecast — the freeze this fixes', () {
    test('countdown segments carry a fixed target, not a rendered duration',
        () {
      final now = DateTime(2026, 8, 10, 12, 0);
      final forecast = buildWidgetForecast(
        shifts: [
          shift(
            id: 'a',
            date: DateTime(2026, 8, 11),
            type: ShiftType.day,
            startMin: 6 * 60,
            endMin: 14 * 60,
          ),
        ],
        cycles: const [],
        now: now,
        use24Hour: true,
        horizonDays: 3,
      );

      final seg = segmentAt(forecast, now)!;
      expect(seg.countdownPrefix, 'Starts in');
      // The whole point: an absolute instant the native side counts towards.
      expect(seg.countdownTo, DateTime(2026, 8, 11, 6, 0));
    });

    test(
        'the target stays put as time passes inside a segment, so the rendered '
        'countdown shrinks', () {
      final now = DateTime(2026, 8, 10, 12, 0);
      final forecast = buildWidgetForecast(
        shifts: [
          shift(
            id: 'a',
            date: DateTime(2026, 8, 10),
            type: ShiftType.night,
            startMin: 22 * 60,
            endMin: 6 * 60, // overnight: 22:00 -> 06:00 next day
          ),
        ],
        cycles: const [],
        now: now,
        use24Hour: true,
        horizonDays: 3,
      );

      final atNoon = segmentAt(forecast, now)!;
      final atFive = segmentAt(forecast, DateTime(2026, 8, 10, 17, 0))!;
      // Same window, same target — only the subtraction the widget does moves.
      expect(atNoon.countdownTo, atFive.countdownTo);
      expect(
        atNoon.countdownTo!.difference(DateTime(2026, 8, 10, 17, 0)),
        const Duration(hours: 5),
      );
    });

    test('crossing a shift start flips the segment to the "Ends in" countdown',
        () {
      final now = DateTime(2026, 8, 10, 12, 0);
      final forecast = buildWidgetForecast(
        shifts: [
          shift(
            id: 'a',
            date: DateTime(2026, 8, 10),
            type: ShiftType.day,
            startMin: 14 * 60,
            endMin: 22 * 60,
          ),
        ],
        cycles: const [],
        now: now,
        use24Hour: true,
        horizonDays: 3,
      );

      final before = segmentAt(forecast, DateTime(2026, 8, 10, 13, 59))!;
      final during = segmentAt(forecast, DateTime(2026, 8, 10, 14, 1))!;

      expect(before.countdownPrefix, 'Starts in');
      expect(before.countdownTo, DateTime(2026, 8, 10, 14, 0));
      expect(during.countdownPrefix, 'Ends in');
      expect(during.countdownTo, DateTime(2026, 8, 10, 22, 0));
    });

    test('a shift ending hands the countdown to the next shift', () {
      final now = DateTime(2026, 8, 10, 12, 0);
      final forecast = buildWidgetForecast(
        shifts: [
          shift(
            id: 'a',
            date: DateTime(2026, 8, 10),
            type: ShiftType.day,
            startMin: 14 * 60,
            endMin: 22 * 60,
          ),
          shift(
            id: 'b',
            date: DateTime(2026, 8, 11),
            type: ShiftType.day,
            startMin: 14 * 60,
            endMin: 22 * 60,
          ),
        ],
        cycles: const [],
        now: now,
        use24Hour: true,
        horizonDays: 3,
      );

      final after = segmentAt(forecast, DateTime(2026, 8, 10, 22, 30))!;
      expect(after.countdownPrefix, 'Starts in');
      expect(after.countdownTo, DateTime(2026, 8, 11, 14, 0));
    });
  });

  group('buildWidgetForecast — payload hygiene', () {
    test('midnight inside a rest stretch does not split the timeline', () {
      final now = DateTime(2026, 8, 10, 12, 0);
      // Nothing scheduled at all: every midnight is a boundary instant, but the
      // hero renders identically across all of them, so merging must collapse
      // them into a single window.
      final forecast = buildWidgetForecast(
        shifts: const [],
        cycles: const [],
        now: now,
        use24Hour: true,
        horizonDays: 30,
      );
      expect(forecast, hasLength(1));
    });

    test('maxSegments caps the payload', () {
      final now = DateTime(2026, 8, 10, 12, 0);
      final shifts = <Shift>[
        for (var i = 1; i <= 40; i++)
          shift(
            id: 's$i',
            date: DateTime(2026, 8, 10 + i),
            type: ShiftType.day,
            startMin: 6 * 60,
            endMin: 14 * 60,
          ),
      ];
      final forecast = buildWidgetForecast(
        shifts: shifts,
        cycles: const [],
        now: now,
        use24Hour: true,
        horizonDays: 60,
        maxSegments: 12,
      );
      expect(forecast.length, lessThanOrEqualTo(12));
    });

    test('encodes to the JSON shape RostrikWidgetProvider parses', () {
      final now = DateTime(2026, 8, 10, 12, 0);
      final forecast = buildWidgetForecast(
        shifts: [
          shift(
            id: 'a',
            date: DateTime(2026, 8, 11),
            type: ShiftType.day,
            startMin: 6 * 60,
            endMin: 14 * 60,
          ),
        ],
        cycles: const [],
        now: now,
        use24Hour: true,
        horizonDays: 3,
      );

      final decoded = jsonDecode(encodeWidgetForecast(forecast)) as List;
      final first = decoded.first as Map<String, dynamic>;
      expect(first['from'], now.millisecondsSinceEpoch);
      expect(first['to'], isA<int>());
      expect(first['badge'], '☀️ Day shift');
      expect(first['type'], 'day');
      expect(first['cdTo'], DateTime(2026, 8, 11, 6, 0).millisecondsSinceEpoch);
      expect(first['cdPre'], 'Starts in');
      // Static-only segments must omit the countdown keys entirely — the
      // provider treats their absence as "render `main` verbatim".
      final tail = decoded.last as Map<String, dynamic>;
      if (!tail.containsKey('cdTo')) {
        expect(tail.containsKey('cdPre'), isFalse);
      }
    });
  });

  group('formatHeroCountdown parity contract', () {
    // RostrikWidgetProvider.formatCountdown is a hand port of
    // formatHeroCountdown. These are the boundary cases the Kotlin version is
    // written against; if the Dart rules change here, that port must follow or
    // the widget and the in-app hero will disagree about the same shift.
    test('documents the boundaries the Kotlin port must match', () {
      expect(formatHeroCountdown(Duration.zero), '0m');
      expect(formatHeroCountdown(const Duration(minutes: -5)), '0m');
      expect(formatHeroCountdown(const Duration(minutes: 23)), '23m');
      expect(formatHeroCountdown(const Duration(minutes: 59)), '59m');
      expect(formatHeroCountdown(const Duration(minutes: 60)), '1h');
      expect(formatHeroCountdown(const Duration(hours: 14, minutes: 22)),
          '14h 22m');
      expect(formatHeroCountdown(const Duration(hours: 23, minutes: 59)),
          '23h 59m');
      expect(formatHeroCountdown(const Duration(hours: 24)), '1d');
      expect(formatHeroCountdown(const Duration(days: 3, hours: 14)), '3d 14h');
      expect(
        formatHeroCountdown(const Duration(days: 6, hours: 1, minutes: 30)),
        '6d 1h',
      );
    });
  });
}
