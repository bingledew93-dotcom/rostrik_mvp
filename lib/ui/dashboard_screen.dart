import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../alarms/alarm_projection.dart';
import '../data/models/alarm_settings.dart';
import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../data/models/shift_cycle.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/app_alarm_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../logic/cycle_resolver.dart';
import '../state/app_preferences.dart';
import 'calendar/shift_calendar.dart';
import 'roster/shift_visuals.dart';
import 'settings_screen.dart';
import 'shift_format.dart';
import 'slide_to_confirm.dart';

/// Primary dashboard — "what's my next shift?" — on tab 0 of the
/// `MainLayout` chassis.
///
/// Source of truth: `context.watch<List<Shift>>()` from `AppProviders`,
/// which is a 1-year-window snapshot of the shift box. We feature the
/// shift the user is currently on (start <= now < end) if one exists, and
/// otherwise the soonest upcoming non-OFF shift — see `_findNext` for the
/// two-tier rule. A 1-minute periodic timer triggers a rebuild so the
/// countdown stays fresh; cancelled in `dispose()` so the timer never
/// outlives the widget.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onOpenTab});

  /// Switches the MainLayout bottom-nav tab. Supplied in production so the
  /// "My Rotation" tile's "View full roster" affordance jumps to the Roster
  /// tab. Null when the screen is pumped standalone (widget tests) — the
  /// affordance is hidden in that case.
  final void Function(int index)? onOpenTab;

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
    final alarms = context.watch<List<AppAlarm>>();
    final globalLeadMinutes = context.watch<AlarmSettings>().leadTime.inMinutes;
    final next = _findNext(shifts, now);
    final activeCycle = _pickActiveCycle(cycles);
    // Early-bird skip: the single next alarm of ANY type due within 12h —
    // rotation rings AND shift-less one-time/weekly rings (which
    // `nextRotationRing` used to filter out, hiding the control for them).
    // When present, the dashboard offers a PER-OCCURRENCE skip: a rotation
    // ring's alarm id is appended to the shift's `dismissedAlarmIds`; a
    // shift-less ring advances its rule's `skippedThrough` watermark (weekly)
    // or disables the rule (one-time). See `_DismissUpcomingAlarmControl`.
    final upcoming = nextAlarmRing(
      alarms: alarms,
      shifts: shifts,
      globalLeadMinutes: globalLeadMinutes,
      now: now,
      // The early-skip is a "you woke before your alarm" affordance — keep the
      // original 12h look-ahead. Same projector the engine + Alarms tab use,
      // so it now inherently ignores paused / archived / muted shifts AND
      // already-dismissed/skipped rings — which is what makes sequential
      // skipping work: each skip write re-lands here targeting the next ring.
      horizon: const Duration(hours: 12),
      isSchedulePaused: AppPreferences.isSchedulePausedOf(context),
    );
    // The skip group, earliest first — `first` IS `upcoming`. For a rotation
    // ring: every remaining ring for its shift (the tail is what "Skip all"
    // covers), projected over the wide display horizon (not the 12h gate) so
    // a sibling ring just outside the window still counts, and filtered to
    // shift-linked rings. For a shift-less ring: a lone-ring group — there is
    // no shift to group by, so skip-one IS skip-all and no escape hatch shows.
    final upcomingRings = upcoming == null
        ? const <AlarmRing>[]
        : upcoming.shift == null
            ? <AlarmRing>[upcoming]
            : projectAlarmRings(
                alarms: alarms,
                shifts: [upcoming.shift!],
                globalLeadMinutes: globalLeadMinutes,
                now: now,
                horizon: kRingDisplayHorizon,
                isSchedulePaused: AppPreferences.isSchedulePausedOf(context),
              ).where((r) => r.shift != null).toList();

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
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero gets a fixed slice of the viewport so its internal
                  // vertical centering still reads as a hero AND the page can
                  // scroll once "My Rotation" expands (a centre-aligned Column
                  // can't live in an unbounded scroll extent).
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.42,
                    child: next == null
                        ? const _EmptyDashboard()
                        : _UpcomingShiftCard(shift: next, now: now),
                  ),
                  if (upcomingRings.isNotEmpty)
                    _DismissUpcomingAlarmControl(
                      // Keyed by the TARGET ring: once a skip lands, the
                      // shift/alarm-stream rebuild re-computes the ring list
                      // and `first` becomes the next chronological ring — the
                      // new key discards the old confirm state + spent slide
                      // handle, so the control is immediately ready for the
                      // next sequential skip. The fireAt component is what
                      // re-keys a WEEKLY retarget (same rule id, same missing
                      // shift — only the occurrence instant moves).
                      key: ValueKey(
                        'early-skip-${upcomingRings.first.shift?.id ?? 'rule'}'
                        '-${upcomingRings.first.alarm.id}'
                        '-${upcomingRings.first.fireAt.millisecondsSinceEpoch}',
                      ),
                      rings: upcomingRings,
                    ),
                  if (activeCycle != null)
                    _RotationPositionCard(cycle: activeCycle, now: now),
                  // Collapsed-by-default "My Rotation" — embeds the month
                  // calendar + a next-shifts preview, keeping the home screen
                  // clean until tapped. Only meaningful with an active cycle.
                  if (activeCycle != null) ...[
                    const SizedBox(height: 16),
                    _MyRotationTile(
                      shifts: shifts,
                      now: now,
                      onOpenTab: widget.onOpenTab,
                    ),
                  ],
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

  /// Selects the active anchored cycle. Mirrors the picker in the
  /// Timeline's Month view so the Dashboard's rotation copy and the
  /// calendar grid always read off the same cycle.
  static ShiftCycle? _pickActiveCycle(List<ShiftCycle> cycles) {
    final anchored = cycles.where((c) => c.isAnchored).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return anchored.isEmpty ? null : anchored.first;
  }

  /// The shift to feature on the hero card. Selected in two tiers so the
  /// card always answers "where am I right now?" before "what's next?":
  ///
  ///   1. **In-progress** — a non-OFF shift whose window straddles [now]
  ///      (`start <= now < end`). The user is physically on this shift, so it
  ///      is shown even when its alarm was muted / acknowledged / snoozed:
  ///      those are alarm-*scheduling* concerns, not *display* concerns.
  ///      (Field bug, roster Day 7: dismissing the morning alarm sets
  ///      `isAcknowledged`, which used to drop today's active shift here and
  ///      jump the countdown to the next rotation block days away.)
  ///   2. **Upcoming** — otherwise the soonest non-OFF shift whose start is
  ///      still in the future. Here the mute/ack filter DOES apply (engine
  ///      parity: a suppressed future shift isn't advertised as "next up").
  ///      Once today's shift ends it stops being in-progress, so the card
  ///      rolls forward to tomorrow — or the next working day when tomorrow
  ///      is OFF, which naturally yields the multi-day countdown.
  ///
  /// A **paused** shift (`isPaused` — sick / leave / holiday) is skipped in
  /// BOTH tiers: unlike mute/ack it means the user isn't working that day at
  /// all, so it's never featured as in-progress nor advertised as next-up.
  static Shift? _findNext(List<Shift> shifts, DateTime now) {
    // Tier 1: a shift currently under way wins outright, suppression flags
    // notwithstanding. Earliest-starting one if (rarely) several overlap.
    Shift? inProgress;
    for (final s in shifts) {
      if (s.type == ShiftType.off) continue;
      // Paused (sick/leave/holiday) = NOT working — never featured, not even
      // when `now` falls inside its window. This is the one flag that overrides
      // Tier 1 (mute/ack don't, because the user is still physically present).
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
      if (s.isPaused) continue; // paused = not working → never "next up"
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
    final use24Hour = AppPreferences.use24HourOf(context);

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
          _formatAbsoluteWhen(start, now, inProgress, use24Hour),
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

/// Which pending action the early-skip control is asking the user to confirm.
enum _EarlySkipMode { collapsed, confirmOne, confirmAll }

/// Early-bird skip affordance: a prominent action shown when a roster-automated
/// alarm is due within the next 12 hours. Tapping reveals an inline
/// slide-to-confirm bar (Rostrik's visible-control → swipe-to-confirm standard,
/// so a stray 4am tap can't silence a must-not-miss alarm).
///
/// PER-OCCURRENCE, not per-shift, and covering EVERY alarm type. Confirming
/// resolves the NEXT chronological ring by what carries its state:
///   * **Rotation ring** (has a shift) → append the alarm id to the shift's
///     [Shift.dismissedAlarmIds]; the shift's later alarms stay armed.
///   * **Weekly ring** (no shift) → advance the rule's
///     [AppAlarm.skippedThrough] watermark to this ring's instant; next
///     week's occurrence fires later, so it stays armed.
///   * **One-time ring** (no shift) → disable the rule (`enabled: false`) —
///     its only upcoming ring skipped IS the rule disarmed, and a watermark
///     would resurrect it tomorrow via the daily next-occurrence roll.
/// Every write flows back through a watched stream (shifts or alarms), the
/// projector drops the skipped ring, and this control re-keys onto the
/// following ring — sequential skips are one slide each. (The old
/// whole-shift `isAlarmSkipped` blanket write is retired here; the flag is
/// still honoured by the projector for shifts already carrying it.)
///
/// When more than one ring remains (rotation groups only — shift-less rings
/// are lone-ring groups), a secondary "Skip all" button covers the
/// intentional day-off case — it appends EVERY remaining ring's alarm id.
/// It is a visible button behind the same slide-to-confirm gate (never a
/// long-press: hidden gestures fail groggy users; and skip-all is the most
/// dangerous action on this screen).
class _DismissUpcomingAlarmControl extends StatefulWidget {
  const _DismissUpcomingAlarmControl({super.key, required this.rings});

  /// The skip group, earliest first — never empty. For a rotation target:
  /// the upcoming shift's remaining rings, all carrying the SAME non-null
  /// [AlarmRing.shift]. For a one-time/weekly target: exactly one shift-less
  /// ring. `rings.first` is the skip-one target; the whole list is skip-all's.
  final List<AlarmRing> rings;

  @override
  State<_DismissUpcomingAlarmControl> createState() =>
      _DismissUpcomingAlarmControlState();
}

class _DismissUpcomingAlarmControlState
    extends State<_DismissUpcomingAlarmControl> {
  _EarlySkipMode _mode = _EarlySkipMode.collapsed;

  AlarmRing get _next => widget.rings.first;

  /// Skips [targets] in one write, routed by where the occurrence's state
  /// lives (see the class doc). Skip-one passes a single ring; skip-all
  /// passes a whole rotation group.
  Future<void> _skip(List<AlarmRing> targets) async {
    // Snapshot the repos before the await — the resulting write rebuilds the
    // dashboard, which may re-key or remove this control, so reading context
    // post-await would race with disposal.
    final ring = targets.first;
    final shift = ring.shift;
    if (shift != null) {
      // Rotation group: append every target's alarm id to the shift's
      // dismissed set. The set spread keeps existing entries first and
      // de-duplicates, so re-confirming a ring that raced in from another
      // surface is a harmless no-op entry-wise.
      final shifts = context.read<ShiftRepository>();
      await shifts.upsert(shift.copyWith(
        dismissedAlarmIds: <String>{
          ...shift.dismissedAlarmIds,
          for (final r in targets) r.alarm.id,
        }.toList(),
      ));
    } else if (ring.alarm.repeatType == AppAlarmRepeatType.oneTime) {
      // A one-shot's only upcoming ring skipped = the rule disarmed. The card
      // stays on the Alarms tab, toggled off, ready to re-arm — and unlike a
      // skip watermark it can't resurrect tomorrow via the daily roll.
      final alarms = context.read<AppAlarmRepository>();
      await alarms.upsert(ring.alarm.copyWith(enabled: false));
    } else {
      // Weekly: advance the skip watermark to this ring's instant. Monotonic
      // max, so skipping Monday's ring and then Tuesday's can never rewind
      // the watermark and un-skip Monday.
      final alarms = context.read<AppAlarmRepository>();
      final prev = ring.alarm.skippedThrough;
      await alarms.upsert(ring.alarm.copyWith(
        skippedThrough:
            (prev != null && prev.isAfter(ring.fireAt)) ? prev : ring.fireAt,
      ));
    }
    // The stream rebuild re-keys this control for the next ring (or removes
    // it once nothing is left). Collapse locally too, so a stale frame —
    // stream debounce, or a static provider under the test harness — never
    // leaves a spent slide handle on screen.
    if (mounted) setState(() => _mode = _EarlySkipMode.collapsed);
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case _EarlySkipMode.collapsed:
        return _buildCollapsed(context);
      case _EarlySkipMode.confirmOne:
        return _buildConfirmBar(
          key: const ValueKey('dismiss-upcoming-slide'),
          label: 'Slide to skip this alarm',
          icon: Icons.alarm_off,
          targets: [_next],
        );
      case _EarlySkipMode.confirmAll:
        return _buildConfirmBar(
          key: const ValueKey('skip-all-slide'),
          label: 'Slide to skip all ${widget.rings.length} alarms',
          icon: Icons.clear_all,
          targets: widget.rings,
        );
    }
  }

  Widget _buildCollapsed(BuildContext context) {
    final theme = Theme.of(context);
    final fireClock = formatClock(
      _next.fireAt.hour * 60 + _next.fireAt.minute,
      use24Hour: AppPreferences.use24HourOf(context),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.tonalIcon(
            key: const ValueKey('dismiss-upcoming-button'),
            onPressed: () =>
                setState(() => _mode = _EarlySkipMode.confirmOne),
            icon: const Icon(Icons.alarm_off),
            label: Text('Dismiss upcoming alarm · $fireClock'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // The intentional-day-off escape hatch — only when there is more
          // than one ring left (with a single ring, skip-one IS skip-all).
          // Quieter than the primary action: skipping every wake-up must be
          // a considered choice, not the path of least resistance.
          if (widget.rings.length > 1)
            TextButton.icon(
              key: const ValueKey('skip-all-button'),
              onPressed: () =>
                  setState(() => _mode = _EarlySkipMode.confirmAll),
              icon: const Icon(Icons.clear_all, size: 18),
              label: Text(
                'Skip all ${widget.rings.length} alarms for this shift',
              ),
            ),
        ],
      ),
    );
  }

  /// The shared confirm row: slide bar + an X to back out. [targets] is what
  /// a completed slide dismisses.
  Widget _buildConfirmBar({
    required Key key,
    required String label,
    required IconData icon,
    required List<AlarmRing> targets,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: SlideToConfirm(
              key: key,
              label: label,
              icon: icon,
              onConfirm: () => _skip(targets),
            ),
          ),
          IconButton(
            key: const ValueKey('dismiss-upcoming-cancel'),
            icon: const Icon(Icons.close),
            tooltip: 'Keep alarm',
            onPressed: () =>
                setState(() => _mode = _EarlySkipMode.collapsed),
          ),
        ],
      ),
    );
  }
}

/// Collapsed-by-default "My Rotation" section on the Dashboard. Consolidates
/// the month calendar and an upcoming-shifts glance into one expandable tile so
/// the home screen stays clean, with a jump to the full Roster tab. Embeds the
/// data-driven [ShiftCalendarView] (read-only here) and reuses the shared
/// `visualFor` / `shift_format` helpers — no calendar/roster rendering is
/// duplicated here.
class _MyRotationTile extends StatelessWidget {
  const _MyRotationTile({
    required this.shifts,
    required this.now,
    this.onOpenTab,
  });

  final List<Shift> shifts;
  final DateTime now;
  final void Function(int index)? onOpenTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Soonest-first upcoming working shifts (an in-progress shift still
    // counts), capped to a short preview.
    final preview = (shifts
            .where((s) => s.type != ShiftType.off && s.endDateTime.isAfter(now))
            .toList()
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime)))
        .take(3)
        .toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(
          Icons.event_note_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          'My Rotation',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          'Calendar & upcoming shifts',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        children: [
          // Read-only month overview, bound to the SAME Hive shift stream as
          // the Timeline (no `onDayTapped` → glance only; the interactive
          // add/edit calendar lives on the Timeline tab).
          ShiftCalendarView(
            shifts: shifts,
            startWeekOnMonday: AppPreferences.startWeekOnMondayOf(context),
            // Compact density so the mini-calendar scales crisply into the
            // dashboard tile (tighter rows, smaller day numbers + bars).
            compact: true,
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Text('Next shifts', style: theme.textTheme.labelLarge),
              ),
            ),
            for (final s in preview) _NextShiftPreviewRow(shift: s),
          ],
          if (onOpenTab != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('my-rotation-view-roster'),
                // Timeline is index 1 post-migration (was Roster at 2).
                onPressed: () => onOpenTab!(1),
                icon: const Icon(Icons.view_list, size: 18),
                label: const Text('Open Timeline'),
              ),
            ),
        ],
      ),
    );
  }
}

/// One compact upcoming-shift row inside [_MyRotationTile] — type glyph +
/// "Day · Mon, Jun 8" + start time, all from the shared visual/format helpers.
class _NextShiftPreviewRow extends StatelessWidget {
  const _NextShiftPreviewRow({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = visualFor(shift.type);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Icon(visual.icon, color: visual.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${shiftTypeLabel(shift.type)} · ${formatShiftDate(shift.date)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatClock(
              shift.startMinutes,
              use24Hour: AppPreferences.use24HourOf(context),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
