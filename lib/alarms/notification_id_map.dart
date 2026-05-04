import 'package:hive_ce/hive.dart';

/// Stable mapping from shift UUID (String) to notification id (int).
///
/// `flutter_local_notifications` requires int IDs but our shifts use UUIDs.
/// A naive `String.hashCode` mapping risks collisions; this allocator hands
/// out monotonically increasing ints and persists the assignment so the same
/// shift always gets the same id across reconciles and process restarts.
abstract class NotificationIdMap {
  /// Returns the int ID for [shiftId], allocating a new one if first seen.
  Future<int> idFor(String shiftId);

  /// Forgets the mapping for [shiftId]. Safe to call for unknown ids.
  Future<void> release(String shiftId);

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
  bool has(String shiftId) {
    if (shiftId == _counterKey) return false;
    return _box.containsKey(shiftId);
  }
}
