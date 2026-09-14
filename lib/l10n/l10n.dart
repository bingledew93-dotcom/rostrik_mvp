import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// The one way UI code reads localized strings: `context.l10n.someKey`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localizations for code with NO BuildContext — notification/reminder text
/// composed in services and in the headless background-sync isolate.
///
/// Resolves the device's preferred locales against the app's supported set
/// with the same algorithm MaterialApp uses, so a notification body always
/// matches the language the UI is showing. Falls back to English when the
/// device speaks none of our languages.
///
/// Strings baked into ALREADY-SCHEDULED notifications keep the language they
/// were scheduled in until the next reconcile re-arms them — the alarm sync's
/// content signature includes title/body, so a device-language change heals
/// itself on the next sync pass.
AppLocalizations resolveL10n() {
  final locale = basicLocaleListResolution(
    PlatformDispatcher.instance.locales,
    AppLocalizations.supportedLocales,
  );
  return lookupAppLocalizations(locale);
}

/// Every number Rostrik writes itself — clock times, countdowns, counts — uses
/// Western digits. intl would print Arabic dates in Arabic-Indic digits, mixing
/// both systems in one line ("٢٣ سبتمبر الساعة 04:23"), so dates follow the
/// rest of the app. Call before `runApp`: Material's localizations create their
/// DateFormats when they load and read this setting at that moment.
void useWesternDigitsInDates() {
  DateFormat.useNativeDigitsByDefaultFor('ar', false);
}

/// Decorative letter spacing for small overline-style labels. Devanagari joins
/// the letters of a word with a headline stroke that letter spacing cuts into
/// pieces ("अगला अलार्म" read as separate letters on a Pixel), so Hindi gets
/// none. Arabic needs no exception: the text engine never spaces a joined run.
double labelTracking(BuildContext context, double spacing) =>
    Localizations.localeOf(context).languageCode == 'hi' ? 0 : spacing;

AppLocalizations? _fromWidgetTree;
Locale? _treeLocale;

/// The l10n bundle for code that composes strings OUTSIDE a widget build —
/// the shared formatters in `shift_format.dart` in particular, whose
/// signatures predate i18n and are called from dozens of sites without a
/// BuildContext. Tracks the widget tree's resolved locale once the app is up
/// (see [syncL10nFromContext]); before that — services at startup, pure Dart
/// tests — it falls back to device-locale resolution.
AppLocalizations get currentL10n => _fromWidgetTree ?? resolveL10n();

/// MaterialApp `builder` hook: keeps [currentL10n] and `Intl.defaultLocale`
/// (which drives every bare `DateFormat`) in lock-step with the locale the
/// widget tree actually resolved. Date symbols for that locale are loaded by
/// GlobalMaterialLocalizations before this runs, so bare DateFormat use is
/// safe anywhere below.
///
/// On a language change while the app is open, every widget below is rebuilt
/// once. Widgets that format through [currentL10n] or a bare DateFormat do not
/// depend on Localizations, so otherwise they kept the old language until
/// something else happened to rebuild them (seen on a Pixel: the calendar's
/// month and weekdays stayed German after switching to Arabic). Marking
/// elements dirty keeps all State, unlike re-keying the tree.
Widget syncL10nFromContext(BuildContext context, Widget? child) {
  final locale = Localizations.localeOf(context);
  _fromWidgetTree = AppLocalizations.of(context);
  Intl.defaultLocale = locale.toString();
  if (_treeLocale != null && _treeLocale != locale) {
    final element = context as Element;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (element.mounted) element.visitChildren(_rebuildSubtree);
    });
  }
  _treeLocale = locale;
  return child ?? const SizedBox.shrink();
}

void _rebuildSubtree(Element element) {
  element.markNeedsBuild();
  element.visitChildren(_rebuildSubtree);
}
