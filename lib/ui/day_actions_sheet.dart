import 'package:flutter/material.dart';

import '../data/models/calendar_activity.dart';
import '../data/models/shift.dart';
import '../data/models/shift_type.dart';
import '../state/app_preferences.dart';
import 'activity_editor_modal.dart';
import 'roster/shift_visuals.dart';
import 'shift_editor_modal.dart';
import 'shift_format.dart';

/// The calendar-day chooser (Phase 3). Tapping a day in the Month view opens
/// this sheet, which lets the day double as a normal calendar: edit/add a SHIFT,
/// or edit/add an ACTIVITY (event / task / birthday). Each row just routes to
/// the relevant editor — the sheet itself performs no writes, so the two data
/// paths (shifts→alarm engine, activities→isolated reminders) stay cleanly
/// separated.
Future<void> showDayActionsSheet(
  BuildContext context, {
  required DateTime date,
  required List<Shift> shiftsOnDate,
  required List<CalendarActivity> activitiesOnDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _DayActionsSheet(
      // Route the follow-on editor off the ORIGINAL context — the sheet's own
      // context is defunct the moment it's popped.
      parentContext: context,
      date: date,
      shiftsOnDate: shiftsOnDate,
      activitiesOnDate: activitiesOnDate,
    ),
  );
}

class _DayActionsSheet extends StatelessWidget {
  const _DayActionsSheet({
    required this.parentContext,
    required this.date,
    required this.shiftsOnDate,
    required this.activitiesOnDate,
  });

  final BuildContext parentContext;
  final DateTime date;
  final List<Shift> shiftsOnDate;
  final List<CalendarActivity> activitiesOnDate;

  void _close() => Navigator.of(parentContext).pop();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final use24Hour = AppPreferences.use24HourOf(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                formatFullDate(date),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),

            _SectionLabel('Shifts'),
            for (var i = 0; i < shiftsOnDate.length; i++)
              _ShiftTile(
                key: ValueKey('day-shift-$i'),
                shift: shiftsOnDate[i],
                use24Hour: use24Hour,
                onTap: () {
                  _close();
                  showShiftEditorModal(
                    parentContext,
                    initialDate: date,
                    existing: shiftsOnDate[i],
                  );
                },
              ),
            ListTile(
              key: const ValueKey('day-add-shift'),
              leading: const Icon(Icons.add),
              title: Text(shiftsOnDate.isEmpty ? 'Add shift' : 'Add another shift'),
              onTap: () {
                _close();
                showShiftEditorModal(parentContext, initialDate: date);
              },
            ),

            const Divider(height: 8),

            _SectionLabel('Activities'),
            for (var i = 0; i < activitiesOnDate.length; i++)
              _ActivityTile(
                key: ValueKey('day-activity-$i'),
                activity: activitiesOnDate[i],
                use24Hour: use24Hour,
                onTap: () {
                  _close();
                  showActivityEditorModal(
                    parentContext,
                    date: date,
                    existing: activitiesOnDate[i],
                  );
                },
              ),
            ListTile(
              key: const ValueKey('day-add-activity'),
              leading: const Icon(Icons.add),
              title: const Text('Add activity'),
              subtitle: const Text('Event, task or birthday'),
              onTap: () {
                _close();
                showActivityEditorModal(parentContext, date: date);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ShiftTile extends StatelessWidget {
  const _ShiftTile({
    super.key,
    required this.shift,
    required this.use24Hour,
    required this.onTap,
  });

  final Shift shift;
  final bool use24Hour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = visualFor(shift.type);
    final isOff = shift.type == ShiftType.off;
    final subtitle = shift.isPaused
        ? 'Paused${shift.pauseReason != null && shift.pauseReason!.isNotEmpty ? ' · ${shift.pauseReason}' : ''}'
        : isOff
            ? 'Off'
            : '${formatClock(shift.startMinutes, use24Hour: use24Hour)}'
                ' – ${formatClock(shift.endMinutes, use24Hour: use24Hour)}';
    return ListTile(
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: shift.isPaused ? Colors.grey : visual.color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text('${shiftTypeLabel(shift.type)} shift'),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    super.key,
    required this.activity,
    required this.use24Hour,
    required this.onTap,
  });

  final CalendarActivity activity;
  final bool use24Hour;
  final VoidCallback onTap;

  IconData get _icon => switch (activity.kind) {
        ActivityKind.event => Icons.event_outlined,
        ActivityKind.task => activity.isDone
            ? Icons.check_circle
            : Icons.radio_button_unchecked,
        ActivityKind.birthday => Icons.cake_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bits = <String>[
      if (!activity.isAllDay)
        formatClock(activity.timeMinutes!, use24Hour: use24Hour),
      if (activity.hasReminder) 'Reminder',
    ];
    final done = activity.kind == ActivityKind.task && activity.isDone;
    return ListTile(
      leading: Icon(_icon),
      title: Text(
        activity.title,
        style: done
            ? theme.textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
      ),
      subtitle: bits.isEmpty
          ? null
          : Text(
              bits.join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
