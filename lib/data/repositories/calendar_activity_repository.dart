import '../models/calendar_activity.dart';

/// Pure data-access contract for [CalendarActivity] records — the non-shift
/// calendar entries (events, tasks, birthdays). Deliberately independent of the
/// shift/alarm repositories: nothing in the alarm engine reads activities, so
/// this surface can never affect shift-alarm scheduling.
abstract class CalendarActivityRepository {
  /// Create or update in place, keyed by id. Idempotent.
  Future<void> upsert(CalendarActivity activity);

  /// Idempotent — no-op if the id is unknown.
  Future<void> delete(String id);

  Future<CalendarActivity?> getById(String id);

  /// Snapshot of every activity. No ordering guarantee at the repo layer.
  Future<List<CalendarActivity>> getAll();

  /// Emits the current snapshot, then a fresh snapshot on every change — the
  /// calendar subscribes to this to paint activity markers reactively.
  Stream<List<CalendarActivity>> watch();
}
