import '../data/models/shift.dart';
import '../l10n/l10n.dart';
import '../data/models/shift_cycle.dart';
import '../data/models/shift_type.dart';
import '../logic/cycle_resolver.dart';
import 'shift_format.dart';

/// Shared "next shift" selection + Hero Card string formatting.
///
/// This is the single source of truth for the Dashboard Hero Card's copy AND
/// the Android home-screen widget (`WidgetService`), so the glanceable widget
/// can never drift from what the in-app hero shows. Extracted verbatim from
/// `dashboard_screen.dart`; the widget builder ([buildDashboardHero]) is layered
/// on top of the same helpers.
///
/// Presentation logic (it formats display strings via `shift_format`), hence it
/// lives under `lib/ui/` rather than `lib/logic/`.

/// The shift to feature on the hero card. Selected in two tiers so the card
/// always answers "where am I right now?" before "what's next?":
///
///   1. **In-progress** — a non-OFF shift whose window straddles [now]
///      (`start <= now < end`). Shown even when muted / acknowledged / snoozed
///      (those are alarm-*scheduling* concerns, not *display* concerns).
///   2. **Upcoming** — otherwise the soonest non-OFF shift whose start is still
///      in the future; here the mute/ack filter DOES apply (engine parity).
///
/// A **paused** shift (`isPaused` — sick / leave / holiday) is skipped in BOTH
/// tiers: the user isn't working that day at all.
Shift? findNextShift(List<Shift> shifts, DateTime now) {
  // Tier 1: a shift currently under way wins outright, suppression flags
  // notwithstanding. Earliest-starting one if (rarely) several overlap.
  Shift? inProgress;
  for (final s in shifts) {
    if (s.type == ShiftType.off) continue;
    if (s.isPaused) continue;
    final start = s.startDateTime;
    if (start.isAfter(now)) continue; // hasn't started — Tier 2's job
    if (!s.endDateTime.isAfter(now)) continue; // already ended
    if (inProgress == null || start.isBefore(inProgress.startDateTime)) {
      inProgress = s;
    }
  }
  if (inProgress != null) return inProgress;

  // Tier 2: soonest upcoming shift, respecting alarm suppression.
  Shift? best;
  DateTime? bestStart;
  for (final s in shifts) {
    if (s.type == ShiftType.off) continue;
    if (s.isPaused) continue;
    if (s.isMuted) continue;
    if (s.isAcknowledged) continue;
    final start = s.startDateTime;
    if (!start.isAfter(now)) continue; // started/ended — handled in Tier 1
    if (bestStart == null || start.isBefore(bestStart)) {
      best = s;
      bestStart = start;
    }
  }
  return best;
}

/// Selects the active anchored cycle (most recently created). Mirrors the
/// Timeline's Month-view picker so every surface reads the same cycle.
ShiftCycle? pickActiveCycle(List<ShiftCycle> cycles) {
  final anchored = cycles.where((c) => c.isAnchored).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return anchored.isEmpty ? null : anchored.first;
}

/// "14h 22m" / "23m" / "3d 14h". Always rounds DOWN — better a minute
/// pessimistic than late.
String formatHeroCountdown(Duration d) {
  final l10n = currentL10n;
  if (d.isNegative) return l10n.durationMinShort(0);
  final totalMinutes = d.inMinutes;
  if (totalMinutes < 60) {
    return l10n.durationMinShort(totalMinutes);
  }
  if (totalMinutes < 60 * 24) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m == 0 ? l10n.durationHShort(h) : l10n.durationHMinShort(h, m);
  }
  final days = totalMinutes ~/ (60 * 24);
  final hoursRem = (totalMinutes - days * 60 * 24) ~/ 60;
  return hoursRem == 0
      ? l10n.durationDayShort(days)
      : l10n.durationDayHourShort(days, hoursRem);
}

/// "Today at 06:00" / "Tomorrow at 06:00" / "Fri, May 22 at 06:00".
/// [inProgress] swaps the verb so the subtitle still reads while running.
/// Calendar-field comparison (not `Duration.inDays`) for DST safety.
String formatHeroAbsoluteWhen(
  DateTime start,
  DateTime now,
  bool inProgress,
  bool use24Hour,
) {
  final today = DateTime(now.year, now.month, now.day);
  final startDay = DateTime(start.year, start.month, start.day);
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  final time = formatClock(
    start.hour * 60 + start.minute,
    use24Hour: use24Hour,
  );
  final l10n = currentL10n;
  if (_isSameDay(startDay, today)) {
    return inProgress
        ? l10n.heroStartedTodayAt(time)
        : l10n.heroStartsTodayAt(time);
  }
  if (_isSameDay(startDay, tomorrow)) return l10n.heroStartsTomorrowAt(time);
  if (_isSameDay(startDay, yesterday)) {
    return inProgress
        ? l10n.heroStartedYesterdayAt(time)
        : l10n.heroStartsYesterdayAt(time);
  }
  return inProgress
      ? l10n.heroStartedOnAt(formatShiftDate(start), time)
      : l10n.heroStartsOnAt(formatShiftDate(start), time);
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Hero type label — "Day" / "Afternoon" / "Night" (rendered as "$label shift").
/// OFF is unreachable on the hero (filtered by [findNextShift]); benign
/// fallback.
String heroTypeLabel(ShiftType type) => shiftTypeLabel(type);

/// Rotation-card short label ("Day shift" / "Afternoon shift" / "Night shift" /
/// "Off"), used in the "Day X of Y — …" position copy.
String heroTypeLabelShort(ShiftType type) {
  final l10n = currentL10n;
  switch (type) {
    case ShiftType.day:
      return l10n.shiftTypeDayShift;
    case ShiftType.afternoon:
      return l10n.shiftTypeAfternoonShift;
    case ShiftType.night:
      return l10n.shiftTypeNightShift;
    case ShiftType.off:
      return l10n.shiftTypeOff;
  }
}

/// "Day 2 of 7 — Off" — the rotation position copy shared by the Dashboard's
/// Rotation card and the widget's off-day fallback.
String rotationPositionCopy(
  int dayWithinBlock,
  int consecutiveDays,
  ShiftType type,
) =>
    currentL10n.heroDayXofY(
      dayWithinBlock + 1,
      consecutiveDays,
      heroTypeLabelShort(type),
    );

/// Walks the cycle forward from [today] to the next OFF day. Returns "Off
/// tomorrow" / "Off in N days", or null (currently OFF, or no OFF in the cycle).
String? daysUntilNextOffCopy(ShiftCycle cycle, DateTime today) {
  final todayResolution = resolveShiftBlockForDate(
    target: today,
    anchor: cycle.anchorDate!,
    blocks: cycle.blocks!,
  );
  if (todayResolution == null) return null;
  if (todayResolution.block.type == ShiftType.off) {
    return daysUntilNextWorkCopy(cycle, today);
  }
  final cycleLen = cycle.cycleLengthDays ?? 0;
  if (cycleLen <= 0) return null;
  for (var offset = 1; offset <= cycleLen; offset++) {
    final target = DateTime(today.year, today.month, today.day + offset);
    final r = resolveShiftBlockForDate(
      target: target,
      anchor: cycle.anchorDate!,
      blocks: cycle.blocks!,
    );
    if (r != null && r.block.type == ShiftType.off) {
      return offset == 1
          ? currentL10n.heroOffTomorrow
          : currentL10n.heroOffInDays(offset);
    }
  }
  return null;
}

/// Symmetric to [daysUntilNextOffCopy] for the currently-OFF case: counts
/// forward to the next work day ("Back on tomorrow" / "Back on in N days").
String? daysUntilNextWorkCopy(ShiftCycle cycle, DateTime today) {
  final cycleLen = cycle.cycleLengthDays ?? 0;
  if (cycleLen <= 0) return null;
  for (var offset = 1; offset <= cycleLen; offset++) {
    final target = DateTime(today.year, today.month, today.day + offset);
    final r = resolveShiftBlockForDate(
      target: target,
      anchor: cycle.anchorDate!,
      blocks: cycle.blocks!,
    );
    if (r != null && r.block.type != ShiftType.off) {
      return offset == 1
          ? currentL10n.heroBackOnTomorrow
          : currentL10n.heroBackOnInDays(offset);
    }
  }
  return null;
}

/// Emoji-prefixed badge for the home-screen widget's title line, e.g.
/// "☀️ Day shift". OFF renders "🛌 Off / RDO".
String heroBadge(ShiftType type) {
  switch (type) {
    case ShiftType.day:
      return '☀️ ${heroTypeLabelShort(type)}';
    case ShiftType.afternoon:
      return '🌇 ${heroTypeLabelShort(type)}';
    case ShiftType.night:
      return '🌙 ${heroTypeLabelShort(type)}';
    case ShiftType.off:
      return '🛌 ${currentL10n.heroOffRdo}';
  }
}

/// The four glanceable strings the home-screen widget renders, computed from the
/// same state and formatting as the in-app Hero Card.
class DashboardHero {
  const DashboardHero({
    required this.badge,
    required this.mainText,
    required this.subtitle,
    required this.shiftType,
    this.countdownTo,
    this.countdownPrefix,
  });

  /// Title line — emoji + type (`hero_badge`).
  final String badge;

  /// Big line — countdown or rotation position (`hero_main_text`).
  final String mainText;

  /// Secondary line — absolute timestamp or "Back on …" (`hero_subtitle`).
  final String subtitle;

  /// Drives the native accent tint (`shift_type`); serialise as [ShiftType.name]
  /// → "day" / "afternoon" / "night" / "off".
  final ShiftType shiftType;

  /// The instant the [mainText] countdown is counting TOWARDS — a shift start
  /// (Tier A upcoming) or a shift end (Tier A in-progress). Null on the Tier B
  /// rotation fallback and the Tier C empty state, which have no countdown.
  ///
  /// This exists so the home-screen widget can re-derive the countdown for
  /// ITSELF at draw time. [mainText] is rendered against the `now` passed to
  /// [buildDashboardHero] and is therefore stale the moment it is written; the
  /// widget process outlives the app, so it needs the target instant, not a
  /// snapshot of the remaining duration. In-app callers keep using [mainText].
  final DateTime? countdownTo;

  /// The verb the widget prefixes to its self-computed countdown — "Starts in"
  /// or "Ends in". Paired with [countdownTo]; both null or both set.
  final String? countdownPrefix;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardHero &&
          runtimeType == other.runtimeType &&
          badge == other.badge &&
          mainText == other.mainText &&
          subtitle == other.subtitle &&
          shiftType == other.shiftType &&
          countdownTo == other.countdownTo &&
          countdownPrefix == other.countdownPrefix;

  @override
  int get hashCode => Object.hash(
        badge,
        mainText,
        subtitle,
        shiftType,
        countdownTo,
        countdownPrefix,
      );

  @override
  String toString() =>
      'DashboardHero($badge | $mainText | $subtitle | ${shiftType.name})';
}

/// Builds the widget payload, mirroring the Dashboard in three tiers:
///   * **A next/in-progress work shift** → the Hero countdown card
///     ("Starts in 6d 1h" + "Starts Wed, Jul 1 at 06:00").
///   * **No next shift but an active cycle** → the Rotation-position fallback
///     ("Day 2 of 7 — Off" + "Back on in 6 days").
///   * **Nothing** → the rest-day empty state.
DashboardHero buildDashboardHero({
  required List<Shift> shifts,
  required List<ShiftCycle> cycles,
  required DateTime now,
  required bool use24Hour,
}) {
  // Tier A — the dominant case: count down to the next (or in-progress) shift.
  final next = findNextShift(shifts, now);
  if (next != null) {
    final start = next.startDateTime;
    final inProgress = !start.isAfter(now);
    final target = inProgress ? next.endDateTime : start;
    final countdown = formatHeroCountdown(target.difference(now));
    return DashboardHero(
      badge: heroBadge(next.type),
      mainText: inProgress
          ? currentL10n.heroEndsIn(countdown)
          : currentL10n.heroStartsIn(countdown),
      subtitle: formatHeroAbsoluteWhen(start, now, inProgress, use24Hour),
      shiftType: next.type,
      countdownTo: target,
      countdownPrefix: inProgress
          ? currentL10n.heroEndsInPrefix
          : currentL10n.heroStartsInPrefix,
    );
  }

  // Tier B — no materialised next shift, but an anchored rotation still
  // projects today's position (typically a rest stretch at the tail of a
  // roster). Resolver-driven, so it needs no materialised shifts.
  final cycle = pickActiveCycle(cycles);
  if (cycle != null && cycle.isAnchored) {
    final today = DateTime(now.year, now.month, now.day);
    final res = resolveShiftBlockForDate(
      target: today,
      anchor: cycle.anchorDate!,
      blocks: cycle.blocks!,
    );
    if (res != null) {
      final type = res.block.type;
      final subtitle = type == ShiftType.off
          ? (daysUntilNextWorkCopy(cycle, today) ?? currentL10n.dashEnjoyTimeOff)
          : (daysUntilNextOffCopy(cycle, today) ?? currentL10n.dashEnjoyTimeOff);
      return DashboardHero(
        badge: heroBadge(type),
        mainText: rotationPositionCopy(
          res.dayWithinBlock,
          res.block.consecutiveDays,
          type,
        ),
        subtitle: subtitle,
        shiftType: type,
      );
    }
  }

  // Tier C — nothing scheduled at all.
  return DashboardHero(
    badge: '🛌 ${currentL10n.heroOffRdo}',
    mainText: currentL10n.dashNoUpcomingShifts,
    subtitle: currentL10n.dashEnjoyTimeOff,
    shiftType: ShiftType.off,
  );
}
