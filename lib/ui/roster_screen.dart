import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/shift.dart';
import 'pattern_picker_screen.dart';
import 'roster/shift_filter.dart';
import 'roster/timeline_view.dart';
import 'settings_screen.dart';
import 'shift_editor_modal.dart';
import 'template_screen.dart';

/// Roster tab — chronological timeline of materialised shifts plus
/// the filter chips and add-shift FAB. Pure read-from-Hive surface:
/// shows what's actually scheduled, not the resolver projection (that
/// lives on the Calendar tab).
///
/// State is screen-local (not provided): the filter is scratch state
/// that should reset when the screen is rebuilt from scratch (e.g.
/// after the wake-up flow returns here). Reads via
/// `context.watch<List<Shift>>`; writes flow through
/// `context.read<ShiftRepository>()` deeper in the timeline. No alarm
/// logic touched at this level.
///
/// Pre-Calendar-promotion this screen also hosted a Calendar / Timeline
/// view toggle and embedded `CalendarView`. The Calendar moved to its
/// own top-level tab ([CalendarScreen]) and the embedded sub-view was
/// deleted, so the toggle and IndexedStack went with it.
class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  ShiftFilter _filter = ShiftFilter.all;

  @override
  Widget build(BuildContext context) {
    final allShifts = context.watch<List<Shift>>();
    // Apply filter once. ShiftFilter.all returns the input unchanged,
    // so the no-filter case is allocation-free.
    final filtered = _filter.apply(allShifts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_repeat_outlined),
            tooltip: 'Choose a pattern',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PatternPickerScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Generate roster block',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TemplateScreen()),
            ),
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
          ShiftFilterChips(
            value: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: TimelineView(shifts: filtered, filter: _filter),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // MainLayout uses IndexedStack, which keeps every tab's FAB
        // alive simultaneously. Sharing the default Hero tag across
        // tabs trips "multiple heroes share the same tag" during the
        // pushAndRemoveUntil transition to WakeUpScreen. WakeUpScreen
        // has no FAB, so disabling the hero animation is invisible.
        heroTag: null,
        onPressed: () => showShiftEditorModal(context),
        tooltip: 'Add shift',
        child: const Icon(Icons.add),
      ),
    );
  }
}
