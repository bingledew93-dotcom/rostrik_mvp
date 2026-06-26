import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/models/ringtone_source.dart';
import 'alarm_payload.dart';
import 'alarm_scheduler.dart';
import 'alarm_sound.dart';

/// Production [AlarmScheduler] backed by the native `AlarmManager` layer —
/// the replacement for `LocalNotificationsAlarmScheduler` (and thus for
/// `flutter_local_notifications` entirely) on the core alarm-trigger path.
///
/// It talks to [MainActivity]'s `rostrik/native_alarms` MethodChannel:
///   * [scheduleAt] → `setExactAlarm`, which arms an explicit
///     `AlarmManager.setAlarmClock` PendingIntent targeting `AlarmReceiver`.
///   * [cancel] → `cancelAlarm`, which removes that PendingIntent from the OS.
///
/// **Why a local ledger.** `AlarmManager` exposes NO API to enumerate pending
/// alarms (unlike FLN's `pendingNotificationRequests`). The reconciler
/// (`AlarmSyncService`) still asks the scheduler for [pendingIds] to find
/// orphans and to gate redundant re-schedules, so this class maintains its own
/// persisted `id → fireAt(millis)` ledger in the always-open `settings` box and
/// answers `pendingIds()` from it. Every [scheduleAt]/[cancel]/[cancelAll]
/// keeps the ledger and the OS in lock-step.
///
/// This preserves `AlarmSyncService`'s idempotent replace-by-id logic verbatim:
/// on a steady state the ledger matches the desired set and the reconciler
/// issues zero channel calls. The one semantic the native path cannot reproduce
/// is FLN's ability to detect an OEM-killed alarm via a live OS query — that
/// resilience now comes from `setAlarmClock`'s own Doze/OEM hardiness plus the
/// native boot re-sync (`BootReceiver` → `AlarmSyncWorker`), not from
/// `pendingIds()`.
class NativeAlarmScheduler implements AlarmScheduler {
  NativeAlarmScheduler({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  /// Wire name — MUST match `MainActivity.NATIVE_ALARMS_CHANNEL`.
  static const String channelName = 'rostrik/native_alarms';

  // Method names — MUST match MainActivity's handler.
  static const String _methodSetExact = 'setExactAlarm';
  static const String _methodCancel = 'cancelAlarm';

  // Argument keys — MUST match what MainActivity reads (and the keys
  // AlarmReceiver / AlarmAudioService expect on the fire Intent).
  static const String _argId = 'id';
  static const String _argTriggerAtMillis = 'triggerAtMillis';
  static const String _argAlarmId = 'alarm_id';
  static const String _argLabel = 'label';
  static const String _argSource = 'source';
  static const String _argUri = 'uri';
  static const String _argVibrate = 'vibrate';
  static const String _argBundledResource = 'bundledResource';
  // The owning AppAlarm UUID — the stable discriminator for shift-less
  // ("one-off") alarms, which all share the 'NONE' shiftId sentinel. The native
  // snooze ledger records it so Dart can persist a one-off alarm's snooze.
  static const String _argAppAlarmId = 'appAlarmId';
  // The user's configured snooze interval (minutes), carried so AlarmActivity's
  // Snooze re-arms at the right offset. Read at schedule time (matching the old
  // FLN behavior); a mid-flight settings change applies on the next reconcile.
  static const String _argSnoozeMinutes = 'snoozeMinutes';
  // Human-facing notification detail. `displayTime` is the ring time formatted
  // 12-hour ("03:00 AM"); `body` is the short shift context ("Before your Night
  // shift"). Both ride to AlarmReceiver, which uses them as the native alarm
  // notification's content title/text and forwards them to AlarmAudioService's
  // keep-alive notification. The 12-hour time lives here (not in `body`) so the
  // two never duplicate the clock value.
  static const String _argDisplayTime = 'displayTime';
  static const String _argBody = 'body';
  // Critical-shift wake mechanics. When true the native AlarmActivity REQUIRES a
  // sustained physical shake to dismiss (and hides the slide-to-dismiss handle),
  // so a half-asleep swipe can't silence a must-not-miss alarm; when false the
  // normal slide-to-dismiss applies. Sourced from the alarm's `isCritical` flag.
  static const String _argRequiresShake = 'requiresShake';

  /// Hive `settings` key for the user's snooze interval (minutes). Same key the
  /// SettingsScreen writes and the old snooze handler read; default 1.
  static const String _snoozeDurationKey = 'snooze_duration';

  /// Persisted ledger key in the (always-open) `settings` box. Distinct from
  /// `AlarmSyncService`'s own `alarm_sync.scheduled_fire_at` snapshot — the two
  /// mirror the same data but each layer owns its contract.
  static const String _ledgerKey = 'native_alarms.scheduled';

  final MethodChannel _channel;

  /// In-memory mirror of the persisted ledger: notification id → fireAt millis.
  final Map<int, int> _ledger = <int, int>{};
  bool _hydrated = false;

  /// Drop-in for `LocalNotificationsAlarmScheduler.init()` so the wiring in
  /// `main()` / the background entrypoint swaps with a one-line change. There's
  /// no plugin to initialise — `setAlarmClock` needs no timezone DB and no
  /// runtime permission — so this only primes the ledger from disk.
  static Future<NativeAlarmScheduler> init() async {
    final scheduler = NativeAlarmScheduler();
    scheduler._hydrate();
    return scheduler;
  }

  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime fireAt,
    required String title,
    required String body,
    required String soundKey,
    String? payload,
  }) async {
    _hydrate();

    // The 4-field payload already carries the shift id, the custom-ringtone URI
    // and the vibrate flag — decode it so we can forward the native sound extras
    // without widening the AlarmScheduler interface.
    final decoded = AlarmPayload.decode(payload);
    final vibrate = decoded?.vibrationEnabled ?? true;
    final customUri = decoded?.customRingtoneUri;

    // Resolve the native sound routing (mirrors AlarmAudioEngine's contract):
    //   * a custom tone → source vault/system + its URI, no bundled resource;
    //   * otherwise → the bundled `res/raw` resource for the chosen soundKey
    //     (engine ignores source/uri when a bundled resource is present).
    final int source;
    final String? uri;
    final String? bundledResource;
    if (customUri != null && customUri.isNotEmpty) {
      uri = customUri;
      // `content://` ⇒ a RingtoneManager system pick; anything else is a durable
      // vault file path. Matches how AlarmAudioEngine opens each.
      source = customUri.startsWith('content://')
          ? RingtoneSource.system.index
          : RingtoneSource.vault.index;
      bundledResource = null;
    } else {
      bundledResource = resolveAlarmSound(soundKey).androidResource;
      source = RingtoneSource.classic.index;
      uri = null;
    }

    final fireMillis = fireAt.millisecondsSinceEpoch;
    await _channel.invokeMethod<void>(_methodSetExact, <String, dynamic>{
      _argId: id,
      _argTriggerAtMillis: fireMillis,
      // The shift id the native dismiss/auto-timeout records in the ledger so
      // Dart acks the right shift in Hive. 'NONE' for shift-less alarms; the
      // native side skips that.
      _argAlarmId: decoded?.shiftId ?? '',
      // The owning AppAlarm UUID — recorded by the native snooze so Dart can
      // persist a one-off ('NONE') alarm's snooze keyed by this id.
      _argAppAlarmId: decoded?.appAlarmId ?? '',
      _argLabel: title,
      // Notification detail: the 12-hour ring time + the short shift context.
      // AlarmReceiver composes these into the native notification (and forwards
      // them to AlarmAudioService) — see [AlarmReceiver.notificationDetail].
      _argDisplayTime: _formatClock12h(fireAt),
      _argBody: body,
      _argSource: source,
      _argUri: uri,
      _argVibrate: vibrate,
      _argBundledResource: bundledResource,
      _argSnoozeMinutes: _readSnoozeMinutes(),
      // Critical-shift alarms require a shake to dismiss; normal alarms slide.
      _argRequiresShake: decoded?.isCritical ?? false,
    });

    _ledger[id] = fireMillis;
    await _persist();
  }

  /// Formats [t]'s wall-clock time as a 12-hour `hh:mm AM/PM` string
  /// ("03:00 AM", "10:05 PM"). Hand-rolled so the core alarm path stays free of
  /// an `intl` dependency; this is a fixed presentation, not a locale format.
  static String _formatClock12h(DateTime t) {
    final isPm = t.hour >= 12;
    var hour12 = t.hour % 12;
    if (hour12 == 0) hour12 = 12; // 0 → 12 (midnight / noon)
    final hh = hour12.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm ${isPm ? 'PM' : 'AM'}';
  }

  /// The user's configured snooze interval in minutes (default 1). Best-effort:
  /// a closed/missing `settings` box (e.g. tests) reads the default.
  int _readSnoozeMinutes() {
    try {
      if (!Hive.isBoxOpen('settings')) return 1;
      final raw = Hive.box('settings').get(_snoozeDurationKey, defaultValue: 1);
      return (raw is int) ? raw : (int.tryParse(raw.toString()) ?? 1);
    } catch (_) {
      return 1;
    }
  }

  @override
  Future<void> cancel(int id) async {
    _hydrate();
    await _channel.invokeMethod<void>(_methodCancel, <String, dynamic>{
      _argId: id,
    });
    _ledger.remove(id);
    await _persist();
  }

  @override
  Future<void> cancelAll() async {
    _hydrate();
    // No native bulk API — cancel each known id, then clear the ledger.
    for (final id in _ledger.keys.toList()) {
      await _channel.invokeMethod<void>(_methodCancel, <String, dynamic>{
        _argId: id,
      });
    }
    _ledger.clear();
    await _persist();
  }

  @override
  Future<Set<int>> pendingIds() async {
    _hydrate();
    return _ledger.keys.toSet();
  }

  /// Reads the persisted ledger into [_ledger] once. Best-effort + idempotent:
  /// a no-op when the `settings` box isn't open (e.g. the test harness, which
  /// injects a fake channel anyway). Mirrors `AlarmSyncService`'s hydrate.
  void _hydrate() {
    if (_hydrated) return;
    _hydrated = true;
    try {
      if (!Hive.isBoxOpen('settings')) return;
      final raw = Hive.box('settings').get(_ledgerKey);
      if (raw is! Map) return;
      raw.forEach((dynamic k, dynamic v) {
        final id = (k is int) ? k : int.tryParse(k.toString());
        final ms = (v is int) ? v : int.tryParse(v.toString());
        if (id != null && ms != null) _ledger[id] = ms;
      });
    } catch (_) {
      // Cold start without persisted state simply re-issues fresh schedules.
    }
  }

  /// Writes the current [_ledger] back to the `settings` box as a `Map<int,int>`
  /// (one key, one put) so the next cold start can decode it adapter-free.
  Future<void> _persist() async {
    try {
      if (!Hive.isBoxOpen('settings')) return;
      await Hive.box('settings')
          .put(_ledgerKey, Map<int, int>.from(_ledger));
    } catch (e) {
      debugPrint('[NativeAlarmScheduler] ledger persist failed: $e');
    }
  }
}
