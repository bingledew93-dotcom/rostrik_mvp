import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/ocr/ocr_scanner_service.dart';
import 'package:rostrik_mvp/ocr/shift_block.dart';

/// Exercises the pure text → blocks step of the scanner. The camera / crop /
/// ML Kit round-trip can only run on a device, but [parseTextLines] is the
/// logic that turns ML Kit's recognised text into [ShiftBlock]s, and it is
/// fully testable from a plain string.
void main() {
  group('OcrScannerService.parseTextLines', () {
    test('column layout: one cell per line, in reading order', () {
      final blocks = OcrScannerService.parseTextLines('0600\n1800\nN');
      expect(blocks, hasLength(3));
      expect(blocks[0], ShiftBlock(startMinutes: 360));
      expect(blocks[1], ShiftBlock(startMinutes: 1080));
      expect(
        blocks[2],
        ShiftBlock(startMinutes: 1080, endMinutes: 360, type: ShiftType.night),
      );
    });

    test('grid ROW: a line that is not one value is whitespace-tokenised', () {
      final blocks = OcrScannerService.parseTextLines('D N O D');
      expect(
        blocks.map((b) => b.type).toList(),
        [ShiftType.day, ShiftType.night, ShiftType.off, ShiftType.day],
      );
    });

    test('a range line is parsed whole (NOT split on its inner spaces)', () {
      final blocks = OcrScannerService.parseTextLines('06:00 - 18:00');
      expect(blocks.single, ShiftBlock(startMinutes: 360, endMinutes: 1080));
    });

    test('retail columns: two times on one line → one range (Coles regression)',
        () {
      // Start/end in separate columns, whitespace only — previously the end
      // was dropped and only the start survived.
      final blocks = OcrScannerService.parseTextLines('Mon 9:15am 5:30pm');
      expect(blocks.single, ShiftBlock(startMinutes: 555, endMinutes: 1050));
    });

    test('whitespace-separated 24h columns → one range', () {
      final blocks = OcrScannerService.parseTextLines('0600 1800');
      expect(blocks.single, ShiftBlock(startMinutes: 360, endMinutes: 1080));
    });

    test("the word 'OFF' on a rest-day line → an Off block (not dropped)", () {
      final blocks = OcrScannerService.parseTextLines('Mon OFF');
      expect(
        blocks.single,
        ShiftBlock(startMinutes: 0, endMinutes: 0, type: ShiftType.off),
      );
    });

    test("'OFF' inside a grid row tokenises to an Off cell", () {
      final blocks = OcrScannerService.parseTextLines('D OFF N');
      expect(
        blocks.map((b) => b.type).toList(),
        [ShiftType.day, ShiftType.off, ShiftType.night],
      );
    });

    test("'6 a.m.' is parsed whole despite the internal space", () {
      expect(
        OcrScannerService.parseTextLines('6 a.m.').single,
        ShiftBlock(startMinutes: 360),
      );
    });

    test('blank lines and unparseable header rows are skipped', () {
      final blocks =
          OcrScannerService.parseTextLines('Mon Tue\n\n0600\n   \nxyz');
      expect(blocks, hasLength(1));
      expect(blocks.single, ShiftBlock(startMinutes: 360));
    });

    test('scrub failsafe survives the line walk (O6OO / l800)', () {
      final blocks = OcrScannerService.parseTextLines('O6OO\nl800');
      expect(blocks, [
        ShiftBlock(startMinutes: 360),
        ShiftBlock(startMinutes: 1080),
      ]);
    });

    test('completely empty text → no blocks', () {
      expect(OcrScannerService.parseTextLines(''), isEmpty);
      expect(OcrScannerService.parseTextLines('\n  \n'), isEmpty);
    });

    test('handwritten Off written as 0 inside a grid row', () {
      // ML Kit reads the large handwritten 'O' as a zero; tokenising the row
      // still resolves it to Off.
      final blocks = OcrScannerService.parseTextLines('D 0 N');
      expect(
        blocks.map((b) => b.type).toList(),
        [ShiftType.day, ShiftType.off, ShiftType.night],
      );
    });
  });

  group('day-of-week anchoring (Phase 6.5)', () {
    test("'mon 3pm-9pm' / 'wed 1pm-8pm' → [Shift, Off, Shift] "
        '(missing Tuesday filled)', () {
      final blocks =
          OcrScannerService.parseTextLines('mon 3pm-9pm\nwed 1pm-8pm');
      expect(blocks, hasLength(3));
      // 3pm–9pm
      expect(blocks[0], ShiftBlock(startMinutes: 900, endMinutes: 1260));
      // injected Tuesday
      expect(
        blocks[1],
        ShiftBlock(startMinutes: 0, endMinutes: 0, type: ShiftType.off),
      );
      // 1pm–8pm
      expect(blocks[2], ShiftBlock(startMinutes: 780, endMinutes: 1200));
    });

    test('Fri → Mon wraps the weekend into exactly 2 Off days', () {
      final blocks =
          OcrScannerService.parseTextLines('fri 0600-1400\nmon 0600-1400');
      expect(blocks, hasLength(4));
      expect(
        blocks.map((b) => b.type).toList(),
        [null, ShiftType.off, ShiftType.off, null],
      );
    });

    test('consecutive weekdays (Mon → Tue) insert no Off', () {
      final blocks =
          OcrScannerService.parseTextLines('mon 0600-1400\ntue 0600-1400');
      expect(blocks, hasLength(2));
      expect(blocks.any((b) => b.type == ShiftType.off), isFalse);
    });

    test('full weekday names, Monday → Wednesday → 1 Off', () {
      final blocks = OcrScannerService.parseTextLines(
        'monday 9am-5pm\nwednesday 9am-5pm',
      );
      expect(blocks, hasLength(3));
      expect(blocks[1].type, ShiftType.off);
    });

    test('a lone weekday header anchors nothing (no shift on the line)', () {
      // "Mon" with no time is a header; the timed line has no weekday, so no
      // gap logic and no spurious Off block.
      final blocks = OcrScannerService.parseTextLines('Mon\n0600-1400');
      expect(blocks, hasLength(1));
      expect(blocks.single, ShiftBlock(startMinutes: 360, endMinutes: 840));
    });

    test('lines without weekdays are unaffected (no gap inference)', () {
      final blocks = OcrScannerService.parseTextLines('0600\n1800');
      expect(blocks, hasLength(2));
      expect(blocks.any((b) => b.type == ShiftType.off), isFalse);
    });
  });
}
