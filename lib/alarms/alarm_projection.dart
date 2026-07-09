import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../util/weekday_mask.dart';
import 'rotation_fire_time.dart';

/// Display horizon for the UI's "next ring" projections (Alarms-tab hero +
/// per-card line). DELIBERATELY the full materialised-roster window, wider than
/// the engine's 14-day SCHEDULING horizon, so a card can prove a ring weeks out.
/// The engine passes its OWN (14-day) horizon to [projectAlarmRings].
const Duration kRingDisplayHorizon = Duration(days: 366);

/// One concrete alarm occurrence that WILL fire — an alarm rule resolved to an
/// exact instant (and, for follows-rotation alarms, the shift it's for).
class AlarmRing {
  const AlarmRing({required this.alarm, required this.fireAt, this.shift});

  final AppAlarm alarm;
  final DateTime fireAt;

  /// The matching roster shift — non-null ONLY for follows-rotation rings
  /// (one-time / weekly alarms aren't linked to a shift).
  final Shift? shift;
}

/// **THE single source of truth** for "which alarms fire, and exactly when" in
/// `(now, now + horizon]`. Every surface that needs to know about a future
/// alarm — the [AlarmSyncService] scheduler, the Dashboard early-skip control,
/// and the Alarms-tab hero + per-card "Next ring" labels — goes through this one
/// function, so a label can never advertise a ring the engine wouldn't arm.
///
/// It is **universally state-aware**, applying every modifier in one place:
///   * **Holiday Mode** ([isSchedulePaused]) → empties the set (nothing fires).
///   * **Disabled alarms** → skipped.
///   * **OFF shifts** → never match a follows-rotation alarm's `linkedShiftType`.
///   * **Per-shift suppression** — muted, acknowledged, alarm-skipped, **paused**
///     (sick/leave/holiday) and **archived** shifts are all dropped.
///   * **Per-ring dismissal** — a ring whose alarm rule is in the shift's
///     [Shift.dismissedAlarmIds] is dropped ALONE; sibling alarms linked to the
///     same shift keep their rings (dismissing the first of a day's alarms must
///     never disarm the rest).
///   * **Shift-less skip watermark** — a one-time/weekly occurrence whose
///     fireAt is at-or-before its rule's [AppAlarm.skippedThrough] is dropped;
///     later occurrences (next week's ring) survive. The shift-less
///     counterpart of the per-ring dismissal above, written by the Dashboard
///     early-skip. Never consulted for follows-rotation rings.
///   * **Snooze resurrection** — a fired-then-snoozed occurrence rings again at
///     its snooze instant; future siblings keep their normal time. Shift-linked
///     alarms read `Shift.snoozedUntil`; shift-less (one-time / weekly) alarms
///     read [oneOffSnoozes] (AppAlarm id → snooze instant), since they have no
///     shift to carry the state.
///
/// Fire times come from the shared [rotationAlarmFireAt] (rotation) and the
/// one-time / weekly next-occurrence rules, all DST-safe. Pure (no Flutter, no
/// Hive) and returns rings sorted earliest-first.
///
/// Shift scope is the caller's: the engine passes its `getInRange(now, until)`
/// window (an O(box) optimisation); UI callers pass the whole shift stream and
/// rely on the internal `fireAt`-window gate below to bound the result.
List<AlarmRing> projectAlarmRings({
  required List<AppAlarm> alarms,
  required List<Shift> shifts,
  required int globalLeadMinutes,
  required DateTime now,
  required Duration horizon,
  bool isSchedulePaused = false,
  Map<String, DateTime> oneOffSnoozes = const <String, DateTime>{},
}) {
  if (isSchedulePaused) return const <AlarmRing>[];
  final until = now.add(horizon);
  final rings = <AlarmRing>[];

  for (final alarm in alarms) {
    if (!alarm.enabled) continue;
    // Shift-less skip watermark (Dashboard early-skip): suppress any
    // one-time/weekly occurrence at-or-before `skippedThrough`. Evaluated
    // per-ring below; rotation rings never consult it (their dismissals live
    // on the shift row as `dismissedAlarmIds`).
    final skippedThrough = alarm.skippedThrough;
    bool skipped(DateTime fireAt) =>
        skippedThrough != null && !fireAt.isAfter(skippedThrough);
    switch (alarm.repeatType) {
      case AppAlarmRepeatType.oneTime:
        // Snooze resurrection: while a one-off snooze is active, the imminent
        // ring IS the snooze — pin to it and skip the normal next occurrence.
        final oneTimeSnooze = oneOffSnoozes[alarm.id];
        if (oneTimeSnooze != null && oneTimeSnooze.isAfter(now)) {
          if (oneTimeSnooze.isBefore(until) && !skipped(oneTimeSnooze)) {
            rings.add(AlarmRing(alarm: alarm, fireAt: oneTimeSnooze));
          }
          continue;
        }
        final fireAt = _nextDailyOccurrence(alarm.minutesOfDay, now);
        if (!fireAt.isBefore(until)) continue;
        if (skipped(fireAt)) continue;
        rings.add(AlarmRing(alarm: alarm, fireAt: fireAt));

      case AppAlarmRepeatType.weekly:
        final mask = alarm.weekdaysBitmask;
        if (mask == 0) continue; // no day selected — nothing to schedule
        // Snooze resurrection: add the snooze ring for the just-fired occurrence.
        // The day-loop below only adds FUTURE occurrences, so today's fired one
        // is already excluded and next week's keeps its normal time — we ADD the
        // snooze rather than skip, unlike one-time.
        final weeklySnooze = oneOffSnoozes[alarm.id];
        if (weeklySnooze != null &&
            weeklySnooze.isAfter(now) &&
            weeklySnooze.isBefore(until) &&
            !skipped(weeklySnooze)) {
          rings.add(AlarmRing(alarm: alarm, fireAt: weeklySnooze));
        }
        // DST-safe calendar-day walk; `now`'s own day is included so today's
        // still-future occurrence is caught.
        for (var d = DateTime(now.year, now.month, now.day);
            d.isBefore(until);
            d = DateTime(d.year, d.month, d.day + 1)) {
          if (!maskHasWeekday(mask, d.weekday)) continue;
          final fireAt = DateTime(
            d.year,
            d.month,
            d.day,
            alarm.minutesOfDay ~/ 60,
            alarm.minutesOfDay % 60,
          );
          if (!fireAt.isAfter(now)) continue;
          if (!fireAt.isBefore(until)) continue;
          if (skipped(fireAt)) continue;
          rings.add(AlarmRing(alarm: alarm, fireAt: fireAt));
        }

      case AppAlarmRepeatType.followsRotation:
        final type = alarm.linkedShiftType;
        if (type == null) continue; // invalid config — skip
        for (final s in shifts) {
          if (s.type != type) continue;
          // Every per-shift state modifier, in ONE place:
          if (s.isMuted) continue;
          if (s.isAcknowledged) continue;
          if (s.isAlarmSkipped) continue;
          if (s.isPaused) continue;
          if (s.isArchived) continue;
          // PER-OCCURRENCE dismissal: only THIS alarm rule's ring for this
          // shift was dismissed — its siblings on the same shift must keep
          // firing. Checked BEFORE the snooze pin so a stale `snoozedUntil`
          // can never resurrect a ring the user already dismissed.
          if (s.dismissedAlarmIds.contains(alarm.id)) continue;

          final normalFireAt = rotationAlarmFireAt(
            alarm: alarm,
            shift: s,
            globalLeadMinutes: globalLeadMinutes,
          );
          // Snooze resurrection: only pin to `snoozedUntil` once the normal
          // fire time is already past (this occurrence fired and was snoozed) —
          // pinning unconditionally would drag future sibling alarms forward.
          final snoozed = s.snoozedUntil;
          final fireAt = (snoozed != null &&
                  snoozed.isAfter(now) &&
                  !normalFireAt.isAfter(now))
              ? snoozed
              : normalFireAt;

          if (!fireAt.isAfter(now)) continue;
          if (!fireAt.isBefore(until)) continue;
          rings.add(AlarmRing(alarm: alarm, fireAt: fireAt, shift: s));
        }
    }
  }

  rings.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return rings;
}

/// The single earliest ring of ANY type, or null. For a per-alarm "Next ring"
/// label, pass a single-element [alarms] list.
AlarmRing? nextAlarmRing({
  required List<AppAlarm> alarms,
  required List<Shift> shifts,
  required int globalLeadMinutes,
  required DateTime now,
  Duration horizon = kRingDisplayHorizon,
  bool isSchedulePaused = false,
}) {
  final rings = projectAlarmRings(
    alarms: alarms,
    shifts: shifts,
    globalLeadMinutes: globalLeadMinutes,
    now: now,
    horizon: horizon,
    isSchedulePaused: isSchedulePaused,
  );
  return rings.isEmpty ? null : rings.first;
}

/// The single earliest **follows-rotation** ring (carries its linked shift), or
/// null. Powers the Dashboard early-skip and the Alarms-tab hero — both are
/// shift-linked: one-time / weekly alarms have no shift to skip or feature.
AlarmRing? nextRotationRing({
  required List<AppAlarm> alarms,
  required List<Shift> shifts,
  required int globalLeadMinutes,
  required DateTime now,
  Duration horizon = kRingDisplayHorizon,
  bool isSchedulePaused = false,
}) {
  for (final ring in projectAlarmRings(
    alarms: alarms,
    shifts: shifts,
    globalLeadMinutes: globalLeadMinutes,
    now: now,
    horizon: horizon,
    isSchedulePaused: isSchedulePaused,
  )) {
    if (ring.shift != null) return ring; // rotation rings carry a shift
  }
  return null;
}

/// Next future occurrence of [minutesOfDay] in local time: today if it's still
/// ahead, else tomorrow.
DateTime _nextDailyOccurrence(int minutesOfDay, DateTime now) {
  final today = DateTime(
    now.year,
    now.month,
    now.day,
    minutesOfDay ~/ 60,
    minutesOfDay % 60,
  );
  if (today.isAfter(now)) return today;
  return DateTime(
    now.year,
    now.month,
    now.day + 1,
    minutesOfDay ~/ 60,
    minutesOfDay % 60,
  );
}
