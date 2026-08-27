import AppIntents
import Foundation

#if canImport(AlarmKit)
  import AlarmKit

  /// What runs when the user stops a Rostrik alarm under AlarmKit.
  ///
  /// ## Why this is the piece that unblocks everything
  ///
  /// On the notification path **no app code runs when an alarm fires or is
  /// dismissed**. That single fact is behind the ugliest machinery in this
  /// project: `NotificationBackend.recordSpentAlarms` has to work out after the
  /// fact which alarms went off by inspecting what iOS still holds in
  /// Notification Centre, and an earlier attempt at that missed dismissals
  /// entirely — which silently turned one-time alarms into daily ones, waking
  /// people every morning for a shift they had already worked.
  ///
  /// AlarmKit's stop button is an App Intent, so this runs in our process the
  /// moment the user stops the alarm. There is nothing to reconstruct: the alarm
  /// that fired says so itself.
  ///
  /// ## Why it needs no Flutter engine
  ///
  /// `perform()` may run with the app suspended or not running at all, so it
  /// cannot assume Dart is alive. It does not need to: the ledger is an
  /// append-only file in Application Support, the same handoff the Android side
  /// uses, drained by Dart whenever it next runs. The nudge to Dart afterwards
  /// is an optimisation for the case where the app *is* up — without it the
  /// ledger still drains on the next launch or background refresh.
  ///
  /// ## Ordering
  ///
  /// The ledger is written BEFORE stopping the alarm. If the process is killed
  /// between the two, the cost is an alarm the user has to stop again; the other
  /// order risks a stopped alarm whose rule is never retired, which is the
  /// failure that actually hurts.
  @available(iOS 26.0, *)
  struct RostrikStopAlarmIntent: LiveActivityIntent {

    static var title: LocalizedStringResource { "Stop alarm" }

    /// Keeps it out of the Shortcuts app. This is plumbing behind AlarmKit's
    /// own stop button, not an action anyone should be able to invoke on its
    /// own — running it out of context would append a spurious deletes-ledger
    /// entry for an alarm that never fired.
    static var isDiscoverable: Bool { false }

    /// The AlarmKit alarm to stop, as a UUID string. Carried as a parameter
    /// rather than recomputed, so the intent stays correct even if the id
    /// derivation in `AlarmKitBackend.alarmUUID(for:)` ever changes.
    @Parameter(title: "Alarm")
    var alarmId: String

    /// The owning `AppAlarm` UUID — the key `pending_alarm_deletes` is read by,
    /// and the reason this intent exists at all.
    @Parameter(title: "Rule")
    var appAlarmId: String

    init() {}

    init(alarmId: UUID, appAlarmId: String) {
      self.alarmId = alarmId.uuidString
      self.appAlarmId = appAlarmId
    }

    func perform() async throws -> some IntentResult {
      if !appAlarmId.isEmpty {
        RostrikLedger.append(appAlarmId, to: RostrikLedger.alarmDeletes)
        NSLog("[Rostrik] AlarmKit stop intent — queued \(appAlarmId) for cleanup")
      }
      if let uuid = UUID(uuidString: alarmId) {
        try? AlarmManager.shared.stop(id: uuid)
      }
      NativeAlarmPlugin.notifyDartSpentAlarmRecorded()
      return .result()
    }
  }
#endif
