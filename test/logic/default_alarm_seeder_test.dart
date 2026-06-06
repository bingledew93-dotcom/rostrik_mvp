import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/default_alarm_seeder.dart';

import '../alarms/fakes.dart';

void main() {
  late FakeAppAlarmRepository alarms;

  setUp(() => alarms = FakeAppAlarmRepository());
  tearDown(() => alarms.dispose());

  test('Day-only roster arms a single enabled Day follows-rotation alarm',
      () async {
    final created = await seedDefaultAlarms(
      alarms: alarms,
      workTypes: const [ShiftType.day],
    );

    expect(created, hasLength(1));
    final a = (await alarms.getAll()).single;
    expect(a.repeatType, AppAlarmRepeatType.followsRotation);
    expect(a.linkedShiftType, ShiftType.day);
    expect(a.enabled, isTrue);
    expect(a.relativeOffsetMinutes, isNull,
        reason: 'seeded alarms track the global lead time');
    expect(a.label, 'Day wake-up');
  });

  test('rotating D/N roster arms a Day AND a Night alarm, Day first', () async {
    final created = await seedDefaultAlarms(
      alarms: alarms,
      // Order/duplicates in the input must not matter.
      workTypes: const [ShiftType.night, ShiftType.day, ShiftType.day],
    );

    expect(created.map((a) => a.linkedShiftType), [
      ShiftType.day,
      ShiftType.night,
    ]);
    expect((await alarms.getAll()).map((a) => a.linkedShiftType).toSet(), {
      ShiftType.day,
      ShiftType.night,
    });
  });

  test('OFF is never armed', () async {
    final created = await seedDefaultAlarms(
      alarms: alarms,
      workTypes: const [ShiftType.off],
    );
    expect(created, isEmpty);
    expect(await alarms.getAll(), isEmpty);
  });

  test('a type already covered by a follows-rotation alarm is skipped',
      () async {
    await alarms.upsert(
      AppAlarm(
        id: 'pre',
        minutesOfDay: 6 * 60,
        label: 'My Day alarm',
        repeatType: AppAlarmRepeatType.followsRotation,
        linkedShiftType: ShiftType.day,
      ),
    );

    final created = await seedDefaultAlarms(
      alarms: alarms,
      workTypes: const [ShiftType.day, ShiftType.night],
    );

    // Only Night is new; the pre-existing Day alarm is left untouched.
    expect(created.map((a) => a.linkedShiftType), [ShiftType.night]);
    expect(await alarms.getAll(), hasLength(2));
  });

  test('running twice is idempotent (no duplicates)', () async {
    await seedDefaultAlarms(alarms: alarms, workTypes: const [ShiftType.day]);
    final second =
        await seedDefaultAlarms(alarms: alarms, workTypes: const [ShiftType.day]);
    expect(second, isEmpty);
    expect(await alarms.getAll(), hasLength(1));
  });
}
