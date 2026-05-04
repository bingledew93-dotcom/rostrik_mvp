import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/shift_type.dart';
import '../logic/shift_generator.dart';
import 'shift_format.dart';

/// Bulk roster generator. Picks a pattern (start/end time + type) and a
/// block (start date + length), then asks [ShiftGenerator] to produce
/// and persist the shifts. The AlarmEngine's stream subscription picks
/// up the writes and reschedules — no engine wiring lives in this screen.
class TemplateScreen extends StatefulWidget {
  const TemplateScreen({super.key});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  static const _maxDays = 14;
  static const _minDays = 1;

  DateTime? _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 15, minute: 0);
  int _consecutiveDays = 7;
  ShiftType _shiftType = ShiftType.day;
  bool _generating = false;

  bool get _canGenerate {
    if (_generating) return false;
    if (_startDate == null) return false;
    if (_startTime == _endTime) return false;
    return true;
  }

  bool get _isOvernight {
    final s = _startTime.hour * 60 + _startTime.minute;
    final e = _endTime.hour * 60 + _endTime.minute;
    return e <= s;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (!mounted || picked == null) return;
    setState(() => _startDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _startTime);
    if (!mounted || picked == null) return;
    setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _endTime);
    if (!mounted || picked == null) return;
    setState(() => _endTime = picked);
  }

  Future<void> _generate() async {
    if (!_canGenerate) return;
    setState(() => _generating = true);

    // Capture context-dependent refs up front — they can't be safely
    // re-read after the await below.
    final generator = context.read<ShiftGenerator>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final shifts = await generator.generateAndPersist(
        startDate: _startDate!,
        startMinutes: _startTime.hour * 60 + _startTime.minute,
        endMinutes: _endTime.hour * 60 + _endTime.minute,
        consecutiveDays: _consecutiveDays,
        shiftType: _shiftType,
      );
      if (!mounted) return;
      // Show on the parent (RosterScreen) Scaffold's messenger so the
      // SnackBar survives the pop.
      messenger.showSnackBar(
        SnackBar(content: Text('Generated ${shifts.length} shifts')),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Generation failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Roster Block')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Text('Pattern', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          // Type — Off excluded, this screen is for active shift blocks.
          SegmentedButton<ShiftType>(
            segments: const [
              ButtonSegment(value: ShiftType.day, label: Text('Day')),
              ButtonSegment(
                  value: ShiftType.afternoon, label: Text('Afternoon')),
              ButtonSegment(value: ShiftType.night, label: Text('Night')),
            ],
            selected: {_shiftType},
            onSelectionChanged: (s) => setState(() => _shiftType = s.single),
          ),
          const SizedBox(height: 12),

          _PickerRow(
            label: 'Starts',
            valueLabel: formatTimeOfDay(_startTime),
            onPressed: _pickStartTime,
          ),
          _PickerRow(
            label: 'Ends',
            valueLabel: formatTimeOfDay(_endTime),
            onPressed: _pickEndTime,
          ),
          if (_isOvernight)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Each shift ends next day',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 24),

          Text('Block', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _PickerRow(
            label: 'Start date',
            valueLabel: _startDate == null
                ? 'Pick date'
                : formatShiftDate(_startDate!),
            onPressed: _pickStartDate,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('Consecutive days',
                    style: theme.textTheme.bodyLarge),
              ),
              Text(
                '$_consecutiveDays',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _consecutiveDays.toDouble(),
            min: _minDays.toDouble(),
            max: _maxDays.toDouble(),
            divisions: _maxDays - _minDays,
            label: '$_consecutiveDays',
            onChanged: (v) =>
                setState(() => _consecutiveDays = v.round()),
          ),

          const SizedBox(height: 24),
          FilledButton(
            onPressed: _canGenerate ? _generate : null,
            child: _generating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Generate Roster Block'),
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
