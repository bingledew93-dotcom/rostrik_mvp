import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/models/shift.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/shift_repository.dart';
import 'shift_format.dart';

/// Convenience launcher — keeps callers free of `showModalBottomSheet` plumbing.
///
/// [initialDate] pre-populates the date field so callers (e.g. the calendar
/// view tapping an empty cell) don't force the user to re-pick a date they
/// just selected.
Future<void> showShiftEditorModal(
  BuildContext context, {
  DateTime? initialDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ShiftEditorModal(initialDate: initialDate),
  );
}

/// New-shift form. Picked values are held in local state until Save, which
/// constructs a fresh [Shift] (UUID id) and `upsert`s it.
///
/// Overnight handling intentionally lives in [Shift] itself
/// (`isOvernight` + `endDateTime`), not here. The UI never adds a day to
/// the picked date — it stores `startMinutes` / `endMinutes` as-is and lets
/// the model resolve the cross-midnight case on read. Doing the +1 day
/// shift here would double-count and the alarm engine would compute a
/// `fireAt` 24h late.
class ShiftEditorModal extends StatefulWidget {
  const ShiftEditorModal({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<ShiftEditorModal> createState() => _ShiftEditorModalState();
}

class _ShiftEditorModalState extends State<ShiftEditorModal> {
  static const _uuid = Uuid();

  ShiftType _type = ShiftType.day;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

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
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (!mounted || picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _start ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (!mounted || picked == null) return;
    setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _end ?? const TimeOfDay(hour: 15, minute: 0),
    );
    if (!mounted || picked == null) return;
    setState(() => _end = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final startMinutes = _isOff ? 0 : _start!.hour * 60 + _start!.minute;
    final endMinutes = _isOff ? 0 : _end!.hour * 60 + _end!.minute;
    final shift = Shift(
      id: _uuid.v4(),
      date: _date!,
      type: _type,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
    );
    // Await the Hive write before popping. Defends against the (rare)
    // hard-kill-within-microseconds case where a fire-and-forget upsert
    // could be lost before the box flushes.
    await context.read<ShiftRepository>().upsert(shift);
    if (!mounted) return;
    Navigator.of(context).pop();
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
              'Add shift',
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
                valueLabel:
                    _start == null ? 'Pick time' : formatTimeOfDay(_start!),
                onPressed: _pickStart,
              ),
              _PickerRow(
                label: 'Ends',
                valueLabel:
                    _end == null ? 'Pick time' : formatTimeOfDay(_end!),
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
