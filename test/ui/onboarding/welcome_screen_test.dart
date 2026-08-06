import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/state/app_preferences.dart';
import 'package:rostrik_mvp/ui/onboarding/welcome_screen.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late AppPreferences prefs;
  var boxCounter = 0;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('rostrik_welcome_test_');
    Hive.init(tempDir.path);
  });

  // Open the Hive box + build AppPreferences in setUp (OUTSIDE the widget
  // tester zone). Opening a box with `await` inside testWidgets would deadlock:
  // real file I/O isn't pumped under the tester's controlled clock.
  setUp(() async {
    box = await Hive.openBox('welcome_settings_${boxCounter++}');
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

  /// Pumps the Welcome screen over the real [AppPreferences] (built in setUp)
  /// so the instant-save toggles can be asserted end to end. pump (not
  /// pumpAndSettle): the bundled hero Image.asset keeps an image stream pending
  /// in the headless test — the copy, keys and toggles all render on the first
  /// frame, which is all we assert.
  Future<void> pumpWelcome(
    WidgetTester tester, {
    VoidCallback? onContinue,
    VoidCallback? onSkip,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppPreferences>.value(
        value: prefs,
        child: MaterialApp(
          home: WelcomeScreen(
            onContinue: onContinue ?? () {},
            onSkip: onSkip ?? () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the new value-prop copy', (tester) async {
    await pumpWelcome(tester);
    expect(
      find.text('The smart alarm clock built for shift workers.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('follow your rotating roster'),
      findsOneWidget,
    );
  });

  testWidgets('discloses the 14-day free trial up front', (tester) async {
    await pumpWelcome(tester);
    expect(
      find.byKey(const ValueKey('welcome-trial-callout')),
      findsOneWidget,
    );
    expect(find.text('14-day free trial'), findsOneWidget);
    // Honest framing: one-time purchase, not a subscription.
    expect(find.textContaining('never a subscription'), findsOneWidget);
  });

  testWidgets('shows Get Started and a Skip / Set up later exit',
      (tester) async {
    var started = false;
    var skipped = false;
    await pumpWelcome(
      tester,
      onContinue: () => started = true,
      onSkip: () => skipped = true,
    );

    expect(find.byKey(const ValueKey('welcome-get-started')), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-skip-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('welcome-skip-button')));
    expect(skipped, isTrue);
    expect(started, isFalse);

    await tester.tap(find.byKey(const ValueKey('welcome-get-started')));
    expect(started, isTrue);
  });

  testWidgets('Quick Preferences render with the persisted defaults',
      (tester) async {
    await pumpWelcome(tester); // defaults: 12h, week starts Monday
    expect(
      find.byKey(const ValueKey('welcome-pref-timeformat')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('welcome-pref-weekstart')),
      findsOneWidget,
    );
  });

  testWidgets('toggling the clock format instantly saves 24h', (tester) async {
    await pumpWelcome(tester);
    expect(prefs.use24HourTime, isFalse);

    // runAsync so the toggle's real Hive write completes (and doesn't leave a
    // pending I/O future that stalls the tester).
    await tester.runAsync(() => tester.tap(find.text('24h')));
    await tester.pump();

    expect(prefs.use24HourTime, isTrue);
  });

  testWidgets('toggling the week start instantly saves Sunday', (tester) async {
    await pumpWelcome(tester);
    expect(prefs.startWeekOnMonday, isTrue);

    await tester.runAsync(() => tester.tap(find.text('Sun')));
    await tester.pump();

    expect(prefs.startWeekOnMonday, isFalse);
  });
}
