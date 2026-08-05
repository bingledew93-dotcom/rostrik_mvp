/// OS-level scheduling contract used by `AlarmSyncService`.
///
/// The concrete production implementation is `NativeAlarmScheduler`, which
/// drives the native Android AlarmManager bridge. Tests inject a
/// `FakeAlarmScheduler` instead so reconciliation logic can be verified without
/// touching the OS.
abstract class AlarmScheduler {
  /// Schedules a single one-shot notification to fire at [fireAt].
  /// If [id] already exists, implementations must replace it.
  ///
  /// [payload] is an opaque string forwarded back to the app when the
  /// notification launches it (used by the wake-up flow to identify
  /// which shift to display + which OS notification to cancel).
  ///
  /// [soundKey] is the bundled-tone key (see `AlarmSound.key`). Implementations
  /// select the per-tone Android notification channel and iOS sound file from
  /// it (`resolveAlarmSound` falls back to the default for an unknown key).
  Future<void> scheduleAt({
    required int id,
    required DateTime fireAt,
    required String title,
    required String body,
    required String soundKey,
    String? payload,
  });

  Future<void> cancel(int id);

  Future<void> cancelAll();

  /// Returns the IDs of all currently-pending (scheduled but not yet fired)
  /// notifications.
  Future<Set<int>> pendingIds();
}
