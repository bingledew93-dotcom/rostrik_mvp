import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/models/shift.dart';
import '../data/models/shift_cycle.dart';
import '../data/repositories/shift_cycle_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../state/app_preferences.dart' show calendarSyncEnabledKey;
import '../util/clock.dart';
import 'roster_calendar_events.dart';

/// Outcome of a user turning Calendar Sync ON, so the UI can respond precisely.
enum CalendarSyncEnableResult {
  /// Permission granted, flag persisted, first sync kicked off.
  enabled,

  /// The user declined (or dismissed) the prompt — can be asked again.
  denied,

  /// Permanently blocked (Android "don't ask again" / iOS restricted). The UI
  /// should point the user at the system settings via [openSystemSettings].
  permanentlyDenied,

  /// The platform doesn't support calendar sync (desktop / web / test VM).
  unsupported,
}

/// Optional Device Calendar Sync (`feature-calendar-sync`).
///
/// Mirrors the roster into a dedicated **"Rostrik Roster"** calendar on the
/// device (never the user's personal calendars) via `device_calendar_plus`, on a
/// 6-month rolling window. Off by default; a Settings toggle turns it on, which
/// is the ONLY thing that ever prompts for calendar permission. While enabled it
/// re-syncs automatically (debounced) on any roster change — save / edit /
/// generate / import / leave / delete — by watching the shift + cycle streams.
///
/// A [ChangeNotifier] so the toggle row reflects [enabled]/[busy] live. Every
/// platform call is guarded to a no-op off Android/iOS and swallows its own
/// errors — a calendar hiccup must never disturb the app or the alarm engine.
///
/// The heavy platform I/O (find-or-create calendar, clear + rebuild events) lives
/// here; the pure "which shifts, what titles" decision is in
/// [buildRosterCalendarEvents] so it stays testable without a device.
class DeviceCalendarService extends ChangeNotifier {
  DeviceCalendarService({
    required ShiftRepository shifts,
    required ShiftCycleRepository cycles,
    required Box settingsBox,
    Clock clock = const SystemClock(),
    DeviceCalendar? calendar,
  })  : _shifts = shifts,
        _cycles = cycles,
        _settings = settingsBox,
        _clock = clock,
        _calendar = calendar ?? DeviceCalendar.instance;

  final ShiftRepository _shifts;
  final ShiftCycleRepository _cycles;
  final Box _settings;
  final Clock _clock;
  final DeviceCalendar _calendar;

  StreamSubscription<List<Shift>>? _shiftSub;
  StreamSubscription<List<ShiftCycle>>? _cycleSub;
  Timer? _debounce;
  bool _started = false;
  bool _busy = false;

  /// Cached id of the "Rostrik Roster" calendar for the session. Re-resolved by
  /// name whenever it's null (e.g. the user deleted the calendar).
  String? _calendarId;

  /// Clear a slightly-wider window than we create so a boundary shift or a
  /// straggler from an earlier, longer horizon can't linger as a duplicate. Only
  /// events starting at/after `now` are ever returned, so past history is safe.
  static const int _clearHorizonDays = 370;

  /// `device_calendar_plus` implements only Android + iOS; elsewhere a call
  /// throws `MissingPluginException`. `Platform` itself throws on web, hence the
  /// guard-inside-try (mirrors `WidgetService._supported`).
  bool get _supported {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Whether the user has Calendar Sync turned on (persisted in the settings
  /// box, so it survives restarts).
  bool get enabled =>
      _settings.get(calendarSyncEnabledKey, defaultValue: false) as bool;

  /// True while an enable/disable/sync round-trip is in flight — the toggle row
  /// shows a spinner and disables interaction so taps can't overlap.
  bool get busy => _busy;

  /// Subscribes to the roster streams and, if sync is already enabled, kicks off
  /// an initial sync (the streams emit their current value on listen, so the
  /// first emission schedules it). Never prompts for permission. Idempotent.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (!_supported) return;

    // Each emission (including the initial one on listen) schedules a debounced
    // sync; `syncRosterToDeviceCalendar` no-ops unless enabled + permitted.
    _shiftSub = _shifts
        .watchInRange(
          _clock.now().subtract(const Duration(days: 1)),
          _clock.now().add(const Duration(days: kCalendarSyncHorizonDays + 5)),
        )
        .listen((_) => _scheduleSync());
    _cycleSub = _cycles.watch().listen((_) => _scheduleSync());
  }

  /// Coalesces the burst a single roster generate produces (many shift upserts +
  /// a cycle write) into ONE sync. Longer than the widget's debounce — a sync is
  /// a heavier clear-and-rebuild of up to ~180 events.
  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 1500),
      syncRosterToDeviceCalendar,
    );
  }

  /// Turns Calendar Sync ON: requests full calendar access (the only prompt in
  /// the whole feature), and on grant persists the flag and runs the first sync.
  /// Returns a [CalendarSyncEnableResult] the UI switches on. Never throws.
  Future<CalendarSyncEnableResult> enableSync() async {
    if (!_supported) return CalendarSyncEnableResult.unsupported;
    _setBusy(true);
    try {
      final status =
          await _calendar.requestPermissions(level: CalendarAccessLevel.full);
      switch (status) {
        case CalendarPermissionStatus.granted:
          await _setEnabled(true);
          await _sync(); // immediate first mirror
          return CalendarSyncEnableResult.enabled;
        case CalendarPermissionStatus.denied:
        case CalendarPermissionStatus.restricted:
          return CalendarSyncEnableResult.permanentlyDenied;
        case CalendarPermissionStatus.writeOnly:
        case CalendarPermissionStatus.notDetermined:
          // We need full access (create/list/delete); a write-only grant or a
          // dismissed prompt is not enough. Leave it off; the user can retry.
          return CalendarSyncEnableResult.denied;
      }
    } catch (e) {
      debugPrint('[DeviceCalendarService] enable failed: $e');
      return CalendarSyncEnableResult.denied;
    } finally {
      _setBusy(false);
    }
  }

  /// Turns Calendar Sync OFF: stops reacting to roster changes and clears the
  /// dedicated calendar's FUTURE events (best-effort; past events stay as
  /// history). Never deletes the calendar itself, so re-enabling is instant.
  Future<void> disableSync() async {
    _setBusy(true);
    try {
      await _setEnabled(false);
      if (!_supported) return;
      // Only clear if we still hold permission; never prompt on the way out.
      final status = await _calendar.hasPermissions();
      if (status != CalendarPermissionStatus.granted) return;
      final id = await _findCalendarId();
      if (id != null) await _clearFutureEvents(id);
    } catch (e) {
      debugPrint('[DeviceCalendarService] disable failed: $e');
    } finally {
      _setBusy(false);
    }
  }

  /// Opens the OS app-settings page so a user who permanently denied access can
  /// grant it. Best-effort.
  Future<void> openSystemSettings() async {
    if (!_supported) return;
    try {
      await _calendar.openAppSettings();
    } catch (e) {
      debugPrint('[DeviceCalendarService] openAppSettings failed: $e');
    }
  }

  /// Public sync entry point used by the stream-driven auto-sync. No-ops unless
  /// supported + enabled + permission already held (it never prompts). Never
  /// throws. Guards against overlapping runs.
  Future<void> syncRosterToDeviceCalendar() async {
    if (!_supported || !enabled || _busy) return;
    _setBusy(true);
    try {
      await _sync();
    } catch (e) {
      debugPrint('[DeviceCalendarService] sync failed: $e');
    } finally {
      _setBusy(false);
    }
  }

  /// The actual mirror: ensure the calendar exists, clear its future events, then
  /// recreate an event per working shift in the 180-day window. Assumes it's
  /// only called when supported + enabled; verifies permission without prompting.
  Future<void> _sync() async {
    final status = await _calendar.hasPermissions();
    if (status != CalendarPermissionStatus.granted) return;

    final id = await _ensureCalendarId();
    if (id == null) return;

    await _clearFutureEvents(id);

    final now = _clock.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = DateTime(now.year, now.month, now.day + kCalendarSyncHorizonDays);
    final shifts = await _shifts.getInRange(from, to);
    final events = buildRosterCalendarEvents(
      shifts,
      now: now,
      horizonDays: kCalendarSyncHorizonDays,
    );

    for (final event in events) {
      await _calendar.createEvent(
        calendarId: id,
        title: event.title,
        startDate: event.start,
        endDate: event.end,
        // Rostrik owns wake-ups; don't add a duplicate calendar reminder, and
        // mark shifts as busy time.
        availability: EventAvailability.busy,
      );
    }
    debugPrint('[DeviceCalendarService] synced ${events.length} shift event(s)');
  }

  /// Resolves the dedicated calendar's id, creating it if absent. Cached for the
  /// session; re-resolved when the cache is null.
  Future<String?> _ensureCalendarId() async {
    final cached = _calendarId;
    if (cached != null) return cached;

    final existing = await _findCalendarId();
    if (existing != null) {
      _calendarId = existing;
      return existing;
    }

    final created = await _calendar.createCalendar(
      name: kRostrikCalendarName,
      colorHex: kRostrikCalendarColorHex,
      platformOptions: Platform.isAndroid
          ? const CreateCalendarOptionsAndroid(
              accountName: kRostrikCalendarAccountName,
            )
          : null,
    );
    _calendarId = created;
    return created;
  }

  /// Finds the "Rostrik Roster" calendar by name (writable), or null. Does NOT
  /// create one. Used both to resolve for a sync and to clear on disable.
  Future<String?> _findCalendarId() async {
    final calendars = await _calendar.listCalendars();
    for (final calendar in calendars) {
      if (calendar.name == kRostrikCalendarName && !calendar.readOnly) {
        return calendar.id;
      }
    }
    return null;
  }

  /// Deletes every event in [calendarId] starting at/after `now` (up to the
  /// clear horizon) so a fresh sync can't produce duplicates. Past events are
  /// left untouched — the calendar doubles as a work-history record.
  Future<void> _clearFutureEvents(String calendarId) async {
    final now = _clock.now();
    final events = await _calendar.listEvents(
      now,
      now.add(const Duration(days: _clearHorizonDays)),
      calendarIds: [calendarId],
    );
    for (final event in events) {
      await _calendar.deleteEvent(eventId: event.eventId);
    }
  }

  Future<void> _setEnabled(bool value) async {
    await _settings.put(calendarSyncEnabledKey, value);
    await _settings.flush().catchError((Object _) {});
    notifyListeners();
  }

  void _setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _shiftSub?.cancel();
    _cycleSub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
