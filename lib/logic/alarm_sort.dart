import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../data/models/shift_type.dart';
import '../ui/alarm_time_projection.dart' show resolveShiftStartMinutes;

/// Display ordering for the Alarms tab. Pure + free-function-shaped so it can be
/// unit-tested with synthetic alarms/rosters and a fixed `now`.
///
/// The Alarms list has no inherent order — the repo streams records in an
/// unspecified order, so a newly-created alarm used to simply appear last (the
/// field complaint: "new alarms go to the bottom"). Worse, sorting on the raw
/// [AppAlarm.minutesOfDay] didn't fix it, because that field is a placeholder
/// for follows-rotation alarms (they fire relative to the shift, not at an
/// absolute minute) — so every rotation alarm tied on the same key and fell back
/// to insertion order.
///
/// This sorts on the **actual ring clock time** — the same value the card hero
/// shows via [AppAlarm.displayFireClockMinutes] — so the list reads in real
/// chronological order, and a new alarm slots into its natural place. The `id`
/// tiebreak makes the order total and stable (no shuffling on unrelated
/// rebuilds).
///
/// PURE DISPLAY: this only reorders what's shown. It never mutates an alarm and
/// is entirely invisible to `AlarmSyncService` / the OS scheduling set.
///
/// [byShiftType] false (default) → order purely by ring time. true → group by
/// shift type (Day → Afternoon → Night, then weekly/one-time), ring time within
/// each group.

/// Display order rank for grouping by shift type. Rotation alarms rank by their
/// linked type in the natural day progression; everything shift-less
/// (weekly / one-time / an invalid unlinked rotation alarm) sorts after.
int _shiftTypeRank(AppAlarm a) {
  if (a.repeatType != AppAlarmRepeatType.followsRotation) return 99;
  switch (a.linkedShiftType) {
    case ShiftType.day:
      return 0;
    case ShiftType.afternoon:
      return 1;
    case ShiftType.night:
      return 2;
    case ShiftType.off: // alarms never link to OFF, but keep the switch total
      return 3;
    case null:
      return 99;
  }
}

/// The clock time (minute-of-day, 0..1439) this alarm rings — the sort key.
/// Mirrors the Alarms-card headline exactly: rotation alarms resolve their
/// linked shift's start and apply the lead/exact-time math; weekly + one-time
/// alarms ring at their absolute [AppAlarm.minutesOfDay].
int alarmRingClockMinutes(
  AppAlarm a, {
  required List<Shift> shifts,
  required int globalLeadMinutes,
  required DateTime now,
}) {
  if (a.repeatType == AppAlarmRepeatType.oneTime ||
      a.repeatType == AppAlarmRepeatType.weekly) {
    return a.minutesOfDay;
  }
  final type = a.linkedShiftType ?? ShiftType.day;
  final shiftStart = resolveShiftStartMinutes(shifts, type, now: now);
  return a.displayFireClockMinutes(
    shiftStartMinutes: shiftStart,
    globalLeadMinutes: globalLeadMinutes,
  );
}

/// Returns a new list of [alarms] in display order (input list untouched).
List<AppAlarm> sortAlarmsForDisplay(
  List<AppAlarm> alarms, {
  required List<Shift> shifts,
  required int globalLeadMinutes,
  required bool byShiftType,
  required DateTime now,
}) {
  int ring(AppAlarm a) => alarmRingClockMinutes(
        a,
        shifts: shifts,
        globalLeadMinutes: globalLeadMinutes,
        now: now,
      );
  return [...alarms]..sort((a, b) {
      if (byShiftType) {
        final rank = _shiftTypeRank(a).compareTo(_shiftTypeRank(b));
        if (rank != 0) return rank;
        final byTime = ring(a).compareTo(ring(b));
        if (byTime != 0) return byTime;
      } else {
        final byTime = ring(a).compareTo(ring(b));
        if (byTime != 0) return byTime;
        final rank = _shiftTypeRank(a).compareTo(_shiftTypeRank(b));
        if (rank != 0) return rank;
      }
      final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
      if (byLabel != 0) return byLabel;
      // Total, stable final tiebreak so equal-time alarms never shuffle across
      // rebuilds (and a brand-new alarm lands deterministically, not "last").
      return a.id.compareTo(b.id);
    });
}
