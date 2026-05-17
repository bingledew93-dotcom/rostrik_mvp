// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_block.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CycleBlockAdapter extends TypeAdapter<CycleBlock> {
  @override
  final typeId = 7;

  @override
  CycleBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleBlock(
      type: fields[0] as ShiftType,
      consecutiveDays: (fields[1] as num).toInt(),
      startMinutes: fields[2] == null ? 0 : (fields[2] as num).toInt(),
      endMinutes: fields[3] == null ? 0 : (fields[3] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, CycleBlock obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.consecutiveDays)
      ..writeByte(2)
      ..write(obj.startMinutes)
      ..writeByte(3)
      ..write(obj.endMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
