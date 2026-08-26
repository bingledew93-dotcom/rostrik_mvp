import AVFoundation
import Flutter
import Foundation

/// iOS side of the `rostrik/ringtone_picker` MethodChannel — **preview only**.
///
/// Android's counterpart (`MainActivity.kt`) also handles `pickSystemRingtone`
/// and fire-time playback; neither applies here. `pickSystemRingtone` never
/// reaches this channel at all — `RingtoneChannel.pickSystemRingtone` in Dart
/// short-circuits on iOS before making the platform call. Fire-time alarm
/// audio is the OS notification sound (`NativeAlarmPlugin.swift`), not this
/// engine. This class exists solely so the create/edit sheet's "Play" button
/// on a custom tone plays something on iOS instead of silently no-op'ing.
///
/// Only `RingtoneSource.vault` (index 1 — a durable file path in app-private
/// storage) is ever reachable here: `.system` (index 2) never occurs on iOS
/// (the system-tone picker always returns nil before this channel is
/// touched), and `.classic` (index 0) bundled tones have no Play button in
/// the UI on any platform — see `create_alarm_sheet.dart`'s `hasCustomRingtone`
/// gate. `RingtoneSource` order is append-only (persisted as a bare int), so
/// index 1 is safe to hard-code rather than importing the Dart enum.
public final class RingtonePreviewPlugin: NSObject {

  private static let channelName = "rostrik/ringtone_picker"
  private static let vaultSourceIndex = 1

  private var player: AVAudioPlayer?

  /// The handler closure holds `plugin` **strongly** on purpose — see the same
  /// note on `NativeAlarmPlugin.register`. A weak capture leaves the instance
  /// unowned (callers discard the return value), so ARC frees it immediately
  /// and every preview call silently no-ops. It also has to outlive the call
  /// regardless: `AVAudioPlayer` stops the moment its owner is deallocated, so
  /// a short-lived plugin would cut playback off instantly.
  @discardableResult
  public static func register(with messenger: FlutterBinaryMessenger) -> RingtonePreviewPlugin {
    let plugin = RingtonePreviewPlugin()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      plugin.handle(call, result: result)
    }
    return plugin
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "previewRingtone":
      preview(call.arguments)
      result(nil)
    case "stopPreview":
      stop()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func preview(_ arguments: Any?) {
    guard let args = arguments as? [String: Any],
      let sourceIndex = args["source"] as? Int,
      sourceIndex == Self.vaultSourceIndex,
      let uri = args["uri"] as? String, !uri.isEmpty
    else {
      // classic / system / malformed args — nothing previewable on iOS.
      return
    }
    stop()  // replace whatever is already playing, mirrors the Android engine
    let url = URL(fileURLWithPath: uri)
    do {
      // `.playback` so the preview is audible even with the ring/silent
      // switch flipped — a deliberate "test this tone" tap should be heard,
      // the same reasoning the alarm's own notification uses time-sensitive
      // delivery for.
      try AVAudioSession.sharedInstance().setCategory(.playback)
      try AVAudioSession.sharedInstance().setActive(true)
      let newPlayer = try AVAudioPlayer(contentsOf: url)
      newPlayer.numberOfLoops = -1  // loops until Stop, matching the Kotlin preview
      newPlayer.prepareToPlay()
      newPlayer.play()
      player = newPlayer
    } catch {
      NSLog("[Rostrik] ringtone preview failed: \(error)")
      player = nil
    }
  }

  private func stop() {
    player?.stop()
    player = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}
