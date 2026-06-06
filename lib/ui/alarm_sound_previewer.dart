import 'package:audioplayers/audioplayers.dart';

import '../alarms/alarm_sound.dart';

/// Converts an [AlarmSound.assetPath] (`assets/sounds/x.wav`) to the key
/// audioplayers' [AssetSource] expects — relative to the `assets/` root
/// (`sounds/x.wav`). Kept as a top-level pure function so the previewer test
/// can assert the exact key without a real player.
String previewAssetKey(String assetPath) =>
    assetPath.startsWith('assets/')
        ? assetPath.substring('assets/'.length)
        : assetPath;

/// The minimal audio surface [AlarmSoundPreviewer] drives. Abstracted behind an
/// interface so the stop-before-play lifecycle is unit-testable with a fake —
/// audioplayers' `AudioPlayer` is a concrete class that touches a platform
/// channel, so it can't run under the widget/unit test harness.
abstract class PreviewAudioPlayer {
  /// Plays the asset at [assetKey] once (no loop). Implementations stop any
  /// current playback first is NOT assumed here — the previewer enforces
  /// stop-before-play itself, so this is a plain "start playing".
  Future<void> play(String assetKey);

  /// Stops playback immediately. Idempotent (safe on an idle player).
  Future<void> stop();

  /// Releases native resources. After this the instance is unusable.
  Future<void> dispose();
}

/// Production [PreviewAudioPlayer] over audioplayers' [AudioPlayer].
///
/// The underlying player is created **lazily** on first [play] — so merely
/// constructing a previewer (e.g. when the create sheet mounts) touches no
/// platform channel. That keeps the many create-sheet widget tests that never
/// tap a tone free of audio-plugin `MissingPluginException`s without each
/// having to inject a fake.
///
/// On creation the player is configured for **alarm-usage audio with transient
/// (duck-others) focus** so the preview plays at alarm loudness — audible even
/// when media volume is down — while only briefly ducking any music rather than
/// permanently seizing audio focus. Plays once ([ReleaseMode.stop]); the
/// previewer never loops a preview.
class AudioPlayersPreviewPlayer implements PreviewAudioPlayer {
  AudioPlayer? _player;

  Future<AudioPlayer> _ensure() async {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setAudioContext(_alarmPreviewContext);
    _player = player;
    return player;
  }

  @override
  Future<void> play(String assetKey) async {
    final player = await _ensure();
    await player.play(AssetSource(assetKey), volume: 1.0);
  }

  @override
  Future<void> stop() => _player?.stop() ?? Future<void>.value();

  @override
  Future<void> dispose() async {
    final player = _player;
    if (player == null) return;
    _player = null;
    await player.stop();
    await player.dispose();
  }
}

/// Alarm-usage, duck-others audio context shared by every preview. Not `const`
/// — audioplayers' `AudioContext`/`AudioContextIOS` constructors are non-const
/// (the latter validates options against the category), so it's built once as a
/// top-level final.
final AudioContext _alarmPreviewContext = AudioContext(
  android: const AudioContextAndroid(
    // "what": a short attention sound. "why": alarm — routes to the alarm
    // volume so the preview reflects real alarm loudness.
    contentType: AndroidContentType.sonification,
    usageType: AndroidUsageType.alarm,
    // Transient focus that ducks (not silences) other audio, released as soon
    // as the short clip ends.
    audioFocus: AndroidAudioFocus.gainTransientMayDuck,
  ),
  iOS: AudioContextIOS(
    category: AVAudioSessionCategory.playback,
    options: const <AVAudioSessionOptions>{AVAudioSessionOptions.duckOthers},
  ),
);

/// Plays the in-app preview of a bundled alarm tone in the create/edit sheet.
///
/// **The overlap-bug guard:** a single underlying player, and every [preview]
/// issues a `stop()` *before* `play()`. Two rapid tone taps therefore can never
/// layer — the second stops the first. This is the deterministic fix; no
/// debounce timing to tune.
///
/// Not part of the alarm-firing path — the OS owns alarm audio. This is purely
/// the "what does this tone sound like" affordance, scoped to the sheet's
/// lifetime: construct in `initState`, [dispose] in `dispose`.
class AlarmSoundPreviewer {
  /// [player] is injectable for tests; production uses a real
  /// [AudioPlayersPreviewPlayer].
  AlarmSoundPreviewer({PreviewAudioPlayer? player})
      : _player = player ?? AudioPlayersPreviewPlayer();

  final PreviewAudioPlayer _player;
  bool _disposed = false;

  /// Stops any in-flight preview, then plays [sound] once. No-op once
  /// [dispose] has run (guards the awaited gap: a dispose racing the awaited
  /// `stop()` must not let a late `play()` resurrect audio after teardown).
  Future<void> preview(AlarmSound sound) async {
    if (_disposed) return;
    await _player.stop();
    if (_disposed) return;
    await _player.play(previewAssetKey(sound.assetPath));
  }

  /// Stops playback without tearing the player down (e.g. on sheet save).
  Future<void> stop() async {
    if (_disposed) return;
    await _player.stop();
  }

  /// Releases the player. Idempotent; subsequent [preview] calls are no-ops.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _player.dispose();
  }
}
