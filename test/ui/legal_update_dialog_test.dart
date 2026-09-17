import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/l10n/l10n.dart';
import 'package:rostrik_mvp/legal/legal.dart';
import 'package:rostrik_mvp/ui/legal_update_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The update notice is a HARD gate that merely looks soft. These pin the two
/// halves of that: it cannot be escaped without accepting, and accepting
/// writes the same record the full consent screen writes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<int> pumpDialog(WidgetTester tester) async {
    var accepted = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () =>
                LegalUpdateDialog.show(context, onAccepted: () => accepted++),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return accepted;
  }

  testWidgets('accepting records the current version and the instant',
      (tester) async {
    await pumpDialog(tester);
    expect(find.byKey(const ValueKey('legal-update-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('legal-update-accept')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kAcceptedLegalVersionKey), kCurrentLegalVersion);
    // Same pair of keys the full consent screen writes — one source of truth
    // for "what has this user accepted, and when".
    expect(
      DateTime.tryParse(prefs.getString(kAcceptedLegalAtKey) ?? ''),
      isNotNull,
    );
    expect(find.byKey(const ValueKey('legal-update-dialog')), findsNothing);
  });

  testWidgets('tapping outside does not dismiss it', (tester) async {
    await pumpDialog(tester);
    // Top-left corner: the barrier, well clear of the dialog itself.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('legal-update-dialog')), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kAcceptedLegalVersionKey), isNull,
        reason: 'nothing may be recorded without an explicit accept');
  });

  testWidgets('the back gesture does not dismiss it', (tester) async {
    await pumpDialog(tester);
    final popped =
        await tester.binding.handlePopRoute().then((_) => true).catchError(
              (_) => true,
            );
    await tester.pumpAndSettle();
    expect(popped, isTrue);
    expect(find.byKey(const ValueKey('legal-update-dialog')), findsOneWidget,
        reason: 'PopScope(canPop: false) must hold the gate shut');
  });

  testWidgets('both documents are offered for review', (tester) async {
    await pumpDialog(tester);
    expect(find.byKey(const ValueKey('legal-update-privacy')), findsOneWidget);
    expect(find.byKey(const ValueKey('legal-update-terms')), findsOneWidget);
  });

  testWidgets('it says what happened, in the user\'s language',
      (tester) async {
    await pumpDialog(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.legalUpdatedTitle), findsOneWidget);
    expect(find.text(l10n.legalUpdatedAccept), findsOneWidget);
  });

  testWidgets('renders in every supported language without overflowing',
      (tester) async {
    for (final locale in AppLocalizations.supportedLocales) {
      var accepted = 0;
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () =>
                  LegalUpdateDialog.show(context, onAccepted: () => accepted++),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('legal-update-dialog')), findsOneWidget,
          reason: 'failed for ${locale.languageCode}');
      expect(tester.takeException(), isNull,
          reason: 'overflow in ${locale.languageCode}');
      await tester.tap(find.byKey(const ValueKey('legal-update-accept')));
      await tester.pumpAndSettle();
    }
  });
}
