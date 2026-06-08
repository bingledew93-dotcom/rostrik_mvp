import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

/// Writes the pre-migration 11-field AppAlarm shape (fields 0-11, with 6
/// retired, NO 12/13/14) so we can prove the real adapter defaults the new
/// per-alarm ringtone fields on legacy records.
class _LegacyAppAlarmAdapter extends TypeAdapter<AppAlarm> {
  @override
  final typeId = 6;

  @override
  AppAlarm read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, AppAlarm obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.autoDeleteAfterFiring);
  }
}

AppAlarm _alarm({
  String? customRingtoneUri,
  String? customRingtoneName,
  RingtoneSource ringtoneSource = RingtoneSource.classic,
}) =>
    AppAlarm(
      id: 'a1',
      minutesOfDay: 6 * 60,
      label: 'Wake',
      repeatType: AppAlarmRepeatType.oneTime,
      customRingtoneUri: customRingtoneUri,
      customRingtoneName: customRingtoneName,
      ringtoneSource: ringtoneSource,
    );

void main() {
  group('AppAlarm — per-alarm custom ringtone (model)', () {
    test('defaults: classic source, null URI/name', () {
      final a = _alarm();
      expect(a.customRingtoneUri, isNull);
      expect(a.customRingtoneName, isNull);
      expect(a.ringtoneSource, RingtoneSource.classic);
    });

    test('copyWith updates ringtone fields, preserving others', () {
      final updated = _alarm().copyWith(
        customRingtoneUri: 'content://media/9',
        customRingtoneName: 'Beep',
        ringtoneSource: RingtoneSource.system,
      );
      expect(updated.customRingtoneUri, 'content://media/9');
      expect(updated.customRingtoneName, 'Beep');
      expect(updated.ringtoneSource, RingtoneSource.system);
      expect(updated.label, 'Wake');
    });

    test('equality + hashCode include the ringtone fields', () {
      final classic = _alarm();
      final vault = _alarm(
        customRingtoneUri: '/v/x.mp3',
        customRingtoneName: 'x.mp3',
        ringtoneSource: RingtoneSource.vault,
      );
      expect(classic == vault, isFalse);
      expect(classic.hashCode == vault.hashCode, isFalse);
    });
  });

  group('AppAlarmAdapter — per-alarm custom ringtone (Hive)', () {
    late Directory tempDir;
    var boxCounter = 0;

    setUpAll(() async {
      tempDir =
          await Directory.systemTemp.createTemp('rostrik_app_alarm_adapter_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ShiftTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(AppAlarmRepeatTypeAdapter());
      }
    });

    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<AppAlarm> roundTrip(
      AppAlarm value, {
      required TypeAdapter<AppAlarm> writeWith,
    }) async {
      final boxName = 'alarms_${boxCounter++}';
      Hive.registerAdapter(writeWith, override: true);
      var box = await Hive.openBox<AppAlarm>(boxName);
      await box.put('k', value);
      await box.close();
      Hive.registerAdapter(AppAlarmAdapter(), override: true);
      box = await Hive.openBox<AppAlarm>(boxName);
      final read = box.get('k')!;
      await box.deleteFromDisk();
      return read;
    }

    test('round-trips a vault ringtone', () async {
      final read = await roundTrip(
        _alarm(
          customRingtoneUri: '/support/ringtones/x.mp3',
          customRingtoneName: 'x.mp3',
          ringtoneSource: RingtoneSource.vault,
        ),
        writeWith: AppAlarmAdapter(),
      );
      expect(read.customRingtoneUri, '/support/ringtones/x.mp3');
      expect(read.customRingtoneName, 'x.mp3');
      expect(read.ringtoneSource, RingtoneSource.vault);
    });

    test('round-trips a system ringtone', () async {
      final read = await roundTrip(
        _alarm(
          customRingtoneUri: 'content://media/audio/9',
          customRingtoneName: 'Beep',
          ringtoneSource: RingtoneSource.system,
        ),
        writeWith: AppAlarmAdapter(),
      );
      expect(read.ringtoneSource, RingtoneSource.system);
      expect(read.customRingtoneUri, 'content://media/audio/9');
    });

    test('a bundled (classic) alarm round-trips with a null URI', () async {
      final read = await roundTrip(_alarm(), writeWith: AppAlarmAdapter());
      expect(read.customRingtoneUri, isNull);
      expect(read.customRingtoneName, isNull);
      expect(read.ringtoneSource, RingtoneSource.classic);
    });

    test('a legacy record (no fields 12-14) defaults to classic / null',
        () async {
      // The stale URI/source on the source object are dropped by the legacy
      // writer (it stops at field 11), so the real adapter reads them as absent.
      final read = await roundTrip(
        _alarm(
          customRingtoneUri: '/ignored.mp3',
          customRingtoneName: 'ignored.mp3',
          ringtoneSource: RingtoneSource.system,
        ),
        writeWith: _LegacyAppAlarmAdapter(),
      );
      expect(read.customRingtoneUri, isNull);
      expect(read.customRingtoneName, isNull);
      expect(read.ringtoneSource, RingtoneSource.classic);
    });
  });
}
