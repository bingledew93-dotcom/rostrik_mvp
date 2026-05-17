import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'alarm_scheduler.dart';
import 'notification_action_dispatcher.dart';
import 'notification_response_handler.dart';

// Stable identifiers shared by:
//   - this scheduler (attaches them to every alarm it schedules), and
//   - the (future) notification response handlers (dispatch on actionId).
// Top-level so handler files can import them without dragging in the
// scheduler class. The iOS `categoryIdentifier` matches the category
// registered in `init()` below; without that match iOS silently drops the
// action buttons.
const String alarmNotificationCategoryId = 'rostrik_alarm_category';
const String actionIdSnooze = 'action_snooze';
const String actionIdDismiss = 'action_dismiss';

// Channel constants are file-private (leading underscore = library-private
// in Dart) so both the class and the top-level [buildAlarmNotificationDetails]
// can reference them without duplication.
//
// Channel-ID lineage (each rename was forced by Android's hard cache of
// channel settings — `createNotificationChannel` is silently ignored when
// the ID already exists, so any change to importance/sound/vibration/
// lockscreen-visibility requires a new ID):
//   1. `rostrik_shift_alarms`         — initial channel, default OS sound
//   2. `rostrik_shift_alarms_silent`  — `playSound: false`, audio handled
//                                       by FlutterRingtonePlayer in the UI
//   3. `rostrik_alarms_insistent`     — native OS sound via raw resource
//                                       + FLAG_INSISTENT so audio loops
//                                       continuously even when UI can't
//                                       open (locked, killed). Ringtone
//                                       player removed.
//   4. `rostrik_alarms_public`        — CURRENT. Adds public lockscreen
//                                       visibility so Snooze/Dismiss
//                                       action buttons render on the
//                                       lockscreen and the user can
//                                       dismiss without unlocking.
//
// The orphan IDs above are deleted in `init()` so system Settings only
// shows one "Shift alarms" row. The user-facing NAME stays constant
// across renames so settings UX is unaffected.
const String _channelId = 'rostrik_alarms_public';
const String _channelName = 'Shift alarms';
const String _channelDescription =
    'Pre-shift wake-up alarms scheduled by Rostrik.';

/// Raw-resource sound file used by both the channel registration and the
/// per-notification details. Pointed at `android/app/src/main/res/raw/
/// classic_alarm.mp3` (Android resolves by name, no extension or path).
/// Centralised as a single const so the channel and the per-notification
/// details can't drift — Android resolves sound at the CHANNEL layer on
/// API 26+, but FLN serialises both, and they MUST match or the snoozed
/// reschedule path silently degrades to the system default tone.
const RawResourceAndroidNotificationSound _alarmTrack =
    RawResourceAndroidNotificationSound('classic_alarm');

/// Android `Notification.FLAG_INSISTENT` = 4. Setting this on the
/// notification's flags causes the OS to loop the channel sound and
/// vibration pattern until the user dismisses the notification (or we
/// `cancel(notificationId)` it programmatically). This is what lets the
/// alarm keep ringing even when the device is awake and unlocked but the
/// app's WakeUpScreen has not opened — the "phone unlocked, you ignore
/// the alarm" case where the previous in-UI ringtone strategy failed.
const int _flagInsistent = 4;

/// Constructs the [NotificationDetails] used for every Rostrik alarm.
///
/// Extracted to a top-level function so the main-isolate scheduler AND the
/// background-isolate snooze handler (Step 5) produce byte-identical
/// notifications: same channel, same FullScreenIntent, same action buttons,
/// same iOS category. Without this single source of truth a snoozed alarm
/// could silently lose its action buttons or full-screen behaviour, which
/// would only show up in the field.
///
/// Action buttons are configured with:
///   - `showsUserInterface: false` — tapping must NOT bring the app to the
///     foreground; the dispatch happens silently in the background isolate.
///   - `cancelNotification: true` — the OS dismisses the heads-up on tap.
///     This is what stops the FLAG_INSISTENT loop when the user taps
///     Snooze or Dismiss directly on the heads-up; without
///     `cancelNotification:true` the OS would keep looping the sound
///     even after the action handler ran.
///
/// Audio model: the OS is the single source of alarm audio. `playSound:
/// true` + `sound: _alarmTrack` + `FLAG_INSISTENT` (via `additionalFlags`)
/// tells Android to loop `res/raw/alarm_track.mp3` on the notification's
/// audio attributes (alarm category, max importance) until the user
/// dismisses the notification or `AlarmScheduler.cancel(id)` is called.
/// This works even when the screen is unlocked but the app is in the
/// background — the failure mode that motivated this refactor.
NotificationDetails buildAlarmNotificationDetails() {
  // The Snooze action button title reflects the user's current snooze
  // duration so the lock-screen affordance matches what'll actually
  // happen. Read at SCHEDULE time (this function runs once per scheduled
  // alarm), so a later setting change won't update already-pending
  // notifications — that's fine: AlarmEngine's next reconcile replaces
  // them, and a snooze tap reschedules via this same function. Both
  // isolates open the 'settings' box during their respective inits
  // (`main()` and `_ensureBackgroundIsolateInit`).
  final int snoozeMins =
      Hive.box('settings').get('snooze_duration', defaultValue: 1) as int;
  final androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDescription,
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: true,
    playSound: true,
    sound: _alarmTrack,
    // FLAG_INSISTENT (4) makes the channel sound and vibration LOOP
    // until the notification is dismissed. `Int32List.fromList` is the
    // wire type FLN's platform channel expects; the bare `<int>[4]`
    // would be serialised as a regular List<int> and silently ignored.
    additionalFlags: Int32List.fromList(<int>[_flagInsistent]),
    enableVibration: true,
    // Public lockscreen visibility — the title/body AND the Snooze/Dismiss
    // action buttons render on the lockscreen, so the user can dismiss
    // the alarm without authenticating. Android's secure-lockscreen
    // contract still gates the WakeUpScreen's slide-to-dismiss behind
    // auth, but the action-button path (broadcast receiver → background
    // isolate) bypasses that gate entirely. Shift type + start time are
    // low-sensitivity for this app's audience.
    visibility: NotificationVisibility.public,
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        actionIdSnooze,
        'Snooze ($snoozeMins min)',
        showsUserInterface: false,
        cancelNotification: true,
      ),
      const AndroidNotificationAction(
        actionIdDismiss,
        'Dismiss',
        showsUserInterface: false,
        cancelNotification: true,
      ),
    ],
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
    categoryIdentifier: alarmNotificationCategoryId,
  );

  return NotificationDetails(android: androidDetails, iOS: iosDetails);
}

/// Foreground notification-response callback. Runs in the main Dart isolate
/// when the app is alive (foreground OR backgrounded but not killed). Routes
/// through [NotificationActionDispatcher] so the live [ShiftRepository] and
/// [AlarmScheduler] handle the write/reschedule without re-opening Hive.
///
/// The dispatcher may be null in the brief window between `runApp` and
/// `NotificationActionDispatcher.setup(...)` in `main()` — a tap during
/// that window is silently dropped rather than crashing the isolate.
void _onForegroundResponse(NotificationResponse response) {
  final actionId = response.actionId;
  final payload = response.payload;
  final dispatcher = NotificationActionDispatcher.instance;
  debugPrint(
    '[fg] _onForegroundResponse '
    'actionId=$actionId payload=$payload '
    'dispatcher=${dispatcher == null ? "unset" : "ready"}',
  );
  if (dispatcher == null) return;

  if (actionId == actionIdSnooze && payload != null) {
    // Fire-and-forget. The response callback signature is `void` so we
    // cannot propagate the Future; the dispatcher logs its own errors.
    dispatcher.snooze(payload);
    return;
  }
  if (actionId == actionIdDismiss && payload != null) {
    dispatcher.dismiss(payload);
    return;
  }
  // actionId == null reaches us in two distinct shapes:
  //   - a genuine heads-up body tap, AND
  //   - the FSI activity launch itself, which FLN delivers via the same
  //     callback with no action id (the bug that caused us to mis-suppress
  //     WakeUpScreen pushes).
  // We can't reliably distinguish the two from here, so we let
  // MainActivity's native `alarmFired` MethodChannel broadcast be the
  // authoritative router. It will call `_routeToWakeUp` and push the
  // WakeUpScreen — which is what we want in both cases now that audio
  // is owned by the OS notification (FLAG_INSISTENT) rather than the UI.
  return;
}

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
    //
    // The iOS notification category MUST be registered here, not in
    // [DarwinNotificationDetails], because iOS resolves action buttons by
    // looking up the category by identifier at delivery time. The matching
    // `categoryIdentifier` is set on the per-notification details in
    // [buildAlarmNotificationDetails].
    // `DarwinNotificationAction.plain` is a non-const constructor in this
    // FLN version, so `iosInit` and the wrapping `InitializationSettings`
    // can't be `const`. That's fine — `init()` runs once at startup.
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          alarmNotificationCategoryId,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(actionIdSnooze, 'Snooze'),
            DarwinNotificationAction.plain(
              actionIdDismiss,
              'Dismiss',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.destructive,
              },
            ),
          ],
        ),
      ],
    );

    // Two callbacks, two isolates:
    //   - `onDidReceiveNotificationResponse` fires in the main Dart isolate
    //     when the app is alive (foreground OR backgrounded but not killed).
    //   - `onDidReceiveBackgroundNotificationResponse` fires in a SEPARATE
    //     Dart isolate when the app is killed or the OS spawns a callback
    //     dispatcher. That second callback MUST be a top-level / static
    //     function annotated `@pragma('vm:entry-point')` so AOT keeps it.
    await plugin.initialize(
      settings: InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    final androidImpl = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      // Clean up orphan channels from the lineage documented at the top
      // of this file. `deleteNotificationChannel` is idempotent — no-op
      // if the legacy channel never existed (fresh installs) — and a
      // one-shot delete on upgraded installs. Without this the user
      // would see multiple identical "Shift alarms" rows in system
      // Settings, each backed by a different (now-stale) sound config.
      await androidImpl
          .deleteNotificationChannel(channelId: 'rostrik_shift_alarms');
      await androidImpl
          .deleteNotificationChannel(channelId: 'rostrik_shift_alarms_silent');
      await androidImpl
          .deleteNotificationChannel(channelId: 'rostrik_alarms_insistent');

      // Channel-level sound + lockscreen visibility are the actual
      // switches — Android resolves sound, importance, vibration, AND
      // lockscreen content gating at the channel layer on API 26+ and
      // ignores per-notification overrides that disagree. The matching
      // values in [buildAlarmNotificationDetails] are kept for symmetry
      // (pre-O fallback + serialisation safety).
      // NOTE: FLN v21's `AndroidNotificationChannel` does NOT expose a
      // lockscreen-visibility constructor parameter (verified against
      // package source — the param set is limited to importance, sound,
      // vibration, lights, badge, audioAttributesUsage). The channel
      // therefore inherits the OS default, and the per-notification
      // `visibility: NotificationVisibility.public` flag in
      // [buildAlarmNotificationDetails] is what actually surfaces the
      // Snooze/Dismiss action buttons on the lockscreen. If a future
      // FLN release adds a channel-level visibility setter, mirror it
      // here for consistency.
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          sound: _alarmTrack,
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

    // zonedSchedule replaces an existing notification with the same id —
    // this is what satisfies the AlarmScheduler contract's "if id already
    // exists, replace it" without an explicit cancel-then-schedule dance.
    //
    // v18+ removed `uiLocalNotificationDateInterpretation`; iOS now always
    // treats TZDateTime as the absolute instant, which is what we want.
    //
    // Notification details come from the top-level [buildAlarmNotificationDetails]
    // so the (future) background-isolate snooze handler produces byte-identical
    // notifications when it reschedules — same channel, FullScreenIntent,
    // action buttons, iOS category.
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzFireAt,
      notificationDetails: buildAlarmNotificationDetails(),
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
