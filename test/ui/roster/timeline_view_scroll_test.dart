import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/ui/roster/shift_filter.dart';
import 'package:rostrik_mvp/ui/roster/timeline_view.dart';

import '../../alarms/fakes.dart';

void main() {
  Shift shiftOnOffset(int dayOffset) {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day + dayOffset);
    return Shift(
      id: 'day$dayOffset',
      date: d,
      type: ShiftType.day,
      startMinutes: 7 * 60,
      endMinutes: 15 * 60,
    );
  }

  testWidgets('opens scrolled to today, not the far-past top of the list',
      (tester) async {
    // A long roster spanning 20 days past → 20 days future in a short viewport,
    // so "today" is well below the fold.
    final shifts = [for (var i = -20; i <= 20; i++) shiftOnOffset(i)];

    await tester.pumpWidget(
      Provider<ShiftRepository>.value(
        value: FakeShiftRepository(),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: TimelineView(shifts: shifts, filter: ShiftFilter.all),
            ),
          ),
        ),
      ),
    );
    // Let the one-shot auto-scroll run: initial frame, the post-frame jump, and
    // the ensureVisible refine. Explicit pumps rather than pumpAndSettle so a
    // stray settle-loop timer can't hang the test.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Today's card is built + visible…
    expect(find.byKey(const ValueKey('shift-card-day0')), findsOneWidget);
    // …while the far-past top of the list has been scrolled off (lazy slivers
    // don't build it), proving the view auto-scrolled to today.
    expect(find.byKey(const ValueKey('shift-card-day-20')), findsNothing);
  });
}
