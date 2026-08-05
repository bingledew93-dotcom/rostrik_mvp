import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/calendar_activity.dart';
import 'package:rostrik_mvp/data/repositories/calendar_activity_repository.dart';
import 'package:rostrik_mvp/ui/activity_editor_modal.dart';

import '../reminders/fakes.dart';

void main() {
  late FakeCalendarActivityRepository repo;

  // A comfortably-future date so the "reminder has passed" hint never fires.
  final date = DateTime(2035, 6, 15);

  setUp(() => repo = FakeCalendarActivityRepository());
  tearDown(() => repo.dispose());

  Future<void> openEditor(
    WidgetTester tester, {
    CalendarActivity? existing,
  }) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      Provider<CalendarActivityRepository>.value(
        value: repo,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showActivityEditorModal(
                    context,
                    date: date,
                    existing: existing,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Save is disabled until a title is entered', (tester) async {
    await openEditor(tester);
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('activity-save')),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('adding a titled all-day event persists it', (tester) async {
    await openEditor(tester);
    await tester.enterText(
      find.byKey(const ValueKey('activity-title')),
      'Dentist',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('activity-save')));
    await tester.pumpAndSettle();

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.title, 'Dentist');
    expect(all.single.kind, ActivityKind.event);
    expect(all.single.isAllDay, isTrue);
    expect(all.single.reminderAt, isNull);
  });

  testWidgets('an all-day reminder defaults to 09:00 on the day',
      (tester) async {
    await openEditor(tester);
    await tester.enterText(
      find.byKey(const ValueKey('activity-title')),
      'Mum birthday',
    );
    await tester.tap(find.byKey(const ValueKey('activity-remind')));
    await tester.pumpAndSettle();
    // The all-day "Remind at" row is shown (no lead chips for an all-day entry).
    expect(find.byKey(const ValueKey('activity-remind-at')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('activity-save')));
    await tester.pumpAndSettle();

    final saved = (await repo.getAll()).single;
    expect(saved.reminderAt, DateTime(date.year, date.month, date.day, 9, 0));
  });

  testWidgets('editing a timed reminder recovers the lead and re-resolves it',
      (tester) async {
    final eventStart = DateTime(date.year, date.month, date.day, 9, 0);
    final existing = CalendarActivity(
      id: 'e1',
      date: date,
      title: 'Meeting',
      kind: ActivityKind.event,
      timeMinutes: 9 * 60,
      reminderAt: eventStart.subtract(const Duration(minutes: 30)),
    );
    await openEditor(tester, existing: existing);

    // The 30-min lead chip is recovered as selected.
    final chip30 = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('activity-lead-30')),
    );
    expect(chip30.selected, isTrue);

    // Switch to "1 hour before" and save → reminderAt = eventStart − 60.
    await tester.tap(find.byKey(const ValueKey('activity-lead-60')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('activity-save')));
    await tester.pumpAndSettle();

    final saved = await repo.getById('e1');
    expect(saved!.reminderAt, eventStart.subtract(const Duration(hours: 1)));
  });

  testWidgets('a Task shows the Completed checkbox', (tester) async {
    await openEditor(tester);
    await tester.tap(find.text('Task'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('activity-done')), findsOneWidget);
  });

  testWidgets('Delete removes the activity (edit mode only)', (tester) async {
    final existing = CalendarActivity(
      id: 'e1',
      date: date,
      title: 'Old thing',
      kind: ActivityKind.event,
    );
    await repo.upsert(existing);
    await openEditor(tester, existing: existing);

    await tester.tap(find.byKey(const ValueKey('activity-delete')));
    await tester.pumpAndSettle();

    expect(await repo.getAll(), isEmpty);
  });

  testWidgets('no Delete button in add mode', (tester) async {
    await openEditor(tester);
    expect(find.byKey(const ValueKey('activity-delete')), findsNothing);
  });
}
