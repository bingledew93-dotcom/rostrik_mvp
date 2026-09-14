import 'dart:ui';

import 'package:flutter/widgets.dart';

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
