// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShiftAdapter extends TypeAdapter<Shift> {
  @override
  final typeId = 1;

  @override
  Shift read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Shift(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      type: fields[2] as ShiftType,
      startMinutes: (fields[3] as num).toInt(),
      endMinutes: (fields[4] as num).toInt(),
      note: fields[5] as String?,
      isMuted: fields[6] == null ? false : fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Shift obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.startMinutes)
      ..writeByte(4)
      ..write(obj.endMinutes)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.isMuted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
