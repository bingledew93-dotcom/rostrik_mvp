import 'dart:io';

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

    // A bare filename with its extension, because `UNNotificationSound(named:)`
    // resolves against the main bundle — a path would not be found, and a
    // missing extension silently falls back to the default chime.
    test('iosSoundName is a bare .caf filename, not a path', () {
      for (final s in kAlarmSounds) {
        expect(s.iosSoundName, endsWith('.caf'));
        expect(s.iosSoundName, isNot(contains('/')));
      }
    });

    test('iosSoundName matches the tone key', () {
      expect(kAlarmSounds.first.iosSoundName, 'classic.caf');
      for (final s in kAlarmSounds) {
        expect(s.iosSoundName, '${s.key}.caf');
      }
    });

    // Both halves of this fail SILENTLY on device: a missing file and an
    // over-length file both make iOS substitute the default chime, with no
    // error anywhere. Catching it here beats discovering it from a phone that
    // rang with the wrong sound.
    test('every iOS tone exists on disk and is under Apple\'s 30s cap', () {
      for (final s in kAlarmSounds) {
        final file = File('ios/Runner/Sounds/${s.iosSoundName}');
        expect(
          file.existsSync(),
          isTrue,
          reason: '${s.iosSoundName} is missing — run '
              'ios/tools/generate_alarm_tones.sh',
        );
        // IMA4 at 44.1kHz mono is ~22.9 KB/s; 30s is therefore ~688 KB. A
        // generous byte ceiling catches a tone regenerated without the cap
        // without needing a CAF parser in a unit test.
        expect(
          file.lengthSync(),
          lessThan(750 * 1024),
          reason: '${s.iosSoundName} looks longer than 30s; iOS would fall '
              'back to the default chime',
        );
      }
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
