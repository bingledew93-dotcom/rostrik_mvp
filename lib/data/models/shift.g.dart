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
      isAcknowledged: fields[7] == null ? false : fields[7] as bool,
      snoozedUntil: fields[8] as DateTime?,
      cycleId: fields[9] as String?,
      isAlarmSkipped: fields[10] == null ? false : fields[10] as bool,
      isAdHoc: fields[11] == null ? false : fields[11] as bool,
      isArchived: fields[12] == null ? false : fields[12] as bool,
      isPaused: fields[13] == null ? false : fields[13] as bool,
      pauseReason: fields[14] as String?,
      dismissedAlarmIds:
          fields[15] == null ? [] : (fields[15] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Shift obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.isMuted)
      ..writeByte(7)
      ..write(obj.isAcknowledged)
      ..writeByte(8)
      ..write(obj.snoozedUntil)
      ..writeByte(9)
      ..write(obj.cycleId)
      ..writeByte(10)
      ..write(obj.isAlarmSkipped)
      ..writeByte(11)
      ..write(obj.isAdHoc)
      ..writeByte(12)
      ..write(obj.isArchived)
      ..writeByte(13)
      ..write(obj.isPaused)
      ..writeByte(14)
      ..write(obj.pauseReason)
      ..writeByte(15)
      ..write(obj.dismissedAlarmIds);
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
