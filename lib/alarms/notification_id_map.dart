import 'package:hive_ce/hive.dart';

/// Stable mapping from an occurrence key (String) to a notification id (int).
///
/// The native AlarmManager bridge keys each scheduled alarm by an int id (the
/// PendingIntent requestCode). The alarm-centric engine
/// keys occurrences as `'<alarmUuid>@<yyyy-MM-dd>'` (one OS alarm per alarm
/// rule per fire date); a naive `String.hashCode` mapping risks collisions, so
/// this allocator hands out monotonically increasing ints and persists the
/// assignment — the same occurrence always gets the same id across reconciles
/// and process restarts.
///
/// **Triggers are ephemeral.** An occurrence whose fire DATE has passed can
/// never be desired again (the engine only schedules future fire times), so
/// `AlarmSyncService` releases past-dated entries each reconcile via
/// [releaseWhere] — keeping this ledger bounded by the scheduling horizon
/// instead of growing by one entry per alarm-occurrence for the life of the
/// install. The counter NEVER rewinds on release, so a released key that is
/// somehow re-allocated gets a fresh id and can never collide with a pending
/// OS notification.
abstract class NotificationIdMap {
  /// Returns the int ID for [shiftId], allocating a new one if first seen.
  Future<int> idFor(String shiftId);

  /// Forgets the mapping for [shiftId]. Safe to call for unknown ids.
  Future<void> release(String shiftId);

  /// Forgets every mapping whose key satisfies [predicate]. The reserved
  /// internals (e.g. the Hive counter) are never offered to the predicate.
  /// Used by the reconcile's past-trigger purge.
  Future<void> releaseWhere(bool Function(String key) predicate);

  bool has(String shiftId);
}

class HiveNotificationIdMap implements NotificationIdMap {
  HiveNotificationIdMap(this._box);

  static const String boxName = 'notification_ids';
  static const String _counterKey = '__counter__';

  final Box<int> _box;

  @override
  Future<int> idFor(String shiftId) async {
    assert(shiftId != _counterKey, 'shiftId collides with reserved counter key');
    final existing = _box.get(shiftId);
    if (existing != null) return existing;
    final next = (_box.get(_counterKey) ?? 0) + 1;
    await _box.put(_counterKey, next);
    await _box.put(shiftId, next);
    return next;
  }

  @override
  Future<void> release(String shiftId) async {
    assert(shiftId != _counterKey, 'shiftId collides with reserved counter key');
    await _box.delete(shiftId);
  }

  @override
  Future<void> releaseWhere(bool Function(String key) predicate) async {
    // Snapshot the matching keys BEFORE deleting — mutating a Hive box while
    // iterating its live `keys` view is undefined behaviour.
    final doomed = <String>[
      for (final k in _box.keys)
        if (k is String && k != _counterKey && predicate(k)) k,
    ];
    if (doomed.isEmpty) return;
    await _box.deleteAll(doomed);
  }

  @override
  bool has(String shiftId) {
    if (shiftId == _counterKey) return false;
    return _box.containsKey(shiftId);
  }
}
