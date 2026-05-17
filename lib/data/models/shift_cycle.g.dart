// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_cycle.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShiftCycleAdapter extends TypeAdapter<ShiftCycle> {
  @override
  final typeId = 4;

  @override
  ShiftCycle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShiftCycle(
      id: fields[0] as String,
      label: fields[1] as String,
      summary: fields[2] as String,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime,
      createdAt: fields[5] as DateTime,
      patternId: fields[6] as String?,
      anchorDate: fields[7] as DateTime?,
      blocks: (fields[8] as List?)?.cast<CycleBlock>(),
    );
  }

  @override
  void write(BinaryWriter writer, ShiftCycle obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.summary)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.patternId)
      ..writeByte(7)
      ..write(obj.anchorDate)
      ..writeByte(8)
      ..write(obj.blocks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftCycleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
