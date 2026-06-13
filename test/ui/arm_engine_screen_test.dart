import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_cycle.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/alarm_settings_repository.dart';
import 'package:rostrik_mvp/data/repositories/app_alarm_repository.dart';
import 'package:rostrik_mvp/data/repositories/shift_cycle_repository.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/logic/cycle_service.dart';
import 'package:rostrik_mvp/ui/onboarding/arm_engine_screen.dart';

import '../alarms/fakes.dart';

/// The fake repo set the Arm-Engine harness exposes for assertions.
typedef ArmHarness = ({
  FakeAppAlarmRepository alarms,
  FakeShiftRepository shifts,
  FakeShiftCycleRepository cycles,
  FakeAlarmSettingsRepository settings,
});

void main() {
  final now = DateTime.now();

  Shift shift(String id, ShiftType type, {int dayOffset = 0, String? cycleId}) =>
      Shift(
        id: id,
        date: DateTime(now.year, now.month, now.day + dayOffset),
        type: type,
        startMinutes: type == ShiftType.off ? 0 : 7 * 60,
        endMinutes: type == ShiftType.off ? 0 : 15 * 60,
      ).copyWith(cycleId: cycleId);

  /// Pumps the Arm Engine screen over fake repos seeded with [shifts] /
  /// [cycles] / [settings]. [onArm] records the injected completion and
  /// [onBack] the injected back affordance — so we never need real navigation
  /// or a Hive box. A real [CycleService] over the fakes drives the back-nav
  /// rollback path.
  Future<ArmHarness> pumpArm(
    WidgetTester tester, {
    required List<Shift> shifts,
    List<ShiftCycle> cycles = const [],
    AlarmSettings settings = AlarmSettings.defaults,
    required void Function() onArm,
    void Function()? onBack,
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
    final settingsRepo = FakeAlarmSettingsRepository();
    await settingsRepo.write(settings);
    addTearDown(settingsRepo.dispose);
    final cycleService = CycleService(
      cycles: cycleRepo,
      shifts: shiftRepo,
      scheduler: FakeAlarmScheduler(),
      idMap: InMemoryNotificationIdMap(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShiftRepository>.value(value: shiftRepo),
          Provider<ShiftCycleRepository>.value(value: cycleRepo),
          Provider<AppAlarmRepository>.value(value: alarmRepo),
          Provider<AlarmSettingsRepository>.value(value: settingsRepo),
          Provider<CycleService>.value(value: cycleService),
        ],
        child: MaterialApp(
          home: ArmEngineScreen(
            onArmComplete: () async => onArm(),
            onBack: onBack,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (
      alarms: alarmRepo,
      shifts: shiftRepo,
      cycles: cycleRepo,
      settings: settingsRepo,
    );
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
    final h = await pumpArm(
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

    final all = await h.alarms.getAll();
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

  group('lead time', () {
    testWidgets('renders the lead-time dropdown at the persisted value',
        (tester) async {
      await pumpArm(
        tester,
        shifts: [shift('d', ShiftType.day)],
        settings: const AlarmSettings(leadTime: Duration(minutes: 45)),
        onArm: () {},
      );

      expect(find.byKey(const ValueKey('arm-engine-lead-time')), findsOneWidget);
      // Closed field shows the persisted lead.
      expect(find.text('45 min'), findsOneWidget);
    });

    testWidgets('changing the lead time persists it before arming',
        (tester) async {
      final h = await pumpArm(
        tester,
        shifts: [shift('d', ShiftType.day)],
        onArm: () {},
      );

      await tester.tap(find.byKey(const ValueKey('arm-engine-lead-time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30 min').last);
      await tester.pumpAndSettle();

      expect((await h.settings.read()).leadTime, const Duration(minutes: 30));
    });
  });

  group('back-nav rollback', () {
    testWidgets('backing out cascade-deletes the just-generated roster',
        (tester) async {
      var backed = false;
      final h = await pumpArm(
        tester,
        shifts: [
          shift('d', ShiftType.day, cycleId: 'c1'),
          shift('o', ShiftType.off, dayOffset: 1, cycleId: 'c1'),
        ],
        cycles: [
          ShiftCycle(
            id: 'c1',
            label: '7/7',
            summary: 'rotating',
            startDate: now,
            endDate: DateTime(now.year, now.month, now.day + 365),
            createdAt: now,
            anchorDate: now,
          ),
        ],
        onArm: () {},
        onBack: () => backed = true,
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // The generated cycle + its shifts are rolled back, then onBack fires —
      // so re-selecting a template starts from a clean slate.
      expect(await h.cycles.getAll(), isEmpty);
      expect(await h.shifts.getByCycleId('c1'), isEmpty);
      expect(backed, isTrue);
    });
  });
}
