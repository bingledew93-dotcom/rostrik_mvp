import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/calendar_activity.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/calendar_activity_repository.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/ui/day_actions_sheet.dart';

import '../alarms/fakes.dart';
import '../reminders/fakes.dart';

void main() {
  late FakeShiftRepository shifts;
  late FakeCalendarActivityRepository activities;

  final date = DateTime(2035, 6, 15);

  setUp(() {
    shifts = FakeShiftRepository();
    activities = FakeCalendarActivityRepository();
  });
  tearDown(() async {
    await shifts.dispose();
    await activities.dispose();
  });

  Shift shift() => Shift(
        id: 's1',
        date: date,
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      );

  CalendarActivity activity() => CalendarActivity(
        id: 'a1',
        date: date,
        title: 'Dentist',
        kind: ActivityKind.event,
      );

  Future<void> openSheet(
    WidgetTester tester, {
    List<Shift> shiftsOnDate = const [],
    List<CalendarActivity> activitiesOnDate = const [],
  }) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShiftRepository>.value(value: shifts),
          Provider<CalendarActivityRepository>.value(value: activities),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showDayActionsSheet(
                    context,
                    date: date,
                    shiftsOnDate: shiftsOnDate,
                    activitiesOnDate: activitiesOnDate,
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

  testWidgets('a blank day offers Add shift and Add activity', (tester) async {
    await openSheet(tester);
    expect(find.byKey(const ValueKey('day-add-shift')), findsOneWidget);
    expect(find.byKey(const ValueKey('day-add-activity')), findsOneWidget);
    expect(find.byKey(const ValueKey('day-shift-0')), findsNothing);
    expect(find.byKey(const ValueKey('day-activity-0')), findsNothing);
  });

  testWidgets('existing shifts and activities are listed', (tester) async {
    await openSheet(
      tester,
      shiftsOnDate: [shift()],
      activitiesOnDate: [activity()],
    );
    expect(find.byKey(const ValueKey('day-shift-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('day-activity-0')), findsOneWidget);
    expect(find.text('Dentist'), findsOneWidget);
  });

  testWidgets('Add activity opens the activity editor', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('day-add-activity')));
    await tester.pumpAndSettle();
    // The activity editor is up (its Save key is unique to it).
    expect(find.byKey(const ValueKey('activity-save')), findsOneWidget);
    // Add mode → no Delete.
    expect(find.byKey(const ValueKey('activity-delete')), findsNothing);
  });

  testWidgets('tapping an existing activity opens it in edit mode',
      (tester) async {
    await openSheet(tester, activitiesOnDate: [activity()]);
    await tester.tap(find.byKey(const ValueKey('day-activity-0')));
    await tester.pumpAndSettle();
    // Edit mode → Delete is present.
    expect(find.byKey(const ValueKey('activity-delete')), findsOneWidget);
  });

  testWidgets('Add shift opens the shift editor', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('day-add-shift')));
    await tester.pumpAndSettle();
    // The shift editor has an "Off" shift-type segment — unique to it.
    expect(find.text('Off'), findsOneWidget);
  });
}
