import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// What the alarm stack can actually deliver on the device in front of the
/// user — the single source of truth the UI consults before offering a control.
///
/// ## Why this exists
///
/// Rostrik's alarm engine is Android-native and iOS gets a genuinely weaker
/// substitute. Left unstated, that difference leaked into the UI as controls
/// that rendered fine and silently did nothing: a "Critical shift" toggle
/// advertising a shake gesture iOS has no way to detect during an alarm, an
/// onboarding lesson *teaching* that gesture, a system-tone picker with no iOS
/// API behind it, and a custom-tone picker whose choice was quietly replaced by
/// a bundled tone at ring time.
///
/// A control that does nothing is worse than an absent one, and on an alarm app
/// it is worse again: someone who picks a distinctive tone and is then woken by
/// a different sound may not register it as their alarm at all.
///
/// The rule this encodes:
///   * **never available on this platform → hide it.** Don't tease something
///     the user cannot have.
///   * **available on a newer OS they could plausibly reach → disable it and
///     say so** ("Requires iOS 26"). Nothing needs this yet; it becomes real
///     when AlarmKit lands.
///
/// ## Why Dart-side, for now
///
/// Every distinction here is currently platform-level, and iOS always runs the
/// notification backend, so `Platform` answers every question correctly. Once
/// `AlarmKitBackend` ships, "which backend actually initialised" becomes a
/// runtime fact only the native side knows — at that point [current] should be
/// fed from the `rostrik/native_alarms` channel instead of computed here. The
/// call sites do not change: they already ask this object, not the platform.
@immutable
class AlarmCapabilities {
  const AlarmCapabilities({
    required this.shakeToDismiss,
    required this.customTonePicker,
    required this.systemTonePicker,
    required this.soundBeyondThirtySeconds,
    required this.piercesSilentSwitch,
    required this.fullScreenAlarm,
  });

  /// Sustained shake (and its 3-second hold fail-safe) can dismiss a firing
  /// alarm. Requires owning the wake surface, which only Android does.
  final bool shakeToDismiss;

  /// A user-chosen audio file can actually ring. iOS plays notification sounds
  /// only from its bundle or `Library/Sounds`, so a picked file is silently
  /// replaced by the bundled fallback — the picker promises what it cannot do.
  final bool customTonePicker;

  /// The OS exposes a system ringtone picker. Android has `RingtoneManager`;
  /// iOS has no public API at all.
  final bool systemTonePicker;

  /// Alarm audio can run past ~30s. iOS notification sounds are hard-capped.
  final bool soundBeyondThirtySeconds;

  /// The alarm is heard through the ring/silent switch and Focus modes.
  final bool piercesSilentSwitch;

  /// A full-screen wake surface is drawn over the lock screen.
  final bool fullScreenAlarm;

  /// The native Android stack: `AlarmManager` → `AlarmReceiver` → foreground
  /// audio service → full-screen `AlarmActivity`. Everything is available.
  static const android = AlarmCapabilities(
    shakeToDismiss: true,
    customTonePicker: true,
    systemTonePicker: true,
    soundBeyondThirtySeconds: true,
    piercesSilentSwitch: true,
    fullScreenAlarm: true,
  );

  /// iOS via `UNUserNotificationCenter` — today's only iOS path. The honest
  /// floor: a time-sensitive notification with a bundled sound, capped at ~30s,
  /// silenced by the ring switch, with no wake surface of our own.
  ///
  /// `soundBeyondThirtySeconds` and `piercesSilentSwitch` flip to true under
  /// AlarmKit (iOS 26+); `shakeToDismiss` and the tone pickers never do, since
  /// AlarmKit presents its own system UI and iOS still has no arbitrary-file
  /// notification sound.
  static const iosNotification = AlarmCapabilities(
    shakeToDismiss: false,
    customTonePicker: false,
    systemTonePicker: false,
    soundBeyondThirtySeconds: false,
    piercesSilentSwitch: false,
    fullScreenAlarm: false,
  );

  static AlarmCapabilities? _override;

  /// Capabilities of the running device. Defaults to [android] off-iOS so
  /// desktop and widget tests keep the full-featured UI they already assert on.
  static AlarmCapabilities get current {
    if (_override != null) return _override!;
    try {
      return Platform.isIOS ? iosNotification : android;
    } catch (_) {
      return android; // no platform (web) — nothing here is web-facing
    }
  }

  /// Pins [current] for a test. Pass null to restore platform detection.
  @visibleForTesting
  static set debugOverride(AlarmCapabilities? value) => _override = value;
}
