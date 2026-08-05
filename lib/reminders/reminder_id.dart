/// Maps a [CalendarActivity] id (a UUID string) to a stable, positive 31-bit
/// integer for use as the reminder's `AlarmManager` request code and
/// notification id.
///
/// Uses FNV-1a rather than `String.hashCode` so the value is deterministic
/// across app launches and Dart versions — the reminder reconcile relies on the
/// same activity always resolving to the same id so a re-schedule REPLACES the
/// prior alarm (and a cancel targets the right one) after a cold start.
///
/// The reminder path targets its own native receiver + action, so even an
/// (astronomically unlikely) numeric clash with a shift-alarm id can't collide
/// at the `PendingIntent` level — the component+action differ. Masked to 31 bits
/// so it's always a non-negative `int` on the platform channel.
int reminderNotificationId(String activityId) {
  // FNV-1a 32-bit.
  var hash = 0x811c9dc5;
  for (var i = 0; i < activityId.length; i++) {
    hash ^= activityId.codeUnitAt(i) & 0xff;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  // Fold to a positive 31-bit value.
  return hash & 0x7fffffff;
}
