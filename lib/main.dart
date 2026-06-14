import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarms/alarm_payload.dart';
import 'alarms/alarm_sync_service.dart';
import 'alarms/local_notifications_alarm_scheduler.dart';
import 'alarms/notification_action_dispatcher.dart';
import 'alarms/pending_dismissal_guard.dart';
import 'data/repositories/shift_repository.dart';
import 'data/storage/local_storage.dart';
import 'legal/legal.dart';
import 'logic/adhoc_archive.dart';
import 'state/app_preferences.dart';
import 'state/app_providers.dart';
import 'ui/app_theme.dart';
import 'ui/legal_consent_screen.dart';
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

  // Strict portrait lock. The roster/alarm/review UIs are laid out portrait-
  // only and overflow (the yellow/black hazard tape) in landscape. Setting
  // this before runApp means the app never renders rotated. portraitUp only —
  // not portraitDown — so it can't flip upside-down either.
  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp],
  );

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

  // NATIVE DISMISS FAIL-SAFE — replay killed-app dismissals from the
  // Kotlin-readable ledger into Hive BEFORE the first reconcile and before
  // any wake routing. Pixel-9-class battery management can reap the
  // background isolate before its Hive write lands; the ledger (written by
  // that isolate's first instruction, kernel-synchronous) is the surviving
  // record. Replaying here means the sync service's initial reconcile sees
  // `isAcknowledged` and tears down any stale OS entry in the same boot.
  await _syncNativePendingDismissals(storage.shifts);

  // SELF-CLEANING AD-HOC SHIFTS — archive (NEVER delete) any one-off shift
  // whose end is >24h past, keeping the active roster/alarm set lean as
  // one-offs accumulate. Runs before the first reconcile; archived shifts are
  // already behind the engine's future-fire gate, so this can never disarm a
  // live alarm. The Shift record stays in Hive for the historical calendar
  // (the payslip-verification record) — only `isArchived` is flipped.
  await archiveExpiredAdHocShifts(storage.shifts, now: DateTime.now());

  await _requestAlarmPermissions(scheduler);

  // Alarm-rule-driven scheduling. AlarmSyncService watches the AppAlarm,
  // ShiftCycle, in-horizon Shift, AND AlarmSettings streams, recomputes the
  // desired set of OS alarms on every change (debounced), and lets the
  // scheduler replace/cancel idempotently. (The shift-centric AlarmEngine that
  // preceded it was deleted once this fully subsumed it.)
  final syncService = AlarmSyncService(
    alarms: storage.alarms,
    shifts: storage.shifts,
    cycles: storage.cycles,
    alarmSettings: storage.alarmSettings,
    scheduler: scheduler,
    idMap: storage.notificationIds,
    clock: const SystemClock(),
  );
  await syncService.start();

  // Holiday Mode wiring: the engine reads the pause flag fresh on each sync,
  // but a toggle must IMMEDIATELY re-reconcile — disarm (cancel every pending
  // OS alarm) when switched on, restore from the untouched roster when off.
  // Scoped to the pause key so the engine's own scheduled-fire-at writes to
  // this box don't feed back into a sync loop.
  Hive.box('settings')
      .listenable(keys: const <String>[isSchedulePausedKey])
      .addListener(syncService.syncAlarms);

  // Install the dispatcher BEFORE the cold-launch handler runs. The
  // dispatcher captures process-global references (shift repo, scheduler,
  // navigatorKey); installing it once here means both the foreground
  // notification-response callback in [LocalNotificationsAlarmScheduler]
  // and the cold-launch path below find a live dispatcher.
  NotificationActionDispatcher.setup(
    shifts: storage.shifts,
    alarms: storage.alarms,
    scheduler: scheduler,
    navigatorKey: navigatorKey,
  );

  // Install the warm-launch handler FIRST so any `alarmFired` call
  // initiated from MainActivity.onNewIntent (rare during boot, but
  // possible if an alarm fires while main() is still running) is
  // captured rather than dropped.
  _alarmRoutingChannel.setMethodCallHandler((call) async {
    if (call.method != 'alarmFired' || call.arguments is! String) return;
    await _routeToWakeUp(storage.shifts, call.arguments as String);
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

  // LEGAL CONSENT GATE — read the accepted legal version from
  // shared_preferences (the source of truth the consent screen writes). If it
  // doesn't match the version currently in force, the app routes through
  // [LegalConsentScreen] before onboarding or the dashboard. Read here (async,
  // pre-runApp) so RostrikApp can decide its home synchronously.
  final sharedPrefs = await SharedPreferences.getInstance();
  final legalAccepted =
      sharedPrefs.getString(kAcceptedLegalVersionKey) == kCurrentLegalVersion;

  runApp(AppProviders(
    storage: storage,
    scheduler: scheduler,
    // UI display preferences ride the already-opened generic 'settings' box.
    preferences: AppPreferences(Hive.box('settings')),
    child: RostrikApp(legalAccepted: legalAccepted),
  ));

  // If we pulled an FSI payload, push WakeUpScreen on top of the
  // freshly-built RosterScreen home. The post-frame callback ensures
  // `navigatorKey.currentState` is attached before `_routeToWakeUp`
  // tries to use it — otherwise the push silently no-ops. From the
  // user's perspective the lock screen flashes RosterScreen for one
  // frame at most, which is invisible during the device wake animation.
  if (initialFsiPayload != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeToWakeUp(storage.shifts, initialFsiPayload);
    });
  }
}

/// Pushes WakeUpScreen on top of whatever's currently on the navigator,
/// clearing the rest of the stack so back-button has nowhere to go (the
/// alarm IS the foreground task — escaping via back is the wrong
/// affordance). Slide-to-dismiss inside WakeUpScreen replaces itself
/// with RosterScreen on success, leaving a clean single-route stack.
///
/// ZOMBIE-UI GATE: the payload is verified against Hive before it is
/// trusted. Android redelivers the original FullScreenIntent when the task
/// is relaunched from recents, so a cold boot HOURS after the alarm was
/// dismissed from the notification panel still hands us the stale payload —
/// and routing on it raised a silent, dead WakeUpScreen. If the shift exists
/// and [Shift.isAlarmHandledAt] says the occurrence was already dismissed
/// (or is snoozed into the future), the route is suppressed — the SAME
/// predicate WakeUpScreen's self-destruct uses, so gate and screen can never
/// disagree. A missing shift (deleted, or the `NONE` sentinel of a
/// shift-less alarm) cannot be verified and routes as before: for a genuine
/// fire the wake screen is the only dismiss surface, so when in doubt, show.
Future<void> _routeToWakeUp(ShiftRepository shifts, String payload) async {
  final parsed = AlarmPayload.decode(payload);
  if (parsed == null) return;
  // NATIVE STORE FIRST, Hive second: drain any killed-app dismissals the
  // background isolate recorded but never got to write (the Pixel-9 reap).
  // After this, the Hive check below sees the replayed `isAcknowledged` and
  // suppresses the zombie route through the one shared predicate.
  await _syncNativePendingDismissals(shifts);
  if (parsed.shiftId != noShiftPayloadSentinel) {
    final shift = await shifts.getById(parsed.shiftId);
    if (shift != null && shift.isAlarmHandledAt(DateTime.now())) {
      debugPrint(
        '[main] stale wake payload for already-handled shift '
        '${shift.id} — suppressing WakeUpScreen',
      );
      return;
    }
  }
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => _wakeUpScreenFor(parsed)),
    (_) => false,
  );
}

/// Drains the native dismiss fail-safe ledger into Hive, then clears it.
///
/// The read and clear go through the alarm-routing MethodChannel —
/// MainActivity answers both with plain synchronous `java.io.File` ops on
/// `filesDir/pending_dismissals`, the ledger the background isolate's first
/// instruction writes on a killed-app Dismiss. Ordering is load-bearing:
///   1. READ the native store;
///   2. WRITE `isAcknowledged` into Hive ([ackPendingDismissalsInHive] —
///      idempotent, snooze-clearing, exactly the write the reaped isolate
///      would have made);
///   3. only then CLEAR the store — a crash between 2 and 3 re-replays on
///      the next boot instead of ever losing a dismissal.
///
/// Channel errors (iOS — no MainActivity handler; widget tests — no
/// platform) read as "nothing pending": the fail-safe is Android-only by
/// nature, because only Android kills the FLN background isolate this way.
Future<void> _syncNativePendingDismissals(ShiftRepository shifts) async {
  List<String> ids;
  try {
    final raw = await _alarmRoutingChannel
        .invokeMethod<List<Object?>>('getPendingDismissals');
    ids = raw?.whereType<String>().toList() ?? const <String>[];
  } catch (_) {
    return; // no native handler on this platform — nothing to drain
  }
  if (ids.isEmpty) return;

  final acked = await ackPendingDismissalsInHive(shifts: shifts, shiftIds: ids);
  debugPrint(
    '[main] native dismiss fail-safe: replayed $acked dismissal(s) '
    'from ${ids.length} ledger entr${ids.length == 1 ? 'y' : 'ies'} into Hive',
  );

  try {
    await _alarmRoutingChannel.invokeMethod<void>('clearPendingDismissals');
  } catch (_) {
    // Best-effort: an uncleared ledger just replays idempotently next boot.
  }
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
  const RostrikApp({super.key, required this.legalAccepted});

  /// Whether the user has already accepted the current legal version. When
  /// false the home is gated behind [LegalConsentScreen].
  final bool legalAccepted;

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
      //
      // The premium pitch-black + high-vis-orange "industrial tool"
      // identity lives in `rostrikDarkTheme()` — every accent (selection
      // states, progress, primary buttons) reads from its single orange
      // seed, so the whole app adopts the look without per-screen edits.
      themeMode: ThemeMode.dark,
      theme: rostrikDarkTheme(),
      darkTheme: rostrikDarkTheme(),
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
      home: _RootGate(legalAccepted: legalAccepted),
    );
  }
}

/// The root routing gate. The LEGAL gate sits in front of the onboarding gate:
/// until the current legal version is accepted, nothing else is reachable. On
/// acceptance the consent screen has already persisted the version to
/// shared_preferences, so [_legalAccepted] flips locally and the onboarding /
/// dashboard gate takes over in place — no navigation needed.
class _RootGate extends StatefulWidget {
  const _RootGate({required this.legalAccepted});

  final bool legalAccepted;

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  late bool _legalAccepted = widget.legalAccepted;

  @override
  Widget build(BuildContext context) {
    if (!_legalAccepted) {
      return LegalConsentScreen(
        onAccepted: () => setState(() => _legalAccepted = true),
      );
    }
    // First-launch onboarding gate: read the synchronously-available
    // `onboarding_complete` flag off the already-open `settings` box.
    return Hive.box('settings').get(
      onboardingCompleteKey,
      defaultValue: false,
    ) as bool
        ? const MainLayout()
        : const OnboardingFlow();
  }
}

/// Builds the WakeUpScreen for an already-decoded (and gate-checked) payload.
/// Decoding lives in [_routeToWakeUp] via the shared [AlarmPayload] codec;
/// `shiftId` may be the `'NONE'` sentinel for an alarm with no linked shift —
/// WakeUpScreen renders a generic title in that case without hitting the
/// ShiftRepository. The bundled-tone `soundKey` is irrelevant here (the OS
/// channel owns that audio), but the custom `customRingtoneUri` IS threaded
/// through: when present, WakeUpScreen plays it via the native player (the
/// notification was scheduled on the silent channel).
Widget _wakeUpScreenFor(AlarmPayload parsed) => WakeUpScreen(
      shiftId: parsed.shiftId,
      notificationId: parsed.notificationId,
      isCritical: parsed.isCritical,
      appAlarmId: parsed.appAlarmId,
      customRingtoneUri: parsed.customRingtoneUri,
      // Preset tone key — drives the native bundled-tone playback when there's
      // no custom URI (every fire-time alarm plays through the service now).
      soundKey: parsed.soundKey,
      vibrationEnabled: parsed.vibrationEnabled,
    );
