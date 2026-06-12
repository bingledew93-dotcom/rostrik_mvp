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
/// the native (Android-only) `RingtoneManager` picker and the Kotlin
/// `MediaPlayer` preview harness that exercises the Phase-2b playback engine
/// (synchronous `prepare()` + try/catch fallback to the bundled classic tone)
/// on demand.
///
/// **Deliberately tolerant.** Every method short-circuits off Android and
/// swallows `MissingPluginException` / `PlatformException`, so:
///   * iOS / desktop builds compile and run (the picker simply returns null and
///     preview is a no-op — bundled-tone selection still works), and
///   * widget tests that never register this channel stay green even if a tap
///     reaches a preview/pick call (it no-ops rather than throwing).
///
/// The matching native handler lives in `MainActivity.kt`.
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

  /// Plays [source]'s audio through the native preview `MediaPlayer`, looping,
  /// using the SAME resolve-and-fallback logic the fire-time engine will use —
  /// so a corrupt path/URI audibly falls back to the bundled classic tone
  /// instead of going silent. No-op off Android / in tests.
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
    if (!Platform.isAndroid) return;
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

  /// Plays [uri] as the FIRING alarm tone (single-notification architecture):
  /// `WakeUpScreen` calls this when the FSI launches it and the alarm's payload
  /// carried a custom ringtone. Same native engine + classic-fallback ladder as
  /// [previewRingtone] — only the entry point differs. The [RingtoneSource] is
  /// inferred from the URI scheme: a `content://` URI is a system tone (read via
  /// ContentResolver), anything else is a durable vault file path. When
  /// [vibrate] is true the native engine also runs a continuous looping
  /// vibration until stopped. Stop it with [stopPreview]. No-op off Android / in
  /// tests.
  Future<void> playAlarmUri(String uri, {bool vibrate = false}) {
    final source = uri.startsWith('content://')
        ? RingtoneSource.system
        : RingtoneSource.vault;
    // asAlarm: this IS the firing alarm — the native player must survive
    // every activity lifecycle event until an explicit Dismiss/Snooze.
    return previewRingtone(
      source: source,
      uri: uri,
      vibrate: vibrate,
      asAlarm: true,
    );
  }

  /// Plays a PRESET internal tone as the FIRING alarm through the SAME
  /// foreground service as custom tones — closing the regression where presets
  /// rode FLAG_INSISTENT and were silenced when the lock-screen shade was
  /// pulled. [androidResource] is the tone's `res/raw` name
  /// (`AlarmSound.androidResource`). No-op off Android / in tests.
  Future<void> playAlarmBundled(String androidResource, {bool vibrate = false}) {
    return previewRingtone(
      // source is ignored when bundledResource is set, but classic is the
      // honest default.
      source: RingtoneSource.classic,
      vibrate: vibrate,
      asAlarm: true,
      bundledResource: androidResource,
    );
  }

  /// Stops and releases the native player (preview OR a firing alarm tone — same
  /// engine). Safe to call when nothing is playing. No-op off Android / in
  /// tests.
  Future<void> stopPreview() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stopPreview');
    } on PlatformException catch (e) {
      debugPrint('[ringtone] stopPreview failed: $e');
    } on MissingPluginException {
      // no-op.
    }
  }

  /// Regression 2 — asks MainActivity to natively finish a WakeUpScreen left
  /// stranded over the lock screen after an EXTERNAL (notification-shade)
  /// dismiss. Called by the foreground dispatcher's dismiss path; a no-op
  /// natively unless an alarm wake screen is actually showing. Off Android / in
  /// tests this is a silent no-op (the platform channel isn't registered).
  Future<void> finishWakeActivity() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('finishWakeActivity');
    } on PlatformException catch (e) {
      debugPrint('[ringtone] finishWakeActivity failed: $e');
    } on MissingPluginException {
      // no-op.
    }
  }
}
