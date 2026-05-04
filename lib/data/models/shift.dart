import 'package:hive_ce/hive.dart';

import 'shift_type.dart';

part 'shift.g.dart';

@HiveType(typeId: 1)
class Shift {
  Shift({
    required this.id,
    required DateTime date,
    required this.type,
    required this.startMinutes,
    required this.endMinutes,
    this.note,
    this.isMuted = false,
  })  : date = DateTime(date.year, date.month, date.day),
        assert(
          startMinutes >= 0 && startMinutes < 1440,
          'startMinutes must be 0..1439',
        ),
        assert(
          endMinutes >= 0 && endMinutes < 1440,
          'endMinutes must be 0..1439',
        );

  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final ShiftType type;

  @HiveField(3)
  final int startMinutes;

  @HiveField(4)
  final int endMinutes;

  @HiveField(5)
  final String? note;

  // Suppresses alarm scheduling for this shift without removing it from the
  // roster. The AlarmEngine treats `isMuted == true` as "not desired" and
  // its existing orphan-cancellation cleans up any pending OS alarm; toggling
  // back to false brings the alarm back. `defaultValue: false` makes records
  // serialized before this field was introduced read back as unmuted.
  @HiveField(6, defaultValue: false)
  final bool isMuted;

  bool get isOvernight => endMinutes <= startMinutes;

  int get durationMinutes => isOvernight
      ? endMinutes + 1440 - startMinutes
      : endMinutes - startMinutes;

  DateTime get startDateTime => date.add(Duration(minutes: startMinutes));

  DateTime get endDateTime => isOvernight
      ? date.add(Duration(days: 1, minutes: endMinutes))
      : date.add(Duration(minutes: endMinutes));

  Shift copyWith({
    String? id,
    DateTime? date,
    ShiftType? type,
    int? startMinutes,
    int? endMinutes,
    String? note,
    bool? isMuted,
  }) =>
      Shift(
        id: id ?? this.id,
        date: date ?? this.date,
        type: type ?? this.type,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
        note: note ?? this.note,
        isMuted: isMuted ?? this.isMuted,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shift &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          type == other.type &&
          startMinutes == other.startMinutes &&
          endMinutes == other.endMinutes &&
          note == other.note &&
          isMuted == other.isMuted;

  @override
  int get hashCode =>
      Object.hash(id, date, type, startMinutes, endMinutes, note, isMuted);

  @override
  String toString() =>
      'Shift(id: $id, date: $date, type: $type, '
      'start: $startMinutes, end: $endMinutes, note: $note, '
      'isMuted: $isMuted)';
}
