// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShiftTypeAdapter extends TypeAdapter<ShiftType> {
  @override
  final typeId = 0;

  @override
  ShiftType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ShiftType.day;
      case 1:
        return ShiftType.night;
      case 2:
        return ShiftType.afternoon;
      case 3:
        return ShiftType.off;
      default:
        return ShiftType.day;
    }
  }

  @override
  void write(BinaryWriter writer, ShiftType obj) {
    switch (obj) {
      case ShiftType.day:
        writer.writeByte(0);
      case ShiftType.night:
        writer.writeByte(1);
      case ShiftType.afternoon:
        writer.writeByte(2);
      case ShiftType.off:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
