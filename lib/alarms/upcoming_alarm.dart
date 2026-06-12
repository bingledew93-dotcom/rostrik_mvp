import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import 'rotation_fire_time.dart';

/// The single next follows-rotation alarm occurrence the Dashboard can offer to
/// skip early. Carries the firing instant plus the rule + shift it belongs to,
/// so the caller can both render the clock ("Skip alarm at 05:30 AM") and write
/// the per-occurrence skip to the right [Shift].
class UpcomingAutomatedAlarm {
  const UpcomingAutomatedAlarm({
    required this.alarm,
    required this.shift,
    required this.fireAt,
  });

  final AppAlarm alarm;
  final Shift shift;
  final DateTime fireAt;
}

/// Finds the single earliest follows-rotation alarm scheduled to fire in
/// `(now, now + within]` — the "Dismiss Upcoming Alarm" target for a
/// shift worker who woke before the alarm and wants to skip just this one swing
/// without disarming the rule.
///
/// Pure (no Flutter, no Provider) so it can be unit-tested with synthetic
/// rosters + a fixed `now`. Fire times come from the SAME `rotationAlarmFireAt`
/// helper `AlarmSyncService` schedules with — covering both lead-time and
/// exact-time modes — so what the Dashboard offers can never disagree with what
/// the engine actually scheduled. It applies the same suppression rules too:
///   * only enabled alarms, only followsRotation with a non-null linkedShiftType;
///   * shift type must match the alarm's linkedShiftType;
///   * muted / acknowledged / already-skipped shifts are ignored (their alarm
///     isn't, or is no longer, desired).
///
/// Scope is followsRotation only: weekly and one-time alarms have no shift to
/// pin a per-occurrence skip to, and the "master loop / roster sync" framing of
/// the feature is roster-automated alarms specifically. Returns `null` when no
/// such alarm falls inside the window.
UpcomingAutomatedAlarm? nextUpcomingAutomatedAlarm({
  required List<AppAlarm> alarms,
  required List<Shift> shifts,
  required int globalLeadMinutes,
  required DateTime now,
  Duration within = const Duration(hours: 12),
  bool isSchedulePaused = false,
}) {
  // Holiday Mode: nothing will fire, so there's no upcoming alarm to skip.
  if (isSchedulePaused) return null;
  final until = now.add(within);
  UpcomingAutomatedAlarm? best;

  for (final alarm in alarms) {
    if (!alarm.enabled) continue;
    if (alarm.repeatType != AppAlarmRepeatType.followsRotation) continue;
    final type = alarm.linkedShiftType;
    if (type == null) continue;

    for (final s in shifts) {
      if (s.type != type) continue;
      if (s.isMuted) continue;
      if (s.isAcknowledged) continue;
      if (s.isAlarmSkipped) continue;

      // Shared with AlarmSyncService so the offered skip can never show a clock
      // the engine didn't arm — and it honours exact-time mode automatically.
      final fireAt = rotationAlarmFireAt(
        alarm: alarm,
        shift: s,
        globalLeadMinutes: globalLeadMinutes,
      );

      if (!fireAt.isAfter(now)) continue;
      if (fireAt.isAfter(until)) continue;

      if (best == null || fireAt.isBefore(best.fireAt)) {
        best = UpcomingAutomatedAlarm(alarm: alarm, shift: s, fireAt: fireAt);
      }
    }
  }

  return best;
}
