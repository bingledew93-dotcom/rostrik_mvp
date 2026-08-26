import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/models/ringtone_source.dart';

/// Result of [RingtoneChannel.pickSystemRingtone] — the `content://` URI of the
/// chosen system tone plus its human-readable title (for the editor row).
class SystemRingtonePick {
  const SystemRingtonePick({required this.uri, required this.title});

  /// `content://media/...` or `content://settings/system/...` — system-owned
  /// audio, readable at fire time via the declared `READ_MEDIA_AUDIO`.
  final String uri;

  /// `RingtoneManager`-resolved display name shown in the editor.
  final String title;
}

/// Dart side of the `rostrik/ringtone_picker` platform channel — the bridge to
/// the native `RingtoneManager` picker + Kotlin `MediaPlayer` preview harness
/// on Android (`MainActivity.kt`), and to the `AVAudioPlayer` preview-only
/// handler on iOS (`RingtonePreviewPlugin.swift`).
///
/// **Deliberately tolerant.** Every method swallows `MissingPluginException` /
/// `PlatformException`, so:
///   * [pickSystemRingtone] still short-circuits off Android — there is no iOS
///     system-tone picker (see `RingtonePreviewPlugin.swift`'s header), and
///     bundled-tone selection works regardless;
///   * widget tests that never register this channel stay green even if a tap
///     reaches a preview/pick call (it no-ops rather than throwing).
class RingtoneChannel {
  RingtoneChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  /// Wire name — must match `MainActivity.RINGTONE_CHANNEL`.
  static const String channelName = 'rostrik/ringtone_picker';

  final MethodChannel _channel;

  /// Opens the native `RingtoneManager` alarm-tone picker. Returns the picked
  /// tone, or null if the user cancelled, the platform isn't Android, or the
  /// channel isn't available (tests/desktop). [currentUri] pre-selects the row
  /// matching the user's existing choice.
  Future<SystemRingtonePick?> pickSystemRingtone({String? currentUri}) async {
    if (!Platform.isAndroid) return null;
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'pickSystemRingtone',
        <String, dynamic>{'currentUri': currentUri},
      );
      final uri = res?['uri'] as String?;
      if (uri == null || uri.isEmpty) return null; // cancelled
      final title = (res?['title'] as String?)?.trim();
      return SystemRingtonePick(
        uri: uri,
        title: (title == null || title.isEmpty) ? 'System tone' : title,
      );
    } on PlatformException catch (e) {
      debugPrint('[ringtone] pickSystemRingtone failed: $e');
      return null;
    } on MissingPluginException {
      return null; // off-Android / no native handler (tests)
    }
  }

  /// Plays [source]'s audio, looping, through the native preview engine — the
  /// Kotlin `MediaPlayer` on Android (resolve-and-fallback logic matching the
  /// fire-time engine, so a corrupt path/URI audibly falls back to the bundled
  /// classic tone instead of going silent) or the `AVAudioPlayer` in
  /// `RingtonePreviewPlugin.swift` on iOS. No-op on other platforms / in tests.
  ///
  /// iOS only ever plays [RingtoneSource.vault] — see that file's header for
  /// why `.system` and `.classic` never reach it in practice; [vibrate],
  /// [asAlarm], and [bundledResource] are Android-only and ignored there.
  ///
  /// [uri] is the durable vault path ([RingtoneSource.vault]) or the
  /// `content://` system URI ([RingtoneSource.system]); ignored for
  /// [RingtoneSource.classic].
  Future<void> previewRingtone({
    required RingtoneSource source,
    String? uri,
    bool vibrate = false,
    bool asAlarm = false,
    String? bundledResource,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('previewRingtone', <String, dynamic>{
        'source': source.index,
        'uri': uri,
        // When true, the native engine starts a continuous looping vibration
        // alongside the audio (and cancels it on stop). The editor preview
        // passes false; a firing alarm passes the user's vibration setting.
        'vibrate': vibrate,
        // FIRING-ALARM playback is lifecycle-immune on the native side: it runs
        // in the foreground AlarmAudioService, which survives activity
        // pause/stop/destroy (Android 14 finishes the occluded FSI activity
        // when the shade covers the keyguard) and only an explicit
        // [stopPreview] — Dismiss/Snooze — ends it. Editor previews stay false
        // so they still die with the activity.
        'asAlarm': asAlarm,
        // PRESET internal tone: a `res/raw` name (from
        // `AlarmSound.androidResource`). Non-null makes the native engine play
        // the bundled tone — the route that puts EVERY fire-time alarm, preset
        // or custom, on the protected foreground service. Null for a custom
        // vault/system URI.
        'bundledResource': bundledResource,
      });
    } on PlatformException catch (e) {
      debugPrint('[ringtone] previewRingtone failed: $e');
    } on MissingPluginException {
      // off-Android / no native handler (tests) — silent no-op.
    }
  }

  /// Stops and releases the native player. On Android that's the same engine a
  /// firing alarm's tone plays through; on iOS it's the preview-only
  /// `AVAudioPlayer`. Safe to call when nothing is playing. No-op on other
  /// platforms / in tests.
  Future<void> stopPreview() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('stopPreview');
    } on PlatformException catch (e) {
      debugPrint('[ringtone] stopPreview failed: $e');
    } on MissingPluginException {
      // no-op.
    }
  }
}
