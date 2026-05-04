import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/ui/roster_screen.dart';
import 'package:table_calendar/table_calendar.dart';

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

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShiftRepository>.value(value: repo),
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

  group('mute toggle visibility', () {
    testWidgets('unmuted upcoming shift shows the mute icon (and the bell)',
        (tester) async {
      await pumpRoster(tester, initialShifts: [dayShift()]);

      expect(find.byTooltip('Mute alarm'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      // Bell is also visible because the alarm WILL fire.
      expect(find.byIcon(Icons.alarm), findsOneWidget);
    });

    testWidgets(
        'muted shift shows the unmute icon, no bell, and dimmed opacity',
        (tester) async {
      await pumpRoster(tester, initialShifts: [dayShift(isMuted: true)]);

      expect(find.byTooltip('Unmute alarm'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
      // The UI/engine drift fix: muted shifts must not advertise an alarm
      // the engine has cancelled.
      expect(find.byIcon(Icons.alarm), findsNothing);

      // Confirm the dim. Find the Opacity that wraps the muted Card.
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byTooltip('Unmute alarm'),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, lessThan(1.0));
      expect(opacity.opacity, greaterThan(0.0));
    });

    testWidgets('OFF shift shows neither alarm bell nor mute toggle',
        (tester) async {
      await pumpRoster(
        tester,
        initialShifts: [
          Shift(
            id: 'off',
            date: futureDate,
            type: ShiftType.off,
            startMinutes: 0,
            endMinutes: 0,
          ),
        ],
      );

      expect(find.byIcon(Icons.alarm), findsNothing);
      expect(find.byTooltip('Mute alarm'), findsNothing);
      expect(find.byTooltip('Unmute alarm'), findsNothing);
    });
  });

  group('mute icon → confirm mode entry', () {
    testWidgets('tapping the mute icon does NOT mutate the repo', (tester) async {
      final repo = await pumpRoster(tester, initialShifts: [dayShift()]);

      await tester.tap(find.byTooltip('Mute alarm'));
      await tester.pump();

      // Tap alone must never commit. The shift must remain unmuted; only
      // a completed swipe is allowed to flip the flag.
      final stored = await repo.getById('a');
      expect(stored!.isMuted, isFalse);
    });

    testWidgets('tapping the mute icon enters swipe-to-confirm mode',
        (tester) async {
      await pumpRoster(tester, initialShifts: [dayShift()]);

      await tester.tap(find.byTooltip('Mute alarm'));
      await tester.pump();

      expect(find.text('Swipe to mute'), findsOneWidget);
      expect(find.byKey(const ValueKey('swipe-thumb')), findsOneWidget);
      expect(find.byTooltip('Cancel'), findsOneWidget);

      // The original mute icon is gone — the whole card was replaced.
      expect(find.byTooltip('Mute alarm'), findsNothing);
    });

    testWidgets('muted card shows the unmute confirm prompt', (tester) async {
      await pumpRoster(tester, initialShifts: [dayShift(isMuted: true)]);

      await tester.tap(find.byTooltip('Unmute alarm'));
      await tester.pump();

      expect(find.text('Swipe to unmute'), findsOneWidget);
    });
  });

  group('swipe gesture → commit / cancel semantics', () {
    testWidgets('full drag past threshold commits the mute upsert',
        (tester) async {
      final repo = await pumpRoster(tester, initialShifts: [dayShift()]);

      await tester.tap(find.byTooltip('Mute alarm'));
      await tester.pump();

      // Drag the thumb well past the completion threshold. The widget
      // clamps internally, so over-dragging is safe.
      await tester.drag(
        find.byKey(const ValueKey('swipe-thumb')),
        const Offset(1200, 0),
      );
      await tester.pumpAndSettle();

      // Stream re-emits, _ShiftCardState rebuilds back to normal mode,
      // and the trailing icon is now the unmute one.
      final stored = await repo.getById('a');
      expect(stored!.isMuted, isTrue);
      expect(find.byTooltip('Unmute alarm'), findsOneWidget);
      expect(find.text('Swipe to mute'), findsNothing);
    });

    testWidgets('short drag below threshold does NOT commit and stays in confirm mode',
        (tester) async {
      final repo = await pumpRoster(tester, initialShifts: [dayShift()]);

      await tester.tap(find.byTooltip('Mute alarm'));
      await tester.pump();

      // Tiny drag, well below the 85% threshold.
      await tester.drag(
        find.byKey(const ValueKey('swipe-thumb')),
        const Offset(8, 0),
      );
      await tester.pumpAndSettle();

      final stored = await repo.getById('a');
      expect(stored!.isMuted, isFalse,
          reason: 'release before threshold must never commit');

      // Slider stays in place so the user can retry without re-tapping
      // the mute icon — important for sleep-impaired retry attempts.
      expect(find.text('Swipe to mute'), findsOneWidget);
      expect(find.byTooltip('Cancel'), findsOneWidget);
    });

    testWidgets('cancel × button exits confirm mode without mutating',
        (tester) async {
      final repo = await pumpRoster(tester, initialShifts: [dayShift()]);

      await tester.tap(find.byTooltip('Mute alarm'));
      await tester.pump();

      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();

      final stored = await repo.getById('a');
      expect(stored!.isMuted, isFalse);
      expect(find.text('Swipe to mute'), findsNothing);
      // We're back to the normal card.
      expect(find.byTooltip('Mute alarm'), findsOneWidget);
    });

    testWidgets('full drag past threshold on a muted shift commits the unmute',
        (tester) async {
      final repo =
          await pumpRoster(tester, initialShifts: [dayShift(isMuted: true)]);

      await tester.tap(find.byTooltip('Unmute alarm'));
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('swipe-thumb')),
        const Offset(1200, 0),
      );
      await tester.pumpAndSettle();

      final stored = await repo.getById('a');
      expect(stored!.isMuted, isFalse);
      expect(find.byTooltip('Mute alarm'), findsOneWidget);
    });
  });

  group('confirm mode hygiene', () {
    testWidgets(
      'swipe-delete background and onDismissed are not active in confirm mode',
      (tester) async {
        // Regression guard: the Dismissible (right-to-left delete) should
        // disappear while the user is confirming a mute, so a fumbled
        // gesture in the slider can't accidentally delete the shift.
        await pumpRoster(tester, initialShifts: [dayShift()]);

        await tester.tap(find.byTooltip('Mute alarm'));
        await tester.pump();

        expect(find.byIcon(Icons.delete_outline), findsNothing);
      },
    );
  });

  group('view mode toggle', () {
    testWidgets('defaults to Timeline (shifts visible, calendar hidden)',
        (tester) async {
      await pumpRoster(tester, initialShifts: [dayShift()]);

      // Card visible — we're on the timeline.
      expect(find.byKey(const ValueKey('shift-card-a')), findsOneWidget);
      expect(find.byType(TableCalendar<Shift>), findsNothing);
    });

    testWidgets('selecting Calendar swaps the timeline for the grid',
        (tester) async {
      await pumpRoster(tester, initialShifts: [dayShift()]);

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      expect(find.byType(TableCalendar<Shift>), findsOneWidget);
      // The timeline list is no longer in the tree.
      expect(find.byKey(const ValueKey('shift-card-a')), findsNothing);
    });

    testWidgets('toggling back to Timeline shows the list again',
        (tester) async {
      await pumpRoster(tester, initialShifts: [dayShift()]);

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();

      expect(find.byType(TableCalendar<Shift>), findsNothing);
      expect(find.byKey(const ValueKey('shift-card-a')), findsOneWidget);
    });

    testWidgets('the AppBar/FAB are not duplicated by the toggle',
        (tester) async {
      // Cheap sanity: the orchestrator should host one AppBar and one FAB
      // regardless of which view is selected. Catches accidental nesting
      // if a future refactor wraps each view in its own Scaffold.
      await pumpRoster(tester, initialShifts: [dayShift()]);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
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
