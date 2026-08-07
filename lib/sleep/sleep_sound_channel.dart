import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart side of the `rostrik/sleep_sounds` platform channel — the bridge to the
/// native (Android-only) [SleepSoundService] foreground media player.
///
/// **Deliberately tolerant** (mirrors `RingtoneChannel`): every method
/// short-circuits off Android and swallows `MissingPluginException` /
/// `PlatformException`, so iOS / desktop builds and widget tests that never
/// register the channel stay green (calls become no-ops).
///
/// The matching native handler lives in `MainActivity.kt`.
class SleepSoundChannel {
  SleepSoundChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  /// Wire name — must match `MainActivity.SLEEP_CHANNEL`.
  static const String channelName = 'rostrik/sleep_sounds';

  final MethodChannel _channel;

  /// Starts (or swaps to) the looping [resource] (a `res/raw` name) in the
  /// foreground service, auto-stopping after [timerMinutes] (0 = until stopped).
  Future<void> play({
    required String resource,
    required String label,
    required int timerMinutes,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('playSleepSound', <String, dynamic>{
        'resource': resource,
        'label': label,
        'timerMinutes': timerMinutes,
      });
    } on PlatformException catch (e) {
      debugPrint('[sleep] play failed: $e');
    } on MissingPluginException {
      // off-Android / no native handler (tests) — silent no-op.
    }
  }

  /// Stops playback (and clears the foreground notification). Safe when nothing
  /// is playing.
  Future<void> stop() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('stopSleepSound');
    } on PlatformException catch (e) {
      debugPrint('[sleep] stop failed: $e');
    } on MissingPluginException {
      // no-op.
    }
  }

  /// Whether the native service is currently playing — used to re-sync the UI
  /// after a background auto-stop. False off Android / in tests.
  Future<bool> isPlaying() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('isSleepPlaying') ?? false;
    } on PlatformException catch (e) {
      debugPrint('[sleep] isPlaying failed: $e');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Registers [onStopped], invoked when the native side reports playback ended
  /// (timer elapsed / focus loss / stop) via `onSleepStopped`. Pass null to
  /// clear. No-op off Android.
  void setStoppedHandler(void Function()? onStopped) {
    if (!_supported) return;
    if (onStopped == null) {
      _channel.setMethodCallHandler(null);
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSleepStopped') onStopped();
      return null;
    });
  }

  bool get _supported {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }
}
