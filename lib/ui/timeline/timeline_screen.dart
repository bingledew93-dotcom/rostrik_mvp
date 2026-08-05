import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/calendar_activity.dart';
import '../../data/models/shift.dart';
import '../../state/app_preferences.dart';
import '../app_theme.dart';
import '../calendar/shift_calendar.dart';
import '../day_actions_sheet.dart';
import '../roster/shift_filter.dart';
import '../roster/timeline_view.dart';
import '../settings_screen.dart';

/// The unified **viewing** surface (post the "Great Migration"). Merges the old
/// Calendar tab (resolver-driven month grid) and the old Roster tab
/// (chronological shift list) behind a single, locally-managed view toggle —
/// [ List View | Month View ]. Manipulation (generate / add / pause) now lives
/// on the dedicated `ManageScreen`.
///
/// The two bodies sit in an [IndexedStack] so swapping is instant and each
/// view keeps its own state (list scroll position, calendar focused month,
/// filter selection) across switches — the same chassis the nav bar uses.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

enum _TimelineView { list, month }

class _TimelineScreenState extends State<TimelineScreen> {
  // Local, screen-scoped state — the whole point of the toggle is an instant
  // in-place swap, so this never leaves the widget.
  late _TimelineView _view;
  ShiftFilter _filter = ShiftFilter.all;

  @override
  void initState() {
    super.initState();
    // Honour the user's "which view opens first" preference (Settings →
    // Preferences). Read once here; after mount the in-screen toggle owns it.
    _view = AppPreferences.timelineDefaultsToMonthOf(context)
        ? _TimelineView.month
        : _TimelineView.list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _ViewToggle(
                value: _view,
                onChanged: (v) => setState(() => _view = v),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _view.index,
                children: [
                  _TimelineListBody(
                    filter: _filter,
                    onFilterChanged: (f) => setState(() => _filter = f),
                  ),
                  const _TimelineMonthBody(),
                ],
              ),
            ),
          ],
        ),
      ),
      // No FAB: the Timeline is view-only. Adding shifts lives on the Manage
      // tab ("Add Custom Shift"), enforcing the viewing/manipulation split.
    );
  }
}

/// Safety-orange segmented control. The selected segment fills with
/// `kRostrikOrange` on black text, matching the app's "armed" accent.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.value, required this.onChanged});

  final _TimelineView value;
  final ValueChanged<_TimelineView> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_TimelineView>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: _TimelineView.list,
            label: Text('List View'),
            icon: Icon(Icons.view_agenda_outlined),
          ),
          ButtonSegment(
            value: _TimelineView.month,
            label: Text('Month View'),
            icon: Icon(Icons.calendar_month),
          ),
        ],
        selected: <_TimelineView>{value},
        onSelectionChanged: (s) => onChanged(s.first),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? kRostrikOrange
                : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? Colors.black : null,
          ),
        ),
      ),
    );
  }
}

/// List View — the migrated Roster body: filter chips over the chronological
/// shift list. Filter state is owned by the parent so it survives view swaps.
class _TimelineListBody extends StatelessWidget {
  const _TimelineListBody({
    required this.filter,
    required this.onFilterChanged,
  });

  final ShiftFilter filter;
  final ValueChanged<ShiftFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final allShifts = context.watch<List<Shift>>();
    // ShiftFilter.all returns the input unchanged → the no-filter case is
    // allocation-free.
    final filtered = filter.apply(allShifts);
    return Column(
      children: [
        ShiftFilterChips(value: filter, onChanged: onFilterChanged),
        Expanded(
          child: TimelineView(shifts: filtered, filter: filter),
        ),
      ],
    );
  }
}

/// Month View — bound to the SAME `List<Shift>` stream the List view watches,
/// so calendar and list are a single source of truth. Cells render strictly
/// from instantiated Hive shifts (blank where there are none — no pattern
/// projection), so a custom 1-week roster shows for exactly its materialised
/// days and manual edits/deletions reflect the instant the stream re-emits.
///
/// Tapping any day opens the shared day chooser ([showDayActionsSheet]): edit
/// an existing shift, add a shift, or add/edit a calendar activity (event, task,
/// birthday). The calendar now doubles as a normal calendar without touching the
/// alarm logic — activities live in their own box and their optional reminders
/// ride a separate, lightweight channel.
class _TimelineMonthBody extends StatelessWidget {
  const _TimelineMonthBody();

  @override
  Widget build(BuildContext context) {
    final shifts = context.watch<List<Shift>>();
    final activities = context.watch<List<CalendarActivity>>();
    // Which days carry an activity → marker dots. Midnight-normalised keys match
    // the calendar's cell lookup.
    final activityDays = <DateTime>{
      for (final a in activities) DateTime(a.date.year, a.date.month, a.date.day),
    };
    // The calendar takes the available space (scrolling the few px a 6-row
    // month needs on a short screen rather than overflowing the column — the
    // old fixed Column overflowed by 8px on 6-row months); the colour legend
    // stays pinned at the bottom below it.
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: ShiftCalendarView(
              shifts: shifts,
              activityDays: activityDays,
              startWeekOnMonday: AppPreferences.startWeekOnMondayOf(context),
              onDayTapped: (date, shiftsOnDate) =>
                  _onDayTapped(context, date, shiftsOnDate, activities),
            ),
          ),
        ),
        const ShiftCalendarLegend(),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Opens the day chooser for the tapped date, passing the shifts AND the
  /// activities already on that day so each can be edited in place (or a new one
  /// added). One entry point; the sheet routes to the right editor.
  void _onDayTapped(
    BuildContext context,
    DateTime date,
    List<Shift> shiftsOnDate,
    List<CalendarActivity> allActivities,
  ) {
    final key = DateTime(date.year, date.month, date.day);
    final activitiesOnDate = [
      for (final a in allActivities)
        if (a.date == key) a,
    ]..sort((a, b) {
        // All-day first, then by time; stable enough for the chooser list.
        final at = a.timeMinutes ?? -1;
        final bt = b.timeMinutes ?? -1;
        return at.compareTo(bt);
      });
    showDayActionsSheet(
      context,
      date: date,
      shiftsOnDate: shiftsOnDate,
      activitiesOnDate: activitiesOnDate,
    );
  }
}
