import '../data/models/shift.dart';
import '../data/models/shift_type.dart';

/// The working shifts a "mark leave" action over [selectedDays] would affect:
/// every non-Off shift whose date falls on one of the (midnight-normalised)
/// selected days. Off / rest days carry no alarm, so leave never touches them.
///
/// Pure so the paint-leave screen's "Apply to N shifts" count and its write set
/// come from one tested source.
List<Shift> leaveTargets(List<Shift> all, Set<DateTime> selectedDays) {
  if (selectedDays.isEmpty) return const [];
  final days = <DateTime>{
    for (final d in selectedDays) DateTime(d.year, d.month, d.day),
  };
  return [
    for (final s in all)
      if (s.type != ShiftType.off &&
          days.contains(DateTime(s.date.year, s.date.month, s.date.day)))
        s,
  ];
}
