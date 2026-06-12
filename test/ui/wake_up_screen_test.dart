import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall, MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/alarms/alarm_scheduler.dart';
import 'package:rostrik_mvp/alarms/alarm_sync_service.dart'
    show noShiftPayloadSentinel;
import 'package:rostrik_mvp/alarms/ringtone_channel.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_cycle.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/app_alarm_repository.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/state/app_preferences.dart';
import 'package:rostrik_mvp/ui/main_layout.dart';
import 'package:rostrik_mvp/ui/wake_up_screen.dart';

import '../alarms/fakes.dart';

/// Records which native-audio entry point WakeUpScreen invokes, bypassing the
/// real channel's off-Android no-op so the routing decision is observable on
/// the host test platform.
class _RecordingRingtoneChannel extends RingtoneChannel {
  final List<String> calls = [];
  String? bundledResource;
  String? customUri;

  @override
  Future<void> playAlarmBundled(String androidResource, {bool vibrate = false}) async {
    calls.add('playAlarmBundled');
    bundledResource = androidResource;
  }

  @override
  Future<void> playAlarmUri(String uri, {bool vibrate = false}) async {
    calls.add('playAlarmUri');
    customUri = uri;
  }

  @override
  Future<void> stopPreview() async {
    calls.add('stopPreview');
  }
}

/// WakeUpScreen back-gesture lockdown (Phase 2, Critical Shift Engine).
///
/// The screen is the ROOT route on alarm launch, so a system back /
/// predictive-back that bubbles to the OS finishes the FSI activity — tearing
/// the screen down and (via the dispose safety net) silencing a custom-tone
/// alarm with no dismiss/snooze bookkeeping. The lockdown is an UNCONDITIONAL
/// `PopScope(canPop: false)`: every alarm, critical or standard, may only be
/// exited through the explicit affordances (Snooze / slide / shake / hold).
///
/// Uses the `noShiftPayloadSentinel` shift id so the screen skips its
/// repository subscription and shift lookup — no providers needed; only the
/// `settings` Hive box (read synchronously in build for the Snooze label).
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('wake_up_screen_test');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // best-effort temp cleanup.
    }
  });

  Future<void> pumpWakeUp(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WakeUpScreen(
          shiftId: noShiftPayloadSentinel,
          notificationId: 1,
        ),
      ),
    );
    await tester.pump();
  }

  group('all fire-time audio routes through the foreground service', () {
    Future<_RecordingRingtoneChannel> pumpWithRingtone(
      WidgetTester tester, {
      String? customRingtoneUri,
      String soundKey = 'classic',
    }) async {
      final ringtone = _RecordingRingtoneChannel();
      await tester.pumpWidget(
        MaterialApp(
          home: WakeUpScreen(
            shiftId: noShiftPayloadSentinel,
            notificationId: 1,
            customRingtoneUri: customRingtoneUri,
            soundKey: soundKey,
            ringtoneChannel: ringtone,
          ),
        ),
      );
      await tester.pump();
      return ringtone;
    }

    testWidgets('a PRESET alarm plays its bundled tone (was the leak: presets '
        'rode FLAG_INSISTENT, silenced by the lock-screen shade)',
        (tester) async {
      final ringtone =
          await pumpWithRingtone(tester, soundKey: 'siren');
      expect(ringtone.calls, contains('playAlarmBundled'),
          reason: 'a preset must play through the foreground-service engine');
      expect(ringtone.bundledResource, 'siren',
          reason: "the soundKey's res/raw resource is what the service plays");

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a CUSTOM alarm plays its URI through the same service',
        (tester) async {
      final ringtone = await pumpWithRingtone(
        tester,
        customRingtoneUri: '/vault/midnight.mp3',
      );
      expect(ringtone.calls, contains('playAlarmUri'));
      expect(ringtone.customUri, '/vault/midnight.mp3');
      expect(ringtone.calls, isNot(contains('playAlarmBundled')),
          reason: 'a custom URI takes precedence over the preset tone');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('an unknown soundKey still routes to the bundled path '
        '(native side degrades to classic)', (tester) async {
      final ringtone =
          await pumpWithRingtone(tester, soundKey: 'tone-removed-in-v9');
      // resolveAlarmSound falls back to the default tone → classic_alarm.
      expect(ringtone.calls, contains('playAlarmBundled'));
      expect(ringtone.bundledResource, 'classic_alarm');

      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('the root Scaffold is wrapped in PopScope(canPop: false)',
      (tester) async {
    await pumpWakeUp(tester);

    final popScope = tester.widget<PopScope>(
      find.descendant(
        of: find.byType(WakeUpScreen),
        matching: find.byType(PopScope),
      ),
    );
    expect(popScope.canPop, isFalse,
        reason: 'back-swipe must never dismiss a ringing alarm');
    // The PopScope must sit ABOVE the Scaffold so the whole screen is locked.
    expect(
      find.descendant(
        of: find.byType(PopScope),
        matching: find.byType(Scaffold),
      ),
      findsOneWidget,
    );

    // Dispose before the test ends so the 1 Hz clock ticker is cancelled.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a system back gesture is vetoed and the screen survives',
      (tester) async {
    await pumpWakeUp(tester);

    // `maybePop` is exactly what the system back routes into. On a root route
    // WITHOUT the lockdown it returns false (the pop "bubbles" to the OS,
    // which finishes the FSI activity); with PopScope(canPop: false) the
    // route VETOES the pop and reports it handled.
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    final bool handled = await navigator.maybePop();
    await tester.pump();

    expect(handled, isTrue,
        reason: 'the pop must be consumed in-app, never bubbled to the OS');
    expect(find.byType(WakeUpScreen), findsOneWidget,
        reason: 'the wake screen must still be showing after a back gesture');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the explicit dismiss affordances are still presented',
      (tester) async {
    // The lockdown must not remove the legitimate exits: a standard alarm
    // keeps Snooze + slide-to-dismiss visible inside the locked screen.
    await pumpWakeUp(tester);

    expect(find.textContaining('Snooze'), findsOneWidget);
    expect(find.text('Slide to dismiss'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  group('Zombie-UI final piece — external dismissal + lock-screen lease', () {
    const channel = MethodChannel('rostrik/alarm_routing');

    /// Installs a mock native side for the alarm-routing channel: a ledger
    /// holding [pendingIds] and a log recording every method call.
    List<String> mockNativeSide(
      WidgetTester tester, {
      List<String> pendingIds = const [],
    }) {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
          (MethodCall call) async {
        calls.add(call.method);
        switch (call.method) {
          case 'getPendingDismissals':
            return List<Object?>.from(pendingIds);
          case 'clearPendingDismissals':
          case 'relinquishLockScreen':
            return null;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));
      return calls;
    }

    /// Pumps a RINGING WakeUpScreen for shift `s1` with the full provider
    /// set MainLayout (the self-destruct landing, five eager tabs) needs.
    Future<FakeShiftRepository> pumpRingingWakeUp(WidgetTester tester) async {
      final shifts = FakeShiftRepository();
      final now = DateTime.now();
      await shifts.upsert(Shift(
        id: 's1',
        date: now,
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      ));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ShiftRepository>.value(value: shifts),
            Provider<AppAlarmRepository>.value(
                value: FakeAppAlarmRepository()),
            Provider<AlarmScheduler>.value(value: FakeAlarmScheduler()),
            Provider<List<Shift>>.value(value: const []),
            Provider<List<ShiftCycle>>.value(value: const []),
            Provider<List<AppAlarm>>.value(value: const []),
            Provider<AlarmSettings>.value(value: AlarmSettings.defaults),
            ChangeNotifierProvider<AppPreferences>.value(
              value: AppPreferences(Hive.box('settings')),
            ),
          ],
          child: const MaterialApp(
            home: WakeUpScreen(shiftId: 's1', notificationId: 1),
          ),
        ),
      );
      await tester.pump();
      return shifts;
    }

    testWidgets(
        'an external (background-isolate) dismissal in the native ledger '
        'self-destructs the stranded WakeUpScreen within one tick',
        (tester) async {
      // Field bug: panel-Dismiss while the FSI WakeUpScreen was up — the
      // dismissal landed on DISK (other isolate), this isolate's Hive cache
      // never saw it, and the screen kept drawing over the lock screen.
      final calls = mockNativeSide(tester, pendingIds: ['s1']);
      final shifts = await pumpRingingWakeUp(tester);
      expect(find.byType(WakeUpScreen), findsOneWidget);

      // One clock tick → ledger poll → ack + clear + self-destruct.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(WakeUpScreen), findsNothing,
          reason: 'the stranded screen must die without a manual swipe');
      expect(find.byType(MainLayout), findsOneWidget);
      // The dismissal was replayed into THIS isolate's Hive…
      expect((await shifts.getById('s1'))!.isAcknowledged, isTrue);
      // …the ledger was cleared, and the dispose purge relinquished the
      // lock screen.
      expect(calls, contains('clearPendingDismissals'));
      expect(calls, contains('relinquishLockScreen'));
    });

    testWidgets(
        'returning to resumed drains the ledger INSTANTLY — no waiting for '
        'the sleeping ticker', (tester) async {
      // Sleeping-Ticker field bug: the shade suspends the Flutter UI, the
      // 1 Hz poll is asleep, the user taps Dismiss in the shade, and the
      // dead screen lingered until a manual touch. The lifecycle observer
      // must drain the ledger the moment the app is resumed.
      final calls = mockNativeSide(tester, pendingIds: ['s1']);
      final shifts = await pumpRingingWakeUp(tester);
      expect(find.byType(WakeUpScreen), findsOneWidget);

      // Shade comes down: UI suspended. NOTE: no audio action may happen
      // here (the Silence-Bug contract) — the observer only acts on resumed.
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(find.byType(WakeUpScreen), findsOneWidget,
          reason: 'suspension alone must never kill the ringing screen');

      // Shade dismissed → resumed. The ledger drain must complete WITHOUT
      // advancing the fake clock anywhere near the next 1-second tick —
      // two microtask pumps are enough for the channel hop + Hive ack.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();

      expect((await shifts.getById('s1'))!.isAcknowledged, isTrue,
          reason: 'resumed must drain the ledger immediately, not on the '
              'next ticker fire');
      expect(calls, contains('clearPendingDismissals'));

      // The destruct was issued in the same breath — let the route
      // transition animation play out, then the screen must be gone.
      await tester.pumpAndSettle();
      expect(find.byType(WakeUpScreen), findsNothing);
      expect(find.byType(MainLayout), findsOneWidget);
    });

    testWidgets(
        'dispose sends the relinquishLockScreen signal (window-flag purge)',
        (tester) async {
      final calls = mockNativeSide(tester);
      await pumpWakeUp(tester);

      // Tear the screen down by any route — dispose is the single purge
      // point shared by slider, snooze self-destruct, and reactive pop.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(calls, contains('relinquishLockScreen'),
          reason: 'the app must fully relinquish the lock screen on exit');
    });

    testWidgets(
        'a ledger entry for a DIFFERENT shift leaves the ringing screen up',
        (tester) async {
      final calls = mockNativeSide(tester, pendingIds: ['other-shift']);
      final shifts = FakeShiftRepository();
      await tester.pumpWidget(
        MultiProvider(
          providers: [Provider<ShiftRepository>.value(value: shifts)],
          child: const MaterialApp(
            home: WakeUpScreen(shiftId: 's1', notificationId: 1),
          ),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump();

      expect(find.byType(WakeUpScreen), findsOneWidget,
          reason: "another alarm's dismissal must not kill THIS alarm's UI");
      expect(calls, isNot(contains('clearPendingDismissals')),
          reason: 'the ledger must be left for its rightful consumer');

      await tester.pumpWidget(const SizedBox());
    });
  });
}
