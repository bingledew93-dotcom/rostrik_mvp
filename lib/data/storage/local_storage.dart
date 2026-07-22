import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../alarms/notification_id_map.dart';
import '../models/alarm_settings.dart';
import '../models/app_alarm.dart';
import '../models/calendar_activity.dart';
import '../models/cycle_block.dart';
import '../models/shift.dart';
import '../models/shift_cycle.dart';
import '../models/shift_type.dart';
import '../repositories/alarm_settings_repository.dart';
import '../repositories/app_alarm_repository.dart';
import '../repositories/calendar_activity_repository.dart';
import '../repositories/hive_alarm_settings_repository.dart';
import '../repositories/hive_app_alarm_repository.dart';
import '../repositories/hive_calendar_activity_repository.dart';
import '../repositories/hive_shift_cycle_repository.dart';
import '../repositories/hive_shift_repository.dart';
import '../repositories/shift_cycle_repository.dart';
import '../repositories/shift_repository.dart';

/// Single bootstrap entry point for all local persistence.
///
/// Call `await LocalStorage.init()` once from `main()` before `runApp(...)`.
/// Nothing else in the app should import Hive directly — go through the
/// repositories exposed here.
class LocalStorage {
  LocalStorage._({
    required this.shifts,
    required this.cycles,
    required this.alarms,
    required this.alarmSettings,
    required this.notificationIds,
    required this.activities,
  });

  final ShiftRepository shifts;
  final ShiftCycleRepository cycles;
  final AppAlarmRepository alarms;
  final AlarmSettingsRepository alarmSettings;
  final NotificationIdMap notificationIds;
  final CalendarActivityRepository activities;

  static LocalStorage? _instance;

  static LocalStorage get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'LocalStorage.init() must be awaited before LocalStorage.instance.',
      );
    }
    return i;
  }

  static Future<LocalStorage> init() async {
    final existing = _instance;
    if (existing != null) return existing;

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ShiftTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ShiftAdapter());
    }
    // typeId 2 intentionally skipped — Hive CE ships a built-in
    // DurationAdapter at typeId 20 that handles `Duration` for us.
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AlarmSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ShiftCycleAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(AppAlarmRepeatTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(AppAlarmAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(CycleBlockAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(CalendarActivityAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(ActivityKindAdapter());
    }

    final shiftBox = await Hive.openBox<Shift>(HiveShiftRepository.boxName);
    final cycleBox = await Hive.openBox<ShiftCycle>(
      HiveShiftCycleRepository.boxName,
    );
    final alarmBox = await Hive.openBox<AppAlarm>(
      HiveAppAlarmRepository.boxName,
    );
    final settingsBox = await Hive.openBox<AlarmSettings>(
      HiveAlarmSettingsRepository.boxName,
    );
    final idsBox = await Hive.openBox<int>(HiveNotificationIdMap.boxName);
    final activityBox = await Hive.openBox<CalendarActivity>(
      HiveCalendarActivityRepository.boxName,
    );

    final storage = LocalStorage._(
      shifts: HiveShiftRepository(shiftBox),
      cycles: HiveShiftCycleRepository(cycleBox),
      alarms: HiveAppAlarmRepository(alarmBox),
      alarmSettings: HiveAlarmSettingsRepository(settingsBox),
      notificationIds: HiveNotificationIdMap(idsBox),
      activities: HiveCalendarActivityRepository(activityBox),
    );
    _instance = storage;
    return storage;
  }

  /// Factory-reset the local data: clears every typed box this owns — shifts,
  /// cycles, alarms, the global alarm settings, and the notification-id map.
  /// Clearing fires each box's change events, so the repository `watch()`
  /// streams re-emit empty and the UI reacts immediately.
  ///
  /// Out of scope (the caller handles these, since they live outside this
  /// store): cancelling pending OS alarms (no scheduler handle here) and the
  /// generic `'settings'` prefs box — onboarding flag, snooze, scheduled-fire
  /// cache — which `main()` opens, not `init()`.
  Future<void> reset() async {
    await Hive.box<Shift>(HiveShiftRepository.boxName).clear();
    await Hive.box<ShiftCycle>(HiveShiftCycleRepository.boxName).clear();
    await Hive.box<AppAlarm>(HiveAppAlarmRepository.boxName).clear();
    await Hive.box<AlarmSettings>(HiveAlarmSettingsRepository.boxName).clear();
    await Hive.box<int>(HiveNotificationIdMap.boxName).clear();
    await Hive.box<CalendarActivity>(
      HiveCalendarActivityRepository.boxName,
    ).clear();
  }
}
