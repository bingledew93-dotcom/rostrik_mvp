import AVFoundation
import Flutter
import Foundation

/// iOS side of the `rostrik/sleep_sounds` MethodChannel — the counterpart of
/// Android's `SleepSoundService` foreground media player.
///
/// The Sleep tab's player was Android-only: `SleepSoundChannel` gated every
/// method on `Platform.isAndroid`, so on iOS the tab rendered but nothing ever
/// played. This restores it with `AVAudioPlayer`.
///
/// **Where the audio comes from.** The six loops live in
/// `android/app/src/main/res/raw/`, which iOS cannot read, and they are NOT
/// Flutter assets — deliberately. Flutter assets are not per-platform, so
/// copying ~9.5 MB of WAVs into `assets/` would duplicate them inside the
/// ANDROID bundle too (Android plays its own `res/raw` copies and would never
/// touch the assets ones). They are instead added to the Runner target as iOS
/// bundle resources referencing those same files, so only iOS pays the cost and
/// nothing is duplicated in the repo. That is why lookup here is
/// `Bundle.main`, not the Flutter asset bundle.
///
/// **Background playback** relies on the `audio` entry in `UIBackgroundModes`;
/// without it iOS silences the player the moment the screen locks, which is
/// precisely when a sleep sound needs to keep going.
public final class SleepSoundPlugin: NSObject {

  private static let channelName = "rostrik/sleep_sounds"

  private var player: AVAudioPlayer?
  /// Auto-stop timer for a non-zero `timerMinutes`. Android's service owns the
  /// equivalent countdown; here it is a plain `Timer`.
  private var stopTimer: Timer?
  /// Retained so playback end can be reported back to Dart (`onSleepStopped`),
  /// which is how the Sleep tab re-syncs its play/stop button.
  private var channel: FlutterMethodChannel?

  /// See `NativeAlarmPlugin.register` — the strong capture is load-bearing.
  /// Doubly so here: `AVAudioPlayer` stops the instant its owner is freed, so a
  /// weakly-held plugin would cut every sleep sound off immediately.
  @discardableResult
  public static func register(with messenger: FlutterBinaryMessenger) -> SleepSoundPlugin {
    let plugin = SleepSoundPlugin()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    plugin.channel = channel
    channel.setMethodCallHandler { call, result in
      plugin.handle(call, result: result)
    }
    return plugin
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "playSleepSound":
      guard let args = call.arguments as? [String: Any],
        let resource = args["resource"] as? String
      else {
        result(FlutterError(code: "BAD_ARGS", message: "playSleepSound requires resource", details: nil))
        return
      }
      play(resource: resource, timerMinutes: args["timerMinutes"] as? Int ?? 0)
      result(nil)

    case "stopSleepSound":
      stop(notifyDart: false)
      result(nil)

    case "isSleepPlaying":
      result(player?.isPlaying ?? false)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func play(resource: String, timerMinutes: Int) {
    stop(notifyDart: false)  // swapping sounds replaces, matching the Android service

    // `resource` is the bare Android res/raw name ("sleep_rain"); the bundled
    // iOS resource keeps that filename with its extension.
    guard let url = Bundle.main.url(forResource: resource, withExtension: "wav") else {
      NSLog("[Rostrik] sleep sound '\(resource).wav' not found in bundle")
      return
    }
    do {
      // `.playback` keeps audio alive when the screen locks and when the ring
      // switch is silent — both essential for a sleep sound.
      try AVAudioSession.sharedInstance().setCategory(.playback)
      try AVAudioSession.sharedInstance().setActive(true)
      let newPlayer = try AVAudioPlayer(contentsOf: url)
      newPlayer.numberOfLoops = -1  // loop until stopped or the timer elapses
      newPlayer.prepareToPlay()
      newPlayer.play()
      player = newPlayer
      NSLog("[Rostrik] sleep sound playing: \(resource) timer=\(timerMinutes)m")
    } catch {
      NSLog("[Rostrik] sleep sound failed: \(error.localizedDescription)")
      player = nil
      return
    }

    guard timerMinutes > 0 else { return }
    let timer = Timer(
      timeInterval: TimeInterval(timerMinutes * 60), repeats: false
    ) { [weak self] _ in
      // Tell Dart, so the Sleep tab's button returns to "play" on its own
      // rather than claiming to still be playing.
      self?.stop(notifyDart: true)
    }
    // Common mode so an open scroll view can't defer the auto-stop.
    RunLoop.main.add(timer, forMode: .common)
    stopTimer = timer
  }

  private func stop(notifyDart: Bool) {
    stopTimer?.invalidate()
    stopTimer = nil
    player?.stop()
    player = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    if notifyDart {
      channel?.invokeMethod("onSleepStopped", arguments: nil)
    }
  }
}
