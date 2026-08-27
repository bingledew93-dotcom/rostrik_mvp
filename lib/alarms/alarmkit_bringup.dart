import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'alarm_scheduler.dart';

/// One-shot AlarmKit bring-up diagnostics — Phase B scaffolding, not product.
///
/// ## Why this runs itself instead of sitting behind a button
///
/// Installing to the device revokes developer trust every time, so each test
/// cycle costs a manual Settings → Trust round-trip. Batching matters. This
/// answers all three open questions in a single launch:
///
///   1. **Is AlarmKit actually reachable?** Compiled in, available at runtime,
///      already authorised.
///   2. **Does `NSAlarmKitUsageDescription` satisfy TCC?** If the key were
///      wrong, requesting authorisation would terminate the app rather than
///      prompt — a crash here is the answer, not a mystery.
///   3. **What is the alarm ceiling?** `AlarmManager` throws
///      `maximumLimitReached` at some undocumented count, and that number
///      decides the architecture: Rostrik arms a 14-day horizon of individually
///      scheduled alarms, and if AlarmKit will not hold that many it cannot
///      carry the horizon alone.
///
/// Results are logged natively. That is deliberate — on the profile builds that
/// are the only ones able to launch standalone on the device, Dart's `print`
/// and `debugPrint` do not reach the device console at all, so the answers have
/// to come out through `NSLog`.
///
/// ## Safety
///
/// Never runs in a release build, never off iOS, and changes no app state: the
/// probe arms its alarms a decade into the future and cancels every one it
/// created, so nothing it schedules can ring. It is also entirely separate from
/// the alarm path users depend on — `alarmKitEnabled` is still false, so the
/// notification backend keeps serving real alarms throughout.
Future<void> runAlarmKitBringUp({
  MethodChannel channel = const MethodChannel('rostrik/native_alarms'),
}) async {
  if (kReleaseMode || !Platform.isIOS) return;

  try {
    final status = await channel.invokeMapMethod<String, dynamic>('alarmKitStatus');
    if (status == null) return;

    // `available` is false on anything below iOS 26 — the fallback path, which
    // is most devices for now. Nothing further to ask there.
    if (status['available'] != true) return;

    if (status['authorized'] != true) {
      final granted = await channel.invokeMethod<bool>('alarmKitAuthorize');
      if (granted != true) return; // denied — the probe would only throw
    }

    // The two probes this used to run at every launch are ANSWERED, measured on
    // an iPhone SE 3 / iOS 26.6.1 on 2026-08-27:
    //
    //   * `alarmKitProbeLimit` — 400 armed, none refused, all 400 confirmed live
    //     before cleanup. The cap is ≥400, so `ios_notification_budget.dart`'s
    //     arithmetic does not constrain this path at all.
    //   * `alarmKitProbeReplace` — AlarmKit REFUSES to schedule over an id it
    //     already holds; cancel-then-schedule works. `AlarmKitBackend.schedule`
    //     cancels pre-emptively because of this.
    //
    // They are left callable on the channel but no longer run automatically:
    // arming 400 alarms on every launch is pure noise now, and noise is exactly
    // where a real failure would hide during an end-to-end test.
  } on MissingPluginException {
    // The channel is not registered on this engine — the background isolate,
    // for instance. Diagnostics are never worth failing a launch over.
  } on PlatformException {
    // Same reasoning: a refused probe is a result, not a crash.
  }
}

/// Reports whether this device can run AlarmKit, and whether it currently is.
///
/// Keys: `compiled`, `available` (iOS 26+), `authorized`, `enabled`.
Future<Map<String, dynamic>> readAlarmKitStatus({
  MethodChannel channel = const MethodChannel('rostrik/native_alarms'),
}) async {
  if (!Platform.isIOS) return const {};
  try {
    return await channel.invokeMapMethod<String, dynamic>('alarmKitStatus') ??
        const {};
  } on MissingPluginException {
    return const {};
  } on PlatformException {
    return const {};
  }
}

/// Switches which backend serves real alarms, then re-arms everything on it.
///
/// ## Why the cancel first is not optional
///
/// Alarms armed on one backend are invisible to the other: AlarmKit keys by
/// UUID and `UNUserNotificationCenter` by identifier string, and neither can
/// see or cancel the other's work. Flipping without sweeping first would strand
/// every armed alarm — still live, still able to ring, with nothing left that
/// can cancel it, for an app that no longer believes it uses that backend.
/// [AlarmScheduler.cancelAll] runs against the OLD backend and clears the
/// ledger, so the reconcile that follows re-arms from scratch on the new one.
///
/// Native answers by nudging Dart's existing drain-and-reconcile, so the caller
/// does not need the sync service — the alarms come back on their own.
Future<bool> setAlarmKitBackendEnabled(
  bool enabled, {
  required AlarmScheduler scheduler,
  MethodChannel channel = const MethodChannel('rostrik/native_alarms'),
}) async {
  if (kReleaseMode || !Platform.isIOS) return false;
  try {
    await scheduler.cancelAll();
    return await channel.invokeMethod<bool>(
          'alarmKitSetEnabled',
          {'enabled': enabled},
        ) ??
        false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

/// Arms one real AlarmKit alarm [seconds] from now and returns whether it took.
///
/// Answers the question the limit probe structurally cannot: **does an AlarmKit
/// alert present without a widget extension?** Its UI is a Live Activity, and we
/// have not built the widget target that renders one, so the alert may appear
/// fully, appear degraded, or not at all — and only a real firing distinguishes
/// those. It also shows whether the bundled tone rings past the ~30 seconds that
/// caps the notification path, which is the entire reason AlarmKit is worth the
/// work.
///
/// Deliberately manual rather than part of [runAlarmKitBringUp]: an alarm that
/// went off every time the app launched would be its own kind of bug.
Future<bool> fireAlarmKitTestAlarm({
  int seconds = 60,
  MethodChannel channel = const MethodChannel('rostrik/native_alarms'),
}) async {
  if (kReleaseMode || !Platform.isIOS) return false;
  try {
    return await channel.invokeMethod<bool>(
          'alarmKitTestAlarm',
          {'seconds': seconds},
        ) ??
        false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}
