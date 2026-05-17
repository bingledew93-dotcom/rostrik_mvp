import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/logic/shift_generator.dart';
import 'package:rostrik_mvp/ui/pattern_picker_screen.dart';
import 'package:rostrik_mvp/ui/roster_screen.dart';

import '../alarms/fakes.dart';

void main() {
  // The widgets need a stable "now" for `_alarmFor` to consider shifts
  // upcoming. Using a far-future date is the simplest way to keep tests
  // independent of wall-clock time without injecting a clock into the UI.
  final futureDate = DateTime.now().add(const Duration(days: 7));

  Future<FakeShiftRepository> pumpRoster(
    WidgetTester tester, {
    required List<Shift> initialShifts,
  }) async {
    final repo = FakeShiftRepository();
    for (final s in initialShifts) {
      await repo.upsert(s);
    }
    addTearDown(repo.dispose);
    final cycleRepo = FakeShiftCycleRepository();
    addTearDown(cycleRepo.dispose);

    final generator = ShiftGenerator(shifts: repo, cycles: cycleRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShiftRepository>.value(value: repo),
          // RosterScreen's new AppBar action pushes PatternPickerScreen,
          // which reads ShiftGenerator from context — supply it here so
          // the route can build successfully if the test navigates to it.
          Provider<ShiftGenerator>.value(value: generator),
          StreamProvider<List<Shift>>(
            create: (_) => repo.watchInRange(
              DateTime(2020),
              DateTime(2099),
            ),
            initialData: const [],
          ),
          Provider<AlarmSettings>.value(
            value: const AlarmSettings(leadTime: Duration(hours: 1)),
          ),
        ],
        child: const MaterialApp(home: RosterScreen()),
      ),
    );
    // First pump = StreamProvider subscribes and gets initialData (empty).
    // Allow the fake's async getInRange microtask to resolve so the real
    // initial snapshot reaches the widget tree.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return repo;
  }

  Shift dayShift({
    String id = 'a',
    bool isMuted = false,
    DateTime? date,
  }) =>
      Shift(
        id: id,
        date: date ?? futureDate,
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
        isMuted: isMuted,
      );

  Shift offShift({String id = 'off', DateTime? date}) => Shift(
        id: id,
        date: date ?? futureDate,
        type: ShiftType.off,
        startMinutes: 0,
        endMinutes: 0,
      );

  // Tests for the mute toggle / swipe-to-confirm / confirm-mode-hygiene
  // surface used to live here. Those features were stripped from the
  // Roster when alarm CRUD moved to the dedicated Alarms tab — see
  // `lib/ui/alarms_screen.dart` and the plan dated 2026-05-15. The
  // corresponding tests live in `test/ui/alarms_screen_test.dart` now.

  group('AppBar — pattern picker entry', () {
    testWidgets('the new "Choose a pattern" icon launches PatternPickerScreen',
        (tester) async {
      // Cheap regression guard: if the AppBar icon ever loses its
      // onPressed (or gets miswired to TemplateScreen), this fails.
      // The screen is identified by its type plus the "Build custom
      // roster" escape-hatch tile (a stable element in the new
      // categorized picker — see pattern_picker_screen.dart).
      await pumpRoster(tester, initialShifts: const []);

      await tester.tap(find.byTooltip('Choose a pattern'));
      await tester.pumpAndSettle();

      expect(find.byType(PatternPickerScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('pattern-picker-build-custom')),
        findsOneWidget,
      );
    });
  });

  // Pre-Calendar-promotion this file had a "view mode toggle" group
  // exercising the Calendar / Timeline switch inside the Roster tab.
  // The Calendar moved to its own top-level tab — see
  // `test/ui/calendar/` for its coverage — and the toggle disappeared
  // with it. The single chassis-sanity assertion that used to live
  // inside that group (one AppBar, one FAB) is preserved below.

  group('Roster chassis sanity', () {
    testWidgets('renders exactly one AppBar and one FAB', (tester) async {
      await pumpRoster(tester, initialShifts: [dayShift()]);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('the timeline shows shift cards directly (no toggle)',
        (tester) async {
      await pumpRoster(tester, initialShifts: [dayShift()]);
      expect(find.byKey(const ValueKey('shift-card-a')), findsOneWidget);
    });
  });

  group('shift filter chips', () {
    testWidgets('All chip shows every shift', (tester) async {
      await pumpRoster(
        tester,
        initialShifts: [dayShift(id: 'd'), offShift(id: 'o')],
      );

      // All is the default selection.
      expect(find.byKey(const ValueKey('shift-card-d')), findsOneWidget);
      expect(find.byKey(const ValueKey('shift-card-o')), findsOneWidget);
    });

    testWidgets('Work chip filters out OFF shifts', (tester) async {
      await pumpRoster(
        tester,
        initialShifts: [dayShift(id: 'd'), offShift(id: 'o')],
      );

      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('shift-card-d')), findsOneWidget);
      expect(find.byKey(const ValueKey('shift-card-o')), findsNothing);
    });

    testWidgets('Off chip keeps only OFF shifts', (tester) async {
      await pumpRoster(
        tester,
        initialShifts: [dayShift(id: 'd'), offShift(id: 'o')],
      );

      await tester.tap(find.text('Off'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('shift-card-d')), findsNothing);
      expect(find.byKey(const ValueKey('shift-card-o')), findsOneWidget);
    });

    testWidgets(
        'empty filter result shows the filter-specific empty message',
        (tester) async {
      // Roster has only a day shift; selecting Off should hide everything
      // and show the filter-specific copy (NOT the "Tap + to add one"
      // message reserved for a genuinely empty roster).
      await pumpRoster(tester, initialShifts: [dayShift(id: 'd')]);

      await tester.tap(find.text('Off'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No shifts match'), findsOneWidget);
      expect(find.textContaining('Tap + to add'), findsNothing);
    });

    testWidgets(
      'genuinely empty roster still shows the original add-prompt copy',
      (tester) async {
        await pumpRoster(tester, initialShifts: const []);
        // No filter activated; should still see the historical empty
        // state copy so users opening a fresh app aren't told to "match
        // a filter" when no filter is at fault.
        expect(find.textContaining('Tap + to add'), findsOneWidget);
      },
    );

    testWidgets(
      'returning to All restores the full list after a Work filter',
      (tester) async {
        // Round-trip: All → Work → All. Pins that filter changes are
        // pure UI state and don't permanently mutate the underlying
        // shift list.
        await pumpRoster(
          tester,
          initialShifts: [dayShift(id: 'd'), offShift(id: 'o')],
        );

        await tester.tap(find.text('Work'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('shift-card-o')), findsNothing);

        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('shift-card-d')), findsOneWidget);
        expect(find.byKey(const ValueKey('shift-card-o')), findsOneWidget);
      },
    );
  });
}
