import Foundation

#if canImport(AlarmKit)
  import AlarmKit

  /// Rostrik's payload on an AlarmKit alarm.
  ///
  /// ## Why it lives in its own file
  ///
  /// `AlarmAttributes` is an `ActivityKit.ActivityAttributes`, so an AlarmKit
  /// alarm's UI is a Live Activity rendered by a **widget extension** — a second
  /// target. Both targets must agree on this type exactly: ActivityKit encodes it
  /// in the app and decodes it in the extension, so a field added on one side
  /// only is a decode failure at alert time, i.e. an alarm that fires with no UI.
  /// Keeping it in a standalone file means the widget target can compile the same
  /// source rather than a copy that drifts.
  ///
  /// ## Why these two fields
  ///
  /// They are the same pair the notification path stuffs into `userInfo`, and for
  /// the same reason: when the user presses Stop, the App Intent has to know
  /// which Rostrik rule just went off so it can write the deletes ledger. Under
  /// notifications that identity round-tripped through `userInfo`; here it
  /// round-trips through metadata.
  ///
  /// `Codable`, `Hashable` and `Sendable` are all synthesised — `AlarmMetadata`
  /// requires them and adds nothing of its own.
  @available(iOS 26.0, *)
  struct RostrikAlarmMetadata: AlarmMetadata {
    /// Owning shift UUID, or the "NONE" sentinel for a shift-less one-off.
    let shiftId: String
    /// Owning `AppAlarm` UUID — the id the deletes ledger is keyed by.
    let appAlarmId: String
  }
#endif
