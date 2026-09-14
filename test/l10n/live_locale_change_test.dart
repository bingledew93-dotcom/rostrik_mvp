import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:rostrik_mvp/l10n/l10n.dart';
import 'package:rostrik_mvp/ui/shift_format.dart';

/// Formats through the context-free helpers only, so nothing ties it to
/// Localizations — the shape of every shared formatter in shift_format.dart.
class _ContextFreeLabel extends StatelessWidget {
  const _ContextFreeLabel();

  @override
  Widget build(BuildContext context) =>
      Text('${formatShiftDate(DateTime(2026, 9, 23))}|${formatWeekdays(0)}');
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => setState(() => taps++),
        child: Text('taps $taps'),
      );
}

void main() {
  tearDown(() => Intl.defaultLocale = null);

  Future<void> pumpIn(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: syncL10nFromContext,
        // const: an ancestor rebuild alone would never reach these.
        home: const Scaffold(
          body: Column(children: [_ContextFreeLabel(), _Counter()]),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Found on a Pixel: switching Rostrik's language while it was open left
  // text formatted outside Localizations in the previous language.
  testWidgets('context-free text follows a live language change', (tester) async {
    String expected(String locale) =>
        '${DateFormat.MMMEd(locale).format(DateTime(2026, 9, 23))}|'
        '${lookupAppLocalizations(Locale(locale)).weekdaysNone}';

    await pumpIn(tester, const Locale('de'));
    expect(find.text(expected('de')), findsOneWidget);

    await pumpIn(tester, const Locale('ar'));
    expect(find.text(expected('ar')), findsOneWidget);
  });

  testWidgets('a language change keeps widget state', (tester) async {
    await pumpIn(tester, const Locale('de'));
    await tester.tap(find.text('taps 0'));
    await tester.pump();

    await pumpIn(tester, const Locale('ja'));
    expect(find.text('taps 1'), findsOneWidget);
  });
}
