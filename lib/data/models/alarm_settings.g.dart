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
    return AlarmSettings(
      leadTime: fields[0] as Duration,
      customRingtoneUri: fields[1] as String?,
      customRingtoneName: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.leadTime)
      ..writeByte(1)
      ..write(obj.customRingtoneUri)
      ..writeByte(2)
      ..write(obj.customRingtoneName);
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
