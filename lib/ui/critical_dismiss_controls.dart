import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../alarms/sustained_shake_detector.dart';

/// How long the user must sustain a shake to dismiss a Critical-Shift alarm.
const Duration kShakeDismissDuration = Duration(seconds: 3);

/// How long the user must hold an unbroken press for the fail-safe dismiss.
const Duration kHoldToDismissDuration = Duration(seconds: 3);

/// Critical-Shift PRIMARY dismiss: a sustained physical shake.
///
/// Owns the accelerometer subscription for exactly its lifetime — opened in
/// [initState], cancelled in [dispose]. Because the wake screen only mounts this
/// while the alarm is actually ringing, the sensor never runs in the background
/// or during normal app use; battery cost is bounded to the dismiss window.
/// Sampling at `SensorInterval.uiInterval` (~16 Hz) and the O(1) per-sample math
/// keep it off the jank path. The detection itself lives in the pure, tested
/// [SustainedShakeDetector]; this widget is just the sensor→detector→UI glue.
///
/// [magnitudeStream] and [clock] are injectable so widget tests can drive it
/// deterministically without a device.
class ShakeToDismiss extends StatefulWidget {
  const ShakeToDismiss({
    super.key,
    required this.onDismissed,
    this.magnitudeStream,
    this.clock,
  });

  final Future<void> Function() onDismissed;

  /// Gravity-removed accelerometer magnitudes. Defaults to the device
  /// `userAccelerometerEventStream`; injected in tests.
  final Stream<double>? magnitudeStream;

  /// Time source for the detector. Defaults to [DateTime.now]; injected in tests.
  final DateTime Function()? clock;

  @override
  State<ShakeToDismiss> createState() => _ShakeToDismissState();
}

class _ShakeToDismissState extends State<ShakeToDismiss> {
  late final SustainedShakeDetector _detector;
  late final DateTime Function() _clock;
  StreamSubscription<double>? _sub;
  double _progress = 0;
  double _lastShown = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _detector =
        SustainedShakeDetector(requiredDuration: kShakeDismissDuration);
    _clock = widget.clock ?? DateTime.now;
    final stream = widget.magnitudeStream ??
        userAccelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
            .map((e) => math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z));
    _sub = stream.listen(_onMagnitude);
  }

  void _onMagnitude(double magnitude) {
    if (_done) return;
    final p = _detector.addSample(magnitude, _clock());
    if (p >= 1.0) {
      _done = true;
      _sub?.cancel();
      _sub = null;
      setState(() => _progress = 1);
      widget.onDismissed();
      return;
    }
    // Throttle rebuilds — only repaint on a visible (~2%) change so a 16 Hz
    // stream doesn't drive 16 setStates/sec.
    if ((p - _lastShown).abs() >= 0.02) {
      _lastShown = p;
      setState(() => _progress = p);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.amber.shade400.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(36),
              ),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vibration, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Shake to dismiss',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Critical-Shift FAIL-SAFE dismiss: an unbroken press held for [duration].
///
/// Uses a raw [Listener] (not a tap/long-press `GestureDetector`) so the press
/// can't be stolen by the gesture arena or time out — the fill only completes
/// while the finger stays down, and any lift/cancel reverses it. Visible, with a
/// live progress fill, so it's a deliberate-but-discoverable affordance rather
/// than a hidden long-press.
class HoldToDismiss extends StatefulWidget {
  const HoldToDismiss({
    super.key,
    required this.onDismissed,
    this.duration = kHoldToDismissDuration,
  });

  final Future<void> Function() onDismissed;
  final Duration duration;

  @override
  State<HoldToDismiss> createState() => _HoldToDismissState();
}

class _HoldToDismissState extends State<HoldToDismiss>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_done) {
          _done = true;
          widget.onDismissed();
        }
      });
  }

  void _start() {
    if (_done) return;
    _controller.forward(from: 0);
  }

  void _cancel() {
    if (_done) return;
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _start(),
      onPointerUp: (_) => _cancel(),
      onPointerCancel: (_) => _cancel(),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _controller.value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            const Text(
              'Or hold to dismiss',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
