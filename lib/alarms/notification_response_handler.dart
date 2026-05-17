// Namespaced because `hive_ce_flutter` transitively pulls in an
// instance-based `IsolateNameServer` that shadows `dart:ui`'s static
// one. Without the `as ui` qualifier the static lookup below fails to
// resolve to the platform name server.
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/alarm_settings.dart';
import '../data/models/shift.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/hive_shift_repository.dart';
import 'local_notifications_alarm_scheduler.dart';
import 'notification_action_dispatcher.dart';

/// Background isolate notification action handler.
///
/// Runs in a SEPARATE Dart VM from the main app — its heap, its Hive
/// instance, and its timezone database are all distinct from those of the
/// main isolate. Everything in this file is deliberately top-level:
///   - `onDidReceiveBackgroundNotificationResponse` requires a top-level /
///     static target so AOT can resolve it via `@pragma('vm:entry-point')`.
///   - No classes, no UI routing, no Provider — the background isolate has
///     none of those available.

// Module-level guard so the OS reusing the isolate across rapid action taps
// (which happens within a single callback-dispatcher lifetime) does not
// trigger "adapter already registered" or duplicate-channel-init failures.
// Reset implicitly on isolate teardown.
bool _isolateInitDone = false;

/// Top-level entry point wired into [LocalNotificationsAlarmScheduler.init]
/// as `onDidReceiveBackgroundNotificationResponse`. The OS invokes this when
/// the user taps a notification action while the app is killed or in the
/// background.
///
/// Routing strategy:
///   - Fast path (main isolate alive): forward the action to the
///     main-isolate dispatcher via `IsolateNameServer` and return
///     immediately. This avoids two failure modes:
///       1. Hive cache staleness — a bg-isolate write to disk does
///          NOT invalidate the main isolate's in-memory Box cache or
///          fire its `box.watch()` events. WakeUpScreen's reactive
///          subscription would never see `isAcknowledged` flip true.
///          (THIS is the regression we are fixing.)
///       2. Concurrent writes from two isolates against the same box
///          file — risk of file-lock contention.
///   - Slow path (main isolate dead): spin up Hive in this isolate
///     and do the write ourselves. The main isolate reconciles
///     against the on-disk state on its next start.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(
  NotificationResponse response,
) async {
  final payload = response.payload;
  // Body tap (no actionId) and payload-less responses are not the bg
  // isolate's concern. Cold-launch body-tap routing lives in main.dart
  // and the foreground dispatcher handles warm body taps.
  if (payload == null) {
    debugPrint('[bg-isolate] null payload — ignoring');
    return;
  }

  final actionId = response.actionId;
  debugPrint('[bg-isolate] actionId=$actionId payload=$payload');

  // Only the two known action buttons reach the bg-isolate switch
  // below in any meaningful way; bail early on anything else so the
  // port-routing decision is cleaner.
  if (actionId != actionIdSnooze && actionId != actionIdDismiss) {
    debugPrint('[bg-isolate] non-action response, ignoring');
    return;
  }

  // FAST PATH: hand off to the main isolate if it is alive.
  final mainPort = ui.IsolateNameServer.lookupPortByName(alarmActionPortName);
  if (mainPort != null) {
    debugPrint('[bg-isolate] main isolate present — routing $actionId via port');
    mainPort.send(<String, String>{
      'actionId': actionId!,
      'payload': payload,
    });
    return;
  }

  // SLOW PATH: app is dead. Initialise Hive in this isolate and write
  // the shift state ourselves.
  debugPrint('[bg-isolate] main isolate absent — handling locally');
  switch (actionId) {
    case actionIdSnooze:
      await _handleSnooze(payload);
      break;
    case actionIdDismiss:
      await _handleDismiss(payload);
      break;
  }
}

/// One-time init for the background isolate.
///
/// A background isolate is a fresh Dart VM: boxes opened on the main
/// isolate are NOT visible here, the tz database has not been loaded, and
/// the Flutter binding may not yet be initialized. This mirrors the boot
/// sequence of [main.dart] but trimmed to only what the dismiss/snooze
/// handlers need:
///   - `WidgetsFlutterBinding.ensureInitialized()` so platform channels
///     used by `path_provider` (inside `Hive.initFlutter`) and
///     `flutter_timezone` are live.
///   - `Hive.initFlutter()` to resolve the app docs dir and prepare the
///     Hive backend for this isolate. The on-disk box files are the same
///     ones the main isolate writes to, just opened here in this VM.
///   - Per-adapter `isAdapterRegistered` guards so the second invocation
///     within a single dispatcher lifetime is a no-op.
///   - Timezone setup so `tz.TZDateTime.from(snoozedUntil, tz.local)` in
///     the snooze reschedule produces a DST-correct absolute instant.
Future<void> _ensureBackgroundIsolateInit() async {
  if (_isolateInitDone) return;

  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // typeIds match local_storage.dart so the same on-disk records read back
  // identically across isolates. typeId 2 is intentionally skipped — Hive
  // CE ships a built-in DurationAdapter at typeId 20 used by AlarmSettings.
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ShiftTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ShiftAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(AlarmSettingsAdapter());
  }

  // Untyped key-value box for app preferences. Opened here so the
  // slow-path snooze handler (and the buildAlarmNotificationDetails call
  // it makes when rescheduling) can read `snooze_duration` synchronously
  // via `Hive.box('settings').get(...)`. The main isolate opens the same
  // on-disk box in `main()` — these two opens hit the same file but live
  // in distinct in-memory caches per VM.
  await Hive.openBox('settings');

  tz_data.initializeTimeZones();
  final tzInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

  _isolateInitDone = true;
}

/// Parses the payload string emitted by AlarmEngine. Format:
/// `<shiftId>|<notificationId>` — see [alarm_engine.dart:145](../alarms/alarm_engine.dart).
/// Returns `null` if the payload is malformed; callers treat that as a
/// no-op rather than throwing, because a thrown exception in a background
/// isolate is a silent failure with no user-visible feedback.
({String shiftId, int notificationId})? _parsePayload(String payload) {
  final parts = payload.split('|');
  if (parts.length != 2) {
    debugPrint('[bg-isolate] malformed payload "$payload" (expected "id|int")');
    return null;
  }
  final notificationId = int.tryParse(parts[1]);
  if (notificationId == null) {
    debugPrint('[bg-isolate] non-int notificationId in "$payload"');
    return null;
  }
  return (shiftId: parts[0], notificationId: notificationId);
}

/// Marks the shift acknowledged in Hive and defensively cancels the OS
/// notification. AlarmEngine will see `isAcknowledged == true` on its next
/// reconcile (typically when the user re-opens the app) and will NOT
/// re-schedule this occurrence.
Future<void> _handleDismiss(String payload) async {
  final parsed = _parsePayload(payload);
  if (parsed == null) return;

  await _ensureBackgroundIsolateInit();
  final shiftBox = await Hive.openBox<Shift>(HiveShiftRepository.boxName);

  final shift = shiftBox.get(parsed.shiftId);
  if (shift == null) {
    debugPrint(
      '[bg-isolate] dismiss: shift ${parsed.shiftId} not found — '
      'cancelling notification anyway',
    );
  } else {
    // Also clear any pending snooze on this occurrence — the user has
    // chosen to handle the alarm fully, not push it forward.
    await shiftBox.put(
      shift.id,
      shift.copyWith(isAcknowledged: true, clearSnoozedUntil: true),
    );
    debugPrint('[bg-isolate] dismiss: marked ${shift.id} acknowledged');
  }

  // `cancelNotification: true` on the action button means the OS has likely
  // already dismissed the heads-up by the time we get here, but a second
  // cancel is cheap and idempotent. It covers edge cases like the user
  // expanding the notification before tapping.
  await FlutterLocalNotificationsPlugin().cancel(id: parsed.notificationId);
}

/// Writes `snoozedUntil = now + snooze_duration` to Hive and reschedules the same
/// notification id for that instant via [zonedSchedule] with
/// [AndroidScheduleMode.alarmClock]. Reuses the top-level
/// [buildAlarmNotificationDetails] so the snoozed notification is
/// byte-identical to the original — same channel, FullScreenIntent, action
/// buttons, iOS category. AlarmEngine's next reconcile will see
/// `snoozedUntil` and converge to the same scheduled time idempotently.
Future<void> _handleSnooze(String payload) async {
  final parsed = _parsePayload(payload);
  if (parsed == null) return;

  await _ensureBackgroundIsolateInit();
  final shiftBox = await Hive.openBox<Shift>(HiveShiftRepository.boxName);
  final shift = shiftBox.get(parsed.shiftId);

  if (shift == null) {
    debugPrint(
      '[bg-isolate] snooze: shift ${parsed.shiftId} not found — '
      'cancelling notification, no reschedule',
    );
    await FlutterLocalNotificationsPlugin().cancel(id: parsed.notificationId);
    return;
  }

  // Snooze duration is user-configurable via SettingsScreen; the bg
  // isolate reads from its own opened copy of the same on-disk box. The
  // default mirrors the historical hard-coded 9-minute snooze.
  final int snoozeMins =
      Hive.box('settings').get('snooze_duration', defaultValue: 1) as int;
  final snoozedUntil = DateTime.now().add(Duration(minutes: snoozeMins));
  await shiftBox.put(shift.id, shift.copyWith(snoozedUntil: snoozedUntil));
  debugPrint('[bg-isolate] snooze: ${shift.id} snoozedUntil=$snoozedUntil');

  // Reuse the same notification id so any subsequent reconcile from the
  // main isolate replaces idempotently. We still issue an explicit cancel
  // first as belt-and-braces — some OEM Android builds have quirks with
  // pure replace-by-id behaviour on alarmClock-mode notifications.
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.cancel(id: parsed.notificationId);

  await plugin.zonedSchedule(
    id: parsed.notificationId,
    title: _titleFor(shift),
    body: _bodyFor(shift),
    scheduledDate: tz.TZDateTime.from(snoozedUntil, tz.local),
    notificationDetails: buildAlarmNotificationDetails(),
    androidScheduleMode: AndroidScheduleMode.alarmClock,
    // Preserve the original `shiftId|notificationId` so a subsequent
    // Snooze / Dismiss / body-tap on the rescheduled alarm carries the
    // same identity. AlarmEngine reconstructs the same payload anyway,
    // but passing it explicitly keeps the snoozed firing self-contained
    // until the next reconcile.
    payload: payload,
  );
}

// Mirrors `AlarmEngine._titleFor` / `_bodyFor`. The duplication is
// intentional: AlarmEngine's helpers are private to that class, and the
// background isolate must be self-contained (no Provider, no shared
// services). On the next main-isolate reconcile AlarmEngine will replace
// this scheduled entry via its own helpers, so any drift between the two
// implementations self-heals within a normal app-open cycle. Keep these
// two pairs in sync.
String _titleFor(Shift s) {
  switch (s.type) {
    case ShiftType.day:
      return 'Day shift coming up';
    case ShiftType.night:
      return 'Night shift coming up';
    case ShiftType.afternoon:
      return 'Afternoon shift coming up';
    case ShiftType.off:
      // Unreachable in practice — OFF shifts are filtered by AlarmEngine
      // before they ever produce a notification. Benign fallback.
      return 'Shift coming up';
  }
}

String _bodyFor(Shift s) {
  final hh = (s.startMinutes ~/ 60).toString().padLeft(2, '0');
  final mm = (s.startMinutes % 60).toString().padLeft(2, '0');
  return 'Starts at $hh:$mm';
}
