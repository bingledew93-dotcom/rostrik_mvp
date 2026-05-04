import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:rostrik_mvp/alarms/notification_id_map.dart';

void main() {
  late Directory tempDir;
  late Box<int> box;
  late HiveNotificationIdMap idMap;
  var boxCounter = 0;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('rostrik_idmap_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    box = await Hive.openBox<int>('idmap_${boxCounter++}');
    idMap = HiveNotificationIdMap(box);
  });

  tearDown(() async {
    if (box.isOpen) {
      await box.deleteFromDisk();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('idFor — allocation', () {
    test('first call returns 1', () async {
      expect(await idMap.idFor('shift-a'), 1);
    });

    test('subsequent distinct shifts get monotonically increasing ints', () async {
      expect(await idMap.idFor('a'), 1);
      expect(await idMap.idFor('b'), 2);
      expect(await idMap.idFor('c'), 3);
    });

    test('same shift returns the same int across calls', () async {
      final first = await idMap.idFor('shift-a');
      expect(await idMap.idFor('shift-a'), first);
      expect(await idMap.idFor('shift-a'), first);
    });

    test('intermixed lookups remain stable per shift', () async {
      final a1 = await idMap.idFor('a');
      final b1 = await idMap.idFor('b');
      final a2 = await idMap.idFor('a');
      final c1 = await idMap.idFor('c');
      final b2 = await idMap.idFor('b');
      expect(a2, a1);
      expect(b2, b1);
      expect({a1, b1, c1}.length, 3); // all distinct
    });
  });

  group('release', () {
    test('forgets the mapping', () async {
      await idMap.idFor('a');
      expect(idMap.has('a'), isTrue);
      await idMap.release('a');
      expect(idMap.has('a'), isFalse);
    });

    test('releasing then re-allocating produces a NEW id (counter never rewinds)', () async {
      final original = await idMap.idFor('a');
      await idMap.release('a');
      final reallocated = await idMap.idFor('a');
      expect(reallocated, isNot(original));
      expect(reallocated, greaterThan(original));
    });

    test('releasing an unknown id is a no-op', () async {
      await idMap.release('never-seen'); // must not throw
    });
  });

  group('has', () {
    test('false for never-seen ids', () {
      expect(idMap.has('nope'), isFalse);
    });

    test('true after idFor', () async {
      await idMap.idFor('a');
      expect(idMap.has('a'), isTrue);
    });

    test('the reserved counter key is never reported as present', () async {
      await idMap.idFor('a'); // bumps the counter, writing __counter__
      expect(idMap.has('__counter__'), isFalse);
    });
  });

  group('persistence', () {
    test('mappings survive box close + reopen', () async {
      final boxName = box.name;
      final originalA = await idMap.idFor('a');
      final originalB = await idMap.idFor('b');

      await box.close();
      box = await Hive.openBox<int>(boxName);
      idMap = HiveNotificationIdMap(box);

      expect(await idMap.idFor('a'), originalA);
      expect(await idMap.idFor('b'), originalB);
    });

    test('counter persists — new ids after reopen continue past previous max', () async {
      final boxName = box.name;
      await idMap.idFor('a');
      await idMap.idFor('b'); // counter is now 2

      await box.close();
      box = await Hive.openBox<int>(boxName);
      idMap = HiveNotificationIdMap(box);

      expect(await idMap.idFor('c'), 3);
    });
  });
}
