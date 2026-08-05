import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/alarm_sort.dart';

void main() {
  // Empty roster + zero lead → a follows-rotation alarm's ring time is exactly
  // its linked type's default start (Day 07:00 = 420, Afternoon 15:00 = 900,
  // Night 22:00 = 1320). Keeps the expected sort keys obvious.
  const noShifts = <Shift>[];
  final now = DateTime(2026, 8, 6, 12);

  AppAlarm rot(String id, ShiftType type, {String label = 'x'}) => AppAlarm(
        id: id,
        // 420 is the create-sheet placeholder every rotation alarm carries — the
        // whole point is the sort must NOT key on this (it'd tie them all).
        minutesOfDay: 420,
        label: label,
        repeatType: AppAlarmRepeatType.followsRotation,
        linkedShiftType: type,
      );

  AppAlarm once(String id, int minutes, {String label = 'x'}) => AppAlarm(
        id: id,
        minutesOfDay: minutes,
        label: label,
        repeatType: AppAlarmRepeatType.oneTime,
      );

  List<String> ids(List<AppAlarm> a) => a.map((x) => x.id).toList();

  List<AppAlarm> sort(List<AppAlarm> input, {required bool byShiftType}) =>
      sortAlarmsForDisplay(
        input,
        shifts: noShifts,
        globalLeadMinutes: 0,
        byShiftType: byShiftType,
        now: now,
      );

  group('sortAlarmsForDisplay — by ring time', () {
    test('orders by the real ring clock time, earliest first', () {
      final input = [
        rot('night', ShiftType.night), // 1320
        once('early', 300), // 05:00
        rot('day', ShiftType.day), // 420
        once('mid', 1000), // 16:40
      ];
      expect(ids(sort(input, byShiftType: false)),
          ['early', 'day', 'mid', 'night']);
    });

    test('a newly-added rotation alarm slots by time, never at the bottom', () {
      // Both rotation alarms share the placeholder minutesOfDay=420, so the old
      // minutesOfDay sort tied them and kept insertion order (new one last).
      // The Day alarm is appended LAST yet must land first by its true time.
      final input = [
        rot('night', ShiftType.night), // rings 1320
        rot('day', ShiftType.day), // rings 420, added last
      ];
      final out = sort(input, byShiftType: false);
      expect(ids(out), ['day', 'night']);
    });
  });

  group('sortAlarmsForDisplay — by shift type', () {
    test('groups Day → Afternoon → Night, then shift-less alarms', () {
      final input = [
        rot('night', ShiftType.night),
        once('one', 300),
        rot('day', ShiftType.day),
        rot('aft', ShiftType.afternoon),
      ];
      expect(ids(sort(input, byShiftType: true)),
          ['day', 'aft', 'night', 'one']);
    });

    test('within a shift-type group, earliest ring time wins', () {
      final input = [
        // Two Day alarms with different leads → different ring times.
        AppAlarm(
          id: 'day-late',
          minutesOfDay: 420,
          label: 'x',
          repeatType: AppAlarmRepeatType.followsRotation,
          linkedShiftType: ShiftType.day,
          isExactTime: true,
          exactTimeMinutes: 400, // rings 06:40
        ),
        AppAlarm(
          id: 'day-early',
          minutesOfDay: 420,
          label: 'x',
          repeatType: AppAlarmRepeatType.followsRotation,
          linkedShiftType: ShiftType.day,
          isExactTime: true,
          exactTimeMinutes: 360, // rings 06:00
        ),
      ];
      expect(ids(sort(input, byShiftType: true)), ['day-early', 'day-late']);
    });
  });

  group('sortAlarmsForDisplay — stability & purity', () {
    test('equal time + label falls back to a stable id order', () {
      final input = [once('b', 500), once('a', 500)];
      expect(ids(sort(input, byShiftType: false)), ['a', 'b']);
    });

    test('does not mutate the input list', () {
      final input = [
        rot('night', ShiftType.night),
        rot('day', ShiftType.day),
      ];
      final before = ids(input);
      sort(input, byShiftType: false);
      expect(ids(input), before);
    });
  });
}
