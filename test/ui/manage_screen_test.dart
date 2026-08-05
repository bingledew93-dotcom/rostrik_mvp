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
  Future<FakeShiftRepository> pumpManage(WidgetTester tester) async {
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
    return repo;
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

  testWidgets(
      'saving an ad-hoc shift writes a cycle-less Shift to the repository',
      (tester) async {
    // The full Phase-3 insert path: Manage card → editor modal → pickers →
    // Save → Hive. The saved record must carry cycleId == null (ad-hoc, owned
    // by no rotation — a cycle cascade-delete can never remove it). Each
    // picker dialog is confirmed on its default (today / 07:00 / 15:00).
    final repo = await pumpManage(tester);

    await tester.tap(find.byKey(const ValueKey('manage-add-custom-shift')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pick date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Two 'Pick time' rows (Starts, Ends) — confirm each on its default.
    await tester.tap(find.text('Pick time').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Modal closed, one shift written: today, Day 07:00–15:00, NO cycle.
    expect(find.byType(ShiftEditorModal), findsNothing);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final stored = (await repo.getInRange(
      today,
      DateTime(today.year, today.month, today.day + 1),
    ))
        .single;
    expect(stored.cycleId, isNull,
        reason: 'ad-hoc shifts belong to no rotation cycle');
    expect(stored.isAdHoc, isTrue,
        reason: 'the editor stamps the explicit ad-hoc marker the '
            'self-cleaning archive sweep keys off');
    expect(stored.isArchived, isFalse, reason: 'a fresh shift is not archived');
    expect(stored.startMinutes, 7 * 60);
    expect(stored.endMinutes, 15 * 60);
    expect(stored.date, today);
  });

  testWidgets('the date picker reaches one year back (payslip backfill) '
      'and one year forward', (tester) async {
    // The calendar doubles as the historical work record users verify
    // payslips against — restricting firstDate to today broke backfill.
    await pumpManage(tester);
    await tester.tap(find.byKey(const ValueKey('manage-add-custom-shift')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick date'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    expect(dialog.firstDate, DateTime(today.year - 1, today.month, today.day),
        reason: 'historical ad-hoc shifts must be backfillable a year back');
    expect(dialog.lastDate, DateTime(today.year + 1, today.month, today.day));
  });

  testWidgets('backfilling a PAST ad-hoc shift saves the historical record',
      (tester) async {
    // The calendar-cell path opens the editor with a past initialDate — the
    // old `firstDate: today` bound would have asserted inside showDatePicker.
    // Drive the modal directly with last month's date and save.
    final repo = FakeShiftRepository();
    addTearDown(repo.dispose);
    final now = DateTime.now();
    final pastDate = DateTime(now.year, now.month - 1, 15);

    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider<ShiftRepository>.value(value: repo)],
        child: MaterialApp(
          home: Scaffold(body: ShiftEditorModal(initialDate: pastDate)),
        ),
      ),
    );
    await tester.pump();

    // Date is pre-filled; confirm the two time pickers on their defaults.
    await tester.tap(find.text('Pick time').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final stored = (await repo.getInRange(
      pastDate,
      DateTime(pastDate.year, pastDate.month, pastDate.day + 1),
    ))
        .single;
    expect(stored.date, pastDate);
    expect(stored.cycleId, isNull);
    expect(stored.isAdHoc, isTrue);
    expect(stored.startMinutes, 7 * 60);
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
