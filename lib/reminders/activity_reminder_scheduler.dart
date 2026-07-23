import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// OS-level scheduling contract for **activity reminders** — the optional,
/// lightweight nudges a [CalendarActivity] (event / task / birthday) can carry.
///
/// This is deliberately a SEPARATE surface from `AlarmScheduler`, wired to its
/// own MethodChannel (`rostrik/activity_reminders`) and its own native receiver
/// + notification channel. Nothing here touches `setAlarmClock`, the full-screen
/// wake activity, the foreground audio service, the boot re-arm store, or the
/// exact-alarm reliability ledger. A reminder is a plain notification; if the OS
/// delays it a few minutes in deep Doze that is acceptable, because — unlike a
/// shift alarm — a birthday nudge is not safety-critical. Keeping the two paths
/// physically apart is the whole point: a bug in reminders can never degrade the
/// shift-alarm guarantees, and vice-versa.
///
/// Tests inject [FakeActivityReminderScheduler]; production uses
/// [NativeActivityReminderScheduler].
abstract class ActivityReminderScheduler {
  /// Schedules (or replaces, keyed by [id]) a single reminder notification to
  /// post at [at]. [title] is the notification title, [body] the content line.
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  });

  /// Cancels the reminder with [id]. Idempotent — a no-op if nothing is armed.
  Future<void> cancel(int id);
}

/// Production [ActivityReminderScheduler] backed by the native
/// `rostrik/activity_reminders` MethodChannel (see `ReminderReceiver.kt` /
/// `ActivityReminderScheduling.kt`).
///
/// Unlike `NativeAlarmScheduler` this keeps NO persisted ledger: the reminder
/// set is small, fully derivable from the activity box, and re-reconciled from
/// Hive on every launch and on every activity change (see
/// `ActivityReminderService`). The native side arms an `AlarmManager`
/// *AllowWhileIdle* alarm (never `setAlarmClock`), so there is no OS enumeration
/// need — replace-by-id is enough.
class NativeActivityReminderScheduler implements ActivityReminderScheduler {
  NativeActivityReminderScheduler({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  /// Wire name — MUST match `ActivityReminderScheduling.CHANNEL` (Kotlin).
  static const String channelName = 'rostrik/activity_reminders';

  static const String _methodSchedule = 'scheduleReminder';
  static const String _methodCancel = 'cancelReminder';

  static const String _argId = 'id';
  static const String _argTriggerAtMillis = 'triggerAtMillis';
  static const String _argTitle = 'title';
  static const String _argBody = 'body';

  final MethodChannel _channel;

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    try {
      await _channel.invokeMethod<void>(_methodSchedule, <String, dynamic>{
        _argId: id,
        _argTriggerAtMillis: at.millisecondsSinceEpoch,
        _argTitle: title,
        _argBody: body,
      });
    } on PlatformException catch (e) {
      // A reminder is best-effort by design — never let a scheduling refusal
      // (e.g. an OEM quirk) escape and disrupt the app. It re-arms on the next
      // reconcile.
      debugPrint('[ActivityReminder] schedule refused id=$id: ${e.code}');
    } on MissingPluginException {
      // No handler (iOS / tests) — silently ignore; reminders are Android-only.
    }
  }

  @override
  Future<void> cancel(int id) async {
    try {
      await _channel.invokeMethod<void>(_methodCancel, <String, dynamic>{
        _argId: id,
      });
    } on PlatformException catch (e) {
      debugPrint('[ActivityReminder] cancel failed id=$id: ${e.code}');
    } on MissingPluginException {
      // No handler (iOS / tests) — nothing to cancel.
    }
  }
}
