import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/shift_pattern.dart';
import '../logic/shift_generator.dart';
import 'shift_format.dart';

/// Configures Day 1 and shift times for a selected [ShiftPattern], then
/// generates the full cycle via [ShiftGenerator.generatePattern].
class RosterConfigScreen extends StatefulWidget {
  const RosterConfigScreen({super.key, required this.pattern});

  final ShiftPattern pattern;

  @override
  State<RosterConfigScreen> createState() => _RosterConfigScreenState();
}

class _RosterConfigScreenState extends State<RosterConfigScreen> {
  DateTime? _day1;
  TimeOfDay _dayStart = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _dayEnd = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay _nightStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _nightEnd = const TimeOfDay(hour: 6, minute: 0);
  bool _generating = false;

  bool get _hasDayShifts => widget.pattern.hasDayShifts;
  bool get _hasNightShifts => widget.pattern.hasNightShifts;

  bool get _isDayTimesValid => _dayStart != _dayEnd;
  bool get _isNightTimesValid => _nightStart != _nightEnd;

  bool get _isNightOvernight {
    final s = _nightStart.hour * 60 + _nightStart.minute;
    final e = _nightEnd.hour * 60 + _nightEnd.minute;
    return e <= s;
  }

  bool get _canGenerate {
    if (_generating || _day1 == null) return false;
    if (_hasDayShifts && !_isDayTimesValid) return false;
    if (_hasNightShifts && !_isNightTimesValid) return false;
    return true;
  }

  Future<void> _pickDay1() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _day1 ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (!mounted || picked == null) return;
    setState(() => _day1 = picked);
  }

  Future<void> _pickTime(
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (!mounted || picked == null) return;
    setState(() => onPicked(picked));
  }

  Future<void> _generate() async {
    if (!_canGenerate) return;
    setState(() => _generating = true);

    final generator = context.read<ShiftGenerator>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final shifts = await generator.generatePattern(
        startDate: _day1!,
        pattern: widget.pattern,
        dayStartMinutes: _dayStart.hour * 60 + _dayStart.minute,
        dayEndMinutes: _dayEnd.hour * 60 + _dayEnd.minute,
        nightStartMinutes: _nightStart.hour * 60 + _nightStart.minute,
        nightEndMinutes: _nightEnd.hour * 60 + _nightEnd.minute,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Generated ${shifts.length} shifts')),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pattern = widget.pattern;

    return Scaffold(
      appBar: AppBar(title: Text(pattern.name)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Text(
            pattern.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${pattern.cycleDays}-day cycle',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 28),

          Text('Day 1', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _PickerRow(
            label: 'Start date',
            valueLabel:
                _day1 == null ? 'Pick date' : formatShiftDate(_day1!),
            onPressed: _pickDay1,
          ),

          if (_hasDayShifts) ...[
            const SizedBox(height: 28),
            Text('Day shift', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _PickerRow(
              label: 'Starts',
              valueLabel: formatTimeOfDay(_dayStart),
              onPressed: () =>
                  _pickTime(_dayStart, (t) => _dayStart = t),
            ),
            _PickerRow(
              label: 'Ends',
              valueLabel: formatTimeOfDay(_dayEnd),
              onPressed: () => _pickTime(_dayEnd, (t) => _dayEnd = t),
            ),
            if (!_isDayTimesValid)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Start and end time must differ',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],

          if (_hasNightShifts) ...[
            const SizedBox(height: 28),
            Text('Night shift', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _PickerRow(
              label: 'Starts',
              valueLabel: formatTimeOfDay(_nightStart),
              onPressed: () =>
                  _pickTime(_nightStart, (t) => _nightStart = t),
            ),
            _PickerRow(
              label: 'Ends',
              valueLabel: formatTimeOfDay(_nightEnd),
              onPressed: () =>
                  _pickTime(_nightEnd, (t) => _nightEnd = t),
            ),
            if (!_isNightTimesValid)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Start and end time must differ',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            else if (_isNightOvernight)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Night shift ends next day',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],

          const SizedBox(height: 36),
          FilledButton(
            onPressed: _canGenerate ? _generate : null,
            child: _generating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Set Day 1 & Generate'),
          ),
        ],
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
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          FilledButton.tonal(
            onPressed: onPressed,
            child: Text(valueLabel),
          ),
        ],
      ),
    );
  }
}
