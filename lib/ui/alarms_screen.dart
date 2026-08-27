import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/alarm_settings.dart';
import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/app_alarm_repository.dart';
import '../alarms/alarm_projection.dart';
import '../alarms/one_off_snooze_store.dart';
import '../logic/alarm_sort.dart';
import '../state/app_preferences.dart';
import 'alarm_time_projection.dart';
import 'create_alarm_sheet.dart';
import 'roster/shift_visuals.dart';
import 'shift_format.dart';

/// The Alarms room — tab 2 of the MainLayout chassis. Currently a
/// read + toggle surface; the create / edit flow lands in the next
/// phase ("the complex bundle logic"), so the FAB shows a placeholder
/// dialog and no widget here mutates beyond flipping `enabled`.
///
/// Source of truth: `context.watch<List<AppAlarm>>()` from `AppProviders`,
/// which streams the `alarms` Hive box.
class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alarms = context.watch<List<AppAlarm>>();
    // The global lead time is the fallback offset for a follows-rotation card
    // that has no per-alarm override. Provided by AppProviders; same source the
    // engine uses.
    final globalLeadMinutes = context.watch<AlarmSettings>().leadTime.inMinutes;
    // Roster shifts (streamed app-wide) let each card show the REAL firing
    // clock time for its linked shift type, not the bare offset.
    final shifts = context.watch<List<Shift>>();
    final use24Hour = AppPreferences.use24HourOf(context);
    final isSchedulePaused = AppPreferences.isSchedulePausedOf(context);
    // Hero target: the next follows-rotation alarm + the shift it's linked to.
    // Display projection only (kRingDisplayHorizon); the engine is untouched.
    final heroRing = nextRotationRing(
      alarms: alarms,
      shifts: shifts,
      globalLeadMinutes: globalLeadMinutes,
      now: DateTime.now(),
      isSchedulePaused: isSchedulePaused,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms'),
        actions: [
          // Sort control — offered only when there's a list to order. Purely a
          // display preference (persisted); it never touches alarm scheduling.
          if (alarms.isNotEmpty)
            _AlarmSortMenu(
              byShiftType: AppPreferences.alarmSortByShiftTypeOf(context),
            ),
        ],
      ),
      // SafeArea(top: false) — AppBar already consumes the status-bar
      // inset; bottom matters so the list and FAB don't tuck under the
      // gesture pill / 3-button bar on edge-to-edge displays.
      body: SafeArea(
        top: false,
        child: alarms.isEmpty
            ? const _EmptyState()
            : Column(
                children: [
                  _NextAlarmHero(
                    ring: heroRing,
                    use24Hour: use24Hour,
                    isSchedulePaused: isSchedulePaused,
                  ),
                  Expanded(
                    child: _AlarmList(
                      alarms: alarms,
                      globalLeadMinutes: globalLeadMinutes,
                      shifts: shifts,
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('alarms-add-fab'),
        // See RosterScreen for the rationale — IndexedStack keeps
        // both FABs alive at once; nulling the heroTag breaks the
        // default-tag collision without affecting the tap behaviour.
        heroTag: null,
        onPressed: () => showCreateAlarmSheet(context),
        tooltip: 'Add alarm',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// AppBar sort control for the Alarms list. Two mutually-exclusive orders — by
/// ring time (default) or grouped by shift type — persisted via
/// [AppPreferences] so the choice sticks. Display-only; the alarm engine never
/// reads it.
class _AlarmSortMenu extends StatelessWidget {
  const _AlarmSortMenu({required this.byShiftType});

  final bool byShiftType;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<bool>(
      key: const ValueKey('alarms-sort-menu'),
      icon: const Icon(Icons.sort),
      tooltip: 'Sort alarms',
      onSelected: (value) =>
          context.read<AppPreferences?>()?.setAlarmSortByShiftType(value),
      itemBuilder: (context) => [
        CheckedPopupMenuItem<bool>(
          key: const ValueKey('alarms-sort-by-time'),
          value: false,
          checked: !byShiftType,
          child: const Text('By time'),
        ),
        CheckedPopupMenuItem<bool>(
          key: const ValueKey('alarms-sort-by-shift-type'),
          value: true,
          checked: byShiftType,
          child: const Text('By shift type'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No alarms yet.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add one.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium "Next Alarm" hero pinned above the rule list. Shows the absolute
/// next follows-rotation ring (the dominant shift-worker case) and the shift
/// it's linked to. Holiday Mode and "nothing upcoming" get their own calm
/// states. Pure display — driven by [nextRotationAlarmRing], no Hive writes.
class _NextAlarmHero extends StatelessWidget {
  const _NextAlarmHero({
    required this.ring,
    required this.use24Hour,
    required this.isSchedulePaused,
  });

  final AlarmRing? ring;
  final bool use24Hour;
  final bool isSchedulePaused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const ValueKey('alarms-next-hero'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerHigh,
            scheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isSchedulePaused
                    ? Icons.pause_circle_outline
                    : Icons.notifications_active_outlined,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'NEXT ALARM',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._buildBody(theme),
        ],
      ),
    );
  }

  List<Widget> _buildBody(ThemeData theme) {
    final scheme = theme.colorScheme;
    if (isSchedulePaused) {
      return [
        Text(
          'Holiday mode',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Alarms are paused — nothing will ring.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ];
    }
    final r = ring;
    if (r == null) {
      return [
        Text(
          'No upcoming shift alarm',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add a follows-rotation alarm, or generate a roster.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ];
    }
    final clock =
        formatClock(r.fireAt.hour * 60 + r.fireAt.minute, use24Hour: use24Hour);
    final shift = r.shift;
    final subtitle = shift != null
        ? 'for your ${shiftTypeLabel(shift.type)} shift · ${_formatRelativeDay(r.fireAt)}'
        : '${r.alarm.label} · ${_formatRelativeDay(r.fireAt)}';
    return [
      Text(
        clock,
        style: theme.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1,
          color: scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: theme.textTheme.titleSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ];
  }
}

/// "Today" / "Tomorrow" / "Mon, Jun 16" for a fire instant, relative to now.
/// Shared by the hero and the per-card "Next ring" line.
String _formatRelativeDay(DateTime when) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(when.year, when.month, when.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  return formatShiftDate(when);
}

class _AlarmList extends StatelessWidget {
  const _AlarmList({
    required this.alarms,
    required this.globalLeadMinutes,
    required this.shifts,
  });

  final List<AppAlarm> alarms;
  final int globalLeadMinutes;
  final List<Shift> shifts;

  @override
  Widget build(BuildContext context) {
    // Deterministic display order (pure UI — never touches scheduling). The
    // repo gives no ordering guarantee, so the list sorts on display: by the
    // real ring clock time, or grouped by shift type when the user picks that
    // in the sort menu. Sorting on the true fire time (not the raw
    // `minutesOfDay`, a placeholder for rotation alarms) is what stops a new
    // alarm from landing at the bottom.
    final sorted = sortAlarmsForDisplay(
      alarms,
      shifts: shifts,
      globalLeadMinutes: globalLeadMinutes,
      byShiftType: AppPreferences.alarmSortByShiftTypeOf(context),
      now: DateTime.now(),
    );
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _AlarmCard(
        key: ValueKey('alarm-card-${sorted[i].id}'),
        alarm: sorted[i],
        globalLeadMinutes: globalLeadMinutes,
        shifts: shifts,
      ),
    );
  }
}

class _AlarmCard extends StatefulWidget {
  const _AlarmCard({
    super.key,
    required this.alarm,
    required this.globalLeadMinutes,
    required this.shifts,
  });

  final AppAlarm alarm;
  final int globalLeadMinutes;
  final List<Shift> shifts;

  @override
  State<_AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<_AlarmCard> {
  bool _confirming = false;

  Future<void> _onConfirmDelete() async {
    // Snapshot the repo before the await — the stream-driven rebuild
    // will drop this card from the list as soon as delete resolves,
    // and reading context post-await would race with disposal.
    final repo = context.read<AppAlarmRepository>();
    await repo.delete(widget.alarm.id);
    // Anti-stick guard: on a successful delete this card unmounts and the
    // setState no-ops (mounted == false). If a delete were ever a no-op, the
    // card resets to its normal row instead of being stranded in the committed
    // slide-to-confirm state (the reported "blank tile"). Defensive — the
    // stream rebuild is still the primary removal path.
    if (mounted) setState(() => _confirming = false);
  }

  void _onCancel() {
    if (!mounted) return;
    setState(() => _confirming = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alarm = widget.alarm;
    // Vertical, color-coded strip on the left edge keyed to the linked shift
    // type (Day/Afternoon/Night via the shared palette); dimmed when disabled.
    final stripColor = _stripColorFor(alarm, theme)
        .withValues(alpha: alarm.enabled ? 1.0 : 0.4);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              key: ValueKey('alarm-strip-${alarm.id}'),
              width: 5,
              color: stripColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: _confirming
                    ? _buildConfirmingRow(theme)
                    : _buildNormalRow(context, theme, alarm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Strip colour = the linked shift type's palette colour for a
  /// follows-rotation alarm, else the primary accent (one-time / weekly alarms
  /// aren't linked to a shift type).
  Color _stripColorFor(AppAlarm a, ThemeData theme) {
    final type = a.linkedShiftType;
    if (a.repeatType == AppAlarmRepeatType.followsRotation && type != null) {
      return visualFor(type).color;
    }
    return theme.colorScheme.primary;
  }

  Widget _buildNormalRow(
    BuildContext context,
    ThemeData theme,
    AppAlarm alarm,
  ) {
    final fadedWhenOff = alarm.enabled ? 1.0 : 0.55;
    // Visual proof of "when does this actually ring next" — the next valid
    // matching shift (rotation) or occurrence (one-time / weekly) in range.
    final nextRing = nextAlarmRing(
      alarms: [alarm],
      shifts: widget.shifts,
      globalLeadMinutes: widget.globalLeadMinutes,
      now: DateTime.now(),
      // Without this a snoozed one-time alarm's "Next ring" label reads as
      // though nothing is scheduled, minutes before it rings.
      oneOffSnoozes: readOneOffSnoozes(),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tapping the card body slides up the create/edit sheet pre-populated
        // with this alarm. The Switch and delete button are separate siblings
        // below, so their gestures never collide with this tap target.
        Expanded(
          child: InkWell(
            key: ValueKey('alarm-card-tap-${alarm.id}'),
            onTap: () => showCreateAlarmSheet(context, initial: alarm),
            borderRadius: BorderRadius.circular(8),
            child: Opacity(
              opacity: fadedWhenOff,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _alarmHeadline(
                      alarm,
                      widget.shifts,
                      widget.globalLeadMinutes,
                      AppPreferences.use24HourOf(context),
                    ),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alarm.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _alarmDetailLine(alarm, widget.globalLeadMinutes),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildNextRingLine(context, theme, alarm, nextRing),
                ],
              ),
            ),
          ),
        ),
        Switch.adaptive(
          value: alarm.enabled,
          onChanged: (v) => context
              .read<AppAlarmRepository>()
              .upsert(alarm.copyWith(enabled: v)),
        ),
        IconButton(
          key: ValueKey('alarm-delete-icon-${alarm.id}'),
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete',
          onPressed: () => setState(() => _confirming = true),
        ),
      ],
    );
  }

  /// The dynamic "visual proof" line under the rule description. Highlighted in
  /// the accent colour so it reads as the card's most actionable fact. A single
  /// combined string (never a bare clock) so it can't be confused with the hero.
  Widget _buildNextRingLine(
    BuildContext context,
    ThemeData theme,
    AppAlarm alarm,
    AlarmRing? ring,
  ) {
    final scheme = theme.colorScheme;
    if (!alarm.enabled) {
      return Text(
        "Off — won't ring",
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    if (ring == null) {
      return Text(
        'No upcoming ring scheduled',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    final clock = formatClock(
      ring.fireAt.hour * 60 + ring.fireAt.minute,
      use24Hour: AppPreferences.use24HourOf(context),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 13, color: scheme.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Next ring: ${_formatRelativeDay(ring.fireAt)} at $clock',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmingRow(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _SlideToConfirmDelete(onConfirm: _onConfirmDelete),
        ),
        IconButton(
          key: ValueKey('alarm-delete-cancel-${widget.alarm.id}'),
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: _onCancel,
        ),
      ],
    );
  }
}

/// Compact slide-to-confirm bar — the in-place confirmation affordance
/// per Rostrik's UX standard (visible icon → swipe-to-confirm) for
/// destructive actions. Modelled on `_SlideToDismiss` in
/// `wake_up_screen.dart` but sized for a list-row context; intentionally
/// not yet extracted to a shared widget (the two contexts have different
/// dimensions and copy — extract on the third use case).
class _SlideToConfirmDelete extends StatefulWidget {
  const _SlideToConfirmDelete({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<_SlideToConfirmDelete> createState() => _SlideToConfirmDeleteState();
}

class _SlideToConfirmDeleteState extends State<_SlideToConfirmDelete> {
  static const double _trackHeight = 44;
  static const double _handleSize = 36;
  static const double _handleInset = 4;
  static const double _commitFraction = 0.6;

  double _dragX = 0;
  bool _committed = false;

  void _onUpdate(double maxX, DragUpdateDetails d) {
    if (_committed) return;
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(0.0, maxX);
    });
  }

  Future<void> _onEnd(double maxX) async {
    if (_committed) return;
    if (_dragX >= maxX * _commitFraction) {
      _committed = true;
      setState(() => _dragX = maxX);
      await widget.onConfirm();
    } else {
      setState(() => _dragX = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Tight-height SizedBox around the LayoutBuilder is load-bearing: this row
    // renders inside the card's IntrinsicHeight, which queries its children's
    // intrinsic height. A bare LayoutBuilder can't answer that — in debug it
    // throws, in release the intrinsic height resolves to 0 and the confirm row
    // collapses into a blank, unusable tile (the field-reported delete bug). The
    // tight SizedBox lets IntrinsicHeight short-circuit to _trackHeight without
    // descending into the LayoutBuilder.
    return SizedBox(
      height: _trackHeight,
      child: LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxX = trackWidth - _handleSize - (_handleInset * 2);
        final progress = maxX <= 0 ? 0.0 : (_dragX / maxX).clamp(0.0, 1.0);
        return Container(
          height: _trackHeight,
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(_trackHeight / 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1 - progress,
                child: Text(
                  'Swipe to delete',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: _handleInset + _dragX,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (d) => _onUpdate(maxX, d),
                  onHorizontalDragEnd: (_) => _onEnd(maxX),
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.onError,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      ),
    );
  }
}

/// Card headline — the calculated FIRING CLOCK TIME (AM/PM), the hero. One-time
/// alarms ring at their absolute time; follows-rotation alarms render through
/// [AppAlarm.displayFireClockMinutes] — the single source of truth shared with
/// the engine's fire-time math — so the card respects exact-time mode and can
/// never show a clock the engine didn't arm. The offset moves to
/// [_alarmDetailLine].
String _alarmHeadline(
  AppAlarm a,
  List<Shift> shifts,
  int globalLeadMinutes,
  bool use24Hour,
) {
  // oneTime and weekly both ring at their absolute picked clock time.
  if (a.repeatType == AppAlarmRepeatType.oneTime ||
      a.repeatType == AppAlarmRepeatType.weekly) {
    return formatClock(a.minutesOfDay, use24Hour: use24Hour);
  }
  // linkedShiftType is non-null for any alarm created via the sheet; a stray
  // null (invalid config, never scheduled) falls back to a Day anchor so the
  // card still renders a clock rather than crashing.
  final type = a.linkedShiftType ?? ShiftType.day;
  final shiftStart =
      resolveShiftStartMinutes(shifts, type, now: DateTime.now());
  return formatClock(
    a.displayFireClockMinutes(
      shiftStartMinutes: shiftStart,
      globalLeadMinutes: globalLeadMinutes,
    ),
    use24Hour: use24Hour,
  );
}

/// Card detail line — the demoted timing label. Lead-time mode: "1h 30m before
/// Day shifts" (a "· default" marker when the offset tracks the Settings
/// value). Exact-time mode: "Exact time · Day shifts" — same copy as the
/// create sheet's caption, since no lead applies. One-time alarms keep a
/// simple descriptor.
String _alarmDetailLine(AppAlarm a, int globalLeadMinutes) {
  if (a.repeatType == AppAlarmRepeatType.oneTime) {
    return a.autoDeleteAfterFiring
        ? 'Rings once · auto-deletes'
        : 'Rings one time only';
  }
  if (a.repeatType == AppAlarmRepeatType.weekly) {
    return formatWeekdays(a.weekdaysBitmask);
  }
  final shift = a.linkedShiftType == null
      ? 'your shift'
      : '${shiftTypeLabel(a.linkedShiftType!)} shifts';
  // Same mode gate the fire-time math uses, so a malformed exact-time record
  // (null clock) correctly reads as the lead-time line it actually fires on.
  if (a.activeExactTimeMinutes != null) {
    return 'Exact time · $shift';
  }
  if (a.relativeOffsetMinutes == null) {
    return '${formatLeadOffset(globalLeadMinutes)} before $shift · default';
  }
  return '${formatLeadOffset(a.relativeOffsetMinutes!)} before $shift';
}
