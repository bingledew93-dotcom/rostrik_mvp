import '../models/shift_cycle.dart';

/// Pure data-access contract for [ShiftCycle] records.
///
/// Cycles are immutable post-creation — the API deliberately exposes
/// `create` (not `upsert`) and `delete`, no `update`. Any cycle-shape
/// change requires regenerating the rosters, which is a deletion-plus-
/// re-create flow at the orchestrator layer.
abstract class ShiftCycleRepository {
  /// Persists a new cycle. Throws on duplicate id (cycle ids are UUIDs;
  /// duplicates indicate a programmer error, not a recoverable state).
  Future<void> create(ShiftCycle cycle);

  /// Deletes by id. Idempotent — no-op if the id is unknown. Does NOT
  /// cascade to child shifts; that orchestration lives in `CycleService`.
  Future<void> delete(String id);

  Future<ShiftCycle?> getById(String id);

  /// Snapshot of every cycle, sorted by `createdAt` descending
  /// (most-recent first).
  Future<List<ShiftCycle>> getAll();

  /// Emits the current snapshot, then a fresh snapshot on every change.
  Stream<List<ShiftCycle>> watch();
}
