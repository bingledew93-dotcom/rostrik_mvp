import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/sleep_plan.dart';
import 'package:rostrik_mvp/reminders/sleep_reminders.dart';

/// Pure tests for the Sleep-nudge decision layer.
void main() {
  final now = DateTime(2026, 8, 10, 19, 0); // 7pm

  Shift dayShift() => Shift(
        id: 's1',
        date: DateTime(2026, 8, 11),
        type: ShiftType.day,
        startMinutes: 6 * 60,
        endMinutes: 14 * 60,
      );

  SleepPlan activePlan({
    DateTime? bedtime,
    DateTime? windDown,
    DateTime? wake,
    int goal = 8,
  }) =>
      SleepPlan(
        state: SleepPlanState.activeTarget,
        sleepGoalHours: goal,
        windDownMinutes: 30,
        nextShift: dayShift(),
        wakeTime: wake ?? DateTime(2026, 8, 11, 5, 30),
        targetBedtime: bedtime ?? DateTime(2026, 8, 10, 21, 30),
        windDownTime: windDown ?? DateTime(2026, 8, 10, 21, 0),
      );

  test('arms wind-down then bedtime when both enabled and in the future', () {
    final reminders = desiredSleepReminders(
      plan: activePlan(),
      now: now,
      bedtimeEnabled: true,
      windDownEnabled: true,
      use24Hour: true,
    );
    expect(reminders, hasLength(2));
    // Wind-down first (it's earlier).
    expect(reminders[0].id, kSleepWindDownReminderId);
    expect(reminders[0].at, DateTime(2026, 8, 10, 21, 0));
    expect(reminders[1].id, kSleepBedtimeReminderId);
    expect(reminders[1].at, DateTime(2026, 8, 10, 21, 30));
    // 24h clock reflected in the copy.
    expect(reminders[1].body, contains('05:30'));
  });

  test('honours the individual toggles', () {
    final onlyBedtime = desiredSleepReminders(
      plan: activePlan(),
      now: now,
      bedtimeEnabled: true,
      windDownEnabled: false,
      use24Hour: false,
    );
    expect(onlyBedtime, hasLength(1));
    expect(onlyBedtime.single.id, kSleepBedtimeReminderId);

    final none = desiredSleepReminders(
      plan: activePlan(),
      now: now,
      bedtimeEnabled: false,
      windDownEnabled: false,
      use24Hour: false,
    );
    expect(none, isEmpty);
  });

  test('excludes a time that has already passed tonight', () {
    // Wind-down at 18:00 is before now (19:00) → dropped; bedtime at 21:30 kept.
    final reminders = desiredSleepReminders(
      plan: activePlan(windDown: DateTime(2026, 8, 10, 18, 0)),
      now: now,
      bedtimeEnabled: true,
      windDownEnabled: true,
      use24Hour: true,
    );
    expect(reminders, hasLength(1));
    expect(reminders.single.id, kSleepBedtimeReminderId);
  });

  test('12-hour copy formats the wake time with AM/PM', () {
    final reminders = desiredSleepReminders(
      plan: activePlan(wake: DateTime(2026, 8, 11, 5, 30)),
      now: now,
      bedtimeEnabled: true,
      windDownEnabled: false,
      use24Hour: false,
    );
    expect(reminders.single.body, contains('5:30 AM'));
  });

  test('advisory / empty plan states arm nothing', () {
    for (final state in [
      SleepPlanState.none,
      SleepPlanState.restRecovery,
      SleepPlanState.nightTransition,
    ]) {
      final plan = SleepPlan(
        state: state,
        sleepGoalHours: 8,
        windDownMinutes: 30,
        nextShift: state == SleepPlanState.none ? null : dayShift(),
      );
      expect(
        desiredSleepReminders(
          plan: plan,
          now: now,
          bedtimeEnabled: true,
          windDownEnabled: true,
          use24Hour: true,
        ),
        isEmpty,
        reason: '$state should arm no reminders',
      );
    }
  });

  test('the two reminder ids are distinct and positive', () {
    expect(kSleepBedtimeReminderId, isPositive);
    expect(kSleepWindDownReminderId, isPositive);
    expect(kSleepBedtimeReminderId, isNot(kSleepWindDownReminderId));
  });
}
