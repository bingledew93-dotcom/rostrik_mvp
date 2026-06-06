import 'dart:math' as math;

import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../data/models/shift_type.dart';

/// Which presentation the Sleep hero card should adopt for the current roster
/// context.
enum SleepPlanState {
  /// No upcoming working shift to plan around — the tab degrades to a calm
  /// empty state.
  none,

  /// The next working shift is a Night shift that does NOT start today, i.e.
  /// the user has tonight free before transitioning onto nights. Advisory:
  /// "consider sleeping in" rather than a strict bedtime.
  nightTransition,

  /// A normal upcoming wake target — show the calculated bedtime / wake /
  /// duration plan.
  activeTarget,
}

/// Pure, roster-derived sleep plan. Computed off the same `Shift` + `AppAlarm`
/// state the rest of the app reads, with no Flutter / Provider / Hive
/// dependency so it can be unit-tested with a synthetic roster and a fixed
/// `now`.
///
/// The bedtime math deliberately mirrors the engine's fire-time arithmetic
/// (`shiftStart − lead`, then `wake − sleepGoal − windDown`) using
/// calendar-field construction rather than `Duration` subtraction, so it stays
/// DST-safe exactly like `AlarmSyncService` / `nextUpcomingAutomatedAlarm`.
class SleepPlan {
  const SleepPlan({
    required this.state,
    required this.sleepGoalHours,
    required this.windDownMinutes,
    this.nextShift,
    this.wakeTime,
    this.targetBedtime,
    this.windDownTime,
  });

  final SleepPlanState state;
  final int sleepGoalHours;
  final int windDownMinutes;

  /// The shift the plan is built around. Null only when [state] is
  /// [SleepPlanState.none].
  final Shift? nextShift;

  /// When the user is expected to wake — the earliest alarm fire time for
  /// [nextShift] (`shiftStart − lead`), or `shiftStart − globalLead` when no
  /// alarm rule targets that shift type.
  final DateTime? wakeTime;

  /// [wakeTime] − [sleepGoalHours].
  final DateTime? targetBedtime;

  /// [targetBedtime] − [windDownMinutes].
  final DateTime? windDownTime;

  /// True when the plan carries concrete times (both shift states), false for
  /// the empty [SleepPlanState.none].
  bool get hasTimes => wakeTime != null;
}

/// Builds the [SleepPlan] for [now] from the live roster.
///
/// - Picks the earliest non-OFF, non-suppressed shift whose start is still in
///   the future (the next wake target).
/// - Derives the wake instant from the matching follows-rotation alarm's lead
///   (the largest lead wins — that's the first alarm to ring), falling back to
///   [globalLeadMinutes] when no rule targets the type.
/// - Flags a [SleepPlanState.nightTransition] when that next shift is a Night
///   shift not starting today (a rest day sits before it).
SleepPlan computeSleepPlan({
  required List<Shift> shifts,
  required List<AppAlarm> alarms,
  required int globalLeadMinutes,
  required int sleepGoalHours,
  required int windDownMinutes,
  required DateTime now,
  bool isSchedulePaused = false,
}) {
  // Holiday Mode: no alarms fire, so there's no wake target to plan around —
  // the tab degrades to the same calm empty state as "no upcoming shift".
  final next = isSchedulePaused ? null : _nextWakeShift(shifts, now);
  if (next == null) {
    return SleepPlan(
      state: SleepPlanState.none,
      sleepGoalHours: sleepGoalHours,
      windDownMinutes: windDownMinutes,
    );
  }

  final lead = _earliestLeadMinutes(next.type, alarms, globalLeadMinutes);
  // Calendar-field math (NOT Duration subtraction) so a lead / sleep-goal that
  // crosses a DST boundary still lands on the right local wall-clock time —
  // same contract as the alarm engine.
  final wake = DateTime(
    next.date.year,
    next.date.month,
    next.date.day,
    next.startMinutes ~/ 60,
    next.startMinutes % 60 - lead,
  );
  final bedtime = DateTime(
    wake.year,
    wake.month,
    wake.day,
    wake.hour - sleepGoalHours,
    wake.minute,
  );
  final windDown = DateTime(
    bedtime.year,
    bedtime.month,
    bedtime.day,
    bedtime.hour,
    bedtime.minute - windDownMinutes,
  );

  final today = DateTime(now.year, now.month, now.day);
  final startDay = DateTime(next.date.year, next.date.month, next.date.day);
  final isNightTransition =
      next.type == ShiftType.night && startDay.isAfter(today);

  return SleepPlan(
    state: isNightTransition
        ? SleepPlanState.nightTransition
        : SleepPlanState.activeTarget,
    sleepGoalHours: sleepGoalHours,
    windDownMinutes: windDownMinutes,
    nextShift: next,
    wakeTime: wake,
    targetBedtime: bedtime,
    windDownTime: windDown,
  );
}

/// Earliest non-OFF, non-suppressed shift whose START is still in the future.
/// Unlike the Dashboard's "next shift" (which keeps an in-progress shift), the
/// sleep planner only cares about a shift the user still has to WAKE for, so an
/// already-started shift is skipped.
Shift? _nextWakeShift(List<Shift> shifts, DateTime now) {
  Shift? best;
  DateTime? bestStart;
  for (final s in shifts) {
    if (s.type == ShiftType.off) continue;
    if (s.isMuted) continue;
    if (s.isAcknowledged) continue;
    final start = s.startDateTime;
    if (!start.isAfter(now)) continue;
    if (bestStart == null || start.isBefore(bestStart)) {
      best = s;
      bestStart = start;
    }
  }
  return best;
}

/// The largest lead (earliest fire) among enabled follows-rotation alarms that
/// target [type] — that first ring is when the user actually wakes. Falls back
/// to [globalLeadMinutes] when no rule targets the type.
int _earliestLeadMinutes(
  ShiftType type,
  List<AppAlarm> alarms,
  int globalLeadMinutes,
) {
  int? maxLead;
  for (final a in alarms) {
    if (!a.enabled) continue;
    if (a.repeatType != AppAlarmRepeatType.followsRotation) continue;
    if (a.linkedShiftType != type) continue;
    final lead = a.relativeOffsetMinutes ?? globalLeadMinutes;
    maxLead = maxLead == null ? lead : math.max(maxLead, lead);
  }
  return maxLead ?? globalLeadMinutes;
}
