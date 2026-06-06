import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/ocr/ocr_time_parser.dart';
import 'package:rostrik_mvp/ocr/shift_block.dart';

void main() {
  // Reference minute-of-day values:
  //   06:00 = 360 · 12:00 = 720 · 14:00 = 840 · 18:00 = 1080 ·
  //   22:00 = 1320 · 23:00 = 1380 · 23:30 = 1410.

  group('pre-scrub failsafe', () {
    test("'O6OO' → 06:00 (letter O → digit 0)", () {
      expect(OcrTimeParser.parse('O6OO'), ShiftBlock(startMinutes: 360));
    });

    test("'l800' → 18:00 (letter l → digit 1)", () {
      expect(OcrTimeParser.parse('l800'), ShiftBlock(startMinutes: 1080));
    });

    test("'O6:OO' → 06:00 (mixed letters + colon)", () {
      expect(OcrTimeParser.parse('O6:OO'), ShiftBlock(startMinutes: 360));
    });

    test("'0 6 0 0' → 06:00 (whitespace between digits stripped)", () {
      expect(OcrTimeParser.parse('0 6 0 0'), ShiftBlock(startMinutes: 360));
    });

    test('preScrub maps o/l/i to digits and squashes inter-digit spaces', () {
      expect(OcrTimeParser.preScrub('o6oo'), '0600');
      expect(OcrTimeParser.preScrub('l800'), '1800');
      expect(OcrTimeParser.preScrub('0 0 0 0'), '0000');
    });
  });

  group('Tier 1 — 24-hour time', () {
    test("'0600' → 360", () {
      expect(OcrTimeParser.parse('0600'), ShiftBlock(startMinutes: 360));
    });

    test("'1800' → 1080", () {
      expect(OcrTimeParser.parse('1800'), ShiftBlock(startMinutes: 1080));
    });

    test("'06:00' → 360", () {
      expect(OcrTimeParser.parse('06:00'), ShiftBlock(startMinutes: 360));
    });

    test("'18:00' → 1080", () {
      expect(OcrTimeParser.parse('18:00'), ShiftBlock(startMinutes: 1080));
    });

    test("'2300' → 1380 (upper hour boundary)", () {
      expect(OcrTimeParser.parse('2300'), ShiftBlock(startMinutes: 1380));
    });

    test("'0000' → 0 (midnight)", () {
      expect(OcrTimeParser.parse('0000'), ShiftBlock(startMinutes: 0));
    });

    test("'600' → 360 (3-digit form)", () {
      expect(OcrTimeParser.parse('600'), ShiftBlock(startMinutes: 360));
    });

    test('a single 24h time leaves endMinutes null', () {
      expect(OcrTimeParser.parse('0600')!.endMinutes, isNull);
      expect(OcrTimeParser.parse('0600')!.type, isNull);
    });
  });

  group('Tier 2 — 12-hour time', () {
    test("'6am' → 360", () {
      expect(OcrTimeParser.parse('6am'), ShiftBlock(startMinutes: 360));
    });

    test("'6:00am' → 360", () {
      expect(OcrTimeParser.parse('6:00am'), ShiftBlock(startMinutes: 360));
    });

    test("'6 a.m.' → 360 (spaced + dotted modifier)", () {
      expect(OcrTimeParser.parse('6 a.m.'), ShiftBlock(startMinutes: 360));
    });

    test("'12pm' → 720 (noon)", () {
      expect(OcrTimeParser.parse('12pm'), ShiftBlock(startMinutes: 720));
    });

    test("'12am' → 0 (midnight)", () {
      expect(OcrTimeParser.parse('12am'), ShiftBlock(startMinutes: 0));
    });

    test("'11pm' → 1380", () {
      expect(OcrTimeParser.parse('11pm'), ShiftBlock(startMinutes: 1380));
    });

    test("'6:30pm' → 1110 (am/pm beats 24h on a colon+pm string)", () {
      expect(OcrTimeParser.parse('6:30pm'), ShiftBlock(startMinutes: 1110));
    });
  });

  group("Tier 2 — handwritten 'pm' tolerance (ML Kit m→n/r misreads)", () {
    test("'3pn' → 900 (pm read as pn)", () {
      expect(OcrTimeParser.parse('3pn'), ShiftBlock(startMinutes: 900));
    });

    test("'3pr' → 900 (pm read as pr)", () {
      expect(OcrTimeParser.parse('3pr'), ShiftBlock(startMinutes: 900));
    });

    test("'3pm' still → 900 (literal modifier, no regression)", () {
      expect(OcrTimeParser.parse('3pm'), ShiftBlock(startMinutes: 900));
    });

    test("'3p.m.' → 900 (dotted modifier still parses)", () {
      expect(OcrTimeParser.parse('3p.m.'), ShiftBlock(startMinutes: 900));
    });

    test("'6:30pn' → 1110 (fuzzy pm still beats 24h on a colon string)", () {
      expect(OcrTimeParser.parse('6:30pn'), ShiftBlock(startMinutes: 1110));
    });

    // The fuzz must NOT manufacture times out of ordinary words. The leading
    // 1–12 hour and the `(?![a-z])` boundary are what keep it honest.
    test("'apron' is not a time (a 'pr' with no leading hour stays null)", () {
      expect(OcrTimeParser.parse('apron'), isNull);
    });

    test("'5 amp' is not 5am (boundary guard rejects a trailing letter)", () {
      expect(OcrTimeParser.parse('5 amp'), isNull);
    });
  });

  group('Tier 3 — grid-letter fallback', () {
    test("'N' → night, 18:00 → 06:00", () {
      expect(
        OcrTimeParser.parse('N'),
        ShiftBlock(
          startMinutes: 1080,
          endMinutes: 360,
          type: ShiftType.night,
        ),
      );
    });

    test("'D' → day, 06:00 → 18:00", () {
      expect(
        OcrTimeParser.parse('D'),
        ShiftBlock(startMinutes: 360, endMinutes: 1080, type: ShiftType.day),
      );
    });

    test("'A' → afternoon, 14:00 → 22:00", () {
      expect(
        OcrTimeParser.parse('A'),
        ShiftBlock(
          startMinutes: 840,
          endMinutes: 1320,
          type: ShiftType.afternoon,
        ),
      );
    });

    test("'O' → off block, 0 → 0 (recognised, not a failure)", () {
      expect(
        OcrTimeParser.parse('O'),
        ShiftBlock(startMinutes: 0, endMinutes: 0, type: ShiftType.off),
      );
    });

    test("a standalone '0' (handwritten 'O' misread as zero) → Off", () {
      expect(
        OcrTimeParser.parse('0'),
        ShiftBlock(startMinutes: 0, endMinutes: 0, type: ShiftType.off),
      );
    });

    test("the full word 'OFF' → Off (case-insensitive)", () {
      const off =
          ShiftBlock(startMinutes: 0, endMinutes: 0, type: ShiftType.off);
      expect(OcrTimeParser.parse('OFF'), off);
      expect(OcrTimeParser.parse('off'), off);
      expect(OcrTimeParser.parse('Off'), off);
      // Punctuation around the word is tolerated (`O.F.F`, `off,`).
      expect(OcrTimeParser.parse('O.F.F'), off);
    });

    test('letters are case-insensitive', () {
      expect(OcrTimeParser.parse('d')!.type, ShiftType.day);
      expect(OcrTimeParser.parse('n')!.type, ShiftType.night);
    });
  });

  group('ranges (start + end)', () {
    test("'0600-1800' → 360 / 1080", () {
      expect(
        OcrTimeParser.parse('0600-1800'),
        ShiftBlock(startMinutes: 360, endMinutes: 1080),
      );
    });

    test("'6am-6pm' → 360 / 1080", () {
      expect(
        OcrTimeParser.parse('6am-6pm'),
        ShiftBlock(startMinutes: 360, endMinutes: 1080),
      );
    });

    test("'O6OO-18OO' → 360 / 1080 (scrub then range)", () {
      expect(
        OcrTimeParser.parse('O6OO-18OO'),
        ShiftBlock(startMinutes: 360, endMinutes: 1080),
      );
    });

    test("'06:00–18:00' (en-dash) → 360 / 1080", () {
      expect(
        OcrTimeParser.parse('06:00–18:00'),
        ShiftBlock(startMinutes: 360, endMinutes: 1080),
      );
    });

    test("'6am to 6pm' → 360 / 1080 (word separator)", () {
      expect(
        OcrTimeParser.parse('6am to 6pm'),
        ShiftBlock(startMinutes: 360, endMinutes: 1080),
      );
    });

    test("'0600=1400' → 360 / 840 (equals as a range separator)", () {
      expect(
        OcrTimeParser.parse('0600=1400'),
        ShiftBlock(startMinutes: 360, endMinutes: 840),
      );
    });

    test("squashed '1500-2300' → 900 / 1380 (no whitespace around dash)", () {
      expect(
        OcrTimeParser.parse('1500-2300'),
        ShiftBlock(startMinutes: 900, endMinutes: 1380),
      );
    });
  });

  group('complete failure → null', () {
    test('empty string', () => expect(OcrTimeParser.parse(''), isNull));
    test('whitespace only', () => expect(OcrTimeParser.parse('   '), isNull));
    test('pure garbage', () => expect(OcrTimeParser.parse('xyz'), isNull));
    test("'2500' (invalid hour)", () {
      expect(OcrTimeParser.parse('2500'), isNull);
    });
    test("'99' (too short to be a time)", () {
      expect(OcrTimeParser.parse('99'), isNull);
    });
    test("'D-N' (letter range is out of scope)", () {
      expect(OcrTimeParser.parse('D-N'), isNull);
    });
  });

  group('explicit prompt edge cases', () {
    test("'O6OO', 'l800', '6 a.m.', 'N' all parse correctly", () {
      expect(OcrTimeParser.parse('O6OO'), ShiftBlock(startMinutes: 360));
      expect(OcrTimeParser.parse('l800'), ShiftBlock(startMinutes: 1080));
      expect(OcrTimeParser.parse('6 a.m.'), ShiftBlock(startMinutes: 360));
      expect(
        OcrTimeParser.parse('N'),
        ShiftBlock(
          startMinutes: 1080,
          endMinutes: 360,
          type: ShiftType.night,
        ),
      );
    });
  });

  group('dot-separated minutes (retail)', () {
    test("'9.15am' → 555 (12h with a dot)", () {
      expect(OcrTimeParser.parse('9.15am'), ShiftBlock(startMinutes: 555));
    });
    test("'14.00' → 840 (24h with a dot)", () {
      expect(OcrTimeParser.parse('14.00'), ShiftBlock(startMinutes: 840));
    });
  });

  group('findTimes — every time on a line, left→right', () {
    test('two space-separated 12h times', () {
      expect(OcrTimeParser.findTimes('9:15am 5:30pm'), [555, 1050]);
    });
    test('two space-separated 24h times keep their gap (no squash)', () {
      expect(OcrTimeParser.findTimes('0600 1800'), [360, 1080]);
    });
    test('a bare 12h pair', () {
      expect(OcrTimeParser.findTimes('9am 5pm'), [540, 1020]);
    });
    test('grid letters yield no times', () {
      expect(OcrTimeParser.findTimes('D N O D'), isEmpty);
    });
    test('a long digit run (phone/id) yields no times', () {
      expect(OcrTimeParser.findTimes('0412345678'), isEmpty);
    });
    test('a squashed range keeps both times (zero whitespace)', () {
      expect(OcrTimeParser.findTimes('1500-2300'), [900, 1380]);
    });
  });

  group('parseRange — explicit OR two-time (the column fix)', () {
    test('whitespace-separated 12h columns → start + end', () {
      expect(
        OcrTimeParser.parseRange('9:15am 5:30pm'),
        ShiftBlock(startMinutes: 555, endMinutes: 1050),
      );
    });
    test('whitespace-separated 24h columns → start + end', () {
      expect(
        OcrTimeParser.parseRange('0600 1800'),
        ShiftBlock(startMinutes: 360, endMinutes: 1080),
      );
    });
    test("explicit 'to' separator still works", () {
      expect(
        OcrTimeParser.parseRange('9am to 5pm'),
        ShiftBlock(startMinutes: 540, endMinutes: 1020),
      );
    });
    test('tilde separator still works', () {
      expect(
        OcrTimeParser.parseRange('0600~1800'),
        ShiftBlock(startMinutes: 360, endMinutes: 1080),
      );
    });
    test('a single time is NOT a range', () {
      expect(OcrTimeParser.parseRange('0600'), isNull);
    });
    test('three times is NOT a range (falls through to per-cell)', () {
      expect(OcrTimeParser.parseRange('0600 1200 1800'), isNull);
    });
    test('a grid-letter row is NOT a range', () {
      expect(OcrTimeParser.parseRange('D N O D'), isNull);
    });

    test("'D = 0600 - 1400' → 360 / 840 (label noise: equals + dash)", () {
      // The cell carries a 'D' label and an '=' before the real range. The
      // two-time fallback ignores both and recovers 06:00 → 14:00 — exactly the
      // path the scanner takes ([_parseLineShifts] calls parseRange first).
      expect(
        OcrTimeParser.parseRange('D = 0600 - 1400'),
        ShiftBlock(startMinutes: 360, endMinutes: 840),
      );
    });

    test("squashed '1500-2300' → 900 / 1380 (range path, no whitespace)", () {
      expect(
        OcrTimeParser.parseRange('1500-2300'),
        ShiftBlock(startMinutes: 900, endMinutes: 1380),
      );
    });
  });
}
