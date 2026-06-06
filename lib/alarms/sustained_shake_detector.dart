/// Pure, device-free detector for a **sustained** shake gesture, used by the
/// wake-up screen's Critical-Shift dismiss path.
///
/// Fed the magnitude of gravity-removed accelerometer samples (m/s², i.e.
/// `userAccelerometer`, which reads ~0 at rest and spikes on motion) together
/// with their timestamps, it tracks how long the user has been shaking
/// *continuously* and reports [progressAt] (0..1) toward [requiredDuration].
/// The natural troughs of a shake oscillation (brief dips below the threshold)
/// are tolerated up to [graceWindow]; a longer quiet gap resets the run, so a
/// single jolt or intermittent bumps can't dismiss a critical alarm.
///
/// **Pure Dart + injected timestamps** — no sensor, no `Timer`, no Flutter — so
/// it unit-tests with synthetic samples and explicit times, mirroring how
/// `OcrTimeParser` and the injected-clock in `AlarmSyncService` keep their logic
/// device-free. The widget layer owns the (battery-bounded) sensor subscription
/// and feeds this detector.
class SustainedShakeDetector {
  SustainedShakeDetector({
    this.requiredDuration = const Duration(seconds: 3),
    this.magnitudeThreshold = 12.0,
    this.graceWindow = const Duration(milliseconds: 350),
  });

  /// How long continuous shaking must persist to reach completion.
  final Duration requiredDuration;

  /// Per-sample magnitude (m/s², gravity removed) at/above which a sample
  /// counts as "shaking". A vigorous shake produces ~15–30 m/s².
  final double magnitudeThreshold;

  /// Maximum gap between above-threshold samples before the run is considered
  /// broken and restarts. Absorbs the sub-threshold troughs of the waveform.
  final Duration graceWindow;

  DateTime? _runStart; // when the current continuous run began
  DateTime? _lastShake; // last above-threshold sample seen

  /// Feeds one sample and returns the current [progressAt] (0..1).
  double addSample(double magnitude, DateTime at) {
    if (magnitude >= magnitudeThreshold) {
      // A gap longer than the grace window means the previous run lapsed —
      // begin a fresh run from this sample.
      if (_lastShake == null || at.difference(_lastShake!) > graceWindow) {
        _runStart = at;
      }
      _lastShake = at;
    } else if (_lastShake != null && at.difference(_lastShake!) > graceWindow) {
      // Quiet for longer than the grace window → the run is broken.
      _runStart = null;
      _lastShake = null;
    }
    return progressAt(at);
  }

  /// Progress (0..1) toward [requiredDuration] as of [at].
  double progressAt(DateTime at) {
    final start = _runStart;
    if (start == null) return 0;
    final total = requiredDuration.inMilliseconds;
    if (total <= 0) return 1;
    final p = at.difference(start).inMilliseconds / total;
    if (p <= 0) return 0;
    if (p >= 1) return 1;
    return p;
  }

  /// True once a continuous run has lasted [requiredDuration].
  bool isComplete(DateTime at) => progressAt(at) >= 1.0;

  /// Forget any in-progress run.
  void reset() {
    _runStart = null;
    _lastShake = null;
  }
}
