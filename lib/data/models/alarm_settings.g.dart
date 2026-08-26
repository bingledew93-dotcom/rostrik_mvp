// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmSettingsAdapter extends TypeAdapter<AlarmSettings> {
  @override
  final typeId = 3;

  @override
  AlarmSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    // Fields 1 (customRingtoneUri), 2 (customRingtoneName) and 3 (ringtoneSource)
    // were RETIRED when custom ringtones moved to AppAlarm. They are still read
    // off the wire of older records into `fields` above (so nothing crashes) but
    // are intentionally ignored here — only leadTime (0) + vibrationEnabled (4)
    // survive.
    return AlarmSettings(
      leadTime: fields[0] as Duration,
      vibrationEnabled: fields[4] == null ? true : fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmSettings obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.leadTime)
      ..writeByte(4)
      ..write(obj.vibrationEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
