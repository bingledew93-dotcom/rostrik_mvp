import '../models/shift.dart';

/// Pure data-access contract for shift records.
///
/// Implementations must not contain business logic (alarm policy, OFF-day
/// filtering, etc.) — that lives in higher-level services. UI and the alarm
/// engine depend only on this interface, never on a concrete storage backend.
abstract class ShiftRepository {
  Future<void> upsert(Shift shift);

  Future<void> delete(String id);

  Future<Shift?> getById(String id);

  /// Returns shifts whose `date` falls in `[fromInclusive, toExclusive)`.
  /// Both bounds are normalized to local midnight internally, so passing any
  /// `DateTime` on the desired calendar day works.
  /// Results are sorted by `date` then `startMinutes`.
  Future<List<Shift>> getInRange(
    DateTime fromInclusive,
    DateTime toExclusive,
  );

  /// Returns the next shift (any type) whose absolute start instant
  /// (`date + startMinutes`) is strictly after `now`, or null if none.
  /// Callers (e.g. alarm engine) apply their own type filtering.
  Future<Shift?> getNextAfter(DateTime now);

  /// Emits the current range result, then a fresh result on every change.
  Stream<List<Shift>> watchInRange(
    DateTime fromInclusive,
    DateTime toExclusive,
  );

  /// Returns every shift whose `cycleId` equals [cycleId]. Used by
  /// `CycleService.deleteCycle` to fan out the cascade-delete. Order
  /// is unspecified — callers that care should sort. Implementations
  /// can scan the full box (linear at app scale; if growth ever bites,
  /// add a secondary index on the cycleId field).
  Future<List<Shift>> getByCycleId(String cycleId);

  /// Returns the shift with the latest `date` for [cycleId], or null
  /// if the cycle has no materialised shifts. Used by the Invisible
  /// Extender to decide whether the rolling horizon needs topping up
  /// and to compute the next materialise window's `from` date.
  Future<Shift?> getLatestForCycle(String cycleId);
}
