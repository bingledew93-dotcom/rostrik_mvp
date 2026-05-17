import 'dart:async';

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

/// Drives OS alarm scheduling from [AppAlarm] rules — the next-phase
/// successor to `AlarmEngine`.
///
/// Where the old engine was shift-centric (one OS alarm per upcoming
/// non-OFF shift, fired at `startDateTime - leadTime`), this service is
/// alarm-centric:
///
///   * One-time alarms ([AppAlarmRepeatType.oneTime]) → one OS alarm
///     at the next future occurrence of `minutesOfDay` (today if still
///     in the future, else tomorrow).
///   * Follows-rotation alarms ([AppAlarmRepeatType.followsRotation]) →
///     one OS alarm per matching shift in the next 365 days at
///     `shift.date + minutesOfDay`. "Matching" means the shift's type
///     equals the alarm's `linkedShiftType`; alarms with `null`
///     `linkedShiftType` are skipped as invalid configuration.
///
/// Trigger contract: [syncAlarms] runs on every `AppAlarm` change AND
/// every `ShiftCycle` change. Debounced 250 ms so a bulk Generate
/// (which writes 365 shifts + one cycle row in tight succession)
/// produces a single reconcile, not 366.
class AlarmSyncService {
  AlarmSyncService({
    required AppAlarmRepository alarms,
    required ShiftRepository shifts,
    required ShiftCycleRepository cycles,
    required AlarmScheduler scheduler,
    required NotificationIdMap idMap,
    required Clock clock,
    Duration horizon = const Duration(days: 365),
    Duration debounceWindow = const Duration(milliseconds: 250),
  })  : _alarms = alarms,
        _shifts = shifts,
        _cycles = cycles,
        _scheduler = scheduler,
        _idMap = idMap,
        _clock = clock,
        _horizon = horizon,
        _debounceWindow = debounceWindow;

  final AppAlarmRepository _alarms;
  final ShiftRepository _shifts;
  final ShiftCycleRepository _cycles;
  final AlarmScheduler _scheduler;
  final NotificationIdMap _idMap;
  final Clock _clock;
  final Duration _horizon;
  final Duration _debounceWindow;

  StreamSubscription<List<AppAlarm>>? _alarmsSub;
  StreamSubscription<List<ShiftCycle>>? _cyclesSub;
  Timer? _debounceTimer;

  /// In-flight sync queue. New calls chain onto the tail of the
  /// previous sync so two concurrent triggers can't race on the
  /// `_scheduledFireAt` map or on `idMap.idFor`'s non-atomic
  /// read-modify-write. Modelled after `AlarmEngine._inFlight`.
  Future<void> _inFlight = Future<void>.value();

  /// Last fireAt we asked the scheduler for, keyed by notification id.
  /// Lets reconcile detect drift (e.g. the user changed an alarm's
  /// `minutesOfDay` or shifted the linked cycle dates) without
  /// re-scheduling identical entries on every tick.
  final Map<int, DateTime> _scheduledFireAt = {};

  /// Performs an initial sync, then re-syncs on every
  /// `AppAlarmRepository` or `ShiftCycleRepository` change. Stream-
  /// driven syncs are debounced; the initial sync is awaited directly
  /// so [start] only returns once the OS state has converged.
  Future<void> start() async {
    await syncAlarms();
    _alarmsSub = _alarms.watch().skip(1).listen(
          (_) => _scheduleDebouncedSync(),
        );
    _cyclesSub = _cycles.watch().skip(1).listen(
          (_) => _scheduleDebouncedSync(),
        );
  }

  Future<void> stop() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _alarmsSub?.cancel();
    await _cyclesSub?.cancel();
    _alarmsSub = null;
    _cyclesSub = null;
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
    // the box once is O(box). We could index by type if perf bites,
    // but at app scale (hundreds of shifts × low single digits of
    // alarms) the linear filter is fine.
    final shiftsInWindow = await _shifts.getInRange(now, until);

    // Collect (key, fireAt, alarm) tuples. The key is a stable
    // (alarmId, isoDate) composite so the same alarm-on-the-same-day
    // gets the same notification id across reconciles — required for
    // FLN's id-based replace semantics to work idempotently.
    final entries = <_Entry>[];
    for (final alarm in enabledAlarms) {
      switch (alarm.repeatType) {
        case AppAlarmRepeatType.oneTime:
          final fireAt = _nextOneTimeOccurrence(alarm, now);
          entries.add(
            _Entry(alarm: alarm, fireAt: fireAt, dateKey: _dateKey(fireAt)),
          );
        case AppAlarmRepeatType.followsRotation:
          final type = alarm.linkedShiftType;
          if (type == null) continue; // invalid config — skip
          for (final s in shiftsInWindow) {
            if (s.type != type) continue;
            // Two fireAt computations based on the alarm's time mode:
            //   * Exact:    shift.date + minutesOfDay
            //   * Relative: shift.startDateTime - relativeOffsetMinutes
            // Both routes use calendar-math reconstruction of the
            // shift's date components (DST-safe; see the prior DST
            // audit). For the relative branch, subtracting a Duration
            // of < 24h from a freshly-constructed local DateTime is
            // inherently safe — the absolute instant moves by exactly
            // that many minutes regardless of DST boundaries, and the
            // user-perceived "minutes before my shift" stays correct.
            final DateTime fireAt;
            if (alarm.isRelativeTime) {
              final shiftStart = DateTime(
                s.date.year,
                s.date.month,
                s.date.day,
                s.startMinutes ~/ 60,
                s.startMinutes % 60,
              );
              fireAt = shiftStart.subtract(
                Duration(minutes: alarm.relativeOffsetMinutes),
              );
            } else {
              fireAt = _fireAtFor(s, alarm.minutesOfDay);
            }
            if (!fireAt.isAfter(now)) continue;
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

    // Resolve every entry to a stable notification id via the shared
    // map. The composite key is what makes "same alarm, same day"
    // collide with a previous reconcile's allocation; different days
    // get different ids automatically.
    final desired = <int, _Entry>{};
    for (final e in entries) {
      final id = await _idMap.idFor('${e.alarm.id}@${e.dateKey}');
      // If two AppAlarms happen to compute the same (alarmId, dateKey)
      // — they can't, since alarmIds are UUIDs — `desired[id] = e`
      // would clobber. Belt-and-braces: keep the earliest fireAt.
      final existing = desired[id];
      if (existing == null || e.fireAt.isBefore(existing.fireAt)) {
        desired[id] = e;
      }
    }

    final pending = await _scheduler.pendingIds();

    // Cancel orphans first (pending ids no longer in the desired set).
    // This is the "clear stale OS alarms before setting the new batch"
    // half of the contract.
    for (final id in pending) {
      if (!desired.containsKey(id)) {
        await _scheduler.cancel(id);
        _scheduledFireAt.remove(id);
      }
    }

    // Insert / replace. `scheduleAt` is contracted to replace existing
    // ids, so this single call covers both new and drift-corrected
    // entries.
    for (final entry in desired.entries) {
      final id = entry.key;
      final desiredFireAt = entry.value.fireAt;
      if (_scheduledFireAt[id] != desiredFireAt) {
        await _scheduler.scheduleAt(
          id: id,
          fireAt: desiredFireAt,
          title: _titleFor(entry.value.alarm),
          body: _bodyFor(entry.value.alarm, entry.value.fireAt),
          // Payload contract: `<shiftId-or-'NONE'>|<notificationId>`.
          // Parsed by `_parseWakeUpRoute` in main.dart and
          // `_ShiftSummary` in wake_up_screen.dart. Shift-less alarms
          // (oneTime today; custom-repeat / bundles later) emit the
          // `NONE` sentinel so WakeUpScreen renders a generic title
          // without hitting the ShiftRepository.
          payload:
              '${entry.value.shift?.id ?? noShiftPayloadSentinel}|$id',
        );
        _scheduledFireAt[id] = desiredFireAt;
      }
    }
  }

  /// Next future occurrence of [alarm.minutesOfDay] in local time:
  /// today if [alarm.minutesOfDay] is still after [now], else tomorrow.
  /// Uses calendar-math (`DateTime(y, m, d + 1, h, mm)`) for the +1-day
  /// case so a DST boundary day doesn't drift the local hour.
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
  /// alarm's `minutesOfDay`. Calendar math throughout — see the prior
  /// DST audit; on a spring-forward day, `DateTime(y, m, d, h, mm)`
  /// resolves to the local time on the target day rather than the
  /// off-by-one absolute instant `date.add(Duration(minutes: …))`
  /// would produce.
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
        // Surface the offset rather than the fireAt time — the user
        // configured "90 minutes before", so that's the contract worth
        // confirming in the notification shade.
        return '${_offsetLabel(a.relativeOffsetMinutes)} before your '
            '${_typeLabel(type)} shift';
      }
      return 'Before your ${_typeLabel(type)} shift · $hh:$mm';
    }
    return 'Rings at $hh:$mm';
  }

  /// Human-readable offset for notification body copy. Mirrors the
  /// create-sheet's `_formatOffset` without the leading minus sign so
  /// the resulting sentence reads naturally ("90m before your Day shift").
  static String _offsetLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  // Local label helper — see the rationale on the equivalent method
  // in `ShiftGenerator`: `lib/logic/` (and now `lib/alarms/`) must not
  // depend on `lib/ui/`'s formatting helpers.
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
