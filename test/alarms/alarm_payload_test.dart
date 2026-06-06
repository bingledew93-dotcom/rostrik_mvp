import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_payload.dart';
import 'package:rostrik_mvp/alarms/alarm_sound.dart';

void main() {
  group('AlarmPayload.encode', () {
    test('produces the canonical 6-field form', () {
      expect(
        AlarmPayload.encode(
          shiftId: 'abc',
          notificationId: 42,
          isCritical: true,
          soundKey: 'siren',
          appAlarmId: 'alarm-9',
          customRingtoneUri: '/support/ringtones/horn.mp3',
        ),
        'abc|42|c|siren|alarm-9|/support/ringtones/horn.mp3',
      );
      // Null ringtone → empty trailing field (two pipes after the soundKey:
      // empty appAlarmId then empty ringtone).
      expect(
        AlarmPayload.encode(
          shiftId: 'NONE',
          notificationId: 7,
          isCritical: false,
          soundKey: 'classic',
          appAlarmId: '',
          customRingtoneUri: null,
        ),
        'NONE|7|n|classic||',
      );
    });
  });

  group('AlarmPayload round-trip', () {
    for (final isCritical in [true, false]) {
      for (final soundKey in const ['classic', 'siren', 'digital', 'chime']) {
        test('critical=$isCritical sound=$soundKey survives encode→decode', () {
          final wire = AlarmPayload.encode(
            shiftId: 'shift-1',
            notificationId: 1234,
            isCritical: isCritical,
            soundKey: soundKey,
            appAlarmId: 'alarm-1',
            customRingtoneUri: 'ring-$soundKey',
          );
          final decoded = AlarmPayload.decode(wire)!;
          expect(decoded.shiftId, 'shift-1');
          expect(decoded.notificationId, 1234);
          expect(decoded.isCritical, isCritical);
          expect(decoded.soundKey, soundKey);
          expect(decoded.appAlarmId, 'alarm-1');
          expect(decoded.customRingtoneUri, 'ring-$soundKey');
        });
      }
    }
  });

  group('AlarmPayload.decode backward tolerance', () {
    test('a bare 2-field payload defaults critical=false + default sound', () {
      // e.g. WakeUpScreen's in-app snooze reconstructs "shiftId|notificationId".
      final decoded = AlarmPayload.decode('s1|99')!;
      expect(decoded.shiftId, 's1');
      expect(decoded.notificationId, 99);
      expect(decoded.isCritical, isFalse);
      expect(decoded.soundKey, kDefaultAlarmSoundKey);
    });

    test('a 3-field (pre-sound) payload keeps its code, defaults the sound', () {
      final decoded = AlarmPayload.decode('s1|99|c')!;
      expect(decoded.isCritical, isTrue);
      expect(decoded.soundKey, kDefaultAlarmSoundKey);
    });

    test('an empty 4th field falls back to the default sound', () {
      expect(AlarmPayload.decode('s1|99|n|')!.soundKey, kDefaultAlarmSoundKey);
    });

    test('a non-c code in field 3 is treated as normal', () {
      expect(AlarmPayload.decode('s1|99|x|siren')!.isCritical, isFalse);
    });

    test('a 4-field (pre-appAlarmId) payload decodes with empty appAlarmId', () {
      // The exact wire form from the build immediately before this field
      // landed, plus older 2/3-field strings — none carry a rule id.
      expect(AlarmPayload.decode('s1|99|c|siren')!.appAlarmId, '');
      expect(AlarmPayload.decode('s1|99')!.appAlarmId, '');
      expect(AlarmPayload.decode('s1|99|c')!.appAlarmId, '');
    });

    test('a full 5-field payload exposes the appAlarmId', () {
      expect(
        AlarmPayload.decode('s1|99|n|classic|alarm-7')!.appAlarmId,
        'alarm-7',
      );
    });

    test('an empty 5th field reads back as empty appAlarmId', () {
      expect(AlarmPayload.decode('s1|99|n|classic|')!.appAlarmId, '');
    });

    test('a 5-field (pre-ringtone) payload decodes with null ringtone', () {
      // The exact wire form from the build before the ringtone field landed,
      // plus shorter legacy strings — none carry a ringtone.
      expect(
        AlarmPayload.decode('s1|99|n|classic|alarm-7')!.customRingtoneUri,
        isNull,
      );
      expect(AlarmPayload.decode('s1|99')!.customRingtoneUri, isNull);
    });

    test('a full 6-field payload exposes the ringtone path', () {
      expect(
        AlarmPayload.decode('s1|99|n|classic|alarm-7|/ring/a.mp3')!
            .customRingtoneUri,
        '/ring/a.mp3',
      );
    });

    test('an empty 6th field reads back as null ringtone', () {
      expect(
        AlarmPayload.decode('s1|99|n|classic|alarm-7|')!.customRingtoneUri,
        isNull,
      );
    });
  });

  group('AlarmPayload.decode rejects malformed input', () {
    test('null / empty → null', () {
      expect(AlarmPayload.decode(null), isNull);
      expect(AlarmPayload.decode(''), isNull);
    });

    test('empty shiftId → null', () {
      expect(AlarmPayload.decode('|99|n|classic'), isNull);
    });

    test('non-int notificationId → null', () {
      expect(AlarmPayload.decode('s1|notanint|n|classic'), isNull);
    });

    test('single field (no notificationId) → null', () {
      expect(AlarmPayload.decode('s1'), isNull);
    });
  });
}
