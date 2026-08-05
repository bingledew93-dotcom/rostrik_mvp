import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/models/calendar_activity.dart';
import '../data/repositories/calendar_activity_repository.dart';
import '../state/app_preferences.dart';
import 'shift_format.dart';
import 'time_picker_pref.dart';

/// Convenience launcher for the activity editor bottom sheet.
///
/// [date] is the calendar day the activity belongs to (a new activity is
/// pre-filled to it). [existing] switches the sheet to EDIT mode — its fields
/// seed from that activity and Save updates it in place (same id); a Delete
/// button also appears.
Future<void> showActivityEditorModal(
  BuildContext context, {
  required DateTime date,
  CalendarActivity? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ActivityEditorModal(date: date, existing: existing),
  );
}

/// Add/Edit form for a [CalendarActivity] — the non-shift calendar entries
/// (events, tasks, birthdays) introduced in Phase 3. Entirely separate from the
/// shift editor and the alarm engine: Save writes to the
/// [CalendarActivityRepository] only, and an optional reminder rides the
/// isolated `ActivityReminderService` (a lightweight notification), never the
/// shift-alarm path.
///
/// The optional reminder is expressed as a lead time before a TIMED activity
/// ("30 min before") or as a time-of-day for an ALL-DAY one ("remind at 9:00"),
/// and resolved to the absolute `reminderAt` instant the model stores.
class ActivityEditorModal extends StatefulWidget {
  const ActivityEditorModal({super.key, required this.date, this.existing});

  final DateTime date;
  final CalendarActivity? existing;

  @override
  State<ActivityEditorModal> createState() => _ActivityEditorModalState();
}

/// Lead-time options (minutes before the event start) for a TIMED activity's
/// reminder. `0` == "At time of event".
const _leadOptions = <int, String>{
  0: 'At time',
  10: '10 min before',
  30: '30 min before',
  60: '1 hour before',
  1440: '1 day before',
};

class _ActivityEditorModalState extends State<ActivityEditorModal> {
  static const _uuid = Uuid();

  late ActivityKind _kind;
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  /// Minute-of-day for a timed activity, or null for all-day.
  int? _timeMinutes;
  bool _allDay = true;

  bool _remind = false;

  /// Lead minutes before a timed event (key into [_leadOptions]).
  int _leadMinutes = 0;

  /// Reminder time-of-day for an all-day activity (default 9:00 AM).
  TimeOfDay _allDayReminderTime = const TimeOfDay(hour: 9, minute: 0);

  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _kind = existing?.kind ?? ActivityKind.event;
    _titleController = TextEditingController(text: existing?.title ?? '')
      ..addListener(() => setState(() {}));
    _noteController = TextEditingController(text: existing?.note ?? '');
    _isDone = existing?.isDone ?? false;

    if (existing != null) {
      _allDay = existing.timeMinutes == null;
      _timeMinutes = existing.timeMinutes;
      if (existing.reminderAt != null) {
        _remind = true;
        _seedReminderControls(existing);
      }
    } else {
      // A fresh birthday defaults to all-day; event/task default all-day too
      // until the user picks a time.
      _allDay = true;
    }
  }

  /// Recovers the lead-chip / all-day-time controls from a saved absolute
  /// `reminderAt` so re-opening an activity shows the reminder it actually has.
  void _seedReminderControls(CalendarActivity a) {
    final reminderAt = a.reminderAt!;
    if (a.timeMinutes != null) {
      final eventStart = DateTime(
        a.date.year,
        a.date.month,
        a.date.day,
        a.timeMinutes! ~/ 60,
        a.timeMinutes! % 60,
      );
      final lead = eventStart.difference(reminderAt).inMinutes;
      // Snap to the nearest offered lead option; unknown offsets fall back to
      // "At time" so the control is always in a valid state.
      _leadMinutes =
          _leadOptions.keys.contains(lead) ? lead : 0;
    } else {
      _allDayReminderTime =
          TimeOfDay(hour: reminderAt.hour, minute: reminderAt.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  /// The absolute instant the reminder should fire, or null when no reminder is
  /// set. Resolved from the lead chip (timed) or the time-of-day (all-day).
  DateTime? get _resolvedReminderAt {
    if (!_remind) return null;
    final d = widget.date;
    if (!_allDay && _timeMinutes != null) {
      final eventStart =
          DateTime(d.year, d.month, d.day, _timeMinutes! ~/ 60, _timeMinutes! % 60);
      return eventStart.subtract(Duration(minutes: _leadMinutes));
    }
    // All-day (or timed-without-a-time): remind at the chosen time-of-day on the
    // activity's date.
    return DateTime(
      d.year,
      d.month,
      d.day,
      _allDayReminderTime.hour,
      _allDayReminderTime.minute,
    );
  }

  Future<void> _pickTime() async {
    final picked = await pickPreferredTime(
      context,
      initialTime: _timeMinutes == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: _timeMinutes! ~/ 60, minute: _timeMinutes! % 60),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _timeMinutes = picked.hour * 60 + picked.minute;
      _allDay = false;
    });
  }

  Future<void> _pickAllDayReminderTime() async {
    final picked = await pickPreferredTime(
      context,
      initialTime: _allDayReminderTime,
    );
    if (!mounted || picked == null) return;
    setState(() => _allDayReminderTime = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final existing = widget.existing;
    final activity = CalendarActivity(
      id: existing?.id ?? _uuid.v4(),
      date: widget.date,
      title: _titleController.text.trim(),
      kind: _kind,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      timeMinutes: _allDay ? null : _timeMinutes,
      reminderAt: _resolvedReminderAt,
      isDone: _kind == ActivityKind.task ? _isDone : false,
    );
    await context.read<CalendarActivityRepository>().upsert(activity);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    await context.read<CalendarActivityRepository>().delete(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final use24Hour = AppPreferences.use24HourOf(context);
    final isEdit = widget.existing != null;
    final reminderPassed = _remind &&
        (_resolvedReminderAt?.isBefore(DateTime.now()) ?? false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit activity' : 'Add activity',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                formatShiftDate(widget.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Kind selector.
              SegmentedButton<ActivityKind>(
                key: const ValueKey('activity-kind'),
                segments: const [
                  ButtonSegment(
                    value: ActivityKind.event,
                    label: Text('Event'),
                    icon: Icon(Icons.event_outlined),
                  ),
                  ButtonSegment(
                    value: ActivityKind.task,
                    label: Text('Task'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: ActivityKind.birthday,
                    label: Text('Birthday'),
                    icon: Icon(Icons.cake_outlined),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.single),
              ),
              const SizedBox(height: 16),

              TextField(
                key: const ValueKey('activity-title'),
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // All-day / time.
              SwitchListTile(
                key: const ValueKey('activity-all-day'),
                contentPadding: EdgeInsets.zero,
                title: const Text('All day'),
                value: _allDay,
                onChanged: (v) => setState(() {
                  _allDay = v;
                  if (!v && _timeMinutes == null) {
                    _timeMinutes = 9 * 60; // sensible default when timing it
                  }
                }),
              ),
              if (!_allDay)
                _PickerRow(
                  label: 'Time',
                  valueLabel: _timeMinutes == null
                      ? 'Pick time'
                      : formatClock(_timeMinutes!, use24Hour: use24Hour),
                  onPressed: _pickTime,
                  buttonKey: const ValueKey('activity-time'),
                ),

              const Divider(height: 24),

              // Reminder section.
              SwitchListTile(
                key: const ValueKey('activity-remind'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Remind me'),
                subtitle: Text(
                  'A gentle notification — separate from your shift alarms.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _remind,
                onChanged: (v) => setState(() => _remind = v),
              ),
              if (_remind) ...[
                const SizedBox(height: 4),
                if (!_allDay && _timeMinutes != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final entry in _leadOptions.entries)
                        ChoiceChip(
                          key: ValueKey('activity-lead-${entry.key}'),
                          label: Text(entry.value),
                          selected: _leadMinutes == entry.key,
                          onSelected: (_) =>
                              setState(() => _leadMinutes = entry.key),
                        ),
                    ],
                  )
                else
                  _PickerRow(
                    label: 'Remind at',
                    valueLabel:
                        formatClockOfDay(_allDayReminderTime, use24Hour: use24Hour),
                    onPressed: _pickAllDayReminderTime,
                    buttonKey: const ValueKey('activity-remind-at'),
                  ),
                if (reminderPassed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'That time has already passed — this reminder won’t fire.',
                      key: const ValueKey('activity-reminder-passed'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],

              const Divider(height: 24),

              // Optional note.
              TextField(
                key: const ValueKey('activity-note'),
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),

              // Task completion.
              if (_kind == ActivityKind.task)
                CheckboxListTile(
                  key: const ValueKey('activity-done'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Completed'),
                  value: _isDone,
                  onChanged: (v) => setState(() => _isDone = v ?? false),
                ),

              const SizedBox(height: 20),

              Row(
                children: [
                  if (isEdit)
                    TextButton.icon(
                      key: const ValueKey('activity-delete'),
                      onPressed: _delete,
                      icon: Icon(Icons.delete_outline,
                          color: theme.colorScheme.error),
                      label: Text(
                        'Delete',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('activity-save'),
                    onPressed: _canSave ? _save : null,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.valueLabel,
    required this.onPressed,
    this.buttonKey,
  });

  final String label;
  final String valueLabel;
  final VoidCallback onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          FilledButton.tonal(
            key: buttonKey,
            onPressed: onPressed,
            child: Text(valueLabel),
          ),
        ],
      ),
    );
  }
}
