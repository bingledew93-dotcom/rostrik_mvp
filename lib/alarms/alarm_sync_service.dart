import 'dart:async';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../data/models/shift_cycle.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/app_alarm_repository.dart';
import '../data/repositories/shift_cycle_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../util/clock.dart';
import 'alarm_scheduler.dart';
import 'notification_id_map.dart';

/// Payload sentinel for alarms with no linked shift (one-time alarms,
/// future custom-repeat / bundle alarms). Replaces the shiftId field
/// in the `<shiftId>|<notificationId>` payload contract. WakeUpScreen
/// treats this as "render a generic 'Alarm' title; do not hit Hive".
const String noShiftPayloadSentinel = 'NONE';

/// Hive key under which the persisted `_scheduledFireAt` map lives in
/// the (always-open) `settings` box. Stored as `Map<int, int>` —
/// notification id → fireAt epoch millis. Hydrated on `start()` BEFORE
/// the initial sync so a cold launch does not unconditionally re-issue
/// `scheduleAt` for every desired id (previously a measurable
/// platform-channel burst on budget Android).
const String _scheduledFireAtSettingsKey = 'alarm_sync.scheduled_fire_at';

/// Drives OS alarm scheduling from [AppAlarm] rules.
///
/// Where the legacy `AlarmEngine` was shift-centric (one OS alarm per
/// upcoming non-OFF shift, fired at `startDateTime - leadTime`), this
/// service is alarm-centric:
///
///   * One-time alarms ([AppAlarmRepeatType.oneTime]) → one OS alarm
///     at the next future occurrence of `minutesOfDay` (today if still
///     in the future, else tomorrow).
///   * Follows-rotation alarms ([AppAlarmRepeatType.followsRotation]) →
///     one OS alarm per matching shift in the rolling [horizon] at
///     `shift.date + minutesOfDay` (exact mode) or
///     `shift.startDateTime - relativeOffsetMinutes` (relative mode).
///     "Matching" means the shift's type equals the alarm's
///     `linkedShiftType`; alarms with `null` `linkedShiftType` are
///     skipped as invalid configuration.
///
/// Scheduling guard rails (both hard caps; whichever triggers first):
///   * [horizon] — 14 days. The OS pending queue is a near-future
///     snapshot; longer-term coverage is the responsibility of the
///     Phase 2 background-refresh path. Keeping the window small also
///     keeps the iOS pending-notification ceiling (64) out of reach.
///   * [maxScheduled] — 50. Dense rosters (4-on/4-off + multiple
///     alarms per shift + relative-time entries) can produce more
///     than 50 entries inside 14 days. Sorted by fireAt and trimmed
///     to the earliest 50; the dropped tail is re-considered on the
///     next reconcile as the window rolls forward.
///
/// Trigger contract: [syncAlarms] runs on every `AppAlarm` change,
/// every `ShiftCycle` change, AND every `Shift` change inside the
/// horizon. Debounced 250 ms so a bulk Generate (which writes hundreds
/// of shifts in tight succession) produces a single reconcile.
class AlarmSyncService {
  AlarmSyncService({
    required AppAlarmRepository alarms,
    required ShiftRepository shifts,
    required ShiftCycleRepository cycles,
    required AlarmScheduler scheduler,
    required NotificationIdMap idMap,
    required Clock clock,
    Duration horizon = const Duration(days: 14),
    int maxScheduled = 50,
    Duration debounceWindow = const Duration(milliseconds: 250),
  })  : _alarms = alarms,
        _shifts = shifts,
        _cycles = cycles,
        _scheduler = scheduler,
        _idMap = idMap,
        _clock = clock,
        _horizon = horizon,
        _maxScheduled = maxScheduled,
        _debounceWindow = debounceWindow;

  final AppAlarmRepository _alarms;
  final ShiftRepository _shifts;
  final ShiftCycleRepository _cycles;
  final AlarmScheduler _scheduler;
  final NotificationIdMap _idMap;
  final Clock _clock;
  final Duration _horizon;
  final int _maxScheduled;
  final Duration _debounceWindow;

  StreamSubscription<List<AppAlarm>>? _alarmsSub;
  StreamSubscription<List<ShiftCycle>>? _cyclesSub;
  StreamSubscription<List<Shift>>? _shiftsSub;
  Timer? _debounceTimer;

  /// In-flight sync queue. New calls chain onto the tail of the
  /// previous sync so two concurrent triggers can't race on the
  /// `_scheduledFireAt` map or on `idMap.idFor`'s non-atomic
  /// read-modify-write.
  Future<void> _inFlight = Future<void>.value();

  /// Last fireAt we asked the scheduler for, keyed by notification id.
  /// Persisted via [_persistScheduledFireAt] at the tail of every
  /// `_doSync` and hydrated by [_hydrateScheduledFireAt] in `start()`
  /// — so cold start can skip the scheduleAt call for any id where the
  /// OS pending set and our persisted fireAt already agree.
  final Map<int, DateTime> _scheduledFireAt = {};

  /// Performs an initial sync, then re-syncs on every `AppAlarm`,
  /// `ShiftCycle`, OR `Shift` change. Stream-driven syncs are
  /// debounced; the initial sync is awaited directly so [start] only
  /// returns once the OS state has converged.
  Future<void> start() async {
    _hydrateScheduledFireAt();
    await syncAlarms();
    final now = _clock.now();
    _alarmsSub = _alarms.watch().skip(1).listen(
          (_) => _scheduleDebouncedSync(),
        );
    _cyclesSub = _cycles.watch().skip(1).listen(
          (_) => _scheduleDebouncedSync(),
        );
    // A direct shift mutation (manual time edit, mute toggle, dismiss
    // or snooze write from the foreground/background dispatcher) used
    // to escape the reconcile because we only watched alarms + cycles.
    // The watch window matches the scheduling horizon: events outside
    // it cannot affect the current pending OS set.
    _shiftsSub = _shifts
        .watchInRange(now, now.add(_horizon))
        .skip(1)
        .listen((_) => _scheduleDebouncedSync());
  }

  Future<void> stop() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _alarmsSub?.cancel();
    await _cyclesSub?.cancel();
    await _shiftsSub?.cancel();
    _alarmsSub = null;
    _cyclesSub = null;
    _shiftsSub = null;
  }

  /// Re-arms the debounce timer; after [_debounceWindow] of quiet,
  /// fires exactly one [syncAlarms]. Safe to fire-and-forget because
  /// concurrent syncs queue on `_inFlight`.
  void _scheduleDebouncedSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceWindow, () {
      _debounceTimer = null;
      syncAlarms();
    });
  }

  /// Public reconciler. Computes the desired set of OS alarms based on
  /// the current AppAlarm + Shift state, cancels orphans, schedules
  /// (or replaces) the rest. Idempotent — running twice with no input
  /// change produces zero scheduler mutations.
  Future<void> syncAlarms() {
    final next = _inFlight.then((_) => _doSync());
    _inFlight = next.catchError((_) {});
    return next;
  }

  Future<void> _doSync() async {
    final now = _clock.now();
    final until = now.add(_horizon);

    final allAlarms = await _alarms.getAll();
    final enabledAlarms = allAlarms.where((a) => a.enabled).toList();

    // Materialise shifts ONCE for the whole sync — every
    // followsRotation alarm walks the same date window, so reading
    // the box once is O(box). The horizon is now 14 days, so the
    // walk is tiny even on dense rosters.
    final shiftsInWindow = await _shifts.getInRange(now, until);

    final entries = <_Entry>[];
    for (final alarm in enabledAlarms) {
      switch (alarm.repeatType) {
        case AppAlarmRepeatType.oneTime:
          final fireAt = _nextOneTimeOccurrence(alarm, now);
          // 14-day cap also applies to oneTime: a oneTime alarm whose
          // next occurrence lands past the horizon is dropped from
          // this sync and re-considered as the window rolls forward.
          // In practice oneTime can only push out to "tomorrow" via
          // _nextOneTimeOccurrence, so this branch is defensive.
          if (!fireAt.isBefore(until)) continue;
          entries.add(
            _Entry(alarm: alarm, fireAt: fireAt, dateKey: _dateKey(fireAt)),
          );
        case AppAlarmRepeatType.followsRotation:
          final type = alarm.linkedShiftType;
          if (type == null) continue; // invalid config — skip
          for (final s in shiftsInWindow) {
            if (s.type != type) continue;

            // Shift-level alarm suppression — ports the legacy
            // AlarmEngine's filters into the alarm-rule-centric world.
            // Both flags survive cold start because they're persisted
            // on the Shift record:
            //   * isMuted: user swiped "mute this occurrence" in the
            //     roster. Phase-3 emergency-mute UX. Every alarm
            //     linked to this shift is dropped; the orphan-cancel
            //     loop below tears down any pending OS notification.
            //   * isAcknowledged: the user already handled this
            //     occurrence's alarm via Dismiss (foreground or
            //     background dispatcher). Re-scheduling would
            //     resurrect a dismissed alarm — never desired, and
            //     the reason this filter existed in the legacy engine.
            if (s.isMuted) continue;
            if (s.isAcknowledged) continue;

            // Two fireAt computations based on the alarm's time mode:
            //   * Exact:    shift.date + minutesOfDay
            //   * Relative: shift.startDateTime - relativeOffsetMinutes
            // Both routes use calendar-math reconstruction of the
            // shift's date components (DST-safe).
            final DateTime normalFireAt;
            if (alarm.isRelativeTime) {
              final shiftStart = DateTime(
                s.date.year,
                s.date.month,
                s.date.day,
                s.startMinutes ~/ 60,
                s.startMinutes % 60,
              );
              normalFireAt = shiftStart.subtract(
                Duration(minutes: alarm.relativeOffsetMinutes),
              );
            } else {
              normalFireAt = _fireAtFor(s, alarm.minutesOfDay);
            }

            // Snoozed-alarm resurrection. When the user taps Snooze,
            // the dispatcher writes `shift.snoozedUntil` AND reschedules
            // the SAME notification id to that instant. On the next
            // reconcile we MUST converge to the dispatcher's schedule
            // or the cancel-orphans pass below would tear down the
            // snooze. The legacy AlarmEngine handled this by pinning
            // unconditionally to snoozedUntil — fine in its 1:1
            // alarm:shift world.
            //
            // In AlarmSyncService's 1:N world (multiple alarms per
            // shift), pinning unconditionally would drag sibling
            // alarms forward too — snoozing the 06:00 wake-up would
            // also reschedule the 06:30 leave-for-work alarm to 06:09,
            // firing two alarms simultaneously. So we only pin when
            // the normal fireAt is already in the past, i.e. THIS
            // alarm has fired and the user has snoozed it. Siblings
            // whose normal fireAt is still in the future use their
            // original schedule.
            final snoozed = s.snoozedUntil;
            final DateTime fireAt;
            if (snoozed != null &&
                snoozed.isAfter(now) &&
                !normalFireAt.isAfter(now)) {
              fireAt = snoozed;
            } else {
              fireAt = normalFireAt;
            }

            if (!fireAt.isAfter(now)) continue;
            // Hard horizon trim — an alarm whose relative-mode offset
            // pushes its fireAt onto the previous calendar day must
            // still respect the window boundary on both ends.
            if (!fireAt.isBefore(until)) continue;
            entries.add(
              _Entry(
                alarm: alarm,
                fireAt: fireAt,
                dateKey: _dateKey(fireAt),
                shift: s,
              ),
            );
          }
      }
    }

    // Earliest first, then trim to the alarm cap. With the 14-day
    // horizon this is normally a no-op, but a dense roster
    // (e.g. follows-rotation Day + Night + relative wake-up + leave-
    // for-work alarm × 4-on/4-off) can clear 50 entries inside 14
    // days. The trimmed tail is re-considered on the next reconcile.
    entries.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    final capped = entries.take(_maxScheduled).toList();

    final desired = <int, _Entry>{};
    for (final e in capped) {
      final id = await _idMap.idFor('${e.alarm.id}@${e.dateKey}');
      // Different AppAlarms can't collide on (alarmId, dateKey) — alarm
      // ids are UUIDs — but keep the earliest-fireAt tie-breaker as
      // belt-and-braces against future composite-key schema changes.
      final existing = desired[id];
      if (existing == null || e.fireAt.isBefore(existing.fireAt)) {
        desired[id] = e;
      }
    }

    final pending = await _scheduler.pendingIds();

    // Cancel orphans: pending OS alarms whose id is no longer desired.
    for (final id in pending) {
      if (!desired.containsKey(id)) {
        await _scheduler.cancel(id);
        _scheduledFireAt.remove(id);
      }
    }

    // Drop persisted entries the OS no longer knows about AND we no
    // longer want (e.g. they fired while the app was killed, then the
    // user's roster changed so they're not desired any more). Without
    // this, the persisted map would accumulate dead ids over the life
    // of the install.
    _scheduledFireAt.removeWhere(
      (id, _) => !pending.contains(id) && !desired.containsKey(id),
    );

    // Insert / replace. Three conditions decide whether we issue a
    // platform-channel call:
    //   1. We have no record of this id (first-time schedule, or hot
    //      restart that wiped the in-memory map but the persisted
    //      hydrate didn't cover it).
    //   2. The OS pending set has lost this id (alarm fired while the
    //      app was killed, or was nuked by an OEM optimisation).
    //   3. Our last-known fireAt has drifted from desired (alarm time
    //      change, shift edit, snooze write — exactly the bridge the
    //      _shiftsSub now feeds).
    // The combined gate means a cold start where persisted state and
    // OS pending state agree issues zero platform calls — fixing the
    // pre-refactor cold-start burst.
    for (final entry in desired.entries) {
      final id = entry.key;
      final desiredFireAt = entry.value.fireAt;
      final lastKnown = _scheduledFireAt[id];
      final osHasIt = pending.contains(id);
      final needsSchedule =
          lastKnown == null || !osHasIt || lastKnown != desiredFireAt;
      if (!needsSchedule) continue;
      await _scheduler.scheduleAt(
        id: id,
        fireAt: desiredFireAt,
        title: _titleFor(entry.value.alarm),
        body: _bodyFor(entry.value.alarm, entry.value.fireAt),
        // Payload contract: `<shiftId-or-'NONE'>|<notificationId>`.
        // Parsed by `_parseWakeUpRoute` in main.dart and
        // `_ShiftSummary` in wake_up_screen.dart.
        payload: '${entry.value.shift?.id ?? noShiftPayloadSentinel}|$id',
      );
      _scheduledFireAt[id] = desiredFireAt;
    }

    await _persistScheduledFireAt();
  }

  /// Reads the persisted `_scheduledFireAt` map from the `settings`
  /// box into memory. Best-effort — the box is opened in `main()` on
  /// the live app but may not exist under the test harness, which
  /// constructs the service without bootstrapping Hive. Any failure
  /// here is silently swallowed and the in-memory map stays empty;
  /// the next sync will re-populate it via fresh `scheduleAt` calls.
  void _hydrateScheduledFireAt() {
    try {
      if (!Hive.isBoxOpen('settings')) return;
      final raw = Hive.box('settings').get(_scheduledFireAtSettingsKey);
      if (raw is! Map) return;
      raw.forEach((k, v) {
        final id = (k is int) ? k : int.tryParse(k.toString());
        final ms = (v is int) ? v : int.tryParse(v.toString());
        if (id == null || ms == null) return;
        _scheduledFireAt[id] = DateTime.fromMillisecondsSinceEpoch(ms);
      });
    } catch (_) {
      // Tests don't open the settings box. Cold start without
      // persisted state simply degrades to the old behaviour.
    }
  }

  /// Writes the current `_scheduledFireAt` snapshot back to the
  /// `settings` box. Called at the tail of every `_doSync`. One key,
  /// one put — the whole map serialises as a `Map<int, int>` so the
  /// hydrate path can decode it without an adapter.
  Future<void> _persistScheduledFireAt() async {
    try {
      if (!Hive.isBoxOpen('settings')) return;
      final encoded = <int, int>{
        for (final e in _scheduledFireAt.entries)
          e.key: e.value.millisecondsSinceEpoch,
      };
      await Hive.box('settings').put(_scheduledFireAtSettingsKey, encoded);
    } catch (_) {
      // Same rationale as _hydrateScheduledFireAt — persistence is
      // best-effort. A failed put just means the next cold start
      // re-issues the platform calls we already issued this run.
    }
  }

  /// Next future occurrence of [alarm.minutesOfDay] in local time:
  /// today if [alarm.minutesOfDay] is still after [now], else tomorrow.
  DateTime _nextOneTimeOccurrence(AppAlarm alarm, DateTime now) {
    final today = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.minutesOfDay ~/ 60,
      alarm.minutesOfDay % 60,
    );
    if (today.isAfter(now)) return today;
    return DateTime(
      now.year,
      now.month,
      now.day + 1,
      alarm.minutesOfDay ~/ 60,
      alarm.minutesOfDay % 60,
    );
  }

  /// Compose a fire instant from a shift's calendar date and an
  /// alarm's `minutesOfDay`. Calendar math throughout for DST safety.
  DateTime _fireAtFor(Shift shift, int minutesOfDay) {
    return DateTime(
      shift.date.year,
      shift.date.month,
      shift.date.day,
      minutesOfDay ~/ 60,
      minutesOfDay % 60,
    );
  }

  /// `2026-05-22` — the date-only ISO portion. Used as part of the
  /// composite id-map key so a per-day alarm gets a stable id within
  /// a day and a fresh id on the next day.
  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _titleFor(AppAlarm a) => a.label.isEmpty ? 'Alarm' : a.label;

  String _bodyFor(AppAlarm a, DateTime fireAt) {
    final hh = (fireAt.hour).toString().padLeft(2, '0');
    final mm = (fireAt.minute).toString().padLeft(2, '0');
    final type = a.linkedShiftType;
    if (a.repeatType == AppAlarmRepeatType.followsRotation && type != null) {
      if (a.isRelativeTime) {
        return '${_offsetLabel(a.relativeOffsetMinutes)} before your '
            '${_typeLabel(type)} shift';
      }
      return 'Before your ${_typeLabel(type)} shift · $hh:$mm';
    }
    return 'Rings at $hh:$mm';
  }

  static String _offsetLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String _typeLabel(ShiftType t) {
    switch (t) {
      case ShiftType.day:
        return 'Day';
      case ShiftType.afternoon:
        return 'Afternoon';
      case ShiftType.night:
        return 'Night';
      case ShiftType.off:
        return 'Off';
    }
  }
}

class _Entry {
  _Entry({
    required this.alarm,
    required this.fireAt,
    required this.dateKey,
    this.shift,
  });
  final AppAlarm alarm;
  final DateTime fireAt;
  final String dateKey;

  /// Null for oneTime alarms (and any future repeat type that fires
  /// without a linked shift). Populated for followsRotation entries
  /// so the scheduler can emit the `<shiftId>|<notificationId>`
  /// payload the WakeUpScreen expects.
  final Shift? shift;
}
