import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../alarms/notification_id_map.dart';
import '../models/alarm_settings.dart';
import '../models/shift.dart';
import '../models/shift_type.dart';
import '../repositories/alarm_settings_repository.dart';
import '../repositories/hive_alarm_settings_repository.dart';
import '../repositories/hive_shift_repository.dart';
import '../repositories/shift_repository.dart';

/// Single bootstrap entry point for all local persistence.
///
/// Call `await LocalStorage.init()` once from `main()` before `runApp(...)`.
/// Nothing else in the app should import Hive directly — go through the
/// repositories exposed here.
class LocalStorage {
  LocalStorage._({
    required this.shifts,
    required this.alarmSettings,
    required this.notificationIds,
  });

  final ShiftRepository shifts;
  final AlarmSettingsRepository alarmSettings;
  final NotificationIdMap notificationIds;

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

    final shiftBox = await Hive.openBox<Shift>(HiveShiftRepository.boxName);
    final settingsBox = await Hive.openBox<AlarmSettings>(
      HiveAlarmSettingsRepository.boxName,
    );
    final idsBox = await Hive.openBox<int>(HiveNotificationIdMap.boxName);

    final storage = LocalStorage._(
      shifts: HiveShiftRepository(shiftBox),
      alarmSettings: HiveAlarmSettingsRepository(settingsBox),
      notificationIds: HiveNotificationIdMap(idsBox),
    );
    _instance = storage;
    return storage;
  }
}
