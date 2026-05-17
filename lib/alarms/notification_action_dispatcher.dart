import 'dart:isolate';
// Namespaced because `hive_ce_flutter` transitively pulls in an
// instance-based `IsolateNameServer` that shadows `dart:ui`'s static
// one. Without the `as ui` qualifier the static lookup below fails to
// resolve to the platform name server. (Same workaround as
// notification_response_handler.dart — applied here when we added the
// hive_ce_flutter import for the snooze-duration setting read.)
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/models/shift.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/shift_repository.dart';
import 'alarm_scheduler.dart';

/// Name under which the main isolate's [ReceivePort] is registered with
/// `IsolateNameServer`. Looked up by the background-isolate notification
/// handler in `notification_response_handler.dart` so it can route
/// Snooze/Dismiss actions back to the live main-isolate dispatcher
/// (avoiding the cross-isolate Hive cache staleness bug where a
/// bg-isolate write to disk does not invalidate the main isolate's
/// in-memory Box cache or fire its `box.watch()` events).
const String alarmActionPortName = 'alarm_action_port';

/// Thin singleton bridge from the main-isolate notification response
/// callback to live runtime services.
///
/// Two notification-response callbacks fire in this isolate:
///   - `onDidReceiveNotificationResponse` while the app is alive
///     (foreground OR backgrounded but not killed).
///   - The cold-launch path in `main.dart` after parsing
///     `getNotificationAppLaunchDetails()`.
///
/// Both are static / top-level entry points with no `BuildContext` and no
/// access to `Provider`. This dispatcher gives them a single place to grab
/// the live [ShiftRepository], [AlarmScheduler], and [GlobalKey] without
/// re-opening Hive boxes or re-initializing anything (in contrast to the
/// background isolate's [notificationBackgroundHandler], which has to).
///
/// The background isolate intentionally does NOT use this — it cannot, the
/// instance set up in `main()` is unreachable from a separate Dart VM.
class NotificationActionDispatcher {
  NotificationActionDispatcher._({
    required this.shifts,
    required this.scheduler,
    required this.navigatorKey,
  });

  static NotificationActionDispatcher? _instance;

  /// Returns the currently installed dispatcher, or null if `setup` has
  /// not yet been called. Callers (foreground response, cold-launch) must
  /// null-check — there's a brief window during `main()` before
  /// [setup] runs where a foreground tap on a stale notification could
  /// race ahead of us. Null in that window is a no-op, not a crash.
  static NotificationActionDispatcher? get instance => _instance;

  /// Installs the dispatcher. Called once from `main()` after the live
  /// repositories and scheduler exist. Calling again throws — a second
  /// install would silently swap pointers that other isolates/captures
  /// may have already bound, which is exactly the kind of bug that
  /// surfaces months later in unrelated places.
  static void setup({
    required ShiftRepository shifts,
    required AlarmScheduler scheduler,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    if (_instance != null) {
      throw StateError(
        'NotificationActionDispatcher.setup() called twice. '
        'This dispatcher is process-global; install it once from main().',
      );
    }
    final dispatcher = NotificationActionDispatcher._(
      shifts: shifts,
      scheduler: scheduler,
      navigatorKey: navigatorKey,
    );
    dispatcher._installPort();
    _instance = dispatcher;
  }

  final ShiftRepository shifts;
  final AlarmScheduler scheduler;
  final GlobalKey<NavigatorState> navigatorKey;

  /// Listens for action messages forwarded from the background isolate's
  /// `notificationBackgroundHandler` when the main isolate is alive. The
  /// port lives for the rest of the process; no teardown is required
  /// (the OS reclaims the entry when the process dies).
  final ReceivePort _actionPort = ReceivePort();

  /// Registers [_actionPort] with the [IsolateNameServer] under
  /// [alarmActionPortName] and starts the listener loop. Removes any
  /// stale registration first so hot-restart in dev does not collide
  /// with the previous isolate's now-defunct port.
  void _installPort() {
    ui.IsolateNameServer.removePortNameMapping(alarmActionPortName);
    final ok = ui.IsolateNameServer.registerPortWithName(
      _actionPort.sendPort,
      alarmActionPortName,
    );
    if (!ok) {
      debugPrint(
        '[fg-dispatch] WARNING: could not register $alarmActionPortName — '
        'bg-isolate actions will fall back to the slow Hive-write path',
      );
      return;
    }
    _actionPort.listen(_onPortMessage);
    debugPrint('[fg-dispatch] port $alarmActionPortName ready');
  }

  /// Receives `{'actionId': String, 'payload': String}` maps from the
  /// background-isolate notification handler. Dispatches to the live
  /// repository-backed methods so the write goes through the main
  /// isolate's in-memory Hive cache (WakeUpScreen's stream subscription
  /// then fires correctly on the change).
  ///
  /// The action-id strings are duplicated here from
  /// `local_notifications_alarm_scheduler.dart`'s `actionIdSnooze` /
  /// `actionIdDismiss` constants to avoid an import cycle. Keep them
  /// in sync if those constants ever change.
  void _onPortMessage(dynamic message) {
    if (message is! Map) {
      debugPrint('[fg-dispatch] port: unexpected message type ${message.runtimeType}');
      return;
    }
    final actionId = message['actionId'];
    final payload = message['payload'];
    if (actionId is! String || payload is! String) {
      debugPrint('[fg-dispatch] port: malformed message $message');
      return;
    }
    debugPrint('[fg-dispatch] port-routed actionId=$actionId');
    if (actionId == 'action_snooze') {
      snooze(payload);
    } else if (actionId == 'action_dismiss') {
      dismiss(payload);
    }
  }

  /// Foreground / cold-launch snooze. Mirrors the background isolate's
  /// `_handleSnooze` but uses the live [ShiftRepository] and
  /// [AlarmScheduler] already in memory, so no Hive re-open and no
  /// timezone re-init are required.
  Future<void> snooze(String payload) async {
    final parsed = _parsePayload(payload);
    if (parsed == null) return;

    // Kill the OS notification FIRST so the FLAG_INSISTENT audio loop
    // stops the moment the user taps. Android auto-cancels on a
    // notification-action-button tap, but the in-app Snooze button on
    // WakeUpScreen has no such auto-cancel — without this explicit call
    // the alarm keeps ringing while we hit Hive and reschedule. Going
    // straight to the FLN singleton (not through `scheduler.cancel`)
    // because the contract is "always touch the OS layer here regardless
    // of which AlarmScheduler implementation is wired" — `FakeAlarmScheduler`
    // in tests doesn't talk to FLN, but its no-op cancel still keeps
    // tests green. Idempotent: cancelling an already-cancelled id is a
    // no-op, so this is safe on the port-routed path (bg isolate → fg
    // dispatcher) where the OS has already dismissed the heads-up.
    await _cancelOsNotification(parsed.notificationId);

    final shift = await shifts.getById(parsed.shiftId);
    if (shift == null) {
      debugPrint(
        '[fg-dispatch] snooze: shift ${parsed.shiftId} not found — '
        'no reschedule',
      );
      return;
    }

    // Snooze duration is user-configurable (see SettingsScreen). The
    // main isolate opens the same on-disk box in `main()`, so this read
    // is synchronous.
    final int snoozeMins =
        Hive.box('settings').get('snooze_duration', defaultValue: 1) as int;
    final snoozedUntil = DateTime.now().add(Duration(minutes: snoozeMins));
    final updated = shift.copyWith(snoozedUntil: snoozedUntil);
    await shifts.upsert(updated);
    debugPrint('[fg-dispatch] snooze: ${updated.id} snoozedUntil=$snoozedUntil');

    // Going through AlarmScheduler.scheduleAt means the production
    // LocalNotificationsAlarmScheduler will apply the SAME notification
    // details builder (action buttons, FullScreenIntent, iOS category)
    // the original alarm used — no duplication of the build logic here.
    await scheduler.scheduleAt(
      id: parsed.notificationId,
      fireAt: snoozedUntil,
      title: _titleFor(updated),
      body: _bodyFor(updated),
      payload: payload,
    );
  }

  /// Foreground / cold-launch dismiss. Marks the shift acknowledged
  /// (and wipes any pending snooze on the same occurrence — user has
  /// chosen to handle the alarm fully) and cancels the OS notification.
  Future<void> dismiss(String payload) async {
    final parsed = _parsePayload(payload);
    if (parsed == null) return;

    // Same rationale as snooze: kill the OS notification (and its
    // FLAG_INSISTENT audio loop) before any DB work so the audio dies
    // immediately on tap rather than waiting on the Hive write.
    await _cancelOsNotification(parsed.notificationId);

    final shift = await shifts.getById(parsed.shiftId);
    if (shift != null) {
      await shifts.upsert(
        shift.copyWith(isAcknowledged: true, clearSnoozedUntil: true),
      );
      debugPrint('[fg-dispatch] dismiss: marked ${shift.id} acknowledged');
    } else {
      debugPrint(
        '[fg-dispatch] dismiss: shift ${parsed.shiftId} not found — '
        'notification already cancelled',
      );
    }
  }

  /// Direct call into the FLN singleton to cancel an OS notification by
  /// id. Wrapped in try/catch so a transient plugin failure (e.g. during
  /// app teardown) cannot strand the caller mid-action; the alternative —
  /// letting the throw propagate — would leave the Hive write either
  /// not done (snooze) or done with the audio still looping (dismiss).
  Future<void> _cancelOsNotification(int notificationId) async {
    try {
      await FlutterLocalNotificationsPlugin().cancel(id: notificationId);
    } catch (e) {
      debugPrint('[fg-dispatch] FLN cancel($notificationId) threw: $e');
    }
  }

}

/// Mirrors the same parser in `notification_response_handler.dart`. The two
/// copies cannot share code without exposing a module-private helper across
/// files; this is a 6-line duplication. Format: `<shiftId>|<notificationId>`.
({String shiftId, int notificationId})? _parsePayload(String payload) {
  final parts = payload.split('|');
  if (parts.length != 2) {
    debugPrint('[fg-dispatch] malformed payload "$payload"');
    return null;
  }
  final notificationId = int.tryParse(parts[1]);
  if (notificationId == null) {
    debugPrint('[fg-dispatch] non-int notificationId in "$payload"');
    return null;
  }
  return (shiftId: parts[0], notificationId: notificationId);
}

// Kept in sync with `AlarmEngine._titleFor` / `_bodyFor` AND the equivalents
// in `notification_response_handler.dart`. Three copies because AlarmEngine's
// are private and the background isolate's are file-private; drift
// self-heals on the next AlarmEngine reconcile, which will replace any
// scheduled entry via its own copy.
String _titleFor(Shift s) {
  switch (s.type) {
    case ShiftType.day:
      return 'Day shift coming up';
    case ShiftType.night:
      return 'Night shift coming up';
    case ShiftType.afternoon:
      return 'Afternoon shift coming up';
    case ShiftType.off:
      // Unreachable — OFF shifts are filtered by AlarmEngine before they
      // ever reach a notification. Benign fallback.
      return 'Shift coming up';
  }
}

String _bodyFor(Shift s) {
  final hh = (s.startMinutes ~/ 60).toString().padLeft(2, '0');
  final mm = (s.startMinutes % 60).toString().padLeft(2, '0');
  return 'Starts at $hh:$mm';
}
