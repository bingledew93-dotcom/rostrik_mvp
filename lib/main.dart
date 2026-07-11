import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarms/alarm_sync_service.dart';
import 'alarms/main_isolate_liveness.dart';
import 'alarms/native_alarm_scheduler.dart';
import 'alarms/pending_alarm_delete_guard.dart';
import 'alarms/pending_dismissal_guard.dart';
import 'alarms/pending_snooze_guard.dart';
import 'data/repositories/app_alarm_repository.dart';
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
  await drainPendingAlarmDeletesIntoHive(storage.alarms);

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
    _AlarmDismissalDrain(storage.shifts, storage.alarms, syncService),
  );

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
  _AlarmDismissalDrain(this._shifts, this._alarms, this._syncService);

  final ShiftRepository _shifts;
  final AppAlarmRepository _alarms;
  final AlarmSyncService _syncService;

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
  Future<void> _drainNativeLedgers() async {
    await _syncNativePendingDismissals(_shifts);
    await drainPendingSnoozesIntoHive(_shifts);
    await drainPendingAlarmDeletesIntoHive(_alarms);
    await _syncService.syncAlarms();
  }
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
  // Android 13+ POST_NOTIFICATIONS — needed for AlarmReceiver's full-screen-
  // intent notification to show. No-op on iOS / older Android.
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

