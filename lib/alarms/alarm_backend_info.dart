import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Which iOS alarm backend is actually serving alarms.
///
/// ## Why this is separate from `AlarmCapabilities`
///
/// They answer different questions. `AlarmCapabilities` describes what to show
/// the user, and on that score AlarmKit and notifications are identical: every
/// flag the UI consumes (`shakeToDismiss`, the tone pickers, `vibrationControl`)
/// is false on both. This describes what the *engine* may assume, where they
/// differ enormously — a 64-notification ceiling versus a measured ≥400 alarms,
/// a ~30s alert needing a repeat chain versus one that rings until dismissed.
///
/// Only the native side knows which backend initialised, so this is fed from
/// the `rostrik/native_alarms` channel rather than inferred from the platform.
///
/// ## Read synchronously, refreshed explicitly
///
/// `AlarmSyncService` needs the answer while computing a budget, deep inside a
/// reconcile — not somewhere it can await. So the value is cached and refreshed
/// at startup, in the foreground isolate and again in the headless background
/// one, each of which builds its own service.
///
/// The default is the CONSERVATIVE one. An unrefreshed reader assumes
/// notifications, which under-schedules on AlarmKit; assuming the reverse would
/// overshoot the notification ceiling, and iOS drops silently past 64 — alarms
/// that never ring, with no error anywhere.
class AlarmBackendInfo {
  const AlarmBackendInfo._();

  static bool _isAlarmKit = false;

  /// True when real alarms are being served by AlarmKit. Always false off iOS.
  static bool get isAlarmKit => _isAlarmKit;

  /// Asks the native side which backend is live. Safe to call anywhere: a
  /// missing channel (the wrong isolate, a widget test, Android) leaves the
  /// conservative default in place.
  static Future<void> refresh({
    MethodChannel channel = const MethodChannel('rostrik/native_alarms'),
  }) async {
    if (!_isIos) {
      _isAlarmKit = false;
      return;
    }
    try {
      final status =
          await channel.invokeMapMethod<String, dynamic>('alarmKitStatus');
      // `active`, not `enabled`: the former is what the native factory would
      // actually select, and they diverge when AlarmKit is preferred but not
      // yet authorised. Budgeting for AlarmKit while really running on
      // notifications would overshoot the 64-notification ceiling, which iOS
      // enforces by silently dropping the excess.
      _isAlarmKit = status?['active'] == true;
    } on MissingPluginException {
      _isAlarmKit = false;
    } on PlatformException {
      _isAlarmKit = false;
    }
  }

  /// Asks for AlarmKit authorisation when this device would use it but has not
  /// been granted it yet.
  ///
  /// **Runs in release builds**, unlike the bring-up diagnostics. AlarmKit's
  /// `schedule` never prompts on its own — it just throws — so without this the
  /// backend degrades to notifications forever and the user never sees the
  /// alarm the device is capable of. Must be called after the first frame, like
  /// every other permission on iOS: prompting before the UI is up deadlocks on
  /// the splash screen.
  static Future<void> requestAuthorizationIfNeeded({
    MethodChannel channel = const MethodChannel('rostrik/native_alarms'),
  }) async {
    if (!_isIos) return;
    try {
      final status =
          await channel.invokeMapMethod<String, dynamic>('alarmKitStatus');
      if (status == null) return;
      // Don't prompt on a device that cannot use it, or one deliberately
      // switched back to notifications — an unexplained permission dialog for a
      // capability the app is not going to use is worse than no dialog.
      if (status['available'] != true || status['enabled'] != true) return;
      if (status['authorized'] == true) return;
      await channel.invokeMethod<bool>('alarmKitAuthorize');
      await refresh(channel: channel);
    } on MissingPluginException {
      // Wrong isolate — the foreground one will ask.
    } on PlatformException {
      // A refused prompt is a result: the backend stays on notifications.
    }
  }

  static bool get _isIos {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false; // web, or no platform
    }
  }

  /// Pins the value for a test. Pass null to restore the default.
  @visibleForTesting
  static set debugOverride(bool? value) => _isAlarmKit = value ?? false;
}
