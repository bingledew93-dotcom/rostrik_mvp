import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/shift_type.dart';
import '../logic/rotation_pattern_validator.dart';
import '../logic/shift_block.dart';
import '../logic/shift_generator.dart';
import 'shift_format.dart';

/// Draft-and-review custom roster builder.
///
/// Lets the user compose an arbitrary list of [ShiftBlock]s on top of a
/// user-named cycle length, then hands the draft to
/// [ShiftGenerator.generateAndPersistCustom]. Multiple blocks on the
/// same cycle-day index are allowed (split shifts); time-overlap is
/// rejected with the exception's message surfaced inline above the
/// Generate button so the user can see exactly which times conflict.
///
/// Reachable from the "Build custom roster" entry on
/// [PatternPickerScreen]. Persists nothing until the user taps Generate;
/// the entire draft lives in this State.
class CustomBuilderScreen extends StatefulWidget {
  const CustomBuilderScreen({super.key});

  @override
  State<CustomBuilderScreen> createState() => _CustomBuilderScreenState();
}

class _CustomBuilderScreenState extends State<CustomBuilderScreen> {
  static const int _minCycleDays = 1;
  static const int _maxCycleDays = 60;
  static const int _minRepeats = 1;
  static const int _maxRepeats = 200;

  final TextEditingController _nameController =
      TextEditingController(text: 'Custom roster');
  int _cycleLengthDays = 7;
  int _repeatCount = 4;
  DateTime? _startDate;
  bool _generating = false;
  String? _validationError;

  // Default first block at 07:00–15:00, day 0 of a single-day span.
  // Mirrors the picker's "first time-edit" defaults so the user can tap
  // Add Block twice and edit one of them — testing the split-shift case
  // takes ~5 taps from a cold open.
  final List<ShiftBlock> _blocks = <ShiftBlock>[
    const ShiftBlock(
      type: ShiftType.day,
      startDayIndex: 0,
      endDayIndex: 0,
      startMinutes: 7 * 60,
      endMinutes: 15 * 60,
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canGenerate {
    if (_generating) return false;
    if (_blocks.isEmpty) return false;
    if (_startDate == null) return false;
    return true;
  }

  void _addBlock() {
    setState(() {
      // New blocks default to the previous block's `endDayIndex` so the
      // split-shift flow is one tap (Add Block → adjust time → done).
      // Sequential rotations still cost one extra stepper tap per block
      // to advance the day, which is acceptable. Empty list → day 0.
      final defaultDayIndex = _blocks.isEmpty
          ? 0
          : _blocks.last.endDayIndex.clamp(0, _cycleLengthDays - 1);
      _blocks.add(ShiftBlock(
        type: ShiftType.day,
        startDayIndex: defaultDayIndex,
        endDayIndex: defaultDayIndex,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      ));
      _validationError = null;
    });
  }

  void _removeBlock(int i) {
    setState(() {
      _blocks.removeAt(i);
      _validationError = null;
    });
  }

  void _updateBlock(int i, ShiftBlock next) {
    setState(() {
      _blocks[i] = next;
      _validationError = null;
    });
  }

  void _setCycleLength(int v) {
    setState(() {
      _cycleLengthDays = v.clamp(_minCycleDays, _maxCycleDays);
      // Clamp any block day indices that now sit past the new cycle end.
      for (var i = 0; i < _blocks.length; i++) {
        final b = _blocks[i];
        final newEnd = b.endDayIndex.clamp(0, _cycleLengthDays - 1);
        final newStart = b.startDayIndex.clamp(0, newEnd);
        if (newEnd != b.endDayIndex || newStart != b.startDayIndex) {
          _blocks[i] = b.copyWith(
            startDayIndex: newStart,
            endDayIndex: newEnd,
          );
        }
      }
      _validationError = null;
    });
  }

  void _setRepeatCount(int v) {
    setState(() {
      _repeatCount = v.clamp(_minRepeats, _maxRepeats);
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 10, today.month, today.day),
    );
    if (!mounted || picked == null) return;
    setState(() => _startDate = picked);
  }

  Future<void> _pickBlockTime(int i, {required bool start}) async {
    final b = _blocks[i];
    final minutesNow = start ? b.startMinutes : b.endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutesNow ~/ 60, minute: minutesNow % 60),
    );
    if (!mounted || picked == null) return;
    final m = picked.hour * 60 + picked.minute;
    _updateBlock(
      i,
      start ? b.copyWith(startMinutes: m) : b.copyWith(endMinutes: m),
    );
  }

  Future<void> _generate() async {
    if (!_canGenerate) return;
    setState(() {
      _generating = true;
      _validationError = null;
    });

    // Capture before any awaits — BuildContext is unsafe to read across
    // suspensions.
    final generator = context.read<ShiftGenerator>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final shifts = await generator.generateAndPersistCustom(
        label: _nameController.text.trim().isEmpty
            ? 'Custom roster'
            : _nameController.text.trim(),
        startDate: _startDate!,
        cycleLengthDays: _cycleLengthDays,
        repeatCount: _repeatCount,
        blocks: List<ShiftBlock>.unmodifiable(_blocks),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Generated ${shifts.length} shifts')),
      );
      // pop(true) signals "a roster was generated" to a caller that
      // awaits the push result — the unified PatternPickerBody uses
      // this to fire its `onGenerated` callback after a Custom
      // Builder round-trip. Callers that ignore the value (Settings
      // → Add another rotation) are unaffected.
      navigator.pop(true);
    } on RosterGenerationException catch (e) {
      // Inline error banner above the Generate button — clearer than a
      // SnackBar for multi-line validator output (a single overlap can
      // list multiple offending pairs). The banner is what the task
      // brief calls "red text banner above the save button".
      if (!mounted) return;
      setState(() {
        _generating = false;
        _validationError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _validationError = 'Generation failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Build custom roster')),
      // SafeArea(bottom: true) so the Generate button can't tuck under
      // the Android gesture-navigation pill / 3-button bar. Top is left
      // off because the AppBar already consumes the status-bar inset.
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Roster name', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. Split-shift trial',
              ),
            ),
            const SizedBox(height: 24),
            _IntStepperRow(
              key: const ValueKey('custom-cycle-length'),
              label: 'Cycle length (days)',
              value: _cycleLengthDays,
              min: _minCycleDays,
              max: _maxCycleDays,
              onChanged: _setCycleLength,
            ),
            const SizedBox(height: 8),
            _IntStepperRow(
              key: const ValueKey('custom-repeat-count'),
              label: 'Repeat cycle ×',
              value: _repeatCount,
              min: _minRepeats,
              max: _maxRepeats,
              onChanged: _setRepeatCount,
            ),
            const SizedBox(height: 16),
            _DateRow(
              label: 'Start date',
              buttonKey: const ValueKey('custom-start-date'),
              date: _startDate,
              onPick: _pickStartDate,
            ),
            const SizedBox(height: 24),
            Text('Blocks', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Two blocks on the same cycle day are allowed — that\'s how '
              'you describe a split shift.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _blocks.length; i++)
              _BlockCard(
                key: ValueKey('custom-block-$i'),
                index: i,
                block: _blocks[i],
                cycleLengthDays: _cycleLengthDays,
                onChanged: (b) => _updateBlock(i, b),
                onRemove: _blocks.length == 1 ? null : () => _removeBlock(i),
                onPickStartTime: () => _pickBlockTime(i, start: true),
                onPickEndTime: () => _pickBlockTime(i, start: false),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                key: const ValueKey('custom-add-block'),
                onPressed: _addBlock,
                icon: const Icon(Icons.add),
                label: const Text('Add Block'),
              ),
            ),
            const SizedBox(height: 24),
            if (_validationError != null) ...[
              _ValidationBanner(message: _validationError!),
              const SizedBox(height: 12),
            ],
            FilledButton(
              key: const ValueKey('custom-generate'),
              onPressed: _canGenerate ? _generate : null,
              child: _generating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate & Save Roster'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Per-block editor card. Inline (not modal) so the user can tweak a
/// time and re-tap Generate without a sheet-dismiss round-trip — this
/// is the fastest path to repeatedly testing the split-shift validator.
class _BlockCard extends StatelessWidget {
  const _BlockCard({
    super.key,
    required this.index,
    required this.block,
    required this.cycleLengthDays,
    required this.onChanged,
    required this.onRemove,
    required this.onPickStartTime,
    required this.onPickEndTime,
  });

  final int index;
  final ShiftBlock block;
  final int cycleLengthDays;
  final ValueChanged<ShiftBlock> onChanged;
  final VoidCallback? onRemove;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Block ${index + 1}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove block',
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SegmentedButton<ShiftType>(
              segments: const [
                ButtonSegment(value: ShiftType.day, label: Text('Day')),
                ButtonSegment(
                    value: ShiftType.afternoon, label: Text('Afternoon')),
                ButtonSegment(value: ShiftType.night, label: Text('Night')),
                ButtonSegment(value: ShiftType.off, label: Text('Off')),
              ],
              selected: {block.type},
              onSelectionChanged: (s) =>
                  onChanged(block.copyWith(type: s.single)),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // UI presents day indices as 1-based (Day 1..Day N) for
                // readability; storage stays 0-based so the generator
                // payload matches the math engine's contract. The +1/-1
                // hop happens at the stepper boundary only.
                Expanded(
                  child: _IntStepperRow(
                    label: 'Start day',
                    value: block.startDayIndex + 1,
                    min: 1,
                    max: cycleLengthDays,
                    onChanged: (displayed) {
                      final zeroBased = displayed - 1;
                      // Keep end >= start to preserve the inclusive
                      // range invariant; bump end forward if needed.
                      final newEnd = zeroBased > block.endDayIndex
                          ? zeroBased
                          : block.endDayIndex;
                      onChanged(block.copyWith(
                        startDayIndex: zeroBased,
                        endDayIndex: newEnd,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _IntStepperRow(
                    label: 'End day',
                    value: block.endDayIndex + 1,
                    min: block.startDayIndex + 1,
                    max: cycleLengthDays,
                    onChanged: (displayed) =>
                        onChanged(block.copyWith(endDayIndex: displayed - 1)),
                  ),
                ),
              ],
            ),
            if (block.type != ShiftType.off) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('Time', style: theme.textTheme.bodyLarge),
                  ),
                  OutlinedButton(
                    key: ValueKey('custom-block-$index-start-time'),
                    onPressed: onPickStartTime,
                    child: Text(formatHhmm(block.startMinutes)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  OutlinedButton(
                    key: ValueKey('custom-block-$index-end-time'),
                    onPressed: onPickEndTime,
                    child: Text(formatHhmm(block.endMinutes)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact "- value +" stepper. Manual buttons (not a Slider) because
/// the value range is small AND we want exact integer setting; sliders
/// at 60-day max have too coarse a per-pixel resolution.
class _IntStepperRow extends StatelessWidget {
  const _IntStepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabledDown = value <= min;
    final disabledUp = value >= max;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyLarge),
        ),
        IconButton.outlined(
          onPressed: disabledDown ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        IconButton.outlined(
          onPressed: disabledUp ? null : () => onChanged(value + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// Date row consistent with the pattern picker — keeps the visual rhythm
/// across the two generation surfaces.
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.buttonKey,
    required this.date,
    required this.onPick,
  });

  final String label;
  final Key buttonKey;
  final DateTime? date;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyLarge),
        ),
        FilledButton.tonal(
          key: buttonKey,
          onPressed: onPick,
          child: Text(date == null ? 'Pick date' : formatShiftDate(date!)),
        ),
      ],
    );
  }
}

/// Multi-line error banner. Used for the validator's output so a
/// multi-pair overlap report wraps cleanly above the Generate button.
class _ValidationBanner extends StatelessWidget {
  const _ValidationBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('custom-validation-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
