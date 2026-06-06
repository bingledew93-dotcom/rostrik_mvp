import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/ocr/ocr_scanner_service.dart';
import 'package:rostrik_mvp/ocr/ocr_text_sanitizer.dart';
import 'package:rostrik_mvp/ocr/shift_block.dart';

/// Exotic inputs are built with [String.fromCharCode] (never literal glyphs)
/// so the test source stays reviewable and can't be silently corrupted —
/// mirroring how the sanitizer itself spells its code points.
void main() {
  final zwsp = String.fromCharCode(0x200B); // zero-width space
  final minus = String.fromCharCode(0x2212); // MINUS SIGN (not ASCII '-')
  final nbsp = String.fromCharCode(0xA0); // non-breaking space

  group('OcrTextSanitizer.sanitize — normalisation', () {
    test('empty / whitespace-only input → empty string', () {
      expect(OcrTextSanitizer.sanitize(''), '');
      expect(OcrTextSanitizer.sanitize('   \n  \r\n'), '');
    });

    test('folds the unicode MINUS SIGN so a range keeps its end time', () {
      // U+2212 is NOT in OcrTimeParser's separator set; without folding the
      // end time would be lost and the cell would collapse to a lone start.
      expect(OcrTextSanitizer.sanitize('0600${minus}1800'), '0600-1800');
    });

    test('folds NBSP and squashes space runs, keeping single spaces', () {
      expect(
        OcrTextSanitizer.sanitize('06:00$nbsp$nbsp-   18:00'),
        '06:00 - 18:00',
      );
    });

    test('strips zero-width characters that split a token', () {
      expect(OcrTextSanitizer.sanitize('06${zwsp}00'), '0600');
    });

    test('preserves newline structure (column layout survives)', () {
      expect(OcrTextSanitizer.sanitize('0600\n1800\nN'), '0600\n1800\nN');
    });
  });

  group('OcrTextSanitizer.sanitize — conservative line handling', () {
    test('drops pure-symbol rules/borders but keeps the real row', () {
      expect(
        OcrTextSanitizer.sanitize('-----\n0600-1800\n| | |'),
        '0600-1800',
      );
    });

    test('rejoins a range ML Kit wrapped onto two lines', () {
      expect(OcrTextSanitizer.sanitize('0600-\n1800'), '0600-1800');
    });

    test('does NOT merge when the continuation is not a number', () {
      // `Mon-` then `Fri ...` is a weekday-range header, not a split time; the
      // digit guard keeps them on separate lines.
      expect(
        OcrTextSanitizer.sanitize('Mon-\nFri 0600-1400'),
        'Mon-\nFri 0600-1400',
      );
    });

    test('leaves ambiguous content for the parser / user (no grid guessing)', () {
      // A status-bar clock and a header are NOT stripped — deleting a real
      // shift is worse than a phantom the user can remove on the review card.
      const raw = '9:41\nMon 0600-1400\nWeek 12';
      expect(OcrTextSanitizer.sanitize(raw), raw);
    });
  });

  group('end-to-end through the parser', () {
    test('a minus-sign range now parses to start + end', () {
      final clean = OcrTextSanitizer.sanitize('0600${minus}1800');
      final blocks = OcrScannerService.parseTextLines(clean);
      expect(blocks.single, ShiftBlock(startMinutes: 360, endMinutes: 1080));
    });
  });
}
