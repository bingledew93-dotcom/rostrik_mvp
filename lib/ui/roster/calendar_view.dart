import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/models/shift.dart';
import '../shift_editor_modal.dart';
import '../shift_format.dart';
import 'shift_visuals.dart';
import 'timeline_view.dart';

/// Monthly calendar view of the (already-filtered) roster. Pure read-layer:
/// every cell is a function of the shifts the orchestrator handed us, no
/// alarm logic and no direct repository access. Mutations only happen via
/// the existing modals (editor, ShiftCard's mute slider in the bottom
/// sheet) — the calendar itself never writes.
///
/// Visual departure from `table_calendar`'s defaults: NO marker dots.
/// Every relevant builder (default/today/outside/selected) is overridden
/// to render an Android-widget-style horizontal bar at the bottom of the
/// cell with the shift type's tint and a short label.
class CalendarView extends StatefulWidget {
  const CalendarView({super.key, required this.shifts});

  final List<Shift> shifts;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

/// Cosmetic states the cell builder distinguishes. We don't expose this
/// outside the file — every public cell variant resolves to one of these.
enum _CellState { normal, today, outside, selected }

class _CalendarViewState extends State<CalendarView> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  /// Day-keyed index built lazily on the first build that sees a new
  /// `widget.shifts` reference. We pin `_lastInput` and use `identical`
  /// rather than equality so the work is O(n) on real changes and free
  /// (one identity check) on rebuilds caused by sibling state.
  Map<DateTime, List<Shift>> _byDate = const {};
  List<Shift>? _lastInput;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  /// Group shifts by their (already-normalised-to-midnight) `date`. Sorts
  /// each day's bucket by start time so the visual bar order is stable —
  /// otherwise a day with a Day + Night split shift would flip order on
  /// every rebuild depending on Hive's iteration order.
  void _ensureIndex(List<Shift> shifts) {
    if (identical(shifts, _lastInput)) return;
    _lastInput = shifts;
    final map = <DateTime, List<Shift>>{};
    for (final s in shifts) {
      (map[s.date] ??= []).add(s);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    }
    _byDate = map;
  }

  List<Shift> _eventsFor(DateTime day) {
    // table_calendar can hand us a DateTime with non-zero time
    // components when the user taps a "today" cell from a focused-day
    // computation. Normalise before lookup so we hit the same key the
    // index used.
    final key = DateTime(day.year, day.month, day.day);
    return _byDate[key] ?? const [];
  }

  Future<void> _onDaySelected(
    DateTime selectedDay,
    DateTime focusedDay,
  ) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    final shifts = _eventsFor(selectedDay);
    if (shifts.isEmpty) {
      // Empty cell: route into the existing add-shift flow with the
      // tapped date pre-filled so the user doesn't have to re-pick it.
      await showShiftEditorModal(context, initialDate: selectedDay);
    } else {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _DayShiftSheet(
          date: selectedDay,
          shifts: shifts,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureIndex(widget.shifts);

    return TableCalendar<Shift>(
      focusedDay: _focusedDay,
      // Wide enough to cover any realistic roster horizon. The orchestrator
      // already caps the read window so the index stays small.
      firstDay: DateTime(2020),
      lastDay: DateTime(2099, 12, 31),
      calendarFormat: CalendarFormat.month,
      availableGestures: AvailableGestures.horizontalSwipe,
      eventLoader: _eventsFor,
      selectedDayPredicate: (d) =>
          _selectedDay != null && isSameDay(_selectedDay, d),
      onDaySelected: _onDaySelected,
      onPageChanged: (d) => _focusedDay = d,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      // Hand each cell variant the same builder; the variant just picks
      // which cosmetic state to render.
      calendarBuilders: CalendarBuilders<Shift>(
        defaultBuilder: (ctx, day, _) => _CalendarCell(
          day: day,
          shifts: _eventsFor(day),
          state: _CellState.normal,
        ),
        todayBuilder: (ctx, day, _) => _CalendarCell(
          day: day,
          shifts: _eventsFor(day),
          state: _CellState.today,
        ),
        outsideBuilder: (ctx, day, _) => _CalendarCell(
          day: day,
          shifts: _eventsFor(day),
          state: _CellState.outside,
        ),
        selectedBuilder: (ctx, day, _) => _CalendarCell(
          day: day,
          shifts: _eventsFor(day),
          state: _CellState.selected,
        ),
      ),
    );
  }
}

/// One date cell. Stack: day number top-left, up to two horizontal bars
/// at the bottom. The cell decoration changes with [state] so the
/// today/selected cells are visually distinct without overriding the
/// bars themselves (consistency: a Day shift is the same colour
/// regardless of whether the cell is "today" or "selected").
class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.shifts,
    required this.state,
  });

  final DateTime day;
  final List<Shift> shifts;
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

    BoxDecoration? cellDecoration;
    if (state == _CellState.selected) {
      cellDecoration = BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      );
    } else if (state == _CellState.today) {
      cellDecoration = BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.55),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      );
    }

    return Container(
      key: ValueKey(
        'calendar-cell-${day.year}-${day.month}-${day.day}',
      ),
      margin: const EdgeInsets.all(2),
      decoration: cellDecoration,
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 6,
            child: Text('${day.day}', style: dayNumberStyle),
          ),
          if (shifts.isNotEmpty)
            Positioned(
              left: 2,
              right: 2,
              bottom: 2,
              child: _ShiftBars(
                shifts: shifts,
                dimmed: state == _CellState.outside,
              ),
            ),
        ],
      ),
    );
  }
}

/// Stacks up to two bars vertically; if the day has 3+ shifts, the second
/// slot becomes a "+N" indicator so the cell never overflows.
class _ShiftBars extends StatelessWidget {
  const _ShiftBars({required this.shifts, required this.dimmed});

  final List<Shift> shifts;

  /// Outside-month cells get an extra opacity so the user's eye is drawn
  /// to the focused month's bars first.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (shifts.length <= 2) {
      for (var i = 0; i < shifts.length; i++) {
        if (i > 0) children.add(const SizedBox(height: 2));
        children.add(_ShiftBar(shift: shifts[i]));
      }
    } else {
      children.add(_ShiftBar(shift: shifts.first));
      children.add(const SizedBox(height: 2));
      children.add(_MoreBar(extra: shifts.length - 1));
    }

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
    return dimmed ? Opacity(opacity: 0.45, child: column) : column;
  }
}

class _ShiftBar extends StatelessWidget {
  const _ShiftBar({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = visualFor(shift.type);
    final bar = Container(
      key: ValueKey('shift-bar-${shift.id}'),
      height: 14,
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        shiftTypeShortLabel(shift.type),
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 10,
          height: 1,
        ),
      ),
    );
    // Mirrors the timeline's muted treatment so the user's mute decision
    // is visible in both views — single visual rule across the app.
    return shift.isMuted ? Opacity(opacity: 0.55, child: bar) : bar;
  }
}

class _MoreBar extends StatelessWidget {
  const _MoreBar({required this.extra});

  final int extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$extra',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 10,
          height: 1,
        ),
      ),
    );
  }
}

/// Bottom sheet listing the shifts on a tapped day. Reuses the same
/// `ShiftCard` the timeline uses, so mute / swipe-delete / alarm display
/// behave identically across views.
class _DayShiftSheet extends StatelessWidget {
  const _DayShiftSheet({required this.date, required this.shifts});

  final DateTime date;
  final List<Shift> shifts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                formatShiftDate(date),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Sheet height bounded by content; if a day ever holds more
            // shifts than fit, the column scrolls inside its
            // ConstrainedBox without resizing the sheet.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: shifts.length,
                itemBuilder: (_, i) => ShiftCard(
                  key: ValueKey('sheet-shift-card-${shifts[i].id}'),
                  shift: shifts[i],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
