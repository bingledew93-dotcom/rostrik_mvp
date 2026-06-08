import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/app_alarm_repository.dart';
import 'package:rostrik_mvp/ui/create_alarm_sheet.dart';

import '../alarms/fakes.dart';

void main() {
  Future<FakeAppAlarmRepository> pumpSheet(
    WidgetTester tester, {
    List<Shift> shifts = const [],
    AppAlarm? initial,
    AlarmSettings settings = AlarmSettings.defaults,
  }) async {
    final repo = FakeAppAlarmRepository();
    if (initial != null) {
      await repo.upsert(initial);
      repo.callLog.clear();
    }
    addTearDown(repo.dispose);

    // Pump the sheet body directly (no bottom-sheet wrapper) so the test
    // doesn't have to deal with route popping. The sheet reads the global
    // AlarmSettings (default 60-min lead time) to compute the hero clock, and
    // the roster `List<Shift>` for the linked shift's start time — empty by
    // default, so the per-type fallback (Day → 07:00) applies.
    //
    // No previewer is injected by default — the real one creates its
    // AudioPlayer lazily (only on a tone tap), so tests that never tap a tone
    // touch no audio plugin.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppAlarmRepository>.value(value: repo),
          Provider<AlarmSettings>.value(value: settings),
          Provider<List<Shift>>.value(value: shifts),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CreateAlarmSheet(initial: initial),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  group('default state', () {
    testWidgets('opens on follows-rotation showing the calculated fire clock',
        (tester) async {
      await pumpSheet(tester);

      // Default repeat is follows-rotation, default lead mode is "use global"
      // (60 min). Empty roster → Day default 07:00; 07:00 − 1h = 06:00 → the
      // hero is the calculated CLOCK time, not the offset.
      expect(find.text('06:00 AM'), findsOneWidget);
      // The offset is demoted to the caption.
      expect(find.textContaining('1h before Day shifts'), findsOneWidget);
      // Default label.
      expect(find.widgetWithText(TextField, 'Wake Up'), findsOneWidget);
      // Follows-rotation reveals the linked-shift section.
      expect(find.text('Linked shift'), findsOneWidget);
    });

    testWidgets('one-time repeat hides the lead-mode + linked-shift sections',
        (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.text('One time'));
      await tester.pumpAndSettle();
      expect(find.text('Linked shift'), findsNothing);
      expect(find.text('Custom'), findsNothing);
      // One-time hero is its own picked clock time (default 07:00) in AM/PM.
      expect(find.text('07:00 AM'), findsOneWidget);
    });

    testWidgets('switching back to follows-rotation re-reveals the sections',
        (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.text('One time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rotation'));
      await tester.pumpAndSettle();
      expect(find.text('Linked shift'), findsOneWidget);
    });
  });

  group('lead-time mode', () {
    testWidgets('lead-mode segmented button only shows under follows-rotation',
        (tester) async {
      await pumpSheet(tester);
      expect(find.text('Use default (60 min)'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      await tester.tap(find.text('One time'));
      await tester.pumpAndSettle();
      expect(find.text('Use default (60 min)'), findsNothing);
      expect(find.text('Custom'), findsNothing);
    });

    testWidgets('tapping "Custom" swaps the hero to the custom-offset clock',
        (tester) async {
      await pumpSheet(tester);
      // Default "use global" hero: 07:00 − 1h = 06:00.
      expect(find.text('06:00 AM'), findsOneWidget);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      // Default custom offset is 90 min → 07:00 − 1h30 = 05:30.
      expect(find.text('05:30 AM'), findsOneWidget);
      expect(find.text('06:00 AM'), findsNothing);
      // Offset still visible, demoted to the caption.
      expect(find.textContaining('1h 30m before Day shifts'), findsOneWidget);
    });

    testWidgets('the hero reflects the linked shift\'s ACTUAL roster start',
        (tester) async {
      // A real Day shift starting 06:00 (not the 07:00 default) → 06:00 − 1h
      // global = 05:00 AM.
      await pumpSheet(tester, shifts: [
        Shift(
          id: 'd1',
          date: DateTime(2030, 1, 1),
          type: ShiftType.day,
          startMinutes: 6 * 60,
          endMinutes: 14 * 60,
        ),
      ]);
      expect(find.text('05:00 AM'), findsOneWidget);
    });

    testWidgets('the offset dialog shows the calculated target clock',
        (tester) async {
      await pumpSheet(tester);
      // Switch to custom so the hero becomes tappable, then open the dialog.
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
          find.byKey(const ValueKey('create-alarm-hero-clock')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-hero-clock')));
      await tester.pumpAndSettle();

      // Day default 07:00 − default custom offset 90 = 05:30. Scope to the
      // dialog — the sheet hero behind it also reads 05:30 in custom mode.
      expect(
        find.byKey(const ValueKey('offset-picker-clock')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('05:30 AM'),
        ),
        findsOneWidget,
      );
    });
  });

  group('save', () {
    testWidgets('Save upserts a followsRotation alarm with the linked type',
        (tester) async {
      final repo = await pumpSheet(tester);
      await tester.ensureVisible(find.text('Night'));
      await tester.tap(find.text('Night'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('create-alarm-save')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
      await tester.pumpAndSettle();

      final stored = (await repo.getAll()).single;
      expect(stored.repeatType, AppAlarmRepeatType.followsRotation);
      expect(stored.linkedShiftType, ShiftType.night);
      expect(stored.label, 'Wake Up');
      expect(stored.enabled, isTrue);
    });

    testWidgets('default lead-time mode stores a null offset (use global)',
        (tester) async {
      final repo = await pumpSheet(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('create-alarm-save')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
      await tester.pumpAndSettle();

      final stored = (await repo.getAll()).single;
      expect(stored.repeatType, AppAlarmRepeatType.followsRotation);
      expect(stored.relativeOffsetMinutes, isNull,
          reason: 'null offset means "use the global lead time"');
      expect(stored.linkedShiftType, ShiftType.day);
    });

    testWidgets('Custom mode persists the per-alarm offset override',
        (tester) async {
      final repo = await pumpSheet(tester);
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('create-alarm-save')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
      await tester.pumpAndSettle();

      final stored = (await repo.getAll()).single;
      expect(stored.relativeOffsetMinutes, 90,
          reason: 'default custom offset value should be persisted');
      expect(stored.linkedShiftType, ShiftType.day);
    });

    testWidgets('Save on a one-time alarm stores null link AND null offset',
        (tester) async {
      // A user toggles Custom, then switches to One Time — the stored record
      // must not carry a stale shift link or a confusing offset.
      final repo = await pumpSheet(tester);
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('One time'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('create-alarm-save')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
      await tester.pumpAndSettle();

      final stored = (await repo.getAll()).single;
      expect(stored.repeatType, AppAlarmRepeatType.oneTime);
      expect(stored.linkedShiftType, isNull);
      expect(stored.relativeOffsetMinutes, isNull);
    });

    testWidgets('defaults to non-critical', (tester) async {
      final repo = await pumpSheet(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('create-alarm-save')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
      await tester.pumpAndSettle();
      expect((await repo.getAll()).single.isCriticalShift, isFalse);
    });

    testWidgets('the Critical-shift toggle persists isCriticalShift',
        (tester) async {
      final repo = await pumpSheet(tester);
      await tester.tap(find.byKey(const ValueKey('create-alarm-critical')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('create-alarm-save')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
      await tester.pumpAndSettle();
      expect((await repo.getAll()).single.isCriticalShift, isTrue);
    });

    testWidgets('defaults to the classic sound', (tester) async {
      // Audio defaults to bundled 'classic' (the Ringtone row's "Rostrik
      // Classic") — the per-tone bundled chips were removed in the Phase-2b
      // audio consolidation; custom tones are chosen via the Ringtone row.
      final repo = await pumpSheet(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('create-alarm-save')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
      await tester.pumpAndSettle();
      expect((await repo.getAll()).single.soundKey, 'classic');
    });

    testWidgets('empty label defaults to "Alarm"', (tester) async {
      final repo = await pumpSheet(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create-alarm-label')),
        '',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('create-alarm-save')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
      await tester.pumpAndSettle();

      final stored = (await repo.getAll()).single;
      expect(stored.label, 'Alarm');
    });
  });

  group('weekly repeat', () {
    Future<FakeAppAlarmRepository> openWeekly(WidgetTester tester) async {
      final repo = await pumpSheet(tester);
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('reveals the Mon–Sun day chips and hides lead/linked sections',
        (tester) async {
      await openWeekly(tester);
      expect(find.text('Repeat on'), findsOneWidget);
      for (var d = 1; d <= 7; d++) {
        expect(find.byKey(ValueKey('create-alarm-weekday-$d')), findsOneWidget);
      }
      expect(find.text('Linked shift'), findsNothing);
      // Weekly rings at its absolute picked time (default 07:00).
      expect(find.text('07:00 AM'), findsOneWidget);
    });

    testWidgets('Save is disabled until at least one day is picked',
        (tester) async {
      await openWeekly(tester);
      // No day selected yet.
      expect(find.text('Pick at least one day'), findsOneWidget);
      final saveBtn = tester.widget<FilledButton>(
        find.byKey(const ValueKey('create-alarm-save')),
      );
      expect(saveBtn.onPressed, isNull, reason: 'no day → Save disabled');
    });

    testWidgets('picking days builds a weekly alarm with the right mask',
        (tester) async {
      final repo = await openWeekly(tester);
      // Mon (1), Wed (3), Fri (5).
      await tester.tap(find.byKey(const ValueKey('create-alarm-weekday-1')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-weekday-3')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-weekday-5')));
      await tester.pumpAndSettle();
      // Caption collapses to the friendly form.
      expect(find.text('Mon, Wed, Fri'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('create-alarm-save')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
      await tester.pumpAndSettle();

      final stored = (await repo.getAll()).single;
      expect(stored.repeatType, AppAlarmRepeatType.weekly);
      // bits for 1,3,5 = 0b10101 = 21.
      expect(stored.weekdaysBitmask, 1 | 1 << 2 | 1 << 4);
      expect(stored.linkedShiftType, isNull);
      expect(stored.relativeOffsetMinutes, isNull);
    });
  });

  group('auto-delete (one-time)', () {
    testWidgets('the toggle is one-time only', (tester) async {
      await pumpSheet(tester);
      // Hidden under follows-rotation and weekly.
      expect(find.byKey(const ValueKey('create-alarm-autodelete')), findsNothing);
      await tester.tap(find.text('One time'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('create-alarm-autodelete')),
        findsOneWidget,
      );
    });

    testWidgets('enabling it persists autoDeleteAfterFiring', (tester) async {
      final repo = await pumpSheet(tester);
      await tester.tap(find.text('One time'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create-alarm-autodelete')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('create-alarm-save')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
      await tester.pumpAndSettle();

      final stored = (await repo.getAll()).single;
      expect(stored.repeatType, AppAlarmRepeatType.oneTime);
      expect(stored.autoDeleteAfterFiring, isTrue);
    });
  });

  group('edit mode', () {
    AppAlarm weekly() => AppAlarm(
          id: 'edit-me',
          minutesOfDay: 6 * 60 + 30,
          label: 'Gym',
          repeatType: AppAlarmRepeatType.weekly,
          enabled: false,
          weekdaysBitmask: 1 | 1 << 2, // Mon + Wed
          soundKey: 'siren',
        );

    testWidgets('header reads "Edit alarm" and pre-populates every field',
        (tester) async {
      await pumpSheet(tester, initial: weekly());
      expect(find.text('Edit alarm'), findsOneWidget);
      // Label prefilled.
      expect(find.widgetWithText(TextField, 'Gym'), findsOneWidget);
      // Weekly hero = 06:30 AM, and its days are pre-checked.
      expect(find.text('06:30 AM'), findsOneWidget);
      expect(find.text('Mon, Wed'), findsOneWidget);
      final mon = tester.widget<FilterChip>(
        find.byKey(const ValueKey('create-alarm-weekday-1')),
      );
      expect(mon.selected, isTrue);
    });

    testWidgets('Save updates in place under the same id (no duplicate)',
        (tester) async {
      final repo = await pumpSheet(tester, initial: weekly());
      await tester.enterText(
        find.byKey(const ValueKey('create-alarm-label')),
        'Morning gym',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('create-alarm-save')));
      await tester.tap(find.byKey(const ValueKey('create-alarm-save')));
      await tester.pumpAndSettle();

      final all = await repo.getAll();
      expect(all, hasLength(1), reason: 'same id → update, not duplicate');
      expect(all.single.id, 'edit-me');
      expect(all.single.label, 'Morning gym');
      // Disabled state preserved across the edit.
      expect(all.single.enabled, isFalse);
    });
  });

  group('custom ringtone row', () {
    testWidgets('renders and defaults to the bundled Classic tone label',
        (tester) async {
      await pumpSheet(tester);
      expect(
        find.byKey(const ValueKey('create-alarm-ringtone-row')),
        findsOneWidget,
      );
      expect(find.text('Ringtone'), findsOneWidget);
      // No custom override → the row shows the selected bundled tone's label
      // ('classic' default → 'Classic'). The per-tone chips were consolidated
      // into the Ringtone chooser; bundled tones are picked there now.
      expect(find.text('Classic'), findsOneWidget);
    });

    testWidgets('shows the per-alarm custom ringtone name when one is set',
        (tester) async {
      // Custom ringtones are per-alarm now — the name comes off the AppAlarm
      // being edited, and takes precedence over the bundled tone label.
      await pumpSheet(
        tester,
        initial: AppAlarm(
          id: 'edit-tone',
          minutesOfDay: 6 * 60,
          label: 'Gym',
          repeatType: AppAlarmRepeatType.oneTime,
          customRingtoneUri: '/cache/midnight.mp3',
          customRingtoneName: 'midnight.mp3',
          ringtoneSource: RingtoneSource.vault,
        ),
      );
      expect(find.text('midnight.mp3'), findsOneWidget);
      expect(find.text('Classic'), findsNothing);
    });

    testWidgets('renders the global Vibrate toggle (default on)',
        (tester) async {
      await pumpSheet(tester);
      final tile = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('create-alarm-vibrate')),
      );
      expect(tile.value, isTrue);
    });
  });
}
