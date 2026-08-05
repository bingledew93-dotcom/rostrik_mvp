import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/pending_alarm_delete_guard.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

import 'fakes.dart';

/// Fired-one-time cleanup fail-safe. The native AlarmActivity dismiss (and the
/// AlarmAudioService 15-min auto-timeout) append the fired alarm's `appAlarmId`
/// to a ledger; Dart drains it on boot/resume/bg-sync and deletes the ONE-TIME
/// rules so a spent one-shot can't re-project into a daily cycle. Recurring
/// rules recorded in the same ledger are left untouched.
void main() {
  AppAlarm alarm({
    required String id,
    AppAlarmRepeatType repeatType = AppAlarmRepeatType.oneTime,
  }) =>
      AppAlarm(
        id: id,
        minutesOfDay: 7 * 60,
        label: 'One-off',
        repeatType: repeatType,
        linkedShiftType: repeatType == AppAlarmRepeatType.followsRotation
            ? ShiftType.day
            : null,
      );

  group('ledger file read/clear', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('rostrik_adel_');
    });
    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {
        // best-effort temp cleanup.
      }
    });

    void writeLedger(String content) {
      File('${tempDir.path}/$pendingAlarmDeletesFileName')
          .writeAsStringSync(content);
    }

    test('a missing ledger reads as empty, never an error', () {
      expect(readPendingAlarmDeletes(tempDir), isEmpty);
    });

    test('reads one id per line, trimmed and de-duplicated', () {
      writeLedger('a1\n a2 \na1\n\n');
      final ids = readPendingAlarmDeletes(tempDir);
      expect(ids, containsAll(<String>['a1', 'a2']));
      expect(ids, hasLength(2)); // blank dropped, duplicate collapsed
    });

    test('clear removes the file (idempotent when already gone)', () {
      writeLedger('a1\n');
      clearPendingAlarmDeletes(tempDir);
      expect(
        File('${tempDir.path}/$pendingAlarmDeletesFileName').existsSync(),
        isFalse,
      );
      clearPendingAlarmDeletes(tempDir); // no throw on a second clear
    });
  });

  group('applyPendingAlarmDeletesInHive', () {
    late FakeAppAlarmRepository repo;
    setUp(() => repo = FakeAppAlarmRepository());
    tearDown(() => repo.dispose());

    test('deletes one-time rules and leaves recurring ones in place', () async {
      await repo.upsert(alarm(id: 'one'));
      await repo.upsert(
        alarm(id: 'rot', repeatType: AppAlarmRepeatType.followsRotation),
      );
      await repo.upsert(alarm(id: 'wk', repeatType: AppAlarmRepeatType.weekly));

      final deleted = await applyPendingAlarmDeletesInHive(
        alarms: repo,
        // 'rot' and 'wk' are recorded too (native records every fired rule),
        // plus an unknown id — all must be safely skipped.
        appAlarmIds: const ['one', 'rot', 'wk', 'ghost'],
      );

      expect(deleted, 1); // only the one-time alarm
      expect(await repo.getById('one'), isNull);
      expect(await repo.getById('rot'), isNotNull);
      expect(await repo.getById('wk'), isNotNull);
    });

    test('is idempotent — re-applying the same ledger deletes nothing more',
        () async {
      await repo.upsert(alarm(id: 'one'));
      final first =
          await applyPendingAlarmDeletesInHive(alarms: repo, appAlarmIds: const ['one']);
      final second =
          await applyPendingAlarmDeletesInHive(alarms: repo, appAlarmIds: const ['one']);
      expect(first, 1);
      expect(second, 0);
    });
  });
}
