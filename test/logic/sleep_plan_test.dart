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
    bool isExactTime = false,
    int? exactTimeMinutes,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: 7 * 60,
        label: 'Wake',
        repeatType: repeatType,
        enabled: enabled,
        linkedShiftType: linkedShiftType,
        relativeOffsetMinutes: relativeOffsetMinutes,
        isExactTime: isExactTime,
        exactTimeMinutes: exactTimeMinutes,
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
    DateTime? nowOverride,
  }) =>
      computeSleepPlan(
        shifts: shifts,
        alarms: alarms,
        globalLeadMinutes: globalLeadMinutes,
        sleepGoalHours: sleepGoalHours,
        windDownMinutes: windDownMinutes,
        now: nowOverride ?? now,
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

  group('exact-time alarms drive the wake target (UI/engine sync)', () {
    test('wakeTime is the exact clock; bedtime derives from THAT wake', () {
      // Day shift today 07:00 with an exact-time 04:15 alarm. The wake target
      // must be 04:15 — NOT the 06:00 the old shiftStart − lead math gave —
      // and the bedtime chain (− 8h sleep goal, − 30m wind-down) must be
      // derived from the true 04:15 wake.
      final p = plan(
        shifts: [shift(id: 'd', date: now)],
        alarms: [rotation(isExactTime: true, exactTimeMinutes: 4 * 60 + 15)],
      );
      expect(p.state, SleepPlanState.activeTarget);
      expect(p.wakeTime, DateTime(2026, 6, 2, 4, 15));
      expect(p.targetBedtime, DateTime(2026, 6, 1, 20, 15));
      expect(p.windDownTime, DateTime(2026, 6, 1, 19, 45));
    });

    test('exact-time mode ignores the alarm\'s own offset override', () {
      // A record carrying BOTH exact mode and a stale 90-min override: the
      // engine fires at the exact clock, so the plan must too.
      final p = plan(
        shifts: [shift(id: 'd', date: now)],
        alarms: [
          rotation(
            isExactTime: true,
            exactTimeMinutes: 4 * 60 + 15,
            relativeOffsetMinutes: 90,
          ),
        ],
      );
      expect(p.wakeTime, DateTime(2026, 6, 2, 4, 15));
    });

    test('mixed rules: the earliest actual fire time wins, either mode', () {
      // Exact 04:15 vs lead-time 90 min (05:30) → exact rings first.
      final early = plan(
        shifts: [shift(id: 'd', date: now)],
        alarms: [
          rotation(id: 'lead', relativeOffsetMinutes: 90),
          rotation(id: 'ex', isExactTime: true, exactTimeMinutes: 4 * 60 + 15),
        ],
      );
      expect(early.wakeTime, DateTime(2026, 6, 2, 4, 15));

      // Exact 06:30 vs lead-time 90 min (05:30) → the lead-time alarm rings
      // first; "earliest fire" is mode-agnostic.
      final late = plan(
        shifts: [shift(id: 'd', date: now)],
        alarms: [
          rotation(id: 'lead', relativeOffsetMinutes: 90),
          rotation(id: 'ex', isExactTime: true, exactTimeMinutes: 6 * 60 + 30),
        ],
      );
      expect(late.wakeTime, DateTime(2026, 6, 2, 5, 30));
    });

    test('a malformed exact-time rule (null clock) falls back to lead math',
        () {
      // Same defensive rule as rotationAlarmFireAt: isExactTime without a
      // stored clock degrades to shiftStart − lead instead of crashing.
      final p = plan(
        shifts: [shift(id: 'd', date: now)],
        alarms: [rotation(isExactTime: true, relativeOffsetMinutes: 90)],
      );
      expect(p.wakeTime, DateTime(2026, 6, 2, 5, 30));
    });

    test('a disabled exact-time alarm does not steer the plan', () {
      final p = plan(
        shifts: [shift(id: 'd', date: now)],
        alarms: [
          rotation(
            enabled: false,
            isExactTime: true,
            exactTimeMinutes: 4 * 60 + 15,
          ),
        ],
      );
      // No enabled rule targets Day → global lead fallback (07:00 − 1h).
      expect(p.wakeTime, DateTime(2026, 6, 2, 6, 0));
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
      // The shift starts ~46h out (after midnight, 2 Jun) — well past the 36h
      // horizon. A Transition Day is EXEMPT from the cap, so it must not be
      // demoted to Rest & Recovery.
      expect(p.state, isNot(SleepPlanState.restRecovery));
    });

    test('a brutal turnaround (work today, nights tomorrow) is NOT a transition',
        () {
      // 11:00 on 2 Jun: today's Day shift (06:00–14:00) is already under way, so
      // the next WAKE target is tomorrow's Night shift. But the user WORKS today
      // — "you have a rest day before nights" would be a lie — so the rest-day
      // guard must keep this out of the advisory.
      final p = plan(
        nowOverride: DateTime(2026, 6, 2, 11, 0),
        shifts: [
          shift(
            id: 'today-day',
            date: DateTime(2026, 6, 2),
            type: ShiftType.day,
            startMin: 6 * 60,
            endMin: 14 * 60,
          ),
          shift(
            id: 'tomorrow-night',
            date: DateTime(2026, 6, 3),
            type: ShiftType.night,
            startMin: 22 * 60,
            endMin: 6 * 60,
          ),
        ],
      );
      expect(p.state, isNot(SleepPlanState.nightTransition));
      // ~35h out and within horizon → a normal active target, not rest & recovery.
      expect(p.state, SleepPlanState.activeTarget);
      expect(p.nextShift?.id, 'tomorrow-night');
    });

    test('a Night shift several days out is NOT a transition day', () {
      // Regression (Day-7 field bug): the next working shift is a Night block 8
      // days away (today + the OFF days between are free). The advisory must
      // stay hidden — it only applies when nights start TOMORROW. Being well
      // beyond the 36h horizon, it degrades to Rest & Recovery rather than
      // firing "Transition Day" (or a concrete bedtime) a week early.
      final p = plan(
        shifts: [
          shift(
            id: 'far-night',
            date: DateTime(2026, 6, 10), // now is 2 Jun → 8 days out
            type: ShiftType.night,
            startMin: 22 * 60,
            endMin: 6 * 60,
          ),
        ],
      );
      expect(p.state, isNot(SleepPlanState.nightTransition));
      expect(p.state, SleepPlanState.restRecovery);
      expect(p.nextShift?.id, 'far-night');
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

  group('rest & recovery (horizon cap, state restRecovery)', () {
    test('a shift beyond the 36h horizon degrades to rest & recovery', () {
      // Day shift 4 Jun 07:00 — ~55h from now (2 Jun 00:00). Too far out to
      // plan a concrete bedtime tonight.
      final p = plan(
        shifts: [shift(id: 'far', date: DateTime(2026, 6, 4))],
        alarms: [rotation()],
      );
      expect(p.state, SleepPlanState.restRecovery);
      // No target times — the whole point of the degraded state.
      expect(p.hasTimes, isFalse);
      expect(p.targetBedtime, isNull);
      expect(p.wakeTime, isNull);
      expect(p.windDownTime, isNull);
      // It still knows the next shift; it just doesn't plan around it yet.
      expect(p.nextShift?.id, 'far');
    });

    test('exactly 36h away is still an active target (boundary, inclusive)', () {
      // now = 2 Jun 00:00; start = 3 Jun 12:00 → exactly 36h. The cap is
      // strictly ">36h", so the boundary itself stays inside the horizon.
      final p = plan(
        shifts: [
          shift(id: 'edge', date: DateTime(2026, 6, 3), startMin: 12 * 60),
        ],
      );
      expect(p.state, SleepPlanState.activeTarget);
      expect(p.hasTimes, isTrue);
    });

    test('one minute past 36h tips into rest & recovery (boundary)', () {
      // start = 3 Jun 12:01 → 36h01m, the first instant past the horizon.
      final p = plan(
        shifts: [
          shift(id: 'edge', date: DateTime(2026, 6, 3), startMin: 12 * 60 + 1),
        ],
      );
      expect(p.state, SleepPlanState.restRecovery);
    });
  });
}
