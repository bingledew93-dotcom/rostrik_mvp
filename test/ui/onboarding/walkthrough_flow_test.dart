import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_capabilities.dart';
import 'package:rostrik_mvp/ui/critical_dismiss_controls.dart';
import 'package:rostrik_mvp/ui/onboarding/walkthrough_flow.dart';

void main() {
  late StreamController<double> shake;
  late DateTime clockNow;
  var finished = 0;

  setUp(() {
    shake = StreamController<double>.broadcast();
    clockNow = DateTime(2030, 1, 1, 8, 0, 0);
    finished = 0;
  });

  tearDown(() {
    shake.close();
    AlarmCapabilities.debugOverride = null;
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: WalkthroughFlow(
          onFinish: () => finished++,
          shakeMagnitudeStream: shake.stream,
          shakeClock: () => clockNow,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('walkthrough-next')));
    await tester.pumpAndSettle();
  }

  // Where the gesture cannot dismiss an alarm, the lesson must not be taught.
  // Teaching a gesture that will never work is the most damaging form of a
  // control that does nothing, because it arrives as instruction.
  testWidgets('drops the shake lesson where the gesture does nothing',
      (tester) async {
    AlarmCapabilities.debugOverride = AlarmCapabilities.iosNotification;
    await pump(tester);

    // The intro previews the lessons, so it must not advertise the shake one.
    expect(find.text('A 60-second tour'), findsOneWidget);
    expect(find.text('Shake to dismiss'), findsNothing);
    await tapNext(tester);
    expect(find.text('Paint your roster'), findsOneWidget);

    // Straight to the final page — no shake lesson in between.
    await tapNext(tester);
    expect(find.byType(ShakeToDismiss), findsNothing);
    expect(find.text('You\u2019re all set'), findsOneWidget);
    expect(find.byKey(const ValueKey('walkthrough-done')), findsOneWidget);
  });

  testWidgets('opens on the intro and Next advances through the pages',
      (tester) async {
    await pump(tester);
    expect(find.text('A 60-second tour'), findsOneWidget);

    await tapNext(tester);
    expect(find.text('Paint your roster'), findsOneWidget);

    await tapNext(tester);
    // The page title AND the ShakeToDismiss widget both read "Shake to
    // dismiss" — assert the widget to disambiguate.
    expect(find.byType(ShakeToDismiss), findsOneWidget);

    await tapNext(tester);
    // Last page → the primary button is Done.
    expect(find.byKey(const ValueKey('walkthrough-done')), findsOneWidget);
  });

  testWidgets('Skip fires onFinish immediately', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('walkthrough-skip')));
    await tester.pump();
    expect(finished, 1);
  });

  testWidgets('the practice grid paints days and updates the feedback',
      (tester) async {
    await pump(tester);
    await tapNext(tester); // → painter page

    // Before painting, the prompt asks the user to tap a day.
    final before = tester.widget<Text>(
      find.byKey(const ValueKey('practice-feedback')),
    );
    expect(before.data, contains('Tap a day'));

    await tester.tap(find.byKey(const ValueKey('practice-day-0')));
    await tester.tap(find.byKey(const ValueKey('practice-day-1')));
    await tester.pump();

    final after = tester.widget<Text>(
      find.byKey(const ValueKey('practice-feedback')),
    );
    expect(after.data, contains('2 days'));
    expect(after.data, contains('Day block'));
  });

  testWidgets('a sustained shake completes the lesson', (tester) async {
    await pump(tester);
    await tapNext(tester); // painter
    await tapNext(tester); // shake

    expect(find.byType(ShakeToDismiss), findsOneWidget);
    expect(find.byKey(const ValueKey('shake-success')), findsNothing);

    // Feed above-threshold samples closer together than the detector's grace
    // window (350 ms), spanning the full 3-second sustain requirement.
    for (var ms = 0; ms <= 3300; ms += 300) {
      clockNow = DateTime(2030, 1, 1, 8, 0, 0).add(Duration(milliseconds: ms));
      shake.add(20.0);
      await tester.pump();
    }
    await tester.pump();

    expect(find.byKey(const ValueKey('shake-success')), findsOneWidget);
    expect(find.text('You’ve got it!'), findsOneWidget);
  });

  testWidgets('Done on the final page fires onFinish', (tester) async {
    await pump(tester);
    await tapNext(tester);
    await tapNext(tester);
    await tapNext(tester);
    await tester.tap(find.byKey(const ValueKey('walkthrough-done')));
    await tester.pump();
    expect(finished, 1);
  });
}
