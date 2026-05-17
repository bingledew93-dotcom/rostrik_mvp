import 'package:flutter/foundation.dart';

import '../alarms/alarm_scheduler.dart';
import '../alarms/notification_id_map.dart';
import '../data/repositories/shift_cycle_repository.dart';
import '../data/repositories/shift_repository.dart';

/// Cascade-delete orchestrator for [ShiftCycle].
///
/// Sits in `lib/logic/` (not on the repo) because the operation reaches
/// across THREE sources of truth — the shifts box, the cycles box, and
/// the OS-owned notification queue — plus the notification-id map. The
/// repository abstraction must not depend on `AlarmScheduler` or
/// `NotificationIdMap`; this service is where the fan-out lives.
///
/// Execution order matters: cancel the OS notification BEFORE deleting
/// the shift row. If we deleted the row first, the engine's box.watch
/// reconcile (debounced 250 ms) would race us to cancel anyway, but
/// during that window the OS notification could still fire — which is
/// exactly the "ghost alarm" failure mode this service exists to prevent.
class CycleService {
  CycleService({
    required ShiftCycleRepository cycles,
    required ShiftRepository shifts,
    required AlarmScheduler scheduler,
    required NotificationIdMap idMap,
  })  : _cycles = cycles,
        _shifts = shifts,
        _scheduler = scheduler,
        _idMap = idMap;

  final ShiftCycleRepository _cycles;
  final ShiftRepository _shifts;
  final AlarmScheduler _scheduler;
  final NotificationIdMap _idMap;

  /// Cascade-delete a cycle and its descendants. Idempotent: re-calling
  /// after a successful delete is a no-op (no children found, cycle
  /// already gone). Best-effort on the OS cancel — if `scheduler.cancel`
  /// throws we log and continue, the Hive deletion is the load-bearing
  /// side effect and the engine's reconcile is the backstop.
  Future<void> deleteCycle(String cycleId) async {
    final children = await _shifts.getByCycleId(cycleId);
    for (final s in children) {
      if (_idMap.has(s.id)) {
        final notifId = await _idMap.idFor(s.id);
        try {
          await _scheduler.cancel(notifId);
        } catch (e) {
          debugPrint('[CycleService] scheduler.cancel($notifId) threw: $e');
        }
        await _idMap.release(s.id);
      }
      await _shifts.delete(s.id);
    }
    await _cycles.delete(cycleId);
  }
}
