import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../alarms/alarm_capabilities.dart';
import '../alarms/alarm_projection.dart' show nextDailyOccurrence;
import '../alarms/alarm_sound.dart';
import '../alarms/default_tone_prefs.dart';
import '../alarms/ringtone_channel.dart';
import '../data/models/alarm_settings.dart';
import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/alarm_settings_repository.dart';
import '../data/repositories/app_alarm_repository.dart';
import '../state/app_preferences.dart';
import '../util/weekday_mask.dart';
import 'alarm_time_projection.dart';
import 'shift_format.dart';
import 'time_picker_pref.dart';

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
  const CreateAlarmSheet({
    super.key,
    this.initial,
    this.ringtoneChannel,
  });

  /// When non-null, the sheet opens in Edit Mode pre-populated from this alarm,
  /// and Save updates the record under its existing id. Null = create flow.
  final AppAlarm? initial;

  /// Injectable bridge to the native ringtone picker + preview engine. Defaults
  /// to a real [RingtoneChannel] in `initState`; the default is itself
  /// test-safe (every method no-ops off Android / without a native handler).
  final RingtoneChannel? ringtoneChannel;

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
  // THE lead time for a follows-rotation alarm in lead-time mode — what the
  // engine fires on, as-is (persisted to `relativeOffsetMinutes` on Save).
  // The old "Use default vs Custom" sub-toggle is gone: there is one duration
  // selector, seeded in `initState` from the global AlarmSettings.leadTime for
  // a new alarm (or the alarm's own offset in Edit Mode) so the starting value
  // still matches what Settings would have given.
  int _leadTimeMinutes = 60;
  // Timing mode for follows-rotation alarms. `false` (default) = Lead Time (fire
  // before the shift). `true` = Exact Time (fire at `_exactTimeMinutes` on the
  // shift's date, ignoring the lead). Only meaningful for follows-rotation.
  bool _isExactTime = false;
  // Exact fire clock (minute-of-day) when `_isExactTime` is on. Kept live across
  // mode flips like `_customOffsetMinutes`. Default 04:15 — a representative
  // pre-dawn shift-worker wake time the user can tweak.
  int _exactTimeMinutes = 4 * 60 + 15;
  // Critical-Shift wake mechanics (shake-to-dismiss + hold fail-safe).
  bool _isCriticalShift = false;
  // Bundled tone this alarm will ring (when no custom ringtone is set). The OS
  // plays it (per-tone channel / iOS sound).
  String _soundKey = kDefaultAlarmSoundKey;
  // Per-alarm custom ringtone DRAFT — migrated off the global AlarmSettings, so
  // every field here is local editor state written into the AppAlarm on Save.
  // Null URI + classic source ⇒ a bundled tone (`_soundKey`).
  String? _customRingtoneUri;
  String? _customRingtoneName;
  RingtoneSource _ringtoneSource = RingtoneSource.classic;
  // Selected ISO weekdays (1..7) for a weekly alarm. Empty until the user picks
  // days; a weekly alarm can't be saved while empty.
  final Set<int> _weekdays = <int>{};
  bool _saving = false;
  // True while the native preview MediaPlayer is looping the current ringtone
  // (the Phase-2a "Play Now" test harness). Toggled by the row's Play/Stop
  // button; the native player loops until explicitly stopped.
  bool _ringtonePreviewing = false;

  late final RingtoneChannel _ringtoneChannel;

  /// True when the sheet was opened to edit an existing alarm — drives the
  /// header copy and makes Save write back under the existing id.
  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _ringtoneChannel = widget.ringtoneChannel ?? RingtoneChannel();

    // Seed the duration selector from the global lead time (`read`, not
    // `watch` — a snapshot is right for a draft default). Edit Mode overrides
    // it below with the alarm's own offset; legacy records with a null offset
    // (the retired "track the global default" state) also land on the global
    // value, which is exactly what they fire on today.
    _leadTimeMinutes = context.read<AlarmSettings>().leadTime.inMinutes;

    // Edit Mode: pre-populate every field from the alarm being edited so the
    // user lands on its exact current state (label, sound, sliders, chips,
    // weekly days, toggles).
    final initial = widget.initial;
    if (initial != null) {
      _minutesOfDay = initial.minutesOfDay;
      _labelController.text = initial.label;
      _repeatType = initial.repeatType;
      _linkedShiftType = initial.linkedShiftType ?? ShiftType.day;
      _leadTimeMinutes = initial.relativeOffsetMinutes ?? _leadTimeMinutes;
      _isExactTime = initial.isExactTime;
      _exactTimeMinutes = initial.exactTimeMinutes ?? _exactTimeMinutes;
      _isCriticalShift = initial.isCriticalShift;
      _soundKey = initial.soundKey;
      _weekdays.addAll(weekdaysFromMask(initial.weekdaysBitmask));
      _customRingtoneUri = initial.customRingtoneUri;
      _customRingtoneName = initial.customRingtoneName;
      _ringtoneSource = initial.ringtoneSource;
    } else if (Hive.isBoxOpen('settings')) {
      // NEW alarm: start on the user's remembered default tone (the sound they
      // last chose), so their preference sticks without re-picking every time.
      final d = DefaultTonePrefs.read(Hive.box('settings'));
      _soundKey = d.soundKey;
      _ringtoneSource = d.source;
      _customRingtoneUri = d.uri;
      _customRingtoneName = d.name;
    }
  }

  @override
  void dispose() {
    // Never let a preview tone outlive the sheet. Fire-and-forget — the native
    // side releases the player; off-Android this is a no-op.
    _ringtoneChannel.stopPreview();
    _labelController.dispose();
    super.dispose();
  }

  /// Opens the ringtone-source chooser (bundled tones / Files / System Tone) and
  /// routes to the matching handler. Every option mutates LOCAL draft state (the
  /// custom ringtone is per-alarm now), written into the AppAlarm on Save.
  Future<void> _chooseRingtoneSource() async {
    // No custom override ⇒ tick the active bundled tone.
    final hasCustom = _customRingtoneName != null;
    // The chooser pops a String: 'tone:<key>' for a bundled tone, or 'files' /
    // 'system' for the two custom sources.
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        final accent = Theme.of(sheetCtx).colorScheme.primary;
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Your pick becomes the default for new alarms.',
                    style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(sheetCtx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                // Bundled tones — selecting one sets this alarm's soundKey.
                for (final s in kAlarmSounds)
                  ListTile(
                    key: ValueKey('ringtone-tone-${s.key}'),
                    leading: const Icon(Icons.music_note_outlined),
                    title: Text(s.label),
                    trailing: (!hasCustom && _soundKey == s.key)
                        ? Icon(Icons.check, color: accent)
                        : null,
                    onTap: () => Navigator.of(sheetCtx).pop('tone:${s.key}'),
                  ),
                // Both custom sources are hidden where they cannot ring. iOS
                // resolves a notification sound only from the app bundle or
                // Library/Sounds, so a picked file was silently swapped for the
                // bundled fallback at ring time — the worst kind of failure on
                // an alarm, since a user woken by a sound they don't recognise
                // may not react to it. It has no system-tone API at all.
                if (AlarmCapabilities.current.customTonePicker) ...[
                  const Divider(height: 1),
                  ListTile(
                    key: const ValueKey('ringtone-source-files'),
                    leading: const Icon(Icons.folder_open_outlined),
                    title: const Text('Select from Files'),
                    subtitle:
                        const Text('Pick an audio file saved on your device'),
                    onTap: () => Navigator.of(sheetCtx).pop('files'),
                  ),
                ],
                if (AlarmCapabilities.current.systemTonePicker)
                  ListTile(
                    key: const ValueKey('ringtone-source-system'),
                    leading: const Icon(Icons.library_music_outlined),
                    title: const Text('Select System Tone'),
                    subtitle:
                        const Text("Choose from your device's alarm sounds"),
                    onTap: () => Navigator.of(sheetCtx).pop('system'),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    if (choice == 'files') {
      await _pickVaultRingtone();
    } else if (choice == 'system') {
      await _pickSystemRingtone();
    } else if (choice.startsWith('tone:')) {
      await _useBundledTone(choice.substring(5));
    }
  }

  /// Vault source: open the audio file browser, copy the pick into durable
  /// app-private storage, and set the LOCAL draft (path + name + vault source).
  /// Cancelled picks are a no-op.
  Future<void> _pickVaultRingtone() async {
    // file_picker 11.x: `pickFiles` is a static on FilePicker. Audio-only. No
    // `context` is read here, so the awaits below can't strand a BuildContext.
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result == null || result.files.isEmpty) return; // cancelled
    final file = result.files.first;
    final srcPath = file.path;
    if (srcPath == null) return; // no usable path (shouldn't happen on mobile)
    // Drop the previous vault copy (if any) so re-picks don't accumulate files.
    await _maybeDeletePreviousVaultFile();
    // file_picker hands back a path in the app CACHE dir, which the OS can
    // purge at any time — copy into durable app-support storage and store THAT
    // path. Our own process always reads it back with no permission.
    final durablePath = await _persistRingtone(srcPath, file.name);
    if (!mounted) return;
    setState(() {
      _customRingtoneUri = durablePath;
      _customRingtoneName = file.name;
      _ringtoneSource = RingtoneSource.vault;
    });
  }

  /// System source: open the native `RingtoneManager` alarm-tone picker and set
  /// the LOCAL draft (content:// URI + title + system source). Cancelled picks
  /// (or non-Android, where the bridge returns null) are a no-op.
  Future<void> _pickSystemRingtone() async {
    final pick = await _ringtoneChannel.pickSystemRingtone(
      // Pre-select the current tone only when it's already a system tone.
      currentUri: _ringtoneSource == RingtoneSource.system
          ? _customRingtoneUri
          : null,
    );
    if (pick == null) return;
    await _maybeDeletePreviousVaultFile();
    if (!mounted) return;
    setState(() {
      _customRingtoneUri = pick.uri;
      _customRingtoneName = pick.title;
      _ringtoneSource = RingtoneSource.system;
    });
    // Remember this as the default so new alarms start on it. System tones have
    // a stable content:// URI, so they're safe to store as a shared default.
    await _rememberDefaultTone(
      source: RingtoneSource.system,
      uri: pick.uri,
      name: pick.title,
    );
  }

  /// Selects a BUNDLED tone for THIS alarm: sets [_soundKey] and resets the
  /// custom ringtone draft to classic (null URI/name), so the bundled tone
  /// actually rings (a non-classic source would route the alarm to the silent
  /// channel). Drops any previous vault copy.
  Future<void> _useBundledTone(String soundKey) async {
    await _maybeDeletePreviousVaultFile();
    if (!mounted) return;
    setState(() {
      _soundKey = soundKey;
      _customRingtoneUri = null;
      _customRingtoneName = null;
      _ringtoneSource = RingtoneSource.classic;
    });
    // Remember this bundled tone as the default for new alarms.
    await _rememberDefaultTone(
      source: RingtoneSource.classic,
      soundKey: soundKey,
    );
  }

  /// Persists the picked tone as the user's default (the tone new alarms start
  /// on). Only bundled + system tones are stored — a vault (file) tone is
  /// per-alarm, so it never becomes the shared default (see [DefaultTonePrefs]).
  Future<void> _rememberDefaultTone({
    required RingtoneSource source,
    String? soundKey,
    String? uri,
    String? name,
  }) async {
    if (!Hive.isBoxOpen('settings')) return;
    await DefaultTonePrefs.write(
      Hive.box('settings'),
      DefaultTone(
        soundKey: soundKey ?? _soundKey,
        source: source,
        uri: uri,
        name: name,
      ),
    );
  }

  /// Deletes the current draft's vault file if it is one — called before
  /// replacing it (re-pick / switch to system or bundled) so per-alarm vault
  /// copies don't accumulate. Best-effort; touches no `context`.
  Future<void> _maybeDeletePreviousVaultFile() async {
    if (_ringtoneSource != RingtoneSource.vault) return;
    final uri = _customRingtoneUri;
    if (uri == null) return;
    try {
      final f = File(uri);
      if (f.existsSync()) await f.delete();
    } catch (_) {
      // best-effort cleanup — a leftover file is harmless.
    }
  }

  /// Persists the global Vibrate toggle. Repo captured before the await so no
  /// `context` is used across the async gap.
  Future<void> _setVibration(bool enabled) async {
    final repo = context.read<AlarmSettingsRepository>();
    final current = await repo.read();
    await repo.write(current.copyWith(vibrationEnabled: enabled));
  }

  /// Play/Stop for the native preview engine. Plays THIS alarm's DRAFT custom
  /// tone through the Kotlin `MediaPlayer` (with its try/catch → classic
  /// fallback). Only shown when a custom tone is set (see build).
  Future<void> _toggleRingtonePreview() async {
    if (_ringtonePreviewing) {
      await _ringtoneChannel.stopPreview();
      if (mounted) setState(() => _ringtonePreviewing = false);
      return;
    }
    // Flip the icon immediately; the native player loops until Stop.
    setState(() => _ringtonePreviewing = true);
    await _ringtoneChannel.previewRingtone(
      source: _ringtoneSource,
      uri: _customRingtoneUri,
    );
  }

  /// Copies the picked audio file into `<app-support>/ringtones/` and returns
  /// the durable absolute path. Uses a UUID-prefixed filename (NOT a directory
  /// wipe) so MULTIPLE alarms' per-alarm tones coexist. The name is stripped of
  /// path separators and the payload delimiter (`|`) so the stored path is
  /// payload-safe.
  static Future<String> _persistRingtone(String srcPath, String name) async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}/ringtones');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final safeName = name.isEmpty
        ? 'ringtone'
        : name.replaceAll(RegExp(r'[\\/|]'), '_');
    final dest = File('${dir.path}/${_uuid.v4()}_$safeName');
    await File(srcPath).copy(dest.path);
    return dest.path;
  }

  Future<void> _pickTime() async {
    final picked = await pickPreferredTime(
      context,
      initialTime: TimeOfDay(
        hour: _minutesOfDay ~/ 60,
        minute: _minutesOfDay % 60,
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _minutesOfDay = picked.hour * 60 + picked.minute);
  }

  /// Exact-time picker for a follows-rotation alarm in [_isExactTime] mode. Like
  /// [_pickTime] it forces the tap-to-type number pad; the picked time becomes
  /// the alarm's absolute fire clock on each linked shift's date.
  Future<void> _pickExactTime() async {
    final picked = await pickPreferredTime(
      context,
      initialTime: TimeOfDay(
        hour: _exactTimeMinutes ~/ 60,
        minute: _exactTimeMinutes % 60,
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _exactTimeMinutes = picked.hour * 60 + picked.minute);
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
      // Lead-time mode persists the selected duration AS the alarm's absolute
      // lead — the engine fires `shiftStart − this`, no sub-modes. weekly /
      // oneTime alarms never carry an offset (they fire at minutesOfDay), and
      // exact-time alarms ignore the lead entirely, so force null in both
      // those cases.
      relativeOffsetMinutes:
          isFollowsRotation && !_isExactTime ? _leadTimeMinutes : null,
      // Exact-time mode + its absolute fire clock — follows-rotation only. weekly
      // / oneTime already fire at an absolute minutesOfDay, so they stay lead-
      // time-false with a null exact time.
      isExactTime: isFollowsRotation && _isExactTime,
      exactTimeMinutes:
          isFollowsRotation && _isExactTime ? _exactTimeMinutes : null,
      isCriticalShift: _isCriticalShift,
      soundKey: _soundKey,
      // Weekday mask only carries meaning for weekly alarms; force 0 otherwise
      // so flipping repeat type can't leave a stale day set behind.
      weekdaysBitmask: isWeekly ? weekdayMaskFromSet(_weekdays) : 0,
      // `autoDeleteAfterFiring` is intentionally left at its default (false):
      // one-time alarms now self-delete after firing BY DESIGN (see
      // `shouldDeleteAfterFiring`), so the field is no longer a user choice and
      // there's no UI for it.
      // Per-alarm custom ringtone draft → persisted on the alarm itself.
      customRingtoneUri: _customRingtoneUri,
      customRingtoneName: _customRingtoneName,
      ringtoneSource: _ringtoneSource,
      // ANCHOR a one-time alarm to the absolute instant it was set for. This is
      // the ONLY thing that lets a spent one-shot be recognised as spent —
      // `minutesOfDay` alone is a time of day, so the projection could only
      // ever roll it forward, turning a one-time alarm into a daily one. Null
      // for every other repeat type, including when EDITING an alarm away from
      // one-time, since this rebuilds the record from scratch.
      oneTimeFireAt: _repeatType == AppAlarmRepeatType.oneTime
          ? nextDailyOccurrence(_minutesOfDay, DateTime.now())
          : null,
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
        initialMinutes: _leadTimeMinutes,
        shiftStartMinutes: shiftStart,
        shiftLabel: shiftTypeLabel(_linkedShiftType),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _leadTimeMinutes = picked);
  }

  /// A weekly alarm with no day selected would never fire, so Save is blocked
  /// until at least one day is picked. Every other repeat type is always
  /// saveable.
  bool get _canSave =>
      _repeatType != AppAlarmRepeatType.weekly || _weekdays.isNotEmpty;

  /// The reveal beneath the Repeat selector, specific to the chosen repeat type:
  ///   * followsRotation → timing-mode toggle (Lead Time vs Exact Time) + the
  ///     mode's control + linked-shift picker;
  ///   * weekly → the Mon–Sun multi-select day chips;
  ///   * oneTime → nothing (no per-alarm options; it self-deletes after firing).
  Widget _buildRepeatReveal(ThemeData theme, bool use24Hour) {
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
                child: Text('Alarm timing', style: theme.textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              // Lead Time (fire BEFORE the shift, tracking it) vs Exact Time
              // (fire at a fixed clock on the shift's date). Exact mode is for
              // workers who want a fixed wake regardless of the global lead.
              SegmentedButton<bool>(
                key: const ValueKey('create-alarm-timing-mode'),
                segments: const [
                  ButtonSegment(value: false, label: Text('Lead time')),
                  ButtonSegment(value: true, label: Text('Exact time')),
                ],
                selected: {_isExactTime},
                onSelectionChanged: (s) =>
                    setState(() => _isExactTime = s.single),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 12),
              // Mode-specific control, one per mode. Exact → forced-numpad
              // time picker; Lead → a single duration selector (the old "Use
              // default vs Custom" sub-toggle was field-tested as redundant —
              // whatever duration sits here IS the alarm's lead time, full
              // stop). Both open via the slider dialog / numpad respectively.
              if (_isExactTime)
                OutlinedButton.icon(
                  key: const ValueKey('create-alarm-exact-time'),
                  onPressed: _pickExactTime,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    'Fires at '
                    '${formatClock(_exactTimeMinutes, use24Hour: use24Hour)}',
                  ),
                )
              else
                OutlinedButton.icon(
                  key: const ValueKey('create-alarm-lead-duration'),
                  onPressed: _pickRelativeOffset,
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(
                    '${formatLeadOffset(_leadTimeMinutes)} before shift start',
                  ),
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
        // No reveal: a one-time alarm has no per-alarm options. It self-deletes
        // after firing by design (see `shouldDeleteAfterFiring`), so there's no
        // "auto-delete" switch to show — a placebo toggle for behaviour the user
        // can't change.
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alarmSettings = context.watch<AlarmSettings>();
    // Audio summary for the Ringtone row — read from THIS alarm's local draft.
    // A custom ringtone (file / system tone) takes precedence and shows its
    // name; otherwise the row shows the selected BUNDLED tone label (Classic /
    // Siren / Digital / Chime). The presence of a custom NAME is the
    // discriminator, so a custom selection always wins the label.
    final hasCustomRingtone = _customRingtoneName != null;
    final ringtoneName =
        _customRingtoneName ?? resolveAlarmSound(_soundKey).label;
    // Roster shifts (streamed app-wide) let the hero show the REAL firing clock
    // time for the linked shift, not the bare offset. Empty/absent-of-type →
    // falls back to a per-type default so a clock always renders.
    final shifts = context.watch<List<Shift>>();
    final isFollowsRotation =
        _repeatType == AppAlarmRepeatType.followsRotation;
    final showLeadTime = isFollowsRotation;
    // The linked shift's start (from the roster) and the resulting fire clock
    // for lead-time mode — `shiftStart − _leadTimeMinutes`, exactly what Save
    // persists and the engine schedules.
    final shiftStart =
        resolveShiftStartMinutes(shifts, _linkedShiftType, now: DateTime.now());
    final fireClock = fireClockMinutes(shiftStart, _leadTimeMinutes);
    // Hero headline: the firing CLOCK time (AM/PM). One-time / weekly alarms
    // ring at their picked `minutesOfDay`; follows-rotation alarms ring either
    // the exact picked time (exact-time mode) or `shiftStart − lead` (lead-time
    // mode). The offset/mode detail is demoted to the caption below.
    final use24Hour = AppPreferences.use24HourOf(context);
    final heroClock = !showLeadTime
        ? formatClock(_minutesOfDay, use24Hour: use24Hour)
        : (_isExactTime
            ? formatClock(_exactTimeMinutes, use24Hour: use24Hour)
            : formatClock(fireClock, use24Hour: use24Hour));

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
            // Massive, easily-tappable hero — the FIRING CLOCK TIME (e.g.
            // "05:30 AM"). One-time / weekly → opens the time picker. Follows-
            // rotation: exact-time mode → opens the exact-time picker; lead-
            // time mode → opens the duration selector. The detail moves to the
            // caption below so the clock leads the hierarchy.
            InkWell(
              key: const ValueKey('create-alarm-time-tap'),
              onTap: !showLeadTime
                  ? _pickTime
                  : (_isExactTime ? _pickExactTime : _pickRelativeOffset),
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
            // Demoted timing caption. Lead-time mode: "1h 30m before Day
            // shifts". Exact-time mode: "Exact time · Day shifts". Follows-
            // rotation only — one-time/weekly alarms have no lead.
            if (showLeadTime)
              Text(
                _isExactTime
                    ? 'Exact time · '
                        '${shiftTypeLabel(_linkedShiftType)} shifts'
                    : '${formatLeadOffset(_leadTimeMinutes)} before '
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
            //
            // Hidden where the wake mechanic doesn't exist. On iOS the alarm is
            // a notification, so there is no surface to shake at and no hold
            // fail-safe; the toggle rendered and did nothing, while its subtitle
            // promised both. See [AlarmCapabilities].
            if (AlarmCapabilities.current.shakeToDismiss)
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
            // Audio — the SINGLE source of truth for this alarm's sound. Tapping
            // the name opens the source chooser (Files / System Tone / Rostrik
            // Classic); the Play/Stop button auditions the current tone through
            // the NATIVE engine (exercising the try/catch → classic fallback).
            // 'Rostrik Classic' is the bundled default; custom tones get wired
            // to fire-time playback in Phase 2b.
            Padding(
              key: const ValueKey('create-alarm-ringtone-row'),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      key: const ValueKey('create-alarm-ringtone-select'),
                      onTap: _chooseRingtoneSource,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
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
                    ),
                  ),
                  // Native preview is only meaningful for a CUSTOM tone (a
                  // file / system URI that should be auditioned via the native
                  // engine + fallback). Bundled tones are known-good and play
                  // through the OS channel, so the Play button is hidden for
                  // them rather than misleadingly previewing the classic tone.
                  if (hasCustomRingtone)
                    IconButton(
                      key: const ValueKey('create-alarm-ringtone-preview'),
                      onPressed: _toggleRingtonePreview,
                      tooltip: _ringtonePreviewing ? 'Stop' : 'Play',
                      icon: Icon(
                        _ringtonePreviewing
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            // Haptics — global, bound to AlarmSettings. Governs the continuous
            // native vibration for custom-ringtone alarms (bundled-tone alarms
            // keep their channel vibration, which Android binds immutably).
            SwitchListTile(
              key: const ValueKey('create-alarm-vibrate'),
              contentPadding: EdgeInsets.zero,
              value: alarmSettings.vibrationEnabled,
              onChanged: _setVibration,
              secondary: const Icon(Icons.vibration),
              title: const Text('Vibrate'),
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
              child: _buildRepeatReveal(theme, use24Hour),
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
