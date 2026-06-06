import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_cycle.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/ui/dashboard_screen.dart';

import '../alarms/fakes.dart';

void main() {
  Future<FakeShiftRepository> pumpDashboard(
    WidgetTester tester, {
    required List<Shift> shifts,
    List<ShiftCycle> cycles = const [],
    List<AppAlarm> alarms = const [],
  }) async {
    // Backing repo for the early-skip "Dismiss Upcoming Alarm" write. Most
    // tests never touch it (no alarm in window → no control), but it must be
    // in the tree because the control reads it on confirm.
    final shiftRepo = FakeShiftRepository();
    addTearDown(shiftRepo.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // Synchronous Provider — DashboardScreen uses
          // `context.watch<List<Shift>>()` (and `<List<ShiftCycle>>()`
          // for the resolver-driven Rotation card), which work with any
          // Provider<T>, not just a StreamProvider. Avoids pulling in a
          // real stream/Hive setup just to render.
          Provider<List<Shift>>.value(value: shifts),
          // Default empty list — most existing tests don't care about
          // the cycle, and an empty list makes `_pickActiveCycle`
          // return null, which suppresses the Rotation card entirely.
          // Tests asserting on rotation copy can override via the
          // `cycles:` parameter.
          Provider<List<ShiftCycle>>.value(value: cycles),
          // The early-skip control reads the alarms + global lead time to find
          // the next automated alarm within 12h, and the shift repo to write
          // the skip.
          Provider<List<AppAlarm>>.value(value: alarms),
          Provider<AlarmSettings>.value(value: AlarmSettings.defaults),
          Provider<ShiftRepository>.value(value: shiftRepo),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();
    return shiftRepo;
  }

  Shift mk({
    required String id,
    required DateTime date,
    required ShiftType type,
    required int startMin,
    required int endMin,
    bool isMuted = false,
    bool isAcknowledged = false,
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: startMin,
        endMinutes: endMin,
        isMuted: isMuted,
        isAcknowledged: isAcknowledged,
      );

  group('empty state', () {
    testWidgets('shows the rest-day copy when no shifts are upcoming',
        (tester) async {
      await pumpDashboard(tester, shifts: const []);
      expect(find.text('No upcoming shifts'), findsOneWidget);
      expect(find.text('Enjoy your time off.'), findsOneWidget);
    });

    testWidgets(
      'OFF shifts in the future do NOT count — empty state is shown',
      (tester) async {
        final tomorrow =
            DateTime.now().add(const Duration(days: 1));
        await pumpDashboard(
          tester,
          shifts: [
            mk(
              id: 'off',
              date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
              type: ShiftType.off,
              startMin: 0,
              endMin: 0,
            ),
          ],
        );
        expect(find.text('No upcoming shifts'), findsOneWidget);
      },
    );

    testWidgets(
      'shifts that have already ended do NOT count — empty state',
      (tester) async {
        final past = DateTime.now().subtract(const Duration(days: 1));
        await pumpDashboard(
          tester,
          shifts: [
            mk(
              id: 'past',
              date: DateTime(past.year, past.month, past.day),
              type: ShiftType.day,
              // 06:00–14:00 yesterday — definitely ended.
              startMin: 6 * 60,
              endMin: 14 * 60,
            ),
          ],
        );
        expect(find.text('No upcoming shifts'), findsOneWidget);
      },
    );
  });

  group('next shift card', () {
    testWidgets('renders the type label and a Starts-in countdown',
        (tester) async {
      // Tomorrow at 06:00 — guarantees a future start regardless of
      // when the test wall-clock fires.
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1));
      await pumpDashboard(
        tester,
        shifts: [
          mk(
            id: 'd1',
            date: tomorrow,
            type: ShiftType.day,
            startMin: 6 * 60,
            endMin: 14 * 60,
          ),
        ],
      );

      expect(find.text('Day shift'), findsOneWidget);
      // The exact "Xh Ym" is wall-clock-dependent; just assert the
      // verb + "Tomorrow at 06:00 AM" subtitle which IS deterministic. The
      // test pumps DashboardScreen without an AppPreferences provider, so the
      // 24h preference falls back to its default (false → 12-hour AM/PM).
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data?.startsWith('Starts in ') ?? false),
        ),
        findsOneWidget,
      );
      expect(find.text('Starts tomorrow at 06:00 AM'), findsOneWidget);
    });

    testWidgets('picks the earliest non-OFF future shift across the list',
        (tester) async {
      // Three candidates: an OFF (should be skipped), a far-future Day,
      // and a near-future Night. The Night must win because it starts
      // sooner among the non-OFF candidates.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final farFuture = today.add(const Duration(days: 7));
      await pumpDashboard(
        tester,
        shifts: [
          mk(
            id: 'far-day',
            date: farFuture,
            type: ShiftType.day,
            startMin: 6 * 60,
            endMin: 14 * 60,
          ),
          mk(
            id: 'off',
            date: tomorrow,
            type: ShiftType.off,
            startMin: 0,
            endMin: 0,
          ),
          mk(
            // Tomorrow morning — start in ~12-36 hours depending on
            // when the test runs. Earliest non-OFF candidate.
            id: 'near-night',
            date: tomorrow,
            type: ShiftType.night,
            startMin: 22 * 60,
            endMin: 6 * 60,
          ),
        ],
      );

      expect(find.text('Night shift'), findsOneWidget);
      expect(find.text('Day shift'), findsNothing);
    });

    testWidgets(
      'a currently-in-progress shift shows "Ends in" + IN PROGRESS chip',
      (tester) async {
        // A shift that started 30 minutes ago and ends in another 30
        // minutes. The dashboard treats this as the current shift.
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final startMin = (now.hour * 60 + now.minute) - 30;
        final endMin = (now.hour * 60 + now.minute) + 30;
        // Guard the boundary: if we're within the first 30 min after
        // midnight, the calc above goes negative — clamp to a safe
        // "today" window. Real users never hit this boundary at the
        // moment a test runs, but flaky tests are worse than a guard.
        if (startMin < 0 || endMin >= 1440) {
          return; // Skip this case; running tests at midnight isn't worth it.
        }

        await pumpDashboard(
          tester,
          shifts: [
            mk(
              id: 'live',
              date: today,
              type: ShiftType.day,
              startMin: startMin,
              endMin: endMin,
            ),
          ],
        );

        expect(find.text('Day shift'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is Text && (w.data?.startsWith('Ends in ') ?? false),
          ),
          findsOneWidget,
        );
        expect(find.text('IN PROGRESS'), findsOneWidget);
      },
    );

    testWidgets(
      'muted or acknowledged shifts are skipped (engine parity)',
      (tester) async {
        // Mirror the engine's filter: muted / acknowledged shifts
        // aren't desired alarms, and the dashboard shouldn't advertise
        // them as "next up".
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 1));
        await pumpDashboard(
          tester,
          shifts: [
            mk(
              id: 'muted',
              date: tomorrow,
              type: ShiftType.day,
              startMin: 6 * 60,
              endMin: 14 * 60,
              isMuted: true,
            ),
            mk(
              id: 'acked',
              date: tomorrow,
              type: ShiftType.day,
              startMin: 7 * 60,
              endMin: 15 * 60,
              isAcknowledged: true,
            ),
          ],
        );

        expect(find.text('No upcoming shifts'), findsOneWidget);
      },
    );
  });

  group('Dismiss Upcoming Alarm (early-bird skip)', () {
    AppAlarm dayAlarm() => AppAlarm(
          id: 'wake',
          minutesOfDay: 7 * 60,
          label: 'Wake Up',
          repeatType: AppAlarmRepeatType.followsRotation,
          linkedShiftType: ShiftType.day,
        );

    // A Day shift whose alarm (global 60-min lead) fires ~2h from now —
    // reliably inside the 12h window regardless of wall-clock, with correct
    // midnight rollover via calendar fields.
    Shift soonShift() {
      final start = DateTime.now().add(const Duration(hours: 3));
      final date = DateTime(start.year, start.month, start.day);
      final startMin = start.hour * 60 + start.minute;
      return Shift(
        id: 'soon',
        date: date,
        type: ShiftType.day,
        startMinutes: startMin,
        endMinutes: (startMin + 8 * 60) % 1440,
      );
    }

    testWidgets('button is hidden when no alarm is within 12h', (tester) async {
      // A shift exists but no alarm rule → nothing to skip.
      await pumpDashboard(tester, shifts: [soonShift()]);
      expect(
        find.byKey(const ValueKey('dismiss-upcoming-button')),
        findsNothing,
      );
    });

    testWidgets('button appears when an automated alarm fires within 12h',
        (tester) async {
      await pumpDashboard(
        tester,
        shifts: [soonShift()],
        alarms: [dayAlarm()],
      );
      expect(
        find.byKey(const ValueKey('dismiss-upcoming-button')),
        findsOneWidget,
      );
    });

    testWidgets('tap reveals the slide-to-confirm bar (no bare-tap skip)',
        (tester) async {
      await pumpDashboard(
        tester,
        shifts: [soonShift()],
        alarms: [dayAlarm()],
      );
      await tester.tap(find.byKey(const ValueKey('dismiss-upcoming-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('dismiss-upcoming-slide')),
        findsOneWidget,
      );
    });

    testWidgets('sliding to confirm marks ONLY that shift isAlarmSkipped',
        (tester) async {
      final repo = await pumpDashboard(
        tester,
        shifts: [soonShift()],
        alarms: [dayAlarm()],
      );
      await tester.tap(find.byKey(const ValueKey('dismiss-upcoming-button')));
      await tester.pumpAndSettle();

      // Drag the handle (the only alarm_off icon once the bar is revealed) well
      // past the 60% commit threshold.
      await tester.drag(find.byIcon(Icons.alarm_off), const Offset(600, 0));
      await tester.pumpAndSettle();

      final stored = await repo.getById('soon');
      expect(stored, isNotNull);
      expect(stored!.isAlarmSkipped, isTrue);
    });
  });
}
