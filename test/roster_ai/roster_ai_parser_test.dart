import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/roster_ai/roster_ai_parser.dart';

void main() {
  group('RosterAiParser.parseAiOutput — happy path', () {
    test('parses a clean multi-day block in order', () {
      const raw = '10/08/2026 | Day | 06:00 - 18:00\n'
          '11/08/2026 | Day | 06:00 - 18:00\n'
          '12/08/2026 | Night | 18:00 - 06:00\n'
          '13/08/2026 | Off | 00:00 - 00:00';
      final shifts = RosterAiParser.parseAiOutput(raw);
      expect(shifts, hasLength(4));
      expect(shifts[0].date, DateTime(2026, 8, 10));
      expect(shifts[0].shiftType, 'Day');
      expect(shifts[0].startTime, '06:00');
      expect(shifts[0].endTime, '18:00');
      expect(shifts[3].shiftType, 'Off');
    });

    test('DD/MM/YYYY is read day-first (10/08 → 10 Aug, not 8 Oct)', () {
      final shifts = RosterAiParser.parseAiOutput('10/08/2026 | Day | 06:00 - 18:00');
      expect(shifts.single.date, DateTime(2026, 8, 10));
    });

    test('maps type + minutes via the typed conveniences', () {
      final shifts = RosterAiParser.parseAiOutput(
        '12/08/2026 | Night | 18:00 - 06:00',
      );
      final s = shifts.single;
      expect(s.type, ShiftType.night);
      expect(s.startMinutes, 18 * 60);
      expect(s.endMinutes, 6 * 60);
    });

    test('Off day canonicalises to type off with 0/0 minutes', () {
      final s = RosterAiParser
          .parseAiOutput('13/08/2026 | Off | 00:00 - 00:00')
          .single;
      expect(s.type, ShiftType.off);
      expect(s.startMinutes, 0);
      expect(s.endMinutes, 0);
    });
  });

  group('RosterAiParser.parseAiOutput — tolerance', () {
    test('ignores intro/outro prose and blank lines around the block', () {
      const raw = 'Sure! Here is your roster:\n'
          '\n'
          '10/08/2026 | Day | 06:00 - 18:00\n'
          '\n'
          'Let me know if you need any changes!';
      final shifts = RosterAiParser.parseAiOutput(raw);
      expect(shifts, hasLength(1));
      expect(shifts.single.shiftType, 'Day');
    });

    test('tolerates \\r\\n endings and flexible whitespace around pipes/dash', () {
      const raw = '10/08/2026|Day|06:00-18:00\r\n'
          '11/08/2026   |   Night   |   18:00   -   06:00\r\n';
      final shifts = RosterAiParser.parseAiOutput(raw);
      expect(shifts, hasLength(2));
      expect(shifts[1].type, ShiftType.night);
    });

    test('drops a markdown-bulleted line (anchored pattern)', () {
      const raw = '- 10/08/2026 | Day | 06:00 - 18:00';
      expect(RosterAiParser.parseAiOutput(raw), isEmpty);
    });

    test('drops an unknown day type (Afternoon is not allowed by the prompt)', () {
      const raw = '10/08/2026 | Afternoon | 14:00 - 22:00';
      expect(RosterAiParser.parseAiOutput(raw), isEmpty);
    });
  });

  group('RosterAiParser.parseAiOutput — invalid values are skipped', () {
    test('impossible calendar date (31/02) is dropped, not rolled over', () {
      const raw = '31/02/2026 | Day | 06:00 - 18:00\n'
          '01/03/2026 | Day | 06:00 - 18:00';
      final shifts = RosterAiParser.parseAiOutput(raw);
      expect(shifts, hasLength(1));
      expect(shifts.single.date, DateTime(2026, 3, 1));
    });

    test('out-of-range clock (25:00) is dropped', () {
      expect(
        RosterAiParser.parseAiOutput('10/08/2026 | Day | 25:00 - 18:00'),
        isEmpty,
      );
    });

    test('month 00 / day 00 are dropped', () {
      const raw = '00/08/2026 | Day | 06:00 - 18:00\n'
          '10/00/2026 | Day | 06:00 - 18:00';
      expect(RosterAiParser.parseAiOutput(raw), isEmpty);
    });
  });

  group('RosterAiParser.parseAiOutput — empties', () {
    test('empty input → empty list', () {
      expect(RosterAiParser.parseAiOutput(''), isEmpty);
      expect(RosterAiParser.parseAiOutput('   \n  \n'), isEmpty);
    });

    test('pure prose with no matching line → empty list', () {
      expect(
        RosterAiParser.parseAiOutput('I could not find any shifts in that.'),
        isEmpty,
      );
    });
  });

  group('ParsedShift value semantics', () {
    test('equality is by value', () {
      final a = ParsedShift(
        date: DateTime(2026, 8, 10),
        shiftType: 'Day',
        startTime: '06:00',
        endTime: '18:00',
      );
      final b = ParsedShift(
        date: DateTime(2026, 8, 10),
        shiftType: 'Day',
        startTime: '06:00',
        endTime: '18:00',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
