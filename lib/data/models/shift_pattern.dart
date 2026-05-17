import 'shift_type.dart';

/// One coloured block in a repeating shift cycle.
class PatternSegment {
  const PatternSegment(this.type, this.days);
  final ShiftType type;
  final int days;
}

/// A named, preset shift rotation pattern.
class ShiftPattern {
  const ShiftPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.cycleDays,
    required this.segments,
  });

  final String id;
  final String name;

  /// Full description including industry note, e.g.
  /// "7 days on, 7 days off — common in mining, oil & gas"
  final String description;

  final int cycleDays;
  final List<PatternSegment> segments;

  bool get hasDayShifts => segments.any(
        (s) => s.type == ShiftType.day || s.type == ShiftType.afternoon,
      );

  bool get hasNightShifts => segments.any((s) => s.type == ShiftType.night);
}

const kShiftPatterns = [
  ShiftPattern(
    id: '7on_7off',
    name: '7 On / 7 Off',
    description: '7 days on, 7 days off — common in mining, oil & gas',
    cycleDays: 14,
    segments: [
      PatternSegment(ShiftType.day, 7),
      PatternSegment(ShiftType.off, 7),
    ],
  ),
  ShiftPattern(
    id: '4on_4off',
    name: '4 On / 4 Off',
    description: '4 days on, 4 days off — healthcare, emergency services',
    cycleDays: 8,
    segments: [
      PatternSegment(ShiftType.day, 4),
      PatternSegment(ShiftType.off, 4),
    ],
  ),
  ShiftPattern(
    id: '7_7_7_day_night_off',
    name: '7/7/7 Day Night Off',
    description: '7 day, 7 night, 7 off — rotating shift pattern',
    cycleDays: 21,
    segments: [
      PatternSegment(ShiftType.day, 7),
      PatternSegment(ShiftType.night, 7),
      PatternSegment(ShiftType.off, 7),
    ],
  ),
  ShiftPattern(
    id: '2_2_3_rotation',
    name: '2-2-3 Rotation',
    description: '2 on, 2 off, 3 on pattern — police, fire services',
    cycleDays: 14,
    segments: [
      PatternSegment(ShiftType.day, 2),
      PatternSegment(ShiftType.off, 2),
      PatternSegment(ShiftType.day, 3),
      PatternSegment(ShiftType.off, 2),
      PatternSegment(ShiftType.night, 2),
      PatternSegment(ShiftType.off, 3),
    ],
  ),
  ShiftPattern(
    id: '5_4_4_5_rotation',
    name: '5-4-4-5 Rotation',
    description: '5 day, 4 off, 4 night, 5 off — manufacturing',
    cycleDays: 28,
    segments: [
      PatternSegment(ShiftType.day, 5),
      PatternSegment(ShiftType.off, 4),
      PatternSegment(ShiftType.night, 4),
      PatternSegment(ShiftType.off, 5),
      PatternSegment(ShiftType.day, 5),
      PatternSegment(ShiftType.off, 5),
    ],
  ),
];
