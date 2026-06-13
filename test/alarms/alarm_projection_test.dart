import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_projection.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

void main() {
  // Mon 2026-06-15, 05:00.
  final now = DateTime(2026, 6, 15, 5, 0);
  const lead = 60;
  const horizon = Duration(days: 14);

  AppAlarm rotation({
    String id = 'r',
    ShiftType type = ShiftType.day,
    int? offset,
    bool enabled = true,
    bool exact = false,
    int? exactMin,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: 6 * 60,
        label: 'Wake',
        repeatType: AppAlarmRepeatType.followsRotation,
        linkedShiftType: type,
        relativeOffsetMinutes: offset,
        enabled: enabled,
        isExactTime: exact,
        exactTimeMinutes: exactMin,
      );

  AppAlarm oneTime(int minutesOfDay, {String id = 'o', bool enabled = true}) =>
      AppAlarm(
        id: id,
        minutesOfDay: minutesOfDay,
        label: 'Once',
        repeatType: AppAlarmRepeatType.oneTime,
        enabled: enabled,
      );

  AppAlarm weekly(int mask, int minutesOfDay, {String id = 'w'}) => AppAlarm(
        id: id,
        minutesOfDay: minutesOfDay,
        label: 'Weekly',
        repeatType: AppAlarmRepeatType.weekly,
        weekdaysBitmask: mask,
      );

  Shift shift({
    required String id,
    required DateTime date,
    ShiftType type = ShiftType.day,
    int start = 7 * 60,
    int end = 15 * 60,
    bool isMuted = false,
    bool isAcknowledged = false,
    bool isAlarmSkipped = false,
    bool isPaused = false,
    bool isArchived = false,
    DateTime? snoozedUntil,
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: start,
        endMinutes: end,
        isMuted: isMuted,
        isAcknowledged: isAcknowledged,
        isAlarmSkipped: isAlarmSkipped,
        isPaused: isPaused,
        isArchived: isArchived,
        snoozedUntil: snoozedUntil,
      );

  List<AlarmRing> project(List<AppAlarm> alarms, List<Shift> shifts,
          {bool paused = false}) =>
      projectAlarmRings(
        alarms: alarms,
        shifts: shifts,
        globalLeadMinutes: lead,
        now: now,
        horizon: horizon,
        isSchedulePaused: paused,
      );

  group('projectAlarmRings — occurrence enumeration', () {
    test('follows-rotation fires at shiftStart − lead, carrying its shift', () {
      final rings =
          project([rotation()], [shift(id: 's', date: DateTime(2026, 6, 16))]);
      expect(rings, hasLength(1));
      expect(rings.single.fireAt, DateTime(2026, 6, 16, 6, 0)); // 07:00 − 1h
      expect(rings.single.shift?.id, 's');
    });

    test('exact-time mode ignores the lead', () {
      final rings = project(
        [rotation(exact: true, exactMin: 4 * 60 + 15)],
        [shift(id: 's', date: DateTime(2026, 6, 16))],
      );
      expect(rings.single.fireAt, DateTime(2026, 6, 16, 4, 15));
    });

    test('one-time: today if ahead, else tomorrow; carries no shift', () {
      expect(project([oneTime(6 * 60)], const []).single.fireAt,
          DateTime(2026, 6, 15, 6, 0)); // 06:00 > 05:00 → today
      expect(project([oneTime(4 * 60)], const []).single.fireAt,
          DateTime(2026, 6, 16, 4, 0)); // 04:00 < 05:00 → tomorrow
      expect(project([oneTime(6 * 60)], const []).single.shift, isNull);
    });

    test('weekly: one ring per selected weekday in the window', () {
      final tueMask = 1 << (DateTime.tuesday - 1);
      final rings = project([weekly(tueMask, 6 * 60)], const []);
      // Mon now → Tue 06-16, Tue 06-23 both inside 14 days.
      expect(rings.map((r) => r.fireAt), [
        DateTime(2026, 6, 16, 6, 0),
        DateTime(2026, 6, 23, 6, 0),
      ]);
    });

    test('rings are sorted earliest-first across alarm types', () {
      final rings = project(
        [oneTime(23 * 60, id: 'late'), rotation(id: 'rot')],
        [shift(id: 's', date: DateTime(2026, 6, 16))], // rotation → 06-16 06:00
      );
      expect(rings.first.alarm.id, 'late'); // today 23:00 is sooner than 06-16
      expect(rings.last.alarm.id, 'rot');
    });

    test('a matching shift beyond the horizon is excluded', () {
      expect(project([rotation()], [shift(id: 'far', date: DateTime(2030, 1, 1))]),
          isEmpty);
    });
  });

  group('projectAlarmRings — universal state awareness', () {
    test('Holiday Mode empties the whole projection', () {
      final rings = project(
        [rotation(), oneTime(6 * 60), weekly(0x7F, 6 * 60)],
        [shift(id: 's', date: DateTime(2026, 6, 16))],
        paused: true,
      );
      expect(rings, isEmpty);
    });

    test('disabled alarms produce no rings', () {
      expect(
        project([rotation(enabled: false), oneTime(6 * 60, enabled: false)],
            [shift(id: 's', date: DateTime(2026, 6, 16))]),
        isEmpty,
      );
    });

    test('OFF shifts never match a rotation alarm', () {
      expect(
        project([rotation(type: ShiftType.day)],
            [shift(id: 'off', date: DateTime(2026, 6, 16), type: ShiftType.off)]),
        isEmpty,
      );
    });

    test('every per-shift suppression flag drops the ring', () {
      for (final s in [
        shift(id: 'm', date: DateTime(2026, 6, 16), isMuted: true),
        shift(id: 'a', date: DateTime(2026, 6, 16), isAcknowledged: true),
        shift(id: 'k', date: DateTime(2026, 6, 16), isAlarmSkipped: true),
        shift(id: 'p', date: DateTime(2026, 6, 16), isPaused: true),
        shift(id: 'x', date: DateTime(2026, 6, 16), isArchived: true),
      ]) {
        expect(project([rotation()], [s]), isEmpty,
            reason: 'suppressed shift ${s.id} must not ring');
      }
    });
  });

  group('projectAlarmRings — snooze resurrection', () {
    test('a fired (past) occurrence with a future snooze rings at snoozedUntil',
        () {
      // Day shift today 04:00 → normalFireAt 03:00 (past now 05:00); snoozed to
      // 05:30 → the ring is the snooze.
      final s = shift(
        id: 'snz',
        date: DateTime(2026, 6, 15),
        start: 4 * 60,
        end: 12 * 60,
        snoozedUntil: DateTime(2026, 6, 15, 5, 30),
      );
      expect(project([rotation()], [s]).single.fireAt,
          DateTime(2026, 6, 15, 5, 30));
    });

    test('a future occurrence ignores a snooze (siblings keep normal time)', () {
      // normalFireAt is future → snooze is NOT applied even if set.
      final s = shift(
        id: 'fut',
        date: DateTime(2026, 6, 16),
        snoozedUntil: DateTime(2026, 6, 15, 6, 0),
      );
      expect(project([rotation()], [s]).single.fireAt,
          DateTime(2026, 6, 16, 6, 0)); // normal, not the snooze
    });
  });

  group('nextAlarmRing / nextRotationRing', () {
    AlarmRing? nextAny(List<AppAlarm> alarms, List<Shift> shifts) =>
        nextAlarmRing(
          alarms: alarms,
          shifts: shifts,
          globalLeadMinutes: lead,
          now: now,
          horizon: horizon,
        );

    AlarmRing? nextRot(List<AppAlarm> alarms, List<Shift> shifts,
            {bool paused = false}) =>
        nextRotationRing(
          alarms: alarms,
          shifts: shifts,
          globalLeadMinutes: lead,
          now: now,
          horizon: horizon,
          isSchedulePaused: paused,
        );

    test('nextAlarmRing returns the single earliest ring of any type', () {
      final ring = nextAny(
        [oneTime(5 * 60 + 30, id: 'soon'), rotation(id: 'rot')],
        [shift(id: 's', date: DateTime(2026, 6, 16))],
      );
      expect(ring!.alarm.id, 'soon'); // 05:30 today beats 06-16 06:00
    });

    test('nextAlarmRing on a single alarm = that alarm next ring (or null)', () {
      expect(nextAny([rotation()], const []), isNull); // no roster
      expect(
        nextAny([rotation()], [shift(id: 's', date: DateTime(2026, 6, 16))])!
            .shift
            ?.id,
        's',
      );
    });

    test('nextRotationRing returns the earliest SHIFT-LINKED ring', () {
      final ring = nextRot(
        // A one-time at 05:30 is sooner, but the hero/early-skip are shift-only.
        [oneTime(5 * 60 + 30, id: 'soon'), rotation(id: 'rot')],
        [shift(id: 's', date: DateTime(2026, 6, 16))],
      );
      expect(ring!.alarm.id, 'rot');
      expect(ring.shift?.id, 's');
    });

    test('nextRotationRing is null under Holiday Mode', () {
      expect(
        nextRot([rotation()], [shift(id: 's', date: DateTime(2026, 6, 16))],
            paused: true),
        isNull,
      );
    });

    test('nextRotationRing ignores a paused shift (early-skip regression)', () {
      expect(
        nextRot([rotation()],
            [shift(id: 'p', date: DateTime(2026, 6, 16), isPaused: true)]),
        isNull,
      );
    });
  });
}
