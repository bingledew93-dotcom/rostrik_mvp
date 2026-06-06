import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_sound.dart';

void main() {
  group('kAlarmSounds catalog integrity', () {
    test('contains the 4 beta tones', () {
      expect(
        kAlarmSounds.map((s) => s.key).toList(),
        ['classic', 'siren', 'digital', 'chime'],
      );
    });

    test('the first tone is the default', () {
      expect(kAlarmSounds.first.key, kDefaultAlarmSoundKey);
    });

    test('keys are unique', () {
      final keys = kAlarmSounds.map((s) => s.key).toSet();
      expect(keys, hasLength(kAlarmSounds.length));
    });

    test('android channel ids are unique (one channel per tone)', () {
      final ids = kAlarmSounds.map((s) => s.androidChannelId).toSet();
      expect(ids, hasLength(kAlarmSounds.length));
    });

    test('keys are payload-safe — no pipe delimiter', () {
      for (final s in kAlarmSounds) {
        expect(s.key.contains('|'), isFalse, reason: 'key "${s.key}" has a |');
      }
    });

    test('assetPath sits under assets/sounds/ and is a .wav', () {
      for (final s in kAlarmSounds) {
        expect(s.assetPath, startsWith('assets/sounds/'));
        expect(s.assetPath, endsWith('.wav'));
      }
    });

    test('iosSoundName is the asset basename', () {
      expect(kAlarmSounds.first.iosSoundName, 'classic.wav');
    });
  });

  group('resolveAlarmSound', () {
    test('resolves a known key', () {
      expect(resolveAlarmSound('siren').key, 'siren');
    });

    test('falls back to the default for an unknown key', () {
      // A tone removed in a future build must degrade to the default, never
      // strand an old alarm.
      expect(resolveAlarmSound('does-not-exist').key, kDefaultAlarmSoundKey);
    });

    test('falls back for an empty key', () {
      expect(resolveAlarmSound('').key, kDefaultAlarmSoundKey);
    });
  });
}
