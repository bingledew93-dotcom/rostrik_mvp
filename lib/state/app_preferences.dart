import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

/// Hive key for the 12/24-hour clock preference. Default false = 12-hour.
const String use24HourTimeKey = 'use24HourTime';

/// Hive key for the calendar week-start preference. Default true = Monday.
const String startWeekOnMondayKey = 'startWeekOnMonday';

/// Hive key for which Timeline view opens first. Default false = List view.
const String timelineDefaultMonthKey = 'timelineDefaultMonth';

/// Hive key for the preferred time-picker entry mode. Default false = the
/// tap-to-type keyboard (number pad); true = the analog dial. Whichever mode
/// the user last switched to inside a picker is remembered here so every time
/// picker opens the way they left it. Pure UI preference — never affects the
/// time that's picked or any alarm logic.
const String timePickerUseDialKey = 'timePickerUseDial';

/// Hive key for the Alarms-tab sort order. Default false = by ring time (the
/// clock time each alarm fires, earliest first); true = grouped by shift type
/// (Day → Afternoon → Night, then non-rotation), earliest ring within a group.
/// Display-only ordering; the alarm engine is entirely unaffected.
const String alarmSortByShiftTypeKey = 'alarmSortByShiftType';

/// Hive key for the nightly sleep target, in whole hours. Default 8.
const String sleepGoalHoursKey = 'sleepGoalHours';

/// Hive key for the wind-down lead, in minutes. Default 30.
const String windDownMinutesKey = 'windDownMinutes';

/// Hive key for the (UI-only, not-yet-wired) bedtime reminder toggle.
const String bedtimeReminderEnabledKey = 'bedtimeReminderEnabled';

/// Hive key for the wind-down reminder toggle (wired via `SleepReminderService`).
const String windDownReminderEnabledKey = 'windDownReminderEnabled';

/// Hive key for the sleep-sound auto-stop timer, in minutes (0 = play until
/// stopped). Persisted so the user's chosen wind-down timer sticks between
/// sessions. Watched so the Sleep tab's chips reflect it live.
const String sleepSoundTimerMinutesKey = 'sleepSoundTimerMinutes';

/// Default nightly sleep target (hours) when the user hasn't changed it.
const int kDefaultSleepGoalHours = 8;

/// Default wind-down lead (minutes) when the user hasn't changed it.
const int kDefaultWindDownMinutes = 30;

/// Default sleep-sound auto-stop timer (minutes) when the user hasn't changed it.
const int kDefaultSleepSoundTimerMinutes = 30;

/// Hive key for the optional Device Calendar Sync toggle. When true, the roster
/// is mirrored to a dedicated "Rostrik Roster" calendar on the device (feature
/// `feature-calendar-sync`). Owned/persisted by `DeviceCalendarService` (which
/// exposes the reactive state), so it is deliberately NOT watched here — nothing
/// in the display-prefs façade renders it. Default false = sync off.
const String calendarSyncEnabledKey = 'calendarSyncEnabled';

/// Hive key for Holiday Mode. When true the alarm engine schedules nothing and
/// the Sleep plan goes dormant — roster/alarm data is left fully intact, only
/// the triggers are silenced. Default false. The alarm engine reads this same
/// key off the `settings` box, so the string MUST stay in lock-step with
/// `AlarmSyncService`'s pause read.
const String isSchedulePausedKey = 'isSchedulePaused';

/// UI-only display preferences, backed by the generic `'settings'` Hive box
/// (the same untyped box that already holds `snooze_duration` /
/// `onboarding_complete` — NOT the typed `AlarmSettings` engine store).
///
/// Pure presentation: these change how existing roster/alarm data is *rendered*
/// (clock format, calendar first column), never the data itself, so they live
/// outside the alarm engine entirely.
///
/// Bridges the box's [ValueListenable] to [ChangeNotifier] so `context.watch`
/// consumers rebuild the instant a toggle writes — the box is the source of
/// truth, this is just the reactive, typed façade over it.
class AppPreferences extends ChangeNotifier {
  AppPreferences(this._box) {
    _listenable = _box.listenable(
      keys: const <String>[
        use24HourTimeKey,
        startWeekOnMondayKey,
        timelineDefaultMonthKey,
        // Note: timePickerUseDialKey is deliberately NOT watched here — it's
        // read via `listen: false` only when a picker opens, and nothing on
        // screen reflects it live, so notifying every watcher on each toggle
        // would be a wasted rebuild.
        alarmSortByShiftTypeKey,
        sleepGoalHoursKey,
        windDownMinutesKey,
        bedtimeReminderEnabledKey,
        windDownReminderEnabledKey,
        sleepSoundTimerMinutesKey,
        isSchedulePausedKey,
      ],
    )..addListener(notifyListeners);
  }

  final Box _box;
  late final ValueListenable<Box> _listenable;

  bool get use24HourTime =>
      _box.get(use24HourTimeKey, defaultValue: false) as bool;

  bool get startWeekOnMonday =>
      _box.get(startWeekOnMondayKey, defaultValue: true) as bool;

  /// Whether the Timeline opens on the Month calendar (true) or the List (false,
  /// default). Read once when the Timeline mounts to pick its initial view.
  bool get timelineDefaultsToMonth =>
      _box.get(timelineDefaultMonthKey, defaultValue: false) as bool;

  /// Whether time pickers should open on the analog dial (true) or the
  /// tap-to-type keyboard (false, default). Read when a picker opens.
  bool get timePickerUsesDial =>
      _box.get(timePickerUseDialKey, defaultValue: false) as bool;

  /// Whether the Alarms tab groups by shift type (true) or orders purely by
  /// ring time (false, default). Watched — the list re-sorts the instant it
  /// changes.
  bool get alarmSortByShiftType =>
      _box.get(alarmSortByShiftTypeKey, defaultValue: false) as bool;

  // ── Sleep MVP preferences ────────────────────────────────────────────────
  // Pure UI/planning settings (no engine or notification wiring yet). Stored
  // in the same generic box alongside the display prefs above.

  int get sleepGoalHours =>
      _box.get(sleepGoalHoursKey, defaultValue: kDefaultSleepGoalHours) as int;

  int get windDownMinutes =>
      _box.get(windDownMinutesKey, defaultValue: kDefaultWindDownMinutes)
          as int;

  bool get bedtimeReminderEnabled =>
      _box.get(bedtimeReminderEnabledKey, defaultValue: false) as bool;

  bool get windDownReminderEnabled =>
      _box.get(windDownReminderEnabledKey, defaultValue: false) as bool;

  /// Sleep-sound auto-stop timer in minutes (0 = until stopped). Default 30.
  int get sleepSoundTimerMinutes =>
      _box.get(sleepSoundTimerMinutesKey,
          defaultValue: kDefaultSleepSoundTimerMinutes) as int;

  bool get isSchedulePaused =>
      _box.get(isSchedulePausedKey, defaultValue: false) as bool;

  void setUse24HourTime(bool value) => _putAndFlush(use24HourTimeKey, value);

  void setStartWeekOnMonday(bool value) =>
      _putAndFlush(startWeekOnMondayKey, value);

  void setTimelineDefaultsToMonth(bool value) =>
      _putAndFlush(timelineDefaultMonthKey, value);

  void setTimePickerUsesDial(bool value) =>
      _putAndFlush(timePickerUseDialKey, value);

  void setAlarmSortByShiftType(bool value) =>
      _putAndFlush(alarmSortByShiftTypeKey, value);

  void setSleepGoalHours(int value) => _putAndFlush(sleepGoalHoursKey, value);

  void setWindDownMinutes(int value) => _putAndFlush(windDownMinutesKey, value);

  void setBedtimeReminderEnabled(bool value) =>
      _putAndFlush(bedtimeReminderEnabledKey, value);

  void setWindDownReminderEnabled(bool value) =>
      _putAndFlush(windDownReminderEnabledKey, value);

  void setSleepSoundTimerMinutes(int value) =>
      _putAndFlush(sleepSoundTimerMinutesKey, value);

  void setIsSchedulePaused(bool value) => _putAndFlush(isSchedulePausedKey, value);

  /// Writes [value] then schedules a durability flush. The in-memory `put`
  /// updates the box AND fires its [ValueListenable] synchronously, so the UI
  /// and every `get` reflect the change instantly (this stays a `void` setter —
  /// callers are fire-and-forget UI toggles). The flush is the reap-durability
  /// guard the AppAlarm repo also makes: on an aggressive-reap OEM device a bare
  /// `put` can be lost if the process is killed before Hive's lazy flush lands,
  /// silently reverting the setting (the "app doesn't remember its settings"
  /// bug). Kept synchronous (no `await`) so a fire-and-forget UI callback can't
  /// leak a pending-I/O Future into a widget test's async zone; flush errors are
  /// swallowed — the next successful write (or app foreground) re-persists.
  void _putAndFlush(String key, Object value) {
    _box.put(key, value);
    _box.flush().catchError((Object _) {});
  }

  @override
  void dispose() {
    _listenable.removeListener(notifyListeners);
    super.dispose();
  }

  /// Tolerant reader for the 12/24-hour preference: returns the live value when
  /// an [AppPreferences] is in the tree, else the default (12-hour). The
  /// nullable lookup means widget tests that pump a screen without this
  /// provider degrade to the default rather than throwing.
  static bool use24HourOf(BuildContext context) =>
      context.watch<AppPreferences?>()?.use24HourTime ?? false;

  /// Tolerant reader for the week-start preference (default Monday). Same
  /// provider-absent fallback contract as [use24HourOf].
  static bool startWeekOnMondayOf(BuildContext context) =>
      context.watch<AppPreferences?>()?.startWeekOnMonday ?? true;

  /// Tolerant reader for the Timeline default-view preference (default List).
  /// Read once via `context.read` when the Timeline mounts, so no listen.
  static bool timelineDefaultsToMonthOf(BuildContext context) =>
      Provider.of<AppPreferences?>(context, listen: false)
          ?.timelineDefaultsToMonth ??
      false;

  /// Tolerant reader for Holiday Mode (default false = armed). Same
  /// provider-absent fallback contract as [use24HourOf].
  static bool isSchedulePausedOf(BuildContext context) =>
      context.watch<AppPreferences?>()?.isSchedulePaused ?? false;

  /// Tolerant reader for the preferred time-picker entry mode (default false =
  /// keyboard). Read via `listen: false` at picker-open time — never a watch.
  static bool timePickerUsesDialOf(BuildContext context) =>
      Provider.of<AppPreferences?>(context, listen: false)
          ?.timePickerUsesDial ??
      false;

  /// Tolerant reader for the Alarms-tab sort order (default false = by ring
  /// time). Watched, so the list re-sorts when the user flips the toggle.
  static bool alarmSortByShiftTypeOf(BuildContext context) =>
      context.watch<AppPreferences?>()?.alarmSortByShiftType ?? false;
}
