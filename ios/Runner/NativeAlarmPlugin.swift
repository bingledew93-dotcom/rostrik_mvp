import Flutter
import Foundation
import UserNotifications

#if canImport(AlarmKit)
  import ActivityKit
  import AlarmKit
  import SwiftUI
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
/// The two are deliberately isolated so a change to one cannot break the other,
/// and so the app keeps ringing via notifications while AlarmKit is finished.
/// [AlarmKitBackend] now compiles against the real SDK, but is still gated off —
/// see `alarmKitEnabled` and the notes on that class for what is outstanding.
/// See `ios/IOS_SETUP.md` for the device checklist.
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

    // ── AlarmKit bring-up (Phase B) ───────────────────────────────────────
    // Diagnostics, not product surface. They exist because the two questions
    // that decide the AlarmKit design — does it present without a widget
    // extension, and how many alarms will it hold — can only be answered on a
    // real device running iOS 26.

    /// Reports what this device could do, without changing anything.
    case "alarmKitStatus":
      var status: [String: Any] = ["compiled": false, "available": false, "authorized": false]
      #if canImport(AlarmKit)
        status["compiled"] = true
        if #available(iOS 26.0, *) {
          status["available"] = true
          status["authorized"] =
            AlarmManager.shared.authorizationState == .authorized
        }
      #endif
      status["enabled"] = Self.alarmKitEnabled
      // NSLog rather than returning quietly: on a profile build — the only kind
      // that runs standalone on the device — Dart's own logging never reaches
      // the console, so native is the only channel that talks.
      NSLog("[Rostrik] AlarmKit status \(status)")
      result(status)

    case "alarmKitAuthorize":
      #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
          AlarmKitBackend.requestAuthorization { granted in result(granted) }
          return
        }
      #endif
      result(false)

    case "alarmKitProbeLimit":
      #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
          let bound = ((call.arguments as? [String: Any])?["bound"] as? Int) ?? 64
          AlarmKitBackend.probeAlarmLimit(upTo: bound) { limit in result(limit) }
          return
        }
      #endif
      result(-1)

    case "alarmKitProbeReplace":
      #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
          AlarmKitBackend.probeReplaceSemantics { verdict in result(verdict) }
          return
        }
      #endif
      result("unavailable")

    /// Arms ONE real AlarmKit alarm a few seconds out, through the production
    /// `configuration(for:)` path.
    ///
    /// This is the only way to answer the question the limit probe cannot: an
    /// AlarmKit alert is a Live Activity, and we have no widget extension yet.
    /// Whether it still presents — and whether the bundled `.caf` rings past the
    /// 30s that caps the notification path — is observable only by letting one
    /// fire. Scheduling it exactly as production would means a pass here is
    /// evidence about production, not about a special case.
    ///
    /// Uses a negative id so it can never collide with a real alarm, and writes
    /// no ledger entry, so nothing in the Dart reconciler reacts to it.
    case "alarmKitTestAlarm":
      #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
          let args = (call.arguments as? [String: Any]) ?? [:]
          let seconds = (args["seconds"] as? Int) ?? 60
          let fireAt = Date(timeIntervalSinceNow: TimeInterval(seconds))
          guard
            let request = AlarmRequest(arguments: [
              "id": -999,
              "triggerAtMillis": Int(fireAt.timeIntervalSince1970 * 1000),
              "label": "Rostrik AlarmKit test",
              "displayTime": "",
              "body": "Phase B bring-up",
              "iosSound": (args["sound"] as? String) ?? "classic.caf",
              "alarm_id": "TEST",
              "appAlarmId": "TEST",
              "snoozeMinutes": 1,
            ])
          else {
            result(false)
            return
          }
          AlarmKitBackend().schedule(request) { error in
            NSLog(
              "[Rostrik] AlarmKit test alarm for \(fireAt): "
                + (error?.localizedDescription ?? "ARMED"))
            result(error == nil)
          }
          return
        }
      #endif
      result(false)

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
      // Snooze is a response too: stop the current ring before re-arming, or
      // the queued links keep firing straight through the snooze window.
      endChain(for: response.notification)
      snooze(response.notification, completionHandler: completionHandler)
      return
    }
    // Anything else — a tap that opens the app, or an explicit dismiss — means
    // this alarm is SPENT. This is the only dependable "it fired" signal iOS
    // offers: it is delivered even when the app was killed (iOS launches it to
    // hand the response over), unlike `getDeliveredNotifications`, which sees
    // only notifications still sitting in Notification Center and therefore
    // misses the most common case of all — the user dismissing one.
    //
    // Tearing down the repeat chain FIRST is the whole safety story for it: the
    // user has just told us to stop, and every remaining link is already queued
    // inside iOS. This fires for a response to any link too, not only the
    // primary, so dismissing the fourth buzz silences the rest.
    endChain(for: response.notification)
    recordSpent(response.notification)
    completionHandler()
  }

  /// Cancels every remaining alert for the alarm this notification belongs to.
  /// Resolves the owning id from either the primary or a link, so a response to
  /// any buzz in the chain silences all of them.
  private func endChain(for notification: UNNotification) {
    guard let id = AlarmChain.baseId(from: notification.request.identifier) else { return }
    AlarmChain.cancelAll(for: id, in: UNUserNotificationCenter.current())
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
  /// How many follow-up alerts to queue after this alarm so it keeps ringing
  /// past the ~30s sound cap. 0 = a single alert. See `AlarmChain`.
  let repeatChain: Int
  /// Spacing between those alerts. Sent by Dart so the cadence lives with the
  /// budget arithmetic that pays for it (`ios_notification_budget.dart`).
  let repeatIntervalSeconds: Double
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
    self.repeatChain = args["repeatChain"] as? Int ?? 0
    self.repeatIntervalSeconds =
      (args["repeatIntervalSeconds"] as? NSNumber)?.doubleValue ?? 30
    self.requiresShake = args["requiresShake"] as? Bool ?? false
  }

  var requestIdentifier: String { AlarmChain.primaryIdentifier(for: id) }
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

// MARK: - Repeat chain

/// Identifier scheme for an alarm's repeat chain — the follow-up alerts that
/// keep it ringing past iOS's ~30s notification sound cap.
///
/// Android rings until dismissed because it owns a foreground audio service for
/// the alarm's duration. iOS runs no app code when a notification fires, so the
/// only way to keep alerting is to queue the follow-ups IN ADVANCE and cancel
/// whatever is left the moment the user responds.
///
/// **Cancelling is the load-bearing half.** A chain that outlives its dismissal
/// is worse than a short alarm, because the user cannot turn it off. Every
/// path that ends an alarm — cancel, dismiss, tap, snooze — must sweep it.
///
/// Members are suffixed `.r1`…`.rN` rather than given ids of their own, so the
/// Dart reconciler never sees them: `aliveIds` parses an Int out of the
/// identifier, and "7.r3" is not one, so a chain member is ignored rather than
/// mistaken for an orphaned alarm and cancelled mid-ring.
enum AlarmChain {
  /// Generous upper bound for cancellation sweeps. Independent of how many
  /// links Dart currently asks for, so shortening the chain later cannot strand
  /// members scheduled by an older build. Removing an identifier that was never
  /// scheduled is a no-op.
  static let maxLinks = 16

  static func primaryIdentifier(for id: Int) -> String {
    "\(NativeAlarmPlugin.identifierPrefix)\(id)"
  }

  static func linkIdentifier(for id: Int, link: Int) -> String {
    "\(primaryIdentifier(for: id)).r\(link)"
  }

  /// Every identifier an alarm could own — the alarm itself plus every possible
  /// link. Used to tear the whole thing down in one call.
  static func allIdentifiers(for id: Int) -> [String] {
    [primaryIdentifier(for: id)]
      + (1...maxLinks).map { linkIdentifier(for: id, link: $0) }
  }

  /// The owning alarm id for any identifier of ours, primary or link, so a
  /// response to a chain member tears down the same chain the primary would.
  static func baseId(from identifier: String) -> Int? {
    guard identifier.hasPrefix(NativeAlarmPlugin.identifierPrefix) else { return nil }
    let tail = identifier.dropFirst(NativeAlarmPlugin.identifierPrefix.count)
    let base = tail.split(separator: ".").first.map(String.init) ?? String(tail)
    return Int(base)
  }

  /// Removes an alarm and every link, pending or already delivered. Safe to
  /// call for an alarm that never had a chain.
  static func cancelAll(for id: Int, in center: UNUserNotificationCenter) {
    let ids = allIdentifiers(for: id)
    center.removePendingNotificationRequests(withIdentifiers: ids)
    center.removeDeliveredNotifications(withIdentifiers: ids)
  }
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
    // Queue the follow-up alerts BEFORE the primary's completion, so a chained
    // alarm is armed as one unit. Each reuses the primary's content, so every
    // alert in the chain looks and sounds identical — the user should not be
    // able to tell the fourth buzz from the first.
    if request.repeatChain > 0 {
      // Clear any longer chain a previous schedule left behind. `add` replaces
      // by identifier, so the primary and the links we are about to write take
      // care of themselves — the stale TAIL beyond the new length would not.
      center.removePendingNotificationRequests(
        withIdentifiers: (1...AlarmChain.maxLinks).map {
          AlarmChain.linkIdentifier(for: request.id, link: $0)
        })
      for link in 1...request.repeatChain {
        let at = request.fireAt.addingTimeInterval(
          Double(link) * request.repeatIntervalSeconds)
        let linkComponents = Calendar.current.dateComponents(
          [.year, .month, .day, .hour, .minute, .second], from: at)
        center.add(
          UNNotificationRequest(
            identifier: AlarmChain.linkIdentifier(for: request.id, link: link),
            content: content,
            trigger: UNCalendarNotificationTrigger(
              dateMatching: linkComponents, repeats: false))
        ) { error in
          if let error {
            NSLog(
              "[Rostrik] chain link \(link) FAILED id=\(request.id): "
                + error.localizedDescription)
          }
        }
      }
      NSLog(
        "[Rostrik] armed \(request.repeatChain) repeat(s) for id=\(request.id) "
          + "(~\(Int(Double(request.repeatChain) * request.repeatIntervalSeconds))s of ringing)")
    }

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
    // The whole chain, not just the primary — a surviving link would ring for
    // an alarm the app has already cancelled, with nothing left to stop it.
    AlarmChain.cancelAll(for: id, in: center)
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
        // Silence anything still queued for those alarms. Reaching this code
        // means the app is running and the user has seen the alarm, so the
        // remaining buzzes would be noise — and unlike a response, opening the
        // app never cancels them on its own.
        for id in Set(ours.compactMap { AlarmChain.baseId(from: $0.request.identifier) }) {
          AlarmChain.cancelAll(for: id, in: self.center)
        }
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

  /// The iOS 26+ path: a real system alarm rather than a notification.
  ///
  /// Every API call below is verified against the iOS 26.5 SDK's
  /// `AlarmKit.swiftinterface` and typechecked by the compiler — not taken from
  /// documentation. That distinction matters here: the AlarmKit guide bundled
  /// with Xcode's assistant is wrong in several specifics (it dates the
  /// framework to iOS 18, invents `AlarmButton(label:)` and `.stopButton` /
  /// `.snoozeButton` statics that do not exist, and makes `cancel` async when it
  /// is synchronous). An earlier draft of this class was written from that shape
  /// and would not have compiled.
  ///
  /// ## What AlarmKit buys us
  ///
  /// It is heard through the ring/silent switch and Focus, it presents a system
  /// alarm UI, and — the part that fixes our worst design compromise — its Stop
  /// and Snooze buttons are `LiveActivityIntent`s, so **our code runs when the
  /// user responds**. Under notifications nothing does, which is why
  /// `NotificationBackend.recordSpentAlarms` has to reconstruct what happened
  /// after the fact by inspecting delivered notifications.
  ///
  /// ## ⚠️ Not yet safe to enable — see `alarmKitEnabled`
  ///
  /// Two things are still missing, and the second is a correctness bug:
  ///
  ///   1. **No widget extension yet.** `AlarmAttributes` is an
  ///      `ActivityKit.ActivityAttributes`, so the alarm UI is a Live Activity
  ///      and needs a second target to render it. Whether the *alert* presents
  ///      without one — as opposed to the countdown, which certainly does not —
  ///      is exactly what the first device test is for. Until that is known this
  ///      schedules a stop-only alert with no countdown, which is the smallest
  ///      thing that answers the question.
  ///   2. **One-time alarms would not retire.** `recordSpentAlarms` is
  ///      inherited as a no-op, so nothing writes the deletes ledger when an
  ///      AlarmKit alarm fires — which is precisely the fault that turned a
  ///      one-time alarm into a daily one on the notification path. The fix is
  ///      the Stop intent (item 1's widget extension work), not more
  ///      after-the-fact inspection. Do not flip the gate before it exists.
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

    /// Builds the alarm exactly as Rostrik's engine describes it.
    ///
    /// `.fixed(Date)` rather than `.relative(time:repeats:)` because Rostrik's
    /// reconciler already resolves every occurrence to an absolute instant. The
    /// recurrence AlarmKit offers is `.weekly([Locale.Weekday])`, which a
    /// rotating roster is not — a 4-on-4-off pattern never repeats weekly. So we
    /// arm one alarm per occurrence, which is also what makes AlarmKit's own
    /// alarm cap (see `AlarmManager.AlarmError.maximumLimitReached`) a live
    /// constraint rather than an academic one.
    static func configuration(for request: AlarmRequest)
      -> AlarmManager.AlarmConfiguration<RostrikAlarmMetadata>
    {
      let stop = AlarmButton(
        text: "Stop", textColor: .white, systemImageName: "stop.circle.fill")
      let snooze = AlarmButton(
        text: "Snooze", textColor: .white, systemImageName: "zzz")

      // `.countdown` hands the snooze to AlarmKit: it re-alerts after
      // `postAlert` below without us re-arming anything. That is a real
      // improvement on the notification path, which has to re-add the same
      // identifier by hand and keep the Dart ledger truthful about it.
      //
      // The stop button is required by the iOS 26.0 initialiser and deprecated
      // by the 26.1 one, which drops it in favour of a system-drawn control.
      // Both are called, because our availability floor for this backend is 26.0.
      let alert: AlarmPresentation.Alert
      if #available(iOS 26.1, *) {
        alert = AlarmPresentation.Alert(
          title: LocalizedStringResource(stringLiteral: request.label),
          secondaryButton: snooze,
          secondaryButtonBehavior: .countdown)
      } else {
        alert = AlarmPresentation.Alert(
          title: LocalizedStringResource(stringLiteral: request.label),
          stopButton: stop,
          secondaryButton: snooze,
          secondaryButtonBehavior: .countdown)
      }

      let attributes = AlarmAttributes<RostrikAlarmMetadata>(
        presentation: AlarmPresentation(alert: alert),
        metadata: RostrikAlarmMetadata(
          shiftId: request.shiftId, appAlarmId: request.appAlarmId),
        tintColor: .orange)

      // The same bundled `.caf` the notification path uses. Those files are
      // pre-looped to fill iOS's ~30s notification ceiling
      // (`ios/tools/generate_alarm_tones.sh`); AlarmKit has no such ceiling and
      // sustains the alarm itself, so the pre-looping is now merely harmless.
      let sound: ActivityKit.AlertConfiguration.AlertSound =
        request.iosSound.map { .named($0) } ?? .default

      // `postAlert` is how long AlarmKit waits before re-alerting a snoozed
      // alarm — the user's own snooze setting, so iOS matches Android rather
      // than imposing Apple's 9 minutes. `preAlert` stays nil: that is the timer
      // case, counting down TO the alarm, which Rostrik does not have.
      //
      // ⚠️ A countdown presentation may need the widget extension the alert
      // turned out not to need. If snooze proves not to work on device, the
      // fallback is `.custom` behaviour plus an intent that stops and re-arms
      // the alarm itself, the way the notification path does.
      //
      // The two intents are what make this backend trustworthy. Stop records
      // that the alarm is spent — without it the reconciler re-projects a
      // one-time alarm to tomorrow, which is the daily-alarm bug reborn. Snooze
      // records the deferral — without it the spent-alarm sweep cancels the
      // alarm mid-snooze.
      return AlarmManager.AlarmConfiguration(
        countdownDuration: Alarm.CountdownDuration(
          preAlert: nil,
          postAlert: TimeInterval(max(1, request.snoozeMinutes) * 60)),
        schedule: .fixed(request.fireAt),
        attributes: attributes,
        stopIntent: RostrikStopAlarmIntent(
          alarmId: alarmUUID(for: request.id),
          appAlarmId: request.appAlarmId),
        secondaryIntent: RostrikSnoozeAlarmIntent(
          appAlarmId: request.appAlarmId,
          shiftId: request.shiftId,
          snoozeMinutes: request.snoozeMinutes),
        sound: sound)
    }

    func schedule(_ request: AlarmRequest, completion: @escaping (Error?) -> Void) {
      let uuid = Self.alarmUUID(for: request.id)
      let configuration = Self.configuration(for: request)
      Task {
        var failure: Error?
        do {
          // ⚠️ AlarmKit does NOT replace by id. `UNUserNotificationCenter.add`
          // does, and `AlarmScheduler.scheduleAt` is specified in those terms
          // ("if id already exists, implementations must replace it") — but
          // scheduling over a UUID that AlarmKit still holds throws
          // `com.apple.AlarmKit.Alarm error 0`. Observed on device 2026-08-27:
          // arming a test alarm, then arming it again before it fired, failed
          // twice and only succeeded once the first had fired and been
          // dismissed.
          //
          // That is not an edge case here. Ids are derived deterministically
          // from the Dart alarm id, so every re-arm of an existing alarm — which
          // is what the reconciler does whenever a shift moves — targets a UUID
          // already in use. Without this cancel, the alarm nearest to firing is
          // exactly the one most likely to fail to update.
          //
          // Cancelling an id AlarmKit does not hold throws, hence `try?`.
          try? AlarmManager.shared.cancel(id: uuid)
          _ = try await AlarmManager.shared.schedule(id: uuid, configuration: configuration)
          NSLog(
            "[Rostrik] AlarmKit scheduled id=\(request.id) at \(request.fireAt) "
              + "sound=\(request.iosSound ?? "default")")
        } catch AlarmManager.AlarmError.maximumLimitReached {
          // The cap is real but its value is not published. Surfacing it as an
          // error keeps the id out of the Dart ledger, so the reconciler will
          // retry rather than believe in an alarm that was never armed.
          NSLog("[Rostrik] AlarmKit REFUSED id=\(request.id): alarm limit reached")
          failure = AlarmManager.AlarmError.maximumLimitReached
        } catch {
          NSLog("[Rostrik] AlarmKit FAILED id=\(request.id): \(error.localizedDescription)")
          failure = error
        }
        DispatchQueue.main.async { completion(failure) }
      }
    }

    func cancel(id: Int) {
      do {
        try AlarmManager.shared.cancel(id: Self.alarmUUID(for: id))
      } catch {
        // Cancelling an alarm AlarmKit no longer holds throws, and that is the
        // normal case after one fires. Never propagate it — the reconciler's
        // whole job is to converge, and a throw here would abort the sweep.
        NSLog("[Rostrik] AlarmKit cancel id=\(id): \(error.localizedDescription)")
      }
    }

    func aliveIds(among ids: [Int], completion: @escaping ([Int]) -> Void) {
      // Same contract as the notification probe: trust the OS, never the local
      // ledger. The id↔UUID mapping is deterministic, so membership is decided
      // by hashing each candidate forward rather than keeping a reverse map.
      let live = Set(((try? AlarmManager.shared.alarms) ?? []).map(\.id))
      let alive = ids.filter { live.contains(Self.alarmUUID(for: $0)) }
      DispatchQueue.main.async { completion(alive) }
    }

    /// Requests AlarmKit authorisation, once, before the first schedule.
    ///
    /// Nothing rings without it, and `schedule` does not prompt on our behalf —
    /// it simply fails. Mirrors the notification permission request in
    /// `main.dart`, and for the same reason must not run before the UI is up.
    static func requestAuthorization(completion: @escaping (Bool) -> Void) {
      Task {
        if AlarmManager.shared.authorizationState == .authorized {
          DispatchQueue.main.async { completion(true) }
          return
        }
        let granted = (try? await AlarmManager.shared.requestAuthorization()) == .authorized
        NSLog("[Rostrik] AlarmKit authorisation granted=\(granted)")
        DispatchQueue.main.async { completion(granted) }
      }
    }

    /// Finds AlarmKit's undocumented alarm ceiling by arming far-future alarms
    /// until it refuses, then removing every one it created.
    ///
    /// This exists because the number decides the architecture. Rostrik arms a
    /// 14-day horizon of individually-scheduled alarms; if AlarmKit's cap is far
    /// below that, it cannot carry the horizon alone and the imminent alarms
    /// need AlarmKit while the rest stay on notifications. Better to learn the
    /// number before building a widget extension around the answer.
    ///
    /// Debug-only, and self-cleaning: the alarms are dated a decade out so a
    /// crash mid-probe cannot ring anything.
    /// A throwaway alarm dated far enough out that nothing it creates can ring,
    /// shared by the probes below so they differ only in what they measure.
    private static func probeConfiguration(at date: Date)
      -> AlarmManager.AlarmConfiguration<RostrikAlarmMetadata>
    {
      let alert = AlarmPresentation.Alert(
        title: "Rostrik probe",
        stopButton: AlarmButton(
          text: "Stop", textColor: .white, systemImageName: "stop.circle.fill"))
      return AlarmManager.AlarmConfiguration(
        countdownDuration: nil,
        schedule: .fixed(date),
        attributes: AlarmAttributes<RostrikAlarmMetadata>(
          presentation: AlarmPresentation(alert: alert),
          metadata: RostrikAlarmMetadata(shiftId: "probe", appAlarmId: "probe"),
          tintColor: .orange),
        sound: .default)
    }

    /// Settles whether AlarmKit replaces an alarm scheduled over an id it
    /// already holds, or refuses it.
    ///
    /// This is not academic. `AlarmScheduler.scheduleAt` is *specified* as
    /// replace-by-id, because `UNUserNotificationCenter.add` behaves that way,
    /// and our AlarmKit ids are derived deterministically from the Dart alarm
    /// id — so every re-arm of an existing alarm lands on a UUID already in use.
    /// Device logs on 2026-08-27 showed two such schedules failing with
    /// `com.apple.AlarmKit.Alarm error 0`, which is the evidence behind the
    /// pre-emptive cancel in `schedule`. This confirms the reading directly
    /// rather than inferring it from a coincidence.
    static func probeReplaceSemantics(completion: @escaping (String) -> Void) {
      Task {
        let uuid = alarmUUID(for: -200_001)
        let base = Date(timeIntervalSinceNow: 10 * 365 * 24 * 60 * 60)
        var verdict: String

        do {
          _ = try await AlarmManager.shared.schedule(
            id: uuid, configuration: probeConfiguration(at: base))
          // Also the check that `aliveIds` can believe what AlarmKit reports.
          let visible = Set(((try? AlarmManager.shared.alarms) ?? []).map(\.id))
            .contains(uuid)

          do {
            _ = try await AlarmManager.shared.schedule(
              id: uuid, configuration: probeConfiguration(at: base.addingTimeInterval(3600)))
            verdict = "REPLACES in place (visible in alarms=\(visible))"
          } catch {
            try? AlarmManager.shared.cancel(id: uuid)
            do {
              _ = try await AlarmManager.shared.schedule(
                id: uuid, configuration: probeConfiguration(at: base.addingTimeInterval(3600)))
              verdict =
                "REFUSES over a live id; cancel-then-schedule works "
                + "(visible in alarms=\(visible))"
            } catch {
              verdict = "REFUSES, and cancel-then-schedule ALSO failed: \(error)"
            }
          }
        } catch {
          verdict = "initial schedule failed: \(error)"
        }

        try? AlarmManager.shared.cancel(id: uuid)
        NSLog("[Rostrik] AlarmKit replace semantics: \(verdict)")
        DispatchQueue.main.async { completion(verdict) }
      }
    }

    static func probeAlarmLimit(upTo bound: Int, completion: @escaping (Int) -> Void) {
      Task {
        let base = Date(timeIntervalSinceNow: 10 * 365 * 24 * 60 * 60)
        var created: [UUID] = []
        var limit = bound
        for index in 0..<bound {
          let uuid = alarmUUID(for: -100_000 - index)
          do {
            _ = try await AlarmManager.shared.schedule(
              id: uuid,
              configuration: probeConfiguration(
                at: base.addingTimeInterval(Double(index) * 60)))
            created.append(uuid)
          } catch {
            limit = index
            NSLog("[Rostrik] AlarmKit limit probe stopped at \(index): \(error)")
            break
          }
        }
        // Count BEFORE cancelling. Measuring only afterwards cannot tell
        // "cancelled cleanly" from "never persisted" — both read as zero — and
        // the difference matters beyond this probe: `aliveIds` trusts
        // `AlarmManager.shared.alarms` to report what is really armed, so this
        // doubles as the check that it does.
        let liveBefore = Set(((try? AlarmManager.shared.alarms) ?? []).map(\.id))
          .intersection(created)

        for uuid in created { try? AlarmManager.shared.cancel(id: uuid) }

        // Verify the cleanup rather than assume it. A probe alarm that survives
        // is not merely litter: it occupies a slot against the very cap being
        // measured, so a failed sweep would quietly shrink the budget for the
        // user's real alarms and make every later measurement wrong.
        let leaked = Set(((try? AlarmManager.shared.alarms) ?? []).map(\.id))
          .intersection(created)
        NSLog(
          "[Rostrik] AlarmKit limit probe: armed \(created.count), refused at \(limit), "
            + "live before cleanup \(liveBefore.count), leaked \(leaked.count)")
        DispatchQueue.main.async { completion(limit) }
      }
    }
  }

#endif
