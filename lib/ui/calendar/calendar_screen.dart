import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/shift.dart';
import '../../data/models/shift_cycle.dart';
import '../../data/repositories/shift_repository.dart';
import '../../logic/cycle_resolver.dart';
import '../settings_screen.dart';
import 'infinite_calendar.dart';

/// Calendar tab — surfaces the active anchored [ShiftCycle] as a
/// month-grid, paints every cell via the pure-Dart `resolveShiftBlockForDate`,
/// and routes day-taps to a bottom sheet that distinguishes
/// **materialised** shifts (editable, day inside the 365-day upfront
/// materialisation window) from **projected** ones (read-only, future
/// days past the materialisation horizon).
///
/// Source-of-truth: `context.watch<List<ShiftCycle>>()` from
/// AppProviders. We pick the most recently created `isAnchored` cycle
/// as the active one — forward-compatible with multi-cycle UI later
/// (a chip row could let the user switch active cycles without
/// touching this layer).
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cycles = context.watch<List<ShiftCycle>>();
    final active = _pickActiveCycle(cycles);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
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
        child: active == null
            ? const _EmptyCycleState()
            : InfiniteCalendarView(
                cycle: active,
                onDayTapped: (date, resolution) =>
                    _onDayTapped(context, date, resolution),
              ),
      ),
    );
  }

  /// Selects the active anchored cycle. Multi-cycle: pick the
  /// most-recently created one (matches the user's mental model of
  /// "the rotation I just set up"). Single-cycle (MVP onboarding):
  /// just returns that one. Null if no anchored cycles exist (legacy
  /// finite cycles or fresh-install-with-cycles-deleted edge case).
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
    // Look up a materialised Shift for this date (if any). The
    // ShiftRepository read is fast (in-memory Hive box) and synchronous-
    // ish — no point pre-loading. Snapshot the repo handle before any
    // awaits so we don't touch `context` after async gaps.
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
        // Materialised days get edit/mute hooks; projected days
        // get a read-only summary (materialisedActions == null/empty
        // is what the sheet uses to render the "Projected" chip).
        materialisedActions: materialised == null
            ? null
            : _buildMaterialisedActions(context, materialised),
      ),
    );
  }

  /// Action row for the bottom sheet when the tapped cell has a
  /// materialised [Shift]. Kept tiny in MVP — just an info pill that
  /// the day is editable from the Roster tab. The full edit modal
  /// flow already lives in `shift_editor_modal.dart` and is reachable
  /// from the Roster timeline; surfacing it inline here is a future
  /// polish, not a blocker.
  List<Widget> _buildMaterialisedActions(
    BuildContext context,
    Shift shift,
  ) {
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
                'Scheduled — edit from the Roster tab.',
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
              'Set up an anchored rotation to see your infinite '
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
