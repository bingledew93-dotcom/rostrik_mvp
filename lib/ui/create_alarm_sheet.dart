import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../alarms/alarm_sound.dart';
import '../data/models/alarm_settings.dart';
import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/alarm_settings_repository.dart';
import '../data/repositories/app_alarm_repository.dart';
import '../state/app_preferences.dart';
import '../util/weekday_mask.dart';
import 'alarm_sound_previewer.dart';
import 'alarm_time_projection.dart';
import 'shift_format.dart';

/// Monday-first short weekday labels for the weekly-repeat chips. Index `d - 1`
/// for an ISO weekday (`DateTime.monday == 1`).
const List<String> _weekdayChipLabels = <String>[
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

/// Modal entry point shown from the AlarmsScreen FAB (create) and from tapping
/// an existing card (edit). Builds an [AppAlarm] from a draft state and
/// `upsert`s it via the repository — the surrounding screen's
/// `StreamProvider<List<AppAlarm>>` re-emits and the card appears (or updates
/// in place) at its sorted position.
///
/// Pass [initial] to open in Edit Mode: every field is pre-populated and Save
/// writes back under the SAME id, so `AlarmSyncService` reschedules in place
/// rather than creating a duplicate. Omit it to create a fresh alarm.
///
/// Use via `showCreateAlarmSheet(context)`. The function returns when
/// the sheet is dismissed (regardless of save vs. cancel).
Future<void> showCreateAlarmSheet(BuildContext context, {AppAlarm? initial}) {
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
      child: CreateAlarmSheet(initial: initial),
    ),
  );
}

/// Stateful body of the create-alarm sheet. Exposed (`public`) so the
/// widget tests can drive it directly without the bottom-sheet wrapper.
class CreateAlarmSheet extends StatefulWidget {
  const CreateAlarmSheet({super.key, this.previewer, this.initial});

  /// Injectable for tests — a fake-backed previewer avoids the audioplayers
  /// platform channel. Production passes none (a real [AlarmSoundPreviewer] is
  /// created in `initState`).
  final AlarmSoundPreviewer? previewer;

  /// When non-null, the sheet opens in Edit Mode pre-populated from this alarm,
  /// and Save updates the record under its existing id. Null = create flow.
  final AppAlarm? initial;

  @override
  State<CreateAlarmSheet> createState() => _CreateAlarmSheetState();
}

class _CreateAlarmSheetState extends State<CreateAlarmSheet> {
  static const Uuid _uuid = Uuid();

  // Default to a 07:00 alarm so a sleep-impaired user who taps Save
  // immediately gets a sensible default — they can always edit later.
  // Only used by one-time alarms; follows-rotation alarms ignore it.
  int _minutesOfDay = 7 * 60;
  final TextEditingController _labelController =
      TextEditingController(text: 'Wake Up');
  AppAlarmRepeatType _repeatType = AppAlarmRepeatType.followsRotation;
  ShiftType _linkedShiftType = ShiftType.day;
  // Lead-time mode for follows-rotation alarms. `true` (default) means "use the
  // global AlarmSettings.leadTime" → a null per-alarm offset. `false` means
  // this alarm carries its own override (`_customOffsetMinutes`).
  bool _useGlobalLeadTime = true;
  // Custom override value, kept live across mode flips so a user who briefly
  // switches to the default and back doesn't lose their tuned offset.
  int _customOffsetMinutes = 90;
  // Critical-Shift wake mechanics (shake-to-dismiss + hold fail-safe).
  bool _isCriticalShift = false;
  // Bundled tone this alarm will ring. The OS plays it (per-tone channel / iOS
  // sound); the previewer below is only for "what does this sound like".
  String _soundKey = kDefaultAlarmSoundKey;
  // Selected ISO weekdays (1..7) for a weekly alarm. Empty until the user picks
  // days; a weekly alarm can't be saved while empty.
  final Set<int> _weekdays = <int>{};
  // One-time only: delete the record permanently the instant it's dismissed.
  bool _autoDeleteAfterFiring = false;
  bool _saving = false;

  late final AlarmSoundPreviewer _previewer;

  /// True when the sheet was opened to edit an existing alarm — drives the
  /// header copy and makes Save write back under the existing id.
  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _previewer = widget.previewer ?? AlarmSoundPreviewer();

    // Edit Mode: pre-populate every field from the alarm being edited so the
    // user lands on its exact current state (label, sound, sliders, chips,
    // weekly days, toggles).
    final initial = widget.initial;
    if (initial != null) {
      _minutesOfDay = initial.minutesOfDay;
      _labelController.text = initial.label;
      _repeatType = initial.repeatType;
      _linkedShiftType = initial.linkedShiftType ?? ShiftType.day;
      // A null override means "track the global default"; a value means this
      // alarm carries its own lead time (Custom mode, slider pre-set to it).
      _useGlobalLeadTime = initial.relativeOffsetMinutes == null;
      _customOffsetMinutes = initial.relativeOffsetMinutes ?? _customOffsetMinutes;
      _isCriticalShift = initial.isCriticalShift;
      _soundKey = initial.soundKey;
      _weekdays.addAll(weekdaysFromMask(initial.weekdaysBitmask));
      _autoDeleteAfterFiring = initial.autoDeleteAfterFiring;
    }
  }

  @override
  void dispose() {
    _previewer.dispose();
    _labelController.dispose();
    super.dispose();
  }

  /// Selects [sound] AND previews it. Fire-and-forget: the previewer's strict
  /// stop-before-play means rapid taps never overlap.
  void _selectSound(AlarmSound sound) {
    setState(() => _soundKey = sound.key);
    _previewer.preview(sound);
  }

  /// Opens the system audio browser and, on selection, persists the picked
  /// file's path + name to the global [AlarmSettings]. Phase 1: storage only —
  /// nothing here touches the OS playback path. Cancelled picks are a no-op.
  Future<void> _pickRingtone() async {
    // Snapshot the repo BEFORE the await so we never touch `context` across the
    // async gap (the file browser is a separate activity/sheet).
    final repo = context.read<AlarmSettingsRepository>();
    // file_picker 11.x: `pickFiles` is a static on FilePicker. Audio-only.
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result == null || result.files.isEmpty) return; // cancelled
    final file = result.files.first;
    final srcPath = file.path;
    if (srcPath == null) return; // no usable path (shouldn't happen on mobile)
    // file_picker hands back a path in the app CACHE dir, which the OS can
    // purge at any time — the exact "cached file cleared" failure mode. Copy it
    // into durable app-support storage so the saved URI keeps resolving, and
    // store THAT path. (Native playback wiring is the deferred Phase 2.)
    final durablePath = await _persistRingtone(srcPath, file.name);
    final current = await repo.read();
    await repo.write(
      current.copyWith(
        customRingtoneUri: durablePath,
        customRingtoneName: file.name,
      ),
    );
    // No setState / context use: the sheet watches AlarmSettings, so the write
    // re-emits through the stream and the row rebuilds with the new name.
  }

  /// Copies the picked audio file into `<app-support>/ringtones/` and returns
  /// the durable absolute path. Only one global ringtone is ever active, so the
  /// directory is wiped first — the slot never accumulates auditioned files.
  /// The destination name is stripped of path separators and the payload
  /// delimiter (`|`) so the stored path is safe to embed in the alarm payload.
  static Future<String> _persistRingtone(String srcPath, String name) async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}/ringtones');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final safeName = name.isEmpty
        ? 'ringtone'
        : name.replaceAll(RegExp(r'[\\/|]'), '_');
    final dest = File('${dir.path}/$safeName');
    await File(srcPath).copy(dest.path);
    return dest.path;
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
    final initial = widget.initial;
    final isFollowsRotation =
        _repeatType == AppAlarmRepeatType.followsRotation;
    final isWeekly = _repeatType == AppAlarmRepeatType.weekly;
    final isOneTime = _repeatType == AppAlarmRepeatType.oneTime;
    final alarm = AppAlarm(
      // Edit Mode reuses the existing id so the repository updates the record
      // in place (one card, one reconcile) instead of minting a duplicate.
      id: initial?.id ?? _uuid.v4(),
      minutesOfDay: _minutesOfDay,
      label: label.isEmpty ? 'Alarm' : label,
      repeatType: _repeatType,
      // Preserve the on/off state when editing; new alarms start enabled.
      enabled: initial?.enabled ?? true,
      // Only stamp the link if the repeat mode wants it; weekly / oneTime
      // alarms get a null link so the sync service knows to ignore it.
      linkedShiftType: isFollowsRotation ? _linkedShiftType : null,
      // null → use the global lead time (the primary default). A value → this
      // alarm overrides the global lead time. weekly / oneTime alarms never
      // carry an offset (they fire at minutesOfDay), so force null there.
      relativeOffsetMinutes:
          isFollowsRotation && !_useGlobalLeadTime ? _customOffsetMinutes : null,
      isCriticalShift: _isCriticalShift,
      soundKey: _soundKey,
      // Weekday mask only carries meaning for weekly alarms; force 0 otherwise
      // so flipping repeat type can't leave a stale day set behind.
      weekdaysBitmask: isWeekly ? weekdayMaskFromSet(_weekdays) : 0,
      // Auto-delete is a one-time-only affordance.
      autoDeleteAfterFiring: isOneTime && _autoDeleteAfterFiring,
    );
    await repo.upsert(alarm);
    if (!mounted) return;
    navigator.pop();
  }

  Future<void> _pickRelativeOffset() async {
    // Resolve the linked shift's start now so the dialog can show the live
    // target clock time as the slider drags.
    final shiftStart = resolveShiftStartMinutes(
      context.read<List<Shift>>(),
      _linkedShiftType,
      now: DateTime.now(),
    );
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => _OffsetPickerDialog(
        initialMinutes: _customOffsetMinutes,
        shiftStartMinutes: shiftStart,
        shiftLabel: shiftTypeLabel(_linkedShiftType),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _customOffsetMinutes = picked);
  }

  /// A weekly alarm with no day selected would never fire, so Save is blocked
  /// until at least one day is picked. Every other repeat type is always
  /// saveable.
  bool get _canSave =>
      _repeatType != AppAlarmRepeatType.weekly || _weekdays.isNotEmpty;

  /// The reveal beneath the Repeat selector, specific to the chosen repeat type:
  ///   * followsRotation → lead-time mode + linked-shift pickers;
  ///   * weekly → the Mon–Sun multi-select day chips;
  ///   * oneTime → the "auto-delete after firing" toggle.
  Widget _buildRepeatReveal(ThemeData theme, int globalLeadMinutes) {
    switch (_repeatType) {
      case AppAlarmRepeatType.followsRotation:
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Lead time', style: theme.textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              // Global default vs per-alarm override. A follows-rotation alarm
              // always fires BEFORE the shift — there is no absolute-clock-time
              // mode, because a fixed time can't track a shift that moves. "Use
              // default" pulls the global lead time (single source of truth);
              // "Custom" overrides it for this alarm only.
              SegmentedButton<bool>(
                key: const ValueKey('create-alarm-lead-mode'),
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text('Use default ($globalLeadMinutes min)'),
                  ),
                  const ButtonSegment(value: false, label: Text('Custom')),
                ],
                selected: {_useGlobalLeadTime},
                onSelectionChanged: (s) =>
                    setState(() => _useGlobalLeadTime = s.single),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Linked shift', style: theme.textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              // Three options — Off intentionally excluded (there's no shift to
              // ring before on an off day).
              SegmentedButton<ShiftType>(
                segments: const [
                  ButtonSegment(value: ShiftType.day, label: Text('Day')),
                  ButtonSegment(
                    value: ShiftType.afternoon,
                    label: Text('Afternoon'),
                  ),
                  ButtonSegment(value: ShiftType.night, label: Text('Night')),
                ],
                selected: {_linkedShiftType},
                onSelectionChanged: (s) =>
                    setState(() => _linkedShiftType = s.single),
                showSelectedIcon: false,
              ),
            ],
          ),
        );
      case AppAlarmRepeatType.weekly:
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Repeat on', style: theme.textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      key: ValueKey('create-alarm-weekday-$d'),
                      label: Text(_weekdayChipLabels[d - 1]),
                      selected: _weekdays.contains(d),
                      onSelected: (sel) => setState(() {
                        if (sel) {
                          _weekdays.add(d);
                        } else {
                          _weekdays.remove(d);
                        }
                      }),
                    ),
                ],
              ),
            ],
          ),
        );
      case AppAlarmRepeatType.oneTime:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SwitchListTile(
            key: const ValueKey('create-alarm-autodelete'),
            contentPadding: EdgeInsets.zero,
            value: _autoDeleteAfterFiring,
            onChanged: (v) => setState(() => _autoDeleteAfterFiring = v),
            title: const Text('Auto-delete after firing'),
            subtitle:
                const Text('Remove this alarm once it rings and is dismissed'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alarmSettings = context.watch<AlarmSettings>();
    final globalLeadMinutes = alarmSettings.leadTime.inMinutes;
    // Global custom ringtone (default "Rostrik Classic" → the bundled .wav).
    // Stored on AlarmSettings, surfaced here in the alarm editor.
    final ringtoneName = alarmSettings.customRingtoneName ?? 'Rostrik Classic';
    // Roster shifts (streamed app-wide) let the hero show the REAL firing clock
    // time for the linked shift, not the bare offset. Empty/absent-of-type →
    // falls back to a per-type default so a clock always renders.
    final shifts = context.watch<List<Shift>>();
    final isFollowsRotation =
        _repeatType == AppAlarmRepeatType.followsRotation;
    final showLeadTime = isFollowsRotation;
    // Active lead: the global default, or this alarm's custom override.
    final heroOffset =
        _useGlobalLeadTime ? globalLeadMinutes : _customOffsetMinutes;
    // The linked shift's start (from the roster) and the resulting fire clock.
    final shiftStart =
        resolveShiftStartMinutes(shifts, _linkedShiftType, now: DateTime.now());
    final fireClock = fireClockMinutes(shiftStart, heroOffset);
    // Hero headline: the calculated firing CLOCK time (AM/PM). One-time alarms
    // ring at their picked time; follows-rotation alarms ring `shiftStart −
    // lead`. The offset itself is demoted to the caption below.
    final use24Hour = AppPreferences.use24HourOf(context);
    final heroClock = showLeadTime
        ? formatClock(fireClock, use24Hour: use24Hour)
        : formatClock(_minutesOfDay, use24Hour: use24Hour);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEditing ? 'Edit alarm' : 'New alarm',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Massive, easily-tappable hero — the calculated FIRING CLOCK TIME
            // (e.g. "05:30 AM"). One-time → opens the time picker. Follows-
            // rotation → read-only in default mode (the offset lives in
            // Settings), tappable to edit the offset when custom. The offset
            // moves to the caption below so the clock leads the hierarchy.
            InkWell(
              key: const ValueKey('create-alarm-time-tap'),
              onTap: !showLeadTime
                  ? _pickTime
                  : (_useGlobalLeadTime ? null : _pickRelativeOffset),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  heroClock,
                  key: const ValueKey('create-alarm-hero-clock'),
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
            // Demoted offset caption: "1h 30m before Day shifts" (+ a Settings
            // hint in default mode). Follows-rotation only — one-time alarms
            // have no lead.
            if (showLeadTime)
              Text(
                _useGlobalLeadTime
                    ? '${formatLeadOffset(heroOffset)} before '
                        '${shiftTypeLabel(_linkedShiftType)} shifts · '
                        'default (Settings)'
                    : '${formatLeadOffset(heroOffset)} before '
                        '${shiftTypeLabel(_linkedShiftType)} shifts',
                key: const ValueKey('create-alarm-offset-caption'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            // Weekly alarms ring at the absolute clock above; the caption
            // demotes the recurrence ("Mon, Wed, Fri" / "Every day"), or
            // prompts when no day is picked yet.
            if (_repeatType == AppAlarmRepeatType.weekly)
              Text(
                _weekdays.isEmpty
                    ? 'Pick at least one day'
                    : formatWeekdays(weekdayMaskFromSet(_weekdays)),
                key: const ValueKey('create-alarm-weekly-caption'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
            const SizedBox(height: 8),
            // Applies to both repeat types — Critical is about the WAKE
            // mechanic, independent of when/how often the alarm fires.
            SwitchListTile(
              key: const ValueKey('create-alarm-critical'),
              contentPadding: EdgeInsets.zero,
              value: _isCriticalShift,
              onChanged: (v) => setState(() => _isCriticalShift = v),
              title: const Text('Critical shift'),
              subtitle:
                  const Text('Shake to dismiss · 3-second hold fail-safe'),
            ),
            const SizedBox(height: 8),
            // Bundled-tone picker. One permanently-visible row of chips — one
            // tap selects AND previews (no menu). Applies to both repeat types.
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Sound', style: theme.textTheme.labelLarge),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in kAlarmSounds)
                  ChoiceChip(
                    key: ValueKey('create-alarm-sound-${s.key}'),
                    label: Text(s.label),
                    selected: _soundKey == s.key,
                    onSelected: (_) => _selectSound(s),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Repeat', style: theme.textTheme.labelLarge),
            ),
            const SizedBox(height: 8),
            SegmentedButton<AppAlarmRepeatType>(
              segments: const [
                ButtonSegment(
                  value: AppAlarmRepeatType.followsRotation,
                  label: Text('Rotation'),
                ),
                ButtonSegment(
                  value: AppAlarmRepeatType.weekly,
                  label: Text('Weekly'),
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
            // Per-repeat-type reveal. `AnimatedSize` so the sheet height
            // doesn't snap when the user toggles between modes.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _buildRepeatReveal(theme, globalLeadMinutes),
            ),
            const SizedBox(height: 16),
            // Custom ringtone (Phase 1 — storage + selection only). Sits BELOW
            // the repeat config on purpose: the lead-mode / weekday controls in
            // the reveal above stay where they are, so this row never shoves
            // them off-screen. Tapping opens the system audio browser; the
            // picked file's name shows here and its path saves to the global
            // AlarmSettings. Playback wiring is a later phase.
            InkWell(
              key: const ValueKey('create-alarm-ringtone-row'),
              onTap: _pickRingtone,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ringtone', style: theme.textTheme.labelLarge),
                          const SizedBox(height: 2),
                          Text(
                            ringtoneName,
                            key: const ValueKey('create-alarm-ringtone-name'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('create-alarm-save'),
              onPressed: (_saving || !_canSave) ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero label for a lead-time offset — the shared [formatLeadOffset] magnitude
/// prefixed with "- " so it reads as "minus N minutes".
String _formatOffset(int minutes) => '- ${formatLeadOffset(minutes)}';

/// Modal dialog that lets the user set the custom override in minutes.
/// A single slider snaps every 5 min from 5 to 240 (4 hours max) — wide
/// enough for any realistic "wake me up before my shift" runway, narrow
/// enough that the slider's per-pixel resolution stays usable. Returns
/// the picked value via `Navigator.pop(context, value)`; returns `null`
/// on Cancel.
class _OffsetPickerDialog extends StatefulWidget {
  const _OffsetPickerDialog({
    required this.initialMinutes,
    required this.shiftStartMinutes,
    required this.shiftLabel,
  });

  final int initialMinutes;

  /// Linked shift's start minute-of-day — the dialog shows `start − offset` as
  /// the live target clock so the user sets the offset by its consequence.
  final int shiftStartMinutes;
  final String shiftLabel;

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
          // Calculated target clock leads; the offset is the supporting line.
          // Both recompute live as the slider drags.
          Text(
            formatClock(
              fireClockMinutes(widget.shiftStartMinutes, _value.round()),
              use24Hour: AppPreferences.use24HourOf(context),
            ),
            key: const ValueKey('offset-picker-clock'),
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatLeadOffset(_value.round())} before '
            '${widget.shiftLabel} shifts',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
