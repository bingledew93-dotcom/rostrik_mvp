import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/shift.dart';
import '../data/models/shift_cycle.dart';
import '../data/models/shift_type.dart';
import '../logic/cycle_resolver.dart';
import 'roster/shift_visuals.dart';
import 'settings_screen.dart';
import 'shift_format.dart';

/// Primary dashboard — "what's my next shift?" — on tab 0 of the
/// `MainLayout` chassis.
///
/// Source of truth: `context.watch<List<Shift>>()` from `AppProviders`,
/// which is a 1-year-window snapshot of the shift box. We pick the next
/// upcoming non-OFF shift whose end has not passed yet (a shift in
/// progress still counts as "current"). A 1-minute periodic timer
/// triggers a rebuild so the countdown stays fresh; cancelled in
/// `dispose()` so the timer never outlives the widget.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 1-minute cadence is enough for the "Starts in 14h 22m" label —
    // the minute digit only flips every 60s, and going finer would burn
    // battery and re-render the whole screen for no visual change.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final shifts = context.watch<List<Shift>>();
    final cycles = context.watch<List<ShiftCycle>>();
    final next = _findNext(shifts, now);
    final activeCycle = _pickActiveCycle(cycles);

    return Scaffold(
      // Respect both top (notch / status bar) AND bottom (gesture pill)
      // insets directly here — the screen has no AppBar, so without
      // this the headline would tuck under the status bar on edge-to-
      // edge displays. MainLayout's NavigationBar handles its own
      // bottom inset, so SafeArea(bottom: true) only adds whatever
      // gesture-pill margin remains.
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: next == null
                        ? const _EmptyDashboard()
                        : _UpcomingShiftCard(shift: next, now: now),
                  ),
                  if (activeCycle != null)
                    _RotationPositionCard(cycle: activeCycle, now: now),
                ],
              ),
            ),
            // Settings overlay — Dashboard has no AppBar, so the gear
            // sits as a top-right floater. Tiny + tonal so it doesn't
            // compete with the hero countdown for attention.
            Positioned(
              top: 4,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Selects the active anchored cycle. Mirrors the picker in
  /// [CalendarScreen] so the Dashboard's rotation copy and the
  /// Calendar grid always read off the same cycle.
  static ShiftCycle? _pickActiveCycle(List<ShiftCycle> cycles) {
    final anchored = cycles.where((c) => c.isAnchored).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return anchored.isEmpty ? null : anchored.first;
  }

  /// The first shift in [shifts] (sorted by start instant) that is
  /// non-OFF AND whose end has not passed [now]. A shift in progress
  /// (now between its start and end) qualifies — "the user's current
  /// shift" is the most useful thing to show.
  static Shift? _findNext(List<Shift> shifts, DateTime now) {
    Shift? best;
    DateTime? bestStart;
    for (final s in shifts) {
      if (s.type == ShiftType.off) continue;
      if (s.isMuted) continue;
      if (s.isAcknowledged) continue;
      if (!s.endDateTime.isAfter(now)) continue;
      final start = s.startDateTime;
      if (bestStart == null || start.isBefore(bestStart)) {
        best = s;
        bestStart = start;
      }
    }
    return best;
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.beach_access_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming shifts',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enjoy your time off.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero card for the next-shift display. Three lines, in size order:
///
///   1. Shift name (medium, coloured by `visualFor(type)`).
///   2. "Starts in 14h 22m" / "In progress · ends in Xh Ym" (huge).
///   3. "Tomorrow at 06:00" / "Today at 06:00" / "Fri, May 22 at 06:00"
///      (medium, secondary colour).
class _UpcomingShiftCard extends StatelessWidget {
  const _UpcomingShiftCard({required this.shift, required this.now});

  final Shift shift;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = visualFor(shift.type);
    final start = shift.startDateTime;
    final inProgress = !start.isAfter(now);
    final countdownTarget = inProgress ? shift.endDateTime : start;
    final countdown = _formatCountdown(countdownTarget.difference(now));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Type label + small leading icon. Coloured.
        Row(
          children: [
            Icon(visual.icon, color: visual.color, size: 32),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                '${_typeLabel(shift.type)} shift',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: visual.color,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // The hero countdown line. Tight letter-spacing + tabular
        // figures so the digits don't jitter as the minute flips.
        Text(
          inProgress ? 'Ends in $countdown' : 'Starts in $countdown',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.05,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _formatAbsoluteWhen(start, now, inProgress),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (inProgress) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'IN PROGRESS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: visual.color,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// "14h 22m" / "23m" / "3d 14h". Always rounds DOWN — better to be a
  /// minute too pessimistic than late.
  static String _formatCountdown(Duration d) {
    if (d.isNegative) return '0m';
    final totalMinutes = d.inMinutes;
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    }
    if (totalMinutes < 60 * 24) {
      final h = totalMinutes ~/ 60;
      final m = totalMinutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    final days = totalMinutes ~/ (60 * 24);
    final hoursRem = (totalMinutes - days * 60 * 24) ~/ 60;
    return hoursRem == 0 ? '${days}d' : '${days}d ${hoursRem}h';
  }

  /// "Today at 06:00" / "Tomorrow at 06:00" / "Fri, May 22 at 06:00".
  /// `inProgress` swaps the verb so the subtitle still makes sense
  /// while a shift is running ("Started today at 06:00").
  ///
  /// Uses calendar-field comparison rather than `.difference(...).inDays`.
  /// `Duration.inDays` truncates on a 23h or 25h gap across DST: on a
  /// spring-forward day, `tomorrow.difference(today).inDays` is 0, which
  /// would mislabel "Tomorrow at 06:00" as "Today at 06:00".
  static String _formatAbsoluteWhen(
    DateTime start,
    DateTime now,
    bool inProgress,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final time = formatHhmm(start.hour * 60 + start.minute);
    final verb = inProgress ? 'Started' : 'Starts';
    if (_isSameDay(startDay, today)) return '$verb today at $time';
    if (_isSameDay(startDay, tomorrow)) return 'Starts tomorrow at $time';
    if (_isSameDay(startDay, yesterday)) return '$verb yesterday at $time';
    // Beyond ±1 day fall back to a compact absolute date. `formatShiftDate`
    // already gives us "Mon, May 4"-style copy, which reads naturally.
    return '$verb ${formatShiftDate(start)} at $time';
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Local label helper. `shiftTypeLabel` lives in `shift_format.dart`
  /// but we want a slightly different capitalization on the hero line.
  /// Reusing it would force "Day shift" → "Day shift" but other types
  /// would inherit "Off" awkwardly; this gives us explicit control.
  static String _typeLabel(ShiftType type) {
    switch (type) {
      case ShiftType.day:
        return 'Day';
      case ShiftType.afternoon:
        return 'Afternoon';
      case ShiftType.night:
        return 'Night';
      case ShiftType.off:
        // Unreachable: `_findNext` filters OFF shifts before they reach
        // this card. Benign fallback.
        return 'Off';
    }
  }
}

/// Secondary card pinned to the bottom of the Dashboard. Resolver-
/// driven so it works for any future day — the active cycle's anchor +
/// blocks are enough input, no materialised shifts required.
///
/// Reads today's resolution from `resolveShiftBlockForDate` and walks
/// forward through the cycle to compute "Next OFF in N days" copy.
class _RotationPositionCard extends StatelessWidget {
  const _RotationPositionCard({required this.cycle, required this.now});

  final ShiftCycle cycle;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime(now.year, now.month, now.day);
    final today_ = resolveShiftBlockForDate(
      target: today,
      anchor: cycle.anchorDate!,
      blocks: cycle.blocks!,
    );
    // Defensive: isAnchored is enforced upstream, so `today_` should
    // never be null here. Surface a tiny neutral state if it ever is
    // rather than crash the Dashboard.
    if (today_ == null) return const SizedBox.shrink();

    final visual = visualFor(today_.block.type);
    final dayLabel = _typeLabelShort(today_.block.type);
    final positionCopy = 'Day ${today_.dayWithinBlock + 1} of '
        '${today_.block.consecutiveDays} — $dayLabel';
    final nextOff = _daysUntilNextOff(cycle, today);

    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: visual.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rotation',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              positionCopy,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (nextOff != null) ...[
              const SizedBox(height: 2),
              Text(
                nextOff,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Walks the cycle forward from [today] (exclusive) until the first
  /// OFF day, capped at one full cycle length. Returns null if the
  /// user is currently on OFF (in which case "Days until OFF" would be
  /// confusing) or if no OFF block exists in the cycle (all-work
  /// rotation — surfaceable later, but degenerate for now).
  static String? _daysUntilNextOff(ShiftCycle cycle, DateTime today) {
    final todayResolution = resolveShiftBlockForDate(
      target: today,
      anchor: cycle.anchorDate!,
      blocks: cycle.blocks!,
    );
    if (todayResolution == null) return null;
    if (todayResolution.block.type == ShiftType.off) {
      // Currently OFF — surface the opposite ("ends in N days").
      return _daysUntilNextWork(cycle, today);
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
            ? 'Off tomorrow'
            : 'Off in $offset days';
      }
    }
    return null;
  }

  /// Symmetric helper for the "currently OFF" case — counts forward to
  /// the next work day so the card never says "Off in N days" while
  /// the user is already on a rest block.
  static String? _daysUntilNextWork(ShiftCycle cycle, DateTime today) {
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
            ? 'Back on tomorrow'
            : 'Back on in $offset days';
      }
    }
    return null;
  }

  static String _typeLabelShort(ShiftType type) {
    switch (type) {
      case ShiftType.day:
        return 'Day shift';
      case ShiftType.afternoon:
        return 'Afternoon shift';
      case ShiftType.night:
        return 'Night shift';
      case ShiftType.off:
        return 'Off';
    }
  }
}
