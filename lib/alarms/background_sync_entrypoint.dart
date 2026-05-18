import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/storage/local_storage.dart';
import '../util/clock.dart';
import 'alarm_sync_service.dart';
import 'local_notifications_alarm_scheduler.dart';

/// Bridge between the native background-task runners and the Dart-side
/// [AlarmSyncService]. Runs in a SEPARATE Dart isolate from the main UI
/// engine — its heap, its Hive instance, and its timezone DB are all
/// distinct from those of the main isolate.
///
/// Triggered by:
///   * iOS — `BGTaskScheduler` handler in `ios/Runner/AppDelegate.swift`
///     fires on background-refresh windows (~4h cadence, iOS-decided).
///   * Android — `BootReceiver` enqueues `AlarmSyncWorker`, which spins
///     up a headless `FlutterEngine` after every boot / package replace.
///
/// Channel contract — identical on both platforms (handshake then run):
///   1. Native creates the engine, calls `executeDartEntrypoint` against
///      this function, then registers a handler that listens for
///      `handlerReady`.
///   2. This function sets up the `run` handler synchronously inside
///      `setMethodCallHandler` and then invokes `handlerReady` so
///      native knows it's safe to call `run`.
///   3. Native invokes `run`. We perform exactly one `syncAlarms()`
///      pass and return.
///   4. Native tears down the engine.
///
/// Without the handshake, native's `invokeMethod("run", …)` can race
/// past Dart's `setMethodCallHandler` and be dropped as
/// `notImplemented`.
///
/// CRITICAL: this function must be top-level (or static) AND annotated
/// `@pragma('vm:entry-point')`. AOT compilation drops any function not
/// reachable from `main()`; the pragma is what tells the tree-shaker to
/// keep this around. The function NAME is hard-coded in the iOS
/// AppDelegate and the Android Worker — rename here without updating
/// both call sites and the background runs silently never happen.

const String _backgroundSyncChannel = 'rostrik/alarm_sync_background';

@pragma('vm:entry-point')
void syncAlarmsBackgroundEntrypoint() {
  // Bind the engine BEFORE installing the handler — `MethodChannel`
  // calls require a live `WidgetsBinding` (or `ServicesBinding`,
  // which is a superclass) to dispatch.
  WidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(_backgroundSyncChannel);

  channel.setMethodCallHandler((call) async {
    if (call.method != 'run') return null;
    try {
      await _runSync();
      return true;
    } catch (e, st) {
      // PlatformException is what native's `MethodChannel.Result.error`
      // / Swift's `FlutterError` parses cleanly. A plain `throw` would
      // produce a `MissingPluginException`-shaped error that's harder
      // to log on the native side.
      throw PlatformException(
        code: 'SYNC_FAILED',
        message: e.toString(),
        details: st.toString(),
      );
    }
  });

  // Fire-and-forget — native is waiting on this to know we're wired.
  // Any error here means native is gone (engine torn down before
  // we got here) and we can do nothing about it; the next invocation
  // is independent.
  channel.invokeMethod<void>('handlerReady');
}

/// The actual sync. Bootstraps Hive + the OS scheduler + the service
/// from scratch — this isolate shares NO state with the main UI
/// isolate.
///
/// Init order mirrors `main.dart`:
///   1. `LocalStorage.init()` — registers Hive adapters, opens the
///      typed boxes (`shifts`, `alarms`, `cycles`, `alarmSettings`,
///      `notificationIds`).
///   2. `Hive.openBox('settings')` — the untyped K/V box that holds
///      `snooze_duration` AND the persisted `_scheduledFireAt` map
///      that `AlarmSyncService` hydrates from on cold start. Without
///      this, the service's hydrate defensively no-ops and we re-issue
///      `scheduleAt` for every desired id (correct but wasteful).
///   3. `LocalNotificationsAlarmScheduler.init()` — timezone DB,
///      `flutter_local_notifications` plugin, notification channel
///      registration. Idempotent against the main-isolate init —
///      both ultimately talk to the same on-device AlarmManager
///      state, but their Dart-side plugin objects are independent.
///   4. Construct the service with a real `SystemClock` and run
///      exactly one `syncAlarms()`.
///
/// The service is constructed, used, and discarded — no `start()`
/// call, no watch subscriptions, no debounce. A background refresh
/// is a one-shot reconcile; reactive watching only makes sense when
/// the app is alive and the user is editing state.
Future<void> _runSync() async {
  final storage = await LocalStorage.init();
  // Mirror main.dart line-for-line: the 'settings' box is opened
  // there before the scheduler init. AlarmSyncService's hydrate /
  // persist methods are guarded by `Hive.isBoxOpen('settings')`, so
  // failing this open would silently skip persistence — fine in
  // tests, bad in production. Awaiting it surfaces any failure.
  await Hive.openBox('settings');

  final scheduler = await LocalNotificationsAlarmScheduler.init();

  final service = AlarmSyncService(
    alarms: storage.alarms,
    shifts: storage.shifts,
    cycles: storage.cycles,
    scheduler: scheduler,
    idMap: storage.notificationIds,
    clock: const SystemClock(),
  );

  await service.syncAlarms();
}
