import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/shift.dart';
import '../../data/models/shift_cycle.dart';
import '../../data/repositories/shift_repository.dart';
import '../../logic/cycle_resolver.dart';
import '../../state/app_preferences.dart';
import '../app_theme.dart';
import '../calendar/infinite_calendar.dart';
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

/// Month View — the migrated Calendar body: the resolver-driven month grid for
/// the active anchored cycle, or a calm empty state when none exists.
class _TimelineMonthBody extends StatelessWidget {
  const _TimelineMonthBody();

  @override
  Widget build(BuildContext context) {
    final cycles = context.watch<List<ShiftCycle>>();
    final active = _pickActiveCycle(cycles);
    if (active == null) return const _EmptyCycleState();
    return InfiniteCalendarView(
      cycle: active,
      startWeekOnMonday: AppPreferences.startWeekOnMondayOf(context),
      onDayTapped: (date, resolution) => _onDayTapped(context, date, resolution),
    );
  }

  /// Most-recently-created anchored cycle — matches the user's "the rotation I
  /// just set up" mental model. Null when no anchored cycle exists.
  static ShiftCycle? _pickActiveCycle(List<ShiftCycle> cycles) {
    final anchored = cycles.where((c) => c.isAnchored).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return anchored.isEmpty ? null : anchored.first;
  }

  Future<void> _onDayTapped(
    BuildContext context,
    DateTime date,
    CycleResolution resolution,
  ) async {
    final repo = context.read<ShiftRepository>();
    final cellMidnight = DateTime(date.year, date.month, date.day);
    final nextMidnight = DateTime(date.year, date.month, date.day + 1);
    final existingShifts = await repo.getInRange(cellMidnight, nextMidnight);
    final materialised = existingShifts.isEmpty ? null : existingShifts.first;

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => CycleResolutionSheet(
        date: date,
        resolution: resolution,
        materialisedActions: materialised == null
            ? null
            : _buildMaterialisedActions(context, materialised),
      ),
    );
  }

  List<Widget> _buildMaterialisedActions(BuildContext context, Shift shift) {
    final theme = Theme.of(context);
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Scheduled — edit from the List view.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _EmptyCycleState extends StatelessWidget {
  const _EmptyCycleState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No active rotation',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a rotation from the Manage tab to see your infinite '
              'calendar projection here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
