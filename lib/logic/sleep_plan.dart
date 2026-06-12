import '../alarms/rotation_fire_time.dart';
import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../data/models/shift_type.dart';

/// Which presentation the Sleep hero card should adopt for the current roster
/// context.
enum SleepPlanState {
  /// No upcoming working shift to plan around — the tab degrades to a calm
  /// empty state.
  none,

  /// The next working shift is a Night shift starting *tomorrow*, i.e. the
  /// user has tonight free before transitioning onto nights. Advisory:
  /// "consider sleeping in" rather than a strict bedtime. A Night shift
  /// further out (a future rotation block) is NOT this state — it is a plain
  /// [activeTarget], so the advisory never fires days early.
  nightTransition,

  /// A normal upcoming wake target — show the calculated bedtime / wake /
  /// duration plan.
  activeTarget,

  /// There IS an upcoming working shift, but its start is beyond the planning
  /// horizon ([_planningHorizon], 36h). Calculating a concrete bedtime for a
  /// shift that far out is noise, so the tab degrades to a calm "Rest &
  /// Recovery" state with no target times — the user is free to sleep on their
  /// own clock until the next shift draws near. Distinct from [none], which
  /// means there is no upcoming shift at all.
  restRecovery,
}

/// Pure, roster-derived sleep plan. Computed off the same `Shift` + `AppAlarm`
/// state the rest of the app reads, with no Flutter / Provider / Hive
/// dependency so it can be unit-tested with a synthetic roster and a fixed
/// `now`.
///
/// The wake instant comes from the SAME `rotationAlarmFireAt` helper the
/// engine schedules with — covering both lead-time AND exact-time alarm modes
/// — then `wake − sleepGoal − windDown` uses calendar-field construction
/// rather than `Duration` subtraction, so the whole chain stays DST-safe
/// exactly like `AlarmSyncService` / `nextUpcomingAutomatedAlarm`.
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
  /// [nextShift] computed via `rotationAlarmFireAt` (so an exact-time alarm's
  /// fixed clock is honoured, and a lead-time alarm yields `shiftStart −
  /// lead`), or `shiftStart − globalLead` when no alarm rule targets that
  /// shift type.
  final DateTime? wakeTime;

  /// [wakeTime] − [sleepGoalHours].
  final DateTime? targetBedtime;

  /// [targetBedtime] − [windDownMinutes].
  final DateTime? windDownTime;

  /// True when the plan carries concrete times — only the [activeTarget] and
  /// [nightTransition] states do. False for [none] and [restRecovery].
  bool get hasTimes => wakeTime != null;
}

/// Beyond this lead time a concrete bedtime is noise rather than guidance: the
/// planner stops computing a target and degrades to [SleepPlanState.restRecovery].
/// 36h means "not until at least the day after tomorrow", the point where
/// planning *tonight's* sleep around the next shift stops being meaningful.
const Duration _planningHorizon = Duration(hours: 36);

/// Builds the [SleepPlan] for [now] from the live roster.
///
/// - Picks the earliest non-OFF, non-suppressed shift whose start is still in
///   the future (the next wake target).
/// - Derives the wake instant from the matching follows-rotation alarm's lead
///   (the largest lead wins — that's the first alarm to ring), falling back to
///   [globalLeadMinutes] when no rule targets the type.
/// - Flags a [SleepPlanState.nightTransition] only when the next shift is a
///   Night shift starting tomorrow AND today is a rest day (no work today) — a
///   brutal turnaround (working today, nights tomorrow) is NOT a transition.
/// - Degrades to [SleepPlanState.restRecovery] when the next shift starts beyond
///   the [_planningHorizon]; a Transition Day is exempt (its advisory is the
///   whole point even when nights begin >36h out).
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

  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  final startDay = DateTime(next.date.year, next.date.month, next.date.day);

  // Transition Day requires BOTH: tomorrow is a Night shift AND today is a rest
  // day (no work today). The exact-day bound stops the advisory firing a week
  // early for a Night block further out; the rest-day guard stops it firing on
  // a brutal turnaround (working today, nights tomorrow), where "you have a
  // rest day before nights" would be a dangerous lie. Calendar-field equality
  // (not Duration) keeps both checks DST-safe.
  final isNightTransition = next.type == ShiftType.night &&
      _isSameDay(startDay, tomorrow) &&
      !_isWorkingDay(shifts, today);

  // Planning horizon: a concrete bedtime is only useful when the next wake is
  // imminent. Past 36h, "go to bed at 22:00" for a shift days away is noise, so
  // degrade to Rest & Recovery (no target times). Transition Day is exempt — it
  // carries advisory copy, not a strict bedtime, and is meaningful even when
  // nights begin >36h out.
  final beyondHorizon = next.startDateTime.difference(now) > _planningHorizon;
  if (!isNightTransition && beyondHorizon) {
    return SleepPlan(
      state: SleepPlanState.restRecovery,
      sleepGoalHours: sleepGoalHours,
      windDownMinutes: windDownMinutes,
      nextShift: next,
    );
  }

  // The true wake instant — earliest matching alarm fire time via the shared
  // engine math (exact-time aware). Calendar-field math (NOT Duration
  // subtraction) downstream so a sleep-goal that crosses a DST boundary still
  // lands on the right local wall-clock time — same contract as the engine.
  final wake = _earliestWakeTime(next, alarms, globalLeadMinutes);
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

/// Calendar-day equality (ignores time-of-day). Local DST shifts never move a
/// wall-clock date, so field comparison is the safe primitive here.
bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Whether the roster has any non-OFF shift dated [day]. Suppression flags
/// (muted / acknowledged / alarm-skipped) are ignored: those silence the alarm,
/// but the user is still rostered ON, so the day is not free. Used to disqualify
/// a Transition Day when the user actually works [day].
bool _isWorkingDay(List<Shift> shifts, DateTime day) {
  for (final s in shifts) {
    if (s.type == ShiftType.off) continue;
    if (_isSameDay(s.date, day)) return true;
  }
  return false;
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

/// The earliest fire time among enabled follows-rotation alarms that target
/// [shift]'s type — that first ring is when the user actually wakes. Each
/// candidate comes from `rotationAlarmFireAt`, the SAME helper the engine
/// schedules with, so the plan honours exact-time alarms (fixed wall clock)
/// and lead-time alarms (`shiftStart − lead`) alike and can never advertise a
/// wake the engine didn't arm. Falls back to `shiftStart − globalLead`
/// (DST-safe calendar-field construction) when no rule targets the type.
DateTime _earliestWakeTime(
  Shift shift,
  List<AppAlarm> alarms,
  int globalLeadMinutes,
) {
  DateTime? earliest;
  for (final a in alarms) {
    if (!a.enabled) continue;
    if (a.repeatType != AppAlarmRepeatType.followsRotation) continue;
    if (a.linkedShiftType != shift.type) continue;
    final fireAt = rotationAlarmFireAt(
      alarm: a,
      shift: shift,
      globalLeadMinutes: globalLeadMinutes,
    );
    if (earliest == null || fireAt.isBefore(earliest)) earliest = fireAt;
  }
  return earliest ??
      DateTime(
        shift.date.year,
        shift.date.month,
        shift.date.day,
        shift.startMinutes ~/ 60,
        shift.startMinutes % 60 - globalLeadMinutes,
      );
}
