import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../alarms/alarm_scheduler.dart';
import '../alarms/notification_id_map.dart';
import '../data/models/alarm_settings.dart';
import '../data/models/app_alarm.dart';
import '../data/models/shift.dart';
import '../data/models/shift_cycle.dart';
import '../data/repositories/alarm_settings_repository.dart';
import '../data/repositories/app_alarm_repository.dart';
import '../data/repositories/shift_cycle_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../data/storage/local_storage.dart';
import '../logic/cycle_service.dart';
import '../logic/shift_generator.dart';

/// Root-level provider tree. Sits between LocalStorage (constructed in
/// main()) and the widget tree. UI never imports Hive — it reads/writes
/// through the repositories exposed here.
///
/// Deliberately does NOT expose AlarmEngine: the UI must remain ignorant
/// of alarm logic. Engine lifecycle stays owned by main().
///
/// [AlarmScheduler] IS exposed, but only so the WakeUpScreen can cancel
/// the OS notification it was launched from, and `CycleService` can
/// cancel orphans on cascade-delete. This is a controlled leak: the UI
/// is reaching back to the OS layer it was launched by, not into the
/// engine's reconciliation state.
class AppProviders extends StatelessWidget {
  const AppProviders({
    super.key,
    required this.storage,
    required this.scheduler,
    required this.child,
  });

  final LocalStorage storage;
  final AlarmScheduler scheduler;
  final Widget child;

  // Generous symmetric window around app-start `now`. Wide enough that
  // no realistic V1 view will fall outside it within a single session.
  static const _uiReadHorizon = Duration(days: 365);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return MultiProvider(
      providers: [
        Provider<ShiftRepository>.value(value: storage.shifts),
        Provider<ShiftCycleRepository>.value(value: storage.cycles),
        Provider<AppAlarmRepository>.value(value: storage.alarms),
        Provider<AlarmSettingsRepository>.value(value: storage.alarmSettings),
        Provider<AlarmScheduler>.value(value: scheduler),
        // Exposed (read-only from the UI's perspective) so the timeline's
        // "kill snooze" affordance can resolve shiftId → notificationId
        // without dragging the engine into the widget tree. The engine is
        // still the writer/allocator; the UI uses `has` + `idFor` purely
        // as a lookup. `NotificationIdMap.idFor` is documented to allocate
        // on miss, so callers MUST guard with `has` if they want a
        // read-only lookup (which a cancel-from-the-UI is).
        Provider<NotificationIdMap>.value(value: storage.notificationIds),
        // Pure-logic helper that bulk-creates Shifts AND a parent cycle
        // on top of the repositories. ProxyProvider2 so it picks up the
        // same repo handles as the rest of the tree — no parallel
        // construction path.
        ProxyProvider2<ShiftRepository, ShiftCycleRepository, ShiftGenerator>(
          update: (_, shifts, cycles, _) =>
              ShiftGenerator(shifts: shifts, cycles: cycles),
        ),
        // Cascade-delete orchestrator. Built once per provider scope;
        // dependencies are all stable singletons so a Provider (not a
        // ProxyProvider) is sufficient.
        Provider<CycleService>(
          create: (_) => CycleService(
            cycles: storage.cycles,
            shifts: storage.shifts,
            scheduler: scheduler,
            idMap: storage.notificationIds,
          ),
        ),
        StreamProvider<List<Shift>>(
          create: (_) => storage.shifts.watchInRange(
            now.subtract(_uiReadHorizon),
            now.add(_uiReadHorizon),
          ),
          initialData: const [],
        ),
        StreamProvider<List<ShiftCycle>>(
          create: (_) => storage.cycles.watch(),
          initialData: const [],
        ),
        StreamProvider<List<AppAlarm>>(
          create: (_) => storage.alarms.watch(),
          initialData: const [],
        ),
        StreamProvider<AlarmSettings>(
          create: (_) => storage.alarmSettings.watch(),
          initialData: AlarmSettings.defaults,
        ),
      ],
      child: child,
    );
  }
}
