import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'alarms/alarm_sync_service.dart';
import 'alarms/local_notifications_alarm_scheduler.dart';
import 'alarms/notification_action_dispatcher.dart';
import 'data/storage/local_storage.dart';
import 'state/app_providers.dart';
import 'ui/main_layout.dart';
import 'ui/onboarding/onboarding_flow.dart';
import 'ui/wake_up_screen.dart';
import 'util/clock.dart';

/// Global Navigator handle. Used by the alarm-routing method channel to
/// push WakeUpScreen from a callback that has no BuildContext (the
/// channel handler runs at the top of the Flutter isolate, not inside
/// the widget tree).
final navigatorKey = GlobalKey<NavigatorState>();

/// Same channel name as MainActivity.kt's CHANNEL constant. Receives an
/// "alarmFired" call with the notification payload as the argument when
/// the OS routes a FullScreenIntent through onNewIntent.
const _alarmRoutingChannel = MethodChannel('rostrik/alarm_routing');

/// Bootstrap order is load-bearing:
///   1. Bind the Flutter engine.
///   2. Open Hive boxes — repositories required by the sync service live here.
///   3. Init the OS scheduler (timezone DB, notification channel, both
///      notification-response callbacks).
///   4. Request runtime permissions BEFORE the first sync, so anything the
///      sync service schedules can actually fire.
///   5. Start the AlarmSyncService: initial sync + subscribe to the
///      AppAlarmRepository AND ShiftCycleRepository streams. Future alarm
///      edits and roster generations are now live.
///   6. Install [NotificationActionDispatcher] — the bridge from the
///      foreground notification-response callback and the cold-launch
///      handler to the live `ShiftRepository`/`AlarmScheduler`/navigator.
///      Must happen BEFORE we read cold-launch details so any action
///      button dispatched on cold launch finds a live dispatcher.
///   7. Handle any cold-launch notification: dispatch action buttons if
///      present, never route to WakeUpScreen here (that path belongs to
///      the FullScreenIntent MethodChannel exclusively).
///   8. Wire the FullScreenIntent MethodChannel for warm-launch.
///   9. runApp — home is always MainLayout on cold launch; WakeUpScreen
///      is pushed on top by the FullScreenIntent path when applicable.
///
/// `syncService.stop()` is deliberately never called: the alarms are owned
/// by the OS's AlarmManager, not the Flutter process. Killing the service
/// on app dispose would only stop reactive re-syncing, not the alarms
/// themselves — they keep firing whether the app is alive or not.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await LocalStorage.init();
  // Generic key-value Hive box for app-wide preferences that don't warrant
  // their own typed repository (currently: `snooze_duration` minutes).
  // Opened here so every read site — SettingsScreen, the foreground
  // dispatcher, the WakeUpScreen, and the bg-isolate snooze handler when
  // it runs the slow path — can call `Hive.box('settings').get(...)`
  // without an async hop. The bg isolate has its own VM/Hive instance and
  // opens this box in `_ensureBackgroundIsolateInit`.
  await Hive.openBox('settings');
  final scheduler = await LocalNotificationsAlarmScheduler.init();

  await _requestAlarmPermissions(scheduler);

  // Phase 5 pivot: the shift-driven `AlarmEngine` is replaced by the
  // alarm-rule-driven `AlarmSyncService`. The service watches the
  // AppAlarmRepository AND the ShiftCycleRepository, recomputes the
  // desired set of OS alarms on every change (debounced), and lets the
  // scheduler replace/cancel idempotently. The engine class is kept in
  // the codebase for now so existing tests (and its concurrency /
  // debounce harnesses) still pass as documentation; nothing here
  // constructs it.
  final syncService = AlarmSyncService(
    alarms: storage.alarms,
    shifts: storage.shifts,
    cycles: storage.cycles,
    scheduler: scheduler,
    idMap: storage.notificationIds,
    clock: const SystemClock(),
  );
  await syncService.start();

  // Install the dispatcher BEFORE the cold-launch handler runs. The
  // dispatcher captures process-global references (shift repo, scheduler,
  // navigatorKey); installing it once here means both the foreground
  // notification-response callback in [LocalNotificationsAlarmScheduler]
  // and the cold-launch path below find a live dispatcher.
  NotificationActionDispatcher.setup(
    shifts: storage.shifts,
    scheduler: scheduler,
    navigatorKey: navigatorKey,
  );

  // Install the warm-launch handler FIRST so any `alarmFired` call
  // initiated from MainActivity.onNewIntent (rare during boot, but
  // possible if an alarm fires while main() is still running) is
  // captured rather than dropped.
  _alarmRoutingChannel.setMethodCallHandler((call) async {
    if (call.method != 'alarmFired' || call.arguments is! String) return;
    _routeToWakeUp(call.arguments as String);
  });

  // PULL the cold-launch FSI payload from MainActivity. Earlier
  // attempts pushed via `invokeMethod('alarmFired', ...)` from
  // `configureFlutterEngine`, but that fires before Dart `main()` runs,
  // so the call is dropped on the floor. Inverting the direction —
  // Kotlin buffers, Dart pulls when ready — makes the delivery
  // deterministic.
  //
  // Method name must exactly match MainActivity.METHOD_GET_INITIAL_PAYLOAD.
  final String? initialFsiPayload = await _alarmRoutingChannel
      .invokeMethod<String>('getInitialAlarmPayload');

  if (initialFsiPayload == null) {
    // No FSI cold-launch. Fall through to FLN's launch-details path,
    // which handles body taps (no-op routing — home is RosterScreen)
    // and defensively dispatches any action buttons that somehow
    // reached cold launch despite `showsUserInterface: false`.
    await _handleColdLaunchNotification(scheduler);
  } else {
    debugPrint(
      '[main] cold-launch FSI payload pulled — '
      'skipping FLN launch-details path: $initialFsiPayload',
    );
  }

  runApp(AppProviders(
    storage: storage,
    scheduler: scheduler,
    child: const RostrikApp(),
  ));

  // If we pulled an FSI payload, push WakeUpScreen on top of the
  // freshly-built RosterScreen home. The post-frame callback ensures
  // `navigatorKey.currentState` is attached before `_routeToWakeUp`
  // tries to use it — otherwise the push silently no-ops. From the
  // user's perspective the lock screen flashes RosterScreen for one
  // frame at most, which is invisible during the device wake animation.
  if (initialFsiPayload != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeToWakeUp(initialFsiPayload);
    });
  }
}

/// Pushes WakeUpScreen on top of whatever's currently on the navigator,
/// clearing the rest of the stack so back-button has nowhere to go (the
/// alarm IS the foreground task — escaping via back is the wrong
/// affordance). Slide-to-dismiss inside WakeUpScreen replaces itself
/// with RosterScreen on success, leaving a clean single-route stack.
void _routeToWakeUp(String payload) {
  final wakeUp = _parseWakeUpRoute(payload);
  if (wakeUp == null) return;
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => wakeUp),
    (_) => false,
  );
}

/// Cold-launch notification handler.
///
/// Called once during boot, after the dispatcher is installed. If the OS
/// launched the app from a notification, this:
///
///   - **Action button tap (Snooze / Dismiss).** In practice rare on cold
///     launch — both actions are `showsUserInterface: false`, so they fire
///     [notificationBackgroundHandler] in a separate isolate instead of
///     relaunching the app. The branch is kept for defensive correctness
///     on platforms / OEMs where the OS still surfaces the action via
///     launch details. Dispatched through the live
///     [NotificationActionDispatcher] so the action runs against the
///     in-memory repos (no Hive re-open, no tz re-init).
///   - **Body tap.** No state mutation required; the user just wants the
///     app open. Falls through — the home route is already RosterScreen.
///
/// Critically, **this function never routes to WakeUpScreen**. The
/// firing-alarm UI is owned exclusively by the FullScreenIntent
/// MethodChannel (`alarmFired`) path, which is wired separately in main().
Future<void> _handleColdLaunchNotification(
  LocalNotificationsAlarmScheduler scheduler,
) async {
  final details = await scheduler.getNotificationAppLaunchDetails();
  if (details == null || !details.didNotificationLaunchApp) return;

  final response = details.notificationResponse;
  if (response == null) return;

  final payload = response.payload;
  if (payload == null) return;

  switch (response.actionId) {
    case actionIdSnooze:
      await NotificationActionDispatcher.instance?.snooze(payload);
      break;
    case actionIdDismiss:
      await NotificationActionDispatcher.instance?.dismiss(payload);
      break;
    default:
      // Body tap (actionId == null) — no-op. Cold launch already lands on
      // RosterScreen so there's nothing to navigate.
      break;
  }
}

/// Two layers of permission requests on purpose:
///   - `permission_handler` for the cross-platform happy path.
///   - The plugin's own Android-specific calls as a fallback, because some
///     OEM ROMs ignore `permission_handler`'s POST_NOTIFICATIONS shortcut.
/// All calls are idempotent — the OS suppresses re-prompts after the user
/// has answered, so calling on every cold start is safe.
Future<void> _requestAlarmPermissions(
  LocalNotificationsAlarmScheduler scheduler,
) async {
  // Android 13+ runtime permission. No-op on iOS / older Android.
  await Permission.notification.request();

  // Android 12+ — required for setAlarmClock-quality scheduling. If denied,
  // flutter_local_notifications falls back to inexact mode; the engine
  // still works, alarms just lose their lock-screen "next alarm" treatment.
  // A future Settings screen can re-prompt; we don't block the app here.
  await Permission.scheduleExactAlarm.request();

  await scheduler.requestSystemPermissions();
}

class RostrikApp extends StatelessWidget {
  const RostrikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rostrik',
      navigatorKey: navigatorKey,
      // Forced dark mode: most app activity is around alarm-fire time
      // (early morning / late night) where dark is correct regardless
      // of OS setting. WakeUpScreen and the notification audio are
      // already calibrated for low-light. The `theme:` fallback below
      // is defensive — `themeMode: ThemeMode.dark` always picks
      // `darkTheme:` so the light theme is effectively unreachable.
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // First-launch gate: read the `onboarding_complete` flag from
      // the already-opened `settings` box. On a fresh install the key
      // is absent → default false → render OnboardingFlow. After the
      // user finishes onboarding, the flag flips to true and every
      // subsequent cold launch goes straight to MainLayout.
      //
      // The read is synchronous (the box is opened in `main()` before
      // `runApp`), so no FutureBuilder gymnastics — the right home is
      // known by the time MaterialApp builds.
      //
      // Cold launch always lands on either chassis. The FullScreenIntent
      // MethodChannel pushes WakeUpScreen on top via [_routeToWakeUp]
      // when applicable; heads-up body taps reach the same `alarmFired`
      // handler so they also end up on WakeUpScreen, which is the right
      // UX with the FLAG_INSISTENT audio model. (FSI routing during
      // onboarding is theoretically possible if an old alarm fires
      // during a re-onboarding — degraded but not broken; WakeUpScreen
      // just pushes over the onboarding stack.)
      home: Hive.box('settings').get(
        onboardingCompleteKey,
        defaultValue: false,
      ) as bool
          ? const MainLayout()
          : const OnboardingFlow(),
    );
  }
}

/// Parses the notification payload into a WakeUpScreen, or null if the
/// payload is missing/malformed (in which case we just open the normal
/// roster).
///
/// Payload contract: `<shiftId-or-'NONE'>|<notificationId>`.
///   * `shiftId` — a real Shift UUID for followsRotation alarms.
///   * `'NONE'`  — the sentinel for alarms with no linked shift
///                 (oneTime today; custom-repeat / bundles later).
///                 WakeUpScreen renders a generic "Alarm" title in
///                 this case without querying the ShiftRepository.
///   * `notificationId` — the OS notification id; parsed as int and
///                        used by WakeUpScreen to cancel the alarm on
///                        slide-to-dismiss / snooze.
Widget? _parseWakeUpRoute(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  final parts = payload.split('|');
  if (parts.isEmpty || parts[0].isEmpty) return null;
  // `shiftId` is either a real UUID or the 'NONE' sentinel — both
  // satisfy the non-empty check above. Validation of the shift's
  // existence is deferred to WakeUpScreen, which has the repository.
  final shiftId = parts[0];
  final notificationId =
      parts.length > 1 ? int.tryParse(parts[1]) : null;
  return WakeUpScreen(shiftId: shiftId, notificationId: notificationId);
}
