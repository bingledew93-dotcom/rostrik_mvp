import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/ui/shift_editor_modal.dart';

import '../alarms/fakes.dart';

void main() {
  Future<FakeShiftRepository> pumpEditor(
    WidgetTester tester, {
    Shift? existing,
    DateTime? initialDate,
  }) async {
    // Tall surface so the editor with the pause section expanded fits without
    // a RenderFlex overflow in the bare test Scaffold (the real sheet scrolls).
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeShiftRepository();
    addTearDown(repo.dispose);
    if (existing != null) await repo.upsert(existing);
    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider<ShiftRepository>.value(value: repo)],
        child: MaterialApp(
          home: Scaffold(
            body: ShiftEditorModal(existing: existing, initialDate: initialDate),
          ),
        ),
      ),
    );
    await tester.pump();
    return repo;
  }

  testWidgets('edit mode saves in place under the same id, preserving '
      'cycleId + isAdHoc (no duplicate, no ad-hoc flip)', (tester) async {
    // A rotation occurrence: belongs to a cycle, NOT ad-hoc. Editing it must
    // update the one record — never spawn a new ad-hoc shift.
    final original = Shift(
      id: 'rota-1',
      date: DateTime(2026, 6, 15),
      type: ShiftType.day,
      startMinutes: 7 * 60,
      endMinutes: 15 * 60,
      cycleId: 'cycle-A',
      isAdHoc: false,
    );
    final repo = await pumpEditor(tester, existing: original);

    // Edit-mode chrome: header + pre-filled, immediately-saveable form.
    expect(find.text('Edit shift'), findsOneWidget);
    expect(find.text('Add shift'), findsNothing);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final all = await repo.getAll();
    expect(all, hasLength(1), reason: 'edit updates in place, never duplicates');
    final saved = all.single;
    expect(saved.id, 'rota-1');
    expect(saved.cycleId, 'cycle-A', reason: 'cycle membership preserved');
    expect(saved.isAdHoc, isFalse, reason: 'a rotation edit stays rotation');
    expect(saved.type, ShiftType.day);
    expect(saved.startMinutes, 7 * 60);
  });

  testWidgets('add mode creates a fresh ad-hoc shift for the prefilled date',
      (tester) async {
    final repo = await pumpEditor(tester, initialDate: DateTime(2026, 6, 20));
    expect(find.text('Add shift'), findsOneWidget);

    // Date is prefilled; confirm the two time pickers on their defaults.
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

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.isAdHoc, isTrue);
    expect(all.single.cycleId, isNull);
    expect(all.single.date, DateTime(2026, 6, 20));
  });

  testWidgets('edit: pausing with a reason persists isPaused + pauseReason',
      (tester) async {
    final original = Shift(
      id: 's1',
      date: DateTime(2026, 6, 15),
      type: ShiftType.day,
      startMinutes: 7 * 60,
      endMinutes: 15 * 60,
    );
    final repo = await pumpEditor(tester, existing: original);

    await tester.tap(find.byKey(const ValueKey('shift-editor-pause-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sick')); // preset reason chip
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = (await repo.getAll()).single;
    expect(saved.id, 's1', reason: 'edit in place, same record');
    expect(saved.isPaused, isTrue);
    expect(saved.pauseReason, 'Sick');
  });

  testWidgets('edit: un-pausing clears the reason', (tester) async {
    final original = Shift(
      id: 's1',
      date: DateTime(2026, 6, 15),
      type: ShiftType.day,
      startMinutes: 7 * 60,
      endMinutes: 15 * 60,
      isPaused: true,
      pauseReason: 'Annual Leave',
    );
    final repo = await pumpEditor(tester, existing: original);

    // Toggle pause OFF, then save → reason wiped (clearPauseReason).
    await tester.tap(find.byKey(const ValueKey('shift-editor-pause-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = (await repo.getAll()).single;
    expect(saved.isPaused, isFalse);
    expect(saved.pauseReason, isNull);
  });
}
