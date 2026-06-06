/// Normalises the raw, noisy text Google ML Kit reads off a roster photo into
/// clean, parser-ready lines BEFORE `OcrScannerService.parseTextLines` / the
/// [OcrTimeParser] tiers ever see it.
///
/// **Pure Dart by design** — like [OcrTimeParser] this imports nothing (no ML
/// Kit, no Flutter), so the whole gauntlet unit-tests on the Dart VM with zero
/// platform channels.
///
/// ## Philosophy: normalise loudly, delete quietly
///
/// The worst failure for a shift worker is a *dropped* shift — it silently
/// becomes a missed alarm and a missed shift. A *phantom* shift is far cheaper:
/// it shows up on a confirmation card and the user removes it with one tap. So
/// this layer is deliberately asymmetric:
///
///   * It does a LOT of safe **normalisation** — folding unicode spaces, dashes
///     and zero-width junk, squashing whitespace, and rejoining a range ML Kit
///     wrapped onto two lines — so text that *should* parse isn't blocked by
///     cosmetic noise.
///   * It **deletes almost nothing**. The only lines it drops are ones that
///     cannot possibly encode a shift: blank lines and pure-symbol rules such
///     as `-----` or `| | |`. Everything else passes through to the parser,
///     which already returns null for anything that isn't a time or a shift
///     letter, and finally to the human review step.
///
/// ### What it deliberately does NOT do
/// It does not try to "find the grid" by heuristics, and it does not strip
/// suspicious-looking content — a status-bar clock (`9:41`), a `Week 12`
/// header, a workshop name. Guessing wrong there means deleting a real shift.
/// Those tokens fall through to the parser and the confirmation UI, where a
/// stray cell is a tap to delete. (If we ever want to suppress a status-bar
/// time, the safe home for that is a *confidence* hint on the review card —
/// "a lone time on the first line, far from any other shift" — never a silent
/// deletion in this layer.)
///
/// The exotic-character matchers are built from integer CODE POINTS via
/// [String.fromCharCodes] on purpose: pasting the literal zero-width / control
/// glyphs into source would be invisible to a reviewer and easy to corrupt,
/// so not a single one appears here as a literal.
class OcrTextSanitizer {
  OcrTextSanitizer._();

  // Zero-width / BOM characters ML Kit occasionally interleaves: pure noise,
  // and they can split an otherwise-valid token (`06<zwsp>00`).
  // ZWSP, ZWNJ, ZWJ, word joiner, BOM.
  static const List<int> _zeroWidthCp = [0x200B, 0x200C, 0x200D, 0x2060, 0xFEFF];

  // The unicode dash family, folded to ASCII '-'. Critically this includes the
  // MINUS SIGN U+2212, which OcrTimeParser's range separator does NOT accept —
  // without folding it, `0600<minus>1800` loses its end and collapses to a lone
  // start. U+2010..U+2015 hyphen..horizontal-bar, U+2212 minus, U+FE58/U+FE63
  // small & fullwidth-form hyphens, U+FF0D fullwidth hyphen-minus.
  static const List<int> _dashCp = [
    0x2010, 0x2011, 0x2012, 0x2013, 0x2014, 0x2015,
    0x2212,
    0xFE58, 0xFE63, 0xFF0D,
  ];

  // Non-newline unicode whitespace, folded to a plain ASCII space. Deliberately
  // omits \n so the row/cell line structure survives. Tab, NBSP, the U+2000..
  // U+200A en/em/thin/hair-space block, narrow NBSP, medium math space, and the
  // ideographic space.
  static const List<int> _spaceCp = [
    0x09, 0xA0, 0x1680,
    0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005,
    0x2006, 0x2007, 0x2008, 0x2009, 0x200A,
    0x202F, 0x205F, 0x3000,
  ];

  static String _classOf(List<int> codePoints) =>
      '[${String.fromCharCodes(codePoints)}]';

  static final RegExp _zeroWidth = RegExp(_classOf(_zeroWidthCp));
  static final RegExp _dashes = RegExp(_classOf(_dashCp));
  static final RegExp _spaces = RegExp(_classOf(_spaceCp));

  // Control / non-printable chars that can linger inside a line (newlines were
  // already consumed by the split): the C0 range U+0000..U+001F plus U+007F DEL.
  // Built as a range so the whole block is covered without listing 32 ints.
  static final RegExp _controls = RegExp(
    '[${String.fromCharCode(0)}-${String.fromCharCode(0x1F)}'
    '${String.fromCharCode(0x7F)}]',
  );

  // Runs of ASCII spaces to squash to one (after the mappings above).
  static final RegExp _multiSpace = RegExp(r' {2,}');

  // A line with no letter and no digit — a table rule, a row of separators,
  // stray punctuation. Cannot encode a shift, so it is safe to drop.
  static final RegExp _hasAlnum = RegExp(r'[a-z0-9]', caseSensitive: false);

  // A trailing range separator marks a range ML Kit wrapped onto the next line
  // (`0600-` then `1800`). Mirrors the hyphen/tilde/slash family OcrTimeParser
  // splits on (the unicode dashes above are already folded to '-' by now).
  static final RegExp _trailingSep = RegExp(r'[-~/]$');

  // The continuation of a wrapped range must start with a digit (its end time).
  static final RegExp _startsDigit = RegExp(r'^\d');

  /// Normalises [raw] into a clean, `\n`-joined string ready for the line
  /// walk. Returns `''` for empty / whitespace-only input.
  static String sanitize(String raw) {
    if (raw.isEmpty) return '';

    // 1. Global character normalisation. Newlines are unified first so the
    //    split below is the only thing that depends on line breaks.
    final normalised = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_zeroWidth, '')
        .replaceAll(_dashes, '-')
        .replaceAll(_spaces, ' ');

    // 2. Per-line clean: strip control chars, squash spaces, trim, then drop
    //    only lines that cannot possibly be a shift (blank / pure-symbol).
    final cleaned = <String>[];
    for (final line in normalised.split('\n')) {
      final tidy =
          line.replaceAll(_controls, '').replaceAll(_multiSpace, ' ').trim();
      if (tidy.isEmpty) continue;
      if (!_hasAlnum.hasMatch(tidy)) continue; // separator rule / border
      cleaned.add(tidy);
    }

    // 3. Rejoin a range ML Kit split across two lines: a line ending in a range
    //    separator absorbs the following line when that line starts with a
    //    digit. Conservative — a dangling separator is meaningless on its own,
    //    and the digit guard leaves a weekday range header (`Mon-` / `Fri ...`)
    //    untouched — so this only ever recovers data.
    final merged = <String>[];
    for (final line in cleaned) {
      if (merged.isNotEmpty &&
          _trailingSep.hasMatch(merged.last) &&
          _startsDigit.hasMatch(line)) {
        merged[merged.length - 1] = merged.last + line;
      } else {
        merged.add(line);
      }
    }

    return merged.join('\n');
  }
}
