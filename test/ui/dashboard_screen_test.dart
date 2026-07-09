import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_cycle.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/app_alarm_repository.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/ui/dashboard_screen.dart';
import 'package:rostrik_mvp/ui/shift_format.dart';

import '../alarms/fakes.dart';

void main() {
  Future<FakeShiftRepository> pumpDashboard(
    WidgetTester tester, {
    required List<Shift> shifts,
    List<ShiftCycle> cycles = const [],
    List<AppAlarm> alarms = const [],
    FakeAppAlarmRepository? alarmRepo,
  }) async {
    // Backing repos for the early-skip "Dismiss Upcoming Alarm" writes. Most
    // tests never touch them (no alarm in window → no control), but they must
    // be in the tree because the control reads them on confirm. Rotation
    // skips write the SHIFT repo (returned); shift-less one-time/weekly skips
    // write the ALARM repo — pass [alarmRepo] to assert on those.
    final shiftRepo = FakeShiftRepository();
    addTearDown(shiftRepo.dispose);
    final appAlarmRepo = alarmRepo ?? FakeAppAlarmRepository();
    if (alarmRepo == null) addTearDown(appAlarmRepo.dispose);
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
          Provider<AppAlarmRepository>.value(value: appAlarmRepo),
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
    bool isPaused = false,
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: startMin,
        endMinutes: endMin,
        isMuted: isMuted,
        isAcknowledged: isAcknowledged,
        isPaused: isPaused,
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

    testWidgets('a PAUSED future shift is skipped — hero shows the next active',
        (tester) async {
      // Paused Day starts sooner; active Night later. The user isn't working
      // the paused day, so the hero must skip it and feature Night.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      await pumpDashboard(
        tester,
        shifts: [
          mk(
            id: 'paused-day',
            date: tomorrow,
            type: ShiftType.day,
            startMin: 6 * 60,
            endMin: 14 * 60,
            isPaused: true,
          ),
          mk(
            id: 'active-night',
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

    testWidgets('a PAUSED in-progress shift is NOT featured (rolls forward)',
        (tester) async {
      // Unlike mute/ack, a paused shift the user is "inside" must NOT show as
      // in-progress — they took the day off. The hero rolls to the next active.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startMin = (now.hour * 60 + now.minute) - 30;
      final endMin = (now.hour * 60 + now.minute) + 30;
      if (startMin < 0 || endMin >= 1440) {
        return; // midnight-boundary guard, as in the in-progress tests
      }

      await pumpDashboard(
        tester,
        shifts: [
          mk(
            id: 'paused-live',
            date: today,
            type: ShiftType.day,
            startMin: startMin,
            endMin: endMin,
            isPaused: true,
          ),
          mk(
            id: 'next-night',
            date: today.add(const Duration(days: 2)),
            type: ShiftType.night,
            startMin: 22 * 60,
            endMin: 6 * 60,
          ),
        ],
      );

      expect(find.text('Night shift'), findsOneWidget);
      expect(find.text('Day shift'), findsNothing);
      expect(find.text('IN PROGRESS'), findsNothing);
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
      'an acknowledged in-progress shift still shows (Day-7 field bug)',
      (tester) async {
        // Regression: on Day 7 the user dismissed the morning alarm, which sets
        // isAcknowledged on TODAY's shift. The hero must still feature it
        // ("Ends in …" / IN PROGRESS) instead of rolling the countdown forward
        // to the next rotation block days away. isAcknowledged/isMuted are
        // alarm-suppression flags and must NOT hide a shift the user is on.
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final startMin = (now.hour * 60 + now.minute) - 30;
        final endMin = (now.hour * 60 + now.minute) + 30;
        if (startMin < 0 || endMin >= 1440) {
          return; // Midnight boundary — same guard as the in-progress test.
        }

        await pumpDashboard(
          tester,
          shifts: [
            // Acknowledged AND muted, yet currently under way.
            mk(
              id: 'live-acked',
              date: today,
              type: ShiftType.day,
              startMin: startMin,
              endMin: endMin,
              isAcknowledged: true,
              isMuted: true,
            ),
            // The next rotation block, 8 days out — must NOT win while the
            // user is still on the active shift.
            mk(
              id: 'far-night',
              date: today.add(const Duration(days: 8)),
              type: ShiftType.night,
              startMin: 22 * 60,
              endMin: 6 * 60,
            ),
          ],
        );

        expect(find.text('Day shift'), findsOneWidget);
        expect(find.text('Night shift'), findsNothing);
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

    // A SECOND alarm on the same Day shift: fires at start−30 (per-alarm
    // lead override), i.e. AFTER dayAlarm's start−60 (global-lead) ring —
    // the sibling the per-ring skip must leave armed.
    AppAlarm thirtyMinAlarm() => AppAlarm(
          id: 'wake30',
          minutesOfDay: 7 * 60,
          label: 'Final call',
          repeatType: AppAlarmRepeatType.followsRotation,
          linkedShiftType: ShiftType.day,
          relativeOffsetMinutes: 30,
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

    testWidgets('a PAUSED shift does NOT surface the early-skip',
        (tester) async {
      // The consolidation fix: the legacy upcoming-alarm helper didn't know
      // about isPaused, so a sick/leave day still offered a skip for an alarm
      // the engine won't fire. The unified projector ignores paused shifts, so
      // the control must be absent.
      await pumpDashboard(
        tester,
        shifts: [soonShift().copyWith(isPaused: true, pauseReason: 'Sick')],
        alarms: [dayAlarm()],
      );
      expect(
        find.byKey(const ValueKey('dismiss-upcoming-button')),
        findsNothing,
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

    testWidgets(
        'sliding to confirm appends ONLY that ring\'s alarm id — no blanket '
        'isAlarmSkipped write', (tester) async {
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
      expect(stored!.dismissedAlarmIds, ['wake']);
      expect(stored.isAlarmSkipped, isFalse,
          reason: 'the whole-shift flag is retired as a write target — it '
              'silenced every alarm on the shift');
      expect(stored.isAcknowledged, isFalse);
    });

    testWidgets(
        'with several alarms, skip-one targets the EARLIEST ring and leaves '
        'the siblings alone', (tester) async {
      final repo = await pumpDashboard(
        tester,
        shifts: [soonShift()],
        // 'wake' fires at start−60 (global lead); 'wake30' at start−30 —
        // 'wake' is the next chronological ring.
        alarms: [dayAlarm(), thirtyMinAlarm()],
      );
      await tester.tap(find.byKey(const ValueKey('dismiss-upcoming-button')));
      await tester.pumpAndSettle();
      await tester.drag(find.byIcon(Icons.alarm_off), const Offset(600, 0));
      await tester.pumpAndSettle();

      final stored = await repo.getById('soon');
      expect(stored!.dismissedAlarmIds, ['wake'],
          reason: 'only the immediate next ring is skipped — wake30 stays');
    });

    testWidgets(
        'sequential skip: once the first ring is dismissed, the control '
        'retargets the next ring (label + write)', (tester) async {
      final base = soonShift();
      final start = base.startDateTime;
      final clock60 = formatClock(
        start.subtract(const Duration(minutes: 60)).let(_minutesOfDay),
        use24Hour: false,
      );
      final clock30 = formatClock(
        start.subtract(const Duration(minutes: 30)).let(_minutesOfDay),
        use24Hour: false,
      );

      // Fresh shift → the button advertises the 60-min ring.
      await pumpDashboard(
        tester,
        shifts: [base],
        alarms: [dayAlarm(), thirtyMinAlarm()],
      );
      expect(find.text('Dismiss upcoming alarm · $clock60'), findsOneWidget);

      // The first ring dismissed (as the production stream would deliver
      // after a skip write) → the SAME control now targets the 30-min ring.
      final repo = await pumpDashboard(
        tester,
        shifts: [
          base.copyWith(dismissedAlarmIds: ['wake']),
        ],
        alarms: [dayAlarm(), thirtyMinAlarm()],
      );
      expect(find.text('Dismiss upcoming alarm · $clock30'), findsOneWidget);

      // And confirming appends the SECOND id alongside the first.
      await tester.tap(find.byKey(const ValueKey('dismiss-upcoming-button')));
      await tester.pumpAndSettle();
      await tester.drag(find.byIcon(Icons.alarm_off), const Offset(600, 0));
      await tester.pumpAndSettle();
      final stored = await repo.getById('soon');
      expect(stored!.dismissedAlarmIds, ['wake', 'wake30']);
    });

    testWidgets(
        'Skip All appears only with multiple rings and appends every '
        'remaining alarm id via its own slide-to-confirm', (tester) async {
      final repo = await pumpDashboard(
        tester,
        shifts: [soonShift()],
        alarms: [dayAlarm(), thirtyMinAlarm()],
      );
      final skipAll = find.byKey(const ValueKey('skip-all-button'));
      expect(skipAll, findsOneWidget);
      expect(find.text('Skip all 2 alarms for this shift'), findsOneWidget);

      // Visible button → slide-to-confirm gate; never a bare tap (and never
      // a long-press — hidden gestures fail groggy users).
      await tester.tap(skipAll);
      await tester.pumpAndSettle();
      final slide = find.byKey(const ValueKey('skip-all-slide'));
      expect(slide, findsOneWidget);
      expect(
        (await repo.getById('soon')),
        isNull,
        reason: 'revealing the bar must not write anything yet',
      );

      await tester.drag(find.byIcon(Icons.clear_all), const Offset(600, 0));
      await tester.pumpAndSettle();

      final stored = await repo.getById('soon');
      expect(stored!.dismissedAlarmIds, containsAll(['wake', 'wake30']));
      expect(stored.isAlarmSkipped, isFalse);
    });

    testWidgets('Skip All is hidden when only one ring remains — skip-one '
        'already covers it', (tester) async {
      await pumpDashboard(
        tester,
        shifts: [soonShift()],
        alarms: [dayAlarm()],
      );
      expect(find.byKey(const ValueKey('skip-all-button')), findsNothing);
    });

    testWidgets(
        'a ONE-TIME alarm within 12h surfaces the control, and skipping '
        'disables the rule (the missing-button regression)', (tester) async {
      // One-time at now+2h: `_nextDailyOccurrence` lands it inside the 12h
      // window whether or not the +2h crosses midnight.
      final fire = DateTime.now().add(const Duration(hours: 2));
      final once = AppAlarm(
        id: 'once',
        minutesOfDay: fire.hour * 60 + fire.minute,
        label: 'Appointment',
        repeatType: AppAlarmRepeatType.oneTime,
      );
      final alarmRepo = FakeAppAlarmRepository();
      addTearDown(alarmRepo.dispose);

      await pumpDashboard(
        tester,
        shifts: const [], // no roster at all — the old rotation-only gate
        alarms: [once],
        alarmRepo: alarmRepo,
      );
      expect(
        find.byKey(const ValueKey('dismiss-upcoming-button')),
        findsOneWidget,
        reason: 'shift-less rings must surface the early-skip too',
      );
      // A lone ring — no Skip All escape hatch.
      expect(find.byKey(const ValueKey('skip-all-button')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('dismiss-upcoming-button')));
      await tester.pumpAndSettle();
      await tester.drag(find.byIcon(Icons.alarm_off), const Offset(600, 0));
      await tester.pumpAndSettle();

      final stored = await alarmRepo.getById('once');
      expect(stored!.enabled, isFalse,
          reason: 'a skipped one-shot is the rule disarmed — a watermark '
              'would resurrect it tomorrow');
      expect(stored.skippedThrough, isNull);
    });

    testWidgets(
        'a WEEKLY alarm within 12h surfaces the control, and skipping '
        'advances skippedThrough to exactly this occurrence', (tester) async {
      // Weekly firing ~2h from now on that day's weekday, so the next
      // occurrence is deterministic: the (possibly midnight-crossed) now+2h
      // calendar slot.
      final fire = DateTime.now().add(const Duration(hours: 2));
      final expectedFireAt =
          DateTime(fire.year, fire.month, fire.day, fire.hour, fire.minute);
      final weekly = AppAlarm(
        id: 'wk',
        minutesOfDay: fire.hour * 60 + fire.minute,
        label: 'Gym',
        repeatType: AppAlarmRepeatType.weekly,
        weekdaysBitmask: 1 << (fire.weekday - 1),
      );
      final alarmRepo = FakeAppAlarmRepository();
      addTearDown(alarmRepo.dispose);

      await pumpDashboard(
        tester,
        shifts: const [],
        alarms: [weekly],
        alarmRepo: alarmRepo,
      );
      expect(
        find.byKey(const ValueKey('dismiss-upcoming-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('dismiss-upcoming-button')));
      await tester.pumpAndSettle();
      await tester.drag(find.byIcon(Icons.alarm_off), const Offset(600, 0));
      await tester.pumpAndSettle();

      final stored = await alarmRepo.getById('wk');
      expect(stored!.skippedThrough, expectedFireAt,
          reason: 'the watermark pins THIS occurrence — next week\'s ring '
              'fires later and stays armed');
      expect(stored.enabled, isTrue,
          reason: 'a weekly rule must survive a one-occurrence skip');
    });

    testWidgets('the cancel X collapses the Skip All bar without writing',
        (tester) async {
      final repo = await pumpDashboard(
        tester,
        shifts: [soonShift()],
        alarms: [dayAlarm(), thirtyMinAlarm()],
      );
      await tester.tap(find.byKey(const ValueKey('skip-all-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dismiss-upcoming-cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('skip-all-slide')), findsNothing);
      expect(
        find.byKey(const ValueKey('dismiss-upcoming-button')),
        findsOneWidget,
      );
      expect(await repo.getById('soon'), isNull);
    });
  });
}

/// Minutes-of-day of a DateTime — mirrors how the control derives the label
/// clock from `fireAt`.
int _minutesOfDay(DateTime t) => t.hour * 60 + t.minute;

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
