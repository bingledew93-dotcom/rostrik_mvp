import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_payload.dart';
import 'package:rostrik_mvp/alarms/alarm_sound.dart';

void main() {
  group('AlarmPayload.encode', () {
    test('produces the canonical 7-field form', () {
      expect(
        AlarmPayload.encode(
          shiftId: 'abc',
          notificationId: 42,
          isCritical: true,
          soundKey: 'siren',
          appAlarmId: 'alarm-9',
          customRingtoneUri: '/support/ringtones/horn.mp3',
          vibrationEnabled: true,
        ),
        'abc|42|c|siren|alarm-9|/support/ringtones/horn.mp3|1',
      );
      // Null ringtone → empty field; vibration off → trailing '0'.
      expect(
        AlarmPayload.encode(
          shiftId: 'NONE',
          notificationId: 7,
          isCritical: false,
          soundKey: 'classic',
          appAlarmId: '',
          customRingtoneUri: null,
          vibrationEnabled: false,
        ),
        // 7 fields: shiftId|notifId|n|classic|<empty appAlarmId>|<empty ringtone>|0
        'NONE|7|n|classic|||0',
      );
    });
  });

  group('AlarmPayload round-trip', () {
    for (final isCritical in [true, false]) {
      for (final vibrate in [true, false]) {
        for (final soundKey in const ['classic', 'siren', 'digital', 'chime']) {
          test(
              'critical=$isCritical vibrate=$vibrate sound=$soundKey survives '
              'encode→decode', () {
            final wire = AlarmPayload.encode(
              shiftId: 'shift-1',
              notificationId: 1234,
              isCritical: isCritical,
              soundKey: soundKey,
              appAlarmId: 'alarm-1',
              customRingtoneUri: 'ring-$soundKey',
              vibrationEnabled: vibrate,
            );
            final decoded = AlarmPayload.decode(wire)!;
            expect(decoded.shiftId, 'shift-1');
            expect(decoded.notificationId, 1234);
            expect(decoded.isCritical, isCritical);
            expect(decoded.soundKey, soundKey);
            expect(decoded.appAlarmId, 'alarm-1');
            expect(decoded.customRingtoneUri, 'ring-$soundKey');
            expect(decoded.vibrationEnabled, vibrate);
          });
        }
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

    test('a 6-field (pre-vibrate) payload defaults vibration ON', () {
      // Every payload shorter than 7 fields predates the vibrate flag — they
      // must keep the historical always-vibrate behaviour.
      expect(
        AlarmPayload.decode('s1|99|n|classic|alarm-7|/ring/a.mp3')!
            .vibrationEnabled,
        isTrue,
      );
      expect(AlarmPayload.decode('s1|99')!.vibrationEnabled, isTrue);
    });

    test('a full 7-field payload exposes the vibrate flag', () {
      expect(
        AlarmPayload.decode('s1|99|n|classic|alarm-7|/ring/a.mp3|1')!
            .vibrationEnabled,
        isTrue,
      );
      expect(
        AlarmPayload.decode('s1|99|n|classic|alarm-7|/ring/a.mp3|0')!
            .vibrationEnabled,
        isFalse,
      );
    });

    test('an empty 7th field reads back as vibration ON (default)', () {
      expect(
        AlarmPayload.decode('s1|99|n|classic|alarm-7|/ring/a.mp3|')!
            .vibrationEnabled,
        isTrue,
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
