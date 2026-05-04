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
    return AlarmSettings(leadTime: fields[0] as Duration);
  }

  @override
  void write(BinaryWriter writer, AlarmSettings obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.leadTime);
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
