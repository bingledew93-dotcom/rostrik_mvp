import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/calendar_activity.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_cycle.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/calendar_activity_repository.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/ui/calendar/shift_calendar.dart';
import 'package:rostrik_mvp/ui/shift_editor_modal.dart';
import 'package:rostrik_mvp/ui/shift_format.dart';
import 'package:rostrik_mvp/ui/timeline/timeline_screen.dart';

import '../alarms/fakes.dart';
import '../reminders/fakes.dart';

void main() {
  // Far-future date keeps shifts "upcoming" independent of wall-clock time.
  final futureDate = DateTime.now().add(const Duration(days: 7));

  Future<void> pumpTimeline(
    WidgetTester tester, {
    required List<Shift> shifts,
    List<ShiftCycle> cycles = const [],
    List<CalendarActivity> activities = const [],
  }) async {
    final repo = FakeShiftRepository();
    for (final s in shifts) {
      await repo.upsert(s);
    }
    addTearDown(repo.dispose);
    final activityRepo = FakeCalendarActivityRepository();
    addTearDown(activityRepo.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // The month-view day-tap editor reads this to save an add/edit.
          Provider<ShiftRepository>.value(value: repo),
          // The day chooser routes "Add/edit activity" into the activity editor,
          // which reads this repo on save.
          Provider<CalendarActivityRepository>.value(value: activityRepo),
          // Both bodies sit under the IndexedStack and watch List<Shift> — the
          // calendar is now bound to the same shift stream as the list. The
          // cycles provider is retained only for a pushed Settings screen.
          Provider<List<Shift>>.value(value: shifts),
          Provider<List<ShiftCycle>>.value(value: cycles),
          // Month view watches this to paint activity markers + feed the chooser.
          Provider<List<CalendarActivity>>.value(value: activities),
        ],
        child: const MaterialApp(home: TimelineScreen()),
      ),
    );
    await tester.pump();
  }

  Shift dayShift({String id = 'a', DateTime? date}) => Shift(
        id: id,
        date: date ?? futureDate,
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      );

  Shift offShift({String id = 'off', DateTime? date}) => Shift(
        id: id,
        date: date ?? futureDate,
        type: ShiftType.off,
        startMinutes: 0,
        endMinutes: 0,
      );

  int? stackIndex(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index;

  group('chassis', () {
    testWidgets('renders one AppBar and NO FAB (view-only surface)',
        (tester) async {
      await pumpTimeline(tester, shifts: [dayShift()]);
      expect(find.byType(AppBar), findsOneWidget);
      // The add-shift FAB moved to the Manage tab — Timeline is view-only.
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Timeline'), findsOneWidget);
    });
  });

  group('view toggle (List / Month)', () {
    testWidgets('exposes both segments and defaults to List View',
        (tester) async {
      await pumpTimeline(tester, shifts: [dayShift()]);
      expect(find.text('List View'), findsOneWidget);
      expect(find.text('Month View'), findsOneWidget);
      // Default index 0 = List → the shift card is on screen.
      expect(stackIndex(tester), 0);
      expect(find.byKey(const ValueKey('shift-card-a')), findsOneWidget);
    });

    testWidgets('tapping Month View swaps to the data-driven calendar grid',
        (tester) async {
      await pumpTimeline(tester, shifts: [dayShift()]);

      await tester.tap(find.text('Month View'));
      await tester.pumpAndSettle();

      expect(stackIndex(tester), 1);
      // The calendar is now bound to the shift stream, not the cycle resolver —
      // it always renders (blank cells when empty), no "no rotation" gate.
      expect(find.byType(ShiftCalendarView), findsOneWidget);
    });

    testWidgets('swapping back to List View restores the list', (tester) async {
      await pumpTimeline(tester, shifts: [dayShift()]);

      await tester.tap(find.text('Month View'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('List View'));
      await tester.pumpAndSettle();

      expect(stackIndex(tester), 0);
      expect(find.byKey(const ValueKey('shift-card-a')), findsOneWidget);
    });
  });

  group('list view — shift cards + filter chips', () {
    testWidgets('shows shift cards directly', (tester) async {
      await pumpTimeline(tester, shifts: [dayShift()]);
      expect(find.byKey(const ValueKey('shift-card-a')), findsOneWidget);
    });

    testWidgets('All chip shows every shift', (tester) async {
      await pumpTimeline(
        tester,
        shifts: [dayShift(id: 'd'), offShift(id: 'o')],
      );
      expect(find.byKey(const ValueKey('shift-card-d')), findsOneWidget);
      expect(find.byKey(const ValueKey('shift-card-o')), findsOneWidget);
    });

    testWidgets('Work chip filters out OFF shifts', (tester) async {
      await pumpTimeline(
        tester,
        shifts: [dayShift(id: 'd'), offShift(id: 'o')],
      );
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('shift-card-d')), findsOneWidget);
      expect(find.byKey(const ValueKey('shift-card-o')), findsNothing);
    });

    testWidgets('Off chip keeps only OFF shifts', (tester) async {
      await pumpTimeline(
        tester,
        shifts: [dayShift(id: 'd'), offShift(id: 'o')],
      );
      await tester.tap(find.text('Off'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('shift-card-d')), findsNothing);
      expect(find.byKey(const ValueKey('shift-card-o')), findsOneWidget);
    });

    testWidgets('filter selection survives a Month → List round-trip',
        (tester) async {
      await pumpTimeline(
        tester,
        shifts: [dayShift(id: 'd'), offShift(id: 'o')],
      );
      // Filter to Work, swap to Month and back — the Work filter must persist
      // (filter state is owned by the parent screen).
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Month View'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('List View'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('shift-card-d')), findsOneWidget);
      expect(find.byKey(const ValueKey('shift-card-o')), findsNothing);
    });

    testWidgets('empty filter result shows the filter-specific message',
        (tester) async {
      await pumpTimeline(tester, shifts: [dayShift(id: 'd')]);
      await tester.tap(find.text('Off'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No shifts match'), findsOneWidget);
    });

    testWidgets('genuinely empty roster shows the add-prompt copy',
        (tester) async {
      await pumpTimeline(tester, shifts: const []);
      expect(find.textContaining('Tap + to add'), findsOneWidget);
    });

    testWidgets('a paused shift shows a Paused badge in the list',
        (tester) async {
      await pumpTimeline(tester, shifts: [
        dayShift(id: 'p').copyWith(isPaused: true, pauseReason: 'Sick'),
      ]);
      // The card stays in the list (history) but is badged as paused.
      expect(find.textContaining('Paused'), findsOneWidget);
      expect(find.byKey(const ValueKey('shift-card-p')), findsOneWidget);
    });

    testWidgets('groups shifts under a sticky month header', (tester) async {
      await pumpTimeline(tester, shifts: [dayShift(id: 'd')]);
      expect(find.text(formatMonthYearHeader(futureDate)), findsOneWidget);
    });

    testWidgets('OFF days render as a slim row (no card); working shifts as cards',
        (tester) async {
      await pumpTimeline(
        tester,
        shifts: [dayShift(id: 'd'), offShift(id: 'o')],
      );
      // Working shift → a Card; OFF day → slim row with no card chrome.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('shift-card-d')),
          matching: find.byType(Card),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('shift-card-o')),
          matching: find.byType(Card),
        ),
        findsNothing,
      );
      expect(find.text('Rest day'), findsOneWidget);
    });

    testWidgets('tapping a shift card opens the edit editor (same as calendar)',
        (tester) async {
      await pumpTimeline(tester, shifts: [dayShift(id: 'a')]);

      await tester.tap(find.byKey(const ValueKey('shift-card-a')));
      await tester.pumpAndSettle();

      expect(find.byType(ShiftEditorModal), findsOneWidget);
      expect(find.text('Edit shift'), findsOneWidget);
    });
  });

  group('month view — data-driven + interactive', () {
    final now = DateTime.now();
    DateTime dayInMonth(int d) => DateTime(now.year, now.month, d);
    Key cellKey(DateTime d) =>
        ValueKey('shift-calendar-cell-${d.year}-${d.month}-${d.day}');
    // table_calendar routes day taps through its table-level gesture handler,
    // so the tap lands on an ancestor of the keyed cell (correct behaviour) —
    // warnIfMissed:false silences the otherwise-noisy hit-test warning.
    Future<void> tapDay(WidgetTester tester, DateTime d) async {
      await tester.tap(find.byKey(cellKey(d)), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets('tapping a blank day opens the chooser → Add shift editor',
        (tester) async {
      // No shifts at all → every cell is blank; tapping one opens the day
      // chooser, and "Add shift" routes to the Add editor.
      await pumpTimeline(tester, shifts: const []);
      await tester.tap(find.text('Month View'));
      await tester.pumpAndSettle();

      await tapDay(tester, dayInMonth(10));
      // The chooser is up; there is no shift row yet, only the add actions.
      expect(find.byKey(const ValueKey('day-shift-0')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('day-add-shift')));
      await tester.pumpAndSettle();

      expect(find.byType(ShiftEditorModal), findsOneWidget);
      expect(find.text('Add shift'), findsOneWidget);
    });

    testWidgets(
        'tapping a day with a Hive shift → chooser lists it → Edit editor',
        (tester) async {
      // The calendar reads the SAME shift list as the List view; a day with a
      // materialised shift edits it in place rather than projecting a pattern.
      await pumpTimeline(
        tester,
        shifts: [dayShift(id: 'mid', date: dayInMonth(15))],
      );
      await tester.tap(find.text('Month View'));
      await tester.pumpAndSettle();

      await tapDay(tester, dayInMonth(15));
      // The chooser lists the existing shift; tapping it edits in place.
      await tester.tap(find.byKey(const ValueKey('day-shift-0')));
      await tester.pumpAndSettle();

      expect(find.byType(ShiftEditorModal), findsOneWidget);
      expect(find.text('Edit shift'), findsOneWidget);
    });

    testWidgets('a day with an activity paints a marker dot in the grid',
        (tester) async {
      final marked = dayInMonth(12);
      await pumpTimeline(
        tester,
        shifts: const [],
        activities: [
          CalendarActivity(
            id: 'act1',
            date: marked,
            title: 'Dentist',
            kind: ActivityKind.event,
          ),
        ],
      );
      await tester.tap(find.text('Month View'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          ValueKey('activity-marker-${marked.year}-${marked.month}-${marked.day}'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the color legend below the grid', (tester) async {
      await pumpTimeline(tester, shifts: [dayShift()]);
      await tester.tap(find.text('Month View'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('calendar-legend')), findsOneWidget);
      expect(find.text('Paused / Leave'), findsOneWidget);
      expect(find.text('Ad-Hoc'), findsOneWidget);
    });
  });
}
