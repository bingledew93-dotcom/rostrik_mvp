import 'package:flutter/material.dart';

import '../data/models/shift_type.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Mon, May 4". DateTime.weekday is 1=Mon..7=Sun.
String formatShiftDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';

/// 24-hour zero-padded — matches roster card subtitle for consistency.
String formatHhmm(int minutesOfDay) {
  final h = (minutesOfDay ~/ 60).toString().padLeft(2, '0');
  final m = (minutesOfDay % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String formatTimeOfDay(TimeOfDay t) => formatHhmm(t.hour * 60 + t.minute);

String shiftTypeLabel(ShiftType type) {
  switch (type) {
    case ShiftType.day:
      return 'Day';
    case ShiftType.afternoon:
      return 'Afternoon';
    case ShiftType.night:
      return 'Night';
    case ShiftType.off:
      return 'Off';
  }
}
