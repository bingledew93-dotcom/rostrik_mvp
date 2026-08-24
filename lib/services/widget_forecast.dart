/// Pre-computed home-screen-widget state, sliced into time windows.
///
/// ## Why this exists
///
/// The widget used to be handed FULLY RENDERED strings — `"Starts in 6d 1h"` —
/// computed against the `now` of whichever app run last pushed them. The widget
/// process outlives the app by days, so that string was a photograph of a
/// clock: it stopped the instant it was written, and every later redraw
/// faithfully re-painted the same dead value. That is the "widget freezes to
/// what the app last showed" bug.
///
/// The fix is to push something TIME-INDEPENDENT and let the native side finish
/// the render against its own clock. But we deliberately do NOT reimplement the
/// roster logic in Kotlin — [buildDashboardHero] stays the single source of
/// truth. Instead Dart evaluates the hero at every instant where its output can
/// change and ships the resulting piecewise-constant timeline. Kotlin then does
/// only two things: pick the segment covering `now`, and subtract two numbers.
///
/// ## Why a segment list is sufficient
///
/// The hero's output is constant EXCEPT at three kinds of instant:
///   * a shift start (upcoming becomes in-progress, or a new shift becomes
///     next),
///   * a shift end (in-progress gives way to the following shift),
///   * local midnight (flips the "tomorrow"/"today" wording and the rotation
///     day).
///
/// Between consecutive boundaries the only thing that moves is the countdown,
/// and that is fully described by [WidgetHeroSegment.countdownTo] — a fixed
/// instant the native side counts towards. So sampling the hero once per
/// boundary reproduces it exactly, with no logic duplicated off-platform.
///
/// Everything here is pure and offline: it reads the local Hive roster and
/// touches no network, no clock beyond the injected `now`, and no plugins.
library;

import 'dart:convert';

import '../data/models/shift.dart';
import '../data/models/shift_cycle.dart';
import '../data/models/shift_type.dart';
import '../ui/dashboard_hero.dart';


/// One window of constant widget content.
///
/// [countdownTo] and [countdownPrefix] are both set (Tier A) or both null (the
/// Tier B rotation fallback and the Tier C empty state, which show
/// [staticMain] verbatim).
class WidgetHeroSegment {
  const WidgetHeroSegment({
    required this.from,
    required this.to,
    required this.badge,
    required this.subtitle,
    required this.shiftType,
    required this.staticMain,
    this.countdownTo,
    this.countdownPrefix,
  });

  /// Start of the window, inclusive.
  final DateTime from;

  /// End of the window, exclusive. The native side re-renders at this instant.
  final DateTime to;

  final String badge;
  final String subtitle;
  final ShiftType shiftType;

  /// The main line for segments with no countdown. For countdown segments this
  /// still carries the value rendered at [from] — a harmless fallback if the
  /// native side ever fails to parse [countdownTo].
  final String staticMain;

  /// Instant the countdown targets, or null when the segment is static.
  final DateTime? countdownTo;

  /// "Starts in" / "Ends in", or null when the segment is static.
  final String? countdownPrefix;

  /// True when the two segments would paint identically, so they can be merged.
  ///
  /// Deliberately ignores [from]/[to] — that is what merging adjusts — and
  /// ignores [staticMain] on countdown segments, where it is only a fallback
  /// and legitimately differs between windows that render the same way.
  bool rendersSameAs(WidgetHeroSegment other) =>
      badge == other.badge &&
      subtitle == other.subtitle &&
      shiftType == other.shiftType &&
      countdownTo == other.countdownTo &&
      countdownPrefix == other.countdownPrefix &&
      (countdownTo != null || staticMain == other.staticMain);

  Map<String, dynamic> toJson() => {
        'from': from.millisecondsSinceEpoch,
        'to': to.millisecondsSinceEpoch,
        'badge': badge,
        'sub': subtitle,
        'type': shiftType.name,
        'main': staticMain,
        if (countdownTo != null) 'cdTo': countdownTo!.millisecondsSinceEpoch,
        if (countdownPrefix != null) 'cdPre': countdownPrefix,
      };
}

/// How far ahead to project. Generous on purpose: the widget must stay honest
/// for a user who does not open the app for weeks (the whole point of a
/// glanceable surface), and the cost is a few tens of KB of SharedPreferences.
const int kWidgetForecastDays = 60;

/// Upper bound on segments written, so a pathological roster (many short
/// same-day shifts) cannot bloat the payload without limit. Reaching this cap
/// simply shortens the effective horizon; the app rewrites the forecast on
/// every resume and every roster mutation anyway.
const int kWidgetForecastMaxSegments = 250;

/// Samples [buildDashboardHero] across the boundary set and returns the merged
/// piecewise timeline covering `[now, now + horizonDays)`.
List<WidgetHeroSegment> buildWidgetForecast({
  required List<Shift> shifts,
  required List<ShiftCycle> cycles,
  required DateTime now,
  required bool use24Hour,
  int horizonDays = kWidgetForecastDays,
  int maxSegments = kWidgetForecastMaxSegments,
}) {
  final horizonEnd = DateTime(now.year, now.month, now.day + horizonDays);
  if (!horizonEnd.isAfter(now)) return const [];

  final boundaries = _boundaryInstants(
    shifts: shifts,
    now: now,
    horizonEnd: horizonEnd,
  );

  final segments = <WidgetHeroSegment>[];
  for (var i = 0; i < boundaries.length; i++) {
    final from = boundaries[i];
    final to = i + 1 < boundaries.length ? boundaries[i + 1] : horizonEnd;
    if (!to.isAfter(from)) continue;

    final hero = buildDashboardHero(
      shifts: shifts,
      cycles: cycles,
      now: from,
      use24Hour: use24Hour,
    );
    final segment = WidgetHeroSegment(
      from: from,
      to: to,
      badge: hero.badge,
      subtitle: hero.subtitle,
      shiftType: hero.shiftType,
      staticMain: hero.mainText,
      countdownTo: hero.countdownTo,
      countdownPrefix: hero.countdownPrefix,
    );

    // Merge into the previous window when nothing visible changed — a midnight
    // that falls inside a long rest stretch, for instance, is a boundary that
    // moves no pixels.
    final last = segments.isEmpty ? null : segments.last;
    if (last != null && last.rendersSameAs(segment)) {
      segments[segments.length - 1] = WidgetHeroSegment(
        from: last.from,
        to: to,
        badge: last.badge,
        subtitle: last.subtitle,
        shiftType: last.shiftType,
        staticMain: last.staticMain,
        countdownTo: last.countdownTo,
        countdownPrefix: last.countdownPrefix,
      );
      continue;
    }

    segments.add(segment);
    if (segments.length >= maxSegments) break;
  }

  return segments;
}

/// Serialises a forecast for the `hero_forecast` SharedPreferences key that
/// `RostrikWidgetProvider` reads.
String encodeWidgetForecast(List<WidgetHeroSegment> segments) =>
    jsonEncode(segments.map((s) => s.toJson()).toList());

/// The sorted, de-duplicated instants at which the hero's output can change:
/// `now`, every in-window shift start and end, and every local midnight.
///
/// Midnights are built by calendar arithmetic (`DateTime(y, m, d + n)`) rather
/// than by adding 24-hour Durations, so a DST transition lands on the real
/// local midnight instead of drifting an hour off it.
List<DateTime> _boundaryInstants({
  required List<Shift> shifts,
  required DateTime now,
  required DateTime horizonEnd,
}) {
  final seen = <int>{};
  final out = <DateTime>[];

  void add(DateTime t) {
    if (t.isBefore(now) || !t.isBefore(horizonEnd)) return;
    if (seen.add(t.millisecondsSinceEpoch)) out.add(t);
  }

  add(now);
  for (final s in shifts) {
    if (s.type == ShiftType.off) continue;
    add(s.startDateTime);
    add(s.endDateTime);
  }
  for (var day = DateTime(now.year, now.month, now.day + 1);
      day.isBefore(horizonEnd);
      day = DateTime(day.year, day.month, day.day + 1)) {
    add(day);
  }

  out.sort();
  return out;
}
