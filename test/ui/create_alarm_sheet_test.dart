import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/app_alarm_repository.dart';
import 'package:rostrik_mvp/ui/create_alarm_sheet.dart';

import '../alarms/fakes.dart';

void main() {
  Future<FakeAppAlarmRepository> pumpSheet(WidgetTester tester) async {
    final repo = FakeAppAlarmRepository();
    addTearDown(repo.dispose);

    // Pump the sheet body directly (no bottom-sheet wrapper) so the
    // test doesn't have to deal with route popping. Scaffold is needed
    // because the inner widgets read `Theme.of(context)` and modal
    // bottom-sheet defaults.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppAlarmRepository>.value(value: repo),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CreateAlarmSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  group('default state', () {
    testWidgets('opens with the default time, label, and repeat mode',
        (tester) async {
      await pumpSheet(tester);

      // Default time is 07:00.
      expect(find.text('07:00'), findsOneWidget);
      // Default label.
      expect(find.widgetWithText(TextField, 'Wake Up'), findsOneWidget);
      // Default repeat mode (Follows rotation) reveals the linked-shift
      // section.
      expect(find.text('Linked shift'), findsOneWidget);
    });

    testWidgets('one-time repeat hides the linked-shift segmented button',
        (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.text('One time'));
      await tester.pumpAndSettle();
      expect(find.text('Linked shift'), findsNothing);
    });

    testWidgets('switching back to follows-rotation re-reveals the link',
        (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.text('One time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Follows rotation'));
      await tester.pumpAndSettle();
      expect(find.text('Linked shift'), findsOneWidget);
    });
  });

  group('relative-time toggle', () {
    testWidgets(
      'time-mode segmented button only shows under follows-rotation',
      (tester) async {
        await pumpSheet(tester);
        // Default repeat = follows-rotation, so the toggle is present.
        expect(find.text('Exact Time'), findsOneWidget);
        expect(find.text('Time Before Shift'), findsOneWidget);

        // Switch to one-time → toggle disappears.
        await tester.tap(find.text('One time'));
        await tester.pumpAndSettle();
        expect(find.text('Exact Time'), findsNothing);
        expect(find.text('Time Before Shift'), findsNothing);
      },
    );

    testWidgets(
      'tapping "Time Before Shift" swaps the hero display from HH:MM to "- Xh Ym"',
      (tester) async {
        await pumpSheet(tester);
        // Default exact-time display.
        expect(find.text('07:00'), findsOneWidget);

        await tester.tap(find.text('Time Before Shift'));
        await tester.pumpAndSettle();

        // Default offset is 90 min → "- 1h 30m".
        expect(find.text('- 1h 30m'), findsOneWidget);
        // And the HH:MM display is gone.
        expect(find.text('07:00'), findsNothing);
      },
    );
  });

  group('save', () {
    testWidgets(
      'Save upserts a followsRotation alarm with the linked shift type',
      (tester) async {
        final repo = await pumpSheet(tester);
        // Pick the Night option in the linked-shift row.
        await tester.tap(find.text('Night'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
        await tester.pumpAndSettle();

        final stored = (await repo.getAll()).single;
        expect(stored.repeatType, AppAlarmRepeatType.followsRotation);
        expect(stored.linkedShiftType, ShiftType.night);
        expect(stored.minutesOfDay, 7 * 60);
        expect(stored.label, 'Wake Up');
        expect(stored.enabled, isTrue);
      },
    );

    testWidgets(
      'Save on a one-time alarm stores null linkedShiftType',
      (tester) async {
        final repo = await pumpSheet(tester);
        await tester.tap(find.text('One time'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
        await tester.pumpAndSettle();

        final stored = (await repo.getAll()).single;
        expect(stored.repeatType, AppAlarmRepeatType.oneTime);
        expect(stored.linkedShiftType, isNull,
            reason: 'one-time alarms must not carry a stale shift link');
      },
    );

    testWidgets(
      'Save with "Time Before Shift" persists isRelativeTime=true and the offset',
      (tester) async {
        final repo = await pumpSheet(tester);
        await tester.tap(find.text('Time Before Shift'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
        await tester.pumpAndSettle();

        final stored = (await repo.getAll()).single;
        expect(stored.isRelativeTime, isTrue);
        expect(stored.relativeOffsetMinutes, 90,
            reason: 'default offset value should be persisted');
        expect(stored.linkedShiftType, ShiftType.day,
            reason: 'follows-rotation alarms still carry the link');
      },
    );

    testWidgets(
      'Flipping to one-time after enabling relative forces isRelativeTime=false',
      (tester) async {
        // Defends a small-but-real footgun: a user toggles relative ON,
        // then switches the repeat mode to One Time. The stored
        // record should NOT carry a stale isRelativeTime=true flag —
        // the sync service would ignore it but persisting confusing
        // state is a code smell.
        final repo = await pumpSheet(tester);
        await tester.tap(find.text('Time Before Shift'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('One time'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
        await tester.pumpAndSettle();

        final stored = (await repo.getAll()).single;
        expect(stored.repeatType, AppAlarmRepeatType.oneTime);
        expect(stored.isRelativeTime, isFalse);
      },
    );

    testWidgets('empty label defaults to "Alarm"', (tester) async {
      final repo = await pumpSheet(tester);
      // Clear the field.
      await tester.enterText(
        find.byKey(const ValueKey('create-alarm-label')),
        '',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
      await tester.pumpAndSettle();

      final stored = (await repo.getAll()).single;
      expect(stored.label, 'Alarm');
    });
  });
}
