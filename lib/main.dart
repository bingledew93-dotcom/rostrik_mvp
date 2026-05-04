import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'alarms/alarm_engine.dart';
import 'alarms/local_notifications_alarm_scheduler.dart';
import 'data/storage/local_storage.dart';
import 'state/app_providers.dart';
import 'ui/roster_screen.dart';
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
///   2. Open Hive boxes — repositories required by the engine live here.
///   3. Init the OS scheduler (timezone DB, notification channel).
///   4. Request runtime permissions BEFORE the engine's first reconcile, so
///      anything the engine schedules can actually fire.
///   5. Start the engine: initial reconcile + subscribe to roster + settings
///      streams. Future roster edits or lead-time changes are now live.
///   6. runApp — UI is intentionally minimal in this V1 step.
///
/// `engine.stop()` is deliberately never called: the alarms are owned by
/// the OS's AlarmManager, not the Flutter process. Killing the engine on
/// app dispose would only stop reactive re-reconciliation, not the alarms
/// themselves — they keep firing whether the app is alive or not.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await LocalStorage.init();
  final scheduler = await LocalNotificationsAlarmScheduler.init();

  await _requestAlarmPermissions(scheduler);

  final engine = AlarmEngine(
    shifts: storage.shifts,
    alarmSettings: storage.alarmSettings,
    scheduler: scheduler,
    idMap: storage.notificationIds,
    clock: const SystemClock(),
  );
  await engine.start();

  // COLD-LAUNCH PATH: if the OS launched us via the alarm's full-screen-
  // intent (or via a tap on a still-pending notification), launch details
  // carry our "shiftId|notificationId" payload — route directly to
  // WakeUpScreen instead of RosterScreen.
  final launchPayload = await _readAlarmLaunchPayload(scheduler);

  // WARM-LAUNCH PATH: if the alarm fires while the app is already alive
  // (foreground or backgrounded), the OS brings MainActivity to front via
  // onNewIntent rather than re-running main(). MainActivity.kt extracts
  // the payload and calls "alarmFired" on this channel. We route through
  // the global navigator key, which works without a BuildContext.
  _alarmRoutingChannel.setMethodCallHandler((call) async {
    if (call.method == 'alarmFired' && call.arguments is String) {
      _routeToWakeUp(call.arguments as String);
    }
  });

  runApp(AppProviders(
    storage: storage,
    scheduler: scheduler,
    child: RostrikApp(alarmLaunchPayload: launchPayload),
  ));
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

/// Returns the payload string if the app was launched by one of our
/// alarm notifications, otherwise null.
Future<String?> _readAlarmLaunchPayload(
  LocalNotificationsAlarmScheduler scheduler,
) async {
  final details = await scheduler.getNotificationAppLaunchDetails();
  if (details == null || !details.didNotificationLaunchApp) return null;
  return details.notificationResponse?.payload;
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
  const RostrikApp({super.key, this.alarmLaunchPayload});

  /// "shiftId|notificationId" if the app was cold-launched by one of our
  /// alarm notifications. When non-null, the home route is the wake-up
  /// screen instead of the roster.
  final String? alarmLaunchPayload;

  @override
  Widget build(BuildContext context) {
    final wakeUp = _parseWakeUpRoute(alarmLaunchPayload);
    return MaterialApp(
      title: 'Rostrik',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: wakeUp ?? const RosterScreen(),
    );
  }
}

/// Parses the "shiftId|notificationId" payload into a WakeUpScreen, or
/// null if the payload is missing/malformed (in which case we just open
/// the normal roster).
Widget? _parseWakeUpRoute(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  final parts = payload.split('|');
  if (parts.isEmpty || parts[0].isEmpty) return null;
  final shiftId = parts[0];
  final notificationId =
      parts.length > 1 ? int.tryParse(parts[1]) : null;
  return WakeUpScreen(shiftId: shiftId, notificationId: notificationId);
}
