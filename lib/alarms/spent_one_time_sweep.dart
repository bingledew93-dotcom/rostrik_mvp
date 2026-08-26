import 'package:flutter/foundation.dart';

import '../data/models/app_alarm.dart';
import '../data/repositories/app_alarm_repository.dart';
import 'one_off_snooze_store.dart';

/// Deletes one-time alarms whose anchored instant ([AppAlarm.oneTimeFireAt])
/// has passed — the alarm has rung and a one-shot fires exactly once.
///
/// ## Why this exists alongside the native ledgers
///
/// Every other retirement path depends on the OS telling us the alarm fired.
/// Android writes a ledger natively at fire time; iOS has no such moment, so it
/// infers it from a notification tap, an explicit dismiss, or a notification
/// still sitting in Notification Center. All three can be defeated by the user
/// simply clearing the notification without opening the app, and the alarm then
/// rings again the next day — a one-time alarm silently becoming a daily one.
///
/// This sweep needs no OS cooperation at all: the anchor is a plain timestamp
/// on the record, so a spent alarm is recognisable offline, from a cold start,
/// days later. It is the backstop that makes the guarantee unconditional rather
/// than best-effort.
///
/// **Legacy records are left alone.** An alarm written before the anchor
/// existed has a null [AppAlarm.oneTimeFireAt] and no reconstructable intended
/// date; deleting one the user may still rely on is worse than letting it roll.
/// They self-correct on the next edit.
///
/// **An active snooze wins.** A snoozed one-time alarm's anchor is in the past
/// by definition (the snooze exists *because* it fired), so retiring on the
/// anchor alone would delete the rule out from under a live snooze and the user
/// would never be woken. The snooze store is the authority for those.
///
/// Returns how many alarms were deleted. Safe to call repeatedly — a second
/// pass finds nothing.
Future<int> sweepSpentOneTimeAlarms(
  AppAlarmRepository alarms, {
  DateTime? now,
  Map<String, DateTime>? oneOffSnoozes,
}) async {
  final clock = now ?? DateTime.now();
  final snoozes = oneOffSnoozes ?? readOneOffSnoozes(now: clock);

  final all = await alarms.getAll();
  var deleted = 0;
  for (final alarm in all) {
    if (alarm.repeatType != AppAlarmRepeatType.oneTime) continue;
    final anchor = alarm.oneTimeFireAt;
    if (anchor == null) continue; // legacy record — see the doc above
    if (anchor.isAfter(clock)) continue; // still ahead of us
    final snooze = snoozes[alarm.id];
    if (snooze != null && snooze.isAfter(clock)) continue; // snooze pending
    await alarms.delete(alarm.id);
    deleted++;
  }
  if (deleted > 0) {
    debugPrint('[spentSweep] retired $deleted spent one-time alarm(s)');
  }
  return deleted;
}
