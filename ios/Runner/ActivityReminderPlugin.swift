import Flutter
import Foundation
import UserNotifications

/// iOS side of the `rostrik/activity_reminders` MethodChannel.
///
/// This channel had no iOS handler at all, so every `scheduleReminder` hit
/// `MissingPluginException` — which the Dart side swallows on purpose
/// ("reminders are Android-only") — and the whole reminder surface silently did
/// nothing: activity nudges, and the Sleep tab's wind-down and bedtime
/// reminders, which are scheduled through this same scheduler.
///
/// Deliberately kept apart from `NativeAlarmPlugin`, mirroring the Android
/// split (`ReminderReceiver` vs the alarm stack). A reminder is an ordinary,
/// interruptible notification: default sound, no time-sensitive level, its own
/// identifier namespace. Nothing here can affect alarm delivery, and a bug in
/// the alarm path cannot silence reminders.
public final class ActivityReminderPlugin: NSObject {

  private static let channelName = "rostrik/activity_reminders"

  /// Separate namespace from `NativeAlarmPlugin.identifierPrefix` so the alarm
  /// liveness probe (`getAliveAlarmIds`) can never mistake a reminder for an
  /// alarm, in either direction.
  static let identifierPrefix = "rostrik.reminder."

  private let center = UNUserNotificationCenter.current()

  /// See `NativeAlarmPlugin.register` — the handler closure holds the plugin
  /// strongly on purpose; nothing else owns it.
  @discardableResult
  public static func register(with messenger: FlutterBinaryMessenger) -> ActivityReminderPlugin {
    let plugin = ActivityReminderPlugin()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      plugin.handle(call, result: result)
    }
    return plugin
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "scheduleReminder":
      guard let args = call.arguments as? [String: Any],
        let id = args["id"] as? Int,
        let millis = args["triggerAtMillis"] as? Int
      else {
        result(
          FlutterError(
            code: "BAD_ARGS", message: "scheduleReminder requires id and triggerAtMillis",
            details: nil))
        return
      }
      schedule(
        id: id,
        at: Date(timeIntervalSince1970: TimeInterval(millis) / 1000.0),
        title: args["title"] as? String ?? "Rostrik",
        body: args["body"] as? String ?? "",
        result: result)

    case "cancelReminder":
      guard let id = (call.arguments as? [String: Any])?["id"] as? Int else {
        result(FlutterError(code: "BAD_ARGS", message: "cancelReminder requires id", details: nil))
        return
      }
      let identifier = "\(Self.identifierPrefix)\(id)"
      center.removePendingNotificationRequests(withIdentifiers: [identifier])
      center.removeDeliveredNotifications(withIdentifiers: [identifier])
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func schedule(
    id: Int, at fireAt: Date, title: String, body: String, result: @escaping FlutterResult
  ) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    // Default sound and default interruption level: a wind-down nudge should
    // respect Do Not Disturb, unlike a shift alarm. This is the same
    // distinction the Android side draws by not using the alarm channel.
    content.sound = .default

    // Calendar-anchored for the same reason as the alarm path: it survives the
    // device clock being changed between arming and firing.
    let components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute, .second], from: fireAt)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    // Same identifier ⇒ replace, which is the replace-by-id contract
    // `ActivityReminderScheduler.schedule` specifies.
    center.add(
      UNNotificationRequest(
        identifier: "\(Self.identifierPrefix)\(id)", content: content, trigger: trigger)
    ) { error in
      DispatchQueue.main.async {
        if let error {
          NSLog("[Rostrik] reminder schedule FAILED id=\(id): \(error.localizedDescription)")
          // Reported as a PlatformException, which the Dart side logs and
          // swallows — a refused reminder must never disrupt the app, and the
          // next reconcile re-arms it.
          result(
            FlutterError(
              code: "IOS_REMINDER_DENIED", message: error.localizedDescription, details: nil))
        } else {
          NSLog("[Rostrik] reminder scheduled id=\(id) at \(fireAt)")
          result(nil)
        }
      }
    }
  }
}
