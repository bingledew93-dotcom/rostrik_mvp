import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/shift_type.dart';
import '../l10n/l10n.dart';
import '../util/weekday_mask.dart';

/// Shared, locale-aware formatting hub. These functions deliberately keep
/// their pre-i18n context-free signatures (dozens of call sites): dates ride
/// the ambient `Intl.defaultLocale` and labels read [currentL10n], both kept
/// in lock-step with the widget tree by [syncL10nFromContext]. In pure Dart
/// tests neither is set, so everything below resolves to English — which is
/// exactly what the output-pinning tests expect.

/// "Mon, May 4" (en) — abbreviated weekday + month + day, per locale.
String formatShiftDate(DateTime date) => DateFormat.MMMEd().format(date);

/// "JUNE 2026" — the upper-cased month + year used as the Timeline list's
/// sticky section header.
String formatMonthYearHeader(DateTime date) =>
    DateFormat.yMMMM().format(date).toUpperCase();

/// "Monday, 9 March 2026" — the long form on the roster builder's start-date
/// field (matches the New Shift Roster design).
String formatFullDate(DateTime date) =>
    DateFormat('EEEE, d MMMM y').format(date);

/// Human alarm lead-time label: "0 min" / "45 min" / "1 h" / "1 h 30 min".
/// Single source for both the Settings slider and the onboarding lead-time
/// dropdown so the two surfaces can never phrase the same duration differently.
String formatLeadTime(int totalMinutes) {
  final l10n = currentL10n;
  if (totalMinutes == 0) return l10n.durationMin(0);
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h == 0) return l10n.durationMin(m);
  if (m == 0) return l10n.durationH(h);
  return l10n.durationHMin(h, m);
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
///
/// Deliberately NOT localized: the numerals-plus-AM/PM shape is a design
/// element of the hero cards and reads universally; users who prefer local
/// conventions have the 24-hour toggle.
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
  final l10n = currentL10n;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return l10n.durationMinShort(m);
  if (m == 0) return l10n.durationHShort(h);
  return l10n.durationHMinShort(h, m);
}

String shiftTypeLabel(ShiftType type) {
  final l10n = currentL10n;
  switch (type) {
    case ShiftType.day:
      return l10n.shiftTypeDay;
    case ShiftType.afternoon:
      return l10n.shiftTypeAfternoon;
    case ShiftType.night:
      return l10n.shiftTypeNight;
    case ShiftType.off:
      return l10n.shiftTypeOff;
  }
}

/// Localized abbreviated weekday name for a `DateTime.weekday` index
/// (1=Mon..7=Sun): "Mon" (en). Anchored to 2024-01-01, a Monday.
String weekdayShort(int weekday) =>
    DateFormat.E().format(DateTime(2024, 1, weekday));

/// Human-readable weekday set for a weekly alarm, from its packed
/// `weekdaysBitmask`. Collapses the common runs into idiomatic copy — all seven
/// → "Every day", Mon–Fri → "Weekdays", Sat+Sun → "Weekends" — and otherwise
/// lists the abbreviated days Monday-first ("Mon, Wed, Fri"). Empty mask →
/// "No days" (a weekly alarm with no day selected can't be saved, so this is
/// only a defensive fallback). Used as the demoted subtitle on weekly alarm
/// cards and the create-sheet caption.
String formatWeekdays(int mask) {
  final l10n = currentL10n;
  final days = weekdaysFromMask(mask);
  if (days.isEmpty) return l10n.weekdaysNone;
  if (days.length == 7) return l10n.weekdaysEveryDay;
  const weekdaySet = {1, 2, 3, 4, 5};
  const weekendSet = {6, 7};
  final set = days.toSet();
  if (set.length == 5 && set.containsAll(weekdaySet)) return l10n.weekdaysWeekdays;
  if (set.length == 2 && set.containsAll(weekendSet)) return l10n.weekdaysWeekends;
  return days.map(weekdayShort).join(', ');
}
