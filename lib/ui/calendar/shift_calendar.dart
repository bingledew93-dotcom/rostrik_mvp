import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/models/shift.dart';
import '../../data/models/shift_type.dart';
import '../roster/shift_visuals.dart';

/// Data-driven month grid, bound to the **same** Hive `Shift` list the List
/// view renders — the single source of truth. Every cell's bar(s) come strictly
/// from instantiated [Shift] records (indexed by calendar day); a date with no
/// Shift renders completely blank. There is NO pattern projection here: a
/// 1-week roster shows for exactly the days it was materialised, manual edits
/// and deletions are reflected the instant the shift stream re-emits, and the
/// repeat-forever bug of the old resolver-driven calendar is gone.
///
/// [onDayTapped] fires for any cell with the tapped date and the shifts on it
/// (empty for a blank day) — the Timeline opens the shared Add/Edit editor off
/// that: edit an existing shift, or add a new one for a blank date.
class ShiftCalendarView extends StatefulWidget {
  const ShiftCalendarView({
    super.key,
    required this.shifts,
    this.activityDays = const {},
    this.onDayTapped,
    this.startWeekOnMonday = true,
    this.compact = false,
  });

  /// The Hive shift list (same instance the List view watches). The index is
  /// rebuilt only when this changes identity (each stream emission is a new
  /// list), so calendar-swipe rebuilds stay O(1) per cell.
  final List<Shift> shifts;

  /// Midnight-normalised days that carry at least one non-shift activity
  /// (event / task / birthday). Days in this set get a small marker dot so the
  /// calendar reads as a normal calendar too. Kept as a plain day-set so the
  /// calendar stays decoupled from the `CalendarActivity` model.
  final Set<DateTime> activityDays;

  /// Tapped a cell → (normalised date, shifts on that date, earliest-first).
  /// Null makes the calendar read-only (e.g. the Dashboard's glance preview).
  final void Function(DateTime date, List<Shift> shiftsOnDate)? onDayTapped;

  /// First grid column: Monday when true, Sunday when false. `table_calendar`
  /// owns the weekday-header / leading-offset math off this flag.
  final bool startWeekOnMonday;

  /// Compact density for the Dashboard's read-only mini-calendar tile: a
  /// shorter row height with proportionally tighter cell padding, smaller day
  /// numbers and thinner bars, so the grid stays crisp when scaled down.
  final bool compact;

  @override
  State<ShiftCalendarView> createState() => _ShiftCalendarViewState();
}

class _ShiftCalendarViewState extends State<ShiftCalendarView> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late Map<DateTime, List<Shift>> _index;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _index = _buildIndex(widget.shifts);
  }

  @override
  void didUpdateWidget(covariant ShiftCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild the index only on a real data change. The shift stream emits a
    // fresh list instance on every Hive event; calendar-swipe setState reuses
    // the same instance, so identity-compare avoids needless reindexing.
    if (!identical(oldWidget.shifts, widget.shifts)) {
      _index = _buildIndex(widget.shifts);
    }
  }

  /// Groups shifts by midnight-normalised calendar day; each day's list is
  /// sorted earliest-start-first so the cell bars and the tap target are stable.
  static Map<DateTime, List<Shift>> _buildIndex(List<Shift> shifts) {
    final map = <DateTime, List<Shift>>{};
    for (final s in shifts) {
      final key = DateTime(s.date.year, s.date.month, s.date.day);
      (map[key] ??= <Shift>[]).add(s);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    }
    return map;
  }

  List<Shift> _shiftsOn(DateTime day) =>
      _index[DateTime(day.year, day.month, day.day)] ?? const <Shift>[];

  bool _hasActivityOn(DateTime day) =>
      widget.activityDays.contains(DateTime(day.year, day.month, day.day));

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    widget.onDayTapped?.call(
      DateTime(selectedDay.year, selectedDay.month, selectedDay.day),
      _shiftsOn(selectedDay),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wide bounds — table_calendar requires firstDay <= focusedDay <= lastDay.
    // 1900..2100 covers any reachable month; out-of-data months simply render
    // blank (no shifts), which is the correct "no record → empty cell" state.
    return TableCalendar<Shift>(
      focusedDay: _focusedDay,
      firstDay: DateTime(1900),
      lastDay: DateTime(2100, 12, 31),
      calendarFormat: CalendarFormat.month,
      rowHeight: widget.compact ? 46 : 60,
      daysOfWeekHeight: widget.compact ? 18 : 16,
      startingDayOfWeek: widget.startWeekOnMonday
          ? StartingDayOfWeek.monday
          : StartingDayOfWeek.sunday,
      availableGestures: AvailableGestures.horizontalSwipe,
      // Markers are drawn as bars inside the cell builders; the event loader is
      // unused (returning empty also suppresses table_calendar's default dots).
      eventLoader: (_) => const [],
      selectedDayPredicate: (d) =>
          _selectedDay != null && isSameDay(_selectedDay, d),
      onDaySelected: _onDaySelected,
      onPageChanged: (d) => setState(() => _focusedDay = d),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarBuilders: CalendarBuilders<Shift>(
        // An empty SizedBox is the documented way to suppress the default dot
        // marker (a null builder falls back to the dot).
        markerBuilder: (_, _, _) => const SizedBox.shrink(),
        defaultBuilder: (ctx, day, _) => _CalendarCell(
            day: day,
            shifts: _shiftsOn(day),
            hasActivity: _hasActivityOn(day),
            state: _CellState.normal,
            compact: widget.compact),
        todayBuilder: (ctx, day, _) => _CalendarCell(
            day: day,
            shifts: _shiftsOn(day),
            hasActivity: _hasActivityOn(day),
            state: _CellState.today,
            compact: widget.compact),
        outsideBuilder: (ctx, day, _) => _CalendarCell(
            day: day,
            shifts: _shiftsOn(day),
            hasActivity: _hasActivityOn(day),
            state: _CellState.outside,
            compact: widget.compact),
        selectedBuilder: (ctx, day, _) => _CalendarCell(
            day: day,
            shifts: _shiftsOn(day),
            hasActivity: _hasActivityOn(day),
            state: _CellState.selected,
            compact: widget.compact),
      ),
    );
  }
}

enum _CellState { normal, today, outside, selected }

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.shifts,
    required this.hasActivity,
    required this.state,
    required this.compact,
  });

  final DateTime day;
  final List<Shift> shifts;
  final bool hasActivity;
  final _CellState state;
  final bool compact;

  /// Cap the stacked bars so a freak multi-shift day can't overflow the cell.
  static const _maxBars = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dayNumberColor = switch (state) {
      _CellState.outside =>
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      _CellState.today => theme.colorScheme.primary,
      _ => theme.colorScheme.onSurface,
    };

    // Proportional metrics — the compact (Dashboard tile) variant tightens
    // every dimension together so the grid stays crisp when scaled down.
    final dayNumberStyle =
        (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
            ?.copyWith(
      color: dayNumberColor,
      fontWeight: state == _CellState.today ? FontWeight.w800 : FontWeight.w500,
    );
    final cellMargin = EdgeInsets.all(compact ? 1.5 : 2);
    final numberPad = compact
        ? const EdgeInsets.fromLTRB(4, 1, 4, 0)
        : const EdgeInsets.fromLTRB(6, 2, 6, 0);
    final barsPad = compact
        ? const EdgeInsets.fromLTRB(2, 0, 2, 2)
        : const EdgeInsets.fromLTRB(2, 0, 2, 4);
    final barHeight = compact ? 4.0 : 5.0;
    final barGap = compact ? 1.5 : 2.0;
    final cellRadius = compact ? 6.0 : 8.0;

    final cellDecoration = switch (state) {
      _CellState.selected => BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(cellRadius),
        ),
      _CellState.today => BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.55),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(cellRadius),
        ),
      _ => null,
    };

    return Container(
      key: ValueKey('shift-calendar-cell-${day.year}-${day.month}-${day.day}'),
      margin: cellMargin,
      decoration: cellDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: numberPad,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('${day.day}', style: dayNumberStyle),
                // Activity marker: a small dot when the day carries an event /
                // task / birthday, so the calendar reads as a normal calendar.
                if (hasActivity)
                  Container(
                    key: ValueKey(
                      'activity-marker-${day.year}-${day.month}-${day.day}',
                    ),
                    width: compact ? 5 : 6,
                    height: compact ? 5 : 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary.withValues(
                        alpha: state == _CellState.outside ? 0.4 : 0.95,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          // Strictly data-driven: bars only when Hive has shift(s) for this day.
          if (shifts.isNotEmpty)
            Padding(
              padding: barsPad,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final s in shifts.take(_maxBars))
                    Padding(
                      padding: EdgeInsets.only(top: barGap),
                      child: _TypeBar(
                        type: s.type,
                        dimmed: state == _CellState.outside,
                        paused: s.isPaused,
                        isAdHoc: s.isAdHoc,
                        height: barHeight,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Solid horizontal bar showing a shift's type via the shared
/// `visualFor(ShiftType)` palette — the same colours the List cards use.
class _TypeBar extends StatelessWidget {
  const _TypeBar({
    required this.type,
    required this.dimmed,
    required this.paused,
    required this.isAdHoc,
    required this.height,
  });

  final ShiftType type;
  final bool dimmed;
  final bool paused;
  final bool isAdHoc;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visual = visualFor(type);
    // Paused day → muted grey, low-opacity bar so it reads as "not working"
    // at a glance while still marking that something is on the calendar.
    final color = paused ? Colors.grey : visual.color;
    // Ad-hoc (overtime) shifts get an accent outline so picked-up overtime
    // pops against the rostered bars — matches the legend's "Ad-Hoc" chip.
    final border = (isAdHoc && !paused)
        ? Border.all(color: scheme.primary, width: 1)
        : null;
    final bar = Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: paused ? 0.4 : 0.9),
        borderRadius: BorderRadius.circular(3),
        border: border,
      ),
    );
    return dimmed ? Opacity(opacity: 0.45, child: bar) : bar;
  }
}

/// Horizontal color-key for the calendar bars — decodes the palette for tired
/// eyes. Colocated with [_TypeBar] so the chip colours stay in lock-step with
/// what the grid actually draws. Wraps on narrow widths.
class ShiftCalendarLegend extends StatelessWidget {
  const ShiftCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      key: const ValueKey('calendar-legend'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _LegendChip(
            color: visualFor(ShiftType.day).color,
            label: 'Day',
            labelStyle: labelStyle,
          ),
          _LegendChip(
            color: visualFor(ShiftType.afternoon).color,
            label: 'Afternoon',
            labelStyle: labelStyle,
          ),
          _LegendChip(
            color: visualFor(ShiftType.night).color,
            label: 'Night',
            labelStyle: labelStyle,
          ),
          _LegendChip(
            color: Colors.transparent,
            borderColor: scheme.primary,
            label: 'Ad-Hoc',
            labelStyle: labelStyle,
          ),
          _LegendChip(
            color: Colors.grey.withValues(alpha: 0.4),
            label: 'Paused / Leave',
            labelStyle: labelStyle,
          ),
          _LegendChip(
            color: scheme.tertiary,
            label: 'Activity',
            labelStyle: labelStyle,
            dot: true,
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.labelStyle,
    this.borderColor,
    this.dot = false,
  });

  final Color color;
  final Color? borderColor;
  final String label;
  final TextStyle? labelStyle;

  /// Renders a small circle (the activity marker) instead of the square shift
  /// swatch, so the legend chip matches what the cell actually draws.
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dot ? 8 : 14,
          height: dot ? 8 : 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: color == Colors.transparent ? 0 : 0.9),
            borderRadius: dot ? null : BorderRadius.circular(4),
            shape: dot ? BoxShape.circle : BoxShape.rectangle,
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1.5)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: labelStyle),
      ],
    );
  }
}
