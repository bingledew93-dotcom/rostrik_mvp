import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';

void main() {
  // Custom ringtones migrated OFF AlarmSettings onto the per-alarm AppAlarm —
  // AlarmSettings now holds only the global lead time + vibration toggle.
  group('AlarmSettings', () {
    test('defaults: 60-min lead time, vibration on', () {
      expect(AlarmSettings.defaults.leadTime, AlarmSettings.defaultLeadTime);
      expect(AlarmSettings.defaults.vibrationEnabled, isTrue);
    });

    test('copyWith updates lead time, preserving vibration', () {
      final updated =
          AlarmSettings.defaults.copyWith(leadTime: const Duration(minutes: 45));
      expect(updated.leadTime, const Duration(minutes: 45));
      expect(updated.vibrationEnabled, isTrue);
    });

    test('copyWith toggles vibration, preserving lead time', () {
      final off = AlarmSettings.defaults.copyWith(vibrationEnabled: false);
      expect(off.vibrationEnabled, isFalse);
      expect(off.leadTime, AlarmSettings.defaultLeadTime);
    });

    test('equality + hashCode cover both fields', () {
      const a = AlarmSettings(leadTime: Duration(minutes: 60));
      expect(a, AlarmSettings.defaults);
      const diffLead = AlarmSettings(leadTime: Duration(minutes: 30));
      const diffVibe = AlarmSettings(
        leadTime: Duration(minutes: 60),
        vibrationEnabled: false,
      );
      expect(a == diffLead, isFalse);
      expect(a == diffVibe, isFalse);
      expect(a.hashCode == diffVibe.hashCode, isFalse);
    });
  });
}
