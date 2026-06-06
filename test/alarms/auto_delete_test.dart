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

  group('shouldAutoDeleteOnDismiss', () {
    test('true only for an auto-delete one-time alarm', () {
      expect(shouldAutoDeleteOnDismiss(alarm()), isTrue);
    });
    test('false when the flag is off', () {
      expect(shouldAutoDeleteOnDismiss(alarm(autoDelete: false)), isFalse);
    });
    test('false for non-one-time repeat types even if flagged', () {
      expect(
        shouldAutoDeleteOnDismiss(
          alarm(repeatType: AppAlarmRepeatType.weekly),
        ),
        isFalse,
      );
      expect(
        shouldAutoDeleteOnDismiss(
          alarm(repeatType: AppAlarmRepeatType.followsRotation),
        ),
        isFalse,
      );
    });
    test('false for null', () {
      expect(shouldAutoDeleteOnDismiss(null), isFalse);
    });
  });

  group('deleteAlarmIfAutoDelete', () {
    late FakeAppAlarmRepository repo;
    setUp(() => repo = FakeAppAlarmRepository());
    tearDown(() => repo.dispose());

    test('deletes an eligible one-time auto-delete alarm by id', () async {
      await repo.upsert(alarm(id: 'gone'));
      await deleteAlarmIfAutoDelete(repo, 'gone');
      expect(await repo.getById('gone'), isNull);
    });

    test('leaves a non-auto-delete alarm in place', () async {
      await repo.upsert(alarm(id: 'stay', autoDelete: false));
      await deleteAlarmIfAutoDelete(repo, 'stay');
      expect(await repo.getById('stay'), isNotNull);
    });

    test('leaves a follows-rotation alarm in place', () async {
      await repo.upsert(
        alarm(id: 'fr', repeatType: AppAlarmRepeatType.followsRotation),
      );
      await deleteAlarmIfAutoDelete(repo, 'fr');
      expect(await repo.getById('fr'), isNotNull);
    });

    test('empty id is a no-op', () async {
      await repo.upsert(alarm(id: 'x'));
      await deleteAlarmIfAutoDelete(repo, '');
      expect(await repo.getById('x'), isNotNull);
    });

    test('unknown id is a no-op (idempotent across dismiss paths)', () async {
      await deleteAlarmIfAutoDelete(repo, 'never-existed');
      expect(await repo.getAll(), isEmpty);
    });
  });
}
