// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_alarm.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppAlarmAdapter extends TypeAdapter<AppAlarm> {
  @override
  final typeId = 6;

  @override
  AppAlarm read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppAlarm(
      id: fields[0] as String,
      minutesOfDay: (fields[1] as num).toInt(),
      label: fields[2] as String,
      repeatType: fields[3] as AppAlarmRepeatType,
      enabled: fields[4] == null ? true : fields[4] as bool,
      linkedShiftType: fields[5] as ShiftType?,
      isRelativeTime: fields[6] == null ? false : fields[6] as bool,
      relativeOffsetMinutes: fields[7] == null
          ? 90
          : (fields[7] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, AppAlarm obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.minutesOfDay)
      ..writeByte(2)
      ..write(obj.label)
      ..writeByte(3)
      ..write(obj.repeatType)
      ..writeByte(4)
      ..write(obj.enabled)
      ..writeByte(5)
      ..write(obj.linkedShiftType)
      ..writeByte(6)
      ..write(obj.isRelativeTime)
      ..writeByte(7)
      ..write(obj.relativeOffsetMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppAlarmAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppAlarmRepeatTypeAdapter extends TypeAdapter<AppAlarmRepeatType> {
  @override
  final typeId = 5;

  @override
  AppAlarmRepeatType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppAlarmRepeatType.followsRotation;
      case 1:
        return AppAlarmRepeatType.oneTime;
      default:
        return AppAlarmRepeatType.followsRotation;
    }
  }

  @override
  void write(BinaryWriter writer, AppAlarmRepeatType obj) {
    switch (obj) {
      case AppAlarmRepeatType.followsRotation:
        writer.writeByte(0);
      case AppAlarmRepeatType.oneTime:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppAlarmRepeatTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
