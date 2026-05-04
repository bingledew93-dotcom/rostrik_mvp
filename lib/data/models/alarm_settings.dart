import 'package:hive_ce/hive.dart';

part 'alarm_settings.g.dart';

/// User-configurable alarm settings.
///
/// V1 holds a single global "fire X minutes before each shift" lead time.
/// Per-shift-type lead times, snooze, ringtone, and enable/disable flags
/// will land here as additional [HiveField]s — adding a new optional field
/// with a fresh field number is a non-breaking Hive change, which is the
/// whole reason we model this as a proper [HiveType] instead of persisting
/// a raw int.
@HiveType(typeId: 3)
class AlarmSettings {
  const AlarmSettings({required this.leadTime});

  @HiveField(0)
  final Duration leadTime;

  static const Duration defaultLeadTime = Duration(minutes: 60);

  static const AlarmSettings defaults =
      AlarmSettings(leadTime: defaultLeadTime);

  AlarmSettings copyWith({Duration? leadTime}) =>
      AlarmSettings(leadTime: leadTime ?? this.leadTime);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmSettings &&
          runtimeType == other.runtimeType &&
          leadTime == other.leadTime;

  @override
  int get hashCode => leadTime.hashCode;

  @override
  String toString() => 'AlarmSettings(leadTime: $leadTime)';
}
