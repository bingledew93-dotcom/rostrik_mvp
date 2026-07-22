// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_activity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalendarActivityAdapter extends TypeAdapter<CalendarActivity> {
  @override
  final typeId = 8;

  @override
  CalendarActivity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarActivity(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      title: fields[2] as String,
      kind: fields[3] as ActivityKind,
      note: fields[4] as String?,
      timeMinutes: (fields[5] as num?)?.toInt(),
      reminderAt: fields[6] as DateTime?,
      isDone: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarActivity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.kind)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.timeMinutes)
      ..writeByte(6)
      ..write(obj.reminderAt)
      ..writeByte(7)
      ..write(obj.isDone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityKindAdapter extends TypeAdapter<ActivityKind> {
  @override
  final typeId = 9;

  @override
  ActivityKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityKind.event;
      case 1:
        return ActivityKind.task;
      case 2:
        return ActivityKind.birthday;
      default:
        return ActivityKind.event;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityKind obj) {
    switch (obj) {
      case ActivityKind.event:
        writer.writeByte(0);
      case ActivityKind.task:
        writer.writeByte(1);
      case ActivityKind.birthday:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityKindAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
