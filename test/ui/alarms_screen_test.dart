import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/app_alarm_repository.dart';
import 'package:rostrik_mvp/ui/alarms_screen.dart';

import '../alarms/fakes.dart';

void main() {
  Future<FakeAppAlarmRepository> pumpAlarms(
    WidgetTester tester, {
    required List<AppAlarm> seed,
    List<Shift> shifts = const [],
  }) async {
    final repo = FakeAppAlarmRepository();
    for (final a in seed) {
      await repo.upsert(a);
    }
    // The Switch toggling path captures upserts after the screen pumps,
    // so reset the call log to keep "what did the UI do" assertions
    // unambiguous.
    repo.callLog.clear();
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppAlarmRepository>.value(value: repo),
          // The create-alarm sheet (opened from the FAB) reads the global
          // lead time; the cards use it to compute the fire clock too.
          Provider<AlarmSettings>.value(value: AlarmSettings.defaults),
          // Each card reads the roster to resolve its linked shift's start
          // time; empty → per-type default (Day 07:00, Night 22:00, etc.).
          Provider<List<Shift>>.value(value: shifts),
          StreamProvider<List<AppAlarm>>(
            create: (_) => repo.watch(),
            initialData: seed,
          ),
        ],
        child: const MaterialApp(home: AlarmsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return repo;
  }

  AppAlarm mk({
    required String id,
    required int minutesOfDay,
    required String label,
    AppAlarmRepeatType repeatType = AppAlarmRepeatType.followsRotation,
    bool enabled = true,
    ShiftType? linkedShiftType,
    int? relativeOffsetMinutes,
    int weekdaysBitmask = 0,
    bool autoDeleteAfterFiring = false,
    bool isExactTime = false,
    int? exactTimeMinutes,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: minutesOfDay,
        label: label,
        repeatType: repeatType,
        enabled: enabled,
        linkedShiftType: linkedShiftType,
        relativeOffsetMinutes: relativeOffsetMinutes,
        weekdaysBitmask: weekdaysBitmask,
        autoDeleteAfterFiring: autoDeleteAfterFiring,
        isExactTime: isExactTime,
        exactTimeMinutes: exactTimeMinutes,
      );

  group('empty state', () {
    testWidgets('renders "No alarms yet" copy when the list is empty',
        (tester) async {
      await pumpAlarms(tester, seed: const []);
      expect(find.text('No alarms yet.'), findsOneWidget);
      expect(find.text('Tap + to add one.'), findsOneWidget);
    });

    testWidgets('the FAB is present even when empty', (tester) async {
      await pumpAlarms(tester, seed: const []);
      expect(find.byKey(const ValueKey('alarms-add-fab')), findsOneWidget);
    });
  });

  group('alarm card rendering', () {
    testWidgets(
      'hero is the calculated fire clock; offset moves to the subtitle',
      (tester) async {
        await pumpAlarms(
          tester,
          seed: [
            // Follows-rotation Day on the global 60-min lead. Empty roster →
            // Day default 07:00; 07:00 − 1h = 06:00 → hero "06:00 AM".
            mk(
              id: 'a',
              minutesOfDay: 6 * 60,
              label: 'Wake Up - Day Shift',
              repeatType: AppAlarmRepeatType.followsRotation,
              linkedShiftType: ShiftType.day,
            ),
            mk(
              id: 'b',
              minutesOfDay: 22 * 60 + 30,
              label: 'Bed time',
              repeatType: AppAlarmRepeatType.oneTime,
            ),
          ],
        );

        // Follows-rotation hero is the CALCULATED clock, not the offset.
        expect(find.text('06:00 AM'), findsOneWidget);
        // The offset is demoted to the subtitle.
        expect(find.textContaining('1h before Day shifts'), findsOneWidget);
        expect(find.text('Default'), findsNothing);
        // One-time keeps its absolute clock time (AM/PM) + simple descriptor.
        expect(find.text('10:30 PM'), findsOneWidget);
        expect(find.text('Rings one time only'), findsOneWidget);
        expect(find.text('Wake Up - Day Shift'), findsOneWidget);
        expect(find.text('Bed time'), findsOneWidget);
      },
    );

    testWidgets('an override card computes the clock from its own offset',
        (tester) async {
      await pumpAlarms(
        tester,
        seed: [
          mk(
            id: 'a',
            minutesOfDay: 6 * 60,
            label: 'Early wake',
            linkedShiftType: ShiftType.night,
            relativeOffsetMinutes: 90,
          ),
        ],
      );
      // Night default 22:00 − 1h30 = 20:30 → "08:30 PM".
      expect(find.text('08:30 PM'), findsOneWidget);
      // Offset (with its shift) in the subtitle, no "default" marker.
      expect(find.textContaining('1h 30m before Night shifts'), findsOneWidget);
      expect(find.textContaining('default'), findsNothing);
    });

    testWidgets('the hero reflects the linked shift\'s ACTUAL roster start',
        (tester) async {
      await pumpAlarms(
        tester,
        seed: [
          mk(
            id: 'a',
            minutesOfDay: 6 * 60,
            label: 'Wake Up',
            linkedShiftType: ShiftType.day,
            relativeOffsetMinutes: 60,
          ),
        ],
        // A real Day shift at 06:00 (not the 07:00 default) → 06:00 − 1h = 05:00.
        shifts: [
          Shift(
            id: 'd1',
            date: DateTime(2030, 1, 1),
            type: ShiftType.day,
            startMinutes: 6 * 60,
            endMinutes: 14 * 60,
          ),
        ],
      );
      expect(find.text('05:00 AM'), findsOneWidget);
    });

    testWidgets(
      'an exact-time card shows the EXACT clock, never the lead-time math',
      (tester) async {
        // Field bug regression (UI/engine desync): exact-time 04:15 on a Day
        // shift starting 06:00 — the old hand-rolled `shiftStart − leadTime`
        // (06:00 − 1h global) rendered 05:00 AM while the engine was correctly
        // armed for 04:15. The card must read off the shared display helper.
        await pumpAlarms(
          tester,
          seed: [
            mk(
              id: 'x',
              minutesOfDay: 6 * 60,
              label: 'Fixed wake',
              linkedShiftType: ShiftType.day,
              isExactTime: true,
              exactTimeMinutes: 4 * 60 + 15,
            ),
          ],
          shifts: [
            Shift(
              id: 'd1',
              date: DateTime(2030, 1, 1),
              type: ShiftType.day,
              startMinutes: 6 * 60,
              endMinutes: 14 * 60,
            ),
          ],
        );
        expect(find.text('04:15 AM'), findsOneWidget);
        expect(find.text('05:00 AM'), findsNothing,
            reason: 'the stale shiftStart − leadTime clock must be gone');
        // Detail line drops the lead copy for the exact-time descriptor.
        expect(find.text('Exact time · Day shifts'), findsOneWidget);
        expect(find.textContaining('before Day shifts'), findsNothing);
      },
    );

    testWidgets(
      'an exact-time card with an (ignored) offset still shows the exact clock',
      (tester) async {
        // Belt-and-braces: a record carrying BOTH exact mode and a stale
        // offset override renders the exact clock, mirroring engine precedence.
        await pumpAlarms(
          tester,
          seed: [
            mk(
              id: 'x',
              minutesOfDay: 6 * 60,
              label: 'Fixed wake',
              linkedShiftType: ShiftType.night,
              relativeOffsetMinutes: 90,
              isExactTime: true,
              exactTimeMinutes: 20 * 60, // 08:00 PM, before the 22:00 default
            ),
          ],
        );
        expect(find.text('08:00 PM'), findsOneWidget);
        expect(find.text('Exact time · Night shifts'), findsOneWidget);
      },
    );

    testWidgets('a weekly card shows its clock + the weekday summary',
        (tester) async {
      await pumpAlarms(
        tester,
        seed: [
          mk(
            id: 'w',
            minutesOfDay: 6 * 60 + 30,
            label: 'Gym',
            repeatType: AppAlarmRepeatType.weekly,
            weekdaysBitmask: 1 | 1 << 2 | 1 << 4, // Mon, Wed, Fri
          ),
        ],
      );
      expect(find.text('06:30 AM'), findsOneWidget);
      expect(find.text('Mon, Wed, Fri'), findsOneWidget);
    });

    testWidgets('a one-time auto-delete card notes the auto-delete',
        (tester) async {
      await pumpAlarms(
        tester,
        seed: [
          mk(
            id: 'o',
            minutesOfDay: 7 * 60,
            label: 'Appointment',
            repeatType: AppAlarmRepeatType.oneTime,
            autoDeleteAfterFiring: true,
          ),
        ],
      );
      expect(find.text('Rings once · auto-deletes'), findsOneWidget);
    });

    testWidgets('alarms are sorted by minutesOfDay ascending', (tester) async {
      // One-time alarms so the clock-time headline is stable to assert order.
      await pumpAlarms(
        tester,
        seed: [
          mk(
            id: 'late',
            minutesOfDay: 22 * 60,
            label: 'Night',
            repeatType: AppAlarmRepeatType.oneTime,
          ),
          mk(
            id: 'early',
            minutesOfDay: 6 * 60,
            label: 'Morning',
            repeatType: AppAlarmRepeatType.oneTime,
          ),
          mk(
            id: 'mid',
            minutesOfDay: 14 * 60,
            label: 'Afternoon',
            repeatType: AppAlarmRepeatType.oneTime,
          ),
        ],
      );

      final earlyY = tester.getCenter(find.text('06:00 AM')).dy;
      final midY = tester.getCenter(find.text('02:00 PM')).dy;
      final lateY = tester.getCenter(find.text('10:00 PM')).dy;
      expect(earlyY, lessThan(midY));
      expect(midY, lessThan(lateY));
    });
  });

  group('Switch toggling', () {
    testWidgets('flipping the Switch off calls repo.upsert with enabled=false',
        (tester) async {
      final repo = await pumpAlarms(
        tester,
        seed: [
          mk(
            id: 'a',
            minutesOfDay: 6 * 60,
            label: 'Wake Up',
            enabled: true,
          ),
        ],
      );

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(repo.callLog, contains('upsert:a:enabled=false'));
      final stored = await repo.getById('a');
      expect(stored!.enabled, isFalse);
    });

    testWidgets('flipping a disabled Switch on calls upsert with enabled=true',
        (tester) async {
      final repo = await pumpAlarms(
        tester,
        seed: [
          mk(
            id: 'a',
            minutesOfDay: 6 * 60,
            label: 'Wake Up',
            enabled: false,
          ),
        ],
      );

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(repo.callLog, contains('upsert:a:enabled=true'));
      final stored = await repo.getById('a');
      expect(stored!.enabled, isTrue);
    });
  });

  group('FAB → create sheet', () {
    testWidgets('tapping the FAB opens the create-alarm bottom sheet',
        (tester) async {
      await pumpAlarms(tester, seed: const []);
      await tester.tap(find.byKey(const ValueKey('alarms-add-fab')));
      await tester.pumpAndSettle();

      // "New alarm" header and the save button identify the sheet.
      expect(find.text('New alarm'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create-alarm-save')),
        findsOneWidget,
      );
    });
  });

  group('tap-to-edit', () {
    testWidgets('tapping a card opens the edit sheet pre-populated',
        (tester) async {
      await pumpAlarms(
        tester,
        seed: [
          mk(
            id: 'a',
            minutesOfDay: 6 * 60,
            label: 'Wake Up - Day Shift',
            linkedShiftType: ShiftType.day,
          ),
        ],
      );

      await tester.tap(find.byKey(const ValueKey('alarm-card-tap-a')));
      await tester.pumpAndSettle();

      // Edit (not create) header, and the label field carries the alarm's label.
      expect(find.text('Edit alarm'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Wake Up - Day Shift'),
        findsOneWidget,
      );
    });
  });
}
