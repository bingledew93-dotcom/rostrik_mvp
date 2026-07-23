import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/models/calendar_activity.dart';
import '../data/repositories/calendar_activity_repository.dart';
import '../util/clock.dart';
import 'activity_reminder_scheduler.dart';
import 'reminder_id.dart';

/// Keeps the OS's set of **activity reminders** in sync with the activity box —
/// the reminder analogue of `AlarmSyncService`, but deliberately tiny and fully
/// isolated from the shift-alarm engine.
///
/// It watches [CalendarActivityRepository.watch] and, on every change, computes
/// the desired reminder set (each activity whose `reminderAt` is in the future)
/// and drives [ActivityReminderScheduler] to match — replace-by-id for changed
/// times, cancel for cleared/deleted/past reminders. Idempotent: a steady state
/// issues zero platform calls.
///
/// **Why a persisted ledger.** The desired set is derived from Hive, but the
/// service must also cancel reminders that no longer belong — including a
/// reminder that was cleared while the app was closed (the activity survives
/// with `reminderAt == null`, so the next launch must know it was previously
/// armed to cancel it). A small `id → fireAt(millis)` ledger in the always-open
/// `settings` box, hydrated on start, provides that memory. On a fresh launch
/// with an empty ledger every future reminder is simply re-scheduled (harmless,
/// replace-by-id), which doubles as the reboot-recovery path — `AlarmManager`
/// alarms don't survive a reboot, and re-arming here on next app open restores
/// them.
class ActivityReminderService {
  ActivityReminderService({
    required CalendarActivityRepository activities,
    required ActivityReminderScheduler scheduler,
    Clock clock = const SystemClock(),
  })  : _activities = activities,
        _scheduler = scheduler,
        _clock = clock;

  final CalendarActivityRepository _activities;
  final ActivityReminderScheduler _scheduler;
  final Clock _clock;

  /// Persisted-ledger key in the always-open `settings` box.
  static const String _ledgerKey = 'activity_reminders.scheduled';

  /// In-memory mirror of the persisted ledger: reminder id → fireAt millis.
  final Map<int, int> _ledger = <int, int>{};
  bool _hydrated = false;

  StreamSubscription<List<CalendarActivity>>? _sub;

  /// Hydrates the ledger and subscribes to the activity stream. The stream
  /// emits its current snapshot immediately, so the initial reconcile happens
  /// as soon as the first event lands.
  Future<void> start() async {
    _hydrate();
    _sub ??= _activities.watch().listen(
      _reconcile,
      onError: (Object e) =>
          debugPrint('[ActivityReminderService] stream error: $e'),
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Recomputes the desired reminder set from [snapshot] and reconciles the OS
  /// against it. Public so a test (or a resume hook) can drive one pass
  /// directly.
  Future<void> reconcile(List<CalendarActivity> snapshot) =>
      _reconcile(snapshot);

  Future<void> _reconcile(List<CalendarActivity> snapshot) async {
    _hydrate();
    final now = _clock.now();

    // Desired: every activity with a reminder strictly in the future.
    final desired = <int, int>{};
    final byId = <int, CalendarActivity>{};
    for (final a in snapshot) {
      final at = a.reminderAt;
      if (at == null || !at.isAfter(now)) continue;
      final id = reminderNotificationId(a.id);
      desired[id] = at.millisecondsSinceEpoch;
      byId[id] = a;
    }

    var changed = false;

    // Cancel anything we previously armed that is no longer desired (cleared,
    // deleted, or now in the past).
    for (final id in _ledger.keys.toList()) {
      if (desired.containsKey(id)) continue;
      await _scheduler.cancel(id);
      _ledger.remove(id);
      changed = true;
    }

    // Schedule new or time-changed reminders (replace-by-id native-side).
    for (final entry in desired.entries) {
      if (_ledger[entry.key] == entry.value) continue; // unchanged — skip
      final a = byId[entry.key]!;
      await _scheduler.schedule(
        id: entry.key,
        at: a.reminderAt!,
        title: _title(a),
        body: _body(a),
      );
      _ledger[entry.key] = entry.value;
      changed = true;
    }

    if (changed) await _persist();
  }

  /// Notification title — the activity's own title, or a sensible default if a
  /// (malformed) empty title ever slips through.
  static String _title(CalendarActivity a) =>
      a.title.trim().isEmpty ? 'Reminder' : a.title.trim();

  /// Notification body — a short `Kind at time` / `Kind` context line.
  static String _body(CalendarActivity a) {
    final kind = switch (a.kind) {
      ActivityKind.event => 'Event',
      ActivityKind.task => 'Task',
      ActivityKind.birthday => 'Birthday',
    };
    final minutes = a.timeMinutes;
    if (minutes == null) return kind;
    return '$kind at ${_formatClock12h(minutes)}';
  }

  /// Formats a minute-of-day as a 12-hour `h:mm AM/PM` string. Self-contained
  /// (no `intl`) — this background path never touches the UI's clock-format
  /// preference.
  static String _formatClock12h(int minuteOfDay) {
    final hour = minuteOfDay ~/ 60;
    final minute = minuteOfDay % 60;
    final isPm = hour >= 12;
    var hour12 = hour % 12;
    if (hour12 == 0) hour12 = 12;
    final mm = minute.toString().padLeft(2, '0');
    return '$hour12:$mm ${isPm ? 'PM' : 'AM'}';
  }

  // ---- Persistence (mirrors NativeAlarmScheduler's ledger idiom) -----------

  void _hydrate() {
    if (_hydrated) return;
    try {
      if (!Hive.isBoxOpen('settings')) return; // not ready — retry next call
      _hydrated = true;
      final raw = Hive.box('settings').get(_ledgerKey);
      if (raw is! Map) return;
      raw.forEach((dynamic k, dynamic v) {
        final id = (k is int) ? k : int.tryParse(k.toString());
        final ms = (v is int) ? v : int.tryParse(v.toString());
        if (id != null && ms != null) _ledger.putIfAbsent(id, () => ms);
      });
    } catch (_) {
      // Unreadable state → treat as not hydrated; the next call retries.
    }
  }

  Future<void> _persist() async {
    try {
      if (!Hive.isBoxOpen('settings')) return;
      await Hive.box('settings').put(_ledgerKey, Map<int, int>.from(_ledger));
    } catch (e) {
      debugPrint('[ActivityReminderService] ledger persist failed: $e');
    }
  }
}
