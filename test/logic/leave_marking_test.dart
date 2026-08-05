import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/logic/leave_marking.dart';

void main() {
  Shift shift({
    required String id,
    required DateTime date,
    ShiftType type = ShiftType.day,
  }) =>
      Shift(
        id: id,
        date: date,
        type: type,
        startMinutes: type == ShiftType.off ? 0 : 7 * 60,
        endMinutes: type == ShiftType.off ? 0 : 15 * 60,
      );

  final d1 = DateTime(2026, 8, 3);
  final d2 = DateTime(2026, 8, 4);
  final d3 = DateTime(2026, 8, 5);

  group('leaveTargets', () {
    test('no selected days → no targets', () {
      final all = [shift(id: 'a', date: d1)];
      expect(leaveTargets(all, <DateTime>{}), isEmpty);
    });

    test('returns working shifts on the selected days only', () {
      final all = [
        shift(id: 'a', date: d1),
        shift(id: 'b', date: d2),
        shift(id: 'c', date: d3),
      ];
      final out = leaveTargets(all, {d1, d3});
      expect(out.map((s) => s.id), unorderedEquals(['a', 'c']));
    });

    test('excludes Off/rest shifts on selected days', () {
      final all = [
        shift(id: 'work', date: d1),
        shift(id: 'off', date: d1, type: ShiftType.off),
      ];
      final out = leaveTargets(all, {d1});
      expect(out.map((s) => s.id), ['work']);
    });

    test('matches on the calendar day regardless of the time component', () {
      // Selected day passed as a non-midnight instant still matches the shift.
      final all = [shift(id: 'a', date: DateTime(2026, 8, 3))];
      final out = leaveTargets(all, {DateTime(2026, 8, 3, 14, 30)});
      expect(out.map((s) => s.id), ['a']);
    });

    test('includes multiple working shifts on the same day (split shift)', () {
      final all = [
        shift(id: 'morning', date: d1),
        shift(id: 'evening', date: d1, type: ShiftType.afternoon),
      ];
      final out = leaveTargets(all, {d1});
      expect(out.map((s) => s.id), unorderedEquals(['morning', 'evening']));
    });
  });
}
