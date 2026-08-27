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
  /// [repeatChain] asks the implementation to keep re-alerting after [fireAt]
  /// until the user responds — see `kAlarmRepeatChainLength`. It exists for
  /// platforms that cannot sustain a single alert: an iOS notification sound is
  /// hard-capped at ~30s, so without this the alarm simply stops and a heavy
  /// sleeper is never woken. Android ignores it — its foreground audio service
  /// already rings until dismissed.
  ///
  /// Implementations MUST cancel the whole chain when the alarm is cancelled,
  /// dismissed, or snoozed. A chain that outlives the user's dismissal is worse
  /// than a short alarm: it cannot be turned off.
  Future<void> scheduleAt({
    required int id,
    required DateTime fireAt,
    required String title,
    required String body,
    required String soundKey,
    String? payload,
    int repeatChain = 0,
  });

  Future<void> cancel(int id);

  Future<void> cancelAll();

  /// Returns the IDs of all currently-pending (scheduled but not yet fired)
  /// notifications.
  Future<Set<int>> pendingIds();
}
