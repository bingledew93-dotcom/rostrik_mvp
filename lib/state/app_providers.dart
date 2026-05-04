import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../alarms/alarm_scheduler.dart';
import '../data/models/alarm_settings.dart';
import '../data/models/shift.dart';
import '../data/repositories/alarm_settings_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../data/storage/local_storage.dart';
import '../logic/shift_generator.dart';

/// Root-level provider tree. Sits between LocalStorage (constructed in
/// main()) and the widget tree. UI never imports Hive — it reads/writes
/// through the repositories exposed here.
///
/// Deliberately does NOT expose AlarmEngine: the UI must remain ignorant
/// of alarm logic. Engine lifecycle stays owned by main().
///
/// [AlarmScheduler] IS exposed, but only so the WakeUpScreen can cancel
/// the OS notification it was launched from. This is a controlled leak:
/// the UI is reaching back to the OS layer it was launched by, not into
/// the engine's reconciliation state.
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
        Provider<AlarmSettingsRepository>.value(value: storage.alarmSettings),
        Provider<AlarmScheduler>.value(value: scheduler),
        // Pure-logic helper that bulk-creates Shifts on top of the
        // repository. ProxyProvider so it picks up the same repo handle
        // as the rest of the tree — no parallel construction path.
        ProxyProvider<ShiftRepository, ShiftGenerator>(
          update: (_, repo, _) => ShiftGenerator(repository: repo),
        ),
        StreamProvider<List<Shift>>(
          create: (_) => storage.shifts.watchInRange(
            now.subtract(_uiReadHorizon),
            now.add(_uiReadHorizon),
          ),
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
