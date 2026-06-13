import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/hive_app_alarm_repository.dart';

/// Regression coverage for the beta-blocker alarm-deletion bug: a deleted alarm
/// must (a) disappear from the watch() stream and (b) STAY gone after the box is
/// closed and reopened (the "returns on restart" symptom). The repo flushes on
/// delete/upsert so the on-disk state matches the in-memory state immediately.
void main() {
  late Directory tempDir;
  late Box<AppAlarm> box;
  late HiveAppAlarmRepository repo;
  var boxCounter = 0;
  late String boxName;

  AppAlarm alarm(String id, {ShiftType type = ShiftType.day}) => AppAlarm(
        id: id,
        minutesOfDay: 6 * 60,
        label: '$id wake-up',
        repeatType: AppAlarmRepeatType.followsRotation,
        linkedShiftType: type,
      );

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('rostrik_alarm_repo_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ShiftTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(AppAlarmRepeatTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(AppAlarmAdapter());
    }
  });

  setUp(() async {
    boxName = 'alarms_${boxCounter++}';
    box = await Hive.openBox<AppAlarm>(boxName);
    repo = HiveAppAlarmRepository(box);
  });

  tearDown(() async {
    if (box.isOpen) await box.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  group('delete', () {
    test('removes the record (getById null, absent from getAll)', () async {
      await repo.upsert(alarm('a'));
      await repo.upsert(alarm('b'));

      await repo.delete('a');

      expect(await repo.getById('a'), isNull);
      expect((await repo.getAll()).map((x) => x.id), ['b']);
    });

    test('is idempotent — deleting an unknown id is a no-op', () async {
      await repo.upsert(alarm('a'));
      await repo.delete('ghost');
      expect((await repo.getAll()).map((x) => x.id), ['a']);
    });

    test('STAYS deleted after the box is closed and reopened (flush durability)',
        () async {
      await repo.upsert(alarm('a'));
      await repo.upsert(alarm('b'));
      await repo.delete('a');

      // Simulate an app restart: close the box and reopen the SAME on-disk box.
      await box.close();
      box = await Hive.openBox<AppAlarm>(boxName);
      final reopened = HiveAppAlarmRepository(box);

      // The deleted alarm must not resurrect from disk.
      expect((await reopened.getAll()).map((x) => x.id), ['b']);
      expect(await reopened.getById('a'), isNull);
    });
  });

  group('watch', () {
    test('emits initial snapshot then a shorter one after delete', () async {
      await repo.upsert(alarm('a'));
      await repo.upsert(alarm('b'));

      final emissions = <List<AppAlarm>>[];
      final sub = repo.watch().listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.last.map((x) => x.id).toSet(), {'a', 'b'});

      await repo.delete('a');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.last.map((x) => x.id), ['b']);
      await sub.cancel();
    });
  });
}
