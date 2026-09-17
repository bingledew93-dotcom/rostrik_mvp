import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/legal/legal.dart';

/// The legal links are the one place in the app where a wrong string is both
/// invisible in every test that renders the screen (the tile still draws) and
/// a compliance problem — Play requires a working privacy policy, and a dead
/// link is a rejection. These pin the shape, not the content.
void main() {
  final urls = {
    'privacy': kPrivacyPolicyUrl,
    'terms': kTermsOfUseUrl,
  };

  test('both legal documents live on the rostrik.com.au domain', () {
    // Moved off Google Sites 2026-09-18. A stray sites.google.com URL here
    // means one of the pair was missed.
    for (final entry in urls.entries) {
      expect(Uri.parse(entry.value).host, 'rostrik.com.au',
          reason: '${entry.key} is not on the app\'s own domain');
    }
  });

  test('both are absolute https URLs with a path', () {
    for (final entry in urls.entries) {
      final uri = Uri.parse(entry.value);
      expect(uri.scheme, 'https', reason: '${entry.key} must be https');
      expect(uri.hasAuthority, isTrue);
      expect(uri.path, isNot(anyOf('', '/')),
          reason: '${entry.key} must point at a page, not the site root');
    }
  });

  test('the two documents are different pages', () {
    expect(kPrivacyPolicyUrl, isNot(kTermsOfUseUrl));
  });

  test('the legal version is a plain ISO date', () {
    // Bumping it re-gates every existing user, so it is worth failing loudly
    // on a malformed value rather than silently never matching.
    expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(kCurrentLegalVersion), isTrue,
        reason: 'kCurrentLegalVersion must be YYYY-MM-DD');
    expect(DateTime.tryParse(kCurrentLegalVersion), isNotNull);
  });
}
