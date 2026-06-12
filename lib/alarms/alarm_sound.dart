/// Catalog of the app's **bundled** alarm tones — the single source of truth
/// shared by every layer that touches alarm audio:
///
///   * `LocalNotificationsAlarmScheduler.init` — registers one Android
///     notification channel per tone (the channel-per-sound pattern, forced by
///     Android API 26+ binding a channel's sound immutably at creation) and
///     copies the WAVs into the iOS `Library/Sounds` folder at startup.
///   * `buildAlarmNotificationDetails(soundKey)` — selects the channel +
///     iOS sound filename for a firing alarm.
///   * The create/edit sheet's tone selector (Ringtone row).
///   * `AlarmPayload` — the chosen tone rides the notification payload so the
///     killed-app snooze reschedule keeps it.
///
/// **Audio ownership:** the OS plays alarm audio (Android channel sound looped
/// by FLAG_INSISTENT; iOS notification sound), NOT the Flutter UI. The app only
/// *selects* which OS resource to use. The sole in-process player is the
/// native Kotlin `MediaPlayer` behind `RingtoneChannel` (custom-tone preview +
/// fire-time playback) — there is no Flutter-side audio engine.
///
/// **Format (Option 1, WAV-everywhere):** every tone is a 16-bit PCM WAV at
/// 44.1 kHz, present in two places — see `assets/sounds/README.md`:
///   * `assets/sounds/<key>.wav` — the master, copied to iOS `Library/Sounds`
///     at runtime.
///   * `android/app/src/main/res/raw/<androidResource>.wav` — the Android
///     notification-channel sound (resolved by name, no extension).
library;

/// Key persisted in [AppAlarm.soundKey] and carried in the notification
/// payload when an alarm has no explicit tone (legacy records, and the
/// default for new alarms). MUST equal `kAlarmSounds.first.key`.
const String kDefaultAlarmSoundKey = 'classic';

/// Android `NotificationChannelGroup` that nests every per-tone channel under
/// one "Shift alarms" header in system Settings — so the channel-per-sound
/// pattern shows as a single tidy group rather than N identical rows.
const String kAlarmChannelGroupId = 'rostrik_alarm_sounds';
const String kAlarmChannelGroupName = 'Shift alarms';
const String kAlarmChannelGroupDescription =
    'Pre-shift wake-up alarms scheduled by Rostrik.';

/// One selectable bundled tone. Immutable, const-constructed in [kAlarmSounds].
class AlarmSound {
  const AlarmSound({
    required this.key,
    required this.label,
    required this.assetPath,
    required this.androidResource,
    required this.androidChannelId,
  });

  /// Stable identifier persisted in [AppAlarm.soundKey] and embedded in the
  /// notification payload. MUST be `|`-free (the payload delimiter) and stable
  /// across releases — renaming a key orphans existing alarms onto the default.
  final String key;

  /// User-facing tone name shown in the picker and used as the Android channel
  /// name (under the [kAlarmChannelGroupName] group).
  final String label;

  /// Full Flutter asset path (`assets/sounds/<key>.wav`). Used by
  /// `rootBundle.load` for the iOS `Library/Sounds` copy.
  final String assetPath;

  /// `res/raw` resource name on Android, WITHOUT extension or path — Android
  /// resolves `RawResourceAndroidNotificationSound` by bare name.
  final String androidResource;

  /// Distinct Android notification channel for this tone. The sound is bound
  /// to the channel at creation and is immutable, so each tone needs its own.
  final String androidChannelId;

  /// iOS notification sound filename — the asset's basename. Lives in the
  /// app container's `Library/Sounds/` folder (populated at startup), which
  /// `UNNotificationSound(named:)` searches, so no Xcode bundle membership is
  /// needed.
  String get iosSoundName => assetPath.split('/').last;
}

/// The beta tone catalog. The FIRST entry is the default and MUST match
/// [kDefaultAlarmSoundKey] — [resolveAlarmSound] falls back to it.
const List<AlarmSound> kAlarmSounds = <AlarmSound>[
  AlarmSound(
    key: 'classic',
    label: 'Classic',
    assetPath: 'assets/sounds/classic.wav',
    androidResource: 'classic_alarm',
    androidChannelId: 'rostrik_alarm_classic',
  ),
  AlarmSound(
    key: 'siren',
    label: 'Siren',
    assetPath: 'assets/sounds/siren.wav',
    androidResource: 'siren',
    androidChannelId: 'rostrik_alarm_siren',
  ),
  AlarmSound(
    key: 'digital',
    label: 'Digital',
    assetPath: 'assets/sounds/digital.wav',
    androidResource: 'digital',
    androidChannelId: 'rostrik_alarm_digital',
  ),
  AlarmSound(
    key: 'chime',
    label: 'Chime',
    assetPath: 'assets/sounds/chime.wav',
    androidResource: 'chime',
    androidChannelId: 'rostrik_alarm_chime',
  ),
];

/// Resolves a persisted/payload [key] to its [AlarmSound], falling back to the
/// default tone for an unknown key (e.g. an alarm created on a build that
/// shipped a tone later removed). Never throws — a missing tone must degrade
/// to "rings with the default sound", never to "no alarm".
AlarmSound resolveAlarmSound(String key) {
  for (final sound in kAlarmSounds) {
    if (sound.key == key) return sound;
  }
  return kAlarmSounds.first;
}
