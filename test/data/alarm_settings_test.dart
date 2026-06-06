import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';

void main() {
  group('AlarmSettings — custom ringtone versioning', () {
    test('defaults carry a null ringtone (matches legacy 1-field records)', () {
      expect(AlarmSettings.defaults.customRingtoneUri, isNull);
      expect(AlarmSettings.defaults.customRingtoneName, isNull);
    });

    test('copyWith sets the ringtone path + name, preserving lead time', () {
      final updated = AlarmSettings.defaults.copyWith(
        customRingtoneUri: '/cache/song.mp3',
        customRingtoneName: 'song.mp3',
      );
      expect(updated.leadTime, AlarmSettings.defaultLeadTime);
      expect(updated.customRingtoneUri, '/cache/song.mp3');
      expect(updated.customRingtoneName, 'song.mp3');
    });

    test('copyWith without ringtone args leaves existing values intact', () {
      const withTone = AlarmSettings(
        leadTime: Duration(minutes: 30),
        customRingtoneUri: '/cache/a.wav',
        customRingtoneName: 'a.wav',
      );
      final bumped = withTone.copyWith(leadTime: const Duration(minutes: 45));
      expect(bumped.leadTime, const Duration(minutes: 45));
      expect(bumped.customRingtoneUri, '/cache/a.wav');
      expect(bumped.customRingtoneName, 'a.wav');
    });

    test('equality + hashCode include the ringtone fields', () {
      const a = AlarmSettings(leadTime: Duration(minutes: 60));
      const b = AlarmSettings(
        leadTime: Duration(minutes: 60),
        customRingtoneName: 'x.mp3',
      );
      expect(a, AlarmSettings.defaults); // both null-ringtone → equal
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
    });
  });
}
