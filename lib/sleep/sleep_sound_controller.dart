import 'dart:async';

import 'package:flutter/widgets.dart';

import '../util/clock.dart';
import 'sleep_sound_channel.dart';
import 'sleep_sounds_catalog.dart';

/// Drives the Sleep tab's sound player and exposes its state to the UI.
///
/// A [ChangeNotifier] over the native [SleepSoundChannel]: it tracks which sound
/// is playing and the wind-down countdown, so a tile can highlight and show
/// "stops in 12m". The NATIVE [SleepSoundService] is the real authority for
/// audio + the auto-stop (it keeps playing with the app backgrounded); this
/// controller mirrors that for display and re-syncs on resume + on the native
/// `onSleepStopped` signal, so the UI never lies about what's playing.
class SleepSoundController extends ChangeNotifier with WidgetsBindingObserver {
  SleepSoundController({SleepSoundChannel? channel, Clock clock = const SystemClock()})
      : _channel = channel ?? SleepSoundChannel(),
        _clock = clock {
    WidgetsBinding.instance.addObserver(this);
    // Native → Dart: playback ended (timer elapsed / focus loss / stopped).
    _channel.setStoppedHandler(_handleStopped);
  }

  final SleepSoundChannel _channel;
  final Clock _clock;

  String? _playingResource;
  DateTime? _endsAt;
  Timer? _tick;

  /// The `res/raw` name of the sound currently playing, or null.
  String? get playingResource => _playingResource;

  bool get isPlaying => _playingResource != null;

  bool isPlayingResource(String resource) => _playingResource == resource;

  /// Time left on the wind-down auto-stop, or null when there's no timer (plays
  /// until stopped) or nothing is playing.
  Duration? get remaining {
    final end = _endsAt;
    if (end == null) return null;
    final left = end.difference(_clock.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Play [sound] if it isn't the current one; stop if it is (tap-to-toggle).
  Future<void> toggle(SleepSound sound, {required int timerMinutes}) {
    if (isPlayingResource(sound.resource)) return stop();
    return play(sound, timerMinutes: timerMinutes);
  }

  /// Starts (or swaps to) [sound], auto-stopping after [timerMinutes] (0 = until
  /// stopped).
  Future<void> play(SleepSound sound, {required int timerMinutes}) async {
    _tick?.cancel();
    _playingResource = sound.resource;
    _endsAt = timerMinutes > 0
        ? _clock.now().add(Duration(minutes: timerMinutes))
        : null;
    notifyListeners();

    await _channel.play(
      resource: sound.resource,
      label: sound.label,
      timerMinutes: timerMinutes,
    );

    // Drive the UI countdown + clear state when the timer elapses. The native
    // service enforces the actual stop; this keeps the display honest while the
    // app is foreground.
    if (_endsAt != null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        final end = _endsAt;
        if (end == null) return;
        if (!_clock.now().isBefore(end)) {
          _handleStopped();
        } else {
          notifyListeners();
        }
      });
    }
  }

  /// Stops playback now.
  Future<void> stop() async {
    await _channel.stop();
    _handleStopped();
  }

  /// Re-syncs against the native service — used on resume, since a background
  /// auto-stop won't have been reflected while the Dart timer was paused.
  Future<void> _syncFromNative() async {
    final playing = await _channel.isPlaying();
    if (!playing && isPlaying) _handleStopped();
  }

  void _handleStopped() {
    _tick?.cancel();
    _tick = null;
    final was = _playingResource != null;
    _playingResource = null;
    _endsAt = null;
    if (was) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncFromNative();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _channel.setStoppedHandler(null);
    _tick?.cancel();
    super.dispose();
  }
}
