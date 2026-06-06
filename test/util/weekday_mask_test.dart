import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/ui/shift_format.dart';
import 'package:rostrik_mvp/util/weekday_mask.dart';

void main() {
  group('weekdayMaskFromSet / weekdaysFromMask', () {
    test('round-trips an arbitrary set', () {
      final mask = weekdayMaskFromSet({1, 3, 5});
      expect(mask, 1 | 1 << 2 | 1 << 4);
      expect(weekdaysFromMask(mask), [1, 3, 5]);
    });

    test('empty set ↔ 0', () {
      expect(weekdayMaskFromSet(const <int>[]), 0);
      expect(weekdaysFromMask(0), isEmpty);
    });

    test('all seven days', () {
      final mask = weekdayMaskFromSet(kAllWeekdays);
      expect(weekdaysFromMask(mask), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('output is always sorted ascending regardless of input order', () {
      expect(weekdaysFromMask(weekdayMaskFromSet({7, 1, 4})), [1, 4, 7]);
    });

    test('out-of-range weekdays are ignored', () {
      expect(weekdayMaskFromSet({0, 8, 3}), 1 << 2);
    });

    test('duplicates collapse', () {
      expect(weekdayMaskFromSet([2, 2, 2]), 1 << 1);
    });
  });

  group('maskHasWeekday', () {
    final mask = weekdayMaskFromSet({2, 6});
    test('reports membership', () {
      expect(maskHasWeekday(mask, 2), isTrue);
      expect(maskHasWeekday(mask, 6), isTrue);
      expect(maskHasWeekday(mask, 1), isFalse);
    });
    test('out-of-range → false', () {
      expect(maskHasWeekday(mask, 0), isFalse);
      expect(maskHasWeekday(mask, 8), isFalse);
    });
  });

  group('formatWeekdays', () {
    test('all seven → Every day', () {
      expect(formatWeekdays(weekdayMaskFromSet(kAllWeekdays)), 'Every day');
    });
    test('Mon–Fri → Weekdays', () {
      expect(formatWeekdays(weekdayMaskFromSet({1, 2, 3, 4, 5})), 'Weekdays');
    });
    test('Sat+Sun → Weekends', () {
      expect(formatWeekdays(weekdayMaskFromSet({6, 7})), 'Weekends');
    });
    test('arbitrary set lists abbreviated days Monday-first', () {
      expect(formatWeekdays(weekdayMaskFromSet({5, 1, 3})), 'Mon, Wed, Fri');
    });
    test('single day', () {
      expect(formatWeekdays(weekdayMaskFromSet({7})), 'Sun');
    });
    test('empty mask → No days', () {
      expect(formatWeekdays(0), 'No days');
    });
  });
}
