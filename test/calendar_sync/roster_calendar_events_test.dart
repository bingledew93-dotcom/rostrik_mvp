import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/calendar_sync/roster_calendar_events.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

/// Pure tests for the Device Calendar Sync decision layer — which shifts become
/// events, their titles, and their instants. No plugin / device involved.
void main() {
  // A fixed "now" so the future/window filters are deterministic. Midday so a
  // same-day earlier shift is unambiguously in the past.
  final now = DateTime(2026, 8, 10, 12, 0);

  Shift shift(
    int daysFromNow, {
    ShiftType type = ShiftType.day,
    int startMinutes = 6 * 60,
    int endMinutes = 14 * 60,
    bool isPaused = false,
    bool isArchived = false,
    bool isMuted = false,
    String? id,
  }) {
    final d = DateTime(now.year, now.month, now.day + daysFromNow);
    return Shift(
      id: id ?? 'shift-$daysFromNow-${type.name}-$startMinutes',
      date: d,
      type: type,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      isPaused: isPaused,
      isArchived: isArchived,
      isMuted: isMuted,
    );
  }

  group('rosterEventTitle', () {
    test('maps each working type to its emoji-labelled title', () {
      expect(rosterEventTitle(ShiftType.day), '☀️ Day Shift (Rostrik)');
      expect(
        rosterEventTitle(ShiftType.afternoon),
        '🌇 Afternoon Shift (Rostrik)',
      );
      expect(rosterEventTitle(ShiftType.night), '🌙 Night Shift (Rostrik)');
    });
  });

  group('buildRosterCalendarEvents', () {
    test('creates one event per future working shift with exact instants', () {
      final events = buildRosterCalendarEvents(
        [shift(1, type: ShiftType.day, startMinutes: 6 * 60, endMinutes: 14 * 60)],
        now: now,
      );
      expect(events, hasLength(1));
      expect(events.single.title, '☀️ Day Shift (Rostrik)');
      expect(events.single.start, DateTime(2026, 8, 11, 6, 0));
      expect(events.single.end, DateTime(2026, 8, 11, 14, 0));
    });

    test('rolls an overnight shift end into the next day', () {
      final events = buildRosterCalendarEvents(
        [shift(2, type: ShiftType.night, startMinutes: 22 * 60, endMinutes: 6 * 60)],
        now: now,
      );
      expect(events.single.start, DateTime(2026, 8, 12, 22, 0));
      expect(events.single.end, DateTime(2026, 8, 13, 6, 0));
    });

    test('excludes off, paused, and archived shifts', () {
      final events = buildRosterCalendarEvents(
        [
          shift(1, type: ShiftType.off),
          shift(2, isPaused: true),
          shift(3, isArchived: true),
        ],
        now: now,
      );
      expect(events, isEmpty);
    });

    test('includes a muted shift (mute only silences the alarm)', () {
      final events = buildRosterCalendarEvents(
        [shift(1, isMuted: true)],
        now: now,
      );
      expect(events, hasLength(1));
    });

    test('excludes shifts that already started (past-only filter)', () {
      // Same day, starts 06:00, now is 12:00 → already started → skipped.
      final events = buildRosterCalendarEvents(
        [shift(0, startMinutes: 6 * 60, endMinutes: 14 * 60)],
        now: now,
      );
      expect(events, isEmpty);
    });

    test('excludes shifts beyond the horizon window', () {
      final events = buildRosterCalendarEvents(
        [shift(1), shift(200)],
        now: now,
        horizonDays: 180,
      );
      expect(events, hasLength(1));
      expect(events.single.start, DateTime(2026, 8, 11, 6, 0));
    });

    test('sorts the resulting events by start instant', () {
      final events = buildRosterCalendarEvents(
        [shift(5), shift(1), shift(3)],
        now: now,
      );
      final starts = events.map((e) => e.start).toList();
      final sorted = [...starts]..sort();
      expect(starts, sorted);
    });
  });
}
