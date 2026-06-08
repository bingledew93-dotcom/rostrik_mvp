import 'package:hive_ce/hive.dart';

part 'alarm_settings.g.dart';

/// Global alarm settings.
///
/// Holds the global "fire X minutes before each shift" lead time and the global
/// vibration toggle. Custom ringtones used to live here too (fields 1-3) but
/// were migrated to the per-alarm [AppAlarm] model — those legacy field numbers
/// are RETIRED, not reused: the adapter reads them off the wire of older records
/// and discards them (see `alarm_settings.g.dart`).
@HiveType(typeId: 3)
class AlarmSettings {
  const AlarmSettings({
    required this.leadTime,
    this.vibrationEnabled = true,
  });

  @HiveField(0)
  final Duration leadTime;

  // HiveFields 1 (customRingtoneUri), 2 (customRingtoneName) and 3
  // (ringtoneSource) were REMOVED when custom ringtones migrated to [AppAlarm].
  // The numbers are retired — the adapter skips them on read so existing Hive
  // records don't crash, and never writes them again.

  /// Whether a firing alarm vibrates. `@HiveField(4)` (kept at its original
  /// number for wire compatibility); defaults to true so legacy records keep
  /// the historical always-vibrate behaviour. Governs the continuous NATIVE
  /// haptic loop `WakeUpScreen` drives for custom-ringtone alarms; bundled-tone
  /// alarms still vibrate via their notification channel (Android binds channel
  /// vibration immutably, so it can't be toggled at runtime for those).
  @HiveField(4)
  final bool vibrationEnabled;

  static const Duration defaultLeadTime = Duration(minutes: 60);

  static const AlarmSettings defaults =
      AlarmSettings(leadTime: defaultLeadTime);

  AlarmSettings copyWith({
    Duration? leadTime,
    bool? vibrationEnabled,
  }) =>
      AlarmSettings(
        leadTime: leadTime ?? this.leadTime,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmSettings &&
          runtimeType == other.runtimeType &&
          leadTime == other.leadTime &&
          vibrationEnabled == other.vibrationEnabled;

  @override
  int get hashCode => Object.hash(leadTime, vibrationEnabled);

  @override
  String toString() => 'AlarmSettings(leadTime: $leadTime, '
      'vibrationEnabled: $vibrationEnabled)';
}
