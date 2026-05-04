import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/alarm_settings.dart';
import '../../data/models/shift.dart';
import '../../data/models/shift_type.dart';
import '../../data/repositories/shift_repository.dart';
import '../shift_format.dart';
import 'shift_filter.dart';
import 'shift_visuals.dart';

/// Chronological list view of (already-filtered) shifts. Pure view: writes
/// flow through `context.read<ShiftRepository>()`; no alarm logic touched.
///
/// Receives [filter] purely so the empty-state copy can distinguish
/// "you have nothing scheduled" from "your filter hides everything".
class TimelineView extends StatelessWidget {
  const TimelineView({
    super.key,
    required this.shifts,
    required this.filter,
  });

  final List<Shift> shifts;
  final ShiftFilter filter;

  @override
  Widget build(BuildContext context) {
    if (shifts.isEmpty) {
      return _EmptyTimeline(filter: filter);
    }
    // Defensive sort by absolute start instant. The repository already
    // sorts by date+startMinutes, but explicit ordering here decouples
    // the view from any future repo-level reordering.
    final sorted = [...shifts]
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      itemBuilder: (_, i) => ShiftCard(
        key: ValueKey('shift-card-${sorted[i].id}'),
        shift: sorted[i],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline({required this.filter});

  final ShiftFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = filter == ShiftFilter.all
        ? 'No shifts scheduled. Tap + to add one.'
        : 'No shifts match the ${filter.label} filter.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// One row in the roster list. Holds the local "am I in swipe-to-confirm
/// mode?" state — kept here (not lifted to RosterScreen) so a confirm-mode
/// card doesn't survive the user scrolling away and back; element diffing
/// disposes the State alongside the widget.
///
/// Public so the calendar view's day-shift bottom sheet can reuse the
/// same row treatment (mute toggle, swipe-delete, alarm trailing) without
/// reimplementing it.
class ShiftCard extends StatefulWidget {
  const ShiftCard({super.key, required this.shift});

  final Shift shift;

  // Vertical margin between cards; matches the Dismissible background so
  // the red surface lines up with the card during the swipe animation.
  static const _cardVerticalMargin = 6.0;
  static const _cardHorizontalMargin = 12.0;

  @override
  State<ShiftCard> createState() => _ShiftCardState();
}

class _ShiftCardState extends State<ShiftCard> {
  bool _confirming = false;

  void _enterConfirm() {
    if (!_confirming) setState(() => _confirming = true);
  }

  void _exitConfirm() {
    if (_confirming) setState(() => _confirming = false);
  }

  /// Commits the mute/unmute toggle to the repository. Called only when the
  /// user has dragged the slider thumb past the completion threshold.
  Future<void> _commitToggle() async {
    final repo = context.read<ShiftRepository>();
    final shift = widget.shift;
    await repo.upsert(shift.copyWith(isMuted: !shift.isMuted));
    // The StreamProvider re-emits, this State is rebuilt with a fresh
    // shift, and we drop confirm-mode so the new state is visible.
    if (mounted) _exitConfirm();
  }

  @override
  Widget build(BuildContext context) {
    if (_confirming) {
      return _SwipeToConfirmCard(
        // Confirm UI describes the action being committed — the OPPOSITE
        // of the current state.
        currentlyMuted: widget.shift.isMuted,
        onConfirm: _commitToggle,
        onCancel: _exitConfirm,
      );
    }
    return _NormalShiftCard(
      shift: widget.shift,
      onMuteIconPressed: _enterConfirm,
    );
  }
}

class _NormalShiftCard extends StatelessWidget {
  const _NormalShiftCard({
    required this.shift,
    required this.onMuteIconPressed,
  });

  final Shift shift;
  final VoidCallback onMuteIconPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = visualFor(shift.type);
    // Alarm time is a pure derivation of the shift + the current global
    // lead time. The UI doesn't read engine state — it computes the same
    // fireAt the engine would (engine source of truth: AlarmEngine._doReconcile).
    final settings = context.watch<AlarmSettings>();
    final alarm = _alarmFor(shift, settings.leadTime);

    // Show the toggle when there's something to act on: an alarm the user
    // might want to mute, or an already-muted shift the user might want to
    // unmute. Hides on OFF/past unmuted shifts (no alarm to suppress).
    final showMuteToggle = alarm != null || shift.isMuted;

    return Dismissible(
      key: ValueKey(shift.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: ShiftCard._cardHorizontalMargin,
          vertical: ShiftCard._cardVerticalMargin,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      // Fire-and-forget: Hive's BoxEvent fires within microseconds, the
      // StreamProvider re-emits, and the list rebuilds without this id.
      // Stable ValueKey(shift.id) keeps Flutter's element diff happy
      // across the brief window between dismissal and stream re-emit.
      onDismissed: (_) {
        context.read<ShiftRepository>().delete(shift.id);
      },
      child: Opacity(
        // Muted shifts visibly demoted in the list. Distinct from "deleted"
        // because the row is still there and still tappable to unmute.
        opacity: shift.isMuted ? 0.55 : 1.0,
        child: Card(
          margin: const EdgeInsets.symmetric(
            horizontal: ShiftCard._cardHorizontalMargin,
            vertical: ShiftCard._cardVerticalMargin,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: visual.color.withValues(alpha: 0.18),
                  foregroundColor: visual.color,
                  child: Icon(visual.icon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatShiftDate(shift.date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${shiftTypeLabel(shift.type)} · ${_timeRange(shift)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (alarm != null) ...[
                  const SizedBox(width: 12),
                  _AlarmTrailing(alarm),
                ],
                if (showMuteToggle)
                  _MuteToggleIconButton(
                    isMuted: shift.isMuted,
                    onPressed: onMuteIconPressed,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The persistent mute/unmute affordance shown next to the alarm cluster.
/// Tap does NOT mutate state — it asks the parent _ShiftCardState to enter
/// swipe-to-confirm mode. The 2-step gesture is intentional friction to
/// prevent accidental mutes when the user is sleep-impaired.
class _MuteToggleIconButton extends StatelessWidget {
  const _MuteToggleIconButton({
    required this.isMuted,
    required this.onPressed,
  });

  final bool isMuted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(
        isMuted
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
      ),
      color: isMuted
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant,
      tooltip: isMuted ? 'Unmute alarm' : 'Mute alarm',
      onPressed: onPressed,
    );
  }
}

/// Replaces the entire shift card while the user is confirming a mute /
/// unmute. Wider than the trailing icon would be, so a sleep-impaired user
/// has a generous track to drag along.
///
/// Behaviour contract:
///   - Drag the thumb past [_completionThreshold] of the track ⇒ animate
///     to end + invoke [onConfirm].
///   - Release before the threshold ⇒ thumb springs back to start; widget
///     stays in confirm mode so the user can retry without going back.
///   - Tap the explicit cancel × ⇒ [onCancel] (return to normal card).
class _SwipeToConfirmCard extends StatefulWidget {
  const _SwipeToConfirmCard({
    required this.currentlyMuted,
    required this.onConfirm,
    required this.onCancel,
  });

  /// Whether the shift is currently muted. The action being confirmed is
  /// always the OPPOSITE — mute when false, unmute when true.
  final bool currentlyMuted;
  final Future<void> Function() onConfirm;
  final VoidCallback onCancel;

  @override
  State<_SwipeToConfirmCard> createState() => _SwipeToConfirmCardState();
}

class _SwipeToConfirmCardState extends State<_SwipeToConfirmCard>
    with SingleTickerProviderStateMixin {
  // Geometry. Big thumb because the target user may be sleep-impaired.
  static const double _thumbSize = 56;
  static const double _trackPadding = 6;
  static const double _cardHeight = 76;
  // Fraction of the track the thumb must cross before release commits.
  // 0.85 leaves a small "definitely not committing" window at the right
  // edge so a tentative drag doesn't accidentally confirm.
  static const double _completionThreshold = 0.85;

  /// 0.0 = thumb at start, 1.0 = thumb at the right edge of the track.
  /// Driven directly by the user's drag, then by an `animateTo` on release
  /// (back to 0 if the swipe was abandoned, forward to 1 if it committed).
  late final AnimationController _progress;

  /// True between the moment the user releases past threshold and the
  /// moment the parent rebuilds us out of existence. Disables further
  /// drags and the cancel button so the gesture can't fire twice.
  bool _committing = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  String get _label =>
      widget.currentlyMuted ? 'Swipe to unmute' : 'Swipe to mute';

  IconData get _thumbIcon => widget.currentlyMuted
      ? Icons.notifications_active
      : Icons.notifications_off;

  void _onDragUpdate(double deltaDx, double maxOffset) {
    if (_committing || maxOffset == 0) return;
    final nextOffset =
        (_progress.value * maxOffset + deltaDx).clamp(0.0, maxOffset);
    _progress.value = nextOffset / maxOffset;
  }

  Future<void> _onDragEnd() async {
    if (_committing) return;
    if (_progress.value >= _completionThreshold) {
      setState(() => _committing = true);
      await _progress.animateTo(
        1.0,
        duration: const Duration(milliseconds: 120),
      );
      try {
        await widget.onConfirm();
      } finally {
        // The parent typically rebuilds us out of existence in onConfirm;
        // guard against late callbacks just in case.
        if (mounted) setState(() => _committing = false);
      }
    } else {
      await _progress.animateTo(0.0, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: ShiftCard._cardHorizontalMargin,
        vertical: ShiftCard._cardVerticalMargin,
      ),
      color: theme.colorScheme.surfaceContainerHighest,
      child: SizedBox(
        height: _cardHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxOffset = math.max(
                      0.0,
                      constraints.maxWidth - _thumbSize - _trackPadding * 2,
                    );
                    return _SwipeTrack(
                      progress: _progress,
                      label: _label,
                      accent: accent,
                      onAccent: theme.colorScheme.onPrimary,
                      thumbIcon: _thumbIcon,
                      thumbSize: _thumbSize,
                      trackPadding: _trackPadding,
                      maxOffset: maxOffset,
                      onDragUpdate: (delta) => _onDragUpdate(delta, maxOffset),
                      onDragEnd: _onDragEnd,
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
                onPressed: _committing ? null : widget.onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pure presentational track + thumb. All state lives in the parent's
/// AnimationController; this widget just renders the current value and
/// forwards drag deltas back up.
class _SwipeTrack extends StatelessWidget {
  const _SwipeTrack({
    required this.progress,
    required this.label,
    required this.accent,
    required this.onAccent,
    required this.thumbIcon,
    required this.thumbSize,
    required this.trackPadding,
    required this.maxOffset,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final AnimationController progress;
  final String label;
  final Color accent;
  final Color onAccent;
  final IconData thumbIcon;
  final double thumbSize;
  final double trackPadding;
  final double maxOffset;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Label fades out as the thumb advances — gives the user a
            // visual cue that the action is "engaging" rather than just
            // moving a knob.
            Padding(
              padding: EdgeInsets.only(left: thumbSize + trackPadding),
              child: Opacity(
                opacity: 1.0 - progress.value,
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ),
            Positioned(
              left: trackPadding + progress.value * maxOffset,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (d) => onDragUpdate(d.delta.dx),
                  onHorizontalDragEnd: (_) => onDragEnd(),
                  child: Container(
                    key: const ValueKey('swipe-thumb'),
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(thumbIcon, color: onAccent),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Right-aligned alarm cluster: bell + time on top in primary colour,
/// optional "(prev day)" subtitle below in muted variant.
class _AlarmTrailing extends StatelessWidget {
  const _AlarmTrailing(this.info);

  final _AlarmInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.alarm,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              info.time,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        if (info.crossesDay)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '(prev day)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _AlarmInfo {
  const _AlarmInfo({required this.time, required this.crossesDay});
  final String time; // HH:MM
  final bool crossesDay; // fireAt landed on the calendar day before the shift
}

/// Returns the alarm display info, or null when no alarm will fire (OFF
/// shifts; muted shifts; shifts whose computed fireAt is already in the
/// past). Mirrors the engine's filtering rules so the UI never advertises
/// an alarm the engine wouldn't actually schedule.
_AlarmInfo? _alarmFor(Shift shift, Duration leadTime) {
  if (shift.type == ShiftType.off) return null;
  if (shift.isMuted) return null;
  final fireAt = shift.startDateTime.subtract(leadTime);
  if (!fireAt.isAfter(DateTime.now())) return null;
  final hhmm = formatHhmm(fireAt.hour * 60 + fireAt.minute);
  // For early-morning shifts with a long lead time, fireAt may land on
  // the previous calendar day. Surface that so the time isn't ambiguous.
  final fireDate = DateTime(fireAt.year, fireAt.month, fireAt.day);
  final crossesDay = !fireDate.isAtSameMomentAs(shift.date);
  return _AlarmInfo(time: hhmm, crossesDay: crossesDay);
}

String _timeRange(Shift shift) {
  if (shift.type == ShiftType.off) return 'All day';
  return '${formatHhmm(shift.startMinutes)} – ${formatHhmm(shift.endMinutes)}';
}
