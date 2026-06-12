import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/shift.dart';
import '../../state/app_preferences.dart';
import '../app_theme.dart';
import '../calendar/shift_calendar.dart';
import '../roster/shift_filter.dart';
import '../roster/timeline_view.dart';
import '../settings_screen.dart';
import '../shift_editor_modal.dart';

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
  _TimelineView _view = _TimelineView.list;
  ShiftFilter _filter = ShiftFilter.all;

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
/// Tapping any day opens the shared Add/Edit editor: a day that already has a
/// shift edits it; a blank day adds a new ad-hoc shift pre-filled to that date.
class _TimelineMonthBody extends StatelessWidget {
  const _TimelineMonthBody();

  @override
  Widget build(BuildContext context) {
    final shifts = context.watch<List<Shift>>();
    return ShiftCalendarView(
      shifts: shifts,
      startWeekOnMonday: AppPreferences.startWeekOnMondayOf(context),
      onDayTapped: (date, shiftsOnDate) =>
          _onDayTapped(context, date, shiftsOnDate),
    );
  }

  /// Existing shift on the tapped date → edit it (earliest first if the day has
  /// several); blank date → add a new ad-hoc shift for that date. Uses the same
  /// [showShiftEditorModal] the Manage tab uses, so both tabs share one editor
  /// and one Hive write path.
  void _onDayTapped(
    BuildContext context,
    DateTime date,
    List<Shift> shiftsOnDate,
  ) {
    showShiftEditorModal(
      context,
      initialDate: date,
      existing: shiftsOnDate.isEmpty ? null : shiftsOnDate.first,
    );
  }
}
