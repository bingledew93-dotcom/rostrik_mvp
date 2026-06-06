import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/upcoming_alarm.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

void main() {
  // Fixed reference instant: midnight, 2 Jun 2026.
  final now = DateTime(2026, 6, 2);

  AppAlarm rotation({
    String id = 'fr',
    ShiftType? linkedShiftType = ShiftType.day,
    bool enabled = true,
    int? relativeOffsetMinutes,
    AppAlarmRepeatType repeatType = AppAlarmRepeatType.followsRotation,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: 7 * 60,
        label: 'Wake',
        repeatType: repeatType,
        enabled: enabled,
        linkedShiftType: linkedShiftType,
        relativeOffsetMinutes: relativeOffsetMinutes,
      );

  Shift shift({
    required String id,
    required DateTime date,
    ShiftType type = ShiftType.day,
    int startMin = 7 * 60,
    bool isMuted = false,
    bool isAcknowledged = false,
    bool isAlarmSkipped = false,
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: startMin,
        endMinutes: 15 * 60,
        isMuted: isMuted,
        isAcknowledged: isAcknowledged,
        isAlarmSkipped: isAlarmSkipped,
      );

  UpcomingAutomatedAlarm? run({
    required List<AppAlarm> alarms,
    required List<Shift> shifts,
    int globalLeadMinutes = 60,
  }) =>
      nextUpcomingAutomatedAlarm(
        alarms: alarms,
        shifts: shifts,
        globalLeadMinutes: globalLeadMinutes,
        now: now,
      );

  test('returns the alarm when a Day shift fires within 12h', () {
    // Day shift today at 07:00, 60-min lead → fires 06:00 (6h out) → in window.
    final result = run(
      alarms: [rotation()],
      shifts: [shift(id: 'd1', date: now)],
    );
    expect(result, isNotNull);
    expect(result!.shift.id, 'd1');
    expect(result.fireAt, DateTime(2026, 6, 2, 6, 0));
  });

  test('returns null when the next fire is beyond the 12h window', () {
    // 07:00 shift with a 60-min lead fires 06:00; from midnight that's 6h, in
    // window. Push the lead to 0 and the shift later so the fire is >12h out.
    final result = run(
      alarms: [rotation()],
      shifts: [shift(id: 'd1', date: now, startMin: 20 * 60)], // fires 19:00
    );
    expect(result, isNull);
  });

  test('returns null when no alarm/shift matches', () {
    expect(run(alarms: const [], shifts: const []), isNull);
    // Alarm linked to Day but only a Night shift exists.
    expect(
      run(
        alarms: [rotation()],
        shifts: [shift(id: 'n1', date: now, type: ShiftType.night)],
      ),
      isNull,
    );
  });

  test('picks the single earliest fire across alarms + shifts', () {
    final result = run(
      alarms: [
        rotation(id: 'a-day'),
        rotation(id: 'a-night', linkedShiftType: ShiftType.night),
      ],
      shifts: [
        shift(id: 'd1', date: now, startMin: 9 * 60), // day → fires 08:00
        shift(
          id: 'n1',
          date: now,
          type: ShiftType.night,
          startMin: 8 * 60,
        ), // night → fires 07:00 (earlier)
      ],
    );
    expect(result!.shift.id, 'n1');
    expect(result.alarm.id, 'a-night');
  });

  test('per-alarm override beats the global lead', () {
    // 90-min override → 07:00 shift fires 05:30 (earlier than the 60-min global).
    final result = run(
      alarms: [rotation(relativeOffsetMinutes: 90)],
      shifts: [shift(id: 'd1', date: now)],
    );
    expect(result!.fireAt, DateTime(2026, 6, 2, 5, 30));
  });

  group('suppression', () {
    for (final c in [
      ('muted', shift(id: 'd1', date: DateTime(2026, 6, 2), isMuted: true)),
      (
        'acknowledged',
        shift(id: 'd1', date: DateTime(2026, 6, 2), isAcknowledged: true)
      ),
      (
        'already-skipped',
        shift(id: 'd1', date: DateTime(2026, 6, 2), isAlarmSkipped: true)
      ),
    ]) {
      test('${c.$1} shift is ignored', () {
        expect(run(alarms: [rotation()], shifts: [c.$2]), isNull);
      });
    }

    test('disabled alarm is ignored', () {
      expect(
        run(
          alarms: [rotation(enabled: false)],
          shifts: [shift(id: 'd1', date: now)],
        ),
        isNull,
      );
    });
  });

  group('scope: followsRotation only', () {
    test('weekly alarms are ignored', () {
      expect(
        run(
          alarms: [rotation(repeatType: AppAlarmRepeatType.weekly)],
          shifts: [shift(id: 'd1', date: now)],
        ),
        isNull,
      );
    });

    test('oneTime alarms are ignored', () {
      expect(
        run(
          alarms: [rotation(repeatType: AppAlarmRepeatType.oneTime)],
          shifts: [shift(id: 'd1', date: now)],
        ),
        isNull,
      );
    });

    test('followsRotation with null link is ignored', () {
      expect(
        run(
          alarms: [rotation(linkedShiftType: null)],
          shifts: [shift(id: 'd1', date: now)],
        ),
        isNull,
      );
    });
  });
}
