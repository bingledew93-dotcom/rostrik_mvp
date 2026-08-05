import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'native_alarm_scheduler.dart' show NativeAlarmScheduler;

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

/// Wire method on the `rostrik/native_alarms` channel answering
/// `AlarmManager.canScheduleExactAlarms()` — MUST match
/// `NativeAlarmScheduling.METHOD_CAN_SCHEDULE_EXACT`.
const String _methodCanScheduleExact = 'canScheduleExactAlarms';

/// Reads the live grant state. Per-check best-effort: a channel failure on
/// either probe reads as healthy for THAT check rather than throwing — this
/// runs on the Dashboard build path and must never break the home screen (or
/// show a warning it can't substantiate).
///
/// The exact-alarm check deliberately asks OUR native channel — the same
/// AlarmManager the scheduler talks to — and NOT
/// `Permission.scheduleExactAlarm.status`. Field bug (Pixel 9 XL, Android 16):
/// permission_handler resolves that group via the MANIFEST declaration first,
/// and since SCHEDULE_EXACT_ALARM is capped at maxSdkVersion=32 (the Google-
/// documented pattern when USE_EXACT_ALARM is declared), the lookup comes back
/// empty on 13+ and the plugin reports "denied" without ever consulting
/// `canScheduleExactAlarms()` — a false banner while the OS happily arms
/// exact alarms. On iOS the channel has no handler → healthy, correct (exact
/// alarms are an Android-only concept).
Future<AlarmHealth> probeAlarmHealth() async {
  // Maps to `areNotificationsEnabled()` on Android (covers both the 13+
  // runtime denial AND the app-level notification toggle) and the
  // authorization status on iOS.
  var notificationsEnabled = true;
  try {
    notificationsEnabled = (await Permission.notification.status).isGranted;
  } catch (_) {
    // No platform (tests) — never a false alarm.
  }

  return AlarmHealth(
    notificationsEnabled: notificationsEnabled,
    exactAlarmsAllowed: await exactAlarmsAllowedNow(),
  );
}

/// The live OS answer for "can this app arm exact alarms right now" —
/// `AlarmManager.canScheduleExactAlarms()` via our native channel. Shared by
/// [probeAlarmHealth] (Dashboard banner) and the onboarding permissions
/// screen's Exact Alarms tile, both of which previously read
/// `Permission.scheduleExactAlarm.status` and got permission_handler's false
/// manifest-based "denied" on Android 13+ (the tile showed a dead, un-flippable
/// switch). Best-effort: no handler (iOS / tests) or a channel error reads as
/// allowed — exactness isn't a concept there, and a warning we can't
/// substantiate must never show.
/// TESTING NOTE: on a real device this call always resolves — Android
/// registers the handler before any Dart runs, and iOS replies
/// not-implemented (→ caught → true). Under the widget-test harness a
/// NEVER-mocked channel neither answers nor throws (the message sits in
/// ChannelBuffers forever), so any test that pumps a widget calling this
/// must mock the `rostrik/native_alarms` channel or inject a probe —
/// otherwise the await strands the caller mid-function.
Future<bool> exactAlarmsAllowedNow() async {
  try {
    return await const MethodChannel(NativeAlarmScheduler.channelName)
            .invokeMethod<bool>(_methodCanScheduleExact) ??
        true;
  } catch (_) {
    return true;
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
