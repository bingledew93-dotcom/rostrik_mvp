import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_projection.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

void main() {
  // Mon 2026-06-15, 05:00.
  final now = DateTime(2026, 6, 15, 5, 0);
  const lead = 60;
  const horizon = Duration(days: 14);

  AppAlarm rotation({
    String id = 'r',
    ShiftType type = ShiftType.day,
    int? offset,
    bool enabled = true,
    bool exact = false,
    int? exactMin,
    DateTime? skippedThrough,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: 6 * 60,
        label: 'Wake',
        repeatType: AppAlarmRepeatType.followsRotation,
        linkedShiftType: type,
        relativeOffsetMinutes: offset,
        enabled: enabled,
        isExactTime: exact,
        exactTimeMinutes: exactMin,
        skippedThrough: skippedThrough,
      );

  AppAlarm oneTime(
    int minutesOfDay, {
    String id = 'o',
    bool enabled = true,
    DateTime? skippedThrough,
    DateTime? anchor,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: minutesOfDay,
        label: 'Once',
        repeatType: AppAlarmRepeatType.oneTime,
        enabled: enabled,
        skippedThrough: skippedThrough,
        oneTimeFireAt: anchor,
      );

  AppAlarm weekly(
    int mask,
    int minutesOfDay, {
    String id = 'w',
    DateTime? skippedThrough,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: minutesOfDay,
        label: 'Weekly',
        repeatType: AppAlarmRepeatType.weekly,
        weekdaysBitmask: mask,
        skippedThrough: skippedThrough,
      );

  Shift shift({
    required String id,
    required DateTime date,
    ShiftType type = ShiftType.day,
    int start = 7 * 60,
    int end = 15 * 60,
    bool isMuted = false,
    bool isAcknowledged = false,
    bool isAlarmSkipped = false,
    bool isPaused = false,
    bool isArchived = false,
    DateTime? snoozedUntil,
    List<String> dismissedAlarmIds = const [],
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: start,
        endMinutes: end,
        isMuted: isMuted,
        isAcknowledged: isAcknowledged,
        isAlarmSkipped: isAlarmSkipped,
        isPaused: isPaused,
        isArchived: isArchived,
        snoozedUntil: snoozedUntil,
        dismissedAlarmIds: dismissedAlarmIds,
      );

  List<AlarmRing> project(List<AppAlarm> alarms, List<Shift> shifts,
          {bool paused = false}) =>
      projectAlarmRings(
        alarms: alarms,
        shifts: shifts,
        globalLeadMinutes: lead,
        now: now,
        horizon: horizon,
        isSchedulePaused: paused,
      );

  // THE one-time-becomes-daily regression. Without an anchor the only thing
  // computable from the record is "next occurrence of this time of day", which
  // rolls forward forever, so a spent one-shot re-armed itself every night.
  group('projectAlarmRings — anchored one-time alarms', () {
    test('rings at its anchored instant, not the next occurrence of its time',
        () {
      // now is Mon 05:00; the anchor is WEDNESDAY, so a time-of-day projection
      // would wrongly fire it today at 06:00.
      final anchor = DateTime(2026, 6, 17, 6, 0);
      final rings = project([oneTime(6 * 60, anchor: anchor)], []);
      expect(rings.single.fireAt, anchor);
    });

    test('a PAST anchor never rings again — the spent one-shot', () {
      final rings = project(
        [oneTime(6 * 60, anchor: DateTime(2026, 6, 15, 4, 0))], // an hour ago
        [],
      );
      expect(rings, isEmpty,
          reason: 'a fired one-time alarm must not re-project to tomorrow');
    });

    test('an anchor beyond the horizon is not scheduled yet', () {
      final rings = project(
        [oneTime(6 * 60, anchor: DateTime(2026, 8, 1, 6, 0))], // ~7 weeks out
        [],
      );
      expect(rings, isEmpty);
    });

    // Records written before the anchor existed must keep working rather than
    // being retired on sight — their intended date cannot be reconstructed.
    test('a legacy alarm with no anchor keeps the old rolling behaviour', () {
      final rings = project([oneTime(6 * 60)], []);
      expect(rings.single.fireAt, DateTime(2026, 6, 15, 6, 0));
    });
  });

  group('projectAlarmRings — occurrence enumeration', () {
    test('follows-rotation fires at shiftStart − lead, carrying its shift', () {
      final rings =
          project([rotation()], [shift(id: 's', date: DateTime(2026, 6, 16))]);
      expect(rings, hasLength(1));
      expect(rings.single.fireAt, DateTime(2026, 6, 16, 6, 0)); // 07:00 − 1h
      expect(rings.single.shift?.id, 's');
    });

    test('exact-time mode ignores the lead', () {
      final rings = project(
        [rotation(exact: true, exactMin: 4 * 60 + 15)],
        [shift(id: 's', date: DateTime(2026, 6, 16))],
      );
      expect(rings.single.fireAt, DateTime(2026, 6, 16, 4, 15));
    });

    test('one-time: today if ahead, else tomorrow; carries no shift', () {
      expect(project([oneTime(6 * 60)], const []).single.fireAt,
          DateTime(2026, 6, 15, 6, 0)); // 06:00 > 05:00 → today
      expect(project([oneTime(4 * 60)], const []).single.fireAt,
          DateTime(2026, 6, 16, 4, 0)); // 04:00 < 05:00 → tomorrow
      expect(project([oneTime(6 * 60)], const []).single.shift, isNull);
    });

    test('weekly: one ring per selected weekday in the window', () {
      final tueMask = 1 << (DateTime.tuesday - 1);
      final rings = project([weekly(tueMask, 6 * 60)], const []);
      // Mon now → Tue 06-16, Tue 06-23 both inside 14 days.
      expect(rings.map((r) => r.fireAt), [
        DateTime(2026, 6, 16, 6, 0),
        DateTime(2026, 6, 23, 6, 0),
      ]);
    });

    test('rings are sorted earliest-first across alarm types', () {
      final rings = project(
        [oneTime(23 * 60, id: 'late'), rotation(id: 'rot')],
        [shift(id: 's', date: DateTime(2026, 6, 16))], // rotation → 06-16 06:00
      );
      expect(rings.first.alarm.id, 'late'); // today 23:00 is sooner than 06-16
      expect(rings.last.alarm.id, 'rot');
    });

    test('a matching shift beyond the horizon is excluded', () {
      expect(project([rotation()], [shift(id: 'far', date: DateTime(2030, 1, 1))]),
          isEmpty);
    });
  });

  group('projectAlarmRings — universal state awareness', () {
    test('Holiday Mode empties the whole projection', () {
      final rings = project(
        [rotation(), oneTime(6 * 60), weekly(0x7F, 6 * 60)],
        [shift(id: 's', date: DateTime(2026, 6, 16))],
        paused: true,
      );
      expect(rings, isEmpty);
    });

    test('disabled alarms produce no rings', () {
      expect(
        project([rotation(enabled: false), oneTime(6 * 60, enabled: false)],
            [shift(id: 's', date: DateTime(2026, 6, 16))]),
        isEmpty,
      );
    });

    test('OFF shifts never match a rotation alarm', () {
      expect(
        project([rotation(type: ShiftType.day)],
            [shift(id: 'off', date: DateTime(2026, 6, 16), type: ShiftType.off)]),
        isEmpty,
      );
    });

    // The core "follows the rotation" guarantee: an alarm is bound to ONE
    // shift type. Previously only the OFF case was covered, so a bug matching
    // a Day alarm against a Night shift would have gone unnoticed — and would
    // wake someone at 06:00 before a night shift they work at 22:00.
    test('a rotation alarm ignores every OTHER working shift type', () {
      for (final other in [ShiftType.afternoon, ShiftType.night]) {
        expect(
          project(
            [rotation(type: ShiftType.day)],
            [shift(id: 'x', date: DateTime(2026, 6, 16), type: other)],
          ),
          isEmpty,
          reason: 'a Day alarm must not ring for a $other shift',
        );
      }
    });

    // A rotation alarm rings once per MATCHING shift across the horizon, and
    // the interleaved off/other-type days stay silent — i.e. it tracks the
    // roster rather than becoming a daily alarm.
    test('a rotation alarm rings once per matching shift across a block', () {
      final rings = project([
        rotation(type: ShiftType.day)
      ], [
        shift(id: 'd1', date: DateTime(2026, 6, 16)),
        shift(id: 'd2', date: DateTime(2026, 6, 17)),
        shift(id: 'n1', date: DateTime(2026, 6, 18), type: ShiftType.night),
        shift(id: 'o1', date: DateTime(2026, 6, 19), type: ShiftType.off),
        shift(id: 'd3', date: DateTime(2026, 6, 20)),
      ]);
      expect(
        rings.map((r) => r.shift?.id).toList(),
        ['d1', 'd2', 'd3'],
        reason: 'only the Day shifts ring, in date order',
      );
    });

    // Marking leave sets Shift.isPaused (see mark_leave_screen.dart) and leaves
    // the roster intact, so the day must go quiet WITHOUT the shift being
    // deleted — and the surrounding worked days must be untouched.
    test('leave on one day of a block silences only that day', () {
      final rings = project([
        rotation(type: ShiftType.day)
      ], [
        shift(id: 'd1', date: DateTime(2026, 6, 16)),
        shift(id: 'd2', date: DateTime(2026, 6, 17), isPaused: true), // on leave
        shift(id: 'd3', date: DateTime(2026, 6, 18)),
      ]);
      expect(rings.map((r) => r.shift?.id).toList(), ['d1', 'd3']);
    });

    test('every per-shift suppression flag drops the ring', () {
      for (final s in [
        shift(id: 'm', date: DateTime(2026, 6, 16), isMuted: true),
        shift(id: 'a', date: DateTime(2026, 6, 16), isAcknowledged: true),
        shift(id: 'k', date: DateTime(2026, 6, 16), isAlarmSkipped: true),
        shift(id: 'p', date: DateTime(2026, 6, 16), isPaused: true),
        shift(id: 'x', date: DateTime(2026, 6, 16), isArchived: true),
      ]) {
        expect(project([rotation()], [s]), isEmpty,
            reason: 'suppressed shift ${s.id} must not ring');
      }
    });
  });

  group('projectAlarmRings — per-ring dismissal (multi-alarm shifts)', () {
    test('dismissing one alarm suppresses ONLY its ring — the shift\'s other '
        'alarms keep firing (the blanket-cancel regression)', () {
      // One Day shift, THREE alarms before it: 60-min lead, 30-min lead, and
      // an exact 05:00 ring. The user dismissed the exact-time ring; the two
      // lead rings must survive the projection (and therefore the reconcile).
      final alarms = [
        rotation(id: 'lead60'),
        rotation(id: 'lead30', offset: 30),
        rotation(id: 'exact5', exact: true, exactMin: 5 * 60),
      ];
      final s = shift(
        id: 's',
        date: DateTime(2026, 6, 16),
        dismissedAlarmIds: const ['exact5'],
      );
      final rings = project(alarms, [s]);
      expect(rings.map((r) => r.alarm.id), containsAll(['lead60', 'lead30']));
      expect(rings.map((r) => r.alarm.id), isNot(contains('exact5')));
    });

    test('a dismissed ring is not resurrected by a stale future snooze', () {
      // The shift's snoozedUntil may outlive a dismissal (it can belong to a
      // sibling). The dismissed ring must stay dead regardless.
      final s = shift(
        id: 'snz',
        date: DateTime(2026, 6, 15),
        start: 4 * 60, // normalFireAt 03:00 — past
        end: 12 * 60,
        snoozedUntil: DateTime(2026, 6, 15, 5, 30), // future
        dismissedAlarmIds: const ['r'],
      );
      expect(project([rotation()], [s]), isEmpty);
    });

    test('a dismissal for a DIFFERENT alarm rule leaves the ring alone', () {
      final s = shift(
        id: 's',
        date: DateTime(2026, 6, 16),
        dismissedAlarmIds: const ['someone-else'],
      );
      expect(project([rotation()], [s]), hasLength(1));
    });
  });

  group('projectAlarmRings — shift-less skip watermark (skippedThrough)', () {
    test('a weekly occurrence at-or-before the watermark is suppressed; '
        'later occurrences survive', () {
      // Mon+Tue at 06:00, now Mon 05:00. Skipping Monday's ring (watermark =
      // Mon 06:00) must leave Tuesday's — and every later occurrence — armed.
      final mask = 3; // Mon | Tue
      final rings = project(
        [weekly(mask, 6 * 60, skippedThrough: DateTime(2026, 6, 15, 6, 0))],
        const [],
      );
      final times = rings.map((r) => r.fireAt).toList();
      expect(times, isNot(contains(DateTime(2026, 6, 15, 6, 0))),
          reason: 'the skipped occurrence itself (== watermark) is dropped');
      expect(times, contains(DateTime(2026, 6, 16, 6, 0)));
      expect(times, contains(DateTime(2026, 6, 22, 6, 0)),
          reason: 'next week\'s same-weekday ring fires after the watermark');
    });

    test('sequential weekly skips: an advanced watermark keeps earlier '
        'occurrences suppressed', () {
      // Skip Mon, then Tue: the watermark advances to Tue 06:00 and must
      // still cover Mon (monotonic — never un-skips).
      final rings = project(
        [weekly(3, 6 * 60, skippedThrough: DateTime(2026, 6, 16, 6, 0))],
        const [],
      );
      final times = rings.map((r) => r.fireAt).toList();
      expect(times, isNot(contains(DateTime(2026, 6, 15, 6, 0))));
      expect(times, isNot(contains(DateTime(2026, 6, 16, 6, 0))));
      expect(times, contains(DateTime(2026, 6, 22, 6, 0)));
    });

    test('a one-time occurrence at-or-before the watermark is suppressed '
        '(defensive — the early-skip disables one-times instead)', () {
      expect(
        project(
          [oneTime(6 * 60, skippedThrough: DateTime(2026, 6, 15, 6, 0))],
          const [],
        ),
        isEmpty,
      );
    });

    test('an elapsed (past) watermark is inert', () {
      // Watermark = yesterday: the future-only gate already excludes
      // everything at-or-before it, so today's ring is untouched.
      final rings = project(
        [oneTime(6 * 60, skippedThrough: DateTime(2026, 6, 14, 6, 0))],
        const [],
      );
      expect(rings.single.fireAt, DateTime(2026, 6, 15, 6, 0));
    });

    test('the watermark NEVER affects follows-rotation rings — their '
        'dismissals live on the shift row', () {
      final rings = project(
        // Watermark far in the future — would swallow everything if consulted.
        [rotation(skippedThrough: DateTime(2030, 1, 1))],
        [shift(id: 's', date: DateTime(2026, 6, 16))],
      );
      expect(rings, hasLength(1));
    });
  });

  group('projectAlarmRings — snooze resurrection', () {
    test('a fired (past) occurrence with a future snooze rings at snoozedUntil',
        () {
      // Day shift today 04:00 → normalFireAt 03:00 (past now 05:00); snoozed to
      // 05:30 → the ring is the snooze.
      final s = shift(
        id: 'snz',
        date: DateTime(2026, 6, 15),
        start: 4 * 60,
        end: 12 * 60,
        snoozedUntil: DateTime(2026, 6, 15, 5, 30),
      );
      expect(project([rotation()], [s]).single.fireAt,
          DateTime(2026, 6, 15, 5, 30));
    });

    test('a future occurrence ignores a snooze (siblings keep normal time)', () {
      // normalFireAt is future → snooze is NOT applied even if set.
      final s = shift(
        id: 'fut',
        date: DateTime(2026, 6, 16),
        snoozedUntil: DateTime(2026, 6, 15, 6, 0),
      );
      expect(project([rotation()], [s]).single.fireAt,
          DateTime(2026, 6, 16, 6, 0)); // normal, not the snooze
    });
  });

  // Regression: `nextAlarmRing` used to accept no `oneOffSnoozes` at all and
  // silently project without them. Because the projector's parameter defaults
  // to an empty map, nothing failed — it just answered "nothing upcoming" for a
  // snoozed one-time alarm, minutes before that alarm rang. Every UI caller was
  // affected (the Dashboard skip control, the Alarms-tab "Next ring" label)
  // while the engine, which calls `projectAlarmRings` directly, had it armed.
  // Found on device: no swipe-to-dismiss appeared after snoozing.
  group('nextAlarmRing — forwards one-off snoozes', () {
    test('a snoozed one-time alarm is still the next ring', () {
      // Anchored to 04:30 — already past at `now`, so without the snooze map
      // the anchor rule retires it and NOTHING projects.
      final a = oneTime(
        4 * 60 + 30,
        id: 'o1',
        anchor: DateTime(2026, 6, 15, 4, 30),
      );

      final blind = nextAlarmRing(
        alarms: [a],
        shifts: const [],
        globalLeadMinutes: lead,
        now: now,
      );
      expect(blind, isNull, reason: 'the spent anchor correctly retires it');

      final seeing = nextAlarmRing(
        alarms: [a],
        shifts: const [],
        globalLeadMinutes: lead,
        now: now,
        oneOffSnoozes: {'o1': DateTime(2026, 6, 15, 5, 10)},
      );
      expect(seeing, isNotNull, reason: 'the snooze must resurrect the ring');
      expect(seeing!.fireAt, DateTime(2026, 6, 15, 5, 10));
      expect(seeing.shift, isNull);
    });

    test('agrees with projectAlarmRings, which is what the engine schedules from',
        () {
      final a = oneTime(
        4 * 60 + 30,
        id: 'o1',
        anchor: DateTime(2026, 6, 15, 4, 30),
      );
      final snoozes = {'o1': DateTime(2026, 6, 15, 5, 10)};

      final engineView = projectAlarmRings(
        alarms: [a],
        shifts: const [],
        globalLeadMinutes: lead,
        now: now,
        horizon: horizon,
        oneOffSnoozes: snoozes,
      );
      final uiView = nextAlarmRing(
        alarms: [a],
        shifts: const [],
        globalLeadMinutes: lead,
        now: now,
        horizon: horizon,
        oneOffSnoozes: snoozes,
      );

      // The divergence between these two views WAS the bug.
      expect(engineView, isNotEmpty);
      expect(uiView?.fireAt, engineView.first.fireAt);
    });
  });

  group('projectAlarmRings — one-off snooze resurrection', () {
    List<AlarmRing> projectOneOff(
      List<AppAlarm> alarms,
      Map<String, DateTime> oneOff,
    ) =>
        projectAlarmRings(
          alarms: alarms,
          shifts: const [],
          globalLeadMinutes: lead,
          now: now,
          horizon: horizon,
          oneOffSnoozes: oneOff,
        );

    test('a snoozed one-time alarm rings at the snooze, suppressing the normal '
        'next occurrence', () {
      // One-time at 06:00 (today still future). Snoozed to 05:10 → the ONLY ring
      // is the snooze; tomorrow's 06:00 is suppressed while snoozed.
      final a = oneTime(6 * 60, id: 'o1');
      final rings = projectOneOff(
        [a],
        {'o1': DateTime(2026, 6, 15, 5, 10)},
      );
      expect(rings.single.fireAt, DateTime(2026, 6, 15, 5, 10));
    });

    test('a one-time alarm with no snooze (or an elapsed one) rings normally',
        () {
      final a = oneTime(6 * 60, id: 'o2');
      // No snooze.
      expect(projectOneOff([a], const {}).single.fireAt,
          DateTime(2026, 6, 15, 6, 0));
      // Elapsed snooze (before now) is ignored → normal occurrence.
      expect(
        projectOneOff([a], {'o2': DateTime(2026, 6, 15, 4, 0)}).single.fireAt,
        DateTime(2026, 6, 15, 6, 0),
      );
    });

    test('a snoozed weekly alarm ADDS the snooze ring and keeps future weekdays',
        () {
      // Weekly Mon+Tue at 06:00 (mask: Mon bit0, Tue bit1 = 0b11 = 3). now is
      // Mon 05:00. Snoozed to 05:20.
      final a = weekly(3, 6 * 60, id: 'w1');
      final rings = projectOneOff([a], {'w1': DateTime(2026, 6, 15, 5, 20)});
      final times = rings.map((r) => r.fireAt).toList();
      // The snooze ring is present...
      expect(times, contains(DateTime(2026, 6, 15, 5, 20)));
      // ...AND this Monday's normal 06:00 (still future) and Tuesday's 06:00.
      expect(times, contains(DateTime(2026, 6, 15, 6, 0)));
      expect(times, contains(DateTime(2026, 6, 16, 6, 0)));
    });

    test('one-off snooze does not affect a shift-linked rotation alarm', () {
      // A rotation alarm keyed under the SAME id in the map is unaffected — only
      // one-time/weekly read oneOffSnoozes.
      final r = rotation(id: 'rot');
      final s = shift(id: 's1', date: DateTime(2026, 6, 16));
      final rings = projectAlarmRings(
        alarms: [r],
        shifts: [s],
        globalLeadMinutes: lead,
        now: now,
        horizon: horizon,
        oneOffSnoozes: {'rot': DateTime(2026, 6, 15, 5, 30)},
      );
      expect(rings.single.fireAt, DateTime(2026, 6, 16, 6, 0)); // normal
    });
  });

  group('nextAlarmRing / nextRotationRing', () {
    AlarmRing? nextAny(List<AppAlarm> alarms, List<Shift> shifts) =>
        nextAlarmRing(
          alarms: alarms,
          shifts: shifts,
          globalLeadMinutes: lead,
          now: now,
          horizon: horizon,
        );

    AlarmRing? nextRot(List<AppAlarm> alarms, List<Shift> shifts,
            {bool paused = false}) =>
        nextRotationRing(
          alarms: alarms,
          shifts: shifts,
          globalLeadMinutes: lead,
          now: now,
          horizon: horizon,
          isSchedulePaused: paused,
        );

    test('nextAlarmRing returns the single earliest ring of any type', () {
      final ring = nextAny(
        [oneTime(5 * 60 + 30, id: 'soon'), rotation(id: 'rot')],
        [shift(id: 's', date: DateTime(2026, 6, 16))],
      );
      expect(ring!.alarm.id, 'soon'); // 05:30 today beats 06-16 06:00
    });

    test('nextAlarmRing on a single alarm = that alarm next ring (or null)', () {
      expect(nextAny([rotation()], const []), isNull); // no roster
      expect(
        nextAny([rotation()], [shift(id: 's', date: DateTime(2026, 6, 16))])!
            .shift
            ?.id,
        's',
      );
    });

    test('nextRotationRing returns the earliest SHIFT-LINKED ring', () {
      final ring = nextRot(
        // A one-time at 05:30 is sooner, but the hero/early-skip are shift-only.
        [oneTime(5 * 60 + 30, id: 'soon'), rotation(id: 'rot')],
        [shift(id: 's', date: DateTime(2026, 6, 16))],
      );
      expect(ring!.alarm.id, 'rot');
      expect(ring.shift?.id, 's');
    });

    test('nextRotationRing is null under Holiday Mode', () {
      expect(
        nextRot([rotation()], [shift(id: 's', date: DateTime(2026, 6, 16))],
            paused: true),
        isNull,
      );
    });

    test('nextRotationRing ignores a paused shift (early-skip regression)', () {
      expect(
        nextRot([rotation()],
            [shift(id: 'p', date: DateTime(2026, 6, 16), isPaused: true)]),
        isNull,
      );
    });
  });
}
