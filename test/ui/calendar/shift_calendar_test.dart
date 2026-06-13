import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/ui/calendar/shift_calendar.dart';

void main() {
  final now = DateTime.now();
  DateTime dayInMonth(int d) => DateTime(now.year, now.month, d);
  Key cellKey(DateTime d) =>
      ValueKey('shift-calendar-cell-${d.year}-${d.month}-${d.day}');

  // table_calendar routes the day tap through its table-level gesture handler,
  // so the tap lands on an ancestor of the keyed cell (expected) —
  // warnIfMissed:false silences the otherwise-noisy hit-test warning.
  Future<void> tapCell(WidgetTester tester, DateTime d) async {
    await tester.tap(find.byKey(cellKey(d)), warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Shift shift({
    required String id,
    required DateTime date,
    ShiftType type = ShiftType.day,
    int start = 7 * 60,
    int end = 15 * 60,
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: start,
        endMinutes: end,
      );

  Future<List<(DateTime, List<Shift>)>> pumpCalendar(
    WidgetTester tester, {
    required List<Shift> shifts,
  }) async {
    final taps = <(DateTime, List<Shift>)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShiftCalendarView(
            shifts: shifts,
            onDayTapped: (date, onDate) => taps.add((date, onDate)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return taps;
  }

  testWidgets('renders in compact mode (dashboard tile) without overflow',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShiftCalendarView(
            shifts: [shift(id: 's15', date: dayInMonth(15))],
            onDayTapped: (_, _) {},
            compact: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Builds + lays out the keyed cell with the tighter metrics (a RenderFlex
    // overflow would have thrown during pump).
    expect(find.byType(ShiftCalendarView), findsOneWidget);
    expect(find.byKey(cellKey(dayInMonth(15))), findsOneWidget);
  });

  testWidgets('tapping a day with a Hive shift reports that shift', (tester) async {
    final s = shift(id: 's15', date: dayInMonth(15));
    final taps = await pumpCalendar(tester, shifts: [s]);

    await tapCell(tester, dayInMonth(15));

    expect(taps, hasLength(1));
    expect(taps.single.$1, dayInMonth(15));
    expect(taps.single.$2.map((x) => x.id), ['s15']);
  });

  testWidgets('tapping a blank day reports an empty shift list', (tester) async {
    // One shift on the 15th; the 10th has none → its tap is a "blank day".
    final taps = await pumpCalendar(
      tester,
      shifts: [shift(id: 's15', date: dayInMonth(15))],
    );

    await tapCell(tester, dayInMonth(10));

    expect(taps, hasLength(1));
    expect(taps.single.$1, dayInMonth(10));
    expect(taps.single.$2, isEmpty);
  });

  testWidgets('a paused shift stays on the calendar (kept as a record)',
      (tester) async {
    final taps = await pumpCalendar(tester, shifts: [
      shift(id: 'paused', date: dayInMonth(15))
          .copyWith(isPaused: true, pauseReason: 'Leave'),
    ]);

    await tapCell(tester, dayInMonth(15));

    // Paused shifts are NOT filtered out — the cell still carries the record.
    expect(taps.single.$2.map((x) => x.id), ['paused']);
  });

  testWidgets('reports every shift on a day, earliest first', (tester) async {
    // Two shifts on the same day, seeded out of order — the index sorts them by
    // start, so tap reports earliest-first (the editor edits the earliest).
    final taps = await pumpCalendar(tester, shifts: [
      shift(id: 'late', date: dayInMonth(15), start: 15 * 60, end: 23 * 60),
      shift(id: 'early', date: dayInMonth(15), start: 7 * 60, end: 15 * 60),
    ]);

    await tapCell(tester, dayInMonth(15));

    expect(taps.single.$2.map((x) => x.id), ['early', 'late']);
  });
}
