import '../data/models/shift_type.dart';
import '../logic/sleep_plan.dart';
import 'reminder_id.dart';

/// Pure, plugin-free logic for the Sleep tab's gentle nudges: which reminders a
/// given [SleepPlan] should arm, when, and with what copy. Kept apart from
/// [SleepReminderService] (which does the OS scheduling) so the decision layer
/// is unit-testable with a synthetic plan and a fixed `now`.
///
/// Sleep nudges ride the SAME isolated `rostrik/activity_reminders` path as the
/// optional activity reminders — a plain, dismissible notification that respects
/// Do-Not-Disturb — so they can never touch the shift-alarm reliability chain.

/// Stable notification/AlarmManager id for the bedtime nudge. A fixed sentinel
/// string (not a UUID) so it always resolves to the same id and a re-schedule
/// REPLACES the prior alarm; it can never collide with an activity reminder
/// (those hash real UUIDs) or the trial-ending nudge (its own sentinel).
final int kSleepBedtimeReminderId =
    reminderNotificationId('__rostrik_sleep_bedtime__');

/// Stable id for the earlier wind-down nudge.
final int kSleepWindDownReminderId =
    reminderNotificationId('__rostrik_sleep_winddown__');

/// A single desired sleep reminder — the args [SleepReminderService] hands to the
/// scheduler. Value-equal so a reconcile can dedupe against what's already armed.
class SleepReminder {
  const SleepReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepReminder &&
          id == other.id &&
          at == other.at &&
          title == other.title &&
          body == other.body;

  @override
  int get hashCode => Object.hash(id, at, title, body);

  @override
  String toString() => 'SleepReminder(id: $id, at: $at, title: $title)';
}

/// The reminders that should be armed for [plan] at [now].
///
/// Only an [SleepPlanState.activeTarget] plan carries concrete bedtime /
/// wind-down times, so the advisory states (none / restRecovery / nightTransition)
/// produce nothing. Each nudge is included only when its toggle is on AND its
/// fire time is still in the future (a bedtime that already passed tonight is not
/// re-armed). Wind-down comes first (it's earlier), then bedtime.
List<SleepReminder> desiredSleepReminders({
  required SleepPlan plan,
  required DateTime now,
  required bool bedtimeEnabled,
  required bool windDownEnabled,
  required bool use24Hour,
}) {
  if (plan.state != SleepPlanState.activeTarget) return const <SleepReminder>[];

  final out = <SleepReminder>[];
  final bedtime = plan.targetBedtime;
  final windDown = plan.windDownTime;
  final wake = plan.wakeTime;
  final shiftLabel = _shiftLabel(plan.nextShift?.type);

  if (windDownEnabled && windDown != null && windDown.isAfter(now)) {
    out.add(SleepReminder(
      id: kSleepWindDownReminderId,
      at: windDown,
      title: 'Time to wind down 🌙',
      body: bedtime != null
          ? 'Ease off the screens — target bedtime is '
              '${_clock(bedtime, use24Hour)}.'
          : 'Ease off the screens and start winding down for the night.',
    ));
  }

  if (bedtimeEnabled && bedtime != null && bedtime.isAfter(now)) {
    out.add(SleepReminder(
      id: kSleepBedtimeReminderId,
      at: bedtime,
      title: 'Bedtime 😴',
      body: wake != null
          ? 'Head to bed for ~${plan.sleepGoalHours}h before your $shiftLabel — '
              'wake-up at ${_clock(wake, use24Hour)}.'
          : 'Head to bed to hit your ${plan.sleepGoalHours}h sleep goal.',
    ));
  }

  return out;
}

String _shiftLabel(ShiftType? type) {
  switch (type) {
    case ShiftType.day:
      return 'day shift';
    case ShiftType.afternoon:
      return 'afternoon shift';
    case ShiftType.night:
      return 'night shift';
    case ShiftType.off:
    case null:
      return 'shift';
  }
}

/// Self-contained clock formatter (no `intl`, no UI import) — this reminder path
/// runs off the UI thread and only needs the user's 12/24h choice.
String _clock(DateTime t, bool use24Hour) {
  final minute = t.minute.toString().padLeft(2, '0');
  if (use24Hour) {
    return '${t.hour.toString().padLeft(2, '0')}:$minute';
  }
  final isPm = t.hour >= 12;
  var hour12 = t.hour % 12;
  if (hour12 == 0) hour12 = 12;
  return '$hour12:$minute ${isPm ? 'PM' : 'AM'}';
}
