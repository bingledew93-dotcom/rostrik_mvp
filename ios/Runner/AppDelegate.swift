import BackgroundTasks
import Flutter
import UIKit

/// iOS background refresh wiring for Rostrik's 14-day rolling alarm window.
///
/// The Dart-side `AlarmSyncService` keeps the OS pending-notification set
/// trimmed to a 14-day rolling horizon (max 50 entries). That horizon only
/// rolls forward when something runs `syncAlarms()`. Without the user
/// opening the app, nothing rolls it — and after ~14 days every shift
/// past the original cutoff loses its OS alarm.
///
/// `BGTaskScheduler` is the iOS-native fix. We register one task identifier,
/// `com.example.rostrikMvp.alarmSyncRefresh`, and ask iOS to fire it no
/// earlier than 4 hours from now whenever we get a chance to schedule.
/// iOS decides the actual fire time based on usage patterns, charging
/// state, and the system's overall health; the request is a request, not
/// a guarantee. The 4-hour minimum keeps system load low without letting
/// the window drift more than a few hours behind in normal use.
///
/// When the task fires:
///   1. We immediately re-arm the NEXT request so a failure in THIS run
///      doesn't terminate the refresh chain.
///   2. We spin up a HEADLESS `FlutterEngine` separate from the UI
///      engine (the UI engine may not even exist — the OS gives us
///      ~30 seconds of background runtime, far less than a cold UI launch).
///   3. The headless engine runs the `syncAlarmsBackgroundEntrypoint`
///      Dart function. That entrypoint opens Hive, builds an
///      `AlarmSyncService`, runs one `syncAlarms()`, and answers back
///      via a `MethodChannel`.
///   4. We tear down the engine and call `task.setTaskCompleted` so
///      iOS knows our slot is free.
///
/// Hand-off contract with Dart:
///   - Native creates the channel, sets a handler that listens for
///     `handlerReady` from Dart (so we don't race-invoke `run` before
///     Dart's `setMethodCallHandler` is wired up).
///   - On receiving `handlerReady`, native calls `run`. The Dart
///     entrypoint executes the sync and returns success/error.
///
/// Without this handshake, `invokeMethod("run", ...)` can fire before
/// Dart has registered its receiver, returning `notImplemented` and
/// skipping the sync entirely.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  /// Must match the entry in `Info.plist`'s
  /// `BGTaskSchedulerPermittedIdentifiers` array AND the value Dart's
  /// background entrypoint expects. Hard-coded rather than pulled from
  /// the bundle so a typo in `Info.plist` surfaces at registration
  /// time (iOS asserts on mismatch) rather than silently never firing.
  private static let refreshTaskIdentifier = "com.example.rostrikMvp.alarmSyncRefresh"

  /// Channel name shared with `lib/alarms/background_sync_entrypoint.dart`.
  /// Lives on its own dedicated channel — NOT the
  /// `rostrik/alarm_routing` channel used by the main UI engine for
  /// FullScreenIntent payload delivery on Android. Mixing them would
  /// mean the foreground notification-routing handler in `main.dart`
  /// could receive a stray `handlerReady`/`run` call from a background
  /// refresh that happens to overlap a warm app.
  private static let backgroundSyncChannel = "rostrik/alarm_sync_background"

  /// Minimum delay before iOS may fire the next refresh. iOS treats
  /// this as a lower bound; the real fire time can be hours later.
  /// 4h keeps the 14-day window from drifting more than a few hours
  /// behind without flogging the device.
  private static let refreshEarliestDelay: TimeInterval = 4 * 60 * 60

  /// Hard cap on how long we'll wait for the Dart sync to complete
  /// before giving up and reporting failure. 25s is comfortably under
  /// the ~30s budget `BGAppRefreshTask` provides; the expiration
  /// handler below is a defence-in-depth for the case where iOS yanks
  /// the budget early (low-power mode, thermal throttling).
  private static let syncTimeoutSeconds: TimeInterval = 25

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Registration MUST happen before this method returns. iOS asserts
    // on late registration with `Launch handler for task with identifier
    // <id> was not registered before app finished launching`. The
    // `using: nil` argument runs the handler on the main queue, which
    // is fine for our use — the actual sync runs in a separate Dart
    // isolate inside the headless engine, not on the main queue.
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: AppDelegate.refreshTaskIdentifier,
      using: nil
    ) { [weak self] task in
      guard let self = self, let refreshTask = task as? BGAppRefreshTask else {
        task.setTaskCompleted(success: false)
        return
      }
      self.handleAppRefresh(task: refreshTask)
    }

    // Submit the first refresh request as soon as the app finishes
    // launching. Cold-launch is the most reliable place to do this —
    // `applicationDidEnterBackground` is the textbook place but won't
    // fire on app uninstall / device reboot reinstall sequences where
    // the user hasn't backgrounded yet.
    scheduleNextRefresh()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    // Re-arm on every background transition. `BGTaskScheduler.submit`
    // is idempotent — submitting again while a request is already
    // pending replaces it, so we never have more than one queued.
    scheduleNextRefresh()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Implicit (UI) engine plugin registration — unchanged from the
    // pre-BGTaskScheduler delegate. The headless background engine
    // registers plugins separately inside `handleAppRefresh`.
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // MARK: - BGTaskScheduler

  private func scheduleNextRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: AppDelegate.refreshTaskIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: AppDelegate.refreshEarliestDelay)
    do {
      try BGTaskScheduler.shared.submit(request)
      NSLog("[Rostrik] BGTaskScheduler.submit OK; earliestBeginDate=\(request.earliestBeginDate!)")
    } catch {
      // Two known failure modes:
      //   1. BGTaskSchedulerErrorCodeNotPermitted — Background App
      //      Refresh is disabled in Settings. We can't fix that from
      //      code; the next user-initiated foreground will re-arm via
      //      didFinishLaunchingWithOptions.
      //   2. BGTaskSchedulerErrorCodeTooManyPendingTaskRequests — we
      //      tried to submit while one is already queued. Idempotent
      //      under our usage but logged for diagnostics.
      NSLog("[Rostrik] BGTaskScheduler.submit failed: \(error)")
    }
  }

  private func handleAppRefresh(task: BGAppRefreshTask) {
    NSLog("[Rostrik] BGAppRefreshTask fired — running background sync")

    // CRITICAL: re-arm BEFORE doing any work. If this run hangs, times
    // out, or crashes, we still want iOS to consider firing the next
    // one. Without this, a single bad run can break the refresh chain
    // until the user opens the app.
    scheduleNextRefresh()

    let engine = FlutterEngine(
      name: "rostrik_bg_sync_\(UUID().uuidString.prefix(8))"
    )

    // `run(withEntrypoint:)` returns synchronously after starting the
    // Dart isolate. The entrypoint itself runs asynchronously; we
    // coordinate readiness via the channel handshake below.
    guard engine.run(withEntrypoint: "syncAlarmsBackgroundEntrypoint") else {
      NSLog("[Rostrik] Failed to start background Flutter engine")
      task.setTaskCompleted(success: false)
      return
    }

    // Register plugins AFTER `engine.run` so the registrant has a
    // live binary messenger to attach to. Order matters here — the
    // reverse is undefined behaviour per Flutter's own docs.
    GeneratedPluginRegistrant.register(with: engine)

    let channel = FlutterMethodChannel(
      name: AppDelegate.backgroundSyncChannel,
      binaryMessenger: engine.binaryMessenger
    )

    // Two channel jobs to do, set up in dependency order:
    //
    //   1. Listen for `handlerReady` from Dart so we don't invoke
    //      `run` before the Dart side has wired its handler. Without
    //      this, the race window between `engine.run` returning and
    //      Dart's `setMethodCallHandler` executing can drop the
    //      `run` call as `notImplemented`.
    //   2. When the `run` callback returns, tear down the engine and
    //      mark the task complete.
    //
    // Both are guarded by the `taskCompleted` flag so the expiration
    // handler and the success path can't double-complete the task
    // (which crashes iOS).

    var taskCompleted = false
    let completeOnce: (Bool) -> Void = { [weak engine] success in
      guard !taskCompleted else { return }
      taskCompleted = true
      engine?.destroyContext()
      task.setTaskCompleted(success: success)
    }

    // iOS will call this if we run out of background time before
    // `setTaskCompleted` is invoked. Use it to tear down the engine
    // cleanly so a future task isn't blocked by a hung Dart isolate.
    task.expirationHandler = {
      NSLog("[Rostrik] BGAppRefreshTask expired before sync completed")
      completeOnce(false)
    }

    // Belt-and-braces timeout — fires if Dart hangs but iOS hasn't
    // yet pulled the budget. 25s is below the expirationHandler
    // window so we control the teardown rather than letting iOS do
    // it abruptly.
    DispatchQueue.main.asyncAfter(deadline: .now() + AppDelegate.syncTimeoutSeconds) {
      if !taskCompleted {
        NSLog("[Rostrik] Background sync hit \(AppDelegate.syncTimeoutSeconds)s timeout")
        completeOnce(false)
      }
    }

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "handlerReady":
        // Dart side is up. Safe to invoke `run` and let it do the
        // sync. The completion callback wraps `completeOnce` so the
        // race between this success and an expirationHandler firing
        // only counts the first one.
        NSLog("[Rostrik] Dart handler ready — invoking run")
        result(nil)
        channel.invokeMethod("run", arguments: nil) { runResult in
          if let error = runResult as? FlutterError {
            NSLog("[Rostrik] background sync error: \(error.message ?? "(nil)")")
            completeOnce(false)
          } else {
            NSLog("[Rostrik] background sync completed")
            completeOnce(true)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
