import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/shift.dart';
import '../../data/models/shift_type.dart';
import '../../data/repositories/shift_repository.dart';
import '../../state/app_preferences.dart';
import '../shift_editor_modal.dart';
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

  // Approximate rendered heights (px) used to estimate the scroll offset of
  // today's shift so the list opens ON today instead of a year in the past.
  // Only an estimate — a post-jump `ensureVisible` refines it to the pixel.
  static const double _topSpacer = 4;
  static const double _headerHeight = _MonthHeaderDelegate._height;
  static const double _workingCardHeight = 84;
  static const double _offRowHeight = 38;

  final ScrollController _controller = ScrollController();

  /// The card the initial scroll should land on (today's shift, or the next
  /// upcoming one). Re-created each build; only the current one is attached.
  final GlobalKey _anchorKey = GlobalKey();

  /// One-shot: auto-scroll to today only on the FIRST build with data. The
  /// keep-alive mixin preserves the user's manual scroll position across tab
  /// switches, and a later stream re-emit (e.g. after an edit) must not yank
  /// them back to today.
  bool _didInitialScroll = false;

  /// Estimated offset of the anchor card, computed during build.
  double _anchorEstimate = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Jumps to the estimated offset (so the anchor region builds), then refines
  /// with [Scrollable.ensureVisible] once the anchor card exists — placing it
  /// just below the pinned month header.
  void _scrollToAnchor() {
    if (_didInitialScroll || !_controller.hasClients) return;
    _didInitialScroll = true;
    final max = _controller.position.maxScrollExtent;
    _controller.jumpTo(_anchorEstimate.clamp(0.0, max));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _anchorKey.currentContext;
      if (ctx == null || !_controller.hasClients) return;
      final vp = _controller.position.viewportDimension;
      // Leave room for the pinned header so the anchor isn't tucked under it.
      final headerFraction = vp > 0 ? (_headerHeight / vp).clamp(0.0, 0.4) : 0.0;
      Scrollable.ensureVisible(ctx, alignment: headerFraction);
    });
  }

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

    // The anchor: the first shift on or after today (else the last shift, if
    // the whole roster is in the past).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var anchorIndex = sorted.indexWhere((s) => !s.date.isBefore(today));
    if (anchorIndex < 0) anchorIndex = sorted.length - 1;
    final anchorId = sorted[anchorIndex].id;

    // Group consecutive shifts by calendar month (already sorted → contiguous
    // runs) so each month gets one sticky header — breaking the wall of cards.
    final groups = <({DateTime month, List<Shift> shifts})>[];
    for (final s in sorted) {
      final month = DateTime(s.date.year, s.date.month);
      if (groups.isEmpty || groups.last.month != month) {
        groups.add((month: month, shifts: <Shift>[s]));
      } else {
        groups.last.shifts.add(s);
      }
    }

    _anchorEstimate = _estimateAnchorOffset(groups, anchorId);
    if (!_didInitialScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToAnchor());
    }

    return CustomScrollView(
      controller: _controller,
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: _topSpacer)),
        for (final g in groups) ...[
          SliverPersistentHeader(
            pinned: true,
            delegate: _MonthHeaderDelegate(label: formatMonthYearHeader(g.month)),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final card = ShiftCard(
                  key: ValueKey('shift-card-${g.shifts[i].id}'),
                  shift: g.shifts[i],
                );
                // Wrap only the anchor in a KeyedSubtree so `ensureVisible` has
                // a context to land on, WITHOUT stealing the card's ValueKey.
                return g.shifts[i].id == anchorId
                    ? KeyedSubtree(key: _anchorKey, child: card)
                    : card;
              },
              childCount: g.shifts.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
      ],
    );
  }

  /// Estimates the scroll offset of the anchor card by summing the approximate
  /// heights of everything above it (top spacer + one header per month + each
  /// card/off-row). Rough by design — [_scrollToAnchor] refines it.
  double _estimateAnchorOffset(
    List<({DateTime month, List<Shift> shifts})> groups,
    String anchorId,
  ) {
    var offset = _topSpacer;
    for (final g in groups) {
      offset += _headerHeight;
      for (final s in g.shifts) {
        if (s.id == anchorId) return offset;
        offset += s.type == ShiftType.off ? _offRowHeight : _workingCardHeight;
      }
    }
    return offset;
  }
}

/// Pinned, opaque month header ("JUNE 2026") that sticks to the top as its
/// section scrolls and is pushed up by the next month's header.
class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  _MonthHeaderDelegate({required this.label});

  final String label;

  static const double _height = 34;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return Container(
      height: _height,
      alignment: Alignment.centerLeft,
      // Opaque so scrolling cards never bleed through the pinned header.
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MonthHeaderDelegate oldDelegate) =>
      oldDelegate.label != label;
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
    final paused = shift.isPaused;
    final muted = theme.colorScheme.onSurfaceVariant;
    final isOff = shift.type == ShiftType.off;

    return Dismissible(
      key: ValueKey(shift.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.symmetric(
          horizontal: _cardHorizontalMargin,
          vertical: isOff ? 3 : _cardVerticalMargin,
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
      // Working shifts are dominant Cards; OFF days render as a slim,
      // low-contrast row so the working blocks read as the primary shapes.
      // (Paused working shifts stay dimmed + struck-through with a badge.)
      child: isOff
          ? _buildOffRow(context, theme)
          : Opacity(
        opacity: paused ? 0.6 : 1.0,
        child: Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(
            horizontal: _cardHorizontalMargin,
            vertical: _cardVerticalMargin,
          ),
          child: InkWell(
            // Tap-to-edit — opens the SAME editor the calendar uses, so a shift
            // can be paused or modified straight from the list.
            onTap: () => showShiftEditorModal(
              context,
              initialDate: shift.date,
              existing: shift,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      (paused ? Colors.grey : visual.color).withValues(alpha: 0.18),
                  foregroundColor: paused ? Colors.grey : visual.color,
                  child: Icon(paused ? Icons.pause : visual.icon),
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
                          decoration:
                              paused ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${shiftTypeLabel(shift.type)} · '
                        '${_timeRange(shift, AppPreferences.use24HourOf(context))}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                          decoration:
                              paused ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (paused) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.do_not_disturb_on_outlined,
                                size: 14, color: muted),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                shift.pauseReason == null
                                    ? 'Paused'
                                    : 'Paused · ${shift.pauseReason}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: muted,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  /// Slim, low-contrast OFF-day row — a hollow dot + date + a faint "Off"
  /// label, no card chrome, so working shifts read as the dominant shapes.
  /// Still tap-to-edit (and swipe-to-delete via the shared Dismissible).
  Widget _buildOffRow(BuildContext context, ThemeData theme) {
    final faint = theme.colorScheme.onSurfaceVariant;
    // "Rest day" (not "Off") — friendlier for tired eyes, and avoids colliding
    // with the "Off" filter chip.
    final trailing = (shift.isPaused && shift.pauseReason != null)
        ? 'Rest day · ${shift.pauseReason}'
        : 'Rest day';
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => showShiftEditorModal(
          context,
          initialDate: shift.date,
          existing: shift,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              // Hollow low-contrast dot — deliberately not a filled glyph.
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: faint.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  formatShiftDate(shift.date),
                  style: theme.textTheme.bodyMedium?.copyWith(color: faint),
                ),
              ),
              Text(
                trailing,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: faint.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _timeRange(Shift shift, bool use24Hour) {
  if (shift.type == ShiftType.off) return 'All day';
  return '${formatClock(shift.startMinutes, use24Hour: use24Hour)} – '
      '${formatClock(shift.endMinutes, use24Hour: use24Hour)}';
}
