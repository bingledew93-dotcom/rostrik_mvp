import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/hive_shift_repository.dart';

/// Stand-in for the pre-isMuted ShiftAdapter (typeId 1, 6 fields). Lets us
/// write a record in the pre-Phase-3 binary shape so we can verify the
/// real adapter's `defaultValue: false` fallback on read.
class _LegacyShiftAdapter extends TypeAdapter<Shift> {
  @override
  final typeId = 1;

  @override
  Shift read(BinaryReader reader) {
    // Real adapter handles read. We only need write to simulate old data.
    throw UnimplementedError();
  }

  @override
  void write(BinaryWriter writer, Shift obj) {
    writer
      ..writeByte(6) // 6 fields, NOT 7 — no isMuted on the wire
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.startMinutes)
      ..writeByte(4)
      ..write(obj.endMinutes)
      ..writeByte(5)
      ..write(obj.note);
  }
}

void main() {
  late Directory tempDir;
  late Box<Shift> box;
  late HiveShiftRepository repo;
  var boxCounter = 0;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('rostrik_repo_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ShiftTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ShiftAdapter());
    }
  });

  setUp(() async {
    final boxName = 'shifts_${boxCounter++}';
    box = await Hive.openBox<Shift>(boxName);
    repo = HiveShiftRepository(box);
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

  group('upsert + getById', () {
    test('round-trips all fields including note', () async {
      final s = _shift(id: 'a', note: 'first note');
      await repo.upsert(s);
      final loaded = await repo.getById('a');
      expect(loaded, equals(s));
      expect(loaded!.note, 'first note');
    });

    test('round-trips a record with null note', () async {
      await repo.upsert(_shift(id: 'a', note: null));
      final loaded = await repo.getById('a');
      expect(loaded, isNotNull);
      expect(loaded!.note, isNull);
    });

    test('survives every ShiftType round-trip', () async {
      for (final type in ShiftType.values) {
        final id = 'id-${type.name}';
        await repo.upsert(_shift(id: id, type: type));
        final loaded = await repo.getById(id);
        expect(loaded!.type, type);
      }
    });

    test('overwrites an existing record with the same id', () async {
      await repo.upsert(_shift(id: 'a', start: 7 * 60));
      await repo.upsert(_shift(id: 'a', start: 8 * 60));
      final loaded = await repo.getById('a');
      expect(loaded!.startMinutes, 8 * 60);
    });

    test('returns null for an unknown id', () async {
      expect(await repo.getById('missing'), isNull);
    });

    test('round-trips isMuted=true', () async {
      await repo.upsert(_shift(id: 'muted', isMuted: true));
      final loaded = await repo.getById('muted');
      expect(loaded!.isMuted, isTrue);
    });

    test('round-trips isMuted=false', () async {
      await repo.upsert(_shift(id: 'unmuted', isMuted: false));
      final loaded = await repo.getById('unmuted');
      expect(loaded!.isMuted, isFalse);
    });

    test('isMuted survives close/reopen', () async {
      final boxName = box.name;
      await repo.upsert(_shift(id: 'persist', isMuted: true));

      await box.close();
      box = await Hive.openBox<Shift>(boxName);
      repo = HiveShiftRepository(box);

      final loaded = await repo.getById('persist');
      expect(loaded!.isMuted, isTrue);
    });
  });

  group('isMuted backward-compat', () {
    test(
      'records written without field 6 deserialize with isMuted=false',
      () async {
        // Reproduce the pre-Phase-3 binary shape (6 fields, no isMuted byte)
        // by swapping the registered adapter for typeId 1 with a 6-field
        // stub, writing a record, then swapping the real adapter back in
        // before reading. This exercises the generated read path's
        // `fields[6] == null ? false : fields[6] as bool` fallback that
        // backs the @HiveField(6, defaultValue: false) annotation.
        final boxName = 'shifts_legacy_${boxCounter++}';

        // Phase 1 — write with the legacy 6-field adapter.
        Hive.registerAdapter(_LegacyShiftAdapter(), override: true);
        final legacyBox = await Hive.openBox<Shift>(boxName);
        await legacyBox.put(
          'pre-phase3',
          _shift(id: 'pre-phase3', note: 'written before mute existed'),
        );
        await legacyBox.close();

        // Phase 2 — re-register the real (7-field) adapter and read back.
        Hive.registerAdapter(ShiftAdapter(), override: true);
        try {
          final reopened = await Hive.openBox<Shift>(boxName);
          final loaded = reopened.get('pre-phase3');
          expect(loaded, isNotNull);
          expect(loaded!.isMuted, isFalse);
          // Other fields untouched — proves the read advanced cleanly past
          // the missing field rather than corrupting earlier fields.
          expect(loaded.id, 'pre-phase3');
          expect(loaded.note, 'written before mute existed');
          await reopened.deleteFromDisk();
        } finally {
          // Leave the registry in the same state every other test expects.
          Hive.registerAdapter(ShiftAdapter(), override: true);
        }
      },
    );
  });

  group('delete', () {
    test('removes the record', () async {
      await repo.upsert(_shift(id: 'a'));
      await repo.delete('a');
      expect(await repo.getById('a'), isNull);
    });

    test('deleting an unknown id is a no-op', () async {
      await repo.delete('missing'); // should not throw
    });
  });

  group('getInRange', () {
    test('includes shifts within [from, to)', () async {
      final apr30 = DateTime(2026, 4, 30);
      final may1 = DateTime(2026, 5, 1);
      final may2 = DateTime(2026, 5, 2);
      final may3 = DateTime(2026, 5, 3);

      await repo.upsert(_shift(id: 'before', date: apr30));
      await repo.upsert(_shift(id: 'a', date: may1));
      await repo.upsert(_shift(id: 'b', date: may2));
      await repo.upsert(_shift(id: 'on-to', date: may3)); // exclusive bound

      final result = await repo.getInRange(may1, may3);
      expect(result.map((s) => s.id), ['a', 'b']);
    });

    test('normalizes non-midnight bounds to calendar days', () async {
      final may1 = DateTime(2026, 5, 1);
      await repo.upsert(_shift(id: 'a', date: may1));
      final result = await repo.getInRange(
        DateTime(2026, 5, 1, 23, 59),
        DateTime(2026, 5, 2, 1),
      );
      expect(result.map((s) => s.id), ['a']);
    });

    test('sorts by date then by startMinutes', () async {
      final may1 = DateTime(2026, 5, 1);
      final may2 = DateTime(2026, 5, 2);

      await repo.upsert(_shift(id: 'b', date: may1, start: 14 * 60));
      await repo.upsert(_shift(id: 'a', date: may1, start: 7 * 60));
      await repo.upsert(_shift(id: 'c', date: may2, start: 0));

      final result = await repo.getInRange(
        may1,
        may2.add(const Duration(days: 1)),
      );
      expect(result.map((s) => s.id), ['a', 'b', 'c']);
    });

    test('empty range returns an empty list', () async {
      final result = await repo.getInRange(
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 2),
      );
      expect(result, isEmpty);
    });

    test('inverted range (to < from) returns empty', () async {
      final may1 = DateTime(2026, 5, 1);
      await repo.upsert(_shift(id: 'a', date: may1));
      final result = await repo.getInRange(may1, may1);
      expect(result, isEmpty);
    });
  });

  group('getNextAfter', () {
    test('returns the next shift strictly after now', () async {
      final may1 = DateTime(2026, 5, 1);
      await repo.upsert(
        _shift(id: 'a', date: may1, start: 7 * 60, end: 15 * 60),
      );
      await repo.upsert(
        _shift(id: 'b', date: may1, start: 15 * 60, end: 23 * 60),
      );

      final next = await repo.getNextAfter(DateTime(2026, 5, 1, 10));
      expect(next!.id, 'b');
    });

    test('returns null when no future shifts exist', () async {
      final may1 = DateTime(2026, 5, 1);
      await repo.upsert(
        _shift(id: 'a', date: may1, start: 7 * 60, end: 15 * 60),
      );
      expect(await repo.getNextAfter(DateTime(2026, 5, 2)), isNull);
    });

    test('compares by absolute startDateTime so day-2 day shift '
        'beats day-1 night shift that already started', () async {
      final may1 = DateTime(2026, 5, 1);
      // Night shift starting 22:00 on may 1 — already started by 23:00.
      await repo.upsert(_shift(
        id: 'night',
        date: may1,
        type: ShiftType.night,
        start: 22 * 60,
        end: 6 * 60,
      ));
      // Day shift starting 07:00 on may 2 — next upcoming.
      await repo.upsert(_shift(
        id: 'day-next',
        date: may1.add(const Duration(days: 1)),
        type: ShiftType.day,
        start: 7 * 60,
        end: 15 * 60,
      ));

      final next = await repo.getNextAfter(DateTime(2026, 5, 1, 23));
      expect(next!.id, 'day-next');
    });

    test('a shift starting exactly at `now` is excluded (strict >)', () async {
      final may1 = DateTime(2026, 5, 1);
      await repo.upsert(
        _shift(id: 'a', date: may1, start: 7 * 60, end: 15 * 60),
      );
      final atStart = DateTime(2026, 5, 1, 7);
      expect(await repo.getNextAfter(atStart), isNull);
    });

    test('returns OFF shifts too — repository is policy-free', () async {
      final may1 = DateTime(2026, 5, 1);
      await repo.upsert(_shift(
        id: 'off',
        date: may1,
        type: ShiftType.off,
        start: 0,
        end: 0,
      ));
      final next = await repo.getNextAfter(DateTime(2026, 4, 30));
      expect(next!.id, 'off');
    });
  });

  group('persistence across box reopen', () {
    test('shifts survive close/reopen', () async {
      final boxName = box.name;
      await repo.upsert(_shift(id: 'persist', note: 'should survive'));

      await box.close();
      box = await Hive.openBox<Shift>(boxName);
      repo = HiveShiftRepository(box);

      final loaded = await repo.getById('persist');
      expect(loaded, isNotNull);
      expect(loaded!.note, 'should survive');
    });

    test('date is still normalized after reopen', () async {
      final boxName = box.name;
      await repo.upsert(_shift(
        id: 'a',
        date: DateTime(2026, 5, 1, 14, 30),
      ));

      await box.close();
      box = await Hive.openBox<Shift>(boxName);
      repo = HiveShiftRepository(box);

      final loaded = await repo.getById('a');
      expect(loaded!.date, DateTime(2026, 5, 1));
    });
  });

  group('watchInRange', () {
    test('emits initial snapshot then again after upsert', () async {
      final may1 = DateTime(2026, 5, 1);
      final may2 = DateTime(2026, 5, 2);

      final emissions = <List<Shift>>[];
      final sub = repo.watchInRange(may1, may2).listen(emissions.add);

      // Allow initial async getInRange to complete.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, hasLength(1));
      expect(emissions.first, isEmpty);

      await repo.upsert(_shift(id: 'a', date: may1));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last.map((s) => s.id), ['a']);

      await sub.cancel();
    });

    test('emits a fresh snapshot after delete', () async {
      final may1 = DateTime(2026, 5, 1);
      final may2 = DateTime(2026, 5, 2);
      await repo.upsert(_shift(id: 'a', date: may1));

      final emissions = <List<Shift>>[];
      final sub = repo.watchInRange(may1, may2).listen(emissions.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, hasLength(1));

      await repo.delete('a');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.last, isEmpty);
      await sub.cancel();
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
