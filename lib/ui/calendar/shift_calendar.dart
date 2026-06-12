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
    this.onDayTapped,
    this.startWeekOnMonday = true,
  });

  /// The Hive shift list (same instance the List view watches). The index is
  /// rebuilt only when this changes identity (each stream emission is a new
  /// list), so calendar-swipe rebuilds stay O(1) per cell.
  final List<Shift> shifts;

  /// Tapped a cell → (normalised date, shifts on that date, earliest-first).
  /// Null makes the calendar read-only (e.g. the Dashboard's glance preview).
  final void Function(DateTime date, List<Shift> shiftsOnDate)? onDayTapped;

  /// First grid column: Monday when true, Sunday when false. `table_calendar`
  /// owns the weekday-header / leading-offset math off this flag.
  final bool startWeekOnMonday;

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
      rowHeight: 60,
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
        defaultBuilder: (ctx, day, _) =>
            _CalendarCell(day: day, shifts: _shiftsOn(day), state: _CellState.normal),
        todayBuilder: (ctx, day, _) =>
            _CalendarCell(day: day, shifts: _shiftsOn(day), state: _CellState.today),
        outsideBuilder: (ctx, day, _) =>
            _CalendarCell(day: day, shifts: _shiftsOn(day), state: _CellState.outside),
        selectedBuilder: (ctx, day, _) =>
            _CalendarCell(day: day, shifts: _shiftsOn(day), state: _CellState.selected),
      ),
    );
  }
}

enum _CellState { normal, today, outside, selected }

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.shifts,
    required this.state,
  });

  final DateTime day;
  final List<Shift> shifts;
  final _CellState state;

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

    final dayNumberStyle = theme.textTheme.bodyMedium?.copyWith(
      color: dayNumberColor,
      fontWeight: state == _CellState.today ? FontWeight.w800 : FontWeight.w500,
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
      key: ValueKey('shift-calendar-cell-${day.year}-${day.month}-${day.day}'),
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
          // Strictly data-driven: bars only when Hive has shift(s) for this day.
          if (shifts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final s in shifts.take(_maxBars))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _TypeBar(
                        type: s.type,
                        dimmed: state == _CellState.outside,
                        paused: s.isPaused,
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
  });

  final ShiftType type;
  final bool dimmed;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final visual = visualFor(type);
    // Paused day → muted grey, low-opacity bar so it reads as "not working"
    // at a glance while still marking that something is on the calendar.
    final color = paused ? Colors.grey : visual.color;
    final bar = Container(
      height: 5,
      decoration: BoxDecoration(
        color: color.withValues(alpha: paused ? 0.4 : 0.9),
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return dimmed ? Opacity(opacity: 0.45, child: bar) : bar;
  }
}
