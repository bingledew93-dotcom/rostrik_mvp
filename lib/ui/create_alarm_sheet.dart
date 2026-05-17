import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/models/app_alarm.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/app_alarm_repository.dart';
import 'shift_format.dart';

/// Modal entry point shown from the AlarmsScreen FAB. Builds an
/// [AppAlarm] from a draft state and `upsert`s it via the repository
/// — the surrounding screen's `StreamProvider<List<AppAlarm>>` re-emits
/// and the new card appears at its sorted position.
///
/// Use via `showCreateAlarmSheet(context)`. The function returns when
/// the sheet is dismissed (regardless of save vs. cancel).
Future<void> showCreateAlarmSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) => Padding(
      // Lift the sheet above the keyboard when the label field is
      // focused. `viewInsets.bottom` is the inset to the keyboard top.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom,
      ),
      child: const CreateAlarmSheet(),
    ),
  );
}

/// Stateful body of the create-alarm sheet. Exposed (`public`) so the
/// widget tests can drive it directly without the bottom-sheet wrapper.
class CreateAlarmSheet extends StatefulWidget {
  const CreateAlarmSheet({super.key});

  @override
  State<CreateAlarmSheet> createState() => _CreateAlarmSheetState();
}

class _CreateAlarmSheetState extends State<CreateAlarmSheet> {
  static const Uuid _uuid = Uuid();

  // Default to a 07:00 alarm so a sleep-impaired user who taps Save
  // immediately gets a sensible default — they can always edit later.
  int _minutesOfDay = 7 * 60;
  final TextEditingController _labelController =
      TextEditingController(text: 'Wake Up');
  AppAlarmRepeatType _repeatType = AppAlarmRepeatType.followsRotation;
  ShiftType _linkedShiftType = ShiftType.day;
  bool _isRelativeTime = false;
  // Default 90 min mirrors the model's HiveField default. We keep this
  // value live across toggle flips so a user who briefly switches to
  // exact-time and back doesn't lose their carefully-tuned offset.
  int _relativeOffsetMinutes = 90;
  bool _saving = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _minutesOfDay ~/ 60,
        minute: _minutesOfDay % 60,
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _minutesOfDay = picked.hour * 60 + picked.minute);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final repo = context.read<AppAlarmRepository>();
    final navigator = Navigator.of(context);
    final label = _labelController.text.trim();
    final isFollowsRotation =
        _repeatType == AppAlarmRepeatType.followsRotation;
    final alarm = AppAlarm(
      id: _uuid.v4(),
      minutesOfDay: _minutesOfDay,
      label: label.isEmpty ? 'Alarm' : label,
      repeatType: _repeatType,
      enabled: true,
      // Only stamp the link if the repeat mode wants it; oneTime
      // alarms get a null link so the sync service knows to ignore it.
      linkedShiftType: isFollowsRotation ? _linkedShiftType : null,
      // isRelativeTime is only meaningful for follows-rotation. Force
      // false for one-time alarms so a user who toggles the relative
      // switch and then flips back to one-time doesn't persist a
      // confusing flag the sync service ignores anyway.
      isRelativeTime: isFollowsRotation && _isRelativeTime,
      relativeOffsetMinutes: _relativeOffsetMinutes,
    );
    await repo.upsert(alarm);
    if (!mounted) return;
    navigator.pop();
  }

  Future<void> _pickRelativeOffset() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => _OffsetPickerDialog(initialMinutes: _relativeOffsetMinutes),
    );
    if (!mounted || picked == null) return;
    setState(() => _relativeOffsetMinutes = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New alarm',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Massive, easily-tappable time display. In exact-time mode
            // it shows HH:MM and opens the native time picker; in
            // relative-time mode it shows "- 1h 30m" and opens the
            // offset-picker dialog. Same hit target either way so the
            // muscle-memory tap location doesn't change.
            InkWell(
              key: const ValueKey('create-alarm-time-tap'),
              onTap: _isRelativeTime ? _pickRelativeOffset : _pickTime,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _isRelativeTime
                      ? _formatOffset(_relativeOffsetMinutes)
                      : formatHhmm(_minutesOfDay),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    color: theme.colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('create-alarm-label'),
              controller: _labelController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Label',
                hintText: 'e.g. Wake Up',
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Repeat', style: theme.textTheme.labelLarge),
            ),
            const SizedBox(height: 8),
            SegmentedButton<AppAlarmRepeatType>(
              segments: const [
                ButtonSegment(
                  value: AppAlarmRepeatType.followsRotation,
                  label: Text('Follows rotation'),
                ),
                ButtonSegment(
                  value: AppAlarmRepeatType.oneTime,
                  label: Text('One time'),
                ),
              ],
              selected: {_repeatType},
              onSelectionChanged: (s) =>
                  setState(() => _repeatType = s.single),
              showSelectedIcon: false,
            ),
            // Linked shift type reveal — only relevant for the
            // follows-rotation path. `AnimatedSize` so the sheet height
            // doesn't snap when the user toggles between modes.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _repeatType == AppAlarmRepeatType.followsRotation
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Time mode',
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Exact vs relative. The huge time display
                          // above re-renders based on this flag — same
                          // tap-target location, different picker on
                          // tap. Only shown for follows-rotation
                          // because the relative semantics only make
                          // sense when there IS a shift to be relative
                          // to.
                          SegmentedButton<bool>(
                            key: const ValueKey('create-alarm-time-mode'),
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('Exact Time'),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('Time Before Shift'),
                              ),
                            ],
                            selected: {_isRelativeTime},
                            onSelectionChanged: (s) =>
                                setState(() => _isRelativeTime = s.single),
                            showSelectedIcon: false,
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Linked shift',
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Three options — Off intentionally excluded
                          // (there's no shift to ring before on an off
                          // day). The user's "Custom" shorthand maps to
                          // Afternoon here.
                          SegmentedButton<ShiftType>(
                            segments: const [
                              ButtonSegment(
                                value: ShiftType.day,
                                label: Text('Day'),
                              ),
                              ButtonSegment(
                                value: ShiftType.afternoon,
                                label: Text('Afternoon'),
                              ),
                              ButtonSegment(
                                value: ShiftType.night,
                                label: Text('Night'),
                              ),
                            ],
                            selected: {_linkedShiftType},
                            onSelectionChanged: (s) =>
                                setState(() => _linkedShiftType = s.single),
                            showSelectedIcon: false,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('create-alarm-save'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Human-readable label for a relative offset. Always prefixed with
/// "- " so the time display reads as "minus N minutes" regardless of
/// whether the user is looking at a 45-minute or 4-hour offset.
String _formatOffset(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '- ${m}m';
  if (m == 0) return '- ${h}h';
  return '- ${h}h ${m}m';
}

/// Modal dialog that lets the user set the relative offset in minutes.
/// A single slider snaps every 5 min from 5 to 240 (4 hours max) — wide
/// enough for any realistic "wake me up before my shift" runway, narrow
/// enough that the slider's per-pixel resolution stays usable. Returns
/// the picked value via `Navigator.pop(context, value)`; returns `null`
/// on Cancel.
class _OffsetPickerDialog extends StatefulWidget {
  const _OffsetPickerDialog({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_OffsetPickerDialog> createState() => _OffsetPickerDialogState();
}

class _OffsetPickerDialogState extends State<_OffsetPickerDialog> {
  static const double _minMinutes = 5;
  static const double _maxMinutes = 240;
  // 5-min snaps: (240 - 5) / 5 = 47 divisions, 48 distinct positions.
  static const int _divisions = 47;

  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialMinutes
        .toDouble()
        .clamp(_minMinutes, _maxMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Time before shift'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatOffset(_value.round()),
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            key: const ValueKey('offset-picker-slider'),
            value: _value,
            min: _minMinutes,
            max: _maxMinutes,
            divisions: _divisions,
            label: _formatOffset(_value.round()),
            onChanged: (v) => setState(() => _value = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5 min', style: theme.textTheme.bodySmall),
              Text('4 h', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('offset-picker-ok'),
          onPressed: () => Navigator.of(context).pop(_value.round()),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
