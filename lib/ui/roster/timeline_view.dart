import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/shift.dart';
import '../../data/models/shift_type.dart';
import '../../data/repositories/shift_repository.dart';
import '../shift_format.dart';
import 'shift_filter.dart';
import 'shift_visuals.dart';

/// Chronological list view of (already-filtered) shifts. **Pure visual
/// representation** — no alarm controls, no mute toggle, no snooze
/// affordance. The Roster's job is to show "what shifts am I working?";
/// all alarm CRUD lives on the Alarms tab.
///
/// Receives [filter] purely so the empty-state copy can distinguish
/// "you have nothing scheduled" from "your filter hides everything".
///
/// Stateful + `AutomaticKeepAliveClientMixin` so the ListView's scroll
/// offset survives toggling between Timeline and Calendar in the parent
/// `IndexedStack`. Without the mixin the tab is rebuilt from scratch on
/// every switch and the user loses their place in the list.
class TimelineView extends StatefulWidget {
  const TimelineView({
    super.key,
    required this.shifts,
    required this.filter,
  });

  final List<Shift> shifts;
  final ShiftFilter filter;

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView>
    with AutomaticKeepAliveClientMixin<TimelineView> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // Required first call when using AutomaticKeepAliveClientMixin —
    // signals the parent that this State should be retained.
    super.build(context);
    if (widget.shifts.isEmpty) {
      return _EmptyTimeline(filter: widget.filter);
    }
    // Defensive sort by absolute start instant. The repository already
    // sorts by date+startMinutes, but explicit ordering here decouples
    // the view from any future repo-level reordering.
    final sorted = [...widget.shifts]
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

/// One row in the roster list. Shows shift type icon + date + time
/// range, with swipe-to-delete for shift management. **Carries no
/// alarm UI** — bell, mute toggle, snooze-kill, and the muted-dimming
/// treatment all moved out when the Alarms tab took over alarm CRUD.
///
/// Public so the calendar view's day-shift bottom sheet can reuse the
/// same row treatment.
class ShiftCard extends StatelessWidget {
  const ShiftCard({super.key, required this.shift});

  final Shift shift;

  // Vertical margin between cards; matches the Dismissible background so
  // the red surface lines up with the card during the swipe animation.
  static const _cardVerticalMargin = 6.0;
  static const _cardHorizontalMargin = 12.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = visualFor(shift.type);

    return Dismissible(
      key: ValueKey(shift.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: _cardHorizontalMargin,
          vertical: _cardVerticalMargin,
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
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: _cardHorizontalMargin,
          vertical: _cardVerticalMargin,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
            ],
          ),
        ),
      ),
    );
  }
}

String _timeRange(Shift shift) {
  if (shift.type == ShiftType.off) return 'All day';
  return '${formatHhmm(shift.startMinutes)} – ${formatHhmm(shift.endMinutes)}';
}
