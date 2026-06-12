import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../alarms/alarm_scheduler.dart';
import '../alarms/alarm_sound.dart';
import '../alarms/alarm_sync_service.dart' show noShiftPayloadSentinel;
import '../alarms/notification_action_dispatcher.dart';
import '../alarms/pending_dismissal_guard.dart';
import '../alarms/ringtone_channel.dart';
import '../data/models/shift.dart';
import '../data/repositories/app_alarm_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../state/app_preferences.dart';
import 'critical_dismiss_controls.dart';
import 'main_layout.dart';
import 'shift_format.dart';

/// Alarm-routing channel — same wire name as `MainActivity.CHANNEL` and
/// main.dart's `_alarmRoutingChannel`. WakeUpScreen uses it for the two
/// lifecycle calls the Kotlin side answers: polling the native dismissal
/// ledger (cross-isolate reactivity) and relinquishing the lock-screen
/// window flags on teardown.
const MethodChannel _alarmRoutingChannel =
    MethodChannel('rostrik/alarm_routing');

/// Full-screen wake-up shown when an alarm fires.
///
/// Audio model — TWO cases:
///   * Bundled tone (default): the OS notification is the single source of
///     sound. `LocalNotificationsAlarmScheduler` schedules with FLAG_INSISTENT,
///     so the channel sound loops until the notification is cancelled. This
///     screen owns NO audio for these; every dismiss path ultimately calls
///     `AlarmScheduler.cancel(notificationId)` or writes a Hive flag that
///     causes a cancel, which stops the loop.
///   * Custom ringtone (Phase 2b single-notification): the alarm was scheduled
///     on a SILENT channel (no OS sound), and the user's tone is played HERE by
///     the native `MediaPlayer` via [RingtoneChannel.playAlarmUri] — started in
///     `initState` when [customRingtoneUri] is non-null and stopped on every
///     exit path (dismiss / snooze / self-destruct / dispose). This is the
///     trade-off accepted for the June Beta: a custom tone only rings when the
///     FSI actually launches this screen (locked / not-foreground); when the
///     phone is already unlocked and active the FSI shows a heads-up instead,
///     so the custom tone is skipped (the user is already awake).
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
///   - On dispose: ticker cancel + subscription cancel + a
///     [RingtoneChannel.stopPreview] safety net — stops the foreground-service
///     player and cancels the haptic loop, guaranteeing no audio outlives the
///     screen on any teardown path the explicit handlers didn't cover. Applies
///     to every alarm now (custom AND preset both play via the service).
///
/// Lockdown: the root [Scaffold] is wrapped in an UNCONDITIONAL
/// `PopScope(canPop: false)`. This screen is the root route on alarm launch,
/// so a system back/predictive-back would otherwise finish the FSI activity —
/// and via the dispose safety net silently kill a custom-tone alarm with no
/// dismiss/snooze bookkeeping. Every exit must go through Snooze,
/// slide-to-dismiss, or the Critical shake/hold mechanics.
class WakeUpScreen extends StatefulWidget {
  const WakeUpScreen({
    super.key,
    required this.shiftId,
    this.notificationId,
    this.isCritical = false,
    this.appAlarmId = '',
    this.customRingtoneUri,
    this.soundKey = kDefaultAlarmSoundKey,
    this.vibrationEnabled = true,
    this.ringtoneChannel,
  });

  /// Shift id parsed from the notification payload. Used to look up the
  /// shift details to display.
  final String shiftId;

  /// OS notification id parsed from the payload. Cancelled on dismiss so
  /// the alarm doesn't sit in the notification shade. Null only if the
  /// payload was malformed — in which case dismiss skips the cancel.
  final int? notificationId;

  /// Critical-Shift alarm: require a sustained shake (with a 3-second hold
  /// fail-safe) to dismiss instead of the casual slide. Parsed from the 3rd
  /// payload field by `_parseWakeUpRoute`.
  final bool isCritical;

  /// Owning [AppAlarm] id parsed from the payload (5th field), or '' when
  /// absent. Lets a dismiss permanently delete a fired one-time alarm marked
  /// auto-delete. The shake/hold/slide dismiss paths all funnel through
  /// `_onDismiss`, so deletion happens once, at the dismissal instant.
  final String appAlarmId;

  /// Custom-ringtone URI parsed from the payload (6th field), or null for a
  /// bundled/preset-tone alarm. When non-null the native player plays this
  /// URI; when null it plays the [soundKey]'s bundled tone. EITHER way the
  /// audio runs through the foreground service (see the class doc) — every
  /// fire-time alarm does.
  final String? customRingtoneUri;

  /// Bundled-tone key parsed from the payload (4th field) — selects which
  /// preset `res/raw` tone the native player loops when [customRingtoneUri] is
  /// null. Defaults to [kDefaultAlarmSoundKey] (a bare/legacy payload).
  final String soundKey;

  /// Whether to vibrate, parsed from the payload (7th field). Drives the
  /// continuous native haptic loop alongside a custom tone. Only applies to the
  /// custom-tone path here — bundled-tone alarms vibrate via their channel.
  final bool vibrationEnabled;

  /// Injectable native-audio bridge — defaults to a real [RingtoneChannel] in
  /// `initState`. The default is itself test-safe (every method no-ops off
  /// Android / without a native handler).
  final RingtoneChannel? ringtoneChannel;

  @override
  State<WakeUpScreen> createState() => _WakeUpScreenState();
}

class _WakeUpScreenState extends State<WakeUpScreen>
    with WidgetsBindingObserver {
  /// How far back / forward to watch for Hive changes. Wide enough that
  /// any realistic wake-up alarm is in range (a snoozed alarm pushed
  /// forward by 9 minutes can't possibly cross this boundary), but
  /// bounded so we're not pumping the entire roster through this stream.
  static const Duration _watchHalfWindow = Duration(days: 7);

  Timer? _clockTicker;
  StreamSubscription<List<Shift>>? _shiftSub;

  /// Native-audio bridge. This screen owns the looping tone for EVERY alarm —
  /// custom URI or preset — by starting the foreground-service player; the OS
  /// notification is silent.
  late final RingtoneChannel _ringtone;

  /// One-shot guard so multiple stream emissions that all satisfy the
  /// self-destruct condition (e.g. ack and snooze landing in the same
  /// box change) don't fire pushReplacement repeatedly. Without this a
  /// quick double-tap could stack two RosterScreens behind us.
  bool _destructed = false;

  /// Live repository handle, captured in initState so the ledger-poll path
  /// can ack the dismissal through the MAIN isolate's Hive (updating its
  /// in-memory cache + firing its streams) without touching `context` from
  /// an async gap. Null for shift-less alarms (sentinel id — nothing to ack).
  ShiftRepository? _shiftRepo;

  /// Re-entrancy guard for the 1 Hz native-ledger poll — a slow channel hop
  /// must not stack a second poll on top of the first.
  bool _ledgerCheckInFlight = false;

  @override
  void initState() {
    super.initState();
    // Lifecycle observer for the SLEEPING-TICKER fix — see
    // [didChangeAppLifecycleState]. Removed in dispose.
    WidgetsBinding.instance.addObserver(this);
    _ringtone = widget.ringtoneChannel ?? RingtoneChannel();

    // START the looping tone through the native foreground-service engine —
    // for EVERY fire-time alarm, custom OR preset. The OS notification is on
    // the silent channel (no FLAG_INSISTENT), so this is the ONLY audio, and
    // the foreground service keeps it alive when the lock-screen shade occludes
    // (and Android 14 destroys) this activity. Fire-and-forget; the native side
    // loops until a Dismiss/Snooze stops it.
    final customUri = widget.customRingtoneUri;
    if (customUri != null && customUri.isNotEmpty) {
      _ringtone.playAlarmUri(customUri, vibrate: widget.vibrationEnabled);
    } else {
      // Preset internal tone: play its bundled res/raw through the SAME
      // service (regression fix — presets used to ride FLAG_INSISTENT, which
      // the lock-screen shade pull silenced).
      _ringtone.playAlarmBundled(
        resolveAlarmSound(widget.soundKey).androidResource,
        vibrate: widget.vibrationEnabled,
      );
    }

    // 1 Hz refresh — granular enough that the seconds tick visibly but
    // doesn't burn CPU. Forces a rebuild that re-reads DateTime.now(), AND
    // piggybacks the cross-isolate dismissal poll (see
    // _checkNativeDismissalLedger) so an external dismiss kills this screen
    // within a second.
    _clockTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _checkNativeDismissalLedger();
    });

    // Reactive listen on the shift's Hive record. `watchInRange` is the
    // only reactive surface ShiftRepository exposes; we filter for our
    // shiftId inside the listener. The wide window keeps things robust
    // against the small bookkeeping window between scheduling and firing.
    //
    // This stream is the FAST self-destruct path: any dismissal that lands
    // in THIS isolate's Hive (in-app dismiss, foreground dispatcher,
    // bg-isolate port forward) fires it instantly. It CANNOT see a write
    // another isolate made straight to disk — Hive's watch events are
    // per-VM-cache — which is exactly the gap the native-ledger poll on the
    // clock ticker closes.
    //
    // Skip the subscription entirely for shift-less alarms — there is
    // no Hive row to watch, and the self-destruct condition (ack /
    // snooze) doesn't apply. Slide-to-dismiss still works because it
    // goes through `scheduler.cancel(notificationId)`, not the repo.
    if (widget.shiftId != noShiftPayloadSentinel) {
      _shiftRepo = context.read<ShiftRepository>();
      final now = DateTime.now();
      _shiftSub = _shiftRepo!
          .watchInRange(
            now.subtract(_watchHalfWindow),
            now.add(_watchHalfWindow),
          )
          .listen(_onShiftsChanged);
    }
  }

  /// SLEEPING-TICKER fix (Android 14 field bug): when the notification shade
  /// suspends the Flutter UI, the 1 Hz ticker (and its ledger poll) is
  /// asleep. A Dismiss tapped from the shade updates the native ledger, but
  /// nothing in Dart ran until the user touched the screen — leaving a dead
  /// WakeUpScreen on display. The instant the app transitions back to
  /// [AppLifecycleState.resumed], drain the ledger immediately rather than
  /// waiting for the next tick.
  ///
  /// THE SILENCE-BUG CONTRACT also lives here, by omission: inactive /
  /// paused / hidden / detached deliberately do NOTHING — and above all
  /// never touch [_ringtone]. A ringing alarm's audio may only stop via an
  /// explicit Dismiss or Snooze (the native side enforces the same rule for
  /// activity pause/stop/destroy). Adding any audio handling to the
  /// non-resumed branches is a regression of the exact field bug where
  /// pulling down the shade silenced the alarm.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNativeDismissalLedger();
    }
    // All other states: intentionally no action.
  }

  /// CROSS-ISOLATE REACTIVITY (Zombie-UI, final piece): detects a dismissal
  /// performed OUTSIDE this isolate — the notification-panel Dismiss handled
  /// by the background engine — and self-destructs within one tick.
  ///
  /// Why polling the native ledger and not a Hive listenable: the background
  /// isolate writes to DISK; this isolate's Box cache (and therefore every
  /// `box.watch()` / ValueListenable built on it) never sees that write. The
  /// `pending_dismissals` ledger file is process-level truth both sides
  /// share. One tiny channel call per second, bounded strictly to the
  /// ringing window — the poll dies with this screen.
  ///
  /// On a hit: replay the ledger into THIS isolate's Hive via the live repo
  /// (so the cache, the streams, and the engine's next reconcile all agree),
  /// clear the ledger natively, then run the normal self-destruct sequence
  /// (stops the native tone, replaces this screen with the chassis).
  Future<void> _checkNativeDismissalLedger() async {
    if (_destructed || _ledgerCheckInFlight) return;
    if (widget.shiftId == noShiftPayloadSentinel) return;
    _ledgerCheckInFlight = true;
    try {
      final raw = await _alarmRoutingChannel
          .invokeMethod<List<Object?>>('getPendingDismissals');
      final ids = raw?.whereType<String>().toList() ?? const <String>[];
      if (!ids.contains(widget.shiftId)) return;

      debugPrint(
        '[wake] external dismissal found in native ledger for '
        '${widget.shiftId} — replaying to Hive and self-destructing',
      );
      final repo = _shiftRepo;
      if (repo != null) {
        // Replay EVERY ledger entry, not just ours — they are all
        // dismissals, and clearing the ledger below must not orphan a
        // sibling entry before the boot-time replay would have seen it.
        await ackPendingDismissalsInHive(shifts: repo, shiftIds: ids);
      }
      try {
        await _alarmRoutingChannel.invokeMethod<void>('clearPendingDismissals');
      } catch (_) {
        // Best-effort — an uncleared ledger replays idempotently next boot.
      }
      await _selfDestruct();
    } catch (_) {
      // No native handler (iOS / tests) — the Hive stream fast path above
      // remains the reactive surface on those platforms.
    } finally {
      _ledgerCheckInFlight = false;
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
    // THE shared handled-occurrence predicate — same gate main.dart's
    // cold-boot wake route applies, so screen and route can never disagree
    // about whether this alarm is still live.
    if (shift.isAlarmHandledAt(DateTime.now())) {
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
    // An external Dismiss/Snooze (notification action) flipped the Hive flag
    // that brought us here. For a custom alarm the dispatcher already stopped
    // the native audio, but stopping again is idempotent and covers the
    // bg-isolate→port race where the order isn't guaranteed.
    _ringtone.stopPreview();
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
    WidgetsBinding.instance.removeObserver(this);
    _shiftSub?.cancel();
    _shiftSub = null;
    _clockTicker?.cancel();
    _clockTicker = null;
    // Safety net for the CUSTOM-tone case: this screen owns the native player,
    // so guarantee it's stopped if the screen is torn down by any path the
    // explicit handlers below didn't already cover. Idempotent / no-op for a
    // bundled-tone alarm (the OS owns that sound via FLAG_INSISTENT, and the
    // notification cancel in the dismiss paths is what stops it).
    _ringtone.stopPreview();
    // WINDOW-FLAG PURGE: every exit path (slider, snooze self-destruct,
    // reactive ledger pop) lands here, so this is the single point where the
    // app relinquishes the lock screen — MainActivity clears showWhenLocked /
    // turnScreenOn / FLAG_KEEP_SCREEN_ON. Without it, a WakeUpScreen
    // stranded in the Recents task kept drawing over the keyguard long
    // after the alarm was externally dismissed.
    _relinquishLockScreen();
    super.dispose();
  }

  /// Fire-and-forget signal to MainActivity to drop the lock-screen bypass
  /// window flags. Swallows every failure — no native handler (iOS / tests)
  /// just means there are no flags to drop.
  Future<void> _relinquishLockScreen() async {
    try {
      await _alarmRoutingChannel.invokeMethod<void>('relinquishLockScreen');
    } catch (_) {
      // No-op off Android / in tests.
    }
  }

  Future<void> _onDismiss() async {
    // Capture context-dependent refs up front — they can't be safely
    // re-read after the awaits below.
    final scheduler = context.read<AlarmScheduler>();
    final alarms = context.read<AppAlarmRepository>();
    final navigator = Navigator.of(context);

    // Stop the native custom tone immediately on the dismiss gesture (silent-
    // channel alarms have no FLAG_INSISTENT loop for the cancel below to kill).
    // No-op for bundled-tone alarms / off Android.
    await _ringtone.stopPreview();

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

    // Auto-delete a fired one-time alarm at the dismissal instant (the
    // shake/hold/slide paths all reach here). No-op unless the payload carried
    // a rule id for an auto-delete one-time alarm.
    await deleteAlarmIfAutoDelete(alarms, widget.appAlarmId);

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
    // Stop the native custom tone now (the dispatcher also stops it, but do it
    // here too so the audio dies the instant the button is tapped, before the
    // async dispatch + Hive write). No-op for bundled-tone alarms.
    _ringtone.stopPreview();
    NotificationActionDispatcher.instance?.snooze('${widget.shiftId}|$id');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeLabel = formatClock(
      now.hour * 60 + now.minute,
      use24Hour: AppPreferences.use24HourOf(context),
    );
    // Pulled from the same 'settings' box the engine/dispatcher consult,
    // so the button label can't disagree with what a tap will actually
    // do. The box was opened in `main()` before runApp, so this read is
    // synchronous. Default mirrors the historical 9-minute snooze.
    final int snoozeMins =
        Hive.box('settings').get('snooze_duration', defaultValue: 1) as int;

    // UNCONDITIONAL back-gesture lockdown. WakeUpScreen is the root route on
    // alarm launch, so a system back/predictive-back would finish the FSI
    // activity — tearing this screen down and (via dispose's safety net)
    // silencing a custom-tone alarm with NO dismiss/snooze bookkeeping. A
    // ringing alarm may only be left through the explicit affordances:
    // Snooze, slide-to-dismiss, or the Critical shake/hold mechanics.
    return PopScope(
      canPop: false,
      child: Scaffold(
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
                        // Critical-Shift alarms can't be silenced by a casual
                        // swipe: require a sustained shake, with a 3-second hold
                        // as the always-present fail-safe. Normal alarms keep the
                        // slide-to-dismiss.
                        if (widget.isCritical) ...[
                          ShakeToDismiss(onDismissed: _onDismiss),
                          const SizedBox(height: 12),
                          HoldToDismiss(onDismissed: _onDismiss),
                        ] else ...[
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
                      ],
                    ),
                  ),
                ),
              );
            },
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
    // Shift-less alarms (oneTime today; custom-repeat / bundles later)
    // carry the `NONE` sentinel as their shiftId. Skip the repository
    // lookup entirely and render a neutral title — the FutureBuilder
    // path would otherwise resolve to "Upcoming shift" copy that's
    // factually wrong for a non-shift alarm.
    if (shiftId == noShiftPayloadSentinel) {
      return const _SummaryText('Alarm');
    }
    final use24Hour = AppPreferences.use24HourOf(context);
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
        final start = formatClock(shift.startMinutes, use24Hour: use24Hour);
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
