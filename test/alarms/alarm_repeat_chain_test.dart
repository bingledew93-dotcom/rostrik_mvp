import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_sync_service.dart';
import 'package:rostrik_mvp/alarms/ios_notification_budget.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

import 'fakes.dart';

/// The repeat chain exists because an iOS notification's sound stops after
/// ~30s. Without follow-up alerts a heavy sleeper is simply not woken — which
/// on a shift app means a missed shift. These tests pin the two properties
/// that make it safe: only the imminent alarms pay for it, and the set MOVES
/// as they fire.
void main() {
  late FakeAppAlarmRepository alarms;
  late FakeShiftRepository shifts;
  late FakeShiftCycleRepository cycles;
  late FakeAlarmSettingsRepository settings;
  late FakeAlarmScheduler scheduler;
  late InMemoryNotificationIdMap idMap;
  late FrozenClock clock;
  late AlarmSyncService service;

  setUp(() {
    alarms = FakeAppAlarmRepository();
    shifts = FakeShiftRepository();
    cycles = FakeShiftCycleRepository();
    settings = FakeAlarmSettingsRepository();
    scheduler = FakeAlarmScheduler();
    idMap = InMemoryNotificationIdMap();
    clock = FrozenClock(DateTime(2026, 6, 1, 5, 0));
  });

  tearDown(() async {
    await service.stop();
    await alarms.dispose();
    await shifts.dispose();
    await cycles.dispose();
    await settings.dispose();
  });

  /// `chainedAlarmCount` is injected rather than left to the platform so these
  /// run identically on any host — the production default is iOS-only.
  AlarmSyncService build({int chainedAlarmCount = 2}) => AlarmSyncService(
        alarms: alarms,
        shifts: shifts,
        cycles: cycles,
        alarmSettings: settings,
        scheduler: scheduler,
        idMap: idMap,
        clock: clock,
        chainedAlarmCount: chainedAlarmCount,
      );

  Future<void> seedDayShifts(List<int> days) async {
    await alarms.upsert(AppAlarm(
      id: 'r',
      minutesOfDay: 6 * 60,
      label: 'Wake',
      repeatType: AppAlarmRepeatType.followsRotation,
      linkedShiftType: ShiftType.day,
    ));
    for (final d in days) {
      await shifts.upsert(Shift(
        id: 's$d',
        date: DateTime(2026, 6, d),
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      ));
    }
    await settings.write(const AlarmSettings(leadTime: Duration(minutes: 60)));
  }

  List<int> chainedIds() => (scheduler.scheduled.values
          .where((a) => a.repeatChain > 0)
          .toList()
        ..sort((a, b) => a.fireAt.compareTo(b.fireAt)))
      .map((a) => a.id)
      .toList();

  test('only the most imminent alarms carry a chain', () async {
    await seedDayShifts([2, 3, 4, 5, 6]);
    service = build();
    await service.syncAlarms();

    // Five alarms armed, but only the front two are worth the notification
    // budget — the rest are days away and will be re-chained before they ring.
    expect(scheduler.scheduled, hasLength(5));
    expect(chainedIds(), hasLength(2));

    final byTime = scheduler.scheduled.values.toList()
      ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    expect(chainedIds(), [byTime[0].id, byTime[1].id]);
    expect(byTime[0].repeatChain, kAlarmRepeatChainLength);
    expect(byTime.last.repeatChain, 0);
  });

  // THE property that makes the chain useful rather than a one-off. When the
  // front alarm drops out, the next one's fireAt has NOT moved and the OS still
  // holds it — so the unchanged-state gate would skip it and it would ring
  // exactly once. Chain membership has to count as a change.
  test('the chain advances when the front alarm is gone', () async {
    await seedDayShifts([2, 3, 4]);
    service = build(chainedAlarmCount: 1);
    await service.syncAlarms();

    final first = chainedIds().single;

    // The front shift passes: delete it and reconcile, exactly as a fired and
    // retired alarm would.
    await shifts.delete('s2');
    scheduler.clearLog();
    await service.syncAlarms();

    final second = chainedIds().single;
    expect(second, isNot(first), reason: 'the chain must move to the new front');
    expect(scheduler.callLog, contains('schedule:$second'),
        reason: 'the newly-imminent alarm must be RE-scheduled to gain its '
            'chain, even though its fire time never changed');
  });

  test('no chain is requested where a single alert already rings until '
      'dismissed', () async {
    await seedDayShifts([2, 3, 4]);
    service = build(chainedAlarmCount: 0); // the Android default
    await service.syncAlarms();

    expect(scheduler.scheduled, isNotEmpty);
    expect(chainedIds(), isEmpty);
  });

  test('the budget stays under the iOS notification ceiling', () {
    // A silent overrun is the failure mode here: iOS drops notifications past
    // 64 with no error, so the alarm simply never arrives.
    const worstCase =
        kIosMaxScheduledAlarms + kChainCost + kIosReminderReserve;
    expect(worstCase, lessThanOrEqualTo(kIosNotificationCeiling));
    expect(kIosMaxScheduledAlarms, greaterThan(0));
  });
}
