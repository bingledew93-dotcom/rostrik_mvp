/// Pure conversions between a set of ISO weekdays and the compact bitmask
/// stored on `AppAlarm.weekdaysBitmask`.
///
/// Encoding: bit `(weekday - 1)` is set when that ISO weekday is selected,
/// matching `DateTime.weekday` (`DateTime.monday == 1` → bit 0 …
/// `DateTime.sunday == 7` → bit 6). The top bit (bit 6) is Sunday; bits ≥ 7 are
/// never produced and ignored on read.
///
/// Kept free of Flutter so it can be unit-tested directly. Display formatting
/// (the "Mon, Wed, Fri" / "Weekdays" copy) lives in `ui/shift_format.dart`
/// alongside the other label helpers; this file is data-shape only.
library;

/// All ISO weekday numbers, Monday-first, for iteration / "every day" checks.
const List<int> kAllWeekdays = <int>[1, 2, 3, 4, 5, 6, 7];

/// Packs [weekdays] (each 1..7; values outside that range are ignored) into a
/// bitmask. Order and duplicates don't matter.
int weekdayMaskFromSet(Iterable<int> weekdays) {
  var mask = 0;
  for (final d in weekdays) {
    if (d < 1 || d > 7) continue;
    mask |= 1 << (d - 1);
  }
  return mask;
}

/// Unpacks [mask] into a sorted ascending list of ISO weekdays (1..7).
List<int> weekdaysFromMask(int mask) {
  final out = <int>[];
  for (var d = 1; d <= 7; d++) {
    if (mask & (1 << (d - 1)) != 0) out.add(d);
  }
  return out;
}

/// Whether [weekday] (1..7) is selected in [mask].
bool maskHasWeekday(int mask, int weekday) {
  if (weekday < 1 || weekday > 7) return false;
  return mask & (1 << (weekday - 1)) != 0;
}
