import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/ui/roster/shift_filter.dart';

void main() {
  group('ShiftFilter — matches', () {
    test('all matches every ShiftType', () {
      for (final type in ShiftType.values) {
        expect(
          ShiftFilter.all.matches(_shift(type)),
          isTrue,
          reason: '$type should be admitted by ShiftFilter.all',
        );
      }
    });

    test('work matches day, afternoon, night', () {
      expect(ShiftFilter.work.matches(_shift(ShiftType.day)), isTrue);
      expect(ShiftFilter.work.matches(_shift(ShiftType.afternoon)), isTrue);
      expect(ShiftFilter.work.matches(_shift(ShiftType.night)), isTrue);
    });

    test('work rejects off', () {
      expect(ShiftFilter.work.matches(_shift(ShiftType.off)), isFalse);
    });

    test('off accepts only off', () {
      expect(ShiftFilter.off.matches(_shift(ShiftType.day)), isFalse);
      expect(ShiftFilter.off.matches(_shift(ShiftType.afternoon)), isFalse);
      expect(ShiftFilter.off.matches(_shift(ShiftType.night)), isFalse);
      expect(ShiftFilter.off.matches(_shift(ShiftType.off)), isTrue);
    });
  });

  group('ShiftFilter — apply', () {
    test('all returns the input list (no allocation)', () {
      final input = [_shift(ShiftType.day), _shift(ShiftType.off)];
      // The hot-path optimisation: ShiftFilter.all must short-circuit so
      // the un-filtered case is identity. Asserting `same` here pins
      // that contract — if a refactor accidentally allocates a copy,
      // this fails loudly.
      expect(identical(ShiftFilter.all.apply(input), input), isTrue);
    });

    test('work removes off shifts', () {
      final shifts = [
        _shift(ShiftType.day, id: 'a'),
        _shift(ShiftType.off, id: 'b'),
        _shift(ShiftType.night, id: 'c'),
      ];
      final result = ShiftFilter.work.apply(shifts);
      expect(result.map((s) => s.id), ['a', 'c']);
    });

    test('off keeps only off shifts', () {
      final shifts = [
        _shift(ShiftType.day, id: 'a'),
        _shift(ShiftType.off, id: 'b'),
        _shift(ShiftType.night, id: 'c'),
        _shift(ShiftType.off, id: 'd'),
      ];
      final result = ShiftFilter.off.apply(shifts);
      expect(result.map((s) => s.id), ['b', 'd']);
    });

    test('apply preserves input order', () {
      // Defends against accidentally introducing a sort inside apply.
      // The orchestrator and TimelineView own ordering decisions; this
      // function must be order-preserving so callers can rely on it.
      final shifts = [
        _shift(ShiftType.night, id: 'first'),
        _shift(ShiftType.day, id: 'second'),
        _shift(ShiftType.afternoon, id: 'third'),
      ];
      expect(
        ShiftFilter.work.apply(shifts).map((s) => s.id),
        ['first', 'second', 'third'],
      );
    });

    test('apply on an empty list yields an empty list', () {
      for (final f in ShiftFilter.values) {
        expect(f.apply(<Shift>[]), isEmpty);
      }
    });

    test('every value has a non-empty label', () {
      // Guards against a future enum extension landing without a label.
      // Cheap, but it's exactly the kind of regression that would make
      // the chip strip render with an empty button.
      for (final f in ShiftFilter.values) {
        expect(f.label, isNotEmpty, reason: '$f must have a chip label');
      }
    });
  });
}

Shift _shift(ShiftType type, {String? id}) => Shift(
      id: id ?? 'id-${type.name}',
      date: DateTime(2026, 5, 1),
      type: type,
      startMinutes: type == ShiftType.off ? 0 : 7 * 60,
      endMinutes: type == ShiftType.off ? 0 : 15 * 60,
    );
