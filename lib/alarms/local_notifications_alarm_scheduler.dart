import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'alarm_scheduler.dart';

/// Production [AlarmScheduler] backed by `flutter_local_notifications`.
///
/// This is the **only** file in the codebase that imports
/// `flutter_local_notifications`, `flutter_timezone`, or `timezone` —
/// everything else talks to the [AlarmScheduler] interface so reconciliation
/// logic stays testable with `FakeAlarmScheduler`.
///
/// Scheduling mode is [AndroidScheduleMode.alarmClock], which delegates to
/// `AlarmManager.setAlarmClock` under the hood. This is what gives us:
///   - Doze / battery-optimization bypass without `USE_EXACT_ALARM`.
///   - A visible "next alarm" indicator on the lock screen.
///   - Reliable wake-up even on aggressive OEM ROMs.
///
/// On iOS the `zonedSchedule` call still applies — DST-correct because
/// `tz.local` is set from the device's IANA zone via `flutter_timezone`.
class LocalNotificationsAlarmScheduler implements AlarmScheduler {
  LocalNotificationsAlarmScheduler._(this._plugin);

  static const String _channelId = 'rostrik_shift_alarms';
  static const String _channelName = 'Shift alarms';
  static const String _channelDescription =
      'Pre-shift wake-up alarms scheduled by Rostrik.';

  final FlutterLocalNotificationsPlugin _plugin;

  /// Initializes the timezone DB, picks the device's local zone, configures
  /// the notification channel, and returns a ready-to-use scheduler.
  ///
  /// Safe to call once at startup. Calling more than once is harmless but
  /// pointless — `flutter_local_notifications` is itself a singleton.
  static Future<LocalNotificationsAlarmScheduler> init() async {
    tz_data.initializeTimeZones();
    // flutter_timezone v5 returns TimezoneInfo (was a raw String in v3).
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    final plugin = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Don't auto-prompt at plugin init — main() drives permission requests
    // explicitly via permission_handler so the order is predictable.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await plugin.initialize(
      settings:
          const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidImpl = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    return LocalNotificationsAlarmScheduler._(plugin);
  }

  /// Asks the OS for notification + exact-alarm permission. Idempotent —
  /// the OS suppresses re-prompts after the user has answered. Belt-and-
  /// braces alongside `permission_handler` in `main()`.
  Future<void> requestSystemPermissions() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
    }
  }

  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime fireAt,
    required String title,
    required String body,
    String? payload,
  }) async {
    final tzFireAt = tz.TZDateTime.from(fireAt, tz.local);

    debugPrint(
      '[Scheduler.scheduleAt] id=$id '
      'fireAt=$fireAt → tz=$tzFireAt '
      '(zone=${tz.local.name}) '
      'title="$title" body="$body" payload="$payload"',
    );

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    // zonedSchedule replaces an existing notification with the same id —
    // this is what satisfies the AlarmScheduler contract's "if id already
    // exists, replace it" without an explicit cancel-then-schedule dance.
    //
    // v18+ removed `uiLocalNotificationDateInterpretation`; iOS now always
    // treats TZDateTime as the absolute instant, which is what we want.
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzFireAt,
      notificationDetails:
          const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: payload,
    );
  }

  /// Returns the launch details if the app was started by tapping (or
  /// being launched via FullScreenIntent of) one of our notifications.
  /// Used by `main()` to route to [WakeUpScreen] on cold start.
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() =>
      _plugin.getNotificationAppLaunchDetails();

  @override
  Future<void> cancel(int id) {
    debugPrint('[Scheduler.cancel] id=$id');
    return _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() {
    debugPrint('[Scheduler.cancelAll]');
    return _plugin.cancelAll();
  }

  @override
  Future<Set<int>> pendingIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    final ids = pending.map((p) => p.id).toSet();
    debugPrint('[Scheduler.pendingIds] count=${ids.length} ids=$ids');
    return ids;
  }
}
