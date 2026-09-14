import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/l10n/l10n.dart';

/// Guards the translation catalogues themselves.
///
/// gen-l10n silently falls back to English for any key a locale is missing, so
/// a string added to app_en.arb and forgotten elsewhere would ship as English
/// inside an otherwise translated screen — and no build step would complain.
/// These tests make that a failure instead.
void main() {
  final dir = Directory('lib/l10n');
  final template = _messages(File('${dir.path}/app_en.arb'));
  final locales = dir
      .listSync()
      .whereType<File>()
      .map((f) => RegExp(r'app_(\w+)\.arb$').firstMatch(f.path)?.group(1))
      .whereType<String>()
      .where((l) => l != 'en')
      .toList()
    ..sort();

  test('every shipped language has a catalogue', () {
    expect(locales, hasLength(AppLocalizations.supportedLocales.length - 1));
  });

  for (final locale in locales) {
    test('[$locale] has exactly the English keys, with the same placeholders',
        () {
      final messages = _messages(File('${dir.path}/app_$locale.arb'));
      expect(
        messages.keys.toSet().difference(template.keys.toSet()),
        isEmpty,
        reason: 'keys that no longer exist in English',
      );
      expect(
        template.keys.toSet().difference(messages.keys.toSet()),
        isEmpty,
        reason: 'untranslated keys (they would render in English)',
      );
      for (final key in template.keys) {
        expect(
          _placeholders(messages[key]!),
          _placeholders(template[key]!),
          reason: '$key: a renamed or dropped placeholder',
        );
      }
    });
  }

  test('plural messages render a count in every language', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      for (final n in [0, 1, 2, 3, 5, 11, 21, 100]) {
        final rendered = [
          l10n.settingsTrialDaysLeft(n),
          l10n.commonMinutes(n),
          l10n.heroOffInDays(n),
          l10n.markLeaveApplyTo(n),
          l10n.patternBlockNights(n),
          l10n.builderDaysCount(n),
        ];
        for (final text in rendered) {
          expect(text.trim(), isNotEmpty, reason: '[$locale] n=$n');
          expect(text, isNot(contains('{')), reason: '[$locale] n=$n: $text');
        }
        // Where the number appears as digits it must be the right number —
        // a plural case wired to the wrong variable would print a stale value.
        if (n > 2) {
          expect(l10n.builderDaysCount(n), contains('$n'),
              reason: '[$locale] builderDaysCount($n)');
        }
      }
    }
  });

  test('device-locale resolution falls back to English for unsupported languages',
      () {
    final resolved = basicLocaleListResolution(
      const [Locale('sw')],
      AppLocalizations.supportedLocales,
    );
    expect(resolved.languageCode, 'en');
  });
}

Map<String, String> _messages(File f) {
  final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final e in json.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };
}

/// Placeholder names used anywhere in an ICU message — `{name}` and the
/// `{name, plural, …}` head — ignoring the plural case selectors themselves.
Set<String> _placeholders(String message) => RegExp(r'\{\s*(\w+)\s*[,}]')
    .allMatches(message)
    .map((m) => m.group(1)!)
    .where((name) =>
        !const {'zero', 'one', 'two', 'few', 'many', 'other'}.contains(name))
    .toSet();
