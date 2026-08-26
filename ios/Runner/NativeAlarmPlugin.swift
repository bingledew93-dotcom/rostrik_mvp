import Flutter
import Foundation
import UserNotifications

#if canImport(AlarmKit)
  import AlarmKit
#endif

/// iOS side of the `rostrik/native_alarms` MethodChannel.
///
/// ## Why this file exists
///
/// Rostrik's alarm engine is entirely native on Android: `AlarmManager`
/// `setAlarmClock` → `AlarmReceiver` → a foreground audio service → a
/// full-screen `AlarmActivity` over the keyguard, with boot re-arm from
/// device-protected storage. None of that has an iOS equivalent, and until this
/// file existed the iOS build had NO alarm delivery whatsoever — every
/// `NativeAlarmScheduler.scheduleAt` would have thrown `MissingPluginException`
/// (which the Dart side deliberately does not catch, since an unregistered
/// channel is a wiring bug, not a runtime condition).
///
/// The Dart contract is unchanged. `NativeAlarmScheduler` keeps its own ledger
/// and calls exactly three methods — `setExactAlarm`, `cancelAlarm`,
/// `getAliveAlarmIds` — so implementing the same channel here means iOS gets
/// alarms with no Dart branching at all.
///
/// ## Two backends
///
/// * **AlarmKit** (iOS 26+) — Apple's framework for exactly this app category.
///   It breaks through the silent switch and Focus, presents a system alarm UI,
///   and offers a real snooze. This is the path that gets close to the Android
///   behaviour.
/// * **UNUserNotificationCenter** (iOS 15.5+) — the fallback. A time-sensitive
///   notification with a bundled sound. It is a genuinely weaker alarm: the
///   sound is capped at ~30s and the ring switch silences it. Documented as a
///   limitation rather than papered over.
///
/// [AlarmBackend] picks between them once, at init.
///
/// ## ⚠️ AlarmKit code below is UNVERIFIED
///
/// It was written without a macOS toolchain to compile against, so treat
/// [AlarmKitBackend] as a structured starting point, not working code — expect
/// to correct the API surface against the SDK on the first Xcode build. The
/// notification backend uses long-stable API and should be sound. The two are
/// deliberately isolated so a rewrite of one cannot break the other, and so the
/// app still builds and rings via notifications while AlarmKit is being fixed
/// up. See `ios/IOS_SETUP.md` for the day-one checklist.
public final class NativeAlarmPlugin: NSObject {

  private static let channelName = "rostrik/native_alarms"

  /// Prefix for every request identifier we own, so `getAliveAlarmIds` can tell
  /// our alarms apart from the activity-reminder notifications that share the
  /// same notification centre.
  fileprivate static let identifierPrefix = "rostrik.alarm."

  private let backend: AlarmBackend

  private init(backend: AlarmBackend) {
    self.backend = backend
    super.init()
  }

  /// Call from `AppDelegate.didInitializeImplicitFlutterEngine`, passing the
  /// implicit engine's binary messenger.
  ///
  /// ⚠️ The handler closure captures `plugin` **strongly**, and that is
  /// load-bearing. `plugin` is a local, and every caller discards the return
  /// value, so a `[weak plugin]` capture left NOTHING owning the instance —
  /// ARC freed it the moment this function returned, and from then on every
  /// call fell through to `FlutterMethodNotImplemented`, i.e. the channel
  /// answered and did nothing while the app believed its alarms were armed.
  /// The strong capture parks ownership in the block the binary messenger
  /// retains, so the plugin lives exactly as long as its engine.
  /// The UI engine's channel, kept so native-side events (a spent alarm) can
  /// call INTO Dart. Deliberately only ever set for the UI engine: the headless
  /// BGTask engine is torn down with `destroyContext()` after every refresh, and
  /// invoking on a dead engine's channel is not safe.
  private static var uiChannel: FlutterMethodChannel?

  /// Tells Dart a spent alarm has just been written to the deletes ledger, so
  /// it can drain and reconcile now rather than on some later resume. A no-op
  /// when the UI engine isn't up — the ledger is durable, so the next launch
  /// drains it anyway.
  static func notifyDartSpentAlarmRecorded() {
    DispatchQueue.main.async {
      uiChannel?.invokeMethod("onSpentAlarmRecorded", arguments: nil)
    }
  }

  @discardableResult
  public static func register(
    with messenger: FlutterBinaryMessenger,
    isUiEngine: Bool = false
  ) -> NativeAlarmPlugin {
    let plugin = NativeAlarmPlugin(backend: makeBackend())
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      plugin.handle(call, result: result)
    }
    if isUiEngine { uiChannel = channel }
    // Foreground presentation. Without a delegate iOS shows NOTHING while the
    // app is frontmost — no banner, no sound — which reads exactly like "the
    // alarm never fired" during testing, the most common way to try one.
    ForegroundAlarmPresenter.install()
    return plugin
  }

  /// Flip to `true` ONLY once `AlarmKitBackend` is actually implemented and has
  /// rung on a device.
  ///
  /// This gate is the whole safety story for shipping an unfinished backend.
  /// Selecting AlarmKit purely on `#available(iOS 26.0, *)` would hand every
  /// modern iPhone a backend whose `schedule` currently fails — i.e. the newest
  /// devices would get NO alarms while older ones worked. Defaulting to
  /// notifications means the worst case is the documented weaker alarm, never
  /// a silent one.
  private static let alarmKitEnabled = false

  private static func makeBackend() -> AlarmBackend {
    #if canImport(AlarmKit)
      if alarmKitEnabled, #available(iOS 26.0, *) {
        return AlarmKitBackend()
      }
    #endif
    return NotificationBackend()
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setExactAlarm":
      guard let request = AlarmRequest(arguments: call.arguments) else {
        result(
          FlutterError(
            code: "BAD_ARGS",
            message: "setExactAlarm requires id and triggerAtMillis",
            details: nil))
        return
      }
      backend.schedule(request) { error in
        if let error {
          // Mirrors the Android contract: a refused schedule is reported as a
          // PlatformException, which the Dart side swallows WITHOUT recording
          // the id in its ledger — so the next reconcile sees the alarm as
          // missing and re-arms it. Never crash the reconcile over one alarm.
          result(
            FlutterError(
              code: "IOS_ALARM_DENIED", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }

    case "cancelAlarm":
      guard let id = (call.arguments as? [String: Any])?["id"] as? Int else {
        result(FlutterError(code: "BAD_ARGS", message: "cancelAlarm requires id", details: nil))
        return
      }
      backend.cancel(id: id)
      result(nil)

    // Harvests alarms iOS has already DELIVERED into the `pending_alarm_deletes`
    // ledger, so the existing Dart drain can retire spent one-time alarms.
    // Must be awaited before that drain runs — see the Dart side.
    case "recordSpentAlarms":
      backend.recordSpentAlarms { count in result(count) }

    case "getAliveAlarmIds":
      let ids = ((call.arguments as? [String: Any])?["ids"] as? [Int]) ?? []
      // Same purpose as the Android `FLAG_NO_CREATE` probe: the Dart ledger is
      // never trusted blind. Anything the OS no longer holds is pruned so the
      // reconciler re-arms it instead of believing a phantom.
      backend.aliveIds(among: ids) { alive in result(alive) }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// MARK: - Foreground presentation

/// Makes an alarm actually show and ring while Rostrik is the frontmost app.
///
/// `UNUserNotificationCenter` suppresses delivery entirely for a foregrounded
/// app unless a delegate answers `willPresent` — and neither `FlutterAppDelegate`
/// nor this project set one, so a notification scheduled and armed correctly
/// still produced no banner and no sound whenever the user was looking at the
/// app. That is the exact situation someone testing an alarm is in.
///
/// A dedicated singleton rather than the plugin itself because
/// `UNUserNotificationCenter.delegate` is a **weak** reference: the background
/// BGTask engine is torn down after every refresh (`destroyContext`), so a
/// per-engine plugin acting as delegate would leave the property nil the first
/// time one of those runs, silently reverting to the silent-in-foreground
/// behaviour. This instance is owned by a static and outlives every engine.
final class ForegroundAlarmPresenter: NSObject, UNUserNotificationCenterDelegate {

  private static let shared = ForegroundAlarmPresenter()

  /// Category carrying the Snooze button. Must be registered before any alarm
  /// is delivered, or the notification shows with no actions.
  static let alarmCategoryIdentifier = "ROSTRIK_ALARM"
  private static let snoozeActionIdentifier = "ROSTRIK_SNOOZE"

  /// Idempotent — safe to call from each engine's plugin registration.
  static func install() {
    let center = UNUserNotificationCenter.current()
    center.delegate = shared
    let snooze = UNNotificationAction(
      identifier: snoozeActionIdentifier,
      title: "Snooze",
      options: [])
    center.setNotificationCategories([
      UNNotificationCategory(
        identifier: alarmCategoryIdentifier,
        actions: [snooze],
        intentIdentifiers: [],
        // `.customDismissAction` is what makes an explicit swipe-away reach
        // `didReceive` at all. Without it iOS silently drops that response and
        // a dismissed one-time alarm is never retired.
        options: [.customDismissAction])
    ])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    guard response.actionIdentifier != Self.snoozeActionIdentifier else {
      snooze(response.notification, completionHandler: completionHandler)
      return
    }
    // Anything else — a tap that opens the app, or an explicit dismiss — means
    // this alarm is SPENT. This is the only dependable "it fired" signal iOS
    // offers: it is delivered even when the app was killed (iOS launches it to
    // hand the response over), unlike `getDeliveredNotifications`, which sees
    // only notifications still sitting in Notification Center and therefore
    // misses the most common case of all — the user dismissing one.
    recordSpent(response.notification)
    completionHandler()
  }

  /// Appends a fired alarm's owning rule to the deletes ledger, then tells Dart
  /// to drain it.
  ///
  /// The nudge to Dart is what makes retirement immediate rather than
  /// eventual. Tapping a notification foregrounds the app, so the resume-time
  /// drain has usually already run by the time iOS delivers this response —
  /// leaving the ledger sitting unread until some later resume, during which
  /// the reconciler happily re-projects the spent alarm to tomorrow.
  private func recordSpent(_ notification: UNNotification) {
    guard
      notification.request.identifier.hasPrefix(NativeAlarmPlugin.identifierPrefix),
      let appAlarmId = notification.request.content.userInfo["appAlarmId"] as? String,
      !appAlarmId.isEmpty
    else { return }
    RostrikLedger.append(appAlarmId, to: RostrikLedger.alarmDeletes)
    NSLog("[Rostrik] alarm \(notification.request.identifier) spent — queued for cleanup")
    NativeAlarmPlugin.notifyDartSpentAlarmRecorded()
  }

  /// Re-arms this alarm and records the snooze, mirroring the Android
  /// `AlarmActivity` Snooze contract documented on `pendingSnoozesFileName`:
  ///
  ///   1. re-arm the SAME notification identifier (so the Dart ledger entry for
  ///      this id stays truthful and the reconcile REPLACES in place rather
  ///      than treating it as an orphan), and
  ///   2. append `<shiftId>|<appAlarmId>|<untilMillis>` to `pending_snoozes`.
  ///
  /// Step 2 is what stops the next reconcile cancelling the re-armed alarm: the
  /// drain sets `Shift.snoozedUntil` BEFORE any reconcile, so `projectAlarmRings`
  /// resurrects the ring at that instant instead of seeing an unacknowledged
  /// shift whose fire time has passed. Writing the ledger BEFORE re-arming
  /// means a crash in between loses the alarm, not the user's snooze intent —
  /// the reconcile re-arms from `snoozedUntil` either way.
  private func snooze(_ notification: UNNotification, completionHandler: @escaping () -> Void) {
    let request = notification.request
    let info = request.content.userInfo
    let minutes = (info["snoozeMinutes"] as? Int) ?? 1
    let until = Date(timeIntervalSinceNow: TimeInterval(minutes * 60))

    appendSnoozeLedgerLine(
      shiftId: (info["alarm_id"] as? String) ?? "",
      appAlarmId: (info["appAlarmId"] as? String) ?? "",
      until: until)

    let components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute, .second], from: until)
    UNUserNotificationCenter.current().add(
      UNNotificationRequest(
        identifier: request.identifier,  // same id ⇒ replace, per the contract
        content: request.content,
        trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
    ) { error in
      if let error {
        NSLog("[Rostrik] snooze re-arm FAILED \(request.identifier): \(error.localizedDescription)")
      } else {
        NSLog("[Rostrik] snoozed \(request.identifier) until \(until)")
      }
      completionHandler()
    }
  }

  /// Appends `<shiftId>|<appAlarmId>|<untilMillis>` to the snooze ledger that
  /// `drainPendingSnoozesIntoHive` reads. That drain is plain file I/O with no
  /// MethodChannel involved, so it already worked on iOS; this writer was the
  /// only missing half.
  private func appendSnoozeLedgerLine(shiftId: String, appAlarmId: String, until: Date) {
    let millis = Int(until.timeIntervalSince1970 * 1000)
    RostrikLedger.append("\(shiftId)|\(appAlarmId)|\(millis)", to: RostrikLedger.snoozes)
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler:
      @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Both of Rostrik's notification surfaces, not just alarms. Scoping this to
    // the alarm prefix alone silently suppressed every reminder and sleep nudge
    // whenever the app was open — indistinguishable from iOS "not allowing"
    // foreground notifications, when in fact this delegate is the only thing
    // that decides.
    let identifier = notification.request.identifier
    guard identifier.hasPrefix(NativeAlarmPlugin.identifierPrefix)
      || identifier.hasPrefix(ActivityReminderPlugin.identifierPrefix)
    else {
      completionHandler([])
      return
    }
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }
}

// MARK: - Wire model

/// One `setExactAlarm` call, decoded. Field names must stay in lock-step with
/// the `_arg*` constants in `lib/alarms/native_alarm_scheduler.dart`.
struct AlarmRequest {
  let id: Int
  let fireAt: Date
  /// Notification title — the alarm's label.
  let label: String
  /// Ring time pre-formatted 12-hour by Dart ("03:00 AM").
  let displayTime: String
  /// Short shift context ("Before your Night shift").
  let body: String
  /// iOS sound filename ("classic.wav") resolved from the bundled catalogue.
  /// Note this is NOT `bundledResource`, which is the Android `res/raw` name.
  let iosSound: String?
  /// Owning shift UUID, or the "NONE" sentinel for a shift-less one-off.
  let shiftId: String
  /// Owning AppAlarm UUID.
  let appAlarmId: String
  let snoozeMinutes: Int
  /// Critical shifts require a sustained shake to dismiss on Android. There is
  /// no equivalent gesture gate on either iOS path; carried so the eventual
  /// AlarmKit presentation can at least reflect the distinction.
  let requiresShake: Bool

  init?(arguments: Any?) {
    guard let args = arguments as? [String: Any],
      let id = args["id"] as? Int,
      let millis = args["triggerAtMillis"] as? Int
    else { return nil }
    self.id = id
    self.fireAt = Date(timeIntervalSince1970: TimeInterval(millis) / 1000.0)
    self.label = args["label"] as? String ?? "Rostrik alarm"
    self.displayTime = args["displayTime"] as? String ?? ""
    self.body = args["body"] as? String ?? ""
    self.iosSound = args["iosSound"] as? String
    self.shiftId = args["alarm_id"] as? String ?? ""
    self.appAlarmId = args["appAlarmId"] as? String ?? ""
    self.snoozeMinutes = args["snoozeMinutes"] as? Int ?? 1
    self.requiresShake = args["requiresShake"] as? Bool ?? false
  }

  var requestIdentifier: String { "\(NativeAlarmPlugin.identifierPrefix)\(id)" }
}

/// What both backends must provide. Deliberately narrow: the Dart reconciler
/// owns all the scheduling policy, so a backend only arms, cancels, and reports
/// what it is actually holding.
protocol AlarmBackend {
  func schedule(_ request: AlarmRequest, completion: @escaping (Error?) -> Void)
  func cancel(id: Int)
  func aliveIds(among ids: [Int], completion: @escaping ([Int]) -> Void)
  /// Records alarms that have already fired into the `pending_alarm_deletes`
  /// ledger. See `NotificationBackend`'s implementation for why this exists.
  func recordSpentAlarms(completion: @escaping (Int) -> Void)
}

extension AlarmBackend {
  /// Backends with no notion of a "delivered" alarm opt out. AlarmKit tracks
  /// its own alarm lifecycle and would retire a one-shot itself.
  func recordSpentAlarms(completion: @escaping (Int) -> Void) { completion(0) }
}

// MARK: - Ledger files

/// Append-only handoff files in Application Support, written natively and
/// drained by Dart. This is the same directory `path_provider`'s
/// `getApplicationSupportDirectory()` resolves to, which is how the Dart side
/// finds them — plain file I/O, no MethodChannel, so the drains work
/// identically on both platforms and in the headless background isolate.
///
/// Filenames MUST match the Dart constants (`pendingSnoozesFileName`,
/// `pendingAlarmDeletesFileName`) and the Kotlin ones.
enum RostrikLedger {
  static let snoozes = "pending_snoozes"
  static let alarmDeletes = "pending_alarm_deletes"

  /// Appends one line, creating the file (and directory) if needed.
  /// Best-effort: a lost line costs one uncleaned alarm, never a crash on the
  /// boot path.
  static func append(_ line: String, to fileName: String) {
    let fm = FileManager.default
    guard let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    else {
      NSLog("[Rostrik] ledger: no Application Support directory")
      return
    }
    if !fm.fileExists(atPath: dir.path) {
      try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    let file = dir.appendingPathComponent(fileName)
    guard let data = "\(line)\n".data(using: .utf8) else { return }
    if let handle = try? FileHandle(forWritingTo: file) {
      defer { try? handle.close() }
      handle.seekToEndOfFile()
      handle.write(data)
    } else {
      try? data.write(to: file, options: .atomic)
    }
  }
}

// MARK: - UNUserNotificationCenter backend (iOS 15.5+)

/// The fallback path, and the floor of what iOS guarantees.
///
/// Known limitations, all inherent to notifications rather than to this code —
/// they are the reason AlarmKit is preferred above:
///   * the sound stops after ~30 seconds;
///   * the ring/silent switch and Focus modes silence it (`.critical` would
///     pierce both, but needs an Apple-approved entitlement we have not
///     applied for);
///   * there is no full-screen wake surface and no shake-to-dismiss;
///   * iOS caps the app at 64 pending notifications. Rostrik's 14-day / 50-alarm
///     horizon fits under that, but the activity-reminder path shares the same
///     budget — worth watching.
final class NotificationBackend: AlarmBackend {

  private let center = UNUserNotificationCenter.current()

  func schedule(_ request: AlarmRequest, completion: @escaping (Error?) -> Void) {
    let content = UNMutableNotificationContent()
    content.title = request.label
    // Match the Android notification's split: the clock value lives in
    // displayTime, the context in body, so neither repeats the other.
    content.body = [request.displayTime, request.body]
      .filter { !$0.isEmpty }
      .joined(separator: " — ")
    content.sound = request.iosSound.map {
      UNNotificationSound(named: UNNotificationSoundName($0))
    } ?? .default
    // Time-sensitive breaks through most Focus modes without any entitlement.
    // It does NOT beat the ring switch — see the type doc.
    if #available(iOS 15.0, *) { content.interruptionLevel = .timeSensitive }
    // Carries the Snooze action. iOS has no full-screen alarm surface, so the
    // notification itself has to be the whole control affordance.
    content.categoryIdentifier = ForegroundAlarmPresenter.alarmCategoryIdentifier
    content.userInfo = [
      "alarm_id": request.shiftId,
      "appAlarmId": request.appAlarmId,
      "snoozeMinutes": request.snoozeMinutes,
      "requiresShake": request.requiresShake,
    ]

    // A calendar trigger rather than a time-interval one: it is anchored to
    // wall-clock components, so it survives the device clock being adjusted
    // between arming and firing (the same failure the Android BootReceiver
    // re-syncs for on TIME_SET / TIMEZONE_CHANGED).
    let components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute, .second], from: request.fireAt)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    // `add` replaces any request with the same identifier, which is exactly the
    // replace-by-id semantics `AlarmScheduler.scheduleAt` specifies.
    center.add(
      UNNotificationRequest(
        identifier: request.requestIdentifier, content: content, trigger: trigger)
    ) { error in
      // NSLog, not debugPrint: alarms can only be judged on a real device, and
      // a device build is a RELEASE build where Dart's debugPrint is compiled
      // out. This is the only channel that still talks on the far side.
      if let error {
        NSLog("[Rostrik] schedule FAILED id=\(request.id): \(error.localizedDescription)")
      } else {
        NSLog(
          "[Rostrik] scheduled id=\(request.id) at \(request.fireAt) "
            + "sound=\(request.iosSound ?? "default")")
      }
      DispatchQueue.main.async { completion(error) }
    }

    // Authorisation is the other half of "armed but silent": `add` succeeds
    // even when the user has never granted permission, and the notification is
    // simply dropped at delivery time.
    center.getNotificationSettings { settings in
      NSLog(
        "[Rostrik] auth=\(settings.authorizationStatus.rawValue) "
          + "sound=\(settings.soundSetting.rawValue) alert=\(settings.alertSetting.rawValue)")
    }
  }

  func cancel(id: Int) {
    let identifier = "\(NativeAlarmPlugin.identifierPrefix)\(id)"
    center.removePendingNotificationRequests(withIdentifiers: [identifier])
    center.removeDeliveredNotifications(withIdentifiers: [identifier])
  }

  /// Retires spent alarms by recording every DELIVERED alarm notification's
  /// `appAlarmId` into the `pending_alarm_deletes` ledger.
  ///
  /// ## Why this is needed, and why it looks nothing like Android
  ///
  /// Android writes that ledger from `AlarmActivity` / `AlarmAudioService` at
  /// fire time. iOS runs NO app code when a notification fires, so there is
  /// nothing to write it — and without it, `drainPendingAlarmDeletesIntoHive`
  /// always found an empty file. The consequence was severe and silent: a spent
  /// one-time alarm was never deleted, so the next reconcile re-projected it to
  /// "the next future occurrence of minutesOfDay", i.e. **a one-time alarm
  /// quietly became a daily one** and kept waking the user every morning.
  ///
  /// iOS cannot tell us at fire time, but it does remember what it DELIVERED,
  /// so this asks after the fact instead — the same shape as `aliveIds`, which
  /// likewise trusts the OS over any local belief.
  ///
  /// Delivered notifications are removed once recorded: leaving them would
  /// re-harvest the same ids on every launch, and an alarm whose rule has just
  /// been deleted should not still be sitting in Notification Center.
  ///
  /// Every delivered alarm is recorded, not just one-time ones — the Dart drain
  /// resolves each id and deletes only the one-time rules, exactly as it does
  /// for Android. A repeating alarm's id is therefore a harmless no-op.
  ///
  /// A SNOOZED alarm is not affected: acting on a notification removes it from
  /// Notification Center, so it is not "delivered" here, and its re-armed
  /// request is pending rather than delivered.
  func recordSpentAlarms(completion: @escaping (Int) -> Void) {
    center.getDeliveredNotifications { notifications in
      let ours = notifications.filter {
        $0.request.identifier.hasPrefix(NativeAlarmPlugin.identifierPrefix)
      }
      var recorded = 0
      for notification in ours {
        guard
          let appAlarmId = notification.request.content.userInfo["appAlarmId"] as? String,
          !appAlarmId.isEmpty
        else { continue }
        RostrikLedger.append(appAlarmId, to: RostrikLedger.alarmDeletes)
        recorded += 1
      }
      if !ours.isEmpty {
        self.center.removeDeliveredNotifications(
          withIdentifiers: ours.map { $0.request.identifier })
      }
      if recorded > 0 {
        NSLog("[Rostrik] recorded \(recorded) spent alarm(s) for cleanup")
      }
      DispatchQueue.main.async { completion(recorded) }
    }
  }

  func aliveIds(among ids: [Int], completion: @escaping ([Int]) -> Void) {
    center.getPendingNotificationRequests { requests in
      let pending = Set(
        requests.compactMap { request -> Int? in
          guard request.identifier.hasPrefix(NativeAlarmPlugin.identifierPrefix) else {
            return nil
          }
          return Int(request.identifier.dropFirst(NativeAlarmPlugin.identifierPrefix.count))
        })
      DispatchQueue.main.async { completion(ids.filter { pending.contains($0) }) }
    }
  }
}

// MARK: - AlarmKit backend (iOS 26+)

#if canImport(AlarmKit)

  /// ⚠️ **UNVERIFIED — see the file header.** Written without a compiler; the
  /// AlarmKit type and method names below are a best-effort reconstruction and
  /// are the first thing to check against the SDK on the Mac.
  ///
  /// What must be true for this path to work, independent of API details:
  ///
  ///   1. `NSAlarmKitUsageDescription` is present in `Info.plist` (added).
  ///   2. Authorisation is requested once before the first schedule. Until it
  ///      is granted, every `schedule` must fail loudly enough that the Dart
  ///      ledger does not record the id — which the error path here does.
  ///   3. AlarmKit keys alarms by `UUID`, while Rostrik's whole engine keys by
  ///      `Int`. [alarmUUID] derives one deterministically from the other so
  ///      cancel and liveness probes resolve without a second ledger.
  ///   4. The alert presentation needs a widget extension target. If that is
  ///      not wired yet, this backend must not be selected — hence the
  ///      capability check in `NativeAlarmPlugin.makeBackend`.
  @available(iOS 26.0, *)
  final class AlarmKitBackend: AlarmBackend {

    /// Namespaces an `Int` alarm id into a stable `UUID`. Deterministic, so the
    /// same id always resolves to the same alarm with nothing persisted here.
    static func alarmUUID(for id: Int) -> UUID {
      var bytes = [UInt8](repeating: 0, count: 16)
      // Fixed namespace prefix ("ROSTRIK\0") + the big-endian id.
      let namespace: [UInt8] = [0x52, 0x4F, 0x53, 0x54, 0x52, 0x49, 0x4B, 0x00]
      for (index, byte) in namespace.enumerated() { bytes[index] = byte }
      var value = UInt64(bitPattern: Int64(id)).bigEndian
      withUnsafeBytes(of: &value) { raw in
        for offset in 0..<8 { bytes[8 + offset] = raw[offset] }
      }
      return UUID(uuid: (
        bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
        bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
      ))
    }

    func schedule(_ request: AlarmRequest, completion: @escaping (Error?) -> Void) {
      // TODO(mac): build the real AlarmKit configuration here. Shape to verify:
      //   - request/inspect authorisation via AlarmManager.shared
      //   - Alarm.Schedule.fixed(request.fireAt)
      //   - AlarmAttributes with an AlarmPresentation carrying request.label,
      //     a stop button, and a snooze secondary button of
      //     request.snoozeMinutes
      //   - the bundled tone (request.iosSound) as the alarm sound
      //   - AlarmManager.shared.schedule(id: Self.alarmUUID(for: request.id),
      //                                  configuration: configuration)
      //
      // Until that is filled in, fail rather than silently drop the alarm: the
      // error keeps the id OUT of the Dart ledger, so the reconciler re-arms
      // rather than believing a phantom. A silent success here would be the
      // worst possible outcome — an alarm the app thinks is set and that never
      // rings.
      completion(
        NSError(
          domain: "rostrik.alarmkit", code: -1,
          userInfo: [NSLocalizedDescriptionKey: "AlarmKit backend not yet implemented"]))
    }

    func cancel(id: Int) {
      // TODO(mac): AlarmManager.shared.cancel(id: Self.alarmUUID(for: id))
    }

    func aliveIds(among ids: [Int], completion: @escaping ([Int]) -> Void) {
      // TODO(mac): intersect `ids` with AlarmManager.shared's live alarm set.
      // Reporting "none alive" is the SAFE default: the reconciler responds by
      // re-arming, whereas over-reporting would leave real gaps unfilled.
      completion([])
    }
  }

#endif
