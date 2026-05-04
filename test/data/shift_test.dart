import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

void main() {
  group('Shift — date normalization', () {
    test('strips time components to local midnight', () {
      final s = Shift(
        id: 'a',
        date: DateTime(2026, 5, 1, 14, 23, 45, 678),
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      );
      expect(s.date, DateTime(2026, 5, 1));
    });

    test('leaves an already-midnight DateTime unchanged', () {
      final s = _shift(date: DateTime(2026, 5, 1));
      expect(s.date, DateTime(2026, 5, 1));
    });

    test('handles last-millisecond-of-day timestamps', () {
      final s = _shift(date: DateTime(2026, 5, 1, 23, 59, 59, 999));
      expect(s.date, DateTime(2026, 5, 1));
    });

    test('handles first-millisecond-of-day timestamps', () {
      final s = _shift(date: DateTime(2026, 5, 1, 0, 0, 0, 1));
      expect(s.date, DateTime(2026, 5, 1));
    });

    test('preserves date across DST-style hour shifts (no rollover)', () {
      // Constructing 02:30 should still normalize to that calendar day's midnight.
      final s = _shift(date: DateTime(2026, 3, 8, 2, 30));
      expect(s.date, DateTime(2026, 3, 8));
    });
  });

  group('Shift — isOvernight', () {
    test('day shift 07:00–15:00 is not overnight', () {
      expect(_shift(start: 7 * 60, end: 15 * 60).isOvernight, isFalse);
    });

    test('afternoon shift 15:00–23:00 is not overnight', () {
      expect(_shift(start: 15 * 60, end: 23 * 60).isOvernight, isFalse);
    });

    test('night shift 22:00–06:00 is overnight', () {
      expect(_shift(start: 22 * 60, end: 6 * 60).isOvernight, isTrue);
    });

    test('end == start is treated as overnight (24h shift)', () {
      // Convention: endMinutes <= startMinutes ⇒ overnight, including equality.
      // This makes 00:00–00:00 mean a full 24-hour shift.
      expect(_shift(start: 8 * 60, end: 8 * 60).isOvernight, isTrue);
    });

    test('end one minute before start is overnight', () {
      expect(_shift(start: 8 * 60, end: 8 * 60 - 1).isOvernight, isTrue);
    });

    test('end one minute after start is not overnight', () {
      expect(_shift(start: 8 * 60, end: 8 * 60 + 1).isOvernight, isFalse);
    });
  });

  group('Shift — durationMinutes', () {
    test('day 07:00–15:00 = 480 min', () {
      expect(_shift(start: 7 * 60, end: 15 * 60).durationMinutes, 480);
    });

    test('afternoon 15:00–23:00 = 480 min', () {
      expect(_shift(start: 15 * 60, end: 23 * 60).durationMinutes, 480);
    });

    test('overnight 22:00–06:00 = 480 min', () {
      expect(_shift(start: 22 * 60, end: 6 * 60).durationMinutes, 480);
    });

    test('full-day shift 00:00–00:00 = 1440 min', () {
      expect(_shift(start: 0, end: 0).durationMinutes, 1440);
    });

    test('one-minute shift', () {
      expect(_shift(start: 100, end: 101).durationMinutes, 1);
    });

    test('one-minute overnight shift wraps to 1439 min', () {
      // start 23:59, end 23:58 ⇒ overnight, lasts (23:58 next day - 23:59 today)
      expect(_shift(start: 23 * 60 + 59, end: 23 * 60 + 58).durationMinutes, 1439);
    });
  });

  group('Shift — startDateTime / endDateTime', () {
    test('day shift end stays on the same calendar day', () {
      final s = _shift(
        date: DateTime(2026, 5, 1),
        start: 7 * 60,
        end: 15 * 60,
      );
      expect(s.startDateTime, DateTime(2026, 5, 1, 7));
      expect(s.endDateTime, DateTime(2026, 5, 1, 15));
    });

    test('overnight shift end rolls into the next day', () {
      final s = _shift(
        date: DateTime(2026, 5, 1),
        type: ShiftType.night,
        start: 22 * 60,
        end: 6 * 60,
      );
      expect(s.startDateTime, DateTime(2026, 5, 1, 22));
      expect(s.endDateTime, DateTime(2026, 5, 2, 6));
    });

    test('24h shift starting at midnight ends at the next midnight', () {
      final s = _shift(
        date: DateTime(2026, 5, 1),
        start: 0,
        end: 0,
      );
      expect(s.startDateTime, DateTime(2026, 5, 1));
      expect(s.endDateTime, DateTime(2026, 5, 2));
    });
  });

  group('Shift — value equality', () {
    test('same fields ⇒ equal and same hashCode', () {
      final a = _shift(id: 'x');
      final b = _shift(id: 'x');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differing id ⇒ not equal', () {
      expect(_shift(id: 'a'), isNot(equals(_shift(id: 'b'))));
    });

    test('differing date ⇒ not equal', () {
      expect(
        _shift(date: DateTime(2026, 5, 1)),
        isNot(equals(_shift(date: DateTime(2026, 5, 2)))),
      );
    });

    test('differing type ⇒ not equal', () {
      expect(
        _shift(type: ShiftType.day),
        isNot(equals(_shift(type: ShiftType.night))),
      );
    });

    test('differing startMinutes ⇒ not equal', () {
      expect(_shift(start: 7 * 60), isNot(equals(_shift(start: 8 * 60))));
    });

    test('differing note ⇒ not equal', () {
      expect(_shift(note: 'foo'), isNot(equals(_shift(note: 'bar'))));
    });

    test('null note vs non-null note ⇒ not equal', () {
      expect(_shift(note: null), isNot(equals(_shift(note: 'x'))));
    });

    test('differing isMuted ⇒ not equal', () {
      expect(_shift(isMuted: false), isNot(equals(_shift(isMuted: true))));
    });

    test('same isMuted ⇒ equal and same hashCode', () {
      final a = _shift(isMuted: true);
      final b = _shift(isMuted: true);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('Shift — copyWith', () {
    test('with no overrides returns an equal copy', () {
      final a = _shift(note: 'orig');
      expect(a.copyWith(), equals(a));
    });

    test('overrides only the named fields', () {
      final a = _shift(start: 7 * 60, end: 15 * 60, note: 'orig');
      final b = a.copyWith(startMinutes: 8 * 60);
      expect(b.startMinutes, 8 * 60);
      expect(b.endMinutes, 15 * 60);
      expect(b.id, a.id);
      expect(b.note, 'orig');
    });

    test('flips isMuted independently of other fields', () {
      final a = _shift(note: 'orig', isMuted: false);
      final b = a.copyWith(isMuted: true);
      expect(b.isMuted, isTrue);
      // every other field is preserved
      expect(b.id, a.id);
      expect(b.date, a.date);
      expect(b.type, a.type);
      expect(b.startMinutes, a.startMinutes);
      expect(b.endMinutes, a.endMinutes);
      expect(b.note, a.note);
    });

    test('preserves isMuted when other fields are copied', () {
      final muted = _shift(isMuted: true);
      final renamed = muted.copyWith(note: 'changed');
      expect(renamed.isMuted, isTrue);
    });
  });

  group('Shift — isMuted default', () {
    test('defaults to false when constructed without the flag', () {
      // Important for backward-compat: every existing call site
      // (templates, editor) constructs Shift without naming isMuted.
      final s = Shift(
        id: 'a',
        date: DateTime(2026, 5, 1),
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
      );
      expect(s.isMuted, isFalse);
    });
  });

  group('Shift — invariants', () {
    test('asserts startMinutes is in 0..1439', () {
      expect(() => _shift(start: -1), throwsA(isA<AssertionError>()));
      expect(() => _shift(start: 1440), throwsA(isA<AssertionError>()));
    });

    test('asserts endMinutes is in 0..1439', () {
      expect(() => _shift(end: -1), throwsA(isA<AssertionError>()));
      expect(() => _shift(end: 1440), throwsA(isA<AssertionError>()));
    });
  });
}

Shift _shift({
  String id = 'test-id',
  DateTime? date,
  ShiftType type = ShiftType.day,
  int start = 7 * 60,
  int end = 15 * 60,
  String? note,
  bool isMuted = false,
}) =>
    Shift(
      id: id,
      date: date ?? DateTime(2026, 5, 1),
      type: type,
      startMinutes: start,
      endMinutes: end,
      note: note,
      isMuted: isMuted,
    );
