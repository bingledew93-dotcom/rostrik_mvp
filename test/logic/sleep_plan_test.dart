import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/sleep_plan.dart';

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
    int endMin = 15 * 60,
    bool isMuted = false,
    bool isAcknowledged = false,
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: startMin,
        endMinutes: endMin,
        isMuted: isMuted,
        isAcknowledged: isAcknowledged,
      );

  SleepPlan plan({
    required List<Shift> shifts,
    List<AppAlarm> alarms = const [],
    int globalLeadMinutes = 60,
    int sleepGoalHours = 8,
    int windDownMinutes = 30,
    bool isSchedulePaused = false,
  }) =>
      computeSleepPlan(
        shifts: shifts,
        alarms: alarms,
        globalLeadMinutes: globalLeadMinutes,
        sleepGoalHours: sleepGoalHours,
        windDownMinutes: windDownMinutes,
        now: now,
        isSchedulePaused: isSchedulePaused,
      );

  group('graceful empty (state none)', () {
    test('no shifts at all', () {
      final p = plan(shifts: const []);
      expect(p.state, SleepPlanState.none);
      expect(p.hasTimes, isFalse);
      expect(p.nextShift, isNull);
      expect(p.targetBedtime, isNull);
    });

    test('only OFF shifts do not count', () {
      final p = plan(
        shifts: [shift(id: 'o', date: now, type: ShiftType.off, startMin: 0)],
      );
      expect(p.state, SleepPlanState.none);
    });

    test('a shift whose start has already passed is not a wake target', () {
      // Now is midnight; a shift that started yesterday morning is in the past.
      final p = plan(
        shifts: [shift(id: 'd', date: DateTime(2026, 6, 1))],
      );
      expect(p.state, SleepPlanState.none);
    });

    test('Holiday Mode goes dormant even with an upcoming shift', () {
      // A perfectly valid wake target exists, but paused → no plan.
      final p = plan(
        shifts: [shift(id: 'd', date: now)],
        isSchedulePaused: true,
      );
      expect(p.state, SleepPlanState.none);
      expect(p.hasTimes, isFalse);
    });
  });

  group('active target (state activeTarget)', () {
    test('bedtime = wake − sleepGoal, wind-down = bedtime − windDown', () {
      // Day shift today 07:00, global lead 60 → wake 06:00.
      // 06:00 − 8h = 22:00 the previous day; − 30m wind-down = 21:30.
      final p = plan(
        shifts: [shift(id: 'd', date: now)],
        alarms: [rotation()],
      );
      expect(p.state, SleepPlanState.activeTarget);
      expect(p.wakeTime, DateTime(2026, 6, 2, 6, 0));
      expect(p.targetBedtime, DateTime(2026, 6, 1, 22, 0));
      expect(p.windDownTime, DateTime(2026, 6, 1, 21, 30));
      expect(p.sleepGoalHours, 8);
    });

    test('falls back to the global lead when no alarm targets the type', () {
      // No alarm rules → wake derives from globalLeadMinutes (60) alone.
      final p = plan(shifts: [shift(id: 'd', date: now)]);
      expect(p.state, SleepPlanState.activeTarget);
      expect(p.wakeTime, DateTime(2026, 6, 2, 6, 0));
    });

    test('the largest matching lead (earliest ring) drives the wake time', () {
      // Two Day alarms: 60 and 90 min. The 90-min one rings first → wake 05:30.
      final p = plan(
        shifts: [shift(id: 'd', date: now)],
        alarms: [
          rotation(id: 'a', relativeOffsetMinutes: 60),
          rotation(id: 'b', relativeOffsetMinutes: 90),
        ],
      );
      expect(p.wakeTime, DateTime(2026, 6, 2, 5, 30));
    });

    test('a Night shift that starts TODAY is an active target, not advisory',
        () {
      final p = plan(
        shifts: [
          shift(id: 'n', date: now, type: ShiftType.night, startMin: 22 * 60),
        ],
      );
      expect(p.state, SleepPlanState.activeTarget);
    });

    test('picks the earliest future non-OFF shift', () {
      final p = plan(
        shifts: [
          shift(id: 'far', date: DateTime(2026, 6, 5)),
          shift(id: 'near', date: DateTime(2026, 6, 3)),
        ],
      );
      expect(p.nextShift?.id, 'near');
    });

    test('muted / acknowledged shifts are skipped', () {
      final p = plan(
        shifts: [
          shift(id: 'm', date: now, isMuted: true),
          shift(id: 'a', date: DateTime(2026, 6, 3), isAcknowledged: true),
        ],
      );
      expect(p.state, SleepPlanState.none);
    });
  });

  group('night transition (state nightTransition)', () {
    test('next working shift is a Night shift starting a future day', () {
      // Night shift tomorrow (3 Jun) evening; today (2 Jun) is free.
      final p = plan(
        shifts: [
          shift(
            id: 'n',
            date: DateTime(2026, 6, 3),
            type: ShiftType.night,
            startMin: 22 * 60,
            endMin: 6 * 60,
          ),
        ],
      );
      expect(p.state, SleepPlanState.nightTransition);
      // Times are still computed so reminders can surface them.
      expect(p.hasTimes, isTrue);
      expect(p.nextShift?.id, 'n');
    });

    test('an earlier non-Night shift suppresses the advisory', () {
      // A Day shift tomorrow morning is the real next wake target, even though
      // a Night shift follows — so this is an active target, not a transition.
      final p = plan(
        shifts: [
          shift(id: 'd', date: DateTime(2026, 6, 3)),
          shift(
            id: 'n',
            date: DateTime(2026, 6, 4),
            type: ShiftType.night,
            startMin: 22 * 60,
            endMin: 6 * 60,
          ),
        ],
      );
      expect(p.state, SleepPlanState.activeTarget);
      expect(p.nextShift?.id, 'd');
    });
  });
}
