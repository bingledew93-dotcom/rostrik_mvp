import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../alarms/alarm_scheduler.dart';
import '../alarms/alarm_sync_service.dart' show noShiftPayloadSentinel;
import '../alarms/notification_action_dispatcher.dart';
import '../data/models/shift.dart';
import '../data/repositories/shift_repository.dart';
import 'main_layout.dart';
import 'shift_format.dart';

/// Full-screen wake-up shown when an alarm fires.
///
/// Audio model: the OS notification is the single source of alarm sound.
/// `LocalNotificationsAlarmScheduler` schedules with FLAG_INSISTENT, so
/// the channel sound loops continuously until the notification is
/// cancelled (slide-to-dismiss here, or the action-button paths in the
/// background isolate / dispatcher). This screen owns NO audio — every
/// dismiss path ultimately calls `AlarmScheduler.cancel(notificationId)`
/// or writes the Hive flag that causes a cancel, which is what stops
/// the loop.
///
/// Lifecycle:
///   - On init: 1Hz ticker to refresh the clock + a reactive subscription
///     to this shift's record in Hive.
///   - On dismiss (slide-to-confirm): cancels the OS notification (kills
///     the insistent audio loop AND removes the notification from the
///     shade), then replaces this screen with the roster.
///   - On the shift becoming `isAcknowledged` or `snoozedUntil` flipping
///     to a future instant (the background-isolate or foreground-
///     dispatcher Snooze/Dismiss paths both write these fields, AND
///     cancel/replace the notification before the write): the screen
///     self-destructs — replaces itself with the roster. This is what
///     fixes the "phantom UI" case where the user dismissed via heads-up
///     while WakeUpScreen was already pushed.
///   - On dispose: ticker cancel + subscription cancel. No audio cleanup
///     needed — the OS owns the sound.
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
  /// How far back / forward to watch for Hive changes. Wide enough that
  /// any realistic wake-up alarm is in range (a snoozed alarm pushed
  /// forward by 9 minutes can't possibly cross this boundary), but
  /// bounded so we're not pumping the entire roster through this stream.
  static const Duration _watchHalfWindow = Duration(days: 7);

  Timer? _clockTicker;
  StreamSubscription<List<Shift>>? _shiftSub;

  /// One-shot guard so multiple stream emissions that all satisfy the
  /// self-destruct condition (e.g. ack and snooze landing in the same
  /// box change) don't fire pushReplacement repeatedly. Without this a
  /// quick double-tap could stack two RosterScreens behind us.
  bool _destructed = false;

  @override
  void initState() {
    super.initState();
    // 1 Hz refresh — granular enough that the seconds tick visibly but
    // doesn't burn CPU. Forces a rebuild that re-reads DateTime.now().
    _clockTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );

    // Reactive listen on the shift's Hive record. `watchInRange` is the
    // only reactive surface ShiftRepository exposes; we filter for our
    // shiftId inside the listener. The wide window keeps things robust
    // against the small bookkeeping window between scheduling and firing.
    //
    // Skip the subscription entirely for shift-less alarms — there is
    // no Hive row to watch, and the self-destruct condition (ack /
    // snooze) doesn't apply. Slide-to-dismiss still works because it
    // goes through `scheduler.cancel(notificationId)`, not the repo.
    if (widget.shiftId != noShiftPayloadSentinel) {
      final now = DateTime.now();
      _shiftSub = context
          .read<ShiftRepository>()
          .watchInRange(
            now.subtract(_watchHalfWindow),
            now.add(_watchHalfWindow),
          )
          .listen(_onShiftsChanged);
    }
  }

  /// Stream listener: triggered on any change inside the watched range.
  /// We find our specific shift by id and apply the self-destruct rule.
  /// Shifts deleted out from under us are ignored — there's no point
  /// closing the screen for a phantom that no longer exists, and the
  /// user can still slide-to-dismiss.
  void _onShiftsChanged(List<Shift> shifts) {
    if (_destructed || !mounted) return;
    Shift? shift;
    for (final s in shifts) {
      if (s.id == widget.shiftId) {
        shift = s;
        break;
      }
    }
    if (shift == null) return;
    final snoozedUntil = shift.snoozedUntil;
    final now = DateTime.now();
    final shouldClose =
        shift.isAcknowledged ||
        (snoozedUntil != null && snoozedUntil.isAfter(now));
    if (shouldClose) {
      _selfDestruct();
    }
  }

  /// Auto-close path. Replaces the WakeUpScreen with the roster. Does
  /// NOT cancel the OS notification here — both the Snooze and Dismiss
  /// handlers (background isolate AND foreground dispatcher) have
  /// already done that before writing the Hive change that triggers
  /// this method, so a second cancel would either be a no-op or, for
  /// Snooze, would clobber the freshly-rescheduled alarm. Likewise no
  /// audio cleanup — the OS owns the insistent loop and the upstream
  /// handler already cancelled the notification that was driving it.
  Future<void> _selfDestruct() async {
    if (_destructed) return;
    _destructed = true;
    if (!mounted) return;
    final navigator = Navigator.of(context);
    // pushReplacement (rather than pop) because WakeUpScreen is the
    // root route in every path that launches it (see `_routeToWakeUp`'s
    // pushAndRemoveUntil with `(_) => false`). Popping would close the
    // app instead of revealing the chassis. Landing on MainLayout (not
    // a bare RosterScreen) preserves the tab bar so the user can
    // navigate after the alarm.
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const MainLayout()),
    );
  }

  @override
  void dispose() {
    _shiftSub?.cancel();
    _shiftSub = null;
    _clockTicker?.cancel();
    _clockTicker = null;
    // No audio cleanup — the OS owns alarm sound via FLAG_INSISTENT on
    // the notification. Every dismissal path (slide-to-dismiss here,
    // _selfDestruct, the Snooze/Dismiss action buttons) cancels the
    // notification before this widget is torn down, which is what
    // stops the audio. A native swipe-away gesture on this screen
    // alone does NOT stop the sound — that's by design: the alarm
    // keeps ringing until the user explicitly dismisses the
    // notification or the OS times it out.
    super.dispose();
  }

  Future<void> _onDismiss() async {
    // Capture context-dependent refs up front — they can't be safely
    // re-read after the awaits below.
    final scheduler = context.read<AlarmScheduler>();
    final navigator = Navigator.of(context);

    final notificationId = widget.notificationId;
    if (notificationId != null) {
      // Best-effort cancel: cancelling the OS notification removes it
      // from the shade AND kills the FLAG_INSISTENT audio loop. If the
      // payload was malformed (notificationId == null) the audio will
      // keep ringing until the OS times it out — degraded but not
      // broken. We still leave the wake-up screen so the user isn't
      // trapped.
      try {
        await scheduler.cancel(notificationId);
      } catch (_) {}
    }
    if (!mounted) return;
    // Replace rather than pop — the wake-up screen is the root route on
    // alarm-launch, so popping would close the app instead of revealing
    // the chassis underneath. MainLayout (not a bare RosterScreen) is
    // the right landing so the tab bar comes back with the user.
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const MainLayout()),
    );
  }

  /// In-app Snooze button. Functionally identical to the heads-up
  /// notification's Snooze action: dispatches through the singleton
  /// dispatcher, which writes `snoozedUntil = now + snooze_duration` to the live
  /// `ShiftRepository` and reschedules the OS notification.
  ///
  /// No manual navigation, no audio handling — the reactive shift
  /// subscription installed in `initState` picks up the Hive write,
  /// fires `_onShiftsChanged`, and triggers `_selfDestruct`, which
  /// replaces this screen with RosterScreen. The OS-side notification
  /// cancel (via `scheduler.cancel` inside the dispatcher) is what
  /// stops the looping FLAG_INSISTENT audio.
  ///
  /// If `notificationId` is null (only possible on a malformed payload —
  /// a programmer error, never a user state) the dispatcher's parser
  /// rejects the reconstructed payload and silently no-ops. Same
  /// best-effort posture as the existing `_onDismiss` path.
  void _onSnooze() {
    final id = widget.notificationId;
    if (id == null) return;
    NotificationActionDispatcher.instance?.snooze('${widget.shiftId}|$id');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeLabel = formatHhmm(now.hour * 60 + now.minute);
    // Pulled from the same 'settings' box the engine/dispatcher consult,
    // so the button label can't disagree with what a tap will actually
    // do. The box was opened in `main()` before runApp, so this read is
    // synchronous. Default mirrors the historical 9-minute snooze.
    final int snoozeMins =
        Hive.box('settings').get('snooze_duration', defaultValue: 1) as int;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        // Layout shape: LayoutBuilder → SingleChildScrollView →
        // SizedBox(height: safeHeight) → Padding → Column. The SizedBox
        // is the key — it gives the Column a strict, bounded vertical
        // extent, which is what Spacer needs to lay out. We deliberately
        // avoid IntrinsicHeight: the slide-to-dismiss handle uses an
        // inner LayoutBuilder, and intrinsic queries traversing through
        // a LayoutBuilder throw at layout time. We also avoid
        // SliverFillRemaining (its flex-child path triggered the same
        // intrinsic-dimension crash during the FSI lock-screen boot).
        //
        // `safeHeight` is clamped to a 650 px minimum so a temporarily
        // tiny viewport (e.g. transient FSI constraints during boot, or
        // a split-screen window) still gives the Column enough room to
        // distribute its Spacers without collapsing the bottom controls
        // off-screen; the outer SingleChildScrollView lets that excess
        // scroll instead of overflowing.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double viewportHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height;
            final double safeHeight = math.max(viewportHeight, 650.0);
            return SingleChildScrollView(
              child: SizedBox(
                height: safeHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top breathing room. Smaller flex than the middle
                      // spacer so the clock sits in the upper third
                      // rather than dead-centre.
                      const Spacer(flex: 2),
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
                      // Mid-section breathing room — larger flex so the
                      // bottom action cluster anchors low on tall screens.
                      // In landscape this collapses to whatever space is
                      // left after the fixed content; the outer
                      // SingleChildScrollView lets the layout scroll if
                      // the 650 px floor exceeds the viewport, so the
                      // buttons stay reachable.
                      const Spacer(flex: 5),
                      // Snooze — large tap target, warm amber so it's
                      // distinguishable from the white slide-to-dismiss
                      // handle at 4 AM. Height matches the slider track
                      // for visual rhythm. No elevation (flat to match
                      // the rest of the screen) and pill-shaped to read
                      // as the action partner of the slider below.
                      SizedBox(
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _onSnooze,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade400,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(36),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          child: Text('Snooze ($snoozeMins min)'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SlideToDismiss(onDismissed: _onDismiss),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Slide to dismiss',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
    // Shift-less alarms (oneTime today; custom-repeat / bundles later)
    // carry the `NONE` sentinel as their shiftId. Skip the repository
    // lookup entirely and render a neutral title — the FutureBuilder
    // path would otherwise resolve to "Upcoming shift" copy that's
    // factually wrong for a non-shift alarm.
    if (shiftId == noShiftPayloadSentinel) {
      return const _SummaryText('Alarm');
    }
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
