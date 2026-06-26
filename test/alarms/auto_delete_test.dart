import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/app_alarm_repository.dart';

import 'fakes.dart';

void main() {
  AppAlarm alarm({
    String id = 'a1',
    AppAlarmRepeatType repeatType = AppAlarmRepeatType.oneTime,
    bool autoDelete = true,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: 7 * 60,
        label: 'One-off',
        repeatType: repeatType,
        linkedShiftType:
            repeatType == AppAlarmRepeatType.followsRotation ? ShiftType.day : null,
        autoDeleteAfterFiring: autoDelete,
      );

  group('shouldDeleteAfterFiring', () {
    test('true for a one-time alarm with the auto-delete flag', () {
      expect(shouldDeleteAfterFiring(alarm()), isTrue);
    });
    test('true for a one-time alarm even without the flag '
        '(one-time fires once, so it is always cleaned up)', () {
      expect(shouldDeleteAfterFiring(alarm(autoDelete: false)), isTrue);
    });
    test('false for recurring repeat types — never cleaned up after firing, '
        'even if a stray flag is set', () {
      expect(
        shouldDeleteAfterFiring(
          alarm(repeatType: AppAlarmRepeatType.weekly),
        ),
        isFalse,
      );
      expect(
        shouldDeleteAfterFiring(
          alarm(repeatType: AppAlarmRepeatType.followsRotation),
        ),
        isFalse,
      );
    });
    test('false for null', () {
      expect(shouldDeleteAfterFiring(null), isFalse);
    });
  });

  group('deleteAlarmAfterFiring', () {
    late FakeAppAlarmRepository repo;
    setUp(() => repo = FakeAppAlarmRepository());
    tearDown(() => repo.dispose());

    test('deletes a fired one-time alarm by id (returns true)', () async {
      await repo.upsert(alarm(id: 'gone'));
      expect(await deleteAlarmAfterFiring(repo, 'gone'), isTrue);
      expect(await repo.getById('gone'), isNull);
    });

    test('deletes a one-time alarm even without the auto-delete flag', () async {
      await repo.upsert(alarm(id: 'gone2', autoDelete: false));
      expect(await deleteAlarmAfterFiring(repo, 'gone2'), isTrue);
      expect(await repo.getById('gone2'), isNull);
    });

    test('leaves a follows-rotation alarm in place (returns false)', () async {
      await repo.upsert(
        alarm(id: 'fr', repeatType: AppAlarmRepeatType.followsRotation),
      );
      expect(await deleteAlarmAfterFiring(repo, 'fr'), isFalse);
      expect(await repo.getById('fr'), isNotNull);
    });

    test('empty id is a no-op (returns false)', () async {
      await repo.upsert(alarm(id: 'x'));
      expect(await deleteAlarmAfterFiring(repo, ''), isFalse);
      expect(await repo.getById('x'), isNotNull);
    });

    test('unknown id is a no-op (idempotent across drains)', () async {
      expect(await deleteAlarmAfterFiring(repo, 'never-existed'), isFalse);
      expect(await repo.getAll(), isEmpty);
    });
  });
}
