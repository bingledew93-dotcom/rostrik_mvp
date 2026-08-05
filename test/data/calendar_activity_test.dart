import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:rostrik_mvp/data/models/calendar_activity.dart';
import 'package:rostrik_mvp/data/repositories/hive_calendar_activity_repository.dart';

void main() {
  CalendarActivity mk({
    String id = 'a1',
    DateTime? date,
    String title = 'Dentist',
    ActivityKind kind = ActivityKind.event,
    String? note,
    int? timeMinutes,
    DateTime? reminderAt,
    bool isDone = false,
  }) =>
      CalendarActivity(
        id: id,
        date: date ?? DateTime(2026, 7, 22),
        title: title,
        kind: kind,
        note: note,
        timeMinutes: timeMinutes,
        reminderAt: reminderAt,
        isDone: isDone,
      );

  group('CalendarActivity model', () {
    test('normalises date to midnight and derives all-day / reminder flags', () {
      final a = mk(date: DateTime(2026, 7, 22, 9, 30));
      expect(a.date, DateTime(2026, 7, 22));
      expect(a.isAllDay, isTrue);
      expect(a.hasReminder, isFalse);

      final timed = mk(timeMinutes: 9 * 60, reminderAt: DateTime(2026, 7, 22, 8));
      expect(timed.isAllDay, isFalse);
      expect(timed.hasReminder, isTrue);
    });

    test('an out-of-range timeMinutes asserts', () {
      expect(() => mk(timeMinutes: 1440), throwsA(isA<AssertionError>()));
      expect(() => mk(timeMinutes: -1), throwsA(isA<AssertionError>()));
      expect(() => mk(timeMinutes: 0), returnsNormally);
      expect(() => mk(timeMinutes: 1439), returnsNormally);
    });

    test('copyWith clear flags reset nullable fields', () {
      final a = mk(
        note: 'bring x-rays',
        timeMinutes: 9 * 60,
        reminderAt: DateTime(2026, 7, 22, 8),
      );
      final cleared =
          a.copyWith(clearNote: true, clearTime: true, clearReminder: true);
      expect(cleared.note, isNull);
      expect(cleared.timeMinutes, isNull);
      expect(cleared.reminderAt, isNull);
      // Untouched fields survive.
      expect(cleared.title, 'Dentist');
    });

    test('equality + hashCode span every field', () {
      expect(mk(), mk());
      expect(mk().hashCode, mk().hashCode);
      expect(mk(kind: ActivityKind.task) == mk(), isFalse);
      expect(mk(isDone: true) == mk(), isFalse);
    });
  });

  group('CalendarActivity Hive round-trip + repository', () {
    late Directory tempDir;
    var boxCounter = 0;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('rostrik_activity_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(CalendarActivityAdapter());
      }
      if (!Hive.isAdapterRegistered(9)) {
        Hive.registerAdapter(ActivityKindAdapter());
      }
    });

    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<HiveCalendarActivityRepository> openRepo() async {
      final box = await Hive.openBox<CalendarActivity>('activities_${boxCounter++}');
      return HiveCalendarActivityRepository(box);
    }

    test('adapter round-trips every field, including a set reminder', () async {
      final repo = await openRepo();
      final a = mk(
        kind: ActivityKind.birthday,
        note: 'turns 30',
        timeMinutes: 12 * 60,
        reminderAt: DateTime(2026, 7, 21, 9),
        isDone: false,
      );
      await repo.upsert(a);
      final read = await repo.getById('a1');
      expect(read, a);
      expect(read!.kind, ActivityKind.birthday);
      expect(read.reminderAt, DateTime(2026, 7, 21, 9));
    });

    test('upsert updates in place; delete removes; getAll snapshots', () async {
      final repo = await openRepo();
      await repo.upsert(mk(id: 'x', title: 'first'));
      await repo.upsert(mk(id: 'x', title: 'second')); // same id → update
      await repo.upsert(mk(id: 'y', kind: ActivityKind.task));

      expect((await repo.getById('x'))!.title, 'second');
      expect(await repo.getAll(), hasLength(2));

      await repo.delete('x');
      expect(await repo.getById('x'), isNull);
      expect(await repo.getAll(), hasLength(1));
      // Deleting an unknown id is a no-op.
      await repo.delete('ghost');
    });

    test('watch emits the current snapshot then updates on change', () async {
      final repo = await openRepo();
      final emissions = <int>[];
      final sub = repo.watch().listen((list) => emissions.add(list.length));
      await Future<void>.delayed(Duration.zero); // initial emit

      await repo.upsert(mk(id: 'w1'));
      await Future<void>.delayed(Duration.zero);
      await repo.delete('w1');
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(emissions.first, 0);
      expect(emissions, contains(1));
      expect(emissions.last, 0);
    });
  });
}
