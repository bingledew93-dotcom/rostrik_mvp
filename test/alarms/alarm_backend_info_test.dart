import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_backend_info.dart';

void main() {
  tearDown(() => AlarmBackendInfo.debugOverride = null);

  group('AlarmBackendInfo', () {
    // The direction of this default is the whole safety argument. The two
    // backends have opposite budgets: notifications share a hard 64-entry
    // ceiling that iOS enforces by SILENTLY DROPPING anything past it, while
    // AlarmKit has no practical cap (≥400 measured on device).
    //
    // So guessing wrong in one direction under-schedules — a shorter pre-armed
    // horizon, self-corrected by the next reconcile. Guessing wrong the other
    // way overshoots the ceiling and alarms simply never ring, with no error
    // raised anywhere. Only one of those is recoverable.
    test('defaults to the conservative backend before any refresh', () {
      expect(AlarmBackendInfo.isAlarmKit, isFalse);
    });

    test('a failed or absent refresh leaves the conservative default', () async {
      // No channel is registered in a test binding, so this is the missing
      // plugin path — the same one the background isolate hits.
      await AlarmBackendInfo.refresh();
      expect(AlarmBackendInfo.isAlarmKit, isFalse);
    });

    test('debugOverride pins the value and unwinds cleanly', () {
      AlarmBackendInfo.debugOverride = true;
      expect(AlarmBackendInfo.isAlarmKit, isTrue);
      AlarmBackendInfo.debugOverride = null;
      expect(AlarmBackendInfo.isAlarmKit, isFalse);
    });
  });
}
