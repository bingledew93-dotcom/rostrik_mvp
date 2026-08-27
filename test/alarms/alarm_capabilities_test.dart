import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_capabilities.dart';

void main() {
  tearDown(() => AlarmCapabilities.debugOverride = null);

  group('AlarmCapabilities', () {
    // The two profiles encode a real product claim: Android owns the whole
    // wake surface, iOS-via-notifications owns none of it.
    test('Android has the full alarm surface', () {
      const c = AlarmCapabilities.android;
      expect(c.shakeToDismiss, isTrue);
      expect(c.customTonePicker, isTrue);
      expect(c.systemTonePicker, isTrue);
      expect(c.soundBeyondThirtySeconds, isTrue);
      expect(c.piercesSilentSwitch, isTrue);
      expect(c.fullScreenAlarm, isTrue);
    });

    test('the iOS notification path claims none of it', () {
      const c = AlarmCapabilities.iosNotification;
      expect(c.shakeToDismiss, isFalse);
      expect(c.customTonePicker, isFalse);
      expect(c.systemTonePicker, isFalse);
      expect(c.soundBeyondThirtySeconds, isFalse);
      expect(c.piercesSilentSwitch, isFalse);
      expect(c.fullScreenAlarm, isFalse);
    });

    // Widget tests run off-device and must keep asserting on the full-featured
    // UI, so the default has to stay Android rather than "whatever the host is".
    test('defaults to the full surface when nothing is overridden', () {
      expect(AlarmCapabilities.current.shakeToDismiss, isTrue);
    });

    test('debugOverride pins the value and unwinds cleanly', () {
      AlarmCapabilities.debugOverride = AlarmCapabilities.iosNotification;
      expect(AlarmCapabilities.current.shakeToDismiss, isFalse);
      AlarmCapabilities.debugOverride = null;
      expect(AlarmCapabilities.current.shakeToDismiss, isTrue);
    });
  });
}
