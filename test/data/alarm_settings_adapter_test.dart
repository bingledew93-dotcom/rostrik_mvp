import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';

/// Writes the OLD pre-migration 5-field shape: leadTime(0), customRingtoneUri(1),
/// customRingtoneName(2), ringtoneSource.index(3), vibrationEnabled(4). Custom
/// ringtones have since moved to AppAlarm, so the real adapter must read leadTime
/// + vibration and SKIP the retired fields 1/2/3 without crashing.
class _LegacyFullAlarmSettingsAdapter extends TypeAdapter<AlarmSettings> {
  @override
  final typeId = 3;

  @override
  AlarmSettings read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, AlarmSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.leadTime)
      ..writeByte(1)
      ..write('/cache/retired.mp3') // retired customRingtoneUri
      ..writeByte(2)
      ..write('retired.mp3') // retired customRingtoneName
      ..writeByte(3)
      ..write(1) // retired ringtoneSource.index (was 'vault')
      ..writeByte(4)
      ..write(obj.vibrationEnabled);
  }
}

/// Writes the original 1-field shape (leadTime only) — a truly-legacy record
/// from before vibration / ringtone fields existed.
class _LeadOnlyAlarmSettingsAdapter extends TypeAdapter<AlarmSettings> {
  @override
  final typeId = 3;

  @override
  AlarmSettings read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, AlarmSettings obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.leadTime);
  }
}

void main() {
  late Directory tempDir;
  var boxCounter = 0;

  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('rostrik_alarm_settings_adapter_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<AlarmSettings> roundTrip(
    AlarmSettings value, {
    required TypeAdapter<AlarmSettings> writeWith,
  }) async {
    final boxName = 'alarm_settings_${boxCounter++}';

    Hive.registerAdapter(writeWith, override: true);
    var box = await Hive.openBox<AlarmSettings>(boxName);
    await box.put('k', value);
    await box.close();

    Hive.registerAdapter(AlarmSettingsAdapter(), override: true);
    box = await Hive.openBox<AlarmSettings>(boxName);
    final read = box.get('k')!;
    await box.deleteFromDisk();
    return read;
  }

  group('AlarmSettingsAdapter — post-migration shape', () {
    test('round-trips leadTime + vibrationEnabled', () async {
      final read = await roundTrip(
        const AlarmSettings(
          leadTime: Duration(minutes: 45),
          vibrationEnabled: false,
        ),
        writeWith: AlarmSettingsAdapter(),
      );
      expect(read.leadTime, const Duration(minutes: 45));
      expect(read.vibrationEnabled, isFalse);
    });

    test('a legacy record with retired ringtone fields reads without crashing',
        () async {
      // The old 5-field shape (with customRingtoneUri/Name/source) must decode
      // to just leadTime + vibration — fields 1/2/3 are read off the wire and
      // discarded, not surfaced.
      final read = await roundTrip(
        const AlarmSettings(
          leadTime: Duration(minutes: 60),
          vibrationEnabled: true,
        ),
        writeWith: _LegacyFullAlarmSettingsAdapter(),
      );
      expect(read.leadTime, const Duration(minutes: 60));
      expect(read.vibrationEnabled, isTrue);
    });

    test('a lead-only legacy record defaults vibration ON', () async {
      final read = await roundTrip(
        const AlarmSettings(leadTime: Duration(minutes: 90)),
        writeWith: _LeadOnlyAlarmSettingsAdapter(),
      );
      expect(read.leadTime, const Duration(minutes: 90));
      expect(read.vibrationEnabled, isTrue);
    });
  });
}
