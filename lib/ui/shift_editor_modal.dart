import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/models/shift.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/shift_repository.dart';
import '../state/app_preferences.dart';
import 'shift_format.dart';

/// Convenience launcher — keeps callers free of `showModalBottomSheet` plumbing.
///
/// [initialDate] pre-populates the date field so callers (e.g. the calendar
/// view tapping an empty cell) don't force the user to re-pick a date they
/// just selected.
///
/// [existing] switches the sheet to EDIT mode: its fields are pre-filled from
/// that shift and Save updates it in place (same id) instead of creating a new
/// record. The Timeline calendar passes the tapped day's shift here so a cell
/// tap edits the real Hive shift — the single source of truth shared with the
/// List view.
Future<void> showShiftEditorModal(
  BuildContext context, {
  DateTime? initialDate,
  Shift? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ShiftEditorModal(initialDate: initialDate, existing: existing),
  );
}

/// Add/Edit shift form. In ADD mode (the Phase-3 **ad-hoc shift** entry point,
/// Manage tab → "Add Custom Shift") Save constructs a fresh [Shift] (UUID id,
/// `isAdHoc: true`) and `upsert`s it. In EDIT mode (when [ShiftEditorModal.existing]
/// is passed — e.g. the Timeline calendar tapping a day that already has a
/// shift) the fields seed from that shift and Save `copyWith`s it in place, so
/// the calendar and List view stay bound to the one Hive record.
/// Picked values are held in local state until Save.
///
/// Ad-hoc contract ("shifts are immutable history; alarms are ephemeral"):
///   * The saved shift carries `cycleId == null` — it belongs to no rotation,
///     so a cycle cascade-delete can never remove it — AND `isAdHoc: true`,
///     the explicit flag the self-cleaning archive sweep
///     (`archiveExpiredAdHocShifts`) keys off. Once such a shift's end is >24h
///     past, the sweep ARCHIVES it (`isArchived: true`) — it is never deleted,
///     so it stays in Hive (and on the calendar) for payslip verification.
///   * No alarm code lives here. The Hive write alone is the trigger:
///     `AlarmSyncService` watches the shift stream and its next reconcile
///     schedules any matching follows-rotation alarm inside the 14-day
///     window (the native background re-sync covers shifts further out).
///   * Once the occurrence's fire date passes, the engine purges the trigger
///     bookkeeping from its rolling window — the Shift record itself is
///     never deleted and remains in Hive for the historical calendar view.
///   * BACKFILL is supported (date picker reaches one year back): the
///     calendar is the work record users verify payslips against. A
///     past-dated shift arms nothing — the engine's shift window starts at
///     `now` and every fire time must be in the future — so backfilling can
///     never resurrect a legacy alarm.
///
/// Overnight handling intentionally lives in [Shift] itself
/// (`isOvernight` + `endDateTime`), not here. The UI never adds a day to
/// the picked date — it stores `startMinutes` / `endMinutes` as-is and lets
/// the model resolve the cross-midnight case on read. Doing the +1 day
/// shift here would double-count and the alarm engine would compute a
/// `fireAt` 24h late.
class ShiftEditorModal extends StatefulWidget {
  const ShiftEditorModal({super.key, this.initialDate, this.existing});

  final DateTime? initialDate;

  /// When non-null the sheet is in EDIT mode: fields seed from this shift and
  /// Save updates it in place (preserving id / cycleId / isAdHoc and every
  /// flag). Null → ADD mode (a fresh ad-hoc shift).
  final Shift? existing;

  @override
  State<ShiftEditorModal> createState() => _ShiftEditorModalState();
}

class _ShiftEditorModalState extends State<ShiftEditorModal> {
  static const _uuid = Uuid();

  ShiftType _type = ShiftType.day;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _isPaused = false;
  late final TextEditingController _reasonController;

  /// Quick-pick pause reasons; the user can also type a custom one.
  static const List<String> _pauseReasonPresets = [
    'Sick',
    'Annual Leave',
    'Public Holiday',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _reasonController = TextEditingController(text: existing?.pauseReason ?? '')
      // Rebuild on edits so the preset chips reflect the current text.
      ..addListener(_onReasonChanged);
    if (existing != null) {
      // EDIT mode — seed every field from the tapped shift so Save is an
      // in-place update rather than a new record.
      _type = existing.type;
      _date = existing.date;
      _start = TimeOfDay(
        hour: existing.startMinutes ~/ 60,
        minute: existing.startMinutes % 60,
      );
      _end = TimeOfDay(
        hour: existing.endMinutes ~/ 60,
        minute: existing.endMinutes % 60,
      );
      _isPaused = existing.isPaused;
    } else {
      _date = widget.initialDate;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onReasonChanged() => setState(() {});

  bool get _isOff => _type == ShiftType.off;

  bool get _canSave {
    if (_date == null) return false;
    if (_isOff) return true;
    if (_start == null || _end == null) return false;
    // Reject zero-duration: start == end is meaningless and isOvernight
    // would treat it as a 24h shift (since end <= start is the rule).
    return _start != _end;
  }

  bool get _isOvernight {
    if (_start == null || _end == null) return false;
    final s = _start!.hour * 60 + _start!.minute;
    final e = _end!.hour * 60 + _end!.minute;
    return e <= s;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      // One year BACK: the calendar doubles as the historical work record
      // shift workers verify payslips against, so past ad-hoc shifts must be
      // backfillable. Safe by construction — the alarm engine's window starts
      // at `now` and every fire time must be in the future, so a backfilled
      // shift can never arm a legacy alarm. (This also un-breaks the
      // calendar-cell path, which passes a PAST initialDate that the old
      // `firstDate: today` made showDatePicker assert on.) Calendar-field
      // construction for both bounds, per the project's DST-safe convention.
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: DateTime(today.year + 1, today.month, today.day),
    );
    if (!mounted || picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _start ?? const TimeOfDay(hour: 7, minute: 0),
      // Default to the tap-to-type number pad (no dial dragging).
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (!mounted || picked == null) return;
    setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _end ?? const TimeOfDay(hour: 15, minute: 0),
      // Default to the tap-to-type number pad (no dial dragging).
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (!mounted || picked == null) return;
    setState(() => _end = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final startMinutes = _isOff ? 0 : _start!.hour * 60 + _start!.minute;
    final endMinutes = _isOff ? 0 : _end!.hour * 60 + _end!.minute;
    final reason = _reasonController.text.trim();
    // A reason only sticks while paused AND non-empty; otherwise it's cleared.
    final hasReason = _isPaused && reason.isNotEmpty;
    final existing = widget.existing;
    final shift = existing == null
        ? Shift(
            id: _uuid.v4(),
            date: _date!,
            type: _type,
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            // The explicit ad-hoc stamp — `cycleId: null` (default) still keeps
            // a cycle cascade-delete away, but `isAdHoc: true` is what the
            // self-cleaning archive sweep keys off, so only shifts created HERE
            // are ever archived.
            isAdHoc: true,
          )
        // EDIT: copyWith preserves id, cycleId, isAdHoc and every flag
        // (ack/snooze/mute/skip/archived), so editing a rotation occurrence
        // keeps it rotation and updates in place instead of duplicating.
        : existing.copyWith(
            date: _date!,
            type: _type,
            startMinutes: startMinutes,
            endMinutes: endMinutes,
            isPaused: _isPaused,
            pauseReason: hasReason ? reason : null,
            clearPauseReason: !hasReason,
          );
    // Await the Hive write before popping. Defends against the (rare)
    // hard-kill-within-microseconds case where a fire-and-forget upsert
    // could be lost before the box flushes.
    await context.read<ShiftRepository>().upsert(shift);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Pause/cancel toggle + reason picker, shown only in EDIT mode. Paused means
  /// "not working this day": the alarm is skipped (AlarmSyncService) and the
  /// shift renders muted on the calendar/list, but it is NEVER deleted.
  Widget _buildPauseSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Divider(),
        SwitchListTile(
          key: const ValueKey('shift-editor-pause-toggle'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Pause / cancel this shift'),
          subtitle: Text(
            _isPaused
                ? "Alarm won't fire. Stays on your calendar as a record."
                : 'Mark a day off (sick, leave, holiday) without deleting it.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          value: _isPaused,
          onChanged: (v) => setState(() => _isPaused = v),
        ),
        if (_isPaused) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Reason', style: theme.textTheme.labelLarge),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final preset in _pauseReasonPresets)
                ChoiceChip(
                  label: Text(preset),
                  selected: _reasonController.text.trim() == preset,
                  // Setting the text fires the listener → setState, so the chip
                  // selection and the field stay in sync.
                  onSelected: (_) => _reasonController.text = preset,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('shift-editor-pause-reason'),
            controller: _reasonController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Add shift' : 'Edit shift',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            SegmentedButton<ShiftType>(
              segments: ShiftType.values
                  .map((t) => ButtonSegment(
                        value: t,
                        label: Text(shiftTypeLabel(t)),
                      ))
                  .toList(),
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.single),
            ),
            const SizedBox(height: 12),

            _PickerRow(
              label: 'Date',
              valueLabel: _date == null ? 'Pick date' : formatShiftDate(_date!),
              onPressed: _pickDate,
            ),
            if (!_isOff) ...[
              _PickerRow(
                label: 'Starts',
                valueLabel: _start == null
                    ? 'Pick time'
                    : formatClockOfDay(
                        _start!,
                        use24Hour: AppPreferences.use24HourOf(context),
                      ),
                onPressed: _pickStart,
              ),
              _PickerRow(
                label: 'Ends',
                valueLabel: _end == null
                    ? 'Pick time'
                    : formatClockOfDay(
                        _end!,
                        use24Hour: AppPreferences.use24HourOf(context),
                      ),
                onPressed: _pickEnd,
              ),
              if (_isOvernight)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Ends next day',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],

            // EXCEPTION LAYER — pause/cancel is only meaningful for an existing
            // shift (you can't "cancel" a shift you're creating right now).
            if (widget.existing != null) _buildPauseSection(theme),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _canSave ? _save : null,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
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
  });

  final String label;
  final String valueLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyLarge),
          ),
          FilledButton.tonal(
            onPressed: onPressed,
            child: Text(valueLabel),
          ),
        ],
      ),
    );
  }
}
