import '../data/models/shift.dart';
import '../data/models/shift_type.dart';

/// Projects the **clock time an alarm will ring** for display in the Alarms UI.
///
/// This is presentation logic — the authoritative scheduled instant is computed
/// with DST-safe calendar math in `AlarmSyncService`. Here we only render a
/// clock face for a follows-rotation alarm, so the UI can flip its visual
/// hierarchy from "- 1h 30m" (anxiety-inducing offset) to "05:30 AM" (the
/// thing the user actually wants to know). The underlying `AppAlarm` lead-time
/// model is untouched: the offset is still the source of truth; we just
/// subtract it from the linked shift's start time for display.
///
/// Kept pure (no Flutter, no Provider) and free-function-shaped so it can be
/// unit-tested with synthetic rosters + a fixed `now`, matching the project's
/// extracted-logic convention.

/// Canonical fallback start-of-shift minute-of-day per type, used ONLY when the
/// roster holds no shift of that type to read a real start time from. Mirrors
/// the rotation-pattern presets (Day 07:00, Night 22:00); Afternoon 15:00 is
/// the conventional swing start. OFF never anchors an alarm — its value is a
/// benign placeholder.
const Map<ShiftType, int> kDefaultShiftStartMinutes = <ShiftType, int>{
  ShiftType.day: 7 * 60, // 07:00
  ShiftType.afternoon: 15 * 60, // 15:00
  ShiftType.night: 22 * 60, // 22:00
  ShiftType.off: 7 * 60, // placeholder — alarms never link to OFF
};

/// The minute-of-day at which the user's [type] shifts actually begin, read
/// from [shifts]: the NEXT upcoming shift of that type relative to [now] if one
/// exists, else the most recent past one (both are representative of "when this
/// shift starts"). Returns `null` if the roster contains no shift of [type].
int? rosterStartMinutesForType(
  List<Shift> shifts,
  ShiftType type, {
  required DateTime now,
}) {
  Shift? nextUpcoming;
  Shift? latestPast;
  for (final s in shifts) {
    if (s.type != type) continue;
    final start = s.startDateTime;
    if (start.isBefore(now)) {
      if (latestPast == null || start.isAfter(latestPast.startDateTime)) {
        latestPast = s;
      }
    } else {
      if (nextUpcoming == null ||
          start.isBefore(nextUpcoming.startDateTime)) {
        nextUpcoming = s;
      }
    }
  }
  return (nextUpcoming ?? latestPast)?.startMinutes;
}

/// Resolved start minute-of-day for [type] — the roster value when available,
/// otherwise the [kDefaultShiftStartMinutes] fallback so a clock can always be
/// shown (e.g. a brand-new user adding an alarm before generating a roster).
int resolveShiftStartMinutes(
  List<Shift> shifts,
  ShiftType type, {
  required DateTime now,
}) =>
    rosterStartMinutesForType(shifts, type, now: now) ??
    kDefaultShiftStartMinutes[type] ??
    7 * 60;

/// Clock time (minute-of-day, 0..1439) an alarm fires: the shift start minus
/// the lead, wrapped across midnight (a 90-min lead before a 00:30 shift fires
/// at 23:00 the previous day → 1380). Display-only; the real scheduled date is
/// resolved elsewhere with calendar math.
int fireClockMinutes(int shiftStartMinutes, int leadMinutes) {
  final raw = (shiftStartMinutes - leadMinutes) % 1440;
  return raw < 0 ? raw + 1440 : raw;
}
