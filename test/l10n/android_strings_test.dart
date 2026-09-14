import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Native Android strings (alarm screen, notification buttons and channels,
/// widget) live outside the ARB catalogues, so nothing else notices a language
/// missing one: Android silently falls back to English for that string.
void main() {
  const res = 'android/app/src/main/res';
  final nameRe = RegExp(r'<string name="([a-z0-9_]+)"[^>]*>(.*?)</string>', dotAll: true);
  final argRe = RegExp(r'%\d+\$[ds]');

  Map<String, String> read(String dir) => {
        for (final m in nameRe.allMatches(File('$res/$dir/strings.xml').readAsStringSync()))
          m.group(1)!: m.group(2)!,
      };

  final english = read('values');
  final languages = Directory(res)
      .listSync()
      .whereType<Directory>()
      .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
      .where((name) => RegExp(r'^values-[a-z]{2}$').hasMatch(name))
      .toList()
    ..sort();

  test('all 14 translated languages have a strings file', () {
    expect(languages, hasLength(14));
  });

  for (final dir in languages) {
    test('[$dir] has exactly the English strings, with the same arguments', () {
      final strings = read(dir);
      expect(strings.keys.toSet(), english.keys.toSet());
      for (final key in english.keys) {
        List<String> args(String s) => argRe.allMatches(s).map((m) => m.group(0)!).toList()..sort();
        expect(args(strings[key]!), args(english[key]!), reason: key);
        // aapt rejects a bare apostrophe; it must be written \'.
        expect(RegExp(r"(?<!\\)'").hasMatch(strings[key]!), isFalse, reason: key);
      }
    });
  }
}
