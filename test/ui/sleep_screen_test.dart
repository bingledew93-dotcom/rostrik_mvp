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

void main() {
  late Directory tempDir;
  late Box box;
  late AppPreferences prefs;
  var boxCounter = 0;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('rostrik_sleep_test_');
    Hive.init(tempDir.path);
  });

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

  testWidgets('shows the beta-limitation banner at the top', (tester) async {
    await pumpSleep(tester);
    expect(find.byKey(const ValueKey('sleep-beta-banner')), findsOneWidget);
    expect(find.text('Beta Limitation'), findsOneWidget);
    expect(
      find.textContaining('under construction for Phase 2'),
      findsOneWidget,
    );
  });

  testWidgets('the reminder toggles are disabled', (tester) async {
    await pumpSleep(tester);
    final bedtime = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('sleep-bedtime-reminder-toggle')),
    );
    final windDown = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('sleep-winddown-reminder-toggle')),
    );
    // onChanged:null == disabled — the gated controls can't be flipped.
    expect(bedtime.onChanged, isNull);
    expect(windDown.onChanged, isNull);
  });

  testWidgets('tapping a locked control surfaces the coming-soon snackbar',
      (tester) async {
    await pumpSleep(tester);

    // The _LockedControl overlay sits over the disabled toggle; a tap on it
    // routes to the snackbar rather than doing nothing.
    await tester.tap(
      find.byKey(const ValueKey('sleep-bedtime-reminder-toggle')),
      warnIfMissed: false,
    );
    await tester.pump(); // start the snackbar animation
    await tester.pump(const Duration(milliseconds: 750));

    expect(
      find.text('Coming soon! We are perfecting the alarm engine first.'),
      findsOneWidget,
    );
  });
}
