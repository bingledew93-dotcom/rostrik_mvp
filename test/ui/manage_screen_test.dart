import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/logic/shift_generator.dart';
import 'package:rostrik_mvp/ui/manage/manage_screen.dart';
import 'package:rostrik_mvp/ui/pattern_picker_screen.dart';
import 'package:rostrik_mvp/ui/shift_editor_modal.dart';

import '../alarms/fakes.dart';

void main() {
  Future<void> pumpManage(WidgetTester tester) async {
    final repo = FakeShiftRepository();
    addTearDown(repo.dispose);
    final cycleRepo = FakeShiftCycleRepository();
    addTearDown(cycleRepo.dispose);
    final generator = ShiftGenerator(shifts: repo, cycles: cycleRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShiftRepository>.value(value: repo),
          // "Generate Rotation" pushes PatternPickerScreen, which reads the
          // generator (+ shift stream) from context to build.
          Provider<ShiftGenerator>.value(value: generator),
          Provider<List<Shift>>.value(value: const []),
          Provider<AlarmSettings>.value(
            value: const AlarmSettings(leadTime: Duration(hours: 1)),
          ),
        ],
        child: const MaterialApp(home: ManageScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders the three roster-tool action cards', (tester) async {
    await pumpManage(tester);
    expect(find.text('Generate Rotation'), findsOneWidget);
    expect(find.text('Add Custom Shift'), findsOneWidget);
    expect(find.text('Pause Schedule'), findsOneWidget);
  });

  testWidgets('Generate Rotation launches the pattern picker', (tester) async {
    await pumpManage(tester);

    await tester.tap(find.byKey(const ValueKey('manage-generate-rotation')));
    await tester.pumpAndSettle();

    expect(find.byType(PatternPickerScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pattern-picker-build-custom')),
      findsOneWidget,
    );
  });

  testWidgets('Add Custom Shift opens the quick-add shift editor',
      (tester) async {
    await pumpManage(tester);

    await tester.tap(find.byKey(const ValueKey('manage-add-custom-shift')));
    await tester.pumpAndSettle();

    // The add-shift modal migrated here from the (now removed) Timeline FAB.
    expect(find.byType(ShiftEditorModal), findsOneWidget);
  });

  testWidgets('Pause Schedule toggle is live (enabled)', (tester) async {
    await pumpManage(tester);

    final toggle = find.byKey(const ValueKey('manage-pause-toggle'));
    expect(toggle, findsOneWidget);
    // A non-null onChanged means the switch is interactive — Holiday Mode is
    // wired (the binding to AppPreferences is exercised in the engine + sleep
    // suite, where the flag's effect is observable).
    expect(tester.widget<Switch>(toggle).onChanged, isNotNull);
  });
}
