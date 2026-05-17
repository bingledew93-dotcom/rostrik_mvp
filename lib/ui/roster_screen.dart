import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/shift.dart';
import 'new_roster_sheet.dart';
import 'roster/calendar_view.dart';
import 'roster/shift_filter.dart';
import 'roster/timeline_view.dart';
import 'roster/view_mode.dart';
import 'settings_screen.dart';
import 'shift_editor_modal.dart';

/// Home screen — Calendar Room orchestrator. Owns two pieces of local UI
/// state ([ViewMode], [ShiftFilter]) and routes the filtered shift stream
/// into either the timeline list or the calendar grid. Body content lives
/// in `lib/ui/roster/`; this file is intentionally small.
///
/// State is intentionally screen-local (not provided): toggle and filter
/// are scratch state that should reset when the screen is rebuilt from
/// scratch (e.g. after the wake-up flow returns here).
///
/// Reads via `context.watch<List<Shift>>`; writes flow through
/// `context.read<ShiftRepository>()` deeper in the timeline. No alarm
/// logic touched at this level.
class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  ViewMode _mode = ViewMode.timeline;
  ShiftFilter _filter = ShiftFilter.all;

  @override
  Widget build(BuildContext context) {
    final allShifts = context.watch<List<Shift>>();
    // Apply filter once, here. Both views consume the same filtered list
    // — single source of truth, no per-view re-derivation. ShiftFilter.all
    // returns the input unchanged, so the no-filter case is allocation-free.
    final filtered = _filter.apply(allShifts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'New roster',
            onPressed: () => showNewRosterSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ViewModeToggle(
            value: _mode,
            onChanged: (v) => setState(() => _mode = v),
          ),
          ShiftFilterChips(
            value: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: switch (_mode) {
              ViewMode.timeline =>
                TimelineView(shifts: filtered, filter: _filter),
              ViewMode.calendar => CalendarView(shifts: filtered),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showShiftEditorModal(context),
        tooltip: 'Add shift',
        child: const Icon(Icons.add),
      ),
    );
  }
}
