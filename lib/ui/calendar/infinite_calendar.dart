import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/models/shift_cycle.dart';
import '../../data/models/shift_type.dart';
import '../../logic/cycle_resolver.dart';
import '../roster/shift_visuals.dart';
import '../shift_format.dart';

/// Resolver-driven month grid. Every cell's color comes from
/// `resolveShiftBlockForDate(target: cellDate, anchor: cycle.anchorDate,
/// blocks: cycle.blocks)` — NOT from the materialised `Shift` records in
/// Hive. That makes the Calendar work for any date the user navigates
/// to: the cycle is conceptually infinite, so any past or future month
/// resolves correctly without depending on the 365-day materialisation
/// window for visual coverage.
///
/// A per-month [_ProjectionCache] guarantees `defaultBuilder` is O(1)
/// during scroll — the 49 cells in the visible 6-week grid are
/// pre-computed once on month change. The math itself is microseconds
/// per call; the cache just protects against table_calendar's habit of
/// invoking `defaultBuilder` on every frame during a swipe.
class InfiniteCalendarView extends StatefulWidget {
  const InfiniteCalendarView({
    super.key,
    required this.cycle,
    this.onDayTapped,
  });

  final ShiftCycle cycle;

  /// Called when the user taps a cell. Receives the date and the
  /// [CycleResolution] for that date (which carries the block, the
  /// day-within-block, etc.). Null lets the cell tap be a no-op.
  final void Function(DateTime date, CycleResolution resolution)? onDayTapped;

  @override
  State<InfiniteCalendarView> createState() => _InfiniteCalendarViewState();
}

class _InfiniteCalendarViewState extends State<InfiniteCalendarView> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final _ProjectionCache _cache = _ProjectionCache();

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  CycleResolution? _resolveFor(DateTime day) =>
      _cache.lookup(cell: day, cycle: widget.cycle);

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    final resolution = _resolveFor(selectedDay);
    if (resolution != null) {
      widget.onDayTapped?.call(selectedDay, resolution);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wide bounds — table_calendar's contract requires firstDay <= focusedDay
    // <= lastDay. 1900..2100 covers every plausible roster anchor for
    // the lifetime of this build (resolver bidirectionally infinite means
    // even a 1925 anchor renders correctly).
    return TableCalendar<CycleResolution>(
      focusedDay: _focusedDay,
      firstDay: DateTime(1900),
      lastDay: DateTime(2100, 12, 31),
      calendarFormat: CalendarFormat.month,
      rowHeight: 60,
      availableGestures: AvailableGestures.horizontalSwipe,
      // eventLoader feeds the marker-builder hook. We suppress markers
      // (custom bar at the cell bottom is the visual signal), so this
      // can return empty without affecting anything.
      eventLoader: (_) => const [],
      selectedDayPredicate: (d) =>
          _selectedDay != null && isSameDay(_selectedDay, d),
      onDaySelected: _onDaySelected,
      onPageChanged: (d) {
        // Nudge the cache to rebuild for the new month BEFORE the next
        // frame paints its cells. setState is required so the new
        // _focusedDay propagates to table_calendar.
        setState(() => _focusedDay = d);
      },
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarBuilders: CalendarBuilders<CycleResolution>(
        // Suppress table_calendar's built-in dot marker — our bar at
        // the cell bottom is the visual signal. Returning a null
        // builder from markerBuilder would NOT suppress; the package
        // falls back to its default dot. Returning an empty SizedBox
        // is the documented suppression idiom.
        markerBuilder: (_, _, _) => const SizedBox.shrink(),
        defaultBuilder: (ctx, day, _) => _CalendarCell(
          day: day,
          resolution: _resolveFor(day),
          state: _CellState.normal,
        ),
        todayBuilder: (ctx, day, _) => _CalendarCell(
          day: day,
          resolution: _resolveFor(day),
          state: _CellState.today,
        ),
        outsideBuilder: (ctx, day, _) => _CalendarCell(
          day: day,
          resolution: _resolveFor(day),
          state: _CellState.outside,
        ),
        selectedBuilder: (ctx, day, _) => _CalendarCell(
          day: day,
          resolution: _resolveFor(day),
          state: _CellState.selected,
        ),
      ),
    );
  }
}

/// Per-month resolution cache. The visible grid is 6 weeks (42 cells)
/// but we pre-compute 49 (one week of padding either side) so cells
/// fed to `outsideBuilder` from adjacent months also hit the cache.
/// Invalidates on month change OR cycle change (identity-compared
/// because `cycles.watch()` emits new list instances on every box
/// event — same cycle object → same identity → no rebuild needed).
class _ProjectionCache {
  DateTime? _cachedMonth;
  ShiftCycle? _cachedCycle;
  final Map<DateTime, CycleResolution> _map = {};

  CycleResolution? lookup({
    required DateTime cell,
    required ShiftCycle cycle,
  }) {
    final monthAnchor = DateTime(cell.year, cell.month, 1);
    if (!identical(_cachedCycle, cycle) || monthAnchor != _cachedMonth) {
      _rebuild(monthAnchor, cycle);
    }
    final key = DateTime(cell.year, cell.month, cell.day);
    return _map[key];
  }

  void _rebuild(DateTime monthAnchor, ShiftCycle cycle) {
    _map.clear();
    _cachedMonth = monthAnchor;
    _cachedCycle = cycle;
    if (!cycle.isAnchored) return;
    // 49-day window: monthAnchor − 7 .. monthAnchor + 42. Covers the
    // full 6-week table_calendar grid plus one week of padding either
    // side so outsideBuilder hits are pre-resolved too.
    final first = DateTime(
      monthAnchor.year,
      monthAnchor.month,
      monthAnchor.day - 7,
    );
    for (var i = 0; i < 49; i++) {
      final d = DateTime(first.year, first.month, first.day + i);
      final r = resolveShiftBlockForDate(
        target: d,
        anchor: cycle.anchorDate!,
        blocks: cycle.blocks!,
      );
      if (r != null) _map[d] = r;
    }
  }
}

/// Cosmetic states the cell builder distinguishes. Mirrors the
/// pattern in the (now-deleted) roster/calendar_view.dart so the
/// visual rhythm stays consistent for users familiar with the prior
/// surface.
enum _CellState { normal, today, outside, selected }

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.resolution,
    required this.state,
  });

  final DateTime day;
  final CycleResolution? resolution;
  final _CellState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dayNumberColor = switch (state) {
      _CellState.outside =>
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      _CellState.today => theme.colorScheme.primary,
      _ => theme.colorScheme.onSurface,
    };

    final dayNumberStyle = theme.textTheme.bodyMedium?.copyWith(
      color: dayNumberColor,
      fontWeight:
          state == _CellState.today ? FontWeight.w800 : FontWeight.w500,
    );

    final cellDecoration = switch (state) {
      _CellState.selected => BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
        ),
      _CellState.today => BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.55),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      _ => null,
    };

    return Container(
      key: ValueKey('infinite-calendar-cell-${day.year}-${day.month}-${day.day}'),
      margin: const EdgeInsets.all(2),
      decoration: cellDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${day.day}', style: dayNumberStyle),
            ),
          ),
          if (resolution != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
              child: _TypeBar(
                type: resolution!.block.type,
                dimmed: state == _CellState.outside,
              ),
            ),
        ],
      ),
    );
  }
}

/// Solid horizontal bar showing the shift type via the shared
/// `visualFor(ShiftType)` palette. The label-less form reads cleanly
/// at calendar density; the bottom sheet on tap surfaces the longer
/// "Day shift · day 3 of 4" copy.
class _TypeBar extends StatelessWidget {
  const _TypeBar({required this.type, required this.dimmed});

  final ShiftType type;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final visual = visualFor(type);
    final bar = Container(
      height: 6,
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return dimmed ? Opacity(opacity: 0.45, child: bar) : bar;
  }
}

/// Bottom sheet shown when the user taps a cell. Header tinted by the
/// resolved shift type; body shows the block-position copy and the
/// configured time window. Callers can stack their own actions (edit /
/// mute) on top of this for materialised days — for projected days
/// (beyond the 365-day upfront materialisation horizon) this read-only
/// summary is the whole sheet.
class CycleResolutionSheet extends StatelessWidget {
  const CycleResolutionSheet({
    super.key,
    required this.date,
    required this.resolution,
    this.materialisedActions,
  });

  final DateTime date;
  final CycleResolution resolution;

  /// Optional list of action widgets rendered below the read-only
  /// summary. Used to inject "Edit shift" / "Mute" for materialised
  /// days. Null or empty → projected day, read-only.
  final List<Widget>? materialisedActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = visualFor(resolution.block.type);
    final typeLabel = _typeLabel(resolution.block.type);
    final block = resolution.block;
    final dayOfBlock = resolution.dayWithinBlock + 1;
    final isProjected =
        materialisedActions == null || materialisedActions!.isEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(visual.icon, color: visual.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$typeLabel shift',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: visual.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isProjected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Projected',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              formatShiftDate(date),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Position in cycle',
              value: 'Day $dayOfBlock of ${block.consecutiveDays} '
                  '($typeLabel block)',
            ),
            if (block.type != ShiftType.off) ...[
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Time',
                value: '${formatHhmm(block.startMinutes)} → '
                    '${formatHhmm(block.endMinutes)}',
              ),
            ],
            if (materialisedActions != null && materialisedActions!.isNotEmpty)
              ...[
              const SizedBox(height: 16),
              ...materialisedActions!,
            ],
          ],
        ),
      ),
    );
  }

  static String _typeLabel(ShiftType type) {
    switch (type) {
      case ShiftType.day:
        return 'Day';
      case ShiftType.afternoon:
        return 'Afternoon';
      case ShiftType.night:
        return 'Night';
      case ShiftType.off:
        return 'Off';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

