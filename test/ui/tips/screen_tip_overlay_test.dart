import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/ui/tips/screen_tip.dart';
import 'package:rostrik_mvp/ui/tips/screen_tip_overlay.dart';

void main() {
  const tip = ScreenTip(
    tipKey: 'demo',
    icon: Icons.home,
    title: 'Demo screen',
    body: 'This is what the screen does.',
  );

  Future<void> pump(
    WidgetTester tester, {
    required VoidCallback onDismiss,
    required VoidCallback onDisable,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const SizedBox.expand(),
              ScreenTipOverlay(
                tip: tip,
                onDismiss: onDismiss,
                onDisable: onDisable,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the tip title and body', (tester) async {
    await pump(tester, onDismiss: () {}, onDisable: () {});
    expect(find.byKey(const ValueKey('screen-tip-title')), findsOneWidget);
    expect(find.text('Demo screen'), findsOneWidget);
    expect(find.text('This is what the screen does.'), findsOneWidget);
  });

  testWidgets('Got it fires onDismiss', (tester) async {
    var dismissed = 0;
    await pump(tester, onDismiss: () => dismissed++, onDisable: () {});
    await tester.tap(find.byKey(const ValueKey('screen-tip-got-it')));
    await tester.pump();
    expect(dismissed, 1);
  });

  testWidgets('tapping the scrim fires onDismiss', (tester) async {
    var dismissed = 0;
    await pump(tester, onDismiss: () => dismissed++, onDisable: () {});
    // The scrim fills the screen; its centre is above the bottom-anchored card.
    await tester.tapAt(const Offset(200, 120));
    await tester.pump();
    expect(dismissed, 1);
  });

  testWidgets("Don't show tips fires onDisable", (tester) async {
    var disabled = 0;
    await pump(tester, onDismiss: () {}, onDisable: () => disabled++);
    await tester.tap(find.byKey(const ValueKey('screen-tip-disable')));
    await tester.pump();
    expect(disabled, 1);
  });
}
