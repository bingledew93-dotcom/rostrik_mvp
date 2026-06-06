import 'dart:async';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/models/alarm_settings.dart';
import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../data/models/shift_cycle.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/alarm_settings_repository.dart';
import '../data/repositories/app_alarm_repository.dart';
import '../data/repositories/shift_cycle_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../util/clock.dart';
import '../util/weekday_mask.dart';
import 'alarm_payload.dart';
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

/// Holiday-Mode flag key in the (always-open) `settings` box. MUST match
/// `AppPreferences.isSchedulePausedKey` — both isolates read the same box, so a
/// pause toggled in the UI is honoured by the headless background re-sync too.
const String _isSchedulePausedSettingsKey = 'isSchedulePaused';

/// Default pause source: reads the Holiday-Mode flag straight off the `settings`
/// box. Best-effort + guarded exactly like [_hydrateScheduledFireAt] so the
/// test harness (which never opens the box) simply reads "not paused".
bool _readSchedulePausedFromSettings() {
  try {
    if (!Hive.isBoxOpen('settings')) return false;
    return Hive.box('settings')
        .get(_isSchedulePausedSettingsKey, defaultValue: false) as bool;
  } catch (_) {
    return false;
  }
}

/// Drives OS alarm scheduling from [AppAlarm] rules. Alarm-centric: it
/// reconciles the desired OS pending set from the enabled alarms + the shift
/// roster + the global [AlarmSettings].
///
///   * One-time alarms ([AppAlarmRepeatType.oneTime]) → one OS alarm
///     at the next future occurrence of `minutesOfDay` (today if still
///     in the future, else tomorrow).
///   * Follows-rotation alarms ([AppAlarmRepeatType.followsRotation]) →
///     one OS alarm per matching shift in the rolling [horizon], fired at
///     `shiftStart − leadTime`. The lead time is the alarm's
///     `relativeOffsetMinutes` when set (a per-alarm OVERRIDE), else the
///     global `AlarmSettings.leadTime` (the default). There is no
///     absolute-clock-time mode — a fixed time can't track a moving shift.
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
///     alarms per shift) can produce more than 50 entries inside 14
///     days. Sorted by fireAt and trimmed to the earliest 50; the
///     dropped tail is re-considered on the next reconcile as the
///     window rolls forward.
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
    required AlarmSettingsRepository alarmSettings,
    required AlarmScheduler scheduler,
    required NotificationIdMap idMap,
    required Clock clock,
    Duration horizon = const Duration(days: 14),
    int maxScheduled = 50,
    Duration debounceWindow = const Duration(milliseconds: 250),
    bool Function()? isPaused,
  })  : _alarms = alarms,
        _shifts = shifts,
        _cycles = cycles,
        _alarmSettings = alarmSettings,
        _scheduler = scheduler,
        _idMap = idMap,
        _clock = clock,
        _horizon = horizon,
        _maxScheduled = maxScheduled,
        _debounceWindow = debounceWindow,
        // Default reads the `settings` box (covers foreground AND the headless
        // background isolate); tests inject a closure to exercise the branch.
        _isPaused = isPaused ?? _readSchedulePausedFromSettings;

  final AppAlarmRepository _alarms;
  final ShiftRepository _shifts;
  final ShiftCycleRepository _cycles;
  final AlarmSettingsRepository _alarmSettings;
  final AlarmScheduler _scheduler;
  final NotificationIdMap _idMap;
  final Clock _clock;
  final Duration _horizon;
  final int _maxScheduled;
  final Duration _debounceWindow;

  /// Holiday-Mode gate, read fresh on every sync. When it returns true the
  /// desired OS alarm set is forced empty (see [_doSync]).
  final bool Function() _isPaused;

  StreamSubscription<List<AppAlarm>>? _alarmsSub;
  StreamSubscription<List<ShiftCycle>>? _cyclesSub;
  StreamSubscription<List<Shift>>? _shiftsSub;
  StreamSubscription<AlarmSettings>? _settingsSub;
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
    // The global lead time is the default fireAt offset for every
    // followsRotation alarm, so changing it must re-arm the pending set —
    // this is the wiring whose absence orphaned the Settings slider before.
    _settingsSub = _alarmSettings.watch().skip(1).listen(
          (_) => _scheduleDebouncedSync(),
        );
  }

  Future<void> stop() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _alarmsSub?.cancel();
    await _cyclesSub?.cancel();
    await _shiftsSub?.cancel();
    await _settingsSub?.cancel();
    _alarmsSub = null;
    _cyclesSub = null;
    _shiftsSub = null;
    _settingsSub = null;
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

  /// Primes the in-memory `_scheduledFireAt` map from the persisted
  /// `settings` snapshot WITHOUT starting any stream subscriptions or
  /// running a sync. [start] already does this internally; the native
  /// background re-sync entrypoint calls [syncAlarms] directly (never
  /// [start]), so it needs this public hook to prime the map before its
  /// one-shot reconcile — otherwise every background run treats every id
  /// as new and re-issues `scheduleAt` for the entire desired set,
  /// defeating the platform-channel-burst avoidance the persistence layer
  /// exists for. Best-effort + idempotent: a no-op when the `settings`
  /// box isn't open (e.g. under the test harness).
  void hydrate() => _hydrateScheduledFireAt();

  Future<void> _doSync() async {
    final now = _clock.now();
    final until = now.add(_horizon);

    final allAlarms = await _alarms.getAll();
    // Holiday Mode (global pause): disarm everything WITHOUT mutating the
    // roster or alarm rules. Forcing the enabled set empty makes `desired`
    // empty, so the cancel-orphans pass below tears down every pending OS
    // alarm and nothing is re-scheduled. Flip the flag back off and the next
    // reconcile rebuilds the whole set from the untouched Hive data.
    final enabledAlarms = _isPaused()
        ? const <AppAlarm>[]
        : allAlarms.where((a) => a.enabled).toList();

    // Global alarm settings, read once per sync. Supplies the DEFAULT lead-time
    // offset for every followsRotation alarm without a per-alarm override, plus
    // the custom-ringtone path that rides the payload as forward-plumbing.
    final settings = await _alarmSettings.read();
    final globalLeadMinutes = settings.leadTime.inMinutes;

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
        case AppAlarmRepeatType.weekly:
          // Standard day-of-week recurring alarm, independent of the roster.
          // Materialise one concrete OS alarm per selected weekday that lands
          // inside the horizon — the same per-occurrence model as
          // followsRotation, so it inherits the idempotent reconcile, the
          // earliest-50 cap, and the native background re-sync that rolls the
          // window forward (no FLN native-repeat path to keep in sync). With a
          // 14-day horizon a full 7-day mask yields ≤14 entries.
          final mask = alarm.weekdaysBitmask;
          if (mask == 0) continue; // no day selected — nothing to schedule
          // Walk calendar days with DST-safe `+1` increments (Duration math
          // would drift across a spring-forward boundary). `now` itself is
          // included so today's still-future occurrence is caught.
          for (var d = DateTime(now.year, now.month, now.day);
              d.isBefore(until);
              d = DateTime(d.year, d.month, d.day + 1)) {
            if (!maskHasWeekday(mask, d.weekday)) continue;
            final fireAt = DateTime(
              d.year,
              d.month,
              d.day,
              alarm.minutesOfDay ~/ 60,
              alarm.minutesOfDay % 60,
            );
            if (!fireAt.isAfter(now)) continue;
            if (!fireAt.isBefore(until)) continue;
            entries.add(
              _Entry(
                alarm: alarm,
                fireAt: fireAt,
                dateKey: _dateKey(fireAt),
              ),
            );
          }
        case AppAlarmRepeatType.followsRotation:
          final type = alarm.linkedShiftType;
          if (type == null) continue; // invalid config — skip
          for (final s in shiftsInWindow) {
            if (s.type != type) continue;

            // Shift-level alarm suppression. Both flags survive cold start
            // because they're persisted on the Shift record:
            //   * isMuted: user swiped "mute this occurrence" in the
            //     roster. Phase-3 emergency-mute UX. Every alarm
            //     linked to this shift is dropped; the orphan-cancel
            //     loop below tears down any pending OS notification.
            //   * isAcknowledged: the user already handled this
            //     occurrence's alarm via Dismiss (foreground or
            //     background dispatcher). Re-scheduling would
            //     resurrect a dismissed alarm — never desired.
            //   * isAlarmSkipped: the user tapped "Dismiss Upcoming
            //     Alarm" on the Dashboard to skip THIS occurrence
            //     ahead of time (they woke before the alarm). Same
            //     suppress-and-cancel treatment as the two above, but a
            //     distinct flag so the Dashboard's next-shift card
            //     still shows the shift (see Shift.isAlarmSkipped).
            if (s.isMuted) continue;
            if (s.isAcknowledged) continue;
            if (s.isAlarmSkipped) continue;

            // followsRotation alarms ALWAYS fire relative to the shift start —
            // an absolute clock time can't track a shift that moves, which is
            // the whole point of the app. The lead time is the per-alarm
            // override when set, else the global default.
            //
            // DST-safe by construction: the offset is folded into the minute
            // field and the DateTime constructor normalises the (possibly
            // negative) result in LOCAL time. Unlike `Duration` subtraction,
            // an offset that crosses midnight or a DST boundary lands on the
            // correct local wall-clock time.
            final leadMinutes =
                alarm.relativeOffsetMinutes ?? globalLeadMinutes;
            final normalFireAt = DateTime(
              s.date.year,
              s.date.month,
              s.date.day,
              s.startMinutes ~/ 60,
              s.startMinutes % 60 - leadMinutes,
            );

            // Snoozed-alarm resurrection. When the user taps Snooze,
            // the dispatcher writes `shift.snoozedUntil` AND reschedules
            // the SAME notification id to that instant. On the next
            // reconcile we MUST converge to the dispatcher's schedule
            // or the cancel-orphans pass below would tear down the
            // snooze. A naive 1:1 alarm:shift model could pin
            // unconditionally to snoozedUntil; we can't, because this is a
            // 1:N world (multiple alarms per
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
        soundKey: entry.value.alarm.soundKey,
        // Canonical 4-field payload — see [AlarmPayload]. Carries the shift id
        // (or 'NONE' sentinel), the OS notification id, the dismiss code
        // (critical vs normal wake mechanics), and the bundled-tone key so the
        // killed-app snooze reschedule keeps the user's chosen sound.
        payload: AlarmPayload.encode(
          shiftId: entry.value.shift?.id ?? noShiftPayloadSentinel,
          notificationId: id,
          isCritical: entry.value.alarm.isCriticalShift,
          soundKey: entry.value.alarm.soundKey,
          // Owning rule id so a dismiss can auto-delete a fired one-time alarm
          // — even from a killed state where the notification id alone can't be
          // reversed to a rule. Harmless for non-auto-delete alarms.
          appAlarmId: entry.value.alarm.id,
          // Global custom ringtone (forward-plumbing; no native consumer yet).
          customRingtoneUri: settings.customRingtoneUri,
        ),
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

  /// `2026-05-22` — the date-only ISO portion. Used as part of the
  /// composite id-map key so a per-day alarm gets a stable id within
  /// a day and a fresh id on the next day.
  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _titleFor(AppAlarm a) => a.label.isEmpty ? 'Alarm' : a.label;

  String _bodyFor(AppAlarm a, DateTime fireAt) {
    final hh = fireAt.hour.toString().padLeft(2, '0');
    final mm = fireAt.minute.toString().padLeft(2, '0');
    final type = a.linkedShiftType;
    if (a.repeatType == AppAlarmRepeatType.followsRotation && type != null) {
      // followsRotation is always relative now; the fireAt already encodes the
      // (global or overridden) lead time, so just surface when it rings.
      return 'Before your ${_typeLabel(type)} shift · $hh:$mm';
    }
    return 'Rings at $hh:$mm';
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
