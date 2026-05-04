import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/ui/roster/calendar_view.dart';
import 'package:rostrik_mvp/ui/roster/timeline_view.dart';

import '../../alarms/fakes.dart';

void main() {
  // The calendar's focused day is `DateTime.now()` on first build, so we
  // build fixtures keyed to today's date so they're guaranteed to land
  // on a cell that's visible without needing to page the grid.
  final today = _dateOnly(DateTime.now());
  final tomorrow = today.add(const Duration(days: 1));

  Future<FakeShiftRepository> pumpCalendar(
    WidgetTester tester, {
    required List<Shift> shifts,
  }) async {
    final repo = FakeShiftRepository();
    for (final s in shifts) {
      await repo.upsert(s);
    }
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShiftRepository>.value(value: repo),
          Provider<AlarmSettings>.value(
            value: const AlarmSettings(leadTime: Duration(hours: 1)),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: CalendarView(shifts: shifts)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  group('cell bar rendering', () {
    testWidgets('a day with one Day shift renders a single bar with text "Day"',
        (tester) async {
      await pumpCalendar(
        tester,
        shifts: [_dayShift(id: 'd', date: today)],
      );

      // The bar key pins a specific shift's bar; finding it asserts the
      // bar widget exists. The text content asserts we use the short
      // label, not the full one.
      expect(find.byKey(const ValueKey('shift-bar-d')), findsOneWidget);
      expect(find.text('Day'), findsAtLeastNWidgets(1));
    });

    testWidgets('Night shift renders the "Night" short label', (tester) async {
      await pumpCalendar(
        tester,
        shifts: [
          Shift(
            id: 'n',
            date: today,
            type: ShiftType.night,
            startMinutes: 22 * 60,
            endMinutes: 6 * 60,
          ),
        ],
      );

      expect(find.byKey(const ValueKey('shift-bar-n')), findsOneWidget);
      expect(find.text('Night'), findsAtLeastNWidgets(1));
    });

    testWidgets('OFF shift renders the "Off" short label', (tester) async {
      await pumpCalendar(
        tester,
        shifts: [_offShift(id: 'o', date: today)],
      );

      expect(find.byKey(const ValueKey('shift-bar-o')), findsOneWidget);
      expect(find.text('Off'), findsAtLeastNWidgets(1));
    });

    testWidgets('a muted shift wraps its bar in Opacity(0.55)', (tester) async {
      await pumpCalendar(
        tester,
        shifts: [_dayShift(id: 'm', date: today, isMuted: true)],
      );

      // Walk up from the bar key to the nearest Opacity ancestor — that
      // Opacity widget mirrors the timeline's muted treatment, so a user
      // toggling mute on the timeline sees a corresponding faded bar
      // here without further code paths needing to know.
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('shift-bar-m')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, closeTo(0.55, 0.001));
    });

    testWidgets('an unmuted shift bar has no Opacity wrapper applied',
        (tester) async {
      // Regression guard: Opacity is reserved for muted state. If a future
      // refactor accidentally always-wraps the bar, the muted-vs-unmuted
      // distinction collapses on the calendar.
      await pumpCalendar(
        tester,
        shifts: [_dayShift(id: 'u', date: today)],
      );

      final opacities = tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.byKey(const ValueKey('shift-bar-u')),
              matching: find.byType(Opacity),
            ),
          )
          .where((o) => o.opacity < 1.0)
          .toList();
      expect(opacities, isEmpty);
    });
  });

  group('multi-shift cap', () {
    testWidgets(
      '4 shifts on the same day render the first bar plus a "+3" indicator',
      (tester) async {
        // Cell width on the test surface (800 px / 7 cols) is generous,
        // but we still cap at 2 visible bars + a "+N" so the design
        // never depends on cell height.
        await pumpCalendar(
          tester,
          shifts: [
            _dayShift(id: 'a', date: today, startMinutes: 6 * 60),
            _dayShift(id: 'b', date: today, startMinutes: 9 * 60),
            _dayShift(id: 'c', date: today, startMinutes: 12 * 60),
            _dayShift(id: 'd', date: today, startMinutes: 15 * 60),
          ],
        );

        // First bar (sorted by startMinutes) is visible.
        expect(find.byKey(const ValueKey('shift-bar-a')), findsOneWidget);
        // "+3" replaces bars 2/3/4.
        expect(find.text('+3'), findsOneWidget);
        // None of the other individual bars are rendered.
        expect(find.byKey(const ValueKey('shift-bar-b')), findsNothing);
        expect(find.byKey(const ValueKey('shift-bar-c')), findsNothing);
        expect(find.byKey(const ValueKey('shift-bar-d')), findsNothing);
      },
    );

    testWidgets('exactly 2 shifts on a day render both bars, no "+N"',
        (tester) async {
      await pumpCalendar(
        tester,
        shifts: [
          _dayShift(id: 'a', date: today, startMinutes: 7 * 60),
          _offShift(id: 'b', date: today),
        ],
      );

      expect(find.byKey(const ValueKey('shift-bar-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('shift-bar-b')), findsOneWidget);
      // No "+N" indicator at the boundary case.
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('shifts are ordered by start time within a single cell',
        (tester) async {
      // Pin the sort: even if the orchestrator hands us shifts in a
      // different order (Hive iteration, filter, etc.), bar order in
      // a cell is deterministic.
      await pumpCalendar(
        tester,
        shifts: [
          _dayShift(id: 'late', date: today, startMinutes: 14 * 60),
          _dayShift(id: 'early', date: today, startMinutes: 6 * 60),
        ],
      );

      final earlyRect =
          tester.getRect(find.byKey(const ValueKey('shift-bar-early')));
      final lateRect =
          tester.getRect(find.byKey(const ValueKey('shift-bar-late')));
      expect(
        earlyRect.top,
        lessThan(lateRect.top),
        reason: 'Earlier shift bar must be stacked above the later one.',
      );
    });
  });

  group('tap routing', () {
    testWidgets('tapping a cell with shifts opens the day-shift bottom sheet',
        (tester) async {
      await pumpCalendar(
        tester,
        shifts: [_dayShift(id: 'd', date: today)],
      );

      // warnIfMissed: false because table_calendar's GestureDetector
      // sits above our keyed Container in the render tree — the tap
      // routes correctly to onDaySelected, but the framework's hit-test
      // warning fires anyway because the literal target widget didn't
      // own the gesture.
      await tester.tap(find.byKey(_cellKey(today)), warnIfMissed: false);
      await tester.pumpAndSettle();

      // The sheet hosts a ShiftCard; the keyed entry confirms our
      // specific shift is the one rendered (not, say, a stray copy).
      expect(
        find.byKey(const ValueKey('sheet-shift-card-d')),
        findsOneWidget,
      );
      // ShiftCard is the timeline row widget; finding one means we
      // successfully reused the timeline rendering instead of a
      // bespoke compact list.
      expect(find.byType(ShiftCard), findsOneWidget);
    });

    testWidgets(
      'tapping an empty cell opens the shift editor pre-populated with that date',
      (tester) async {
        // No shifts at all → today is empty.
        await pumpCalendar(tester, shifts: const []);

        // warnIfMissed: false because table_calendar's GestureDetector
      // sits above our keyed Container in the render tree — the tap
      // routes correctly to onDaySelected, but the framework's hit-test
      // warning fires anyway because the literal target widget didn't
      // own the gesture.
      await tester.tap(find.byKey(_cellKey(today)), warnIfMissed: false);
        await tester.pumpAndSettle();

        // The editor's title text is the cheapest signal that the modal
        // launched and is fully built.
        expect(find.text('Add shift'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping an unrelated empty cell still opens the editor (not the sheet)',
      (tester) async {
        // Has shifts on `today` but tomorrow is empty. Tapping tomorrow
        // must NOT confuse the route by latching on today's shifts.
        await pumpCalendar(
          tester,
          shifts: [_dayShift(id: 'd', date: today)],
        );

        await tester.tap(find.byKey(_cellKey(tomorrow)), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('Add shift'), findsOneWidget);
        // No ShiftCard in the sheet — the empty-cell branch never opens
        // it, so it must remain absent.
        expect(find.byKey(const ValueKey('sheet-shift-card-d')), findsNothing);
      },
    );
  });
}

DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

ValueKey<String> _cellKey(DateTime d) =>
    ValueKey('calendar-cell-${d.year}-${d.month}-${d.day}');

Shift _dayShift({
  required String id,
  required DateTime date,
  int startMinutes = 7 * 60,
  bool isMuted = false,
}) =>
    Shift(
      id: id,
      date: date,
      type: ShiftType.day,
      startMinutes: startMinutes,
      endMinutes: (startMinutes + 8 * 60) % 1440,
      isMuted: isMuted,
    );

Shift _offShift({required String id, required DateTime date}) => Shift(
      id: id,
      date: date,
      type: ShiftType.off,
      startMinutes: 0,
      endMinutes: 0,
    );
