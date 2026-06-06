import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_cycle.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/ui/timeline/timeline_screen.dart';

import '../alarms/fakes.dart';

void main() {
  // Far-future date keeps shifts "upcoming" independent of wall-clock time.
  final futureDate = DateTime.now().add(const Duration(days: 7));

  Future<void> pumpTimeline(
    WidgetTester tester, {
    required List<Shift> shifts,
    List<ShiftCycle> cycles = const [],
  }) async {
    final repo = FakeShiftRepository();
    for (final s in shifts) {
      await repo.upsert(s);
    }
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // The month-view day-tap + add-shift FAB read this; harmless here.
          Provider<ShiftRepository>.value(value: repo),
          // List body watches shifts; month body watches cycles. Both bodies
          // are built under the IndexedStack, so both providers are required.
          Provider<List<Shift>>.value(value: shifts),
          Provider<List<ShiftCycle>>.value(value: cycles),
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

    testWidgets('tapping Month View swaps to the calendar grid',
        (tester) async {
      // Empty cycle list → Month view renders the calm "no rotation" state.
      await pumpTimeline(tester, shifts: [dayShift()]);

      await tester.tap(find.text('Month View'));
      await tester.pumpAndSettle();

      expect(stackIndex(tester), 1);
      expect(find.text('No active rotation'), findsOneWidget);
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
  });
}
