import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/state/app_preferences.dart';
import 'package:rostrik_mvp/ui/sleep/sleep_screen.dart';

/// Widget tests for the (now unlocked) Sleep tab. The sound grid degrades
/// gracefully without a `SleepSoundController` provider — tiles render, taps
/// no-op — so these pump only the roster + preference providers.
void main() {
  late Directory tempDir;
  late Box box;
  late AppPreferences prefs;
  var boxCounter = 0;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('rostrik_sleep_test_');
    Hive.init(tempDir.path);
  });

  // Open the Hive box + build AppPreferences in setUp (OUTSIDE the tester zone):
  // awaiting a box open inside testWidgets would deadlock under the fake clock.
  setUp(() async {
    box = await Hive.openBox('sleep_settings_${boxCounter++}');
    prefs = AppPreferences(box);
  });

  tearDown(() async {
    prefs.dispose();
    await box.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<void> pumpSleep(WidgetTester tester) async {
    // Tall viewport so the whole (scrolling) Sleep tab lays out — the sound grid
    // sits below a normal 600px test fold and the lazy ListView wouldn't build it.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<List<Shift>>.value(value: const []),
          Provider<List<AppAlarm>>.value(value: const []),
          Provider<AlarmSettings>.value(value: AlarmSettings.defaults),
          ChangeNotifierProvider<AppPreferences>.value(value: prefs),
        ],
        child: const MaterialApp(home: SleepScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('the reminder toggles are enabled (no longer beta-locked)',
      (tester) async {
    await pumpSleep(tester);
    final bedtime = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('sleep-bedtime-reminder-toggle')),
    );
    final windDown = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('sleep-winddown-reminder-toggle')),
    );
    expect(bedtime.onChanged, isNotNull);
    expect(windDown.onChanged, isNotNull);
    // The beta banner is gone.
    expect(find.byKey(const ValueKey('sleep-beta-banner')), findsNothing);
  });

  testWidgets('renders the six sleep sounds and the target/timer chips',
      (tester) async {
    await pumpSleep(tester);
    for (final resource in const [
      'sleep_white_noise',
      'sleep_pink_noise',
      'sleep_brown_noise',
      'sleep_fan',
      'sleep_ocean',
      'sleep_rain',
    ]) {
      expect(find.byKey(ValueKey('sleep-sound-$resource')), findsOneWidget);
    }
    // Target-hours + auto-stop-timer chips present.
    expect(find.byKey(const ValueKey('sleep-goal-8')), findsOneWidget);
    expect(find.byKey(const ValueKey('sleep-timer-30')), findsOneWidget);
    expect(find.byKey(const ValueKey('sleep-timer-0')), findsOneWidget); // Off
  });

  testWidgets('tapping a sleep-target chip persists the goal', (tester) async {
    await pumpSleep(tester);
    expect(prefs.sleepGoalHours, 8); // default

    await tester.runAsync(
      () => tester.tap(find.byKey(const ValueKey('sleep-goal-7'))),
    );
    await tester.pump();

    expect(prefs.sleepGoalHours, 7);
  });

  testWidgets('toggling the bedtime reminder persists the preference',
      (tester) async {
    await pumpSleep(tester);
    expect(prefs.bedtimeReminderEnabled, isFalse);

    await tester.runAsync(
      () => tester.tap(find.byKey(const ValueKey('sleep-bedtime-reminder-toggle'))),
    );
    await tester.pump();

    expect(prefs.bedtimeReminderEnabled, isTrue);
  });
}
