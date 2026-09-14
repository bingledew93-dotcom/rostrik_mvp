import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/models/shift.dart';
import '../../data/models/shift_type.dart';
import '../../data/repositories/shift_repository.dart';
import '../../l10n/l10n.dart';
import '../../logic/leave_marking.dart';
import '../../state/app_preferences.dart';

/// Paint-style leave marker (feature #1). Instead of opening each shift and
/// pausing it one at a time, the user taps the days they're off on a calendar
/// (multi-select), picks a reason, and Applies — every working shift on those
/// days is paused in one go, reusing the existing pause/leave mechanic
/// (`Shift.isPaused` + `pauseReason`).
///
/// Deliberately additive: it NEVER deletes a shift and only pauses working
/// shifts (Off/rest days carry no alarm). The alarm engine already skips paused
/// shifts, so the alarms for those days simply won't fire while the record stays
/// on the calendar.
class MarkLeaveScreen extends StatefulWidget {
  const MarkLeaveScreen({super.key});

  @override
  State<MarkLeaveScreen> createState() => _MarkLeaveScreenState();
}

class _MarkLeaveScreenState extends State<MarkLeaveScreen> {
  // currentL10n (not context.l10n): the first preset seeds the controller in
  // initState, where inherited-widget lookups are off-limits.
  static List<String> get _reasonPresets => [
        currentL10n.leaveAnnual,
        currentL10n.leaveSick,
        currentL10n.leavePublicHoliday,
      ];

  final Set<DateTime> _selectedDays = <DateTime>{};
  late final TextEditingController _reasonController;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: _reasonPresets.first)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  DateTime _normalise(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSelected(DateTime day) =>
      _selectedDays.contains(_normalise(day));

  void _onDayTapped(DateTime selectedDay, DateTime focusedDay) {
    final key = _normalise(selectedDay);
    setState(() {
      if (_selectedDays.contains(key)) {
        _selectedDays.remove(key);
      } else {
        _selectedDays.add(key);
      }
      _focusedDay = focusedDay;
    });
  }

  Future<void> _apply(List<Shift> targets) async {
    final repo = context.read<ShiftRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final reason = _reasonController.text.trim();
    for (final s in targets) {
      await repo.upsert(
        s.copyWith(
          isPaused: true,
          pauseReason: reason.isEmpty ? null : reason,
          clearPauseReason: reason.isEmpty,
        ),
      );
    }
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          currentL10n.markLeaveMarked(
            targets.length,
            reason.isEmpty ? currentL10n.markLeaveFallbackReason : reason,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allShifts = context.watch<List<Shift>>();
    // Which days have a WORKING shift → a marker dot so the user can see which
    // days actually carry a shift to pause.
    final workingDays = <DateTime>{
      for (final s in allShifts)
        if (s.type != ShiftType.off) _normalise(s.date),
    };
    final targets = leaveTargets(allShifts, _selectedDays);
    final startWeekOnMonday = AppPreferences.startWeekOnMondayOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.markLeaveTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                context.l10n.markLeaveIntro,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TableCalendar<void>(
              locale: Localizations.localeOf(context).toString(),
              focusedDay: _focusedDay,
              firstDay: DateTime(DateTime.now().year - 1),
              lastDay: DateTime(DateTime.now().year + 1, 12, 31),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: startWeekOnMonday
                  ? StartingDayOfWeek.monday
                  : StartingDayOfWeek.sunday,
              availableGestures: AvailableGestures.horizontalSwipe,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              // Multi-select: any day in the set reads as selected; a tap toggles.
              selectedDayPredicate: _isSelected,
              onDaySelected: _onDayTapped,
              onPageChanged: (d) => _focusedDay = d,
              eventLoader: (d) =>
                  workingDays.contains(_normalise(d)) ? const [null] : const [],
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: theme.colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.l10n.markLeaveReason,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final preset in _reasonPresets)
                          ChoiceChip(
                            key: ValueKey('mark-leave-reason-$preset'),
                            label: Text(preset),
                            selected:
                                _reasonController.text.trim() == preset,
                            onSelected: (_) =>
                                _reasonController.text = preset,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const ValueKey('mark-leave-reason-field'),
                      controller: _reasonController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: context.l10n.markLeaveReason,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    key: const ValueKey('mark-leave-apply'),
                    onPressed: targets.isEmpty ? null : () => _apply(targets),
                    child: Text(
                      targets.isEmpty
                          ? (_selectedDays.isEmpty
                              ? context.l10n.markLeaveSelectDays
                              : context.l10n.markLeaveNoShifts)
                          : context.l10n.markLeaveApplyTo(targets.length),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
