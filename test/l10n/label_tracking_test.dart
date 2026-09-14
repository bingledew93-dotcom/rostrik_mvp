import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/l10n/l10n.dart';

void main() {
  // Found on a Pixel: spaced labels split Hindi words into separate letters.
  testWidgets('label letter spacing is dropped for Hindi only', (tester) async {
    final spacing = <String, double>{};
    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (context) {
            spacing[locale.languageCode] = labelTracking(context, 1.2);
            return const SizedBox.shrink();
          }),
        ),
      );
    }

    expect(spacing['hi'], 0);
    spacing.remove('hi');
    expect(spacing.values, everyElement(1.2));
    expect(spacing, hasLength(AppLocalizations.supportedLocales.length - 1));
  });
}
