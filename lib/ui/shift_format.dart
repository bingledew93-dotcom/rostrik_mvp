import 'package:flutter/material.dart';

import '../data/models/shift_type.dart';
import '../util/weekday_mask.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Mon, May 4". DateTime.weekday is 1=Mon..7=Sun.
String formatShiftDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';

const _monthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "JUNE 2026" — the upper-cased month + year used as the Timeline list's
/// sticky section header.
String formatMonthYearHeader(DateTime date) =>
    '${_monthsFull[date.month - 1].toUpperCase()} ${date.year}';

const _weekdaysFull = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// "Monday, 9 March 2026" — the long form on the roster builder's start-date
/// field (matches the New Shift Roster design).
String formatFullDate(DateTime date) =>
    '${_weekdaysFull[date.weekday - 1]}, ${date.day} '
    '${_monthsFull[date.month - 1]} ${date.year}';

/// Human alarm lead-time label: "0 min" / "45 min" / "1 h" / "1 h 30 min".
/// Single source for both the Settings slider and the onboarding lead-time
/// dropdown so the two surfaces can never phrase the same duration differently.
String formatLeadTime(int totalMinutes) {
  if (totalMinutes == 0) return '0 min';
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m min';
}

/// 24-hour zero-padded — matches roster card subtitle for consistency.
String formatHhmm(int minutesOfDay) {
  final h = (minutesOfDay ~/ 60).toString().padLeft(2, '0');
  final m = (minutesOfDay % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String formatTimeOfDay(TimeOfDay t) => formatHhmm(t.hour * 60 + t.minute);

/// UI-facing wall-clock formatter that honours the user's 12/24-hour
/// preference. A thin delegate over the existing [formatHhmm] (24h) and
/// [formatClock12h] (12h) — neither base formatter changes, so the tests
/// pinning their output stay valid. Callers pass a normalised minutes-of-day
/// (0..1439); 12h mode also wraps defensively inside [formatClock12h].
String formatClock(int minutesOfDay, {required bool use24Hour}) =>
    use24Hour ? formatHhmm(minutesOfDay) : formatClock12h(minutesOfDay);

/// [formatClock] for a [TimeOfDay] — same preference-aware behaviour.
String formatClockOfDay(TimeOfDay t, {required bool use24Hour}) =>
    formatClock(t.hour * 60 + t.minute, use24Hour: use24Hour);

/// 12-hour clock with AM/PM, zero-padded hour: 270 → "04:30 AM",
/// 0 → "12:00 AM", 720 → "12:00 PM", 1290 → "09:30 PM". Used for the Alarms
/// hero text, where the calculated firing time (not the lead offset) is the
/// headline. Input is wrapped to 0..1439 so a midnight-crossing fire time
/// (start − lead < 0) formats correctly.
String formatClock12h(int minutesOfDay) {
  final total = ((minutesOfDay % 1440) + 1440) % 1440;
  final h24 = total ~/ 60;
  final m = total % 60;
  final period = h24 < 12 ? 'AM' : 'PM';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '${h12.toString().padLeft(2, '0')}:'
      '${m.toString().padLeft(2, '0')} $period';
}

/// Human-readable lead-time magnitude: 60 → "1h", 90 → "1h 30m", 45 → "45m".
/// Unsigned — callers add their own framing ("- " on the create sheet,
/// "before shift" on the alarm card).
String formatLeadOffset(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

String shiftTypeLabel(ShiftType type) {
  switch (type) {
    case ShiftType.day:
      return 'Day';
    case ShiftType.afternoon:
      return 'Afternoon';
    case ShiftType.night:
      return 'Night';
    case ShiftType.off:
      return 'Off';
  }
}

/// Human-readable weekday set for a weekly alarm, from its packed
/// `weekdaysBitmask`. Collapses the common runs into idiomatic copy — all seven
/// → "Every day", Mon–Fri → "Weekdays", Sat+Sun → "Weekends" — and otherwise
/// lists the abbreviated days Monday-first ("Mon, Wed, Fri"). Empty mask →
/// "No days" (a weekly alarm with no day selected can't be saved, so this is
/// only a defensive fallback). Used as the demoted subtitle on weekly alarm
/// cards and the create-sheet caption.
String formatWeekdays(int mask) {
  final days = weekdaysFromMask(mask);
  if (days.isEmpty) return 'No days';
  if (days.length == 7) return 'Every day';
  const weekdaySet = {1, 2, 3, 4, 5};
  const weekendSet = {6, 7};
  final set = days.toSet();
  if (set.length == 5 && set.containsAll(weekdaySet)) return 'Weekdays';
  if (set.length == 2 && set.containsAll(weekendSet)) return 'Weekends';
  return days.map((d) => _weekdays[d - 1]).join(', ');
}
