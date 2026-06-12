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
  bool isExactTime = false,
  int? exactTimeMinutes,
  int? relativeOffsetMinutes,
}) =>
    AppAlarm(
      id: 'a1',
      minutesOfDay: 6 * 60,
      label: 'Wake',
      repeatType: AppAlarmRepeatType.oneTime,
      customRingtoneUri: customRingtoneUri,
      customRingtoneName: customRingtoneName,
      ringtoneSource: ringtoneSource,
      isExactTime: isExactTime,
      exactTimeMinutes: exactTimeMinutes,
      relativeOffsetMinutes: relativeOffsetMinutes,
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

  group('AppAlarm — Lead Time vs Exact Time (model)', () {
    test('defaults: lead-time mode, null exact time', () {
      final a = _alarm();
      expect(a.isExactTime, isFalse);
      expect(a.exactTimeMinutes, isNull);
    });

    test('copyWith sets exact-time mode + the clock', () {
      final updated = _alarm().copyWith(isExactTime: true, exactTimeMinutes: 255);
      expect(updated.isExactTime, isTrue);
      expect(updated.exactTimeMinutes, 255);
      expect(updated.label, 'Wake'); // others preserved
    });

    test('copyWith clearExactTime resets the clock to null', () {
      final exact = _alarm(isExactTime: true, exactTimeMinutes: 255);
      final cleared = exact.copyWith(isExactTime: false, clearExactTime: true);
      expect(cleared.isExactTime, isFalse);
      expect(cleared.exactTimeMinutes, isNull);
    });

    test('equality + hashCode include the timing fields', () {
      final lead = _alarm();
      final exact = _alarm(isExactTime: true, exactTimeMinutes: 255);
      expect(lead == exact, isFalse);
      expect(lead.hashCode == exact.hashCode, isFalse);
    });

    test('a valid minute-of-day exact time is accepted; out-of-range asserts',
        () {
      expect(() => _alarm(exactTimeMinutes: 0), returnsNormally);
      expect(() => _alarm(exactTimeMinutes: 1439), returnsNormally);
      expect(() => _alarm(exactTimeMinutes: 1440), throwsA(isA<AssertionError>()));
      expect(() => _alarm(exactTimeMinutes: -1), throwsA(isA<AssertionError>()));
    });
  });

  group('AppAlarm.displayFireClockMinutes — the UI display source of truth',
      () {
    // Day shift starting 07:00; global lead 60 min throughout.
    const shiftStart = 7 * 60;
    const globalLead = 60;

    int clock(AppAlarm a) => a.displayFireClockMinutes(
          shiftStartMinutes: shiftStart,
          globalLeadMinutes: globalLead,
        );

    test('lead-time mode on the global default: shiftStart − globalLead', () {
      expect(clock(_alarm()), 6 * 60); // 07:00 − 1h = 06:00
    });

    test('lead-time mode with a per-alarm override: shiftStart − override',
        () {
      expect(clock(_alarm(relativeOffsetMinutes: 90)), 5 * 60 + 30); // 05:30
    });

    test('exact-time mode returns the exact clock, ignoring EVERY lead', () {
      // Field bug regression: exact 04:15 must render 04:15, never the
      // shiftStart − lead hand-math (05:30/06:00).
      final a = _alarm(
        isExactTime: true,
        exactTimeMinutes: 4 * 60 + 15,
        relativeOffsetMinutes: 90,
      );
      expect(clock(a), 4 * 60 + 15);
    });

    test('malformed exact-time record (null clock) falls back to lead math',
        () {
      // Same defensive rule as the engine's rotationAlarmFireAt — a wrong-but-
      // safe clock beats a crash, and BOTH must pick the same fallback.
      final a = _alarm(isExactTime: true, relativeOffsetMinutes: 90);
      expect(clock(a), 5 * 60 + 30);
    });

    test('a lead crossing midnight wraps to the previous evening clock', () {
      // 00:30 shift, 90-min lead → 23:00 (display-only wrap; the engine owns
      // the date-anchored instant).
      final a = _alarm(relativeOffsetMinutes: 90);
      expect(
        a.displayFireClockMinutes(
          shiftStartMinutes: 30,
          globalLeadMinutes: globalLead,
        ),
        23 * 60,
      );
    });

    test('activeExactTimeMinutes gates the mode exactly like the engine', () {
      expect(_alarm().activeExactTimeMinutes, isNull);
      expect(
        _alarm(isExactTime: true, exactTimeMinutes: 255).activeExactTimeMinutes,
        255,
      );
      // isExactTime without a clock → lead-time mode, not a crash.
      expect(_alarm(isExactTime: true).activeExactTimeMinutes, isNull);
      // A stored clock without the mode flag stays dormant.
      expect(_alarm(exactTimeMinutes: 255).activeExactTimeMinutes, isNull);
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

    test('round-trips an exact-time alarm (fields 15-16)', () async {
      final read = await roundTrip(
        _alarm(isExactTime: true, exactTimeMinutes: 4 * 60 + 15),
        writeWith: AppAlarmAdapter(),
      );
      expect(read.isExactTime, isTrue);
      expect(read.exactTimeMinutes, 4 * 60 + 15);
    });

    test('a lead-time alarm round-trips with isExactTime false / null clock',
        () async {
      final read = await roundTrip(_alarm(), writeWith: AppAlarmAdapter());
      expect(read.isExactTime, isFalse);
      expect(read.exactTimeMinutes, isNull);
    });

    test('a legacy record (no fields 15-16) defaults to lead-time mode',
        () async {
      // The legacy writer stops at field 11, so even though the source object
      // carries an exact time, the real adapter must read it back as lead-time.
      final read = await roundTrip(
        _alarm(isExactTime: true, exactTimeMinutes: 255),
        writeWith: _LegacyAppAlarmAdapter(),
      );
      expect(read.isExactTime, isFalse);
      expect(read.exactTimeMinutes, isNull);
    });
  });
}
