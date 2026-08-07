import '../data/models/shift.dart';
import '../data/models/shift_type.dart';

/// Pure, plugin-free logic for the optional Device Calendar Sync
/// (`feature-calendar-sync`): which shifts become calendar events, what those
/// events are titled, and their exact start/end instants.
///
/// Kept entirely separate from [DeviceCalendarService] (which does the actual
/// platform I/O) so this decision layer is unit-testable without a device or the
/// `device_calendar_plus` channel.

/// User-facing name of the dedicated calendar Rostrik creates. Shifts are
/// mirrored ONLY here so they never pollute the user's personal calendars, and
/// the sync clears/rebuilds this calendar by matching on this exact name.
const String kRostrikCalendarName = 'Rostrik Roster';

/// Colour of the dedicated calendar (`#RRGGBB`) — the app's safety-orange, so
/// Rostrik shifts are visually distinct in the device calendar app.
const String kRostrikCalendarColorHex = '#FF7A1A';

/// Android local-account name the calendar is grouped under (keeps it clearly
/// "ours" and off any Google/personal account). iOS ignores this.
const String kRostrikCalendarAccountName = 'Rostrik';

/// How far ahead the roster is mirrored, in days (the "6-month rolling window").
const int kCalendarSyncHorizonDays = 180;

/// A single shift resolved into the three facts a calendar event needs. Immutable
/// and value-equal so the build step is trivially testable.
class RosterCalendarEvent {
  const RosterCalendarEvent({
    required this.title,
    required this.start,
    required this.end,
  });

  final String title;
  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RosterCalendarEvent &&
          title == other.title &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(title, start, end);

  @override
  String toString() =>
      'RosterCalendarEvent(title: $title, start: $start, end: $end)';
}

/// Event title for a shift type, e.g. `☀️ Day Shift (Rostrik)`. The `(Rostrik)`
/// suffix marks the event as app-owned even if it's ever copied out of the
/// dedicated calendar. The emoji match the Dashboard hero badges.
///
/// [ShiftType.off] never produces an event (off days are filtered out before
/// this is called); it returns a sensible label only for completeness.
String rosterEventTitle(ShiftType type) {
  switch (type) {
    case ShiftType.day:
      return '☀️ Day Shift (Rostrik)';
    case ShiftType.afternoon:
      return '🌇 Afternoon Shift (Rostrik)';
    case ShiftType.night:
      return '🌙 Night Shift (Rostrik)';
    case ShiftType.off:
      return '🛌 Off (Rostrik)';
  }
}

/// Turns raw shifts into the events to write into the "Rostrik Roster" calendar.
///
/// Included only when a shift is:
///   * a WORKING shift — [ShiftType.off] is excluded;
///   * NOT paused (leave/sick/holiday are excluded — the day isn't worked);
///   * NOT archived (expired ad-hoc tombstones are excluded);
///   * yet to start — its start is strictly after [now] (past shifts stay in the
///     calendar as history and are never re-created);
///   * within the rolling window — starts before `now + [horizonDays]`.
///
/// A muted shift IS included: muting only silences its alarm; the shift is still
/// worked, so it belongs on the calendar.
///
/// Keying inclusion on `start > now` (the same instant the clear step deletes
/// from) makes clear+recreate symmetric, so repeated syncs never duplicate or
/// orphan an event. Results are sorted by start.
List<RosterCalendarEvent> buildRosterCalendarEvents(
  List<Shift> shifts, {
  required DateTime now,
  int horizonDays = kCalendarSyncHorizonDays,
}) {
  final horizonEnd = DateTime(now.year, now.month, now.day + horizonDays);
  final events = <RosterCalendarEvent>[];

  for (final shift in shifts) {
    if (shift.type == ShiftType.off) continue;
    if (shift.isPaused) continue;
    if (shift.isArchived) continue;

    final start = shift.startDateTime;
    final end = shift.endDateTime;
    // Future-only + within window. `end` after `start` always holds for a real
    // shift (overnight shifts roll `end` to the next day), but guard anyway so a
    // zero/negative-length record can never throw at the plugin boundary.
    if (!start.isAfter(now)) continue;
    if (!start.isBefore(horizonEnd)) continue;
    if (!end.isAfter(start)) continue;

    events.add(
      RosterCalendarEvent(
        title: rosterEventTitle(shift.type),
        start: start,
        end: end,
      ),
    );
  }

  events.sort((a, b) => a.start.compareTo(b.start));
  return events;
}
