import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';

/// The single source of truth for **when a follows-rotation alarm fires** for a
/// given shift occurrence. Shared by `AlarmSyncService` (which actually schedules
/// the OS alarm) and `nextUpcomingAutomatedAlarm` (the Dashboard's "Dismiss
/// upcoming alarm" preview) so the two can never disagree about a fire time —
/// previously each computed the offset math independently and a divergence would
/// have shown the user a clock the engine never armed.
///
/// Two modes, selected by [AppAlarm.isExactTime]:
///   * **Exact-time** ([AppAlarm.isExactTime] true and
///     [AppAlarm.exactTimeMinutes] set): fire at that absolute minute-of-day on
///     the shift's DATE, ignoring every lead time (global default and per-alarm
///     override alike).
///   * **Lead-time** (default): fire at `shiftStart − lead`, where `lead` is the
///     alarm's [AppAlarm.relativeOffsetMinutes] override when set, else
///     [globalLeadMinutes].
///
/// DST-safe by construction in BOTH modes: the (possibly negative) minute field
/// is handed to the `DateTime` constructor, which normalises it in LOCAL time —
/// unlike `Duration` subtraction, an offset crossing midnight or a DST boundary
/// still lands on the correct local wall-clock time.
///
/// Defensive: if [AppAlarm.isExactTime] is true but [AppAlarm.exactTimeMinutes]
/// is null (a malformed record), this falls back to lead-time math rather than
/// throwing — a wrong-but-safe fire time beats a crashed reconcile.
DateTime rotationAlarmFireAt({
  required AppAlarm alarm,
  required Shift shift,
  required int globalLeadMinutes,
}) {
  // Mode decision (incl. the malformed-record fallback) lives on the model —
  // `AppAlarm.activeExactTimeMinutes` — shared with the display projection
  // `AppAlarm.displayFireClockMinutes` so engine and UI clocks can't diverge.
  final exact = alarm.activeExactTimeMinutes;
  if (exact != null) {
    return DateTime(
      shift.date.year,
      shift.date.month,
      shift.date.day,
      exact ~/ 60,
      exact % 60,
    );
  }
  final leadMinutes = alarm.leadMinutesWith(globalLeadMinutes);
  return DateTime(
    shift.date.year,
    shift.date.month,
    shift.date.day,
    shift.startMinutes ~/ 60,
    shift.startMinutes % 60 - leadMinutes,
  );
}
