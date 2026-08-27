import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/models/ringtone_source.dart';
import 'alarm_payload.dart';
import 'alarm_scheduler.dart';
import 'alarm_sound.dart';
import 'ios_notification_budget.dart';

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
/// issues zero channel calls.
///
/// **The ledger is VALIDATED against the OS on every [pendingIds] read.**
/// Force-stop, reboot, and OEM "cleaner" kills all cancel the app's alarms
/// WITHOUT touching our persisted ledger — trusting it blind made the
/// reconciler believe everything was still armed and re-issue nothing, a
/// silent total outage until each occurrence's date rolled out of the window
/// (Pixel 9 XL field bug: a force-stop wiped the OS set; every alarm already
/// in the ledger stayed phantom while newly-created rules armed fine). The
/// same events that wipe the alarms also wipe the app's PendingIntents, and
/// THOSE can be probed (`FLAG_NO_CREATE`), so `getAliveAlarmIds` filters the
/// ledger down to what the OS really holds; pruned phantoms then read as
/// not-pending and the reconciler re-arms them. This is also what makes the
/// boot re-sync actually effective — alarms never survive a reboot, and
/// before this validation the boot reconcile trusted the stale ledger too.
class NativeAlarmScheduler implements AlarmScheduler {
  NativeAlarmScheduler({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  /// Wire name — MUST match `MainActivity.NATIVE_ALARMS_CHANNEL`.
  static const String channelName = 'rostrik/native_alarms';

  // Method names — MUST match MainActivity's handler.
  static const String _methodSetExact = 'setExactAlarm';
  static const String _methodCancel = 'cancelAlarm';
  static const String _methodGetAliveAlarmIds = 'getAliveAlarmIds';
  // iOS-only handler; Android writes the same ledger natively at fire time.
  static const String _methodRecordSpentAlarms = 'recordSpentAlarms';

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
  // iOS ONLY. `bundledResource` above is an ANDROID `res/raw` name
  // ("classic_alarm"); iOS resolves a notification sound by FILENAME
  // ("classic.wav") out of the app container's Library/Sounds. Sending both
  // keeps one call shape for both platforms — Android ignores this key, iOS
  // ignores `bundledResource`. Always populated from the bundled catalog, even
  // for a custom tone: iOS cannot play an arbitrary vault/content URI as a
  // notification sound, so the bundled tone is the honest fallback there.
  static const String _argIosSound = 'iosSound';
  // iOS ONLY. How many follow-up alerts keep the alarm ringing past the ~30s
  // notification sound cap, and how far apart. Android ignores both — it rings
  // until dismissed from its foreground audio service. See
  // `ios_notification_budget.dart` for the ceiling that limits these.
  static const String _argRepeatChain = 'repeatChain';
  static const String _argRepeatIntervalSeconds = 'repeatIntervalSeconds';

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
    int repeatChain = 0,
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
    try {
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
        _argIosSound: resolveAlarmSound(soundKey).iosSoundName,
        _argRepeatChain: repeatChain,
        _argRepeatIntervalSeconds: kAlarmRepeatInterval.inSeconds,
      });
    } on PlatformException catch (e) {
      // Native refused the schedule — 'EXACT_ALARM_DENIED' when the user
      // revoked "Alarms & reminders" on Android 12/12L. Two invariants:
      //   1. Do NOT record the id in the ledger. A phantom entry would make
      //      the reconciler believe the alarm is armed and never retry; a
      //      skipped write means the next reconcile sees the id absent from
      //      pendingIds() and re-issues it — self-healing once the permission
      //      is restored.
      //   2. Do NOT rethrow. One refused alarm must not abort the whole
      //      reconcile — which on cold start runs BEFORE runApp, where an
      //      escaping error would strand the app on the splash screen.
      // (MissingPluginException is deliberately NOT caught: an unregistered
      // channel is a wiring bug that should stay loud in development.)
      debugPrint(
        '[NativeAlarmScheduler] schedule refused for id=$id: '
        '${e.code} ${e.message}',
      );
      return;
    }

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

  /// iOS ONLY in practice: asks the native side to record every alarm the OS has
  /// already DELIVERED into the `pending_alarm_deletes` ledger, so
  /// [drainPendingAlarmDeletesIntoHive] can retire spent one-time alarms.
  ///
  /// **Must be awaited immediately before that drain.** Android needs nothing
  /// here — it writes the same ledger natively at fire time — but iOS runs no
  /// app code when a notification fires, so without this the ledger was always
  /// empty and a fired one-time alarm was never deleted. The reconciler then
  /// re-projected it to the next occurrence of its time-of-day, silently
  /// turning a one-time alarm into a daily one.
  ///
  /// Best-effort, like the drains it feeds: a missing handler (Android, tests)
  /// or a native error reads as "nothing was spent", and the next launch
  /// retries. Never throws — this sits on the pre-`runApp` boot path.
  Future<void> recordSpentAlarms() async {
    try {
      final recorded =
          await _channel.invokeMethod<int>(_methodRecordSpentAlarms);
      if (recorded != null && recorded > 0) {
        debugPrint('[NativeAlarmScheduler] recorded $recorded spent alarm(s)');
      }
    } on PlatformException catch (e) {
      debugPrint('[NativeAlarmScheduler] recordSpentAlarms failed: ${e.code}');
    } on MissingPluginException {
      // Android / tests — the ledger is written natively at fire time there.
    }
  }

  /// Registers [onRecorded], invoked when the native side reports that an alarm
  /// has fired and been written to the `pending_alarm_deletes` ledger
  /// (`onSpentAlarmRecorded`). Pass null to clear.
  ///
  /// iOS only in practice. Without this the ledger is only drained on the next
  /// resume — and since tapping a notification foregrounds the app, that resume
  /// has typically already happened by the time iOS delivers the response, so a
  /// spent one-time alarm would linger (and be re-projected to tomorrow) until
  /// some later app switch.
  void setSpentAlarmListener(void Function()? onRecorded) {
    if (onRecorded == null) {
      _channel.setMethodCallHandler(null);
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSpentAlarmRecorded') onRecorded();
      return null;
    });
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
    if (_ledger.isEmpty) return <int>{};
    try {
      final alive = await _channel.invokeMethod<List<Object?>>(
        _methodGetAliveAlarmIds,
        <String, dynamic>{'ids': _ledger.keys.toList()},
      );
      // A null reply means the handler didn't actually answer (e.g. a test
      // mock covering other methods) — only a real list is authoritative.
      if (alive == null) return _ledger.keys.toSet();
      final aliveSet = alive.whereType<int>().toSet();
      // Prune phantoms: ids the OS no longer holds (force-stop / reboot /
      // OEM cleaner wiped them). Dropping them here makes the reconciler
      // see them as not-pending and re-arm; keeping them was the outage.
      if (aliveSet.length != _ledger.length) {
        _ledger.removeWhere((id, _) => !aliveSet.contains(id));
        await _persist();
      }
      return aliveSet;
    } on PlatformException {
      return _ledger.keys.toSet(); // native error — degrade to ledger truth
    } on MissingPluginException {
      return _ledger.keys.toSet(); // no handler (iOS/tests) — ledger truth
    }
  }

  /// Reads the persisted ledger into [_ledger], retrying on every call until
  /// the `settings` box is actually readable. Mirrors `AlarmSyncService`'s
  /// hydrate.
  ///
  /// The latch is set ONLY once `Hive.isBoxOpen('settings')` confirms the box
  /// — at that point whatever the box holds (including nothing, on a fresh
  /// install) IS the hydrated truth. Latching before the check would make a
  /// single too-early call (scheduler constructed ahead of the box open)
  /// permanently blind this ledger to its on-disk state: `pendingIds()` would
  /// answer empty forever, the reconciler would re-schedule everything as
  /// new, and `cancelAll` — which can only cancel ids the ledger knows, since
  /// AlarmManager has no enumeration API — would silently orphan every live
  /// OS alarm. Both production init paths open the box first, so the retry
  /// is a guard rail against reordering, not a live bug being papered over.
  ///
  /// Disk entries merge via `putIfAbsent`: hydration may land AFTER live
  /// `scheduleAt`/`cancel` mutations (the retry is the point), and a fresher
  /// in-memory fireAt must never be clobbered by a stale persisted one.
  void _hydrate() {
    if (_hydrated) return;
    try {
      if (!Hive.isBoxOpen('settings')) return; // not ready — retry next call
      _hydrated = true;
      final raw = Hive.box('settings').get(_ledgerKey);
      if (raw is! Map) return; // fresh install / nothing persisted yet
      raw.forEach((dynamic k, dynamic v) {
        final id = (k is int) ? k : int.tryParse(k.toString());
        final ms = (v is int) ? v : int.tryParse(v.toString());
        if (id != null && ms != null) _ledger.putIfAbsent(id, () => ms);
      });
    } catch (_) {
      // Unreadable state is treated as "not hydrated yet" — the next call
      // retries. Cold start without persisted state simply re-issues fresh
      // schedules.
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
