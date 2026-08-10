import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/models/alarm_settings.dart';
import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../data/repositories/alarm_settings_repository.dart';
import '../data/repositories/app_alarm_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../logic/sleep_plan.dart';
import '../state/app_preferences.dart'
    show
        bedtimeReminderEnabledKey,
        windDownReminderEnabledKey,
        sleepGoalHoursKey,
        windDownMinutesKey,
        use24HourTimeKey,
        isSchedulePausedKey,
        kDefaultSleepGoalHours,
        kDefaultWindDownMinutes;
import '../util/clock.dart';
import 'activity_reminder_scheduler.dart';
import 'sleep_reminders.dart';

/// Keeps the OS's two Sleep nudges (wind-down + bedtime) in sync with the live
/// roster and the user's sleep preferences — the sleep analogue of
/// [ActivityReminderService], reusing the SAME isolated
/// `rostrik/activity_reminders` scheduler/receiver so a plain, dismissible
/// notification fires at the right time and NOTHING here can touch the
/// shift-alarm fire chain.
///
/// It recomputes [computeSleepPlan] whenever the roster (shift/alarm/lead-time)
/// or a sleep preference changes and reconciles the two fixed-id reminders to
/// match — schedule (replace-by-id) the ones due in the future, cancel the rest.
/// Only two stable ids are ever involved, so no persisted ledger is needed: a
/// non-desired id is simply cancelled every reconcile (idempotent), which also
/// clears any stale reminder armed in a previous session.
///
/// Guarded + best-effort throughout: the scheduler swallows platform refusals,
/// and a fresh reconcile re-arms on the next launch (AlarmManager reminders
/// don't survive a reboot), so a missed nudge self-heals.
class SleepReminderService {
  SleepReminderService({
    required ShiftRepository shifts,
    required AppAlarmRepository alarms,
    required AlarmSettingsRepository alarmSettings,
    required Box settingsBox,
    required ActivityReminderScheduler scheduler,
    Clock clock = const SystemClock(),
  })  : _shifts = shifts,
        _alarms = alarms,
        _alarmSettings = alarmSettings,
        _settings = settingsBox,
        _scheduler = scheduler,
        _clock = clock;

  final ShiftRepository _shifts;
  final AppAlarmRepository _alarms;
  final AlarmSettingsRepository _alarmSettings;
  final Box _settings;
  final ActivityReminderScheduler _scheduler;
  final Clock _clock;

  // Latest snapshots, kept current by the stream subscriptions below; the
  // reconcile reads them rather than re-querying the repos.
  List<Shift> _latestShifts = const <Shift>[];
  List<AppAlarm> _latestAlarms = const <AppAlarm>[];
  int _latestLeadMinutes = AlarmSettings.defaults.leadTime.inMinutes;

  /// In-memory record of what we last armed (id → fireAt millis) so an unchanged
  /// reconcile issues no platform call.
  final Map<int, int> _scheduled = <int, int>{};

  StreamSubscription<List<Shift>>? _shiftSub;
  StreamSubscription<List<AppAlarm>>? _alarmSub;
  StreamSubscription<AlarmSettings>? _settingsSub;
  VoidCallback? _prefsListener;
  Timer? _debounce;
  bool _started = false;

  /// Which settings-box keys should trigger a re-reconcile when they change.
  static const List<String> _watchedPrefKeys = <String>[
    bedtimeReminderEnabledKey,
    windDownReminderEnabledKey,
    sleepGoalHoursKey,
    windDownMinutesKey,
    use24HourTimeKey,
    isSchedulePausedKey,
  ];

  /// Subscribes to the roster + preference sources. Each emits its current value
  /// on listen, so the initial reconcile happens as soon as the first values
  /// land. Idempotent.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    final now = _clock.now();
    // A tight window: the planner only arms a concrete bedtime for a shift
    // within its 36h horizon, so a few days either side is ample.
    _shiftSub = _shifts
        .watchInRange(
          DateTime(now.year, now.month, now.day - 1),
          DateTime(now.year, now.month, now.day + 4),
        )
        .listen((s) {
      _latestShifts = s;
      _scheduleReconcile();
    }, onError: (Object e) => debugPrint('[SleepReminder] shift stream: $e'));

    _alarmSub = _alarms.watch().listen((a) {
      _latestAlarms = a;
      _scheduleReconcile();
    }, onError: (Object e) => debugPrint('[SleepReminder] alarm stream: $e'));

    _settingsSub = _alarmSettings.watch().listen((s) {
      _latestLeadMinutes = s.leadTime.inMinutes;
      _scheduleReconcile();
    }, onError: (Object e) => debugPrint('[SleepReminder] settings stream: $e'));

    final listener = _scheduleReconcile;
    _prefsListener = listener;
    _settings.listenable(keys: _watchedPrefKeys).addListener(listener);
  }

  Future<void> stop() async {
    await _shiftSub?.cancel();
    await _alarmSub?.cancel();
    await _settingsSub?.cancel();
    if (_prefsListener != null) {
      _settings.listenable(keys: _watchedPrefKeys).removeListener(_prefsListener!);
    }
    _debounce?.cancel();
    _started = false;
  }

  /// Coalesces the burst of emissions a roster generate / preference toggle
  /// produces into ONE reconcile.
  void _scheduleReconcile() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), reconcile);
  }

  /// Recomputes the plan and reconciles the two nudges. Public so a resume hook
  /// or a test can drive one pass directly. Never throws.
  Future<void> reconcile() async {
    try {
      final now = _clock.now();
      final plan = computeSleepPlan(
        shifts: _latestShifts,
        alarms: _latestAlarms,
        globalLeadMinutes: _latestLeadMinutes,
        sleepGoalHours:
            _settings.get(sleepGoalHoursKey, defaultValue: kDefaultSleepGoalHours)
                as int,
        windDownMinutes: _settings.get(windDownMinutesKey,
            defaultValue: kDefaultWindDownMinutes) as int,
        now: now,
        isSchedulePaused:
            _settings.get(isSchedulePausedKey, defaultValue: false) as bool,
      );

      final desired = desiredSleepReminders(
        plan: plan,
        now: now,
        bedtimeEnabled:
            _settings.get(bedtimeReminderEnabledKey, defaultValue: false) as bool,
        windDownEnabled: _settings.get(windDownReminderEnabledKey,
            defaultValue: false) as bool,
        use24Hour: _settings.get(use24HourTimeKey, defaultValue: false) as bool,
      );
      final byId = {for (final r in desired) r.id: r};

      for (final id in <int>[kSleepWindDownReminderId, kSleepBedtimeReminderId]) {
        final r = byId[id];
        if (r == null) {
          // Not wanted — cancel unconditionally (idempotent). This also clears a
          // stray reminder armed in a prior session that's no longer valid.
          await _scheduler.cancel(id);
          _scheduled.remove(id);
          continue;
        }
        final ms = r.at.millisecondsSinceEpoch;
        if (_scheduled[id] == ms) continue; // unchanged — skip
        await _scheduler.schedule(
          id: r.id,
          at: r.at,
          title: r.title,
          body: r.body,
        );
        _scheduled[id] = ms;
      }
    } catch (e) {
      debugPrint('[SleepReminderService] reconcile failed: $e');
    }
  }
}
