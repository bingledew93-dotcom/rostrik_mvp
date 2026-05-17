import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/repositories/app_alarm_repository.dart';
import 'package:rostrik_mvp/ui/alarms_screen.dart';

import '../alarms/fakes.dart';

void main() {
  Future<FakeAppAlarmRepository> pumpAlarms(
    WidgetTester tester, {
    required List<AppAlarm> seed,
  }) async {
    final repo = FakeAppAlarmRepository();
    for (final a in seed) {
      await repo.upsert(a);
    }
    // The Switch toggling path captures upserts after the screen pumps,
    // so reset the call log to keep "what did the UI do" assertions
    // unambiguous.
    repo.callLog.clear();
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppAlarmRepository>.value(value: repo),
          StreamProvider<List<AppAlarm>>(
            create: (_) => repo.watch(),
            initialData: seed,
          ),
        ],
        child: const MaterialApp(home: AlarmsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return repo;
  }

  AppAlarm mk({
    required String id,
    required int minutesOfDay,
    required String label,
    AppAlarmRepeatType repeatType = AppAlarmRepeatType.followsRotation,
    bool enabled = true,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: minutesOfDay,
        label: label,
        repeatType: repeatType,
        enabled: enabled,
      );

  group('empty state', () {
    testWidgets('renders "No alarms yet" copy when the list is empty',
        (tester) async {
      await pumpAlarms(tester, seed: const []);
      expect(find.text('No alarms yet.'), findsOneWidget);
      expect(find.text('Tap + to add one.'), findsOneWidget);
    });

    testWidgets('the FAB is present even when empty', (tester) async {
      await pumpAlarms(tester, seed: const []);
      expect(find.byKey(const ValueKey('alarms-add-fab')), findsOneWidget);
    });
  });

  group('alarm card rendering', () {
    testWidgets(
      'renders one card per alarm with time, label, repeat-type subtitle',
      (tester) async {
        await pumpAlarms(
          tester,
          seed: [
            mk(
              id: 'a',
              minutesOfDay: 6 * 60,
              label: 'Wake Up - Day Shift',
              repeatType: AppAlarmRepeatType.followsRotation,
            ),
            mk(
              id: 'b',
              minutesOfDay: 22 * 60 + 30,
              label: 'Bed time',
              repeatType: AppAlarmRepeatType.oneTime,
            ),
          ],
        );

        expect(find.text('06:00'), findsOneWidget);
        expect(find.text('22:30'), findsOneWidget);
        expect(find.text('Wake Up - Day Shift'), findsOneWidget);
        expect(find.text('Bed time'), findsOneWidget);
        expect(find.text('Follows your rotation'), findsOneWidget);
        expect(find.text('Rings one time only'), findsOneWidget);
      },
    );

    testWidgets('alarms are sorted by minutesOfDay ascending', (tester) async {
      // Insertion order is intentionally reversed; the UI must render
      // 06:00 above 14:00 above 22:00 regardless.
      await pumpAlarms(
        tester,
        seed: [
          mk(id: 'late', minutesOfDay: 22 * 60, label: 'Night'),
          mk(id: 'early', minutesOfDay: 6 * 60, label: 'Morning'),
          mk(id: 'mid', minutesOfDay: 14 * 60, label: 'Afternoon'),
        ],
      );

      final earlyY = tester.getCenter(find.text('06:00')).dy;
      final midY = tester.getCenter(find.text('14:00')).dy;
      final lateY = tester.getCenter(find.text('22:00')).dy;
      expect(earlyY, lessThan(midY));
      expect(midY, lessThan(lateY));
    });
  });

  group('Switch toggling', () {
    testWidgets('flipping the Switch off calls repo.upsert with enabled=false',
        (tester) async {
      final repo = await pumpAlarms(
        tester,
        seed: [
          mk(
            id: 'a',
            minutesOfDay: 6 * 60,
            label: 'Wake Up',
            enabled: true,
          ),
        ],
      );

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(repo.callLog, contains('upsert:a:enabled=false'));
      final stored = await repo.getById('a');
      expect(stored!.enabled, isFalse);
    });

    testWidgets('flipping a disabled Switch on calls upsert with enabled=true',
        (tester) async {
      final repo = await pumpAlarms(
        tester,
        seed: [
          mk(
            id: 'a',
            minutesOfDay: 6 * 60,
            label: 'Wake Up',
            enabled: false,
          ),
        ],
      );

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(repo.callLog, contains('upsert:a:enabled=true'));
      final stored = await repo.getById('a');
      expect(stored!.enabled, isTrue);
    });
  });

  group('FAB → create sheet', () {
    testWidgets('tapping the FAB opens the create-alarm bottom sheet',
        (tester) async {
      await pumpAlarms(tester, seed: const []);
      await tester.tap(find.byKey(const ValueKey('alarms-add-fab')));
      await tester.pumpAndSettle();

      // "New alarm" header and the save button identify the sheet.
      expect(find.text('New alarm'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create-alarm-save')),
        findsOneWidget,
      );
    });
  });
}
