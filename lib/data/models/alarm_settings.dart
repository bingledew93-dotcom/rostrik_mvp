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
  const AlarmSettings({
    required this.leadTime,
    this.customRingtoneUri,
    this.customRingtoneName,
  });

  @HiveField(0)
  final Duration leadTime;

  /// Path/URI of a user-picked custom ringtone, or null for the bundled
  /// default. Added in the Custom Ringtones phase. Nullable + a fresh
  /// [HiveField] number, so existing records (written with only field 0) read
  /// back as null — a non-breaking adapter bump.
  ///
  /// Phase 1 is storage only: this value is persisted and surfaced in the
  /// editor, but the OS-owned alarm playback path is NOT yet wired to it.
  @HiveField(1)
  final String? customRingtoneUri;

  /// Human-readable file name of [customRingtoneUri] (what the editor shows),
  /// or null when on the bundled default. Same non-breaking versioning as
  /// [customRingtoneUri].
  @HiveField(2)
  final String? customRingtoneName;

  static const Duration defaultLeadTime = Duration(minutes: 60);

  static const AlarmSettings defaults =
      AlarmSettings(leadTime: defaultLeadTime);

  AlarmSettings copyWith({
    Duration? leadTime,
    String? customRingtoneUri,
    String? customRingtoneName,
  }) =>
      AlarmSettings(
        leadTime: leadTime ?? this.leadTime,
        customRingtoneUri: customRingtoneUri ?? this.customRingtoneUri,
        customRingtoneName: customRingtoneName ?? this.customRingtoneName,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmSettings &&
          runtimeType == other.runtimeType &&
          leadTime == other.leadTime &&
          customRingtoneUri == other.customRingtoneUri &&
          customRingtoneName == other.customRingtoneName;

  @override
  int get hashCode =>
      Object.hash(leadTime, customRingtoneUri, customRingtoneName);

  @override
  String toString() => 'AlarmSettings(leadTime: $leadTime, '
      'customRingtoneUri: $customRingtoneUri, '
      'customRingtoneName: $customRingtoneName)';
}
