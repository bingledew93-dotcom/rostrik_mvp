import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'alarm_payload.dart';
import 'alarm_scheduler.dart';
import 'alarm_sound.dart';
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

// Channel-per-sound: Android binds a channel's sound IMMUTABLY at creation on
// API 26+ (`createNotificationChannel` is silently ignored once the ID exists),
// so a user-selectable tone is impossible to express on a single channel. We
// instead register ONE channel per bundled tone (`AlarmSound.androidChannelId`)
// and pick the matching channel at schedule time — see [buildAlarmNotificationDetails].
// All per-tone channels are nested under one [kAlarmChannelGroupId] group so
// system Settings shows a single tidy "Shift alarms" header instead of N rows.
//
// Legacy channel-ID lineage (each rename was forced by the same immutability —
// changing importance/sound/vibration/lockscreen-visibility required a fresh
// ID). All are deleted in `init()` so they don't linger in system Settings:
//   1. `rostrik_shift_alarms`         — initial channel, default OS sound
//   2. `rostrik_shift_alarms_silent`  — silent; audio handled in-UI (removed)
//   3. `rostrik_alarms_insistent`     — raw-resource sound + FLAG_INSISTENT
//   4. `rostrik_alarms_public`        — single channel, public lockscreen
//                                       visibility (the pre-tone design this
//                                       feature replaces — now RETIRED into the
//                                       cleanup list; its `classic_alarm` sound
//                                       lives on as the 'classic' tone channel).
const List<String> _legacyChannelIds = <String>[
  'rostrik_shift_alarms',
  'rostrik_shift_alarms_silent',
  'rostrik_alarms_insistent',
  'rostrik_alarms_public',
];

/// Android `Notification.FLAG_INSISTENT` = 4. Setting this on the
/// notification's flags causes the OS to loop the channel sound and
/// vibration pattern until the user dismisses the notification (or we
/// `cancel(notificationId)` it programmatically). This is what lets the
/// alarm keep ringing even when the device is awake and unlocked but the
/// app's WakeUpScreen has not opened — the "phone unlocked, you ignore
/// the alarm" case where the previous in-UI ringtone strategy failed.
const int _flagInsistent = 4;

/// Single SILENT channel for custom-ringtone alarms (Phase 2b, single-
/// notification architecture). It plays NO sound — the user's custom tone is
/// played by the native `MediaPlayer` that `WakeUpScreen` starts when the
/// FullScreenIntent launches it. Routing custom alarms here is what prevents
/// the bundled tone from ringing OVER the native custom audio. Vibration stays
/// on as a physical cue for the unlocked-active case (where the FSI only shows
/// a heads-up and `WakeUpScreen` never launches, so no custom audio plays).
/// Nested under the same [kAlarmChannelGroupId] group as the per-tone channels.
const String _silentAlarmChannelId = 'rostrik_alarm_custom_silent';
const String _silentAlarmChannelName = 'Custom ringtone alarms';

/// Constructs the [NotificationDetails] for a Rostrik alarm ringing the tone
/// identified by [soundKey] (an `AlarmSound.key`; unknown keys fall back to the
/// default via [resolveAlarmSound]).
///
/// Extracted to a top-level function so the main-isolate scheduler AND the
/// background-isolate snooze handler produce byte-identical notifications:
/// same channel selection, same FullScreenIntent, same action buttons, same
/// iOS category. Without this single source of truth a snoozed alarm could
/// silently lose its action buttons, full-screen behaviour, or its TONE — which
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
/// Audio model: the OS is the single source of alarm audio. The per-tone
/// Android channel ([AlarmSound.androidChannelId]) carries the looped sound
/// (API 26+ resolves sound at the channel layer); `playSound: true` +
/// `sound:` + `FLAG_INSISTENT` are mirrored on the details for pre-O fallback
/// and serialisation symmetry. On iOS the tone is the per-notification
/// `sound:` filename, resolved from `Library/Sounds/` (see
/// [installIosNotificationSounds]).
NotificationDetails buildAlarmNotificationDetails(
  String soundKey, {
  bool useSilentChannel = false,
}) {
  final sound = resolveAlarmSound(soundKey);
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
  // Shared across both channel variants: public lockscreen visibility so the
  // title/body AND the Snooze/Dismiss buttons render on the lockscreen (the
  // user can dismiss without authenticating — the action-button path bypasses
  // the keyguard via the broadcast receiver → background isolate).
  final actions = <AndroidNotificationAction>[
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
  ];

  // Custom-ringtone alarms (payload carried a customRingtoneUri) route to the
  // SILENT channel: no channel sound and NO FLAG_INSISTENT, because the native
  // MediaPlayer started by WakeUpScreen owns the looping custom audio. Bundled-
  // tone alarms keep the per-tone channel + FLAG_INSISTENT exactly as before.
  final androidDetails = useSilentChannel
      ? AndroidNotificationDetails(
          _silentAlarmChannelId,
          _silentAlarmChannelName,
          channelDescription: kAlarmChannelGroupDescription,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          // Still a full-screen intent — this is what launches WakeUpScreen,
          // which is what STARTS the native custom audio. Without FSI there'd
          // be no trigger for the tone in the single-notification design.
          fullScreenIntent: true,
          playSound: false,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          actions: actions,
        )
      : AndroidNotificationDetails(
          // Per-tone channel — the sound is bound here, immutably, by `init()`.
          sound.androidChannelId,
          sound.label,
          channelDescription: kAlarmChannelGroupDescription,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(sound.androidResource),
          // FLAG_INSISTENT (4) makes the channel sound and vibration LOOP
          // until the notification is dismissed. `Int32List.fromList` is the
          // wire type FLN's platform channel expects; the bare `<int>[4]`
          // would be serialised as a regular List<int> and silently ignored.
          additionalFlags: Int32List.fromList(<int>[_flagInsistent]),
          enableVibration: true,
          visibility: NotificationVisibility.public,
          actions: actions,
        );

  final iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
    // iOS resolves this filename in the app bundle AND Library/Sounds/ — the
    // latter is populated at startup by [installIosNotificationSounds], so no
    // Xcode bundle membership is required.
    sound: sound.iosSoundName,
    interruptionLevel: InterruptionLevel.timeSensitive,
    categoryIdentifier: alarmNotificationCategoryId,
  );

  return NotificationDetails(android: androidDetails, iOS: iosDetails);
}

/// Copies each bundled tone WAV from Flutter assets into the iOS app
/// container's `Library/Sounds/` directory, where `UNNotificationSound(named:)`
/// resolves notification sounds by filename. This is what lets
/// `DarwinNotificationDetails(sound: '<key>.wav')` work WITHOUT adding the
/// files to the Xcode/Runner bundle — critical for a Windows-only dev box.
///
/// No-op on every non-iOS platform (Android plays from `res/raw`). Idempotent:
/// each file is copied only if absent, so the cost after first launch is a few
/// `existsSync` checks. (A bundled-audio change in a future release would need
/// a forced refresh — e.g. keyed on app version — but the tone set is fixed for
/// the beta.) Best-effort per file: a missing/unreadable asset is logged and
/// skipped so one bad tone can't abort startup or the other tones.
Future<void> installIosNotificationSounds() async {
  if (!Platform.isIOS) return;

  final libraryDir = await getLibraryDirectory();
  final soundsDir = Directory('${libraryDir.path}/Sounds');
  if (!soundsDir.existsSync()) {
    soundsDir.createSync(recursive: true);
  }

  for (final sound in kAlarmSounds) {
    final dest = File('${soundsDir.path}/${sound.iosSoundName}');
    if (dest.existsSync()) continue;
    try {
      final data = await rootBundle.load(sound.assetPath);
      await dest.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      debugPrint('[ios-sounds] installed ${sound.iosSoundName}');
    } catch (e) {
      debugPrint('[ios-sounds] skipped ${sound.assetPath}: $e');
    }
  }
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
      await _registerAndroidChannels(androidImpl);
    }

    // iOS only: copy the bundled WAV assets into Library/Sounds so
    // DarwinNotificationDetails(sound:) can resolve them. No-op elsewhere.
    await installIosNotificationSounds();

    return LocalNotificationsAlarmScheduler._(plugin);
  }

  /// Registers the channel-per-sound topology and prunes the legacy single
  /// channels. `deleteNotificationChannel` / `createNotificationChannel` /
  /// `createNotificationChannelGroup` are all idempotent — a no-op on a fresh
  /// install and a one-shot reconcile on upgraded installs.
  static Future<void> _registerAndroidChannels(
    AndroidFlutterLocalNotificationsPlugin androidImpl,
  ) async {
    // Retire every legacy single-channel id (see `_legacyChannelIds`) so system
    // Settings doesn't show stale "Shift alarms" rows alongside the new
    // per-tone group. Idempotent if the channel never existed.
    for (final id in _legacyChannelIds) {
      await androidImpl.deleteNotificationChannel(channelId: id);
    }

    // One group nests all per-tone channels under a single header.
    await androidImpl.createNotificationChannelGroup(
      const AndroidNotificationChannelGroup(
        kAlarmChannelGroupId,
        kAlarmChannelGroupName,
        description: kAlarmChannelGroupDescription,
      ),
    );

    // One channel per tone — the sound is bound HERE, immutably (API 26+
    // resolves sound at the channel layer and ignores per-notification
    // overrides that disagree, so the matching `sound:` in
    // [buildAlarmNotificationDetails] is pre-O fallback + serialisation
    // symmetry). `createNotificationChannel` is silently ignored if the id
    // already exists, so a tone's sound is effectively write-once — adding a
    // NEW tone is fine, but CHANGING an existing tone's audio requires a new
    // channel id (the same discipline that produced `_legacyChannelIds`).
    //
    // NOTE: FLN's `AndroidNotificationChannel` exposes no lockscreen-visibility
    // param; the per-notification `visibility: NotificationVisibility.public`
    // in [buildAlarmNotificationDetails] surfaces the action buttons on the
    // lockscreen instead.
    for (final s in kAlarmSounds) {
      await androidImpl.createNotificationChannel(
        AndroidNotificationChannel(
          s.androidChannelId,
          s.label,
          description: kAlarmChannelGroupDescription,
          groupId: kAlarmChannelGroupId,
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(s.androidResource),
          enableVibration: true,
        ),
      );
    }

    // Silent channel for custom-ringtone alarms (single-notification Phase 2b):
    // NO sound (the native MediaPlayer that WakeUpScreen starts owns the custom
    // audio), vibration on as a physical cue. One shared channel under the same
    // group. `playSound: false` is bound immutably here, just like the per-tone
    // sounds above.
    await androidImpl.createNotificationChannel(
      const AndroidNotificationChannel(
        _silentAlarmChannelId,
        _silentAlarmChannelName,
        description: kAlarmChannelGroupDescription,
        groupId: kAlarmChannelGroupId,
        importance: Importance.max,
        playSound: false,
        enableVibration: true,
      ),
    );
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
    required String soundKey,
    String? payload,
  }) async {
    final tzFireAt = tz.TZDateTime.from(fireAt, tz.local);

    debugPrint(
      '[Scheduler.scheduleAt] id=$id '
      'fireAt=$fireAt → tz=$tzFireAt '
      '(zone=${tz.local.name}) '
      'title="$title" body="$body" sound="$soundKey" payload="$payload"',
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
      // Single source of truth: the payload's customRingtoneUri (encoded by
      // AlarmSyncService from the global AlarmSettings) decides whether this
      // alarm is custom. If so, route it to the SILENT channel so the bundled
      // tone doesn't play over the native audio WakeUpScreen will start — the
      // SAME payload also reaches WakeUpScreen, so the channel choice and the
      // wake-screen audio can never disagree. No reconcile/ledger change.
      notificationDetails: buildAlarmNotificationDetails(
        soundKey,
        useSilentChannel: AlarmPayload.decode(payload)?.customRingtoneUri != null,
      ),
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
