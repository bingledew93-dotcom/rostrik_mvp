import 'dart:async';

import '../data/models/alarm_settings.dart';
import '../data/models/shift.dart';
import '../data/models/shift_type.dart';
import '../data/repositories/alarm_settings_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../util/clock.dart';
import 'alarm_scheduler.dart';
import 'notification_id_map.dart';

/// Orchestrates alarm scheduling. The shift repository is policy-free
/// (returns all shifts including OFF); this engine is where every alarm-related
/// policy lives:
///   - Skip [ShiftType.off] entries.
///   - Skip muted entries (`Shift.isMuted == true`). The shift stays in the
///     roster; the alarm is suppressed. Unmuting is symmetric — the shift
///     reappears in the desired set on the next reconcile and is rescheduled.
///   - Skip acknowledged entries (`Shift.isAcknowledged == true`). The user
///     has already handled this occurrence's alarm via the Dismiss action;
///     do not re-schedule it across cold starts or settings changes.
///   - If `snoozedUntil` is set and still in the future, pin the desired
///     `fireAt` to that instant instead of the default `start - leadTime`.
///     This lets a background-isolate snooze (which writes the field and
///     schedules a one-shot notification) survive a cold start: the engine
///     reconciles to the same time the background isolate already scheduled,
///     and `scheduleAt` is contracted to replace the existing id idempotently.
///   - Skip shifts whose computed `fireAt` is already in the past.
///   - Cap to [maxScheduled] entries within a [horizon] window
///     (iOS allows 64 pending notifications; we leave headroom).
class AlarmEngine {
  AlarmEngine({
    required ShiftRepository shifts,
    required AlarmSettingsRepository alarmSettings,
    required AlarmScheduler scheduler,
    required NotificationIdMap idMap,
    required Clock clock,
    Duration horizon = const Duration(days: 60),
    int maxScheduled = 50,
    Duration debounceWindow = const Duration(milliseconds: 250),
  })  : _shifts = shifts,
        _alarmSettings = alarmSettings,
        _scheduler = scheduler,
        _idMap = idMap,
        _clock = clock,
        _horizon = horizon,
        _maxScheduled = maxScheduled,
        _debounceWindow = debounceWindow;

  final ShiftRepository _shifts;
  final AlarmSettingsRepository _alarmSettings;
  final AlarmScheduler _scheduler;
  final NotificationIdMap _idMap;
  final Clock _clock;
  final Duration _horizon;
  final int _maxScheduled;
  final Duration _debounceWindow;

  StreamSubscription<List<Shift>>? _shiftSub;
  StreamSubscription<AlarmSettings>? _settingsSub;

  /// Coalesces bursts of stream emissions into a single reconcile. A bulk
  /// roster import (e.g. 6 months of shifts) emits one Hive `BoxEvent` per
  /// row; without this, each one would walk the full reconcile pipeline and
  /// hit the OS notification bridge n times — O(n) native method-channel
  /// calls cause severe UI jank on budget Android devices. Direct callers of
  /// `reconcile()` (initial start, app-resume, tests) bypass the debounce.
  Timer? _debounceTimer;

  /// Records the `fireAt` we last asked the scheduler to use for each id.
  /// This is what lets reconcile detect drift (e.g. the user changed their
  /// global lead time) and re-schedule, while staying idempotent when nothing
  /// has changed. In-memory only — on cold start it's empty, so the first
  /// reconcile re-issues `scheduleAt` for every still-desired id, which is
  /// safe because schedulers are contracted to replace existing entries.
  final Map<int, DateTime> _scheduledFireAt = {};

  /// Single-slot queue: the next reconcile chains onto the tail of the
  /// previous one. Without this, a burst of stream emissions (e.g. a bulk
  /// shift import) would fire several reconciles concurrently, racing on
  /// the shared `_scheduledFireAt` map and on `NotificationIdMap.idFor`'s
  /// non-atomic read-modify-write — producing unstable id assignments and
  /// orphaned OS-level alarms. This was caught by the SimulationInjector
  /// harness; see test/alarms/alarm_engine_concurrency_test.dart.
  Future<void> _inFlight = Future<void>.value();

  /// Diff-and-converge:
  ///   - Cancel any pending alarm whose shift is no longer desired.
  ///   - (Re)schedule any desired alarm whose `fireAt` differs from the last
  ///     `fireAt` we asked the scheduler for. This covers both first-time
  ///     scheduling and lead-time / shift-time changes.
  /// Idempotent — running it twice with no input change produces zero
  /// scheduler mutations. Serialized — concurrent callers queue behind the
  /// in-flight reconcile rather than racing.
  Future<void> reconcile() {
    final next = _inFlight.then((_) => _doReconcile());
    // .catchError on the chain (not the returned future) ensures one failed
    // reconcile doesn't poison the queue and block all future reconciles.
    // Callers awaiting `reconcile()` still observe the original error.
    _inFlight = next.catchError((_) {});
    return next;
  }

  Future<void> _doReconcile() async {
    final now = _clock.now();
    final until = now.add(_horizon);

    final settings = await _alarmSettings.read();
    final allShifts = await _shifts.getInRange(now, until);

    final entries = <_Entry>[];
    for (final s in allShifts) {
      if (s.type == ShiftType.off) continue;
      if (s.isMuted) continue;
      if (s.isAcknowledged) continue;
      // A live snooze overrides the default lead-time computation. Once
      // snoozedUntil is in the past (e.g. the snoozed alarm has fired and
      // been handled), fall back to the standard fireAt so re-acknowledge /
      // un-acknowledge flows behave correctly.
      final defaultFireAt = s.startDateTime.subtract(settings.leadTime);
      final snoozed = s.snoozedUntil;
      final fireAt = (snoozed != null && snoozed.isAfter(now))
          ? snoozed
          : defaultFireAt;
      if (!fireAt.isAfter(now)) continue;
      entries.add(_Entry(shift: s, fireAt: fireAt));
    }
    entries.sort((a, b) => a.fireAt.compareTo(b.fireAt));

    final capped = entries.take(_maxScheduled).toList();

    final desired = <int, _Entry>{};
    for (final e in capped) {
      final id = await _idMap.idFor(e.shift.id);
      desired[id] = e;
    }

    final pending = await _scheduler.pendingIds();

    // Cancel orphans: pending OS alarms whose shift is no longer desired.
    for (final id in pending) {
      if (!desired.containsKey(id)) {
        await _scheduler.cancel(id);
        _scheduledFireAt.remove(id);
      }
    }

    // Insert OR replace: schedule whenever fireAt differs from what we last
    // told the scheduler. `scheduleAt` is contracted to replace existing ids,
    // so this single call covers both new and lead-time-changed alarms.
    for (final entry in desired.entries) {
      final id = entry.key;
      final desiredFireAt = entry.value.fireAt;
      if (_scheduledFireAt[id] != desiredFireAt) {
        await _scheduler.scheduleAt(
          id: id,
          fireAt: desiredFireAt,
          title: _titleFor(entry.value.shift),
          body: _bodyFor(entry.value.shift),
          // "shiftId|notificationId" — gives the wake-up screen everything
          // it needs to look up the shift AND cancel the OS notification
          // on dismiss without exposing NotificationIdMap to the UI.
          payload: '${entry.value.shift.id}|$id',
        );
        _scheduledFireAt[id] = desiredFireAt;
      }
    }
  }

  /// Performs an initial reconcile, then re-reconciles on every roster or
  /// settings change. Stream-driven reconciles are debounced; the initial
  /// reconcile is awaited directly so `start()` only returns once the engine
  /// has converged with current state.
  Future<void> start() async {
    await reconcile();
    final now = _clock.now();
    _shiftSub = _shifts
        .watchInRange(now, now.add(_horizon))
        .skip(1) // initial snapshot was already covered by reconcile() above
        .listen((_) => _scheduleDebouncedReconcile());
    _settingsSub = _alarmSettings
        .watch()
        .skip(1)
        .listen((_) => _scheduleDebouncedReconcile());
  }

  Future<void> stop() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _shiftSub?.cancel();
    await _settingsSub?.cancel();
    _shiftSub = null;
    _settingsSub = null;
  }

  /// Resets the debounce timer on every call. After [_debounceWindow] of
  /// quiet, fires exactly one `reconcile()` — and because reconciles are
  /// queued via `_inFlight`, it's safe to fire-and-forget here.
  void _scheduleDebouncedReconcile() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceWindow, () {
      _debounceTimer = null;
      reconcile();
    });
  }

  String _titleFor(Shift s) {
    switch (s.type) {
      case ShiftType.day:
        return 'Day shift coming up';
      case ShiftType.night:
        return 'Night shift coming up';
      case ShiftType.afternoon:
        return 'Afternoon shift coming up';
      case ShiftType.off:
        return ''; // unreachable: filtered in reconcile()
    }
  }

  String _bodyFor(Shift s) {
    final hh = (s.startMinutes ~/ 60).toString().padLeft(2, '0');
    final mm = (s.startMinutes % 60).toString().padLeft(2, '0');
    return 'Starts at $hh:$mm';
  }
}

class _Entry {
  _Entry({required this.shift, required this.fireAt});
  final Shift shift;
  final DateTime fireAt;
}
