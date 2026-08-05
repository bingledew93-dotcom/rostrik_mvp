import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/reminders/reminder_id.dart';

void main() {
  test('is deterministic for the same id', () {
    expect(
      reminderNotificationId('11111111-2222-3333-4444-555555555555'),
      reminderNotificationId('11111111-2222-3333-4444-555555555555'),
    );
  });

  test('differs for different ids', () {
    expect(
      reminderNotificationId('a'),
      isNot(reminderNotificationId('b')),
    );
  });

  test('is always a non-negative 31-bit int', () {
    for (final s in ['', 'x', 'a-uuid-string', '🎂', 'ZZZZZZZZ']) {
      final id = reminderNotificationId(s);
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThanOrEqualTo(0x7fffffff));
    }
  });
}
