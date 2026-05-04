import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:provider/provider.dart';

import '../alarms/alarm_scheduler.dart';
import '../data/models/shift.dart';
import '../data/repositories/shift_repository.dart';
import 'roster_screen.dart';
import 'shift_format.dart';

/// Full-screen wake-up shown when an alarm fires.
///
/// Lifecycle:
///   - On init: starts looping the device's system alarm tone on the
///     alarm audio stream + a 1Hz ticker to refresh the clock.
///   - On dismiss (slide-to-confirm): stops the ringtone, cancels the OS
///     notification (so it doesn't linger in the shade), then replaces
///     this screen with the roster.
///   - On dispose: defensive double-stop of the ringtone + ticker, in
///     case the user backgrounds the app via gesture instead of dismiss.
class WakeUpScreen extends StatefulWidget {
  const WakeUpScreen({super.key, required this.shiftId, this.notificationId});

  /// Shift id parsed from the notification payload. Used to look up the
  /// shift details to display.
  final String shiftId;

  /// OS notification id parsed from the payload. Cancelled on dismiss so
  /// the alarm doesn't sit in the notification shade. Null only if the
  /// payload was malformed — in which case dismiss skips the cancel.
  final int? notificationId;

  @override
  State<WakeUpScreen> createState() => _WakeUpScreenState();
}

class _WakeUpScreenState extends State<WakeUpScreen> {
  final FlutterRingtonePlayer _ringtone = FlutterRingtonePlayer();
  Timer? _clockTicker;
  bool _ringing = false;

  @override
  void initState() {
    super.initState();
    _startRinging();
    // 1 Hz refresh — granular enough that the seconds tick visibly but
    // doesn't burn CPU. Forces a rebuild that re-reads DateTime.now().
    _clockTicker =
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  Future<void> _startRinging() async {
    try {
      await _ringtone.playAlarm(
        looping: true,
        volume: 1.0,
        asAlarm: true, // routes to the alarm audio stream, not media
      );
      _ringing = true;
    } catch (_) {
      // Ringtone failure is non-fatal — the visual wake-up still does its
      // job. Most likely cause: emulator without a system alarm tone.
      _ringing = false;
    }
  }

  Future<void> _stopRinging() async {
    if (!_ringing) return;
    _ringing = false;
    try {
      await _ringtone.stop();
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    _clockTicker = null;
    _stopRinging();
    super.dispose();
  }

  Future<void> _onDismiss() async {
    // Capture context-dependent refs up front — they can't be safely
    // re-read after the awaits below.
    final scheduler = context.read<AlarmScheduler>();
    final navigator = Navigator.of(context);

    await _stopRinging();
    final notificationId = widget.notificationId;
    if (notificationId != null) {
      // Best-effort cancel: if the payload was malformed or the
      // scheduler somehow forgot the id, we still want to leave the
      // wake-up screen.
      try {
        await scheduler.cancel(notificationId);
      } catch (_) {}
    }
    if (!mounted) return;
    // Replace rather than pop — the wake-up screen is the root route on
    // alarm-launch, so popping would close the app instead of revealing
    // the roster underneath.
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const RosterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeLabel = formatHhmm(now.hour * 60 + now.minute);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Text(
                  timeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 128,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _ShiftSummary(shiftId: widget.shiftId),
              const Spacer(),
              _SlideToDismiss(onDismissed: _onDismiss),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Slide to dismiss',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftSummary extends StatelessWidget {
  const _ShiftSummary({required this.shiftId});

  final String shiftId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Shift?>(
      future: context.read<ShiftRepository>().getById(shiftId),
      builder: (_, snap) {
        final shift = snap.data;
        if (shift == null) {
          // Either still loading or the shift was deleted between
          // schedule and fire — show neutral copy rather than a spinner
          // so the user isn't confused at 4am.
          return const _SummaryText('Upcoming shift');
        }
        final type = shiftTypeLabel(shift.type);
        final start = formatHhmm(shift.startMinutes);
        return _SummaryText('Upcoming $type shift · starts $start');
      },
    );
  }
}

class _SummaryText extends StatelessWidget {
  const _SummaryText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

/// Full-width slide-to-confirm bar. Custom-built (no extra package) so the
/// dismiss gesture is unmistakably deliberate — a casual touch can't
/// accidentally silence an alarm. Threshold is 60% of the track.
class _SlideToDismiss extends StatefulWidget {
  const _SlideToDismiss({required this.onDismissed});
  final Future<void> Function() onDismissed;

  @override
  State<_SlideToDismiss> createState() => _SlideToDismissState();
}

class _SlideToDismissState extends State<_SlideToDismiss>
    with SingleTickerProviderStateMixin {
  static const double _trackHeight = 72;
  static const double _handleSize = 64;
  static const double _commitFraction = 0.6;

  double _dragX = 0;
  bool _committed = false;

  void _onUpdate(double maxX, DragUpdateDetails d) {
    if (_committed) return;
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(0.0, maxX);
    });
  }

  Future<void> _onEnd(double maxX) async {
    if (_committed) return;
    if (_dragX >= maxX * _commitFraction) {
      _committed = true;
      setState(() => _dragX = maxX);
      await widget.onDismissed();
    } else {
      setState(() => _dragX = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxX = trackWidth - _handleSize;
        final progress = maxX <= 0 ? 0.0 : (_dragX / maxX).clamp(0.0, 1.0);
        return Container(
          height: _trackHeight,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(_trackHeight / 2),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Filled progress on the left side as the user drags.
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(_trackHeight / 2),
                  ),
                ),
              ),
              Positioned(
                left: 4 + _dragX,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (d) => _onUpdate(maxX, d),
                  onHorizontalDragEnd: (_) => _onEnd(maxX),
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
