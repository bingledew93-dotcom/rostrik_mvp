import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rostrik_mvp/legal/legal.dart';
import 'package:rostrik_mvp/ui/legal_consent_screen.dart';

void main() {
  setUp(() {
    // Fresh, empty prefs each test (no version accepted yet).
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpConsent(
    WidgetTester tester, {
    required VoidCallback onAccepted,
  }) async {
    await tester.pumpWidget(
      MaterialApp(home: LegalConsentScreen(onAccepted: onAccepted)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the heading, an UNticked checkbox, and a disabled CTA',
      (tester) async {
    await pumpConsent(tester, onAccepted: () {});

    expect(find.text('Before you rely on Rostrik'), findsOneWidget);

    final checkbox = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('legal-consent-checkbox')),
    );
    expect(checkbox.value, isFalse);

    // CTA is disabled until the box is ticked — the gate can't be skipped.
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('legal-consent-agree')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('ticking enables Agree; agreeing persists the version + calls back',
      (tester) async {
    var accepted = false;
    await pumpConsent(tester, onAccepted: () => accepted = true);

    await tester.tap(find.byKey(const ValueKey('legal-consent-checkbox')));
    await tester.pump();

    final enabled = tester.widget<FilledButton>(
      find.byKey(const ValueKey('legal-consent-agree')),
    );
    expect(enabled.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('legal-consent-agree')));
    await tester.pumpAndSettle();

    // onAccepted advanced the gate, and the consent is recorded for the router.
    expect(accepted, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kAcceptedLegalVersionKey), '2026-06-15');
    expect(prefs.getString(kAcceptedLegalAtKey), isNotNull);
  });
}
