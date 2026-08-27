import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarms/alarm_sync_service.dart';
import 'alarms/alarmkit_bringup.dart';
import 'alarms/main_isolate_liveness.dart';
import 'alarms/native_alarm_scheduler.dart';
import 'alarms/pending_alarm_delete_guard.dart';
import 'alarms/pending_dismissal_guard.dart';
import 'alarms/pending_snooze_guard.dart';
import 'alarms/spent_one_time_sweep.dart';
import 'calendar_sync/device_calendar_service.dart';
import 'data/repositories/app_alarm_repository.dart';
import 'data/repositories/shift_repository.dart';
import 'data/storage/local_storage.dart';
import 'legal/legal.dart';
import 'logic/adhoc_archive.dart';
import 'purchase/entitlement_service.dart';
import 'purchase/purchase_gate.dart';
import 'reminders/activity_reminder_scheduler.dart';
import 'reminders/activity_reminder_service.dart';
import 'reminders/sleep_reminder_service.dart';
import 'services/widget_service.dart';
import 'sleep/sleep_sound_controller.dart';
import 'state/app_preferences.dart';
import 'state/app_providers.dart';
import 'ui/app_theme.dart';
import 'ui/legal_consent_screen.dart';
import 'ui/main_layout.dart';
import 'ui/onboarding/onboarding_flow.dart';
import 'util/clock.dart';

/// Global Navigator handle for [MaterialApp] — lets navigation happen from
/// callbacks that have no BuildContext.
final navigatorKey = GlobalKey<NavigatorState>();

/// Same channel name as MainActivity.kt's alarm-routing CHANNEL. Now used ONLY
/// to drain the native `pending_dismissals` ledger (`getPendingDismissals` /
/// `clearPendingDismissals`) — the firing-alarm UI is the native AlarmActivity,
/// so the old `alarmFired` / WakeUpScreen routing is gone.
const _alarmRoutingChannel = MethodChannel('rostrik/alarm_routing');

/// Bootstrap order is load-bearing:
///   1. Bind the Flutter engine.
///   2. Open Hive boxes — repositories required by the sync service live here.
///   3. Init the native AlarmManager scheduler ([NativeAlarmScheduler]).
///   4. Drain the native `pending_dismissals` ledger into Hive BEFORE the first
///      reconcile, so a killed-app/native dismiss is acknowledged.
///   5. Request runtime permissions BEFORE the first sync, so anything the sync
///      service schedules can actually fire.
///   6. Start the AlarmSyncService: initial sync + subscribe to the alarm /
///      cycle / in-horizon shift / settings streams.
///   7. Register the main-isolate liveness port the background sync probes
///      ([registerMainIsolatePort]).
///   8. Register the app-lifecycle observer that re-drains the dismissal ledger
///      on resume (a native AlarmActivity dismiss while the app was
///      backgrounded must still reconcile Hive).
///   9. runApp — home is always MainLayout (or the legal/onboarding gate). The
///      firing-alarm UI is the native AlarmActivity, drawn over whatever is on
///      screen; the Flutter process is never the alarm surface.
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

  // EDGE-TO-EDGE on every Android version (Play Console: "Edge-to-edge may not
  // display for all users").
  //
  // targetSdk 36 means Android 15+ (API 35+) ALREADY forces edge-to-edge on us —
  // that is what 1.2.0 shipped with and what those users see today. Below API 35
  // the OS does not, so the app letterboxed itself inside opaque system bars:
  // one binary rendering two different ways depending on OS version, which is
  // exactly what Play is flagging. Setting the mode explicitly makes API 24–34
  // render the way API 35+ already does — parity, not a new layout.
  //
  // Inset handling is unchanged: edgeToEdge keeps the status and navigation bars
  // VISIBLE and still reports them through `MediaQuery.viewPadding`, so the
  // existing Scaffold / AppBar / SafeArea chrome positions content exactly as it
  // does on Android 15 today.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final storage = await LocalStorage.init();
  // Generic key-value Hive box for app-wide preferences that don't warrant
  // their own typed repository (currently: `snooze_duration` minutes).
  // Opened here so every read site — SettingsScreen, the foreground
  // dispatcher, the WakeUpScreen, and the bg-isolate snooze handler when
  // it runs the slow path — can call `Hive.box('settings').get(...)`
  // without an async hop. The bg isolate has its own VM/Hive instance and
  // opens this box in `_ensureBackgroundIsolateInit`.
  await Hive.openBox('settings');
  // OS scheduling now goes through the native AlarmManager bridge — no
  // flutter_local_notifications plugin, no timezone DB. NativeAlarmScheduler
  // implements the same AlarmScheduler interface, so AlarmSyncService's
  // idempotent reconcile is unchanged.
  final scheduler = await NativeAlarmScheduler.init();

  // NATIVE DISMISS FAIL-SAFE — replay killed-app dismissals from the
  // Kotlin-readable ledger into Hive BEFORE the first reconcile and before
  // any wake routing. Pixel-9-class battery management can reap the
  // background isolate before its Hive write lands; the ledger (written by
  // that isolate's first instruction, kernel-synchronous) is the surviving
  // record. Replaying here means the sync service's initial reconcile sees
  // `isAcknowledged` and tears down any stale OS entry in the same boot.
  await _syncNativePendingDismissals(storage.shifts);

  // NATIVE SNOOZE FAIL-SAFE — replay native AlarmActivity snoozes into Hive
  // (set `snoozedUntil`) BEFORE the first reconcile, so a shift snoozed while
  // the app was dead/backgrounded keeps its re-armed alarm instead of having it
  // cancelled as an orphan. Drained AFTER dismissals so a dismiss (final) wins
  // over any stale snooze for the same shift.
  await drainPendingSnoozesIntoHive(storage.shifts);

  // FIRED ONE-TIME CLEANUP — delete any one-time alarm that fired (and was
  // dismissed or auto-timed-out) natively, BEFORE the first reconcile, so the
  // engine doesn't re-project a spent one-shot into tomorrow (a one-time alarm
  // silently becoming a daily cycle). The native dismiss/auto-timeout records
  // the fired `appAlarmId` in the `pending_alarm_deletes` ledger; this drain
  // resolves each to its AppAlarm and deletes the one-time ones.
  //
  // On iOS nothing runs at fire time to write that ledger, so it is harvested
  // from what the OS actually delivered — which must happen BEFORE the drain,
  // or the drain reads a file that is still empty. No-op on Android.
  await scheduler.recordSpentAlarms();
  await drainPendingAlarmDeletesIntoHive(storage.alarms);

  // ANCHOR-BASED BACKSTOP. The ledger drains above all depend on the OS having
  // told us the alarm fired; clearing a notification without opening the app
  // tells us nothing, and the one-shot would ring again tomorrow. This needs no
  // OS cooperation — a spent alarm is recognisable from its own timestamp.
  await sweepSpentOneTimeAlarms(storage.alarms);

  // SELF-CLEANING AD-HOC SHIFTS — archive (NEVER delete) any one-off shift
  // whose end is >24h past, keeping the active roster/alarm set lean as
  // one-offs accumulate. Runs before the first reconcile; archived shifts are
  // already behind the engine's future-fire gate, so this can never disarm a
  // live alarm. The Shift record stays in Hive for the historical calendar
  // (the payslip-verification record) — only `isArchived` is flipped.
  await archiveExpiredAdHocShifts(storage.shifts, now: DateTime.now());

  await _requestAlarmPermissions();

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

  // PHASE-3 OPTIONAL REMINDERS — a fully separate, lightweight path from the
  // shift-alarm engine above. This service watches the activity box and keeps
  // the OS's reminder set in sync (schedule/replace/cancel) via the native
  // `rostrik/activity_reminders` channel. The initial reconcile here also
  // re-arms reminders after a reboot (AlarmManager alarms don't survive one),
  // covered on the next app open. Never stopped, for the same reason the alarm
  // sync service isn't — but even if the process dies the armed reminders live
  // in the OS.
  final reminderScheduler = NativeActivityReminderScheduler();
  final reminderService = ActivityReminderService(
    activities: storage.activities,
    scheduler: reminderScheduler,
  );
  await reminderService.start();

  // SLEEP NUDGES (Sleep tab) — the wind-down + bedtime reminders. Reuses the
  // SAME isolated reminder scheduler as the activity reminders above (a plain,
  // DND-respecting notification, never the shift-alarm chain). It recomputes the
  // roster-derived sleep plan and reconciles the two fixed-id nudges whenever the
  // roster or a sleep preference changes; a fresh reconcile on each launch also
  // re-arms them after a reboot.
  final sleepReminderService = SleepReminderService(
    shifts: storage.shifts,
    alarms: storage.alarms,
    alarmSettings: storage.alarmSettings,
    settingsBox: Hive.box('settings'),
    scheduler: reminderScheduler,
  );
  await sleepReminderService.start();

  // FEATURE #4 — 14-day free trial + one-time full-access purchase. Records the
  // trial clock on first launch, writes the lock + horizon-cap gates the alarm
  // sync reads (a locked app fires NO alarms; an in-trial app arms nothing past
  // the trial), schedules the "trial ends tomorrow" nudge on the isolated
  // reminder channel, and drives Google Play Billing for the unlock.
  // `onEntitlementChanged` re-runs the reconcile so alarms disarm on lock and
  // restore on purchase. init() runs AFTER syncService.start() so its refresh
  // re-syncs with the gates applied.
  final entitlementService = EntitlementService(
    settingsBox: Hive.box('settings'),
    reminderScheduler: reminderScheduler,
    onEntitlementChanged: syncService.syncAlarms,
  );
  await entitlementService.init();

  // PHASE 2 — HOME-SCREEN WIDGET bridge. Pushes an initial snapshot of the
  // Dashboard hero to the Android widget and refreshes it on every roster
  // change (shift/cycle streams) and app resume. Self-guards on unsupported
  // platforms and swallows its own errors, so it can never disturb startup or
  // the alarm engine. Started AFTER syncService so the roster it reads is
  // whatever the initial reconcile has settled on.
  final widgetService = WidgetService(
    shifts: storage.shifts,
    cycles: storage.cycles,
    settingsBox: Hive.box('settings'),
  );
  await widgetService.start();

  // OPTIONAL DEVICE CALENDAR SYNC (feature-calendar-sync). Mirrors the roster to
  // a dedicated "Rostrik Roster" calendar when the user turns it on in Settings.
  // Off by default and self-guarding: start() only subscribes to the roster
  // streams and never prompts for permission — the initial stream emission
  // triggers a re-sync only if sync is already enabled (and permission held), so
  // the 180-day window rolls forward on each launch with zero cost when off.
  final deviceCalendarService = DeviceCalendarService(
    shifts: storage.shifts,
    cycles: storage.cycles,
    settingsBox: Hive.box('settings'),
  );
  await deviceCalendarService.start();

  // SLEEP SOUNDS controller (Sleep tab) — the Flutter-side mirror of the native
  // SleepSoundService foreground player. Provided app-wide so the Sleep tab can
  // play/stop the looping white/brown-noise sounds and show the wind-down
  // countdown. Constructed here so it can observe app lifecycle (re-syncs its
  // "is playing" state on resume after a background auto-stop).
  final sleepSoundController = SleepSoundController();

  // Register the main-isolate liveness beacon — the background sync checks for
  // it (`mainIsolateIsAlive`) and bails rather than reconcile Hive concurrently
  // with this live isolate (which would race the id-map counter + scheduled-
  // fire-at persistence).
  registerMainIsolatePort();

  // RESUME-TIME LEDGER DRAIN. The firing-alarm UI is the native AlarmActivity;
  // when it dismisses an alarm WHILE THE FLUTTER APP IS ALIVE (backgrounded
  // behind the alarm's own task), it records the dismissal in the native
  // `pending_dismissals` ledger but cannot touch Hive — the Flutter isolate is
  // the SOLE Hive writer, which is exactly what prevents cross-side state
  // corruption. This observer drains the ledger into Hive on every resume; the
  // resulting `isAcknowledged` shift write trips AlarmSyncService's shift
  // watcher, which reconciles away any now-stale OS alarm. Cold-launch is
  // covered by the drain above; there is no longer any FSI payload to pull —
  // AlarmActivity, not MainActivity, owns the alarm event end to end.
  WidgetsBinding.instance.addObserver(
    _AlarmDismissalDrain(storage.shifts, storage.alarms, syncService, scheduler),
  );

  // iOS: a fired alarm is only knowable from the notification response, which
  // iOS delivers AFTER the app is already active — i.e. after the resume drain
  // above has run. This nudge closes that window, retiring a spent one-time
  // alarm immediately instead of leaving it to be re-projected to tomorrow.
  scheduler.setSpentAlarmListener(() {
    unawaited(drainNativeLedgers(
      shifts: storage.shifts,
      alarms: storage.alarms,
      scheduler: scheduler,
      syncService: syncService,
    ));
  });

  // LEGAL CONSENT GATE — read the accepted legal version from
  // shared_preferences (the source of truth the consent screen writes). If it
  // doesn't match the version currently in force, the app routes through
  // [LegalConsentScreen] before onboarding or the dashboard. Read here (async,
  // pre-runApp) so RostrikApp can decide its home synchronously.
  final sharedPrefs = await SharedPreferences.getInstance();
  final legalAccepted =
      sharedPrefs.getString(kAcceptedLegalVersionKey) == kCurrentLegalVersion;

  // Must come after runApp: it posts to the first frame, which only exists
  // once there is a widget tree. See the function's own doc for why this
  // cannot live in the pre-runApp permission block.
  requestIosNotificationPermission();
  runApp(AppProviders(
    storage: storage,
    scheduler: scheduler,
    // UI display preferences ride the already-opened generic 'settings' box.
    preferences: AppPreferences(Hive.box('settings')),
    entitlementService: entitlementService,
    widgetService: widgetService,
    deviceCalendarService: deviceCalendarService,
    sleepSoundController: sleepSoundController,
    child: RostrikApp(legalAccepted: legalAccepted),
  ));

}

/// App-lifecycle observer that drains the native `pending_dismissals` ledger
/// into Hive whenever the app returns to the foreground.
///
/// The firing-alarm UI is the native [AlarmActivity], which can dismiss an
/// alarm while the Flutter app is merely backgrounded (behind the alarm's own
/// task). It records the dismissal in the file ledger but never touches Hive —
/// the Flutter isolate is the sole Hive writer, which is exactly what keeps the
/// two sides from corrupting each other. On resume we replay the ledger into
/// Hive ([_syncNativePendingDismissals]); the resulting per-ring
/// `dismissedAlarmIds` write trips AlarmSyncService's shift watcher, which
/// cancels the dismissed ring's now-stale OS alarm — and ONLY that one.
class _AlarmDismissalDrain with WidgetsBindingObserver {
  _AlarmDismissalDrain(
    this._shifts,
    this._alarms,
    this._syncService,
    this._scheduler,
  );

  final ShiftRepository _shifts;
  final AppAlarmRepository _alarms;
  final AlarmSyncService _syncService;
  final NativeAlarmScheduler _scheduler;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Fire-and-forget the sequenced drain; every helper swallows its own
    // errors (a channel miss / missing dir off-Android is a no-op).
    _drainNativeLedgers();
  }

  /// Dismissals first (a dismiss is final and clears any snooze), then snoozes,
  /// then fired-one-time cleanup. Each resulting Hive write trips
  /// AlarmSyncService's alarm/shift watchers, which reconcile the OS alarm set
  /// to match (and stop re-projecting a deleted one-time).
  ///
  /// The tail sync is the WINDOW-ROLL guarantee (audit F1): the drains only
  /// trigger a reconcile when a ledger actually had entries, so a long-lived
  /// process resumed after days of quiet would otherwise keep a stale 14-day
  /// window. An explicit sync is safe to run unconditionally — it's
  /// idempotent and issues zero platform calls when nothing changed.
  Future<void> _drainNativeLedgers() => drainNativeLedgers(
        shifts: _shifts,
        alarms: _alarms,
        scheduler: _scheduler,
        syncService: _syncService,
      );
}

/// The full ledger-drain sequence, shared by the resume observer and the
/// native `onSpentAlarmRecorded` nudge so both converge identically.
///
/// Order is load-bearing: dismissals first (a dismiss is final and clears any
/// snooze), then snoozes, then the delivered-alarm harvest BEFORE the deletes
/// drain that consumes it, and finally a reconcile so the OS set matches the
/// Hive writes the drains just made.
Future<void> drainNativeLedgers({
  required ShiftRepository shifts,
  required AppAlarmRepository alarms,
  required NativeAlarmScheduler scheduler,
  required AlarmSyncService syncService,
}) async {
  await _syncNativePendingDismissals(shifts);
  await drainPendingSnoozesIntoHive(shifts);
  await scheduler.recordSpentAlarms();
  await drainPendingAlarmDeletesIntoHive(alarms);
  await sweepSpentOneTimeAlarms(alarms);
  await syncService.syncAlarms();
}

/// Drains the native dismiss fail-safe ledger into Hive, then clears it.
///
/// The read and clear go through the alarm-routing MethodChannel —
/// MainActivity answers both with plain synchronous `java.io.File` ops on
/// `filesDir/pending_dismissals`, the ledger the background isolate's first
/// instruction writes on a killed-app Dismiss. Ordering is load-bearing:
///   1. READ the native store;
///   2. WRITE the dismissal into Hive ([ackPendingDismissalsInHive] —
///      idempotent, per-ring via `Shift.dismissedAlarmIds`, exactly the
///      write the reaped isolate would have made);
///   3. only then CLEAR the store — a crash between 2 and 3 re-replays on
///      the next boot instead of ever losing a dismissal.
///
/// Channel errors (iOS — no MainActivity handler; widget tests — no
/// platform) read as "nothing pending": the fail-safe is Android-only by
/// nature, because only Android kills the FLN background isolate this way.
///
/// Each ledger line is `<shiftId>|<appAlarmId>` — a PER-OCCURRENCE dismissal
/// that lands in `Shift.dismissedAlarmIds` and suppresses only that ring, so
/// a shift's remaining alarms survive the reconcile. A legacy bare
/// `<shiftId>` line (no alarm identity) degrades to the whole-shift ack.
Future<void> _syncNativePendingDismissals(ShiftRepository shifts) async {
  List<PendingDismissal> dismissals;
  try {
    final raw = await _alarmRoutingChannel
        .invokeMethod<List<Object?>>('getPendingDismissals');
    dismissals = (raw ?? const <Object?>[])
        .whereType<String>()
        .map(parsePendingDismissalLine)
        .whereType<PendingDismissal>()
        .toList();
  } catch (_) {
    return; // no native handler on this platform — nothing to drain
  }
  if (dismissals.isEmpty) return;

  final acked = await ackPendingDismissalsInHive(
    shifts: shifts,
    dismissals: dismissals,
  );
  debugPrint(
    '[main] native dismiss fail-safe: replayed $acked dismissal(s) '
    'from ${dismissals.length} ledger '
    'entr${dismissals.length == 1 ? 'y' : 'ies'} into Hive',
  );

  try {
    await _alarmRoutingChannel.invokeMethod<void>('clearPendingDismissals');
  } catch (_) {
    // Best-effort: an uncleared ledger just replays idempotently next boot.
  }
}

/// Runtime permissions for the native alarm stack, all via `permission_handler`
/// (the project's existing cross-platform permission layer — there's no
/// plugin-specific fallback now that flutter_local_notifications is gone). All
/// calls are idempotent: the OS suppresses re-prompts after the user answers.
Future<void> _requestAlarmPermissions() async {
  // iOS asks for NOTHING here — see [requestIosNotificationPermission], which
  // runs after the first frame instead. Every permission below is an Android
  // concept anyway (`scheduleExactAlarm` and `systemAlertWindow` both resolve
  // to permission_handler's "unknown" strategy on iOS, i.e. an immediate
  // permanently-denied), so skipping the whole block off-Android costs nothing.
  if (!Platform.isAndroid) return;

  // Android 13+ POST_NOTIFICATIONS — needed for AlarmReceiver's full-screen-
  // intent notification to show. No-op on older Android.
  await Permission.notification.request();

  // Android 12+ exact-alarm. `setAlarmClock` itself is exempt and always
  // allowed, but requesting keeps the lock-screen "next alarm" treatment and
  // makes the capability explicit. Auto-granted where USE_EXACT_ALARM is
  // declared (this app qualifies as an alarm clock).
  await Permission.scheduleExactAlarm.request();

  // SYSTEM_ALERT_WINDOW (maps to Settings.canDrawOverlays on Android) — lets the
  // alarm draw over other apps when the device is UNLOCKED and in active use.
  // Best-effort: the full-screen intent is the primary surface, so a denial is
  // non-fatal and we never hard-gate the app on it. Only prompt when not
  // already granted; a future Settings screen can own re-prompting so this
  // isn't a per-launch nag.
  if (!await Permission.systemAlertWindow.isGranted) {
    await Permission.systemAlertWindow.request();
  }
}

/// Asks for the iOS notification permission AFTER the first frame.
///
/// It cannot be asked for during `main()`. permission_handler's iOS side
/// answers a status check by blocking its thread on a semaphore until
/// `UNUserNotificationCenter` calls back, and that callback does not arrive
/// while the app is still launching — so asking pre-`runApp` blocks the very
/// launch the callback is waiting on, and the app sits on the native splash
/// screen forever. Posting it after the first frame means the app is provably
/// live before anything blocks.
///
/// Unawaited by design, and safe to no-op: [PermissionsScreen] asks again on an
/// explicit tap during onboarding, so a returning user who dismissed the
/// system prompt still has a route back to granting it.
void requestIosNotificationPermission() {
  if (!Platform.isIOS) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // The AlarmKit bring-up probe is chained AFTER the notification prompt
    // rather than fired alongside it, so the two system alerts queue instead of
    // racing for the same window. It is a no-op in release builds and on any
    // device below iOS 26 — see `runAlarmKitBringUp`. Still unawaited overall,
    // which is the property that matters here: nothing blocks the first frame.
    unawaited(
      Permission.notification.request().whenComplete(runAlarmKitBringUp),
    );
  });
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
      // No corner "DEBUG" ribbon on dev installs. Release builds never show
      // it, but field-testing happens on debug builds too and the banner
      // reads as broken UI to a beta tester.
      debugShowCheckedModeBanner: false,
      // Appearance: dark by default (the app's identity — most activity is
      // around alarm-fire time, early morning / late night, where dark is
      // correct regardless of OS setting, and the native alarm surface is
      // always dark). Users can opt into the warm cream `rostrikLightTheme()`
      // or "follow system" from Settings → Preferences; the choice persists in
      // `AppPreferences` and is WATCHED here, so flipping it re-themes the whole
      // app instantly. When no provider is in the tree (bare widget tests) the
      // tolerant reader falls back to dark — nothing goes light by accident.
      //
      // Both themes read from ONE orange seed via `_rostrikThemeFromScheme`, so
      // every accent (selection states, progress, primary buttons) adopts the
      // look without per-screen edits.
      themeMode: AppPreferences.themeModeOf(context),
      theme: rostrikLightTheme(),
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
      // Cold launch always lands on either chassis (or the legal/onboarding
      // gate). The firing alarm is no longer a Flutter route at all: the native
      // AlarmActivity draws over whatever is here when an alarm fires, in its
      // own task, so nothing in this widget tree needs to react to it.
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
    // FEATURE #4 — full lock once the 14-day trial lapses without a purchase.
    // Sits AFTER legal (consent still comes first) and in front of everything
    // else; `context.watch` rebuilds the instant a purchase clears the lock.
    // A fresh install is inside its trial, so new users flow straight to
    // onboarding — the wall only ever appears after the trial ends.
    final entitlement = context.watch<EntitlementService>();
    if (entitlement.locked) {
      return PurchaseGate(service: entitlement);
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

