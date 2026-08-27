import 'dart:async';
import 'dart:io' show Platform;

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
import '../purchase/entitlement_store.dart';
import '../util/clock.dart';
import 'alarm_backend_info.dart';
import 'alarm_payload.dart';
import 'alarm_projection.dart';
import 'alarm_scheduler.dart';
import 'ios_notification_budget.dart';
import 'notification_id_map.dart';
import 'one_off_snooze_store.dart';

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

/// Default pause source: alarms are suppressed when Holiday Mode is on OR the
/// app is LOCKED (14-day trial lapsed without purchase — feature #4). Both mean
/// "schedule nothing", so they're OR-ed into the one gate the projection reads.
/// Best-effort + guarded exactly like [_hydrateScheduledFireAt] so the test
/// harness (which never opens the box) simply reads "not paused / not locked".
bool _readSchedulePausedFromSettings() {
  try {
    if (!Hive.isBoxOpen('settings')) return false;
    final box = Hive.box('settings');
    final paused =
        box.get(_isSchedulePausedSettingsKey, defaultValue: false) as bool;
    final locked =
        box.get(EntitlementStore.lockedKey, defaultValue: false) as bool;
    return paused || locked;
  } catch (_) {
    return false;
  }
}

/// The unpurchased scheduling-horizon cap (trial end), or null when uncapped.
/// Guarded like the pause read; caps how far ahead alarms may arm so none fires
/// past the trial even before a re-sync catches the lapse.
DateTime? _readHorizonCapFromSettings() {
  try {
    if (!Hive.isBoxOpen('settings')) return null;
    return EntitlementStore.horizonCap(Hive.box('settings'));
  } catch (_) {
    return null;
  }
}

/// Alarm cap for the running platform AND backend.
///
/// The iOS notification path shares a 64-notification ceiling across alarms,
/// their repeat chains and every reminder, so it schedules fewer alarms further
/// out than Android — see `ios_notification_budget.dart`. **AlarmKit has no such
/// ceiling** (measured ≥400 on device), so keeping the reduced cap there would
/// shorten the pre-armed horizon to pay for a constraint that does not exist.
int _platformMaxScheduled() {
  try {
    if (!Platform.isIOS) return 50;
    return AlarmBackendInfo.isAlarmKit ? 50 : kIosMaxScheduledAlarms;
  } catch (_) {
    return 50;
  }
}

/// Repeat chains exist only where a single alert cannot ring long enough.
/// AlarmKit rings until dismissed — verified past five minutes on device — so a
/// chain there would be pure waste, and worse, extra alerts nothing cancels.
int _platformChainedAlarmCount() {
  try {
    if (!Platform.isIOS) return 0;
    return AlarmBackendInfo.isAlarmKit ? 0 : kChainedAlarmCount;
  } catch (_) {
    return 0;
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
///     one OS alarm per matching shift in the rolling [horizon]. Two timing
///     modes (see `rotationAlarmFireAt`): lead-time fires at `shiftStart −
///     leadTime` (the alarm's `relativeOffsetMinutes` override, else the global
///     `AlarmSettings.leadTime`); exact-time (`isExactTime`) fires at the
///     alarm's absolute `exactTimeMinutes` on the shift's date, ignoring the
///     lead entirely. "Matching" means the shift's type equals the alarm's
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
    // Null resolves per platform. iOS keeps at most 64 pending notifications
    // across ALL surfaces, and repeat chains spend that same allowance, so its
    // alarm cap is lower — see `ios_notification_budget.dart` for the
    // arithmetic. Tests pass explicit values.
    int? maxScheduled,
    int? chainedAlarmCount,
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
        _maxScheduledOverride = maxScheduled,
        _chainedAlarmCountOverride = chainedAlarmCount,
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

  /// Budgets are resolved per read rather than captured at construction,
  /// because on iOS they depend on which backend is live and that can change
  /// while the app runs. Injected values still win, so tests stay explicit.
  final int? _maxScheduledOverride;
  final int? _chainedAlarmCountOverride;

  int get _maxScheduled => _maxScheduledOverride ?? _platformMaxScheduled();

  /// How many of the most imminent alarms get a repeat chain. Zero off iOS —
  /// Android rings until dismissed from its foreground audio service and needs
  /// no help — and zero under AlarmKit, which does the same.
  int get _chainedAlarmCount =>
      _chainedAlarmCountOverride ?? _platformChainedAlarmCount();

  /// The chain length last requested per id, so a change in chain MEMBERSHIP
  /// re-schedules even when the fire time has not moved. Without this the
  /// chain would never advance: when the front alarm fires and drops out, the
  /// next one's `fireAt` is unchanged and the OS still holds it, so the
  /// unchanged-state gate below would skip it and it would ring just once.
  ///
  /// In-memory only, deliberately. A cold start re-arms the chains it believes
  /// in rather than trusting a persisted claim about what iOS is holding.
  final Map<int, int> _lastChainLength = <int, int>{};
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
    // Trial horizon cap (feature #4): while unpurchased, never arm an alarm past
    // the trial end, so nothing can fire after the trial lapses even before the
    // next reconcile. Uncapped (null) once purchased. Clamped to [0, _horizon].
    var horizon = _horizon;
    final cap = _readHorizonCapFromSettings();
    if (cap != null) {
      final capDur = cap.difference(now);
      if (capDur < horizon) horizon = capDur.isNegative ? Duration.zero : capDur;
    }
    final until = now.add(horizon);

    final allAlarms = await _alarms.getAll();

    // Global alarm settings, read once per sync. Supplies the DEFAULT lead-time
    // offset for every followsRotation alarm without a per-alarm override, plus
    // the custom-ringtone path that rides the payload as forward-plumbing.
    final settings = await _alarmSettings.read();
    final globalLeadMinutes = settings.leadTime.inMinutes;

    // Materialise shifts ONCE for the whole sync — every followsRotation alarm
    // walks the same date window, so reading the box once is O(box).
    final shiftsInWindow = await _shifts.getInRange(now, until);

    // SINGLE SOURCE OF TRUTH. `projectAlarmRings` owns ALL occurrence
    // enumeration AND state-awareness — Holiday Mode (`_isPaused`), disabled
    // alarms, OFF shifts, the mute/ack/skip/pause/archive suppression set, and
    // snooze resurrection — and is the SAME projector the Dashboard early-skip
    // and the Alarms-tab "Next ring" labels use, so what we schedule can never
    // diverge from what the UI advertises. (Holiday Mode previously lived as an
    // inline `enabledAlarms = []` short-circuit here; it now rides
    // `isSchedulePaused`, which empties the projection.)
    final rings = projectAlarmRings(
      alarms: allAlarms,
      shifts: shiftsInWindow,
      globalLeadMinutes: globalLeadMinutes,
      now: now,
      horizon: horizon,
      isSchedulePaused: _isPaused(),
      // Shift-less ('NONE') alarms snoozed natively are pinned to their snooze
      // instant here, so the orphan-cancel pass keeps (not cancels) the re-armed
      // alarm within its window — the one-off counterpart to Shift.snoozedUntil.
      // The native snooze drain (main()/resume/bg) sets this map BEFORE any
      // reconcile reads it.
      oneOffSnoozes: readOneOffSnoozes(now: now),
    );

    // Trim to the alarm cap (dense-roster guard; rings are sorted earliest
    // first) and resolve each to its stable notification id. Two rings can only
    // collide on (alarmId, dateKey) when two same-type shifts share a date —
    // keep the earliest as belt-and-braces.
    final desired = <int, _Entry>{};
    for (final ring in rings.take(_maxScheduled)) {
      final dateKey = _dateKey(ring.fireAt);
      final id = await _idMap.idFor('${ring.alarm.id}@$dateKey');
      final existing = desired[id];
      if (existing == null || ring.fireAt.isBefore(existing.fireAt)) {
        desired[id] = _Entry(
          alarm: ring.alarm,
          fireAt: ring.fireAt,
          dateKey: dateKey,
          shift: ring.shift,
        );
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

    // Shifts are immutable history; ALARM TRIGGERS ARE EPHEMERAL. Once an
    // occurrence's fire DATE has passed it can never re-enter the desired set
    // (every branch above requires `fireAt.isAfter(now)`), so its id-map entry
    // is dead weight — release it. This keeps the notification_ids ledger
    // bounded by the rolling horizon instead of growing by one entry per
    // alarm-occurrence forever (a year of one daily alarm would otherwise
    // strand 365 rows). The Shift records themselves are NEVER touched here —
    // they stay in Hive for the historical calendar view.
    //
    // Strictly-before-today (not before-now) deliberately leaves today's
    // already-fired keys until tomorrow: the cross-midnight snooze edge keys
    // its rescheduled fire on today's date, and one day of slack is bounded.
    // Releasing can never collide with a pending OS notification — the
    // counter never rewinds, so a re-allocated key gets a fresh id, and a
    // past-dated id still pending is cancelled by the orphan pass above.
    final todayKey = _dateKey(now);
    await _idMap.releaseWhere((key) {
      final at = key.lastIndexOf('@');
      if (at < 0) return false; // unknown/legacy key shape — leave untouched
      final dateKey = key.substring(at + 1);
      if (!_isoDateKeyPattern.hasMatch(dateKey)) return false;
      // Zero-padded ISO dates order lexicographically.
      return dateKey.compareTo(todayKey) < 0;
    });

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
    // Which alarms carry a repeat chain: the most imminent few. An iOS
    // notification's sound stops after ~30s, so without follow-up alerts a
    // heavy sleeper is simply not woken. They are expensive against the 64
    // ceiling, so only the alarms about to ring get them; the set moves forward
    // as they fire (dismissing one triggers a resync, which re-chains the next).
    final chained = <int>{
      if (_chainedAlarmCount > 0)
        ...(desired.entries.toList()
              ..sort((a, b) => a.value.fireAt.compareTo(b.value.fireAt)))
            .take(_chainedAlarmCount)
            .map((e) => e.key),
    };

    for (final entry in desired.entries) {
      final id = entry.key;
      final desiredFireAt = entry.value.fireAt;
      final lastKnown = _scheduledFireAt[id];
      final osHasIt = pending.contains(id);
      final chainLength = chained.contains(id) ? kAlarmRepeatChainLength : 0;
      // Condition 4: chain membership changed. See [_lastChainLength] — without
      // this the chain never advances past the first alarm. Absent reads as 0,
      // NOT as "unknown": treating it as a change would re-schedule every
      // unchained alarm on the first reconcile after launch, which is exactly
      // the cold-start burst conditions 1-3 exist to avoid.
      final needsSchedule = lastKnown == null ||
          !osHasIt ||
          lastKnown != desiredFireAt ||
          (_lastChainLength[id] ?? 0) != chainLength;
      if (!needsSchedule) continue;
      await _scheduler.scheduleAt(
        id: id,
        repeatChain: chainLength,
        fireAt: desiredFireAt,
        title: _titleFor(entry.value.alarm),
        body: _bodyFor(entry.value.alarm),
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
          // Per-alarm custom ringtone — non-null routes THIS alarm to the silent
          // channel and is replayed natively by WakeUpScreen. (Migrated off the
          // global settings; each alarm now carries its own.)
          customRingtoneUri: entry.value.alarm.customRingtoneUri,
          // Vibration stays a GLOBAL toggle — carried so WakeUpScreen can drive
          // (or skip) the native haptic loop for a custom-ringtone alarm.
          vibrationEnabled: settings.vibrationEnabled,
        ),
      );
      _scheduledFireAt[id] = desiredFireAt;
      _lastChainLength[id] = chainLength;
    }

    // Drop chain bookkeeping for ids no longer desired, so a returning id is
    // treated as unchained rather than inheriting a stale claim.
    _lastChainLength.removeWhere((id, _) => !desired.containsKey(id));

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

  /// `2026-05-22` — the date-only ISO portion. Used as part of the
  /// composite id-map key so a per-day alarm gets a stable id within
  /// a day and a fresh id on the next day.
  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Shape guard for the `@<date>` suffix the past-trigger purge parses out
  /// of id-map keys — anything that isn't exactly a [_dateKey] is left alone.
  static final RegExp _isoDateKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  String _titleFor(AppAlarm a) => a.label.isEmpty ? 'Alarm' : a.label;

  /// The short shift CONTEXT line for the alarm notification — deliberately
  /// time-free. The native scheduler supplies the formatted ring time
  /// separately (12-hour, e.g. "03:00 AM") and composes the two
  /// ([AlarmReceiver.notificationDetail] on the native side), so embedding a
  /// clock value here would only duplicate it. Empty for a plain (non-rotation)
  /// alarm, whose time alone already says everything.
  String _bodyFor(AppAlarm a) {
    final type = a.linkedShiftType;
    if (a.repeatType == AppAlarmRepeatType.followsRotation && type != null) {
      // "Before" reads correctly for both timing modes: an exact time the user
      // picks is, in practice, ahead of the shift start, as is a lead-time ring.
      return 'Before your ${_typeLabel(type)} shift';
    }
    return '';
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
