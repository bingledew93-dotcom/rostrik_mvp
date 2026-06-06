import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_cycle.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/app_alarm_repository.dart';
import 'package:rostrik_mvp/data/repositories/shift_cycle_repository.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/ui/onboarding/arm_engine_screen.dart';

import '../alarms/fakes.dart';

void main() {
  final now = DateTime.now();

  Shift shift(String id, ShiftType type, {int dayOffset = 0}) => Shift(
        id: id,
        date: DateTime(now.year, now.month, now.day + dayOffset),
        type: type,
        startMinutes: type == ShiftType.off ? 0 : 7 * 60,
        endMinutes: type == ShiftType.off ? 0 : 15 * 60,
      );

  /// Pumps the Arm Engine screen over fake repos seeded with [shifts] /
  /// [cycles]. [onArm] records the injected completion so we never need real
  /// navigation or a Hive box in the test.
  Future<FakeAppAlarmRepository> pumpArm(
    WidgetTester tester, {
    required List<Shift> shifts,
    List<ShiftCycle> cycles = const [],
    required void Function() onArm,
  }) async {
    final shiftRepo = FakeShiftRepository();
    for (final s in shifts) {
      await shiftRepo.upsert(s);
    }
    addTearDown(shiftRepo.dispose);
    final cycleRepo = FakeShiftCycleRepository();
    for (final c in cycles) {
      await cycleRepo.create(c);
    }
    addTearDown(cycleRepo.dispose);
    final alarmRepo = FakeAppAlarmRepository();
    addTearDown(alarmRepo.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShiftRepository>.value(value: shiftRepo),
          Provider<ShiftCycleRepository>.value(value: cycleRepo),
          Provider<AppAlarmRepository>.value(value: alarmRepo),
        ],
        child: MaterialApp(
          home: ArmEngineScreen(onArmComplete: () async => onArm()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return alarmRepo;
  }

  testWidgets('summarises the roster and the alarms it will arm',
      (tester) async {
    await pumpArm(
      tester,
      shifts: [
        shift('d', ShiftType.day),
        shift('n', ShiftType.night, dayOffset: 7),
        shift('o', ShiftType.off, dayOffset: 1),
      ],
      cycles: [
        ShiftCycle(
          id: 'c1',
          label: '7/7 D/N',
          summary: 'rotating',
          startDate: now,
          endDate: DateTime(now.year, now.month, now.day + 365),
          createdAt: now,
          anchorDate: now,
        ),
      ],
      onArm: () {},
    );

    expect(find.byKey(const ValueKey('arm-engine-button')), findsOneWidget);
    expect(find.text('Automate My Alarms'), findsOneWidget);
    // Cycle label surfaces in the summary.
    expect(find.textContaining('7/7 D/N'), findsOneWidget);
    // The arming line names both working types (OFF excluded), Day first.
    final summary = tester.widget<Text>(
      find.byKey(const ValueKey('arm-engine-arming-summary')),
    );
    expect(summary.data, contains('Day & Night'));
  });

  testWidgets('Automate My Alarms seeds the roster\'s alarms and completes',
      (tester) async {
    var armed = false;
    final repo = await pumpArm(
      tester,
      shifts: [
        shift('d', ShiftType.day),
        shift('n', ShiftType.night, dayOffset: 7),
        shift('o', ShiftType.off, dayOffset: 1),
      ],
      onArm: () => armed = true,
    );

    await tester.tap(find.byKey(const ValueKey('arm-engine-button')));
    // Not pumpAndSettle: while arming, the button shows a CircularProgress
    // that animates forever (in production the injected completion navigates
    // away). Pump fixed frames to flush the async seed + completion instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final all = await repo.getAll();
    // One enabled follows-rotation alarm per WORKING type — OFF never armed.
    expect(all.map((a) => a.linkedShiftType).toSet(), {
      ShiftType.day,
      ShiftType.night,
    });
    expect(
      all.every((a) =>
          a.repeatType == AppAlarmRepeatType.followsRotation &&
          a.enabled &&
          a.relativeOffsetMinutes == null),
      isTrue,
    );
    // Completion handed off to the injected callback.
    expect(armed, isTrue);
  });
}
