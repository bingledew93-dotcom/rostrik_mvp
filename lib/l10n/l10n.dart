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

AppLocalizations? _fromWidgetTree;

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
Widget syncL10nFromContext(BuildContext context, Widget? child) {
  _fromWidgetTree = AppLocalizations.of(context);
  Intl.defaultLocale = Localizations.localeOf(context).toString();
  return child ?? const SizedBox.shrink();
}
