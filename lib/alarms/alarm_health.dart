import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Snapshot of the two runtime grants a ringing alarm cannot survive without
/// (audit F3). Both can silently disappear AFTER onboarding:
///
///   * **Notifications** — revocable any time on Android 13+/iOS. Without
///     them the full-screen-intent notification silently no-ops: the alarm
///     AUDIO still fires (the foreground service is independent), but there
///     is no wake screen and no visible way to dismiss — a screaming phone
///     until the 15-minute auto-timeout.
///   * **Exact alarms** — revocable ONLY on Android 12/12L (the manifest's
///     USE_EXACT_ALARM makes 13+ non-revocable). When revoked, every
///     `setAlarmClock` is refused (`EXACT_ALARM_DENIED`) and NOTHING is
///     armed — the engine stays honest and re-arms after a re-grant, but
///     until then the user must be told.
///
/// The Dashboard probes this on launch + every resume and surfaces a warning
/// banner while unhealthy — turning silent misconfiguration into a visible,
/// one-tap-fixable state instead of a missed shift.
class AlarmHealth {
  const AlarmHealth({
    required this.notificationsEnabled,
    required this.exactAlarmsAllowed,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsAllowed;

  bool get ok => notificationsEnabled && exactAlarmsAllowed;

  /// The "everything fine" snapshot — also the defensive fallback when no
  /// platform is available (widget tests), so a probe failure can never
  /// flash a false warning.
  static const AlarmHealth healthy = AlarmHealth(
    notificationsEnabled: true,
    exactAlarmsAllowed: true,
  );
}

/// Injection point for the Dashboard: production passes [probeAlarmHealth];
/// tests inject a canned snapshot.
typedef AlarmHealthProbe = Future<AlarmHealth> Function();

/// Reads the live permission state via `permission_handler`. Best-effort:
/// any channel failure reads as [AlarmHealth.healthy] rather than throwing —
/// this runs on the Dashboard build path and must never break the home
/// screen (or show a warning it can't substantiate).
Future<AlarmHealth> probeAlarmHealth() async {
  try {
    // Maps to `areNotificationsEnabled()` on Android (covers both the 13+
    // runtime denial AND the app-level notification toggle) and the
    // authorization status on iOS.
    final notifications = await Permission.notification.status;

    // Exact alarms are an Android-only concept; on 13+ USE_EXACT_ALARM reads
    // granted and can't be revoked, so this effectively guards the 12/12L
    // "Alarms & reminders" toggle.
    var exactAllowed = true;
    if (!kIsWeb && Platform.isAndroid) {
      exactAllowed = (await Permission.scheduleExactAlarm.status).isGranted;
    }

    return AlarmHealth(
      notificationsEnabled: notifications.isGranted,
      exactAlarmsAllowed: exactAllowed,
    );
  } catch (_) {
    return AlarmHealth.healthy; // no platform (tests) — never a false alarm
  }
}

/// Notifications fix path: the app's system settings page (the notification
/// toggle lives there, not behind a re-requestable runtime prompt once the
/// user has denied it). Best-effort — a channel miss is a silent no-op.
Future<void> openNotificationSettings() async {
  try {
    await openAppSettings();
  } catch (_) {
    // No platform / no settings surface — nothing else to do.
  }
}

/// Exact-alarm fix path: launches the system "Alarms & reminders" special
/// access screen (ACTION_REQUEST_SCHEDULE_EXACT_ALARM under the hood).
/// Best-effort, Android-only by nature.
Future<void> requestExactAlarmPermission() async {
  try {
    await Permission.scheduleExactAlarm.request();
  } catch (_) {
    // No platform — nothing else to do.
  }
}
