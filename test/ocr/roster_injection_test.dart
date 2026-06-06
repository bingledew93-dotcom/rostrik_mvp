import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/shift_block.dart' as builder;
import 'package:rostrik_mvp/ocr/roster_injection.dart';
import 'package:rostrik_mvp/ocr/shift_block.dart' as ocr;

void main() {
  group('ScannedRosterInjection.map — OCR blocks → builder blocks', () {
    test('each block lands on its own sequential cycle day from day 0', () {
      final result = ScannedRosterInjection.map([
        ocr.ShiftBlock(startMinutes: 360, endMinutes: 1080),
        ocr.ShiftBlock(startMinutes: 1080, endMinutes: 360, type: ShiftType.night),
        ocr.ShiftBlock(startMinutes: 0, endMinutes: 0, type: ShiftType.off),
      ]);
      expect(result.map((b) => b.startDayIndex).toList(), [0, 1, 2]);
      expect(result.map((b) => b.endDayIndex).toList(), [0, 1, 2]);
    });

    test('fromDayIndex offsets the sequence (the append case)', () {
      final result = ScannedRosterInjection.map(
        [
          ocr.ShiftBlock(startMinutes: 360, endMinutes: 1080),
          ocr.ShiftBlock(startMinutes: 1080, endMinutes: 360),
        ],
        fromDayIndex: 3,
      );
      expect(result.map((b) => b.startDayIndex).toList(), [3, 4]);
    });

    test('a range block maps to a complete builder block', () {
      final result = ScannedRosterInjection.map(
        [ocr.ShiftBlock(startMinutes: 360, endMinutes: 1080)],
      );
      expect(
        result.single,
        builder.ShiftBlock(
          type: ShiftType.day,
          startDayIndex: 0,
          endDayIndex: 0,
          startMinutes: 360,
          endMinutes: 1080,
        ),
      );
      expect(ScannedRosterInjection.needsEndTime(result.single), isFalse);
    });

    test('a time-only block (null end, null type) → Day + zero-duration '
        'placeholder flagged as needing an end time', () {
      final result =
          ScannedRosterInjection.map([ocr.ShiftBlock(startMinutes: 360)]);
      expect(
        result.single,
        builder.ShiftBlock(
          type: ShiftType.day, // null type defaults to Day
          startDayIndex: 0,
          endDayIndex: 0,
          startMinutes: 360,
          endMinutes: 360, // placeholder == start
        ),
      );
      expect(ScannedRosterInjection.needsEndTime(result.single), isTrue);
    });

    test('a letter block keeps its parsed type and end', () {
      final result = ScannedRosterInjection.map([
        ocr.ShiftBlock(startMinutes: 1080, endMinutes: 360, type: ShiftType.night),
      ]);
      expect(result.single.type, ShiftType.night);
      expect(result.single.startMinutes, 1080);
      expect(result.single.endMinutes, 360);
      expect(ScannedRosterInjection.needsEndTime(result.single), isFalse);
    });

    test('an Off block stays 0/0 and is never flagged', () {
      final result = ScannedRosterInjection.map([
        ocr.ShiftBlock(startMinutes: 0, endMinutes: 0, type: ShiftType.off),
      ]);
      expect(result.single.type, ShiftType.off);
      expect(result.single.startMinutes, 0);
      expect(result.single.endMinutes, 0);
      expect(ScannedRosterInjection.needsEndTime(result.single), isFalse);
    });

    test('empty input → empty output', () {
      expect(ScannedRosterInjection.map(const []), isEmpty);
    });
  });

  group('ScannedRosterInjection.needsEndTime', () {
    builder.ShiftBlock block(ShiftType type, int start, int end) =>
        builder.ShiftBlock(
          type: type,
          startDayIndex: 0,
          endDayIndex: 0,
          startMinutes: start,
          endMinutes: end,
        );

    test('non-Off zero-duration block needs an end time', () {
      expect(
        ScannedRosterInjection.needsEndTime(block(ShiftType.day, 360, 360)),
        isTrue,
      );
    });

    test('non-Off block with a real duration is complete', () {
      expect(
        ScannedRosterInjection.needsEndTime(block(ShiftType.day, 360, 1080)),
        isFalse,
      );
    });

    test('Off block at 0/0 is never flagged', () {
      expect(
        ScannedRosterInjection.needsEndTime(block(ShiftType.off, 0, 0)),
        isFalse,
      );
    });
  });
}
