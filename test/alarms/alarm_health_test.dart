import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_health.dart';
import 'package:rostrik_mvp/alarms/native_alarm_scheduler.dart';

/// The Dashboard reliability probe's exact-alarm check (audit F3, field-fixed
/// on the Pixel 9 XL). It MUST ask our own native channel — the same
/// AlarmManager the scheduler uses — because permission_handler resolves the
/// SCHEDULE_EXACT_ALARM group via the manifest declaration and reports a
/// false "denied" on Android 13+ where the manifest (correctly) caps that
/// permission at maxSdkVersion=32 and USE_EXACT_ALARM carries the grant.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NativeAlarmScheduler.channelName);

  void mockCanScheduleExact(Object? Function() answer) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'canScheduleExactAlarms') return answer();
      return null;
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('exact-alarm health comes from the native canScheduleExactAlarms — '
      'true reads healthy', () async {
    mockCanScheduleExact(() => true);
    final health = await probeAlarmHealth();
    expect(health.exactAlarmsAllowed, isTrue);
  });

  test('a native false (12/12L revocation) reads unhealthy', () async {
    mockCanScheduleExact(() => false);
    final health = await probeAlarmHealth();
    expect(health.exactAlarmsAllowed, isFalse);
    expect(health.ok, isFalse);
  });

  test('no channel handler (iOS / tests) degrades to healthy — never a '
      'false banner', () async {
    // No mock registered at all: the invoke fails and the probe must treat
    // exactness as a non-concept rather than warn on a guess.
    final health = await probeAlarmHealth();
    expect(health.exactAlarmsAllowed, isTrue);
  });

  test('a channel error degrades to healthy', () async {
    mockCanScheduleExact(
      () => throw PlatformException(code: 'BOOM'),
    );
    final health = await probeAlarmHealth();
    expect(health.exactAlarmsAllowed, isTrue);
  });
}
