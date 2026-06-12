// Namespaced because `hive_ce_flutter` transitively pulls in an
// instance-based `IsolateNameServer` that shadows `dart:ui`'s static
// one. Without the `as ui` qualifier the static lookup below fails to
// resolve to the platform name server.
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/alarm_settings.dart';
import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/hive_app_alarm_repository.dart';
import '../data/repositories/hive_shift_repository.dart';
import 'alarm_payload.dart';
import 'local_notifications_alarm_scheduler.dart';
import 'notification_action_dispatcher.dart';
import 'pending_dismissal_guard.dart';

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

// Separate guard for the timezone bootstrap — see [_ensureTimezoneInit].
bool _timezoneInitDone = false;

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

  // NATIVE-STORE FAIL-SAFE — the FIRST real work this isolate does for a
  // Dismiss, before the port lookup and long before the Hive boot chain.
  // Pixel-9-class battery management reaps this headless engine fast enough
  // to lose the slow-path Hive write; one path_provider hop plus a
  // synchronous, flushed file write puts the dismissal in the kernel within
  // milliseconds of Dart starting. Boot-time replay in main() turns it into
  // the real `isAcknowledged` Hive state even if everything after this line
  // never runs. Written on the fast path too — it also covers the race where
  // the main isolate dies between the port send and ITS Hive write.
  if (actionId == actionIdDismiss) {
    await _markDismissalInNativeStore(payload);
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

/// Writes the dismissed shift's id to the native fail-safe ledger (see
/// `pending_dismissal_guard.dart`) — deliberately the cheapest possible
/// sequence: binding (idempotent, ms), ONE path_provider hop to resolve
/// `filesDir`, then a synchronous flushed file write. No Hive, no timezone,
/// no plugin beyond path_provider. Failures are swallowed: this is the
/// parachute, and the primary Hive slow path still runs right after — a
/// marker failure must never abort the real write attempt.
Future<void> _markDismissalInNativeStore(String payload) async {
  try {
    final parsed = AlarmPayload.decode(payload);
    if (parsed == null) return;
    WidgetsFlutterBinding.ensureInitialized();
    final dir = await getApplicationSupportDirectory();
    markPendingDismissal(dir, parsed.shiftId);
    debugPrint(
      '[bg-isolate] dismissal marker written to native store for '
      '${parsed.shiftId}',
    );
  } catch (e) {
    debugPrint('[bg-isolate] pending-dismissal marker failed: $e');
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
  // Needed for the auto-delete path: dismissing a fired one-time alarm marked
  // auto-delete removes its record from the `alarms` box. typeIds match
  // local_storage.dart so the on-disk records read back identically.
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(AppAlarmRepeatTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(AppAlarmAdapter());
  }

  // Untyped key-value box for app preferences. Opened here so the
  // slow-path snooze handler (and the buildAlarmNotificationDetails call
  // it makes when rescheduling) can read `snooze_duration` synchronously
  // via `Hive.box('settings').get(...)`. The main isolate opens the same
  // on-disk box in `main()` — these two opens hit the same file but live
  // in distinct in-memory caches per VM.
  await Hive.openBox('settings');

  _isolateInitDone = true;
}

/// Timezone bootstrap, deliberately SEPARATE from [_ensureBackgroundIsolateInit]
/// and called only by the snooze path (the lone consumer — `zonedSchedule`
/// needs `tz.local`). Dismiss must never depend on it: the
/// `flutter_timezone` platform-channel hop is the flakiest step in a headless
/// engine, and when it threw BEFORE the dismiss write the write was lost —
/// the "Zombie UI" bug where the database still thought the alarm was ringing.
Future<void> _ensureTimezoneInit() async {
  if (_timezoneInitDone) return;
  tz_data.initializeTimeZones();
  final tzInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
  _timezoneInitDone = true;
}

/// Marks the shift acknowledged in Hive and defensively cancels the OS
/// notification. AlarmEngine will see `isAcknowledged == true` on its next
/// reconcile (typically when the user re-opens the app) and will NOT
/// re-schedule this occurrence.
Future<void> _handleDismiss(String payload) async {
  final parsed = AlarmPayload.decode(payload);
  if (parsed == null) return;

  await _ensureBackgroundIsolateInit();
  await performBackgroundDismissWrite(parsed);

  // `cancelNotification: true` on the action button means the OS has likely
  // already dismissed the heads-up by the time we get here, but a second
  // cancel is cheap and idempotent. It covers edge cases like the user
  // expanding the notification before tapping.
  await FlutterLocalNotificationsPlugin().cancel(id: parsed.notificationId);
}

/// The Hive side of the killed-app Dismiss, isolated from every platform
/// channel so it is unit-testable against a real on-disk Hive and CANNOT be
/// pre-empted by a flaky channel hop (the Zombie-UI regression): opens the
/// shifts box, marks the occurrence `isAcknowledged` (clearing any pending
/// snooze), flushes, and — in a `finally` — CLOSES the box. The close is
/// load-bearing twice over:
///   * durability — the acknowledged flag is guaranteed on disk even if the
///     OS reaps this isolate the instant the handler returns;
///   * no isolate contention — the file handle/lock is released, so a main
///     isolate cold-booting moments later opens the same box cleanly instead
///     of racing a still-open background handle.
/// The main isolate is dead on this path (the fast path forwards to it when
/// alive), so closing can never disturb a live UI.
Future<void> performBackgroundDismissWrite(AlarmPayload parsed) async {
  final shiftBox = await Hive.openBox<Shift>(HiveShiftRepository.boxName);
  try {
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
      await shiftBox.flush();
      debugPrint('[bg-isolate] dismiss: marked ${shift.id} acknowledged');
    }
  } finally {
    await shiftBox.close();
  }

  // Auto-delete a fired one-time alarm marked auto-delete, at the dismissal
  // instant — even here, in the killed-app path. The main isolate is dead (we
  // took the slow path), so it re-reads the box from disk on next open; the
  // record is simply gone. No-op unless the payload carried a rule id for an
  // auto-delete one-time alarm.
  await _maybeAutoDeleteAlarm(parsed.appAlarmId);
}

/// Killed-app counterpart of the foreground dispatcher's auto-delete: removes a
/// fired one-time alarm marked auto-delete from the `alarms` box directly in
/// this isolate. No-op when the payload had no rule id, the rule is gone, or it
/// isn't an auto-delete one-time alarm. Same flush-and-close contract as the
/// dismiss write — the box never outlives the call.
Future<void> _maybeAutoDeleteAlarm(String appAlarmId) async {
  if (appAlarmId.isEmpty) return;
  final alarmBox = await Hive.openBox<AppAlarm>(HiveAppAlarmRepository.boxName);
  try {
    final alarm = alarmBox.get(appAlarmId);
    if (!shouldAutoDeleteOnDismiss(alarm)) return;
    await alarmBox.delete(appAlarmId);
    await alarmBox.flush();
    debugPrint('[bg-isolate] dismiss: auto-deleted alarm $appAlarmId');
  } finally {
    await alarmBox.close();
  }
}

/// Writes `snoozedUntil = now + snooze_duration` to Hive and reschedules the same
/// notification id for that instant via [zonedSchedule] with
/// [AndroidScheduleMode.alarmClock]. Reuses the top-level
/// [buildAlarmNotificationDetails] so the snoozed notification is
/// byte-identical to the original — same channel, FullScreenIntent, action
/// buttons, iOS category. AlarmEngine's next reconcile will see
/// `snoozedUntil` and converge to the same scheduled time idempotently.
Future<void> _handleSnooze(String payload) async {
  final parsed = AlarmPayload.decode(payload);
  if (parsed == null) return;

  await _ensureBackgroundIsolateInit();

  // Snooze duration is user-configurable via SettingsScreen; the bg
  // isolate reads from its own opened copy of the same on-disk box. The
  // default mirrors the historical hard-coded 9-minute snooze.
  final int snoozeMins =
      Hive.box('settings').get('snooze_duration', defaultValue: 1) as int;
  final snoozedUntil = DateTime.now().add(Duration(minutes: snoozeMins));

  final shift = await performBackgroundSnoozeWrite(parsed, snoozedUntil);
  if (shift == null) {
    debugPrint(
      '[bg-isolate] snooze: shift ${parsed.shiftId} not found — '
      'cancelling notification, no reschedule',
    );
    await FlutterLocalNotificationsPlugin().cancel(id: parsed.notificationId);
    return;
  }

  // Timezone is needed ONLY from here on (the zonedSchedule below) — by
  // design it runs AFTER the Hive write, so a flaky flutter_timezone channel
  // can no longer cost the persisted snooze state.
  await _ensureTimezoneInit();

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
    // SILENT channel for every snooze reschedule — preset AND custom — matching
    // the main scheduler: the foreground-service native player owns all alarm
    // audio when the snoozed alarm fires (WakeUpScreen starts it), so the
    // bundled tone must not ALSO play via FLAG_INSISTENT. The decoded soundKey
    // still rides through (iOS sound + the bundled tone WakeUpScreen plays).
    notificationDetails: buildAlarmNotificationDetails(
      parsed.soundKey,
      useSilentChannel: true,
    ),
    androidScheduleMode: AndroidScheduleMode.alarmClock,
    // Preserve the original `shiftId|notificationId` so a subsequent
    // Snooze / Dismiss / body-tap on the rescheduled alarm carries the
    // same identity. AlarmEngine reconstructs the same payload anyway,
    // but passing it explicitly keeps the snoozed firing self-contained
    // until the next reconcile.
    payload: payload,
  );
}

/// The Hive side of the killed-app Snooze — same isolation, flush, and
/// close-in-`finally` contract as [performBackgroundDismissWrite] (durability
/// + lock release with a dead main isolate). Returns the UPDATED shift so the
/// caller can build the rescheduled notification without re-opening the box,
/// or null when the occurrence no longer exists.
Future<Shift?> performBackgroundSnoozeWrite(
  AlarmPayload parsed,
  DateTime snoozedUntil,
) async {
  final shiftBox = await Hive.openBox<Shift>(HiveShiftRepository.boxName);
  try {
    final shift = shiftBox.get(parsed.shiftId);
    if (shift == null) return null;
    final updated = shift.copyWith(snoozedUntil: snoozedUntil);
    await shiftBox.put(shift.id, updated);
    await shiftBox.flush();
    debugPrint('[bg-isolate] snooze: ${shift.id} snoozedUntil=$snoozedUntil');
    return updated;
  } finally {
    await shiftBox.close();
  }
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
