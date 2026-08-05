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
      relativeOffsetMinutes: (fields[7] as num?)?.toInt(),
      isCriticalShift: fields[8] == null ? false : fields[8] as bool,
      soundKey: fields[9] == null ? 'classic' : fields[9] as String,
      weekdaysBitmask: fields[10] == null ? 0 : (fields[10] as num).toInt(),
      autoDeleteAfterFiring: fields[11] == null ? false : fields[11] as bool,
      // Fields 12-14 (per-alarm custom ringtone) added in the per-alarm audio
      // migration. Absent on legacy records → null URI/name, classic source.
      customRingtoneUri: fields[12] as String?,
      customRingtoneName: fields[13] as String?,
      ringtoneSource: fields[14] == null
          ? RingtoneSource.classic
          : RingtoneSource.values[(fields[14] as num).toInt()],
      // Fields 15-16 (Lead Time vs Exact Time) added in the time-entry-friction
      // migration. Absent on legacy records → isExactTime defaults false, exact
      // time null, so every pre-migration alarm reads back as lead-time mode.
      isExactTime: fields[15] == null ? false : fields[15] as bool,
      exactTimeMinutes: (fields[16] as num?)?.toInt(),
      // Field 17 (per-occurrence skip watermark for shift-less alarms) added
      // in the early-skip coverage migration. Absent on legacy records → null
      // (nothing skipped).
      skippedThrough: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppAlarm obj) {
    writer
      ..writeByte(17)
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
      ..writeByte(7)
      ..write(obj.relativeOffsetMinutes)
      ..writeByte(8)
      ..write(obj.isCriticalShift)
      ..writeByte(9)
      ..write(obj.soundKey)
      ..writeByte(10)
      ..write(obj.weekdaysBitmask)
      ..writeByte(11)
      ..write(obj.autoDeleteAfterFiring)
      ..writeByte(12)
      ..write(obj.customRingtoneUri)
      ..writeByte(13)
      ..write(obj.customRingtoneName)
      ..writeByte(14)
      ..write(obj.ringtoneSource.index)
      ..writeByte(15)
      ..write(obj.isExactTime)
      ..writeByte(16)
      ..write(obj.exactTimeMinutes)
      ..writeByte(17)
      ..write(obj.skippedThrough);
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
      case 2:
        return AppAlarmRepeatType.weekly;
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
      case AppAlarmRepeatType.weekly:
        writer.writeByte(2);
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
