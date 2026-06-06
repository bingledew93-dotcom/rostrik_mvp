import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/ui/critical_dismiss_controls.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  group('HoldToDismiss', () {
    testWidgets('holding for the full duration dismisses', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(host(HoldToDismiss(
        duration: const Duration(seconds: 3),
        onDismissed: () async => dismissed = true,
      )));

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(HoldToDismiss)));
      // First pump starts the controller's ticker (baseline, ~0 elapsed); the
      // second advances past the hold duration while the pointer stays down.
      await tester.pump();
      await tester.pump(const Duration(seconds: 3, milliseconds: 100));
      expect(dismissed, isTrue);
      await gesture.up();
    });

    testWidgets('releasing early does NOT dismiss', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(host(HoldToDismiss(
        duration: const Duration(seconds: 3),
        onDismissed: () async => dismissed = true,
      )));

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(HoldToDismiss)));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up(); // released after only 1s
      await tester.pump(const Duration(seconds: 3));
      expect(dismissed, isFalse);
    });
  });

  group('ShakeToDismiss', () {
    testWidgets('a sustained shake stream dismisses', (tester) async {
      final magnitudes = StreamController<double>();
      addTearDown(magnitudes.close);
      var now = DateTime(2026, 6, 1, 4, 0, 0);
      var dismissed = false;

      await tester.pumpWidget(host(ShakeToDismiss(
        magnitudeStream: magnitudes.stream,
        clock: () => now,
        onDismissed: () async => dismissed = true,
      )));

      // Feed above-threshold samples, advancing the injected clock past the
      // 3-second shake-hold duration.
      for (var ms = 0; ms <= 3100; ms += 100) {
        now = DateTime(2026, 6, 1, 4, 0, 0).add(Duration(milliseconds: ms));
        magnitudes.add(20);
        await tester.pump();
      }
      expect(dismissed, isTrue);
    });

    testWidgets('a single spike does NOT dismiss', (tester) async {
      final magnitudes = StreamController<double>();
      addTearDown(magnitudes.close);
      var now = DateTime(2026, 6, 1, 4, 0, 0);
      var dismissed = false;

      await tester.pumpWidget(host(ShakeToDismiss(
        magnitudeStream: magnitudes.stream,
        clock: () => now,
        onDismissed: () async => dismissed = true,
      )));

      magnitudes.add(30); // one spike
      await tester.pump();
      now = DateTime(2026, 6, 1, 4, 0, 4); // 4s later, still
      magnitudes.add(0);
      await tester.pump();
      expect(dismissed, isFalse);
    });
  });
}
