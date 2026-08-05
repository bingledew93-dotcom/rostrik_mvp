import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:rostrik_mvp/alarms/alarm_sync_service.dart'
    show noShiftPayloadSentinel;
import 'package:rostrik_mvp/alarms/one_off_snooze_store.dart';
import 'package:rostrik_mvp/alarms/pending_snooze_guard.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

import 'fakes.dart';

/// Native snooze fail-safe. The native AlarmActivity re-arms the alarm itself
/// and records `<shiftId>|<appAlarmId>|<untilMillis>` to a ledger; Dart replays
/// it on resume/boot — setting `Shift.snoozedUntil` for shift alarms, and the
/// settings-box one-off map (keyed by AppAlarm id) for shift-less 'NONE' alarms,
/// so the reconcile keeps the re-armed alarm instead of cancelling it.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('rostrik_snooze_');
  });
  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // best-effort temp cleanup.
    }
  });

  void writeLedger(String content) {
    File('${tempDir.path}/$pendingSnoozesFileName').writeAsStringSync(content);
  }

  final until = DateTime(2026, 6, 15, 6, 9);
  final untilMs = until.millisecondsSinceEpoch;
  final now = DateTime(2026, 6, 15, 5, 0);

  group('pending-snoozes ledger parser', () {
    test('parses the 3-field shiftId|appAlarmId|millis form', () {
      writeLedger('s1|app1|$untilMs\n');
      final parsed = readPendingSnoozes(tempDir).single;
      expect(parsed.shiftId, 's1');
      expect(parsed.appAlarmId, 'app1');
      expect(parsed.until, until);
    });

    test('tolerates the legacy 2-field shiftId|millis form (no appAlarmId)', () {
      writeLedger('s1|$untilMs\n');
      final parsed = readPendingSnoozes(tempDir).single;
      expect(parsed.shiftId, 's1');
      expect(parsed.appAlarmId, '');
      expect(parsed.until, until);
    });

    test('skips malformed lines, keeps the good ones', () {
      writeLedger('garbage\nNONE|app1|$untilMs\ns2|app2|notanint\n');
      final parsed = readPendingSnoozes(tempDir);
      expect(parsed, hasLength(1));
      expect(parsed.single.appAlarmId, 'app1');
    });

    test('a missing ledger reads as empty, never an error', () {
      expect(readPendingSnoozes(tempDir), isEmpty);
    });
  });

  group('applyPendingSnoozesInHive — shift path', () {
    late FakeShiftRepository shifts;
    setUp(() => shifts = FakeShiftRepository());

    Shift mk({
      String id = 's1',
      bool ack = false,
      DateTime? snoozedUntil,
      List<String> dismissedAlarmIds = const [],
    }) =>
        Shift(
          id: id,
          date: DateTime(2026, 6, 15),
          type: ShiftType.day,
          startMinutes: 7 * 60,
          endMinutes: 15 * 60,
          isAcknowledged: ack,
          snoozedUntil: snoozedUntil,
          dismissedAlarmIds: dismissedAlarmIds,
        );

    test('sets snoozedUntil on the shift', () async {
      await shifts.upsert(mk());
      final applied = await applyPendingSnoozesInHive(
        shifts: shifts,
        snoozes: [PendingSnooze('s1', '', until)],
        now: now,
      );
      expect(applied, 1);
      expect((await shifts.getById('s1'))!.snoozedUntil, until);
    });

    test('latest until per shift wins', () async {
      await shifts.upsert(mk());
      final later = until.add(const Duration(minutes: 5));
      await applyPendingSnoozesInHive(
        shifts: shifts,
        snoozes: [
          PendingSnooze('s1', '', until),
          PendingSnooze('s1', '', later),
        ],
        now: now,
      );
      expect((await shifts.getById('s1'))!.snoozedUntil, later);
    });

    test('an elapsed snooze and an acknowledged shift are skipped', () async {
      await shifts.upsert(mk(id: 'past'));
      await shifts.upsert(mk(id: 'ackd', ack: true));
      final applied = await applyPendingSnoozesInHive(
        shifts: shifts,
        snoozes: [
          PendingSnooze('past', '', DateTime(2026, 6, 15, 4, 0)), // before now
          PendingSnooze('ackd', '', until),
        ],
        now: now,
      );
      expect(applied, 0);
      expect((await shifts.getById('past'))!.snoozedUntil, isNull);
    });

    test('dismiss-wins is PER-RING: a snooze whose own alarm was dismissed is '
        'stale, but a sibling alarm\'s snooze still applies', () async {
      // The dismissal drain runs before the snooze drain and recorded
      // alarm-1's dismissal on this shift. alarm-1's snooze line is now stale
      // (dismiss is final for that ring); alarm-2's snooze must still land —
      // the whole-shift blanket skip is exactly what the per-occurrence
      // dismissal layer removed.
      await shifts.upsert(mk(dismissedAlarmIds: const ['alarm-1']));
      final applied = await applyPendingSnoozesInHive(
        shifts: shifts,
        snoozes: [PendingSnooze('s1', 'alarm-1', until)],
        now: now,
      );
      expect(applied, 0);
      expect((await shifts.getById('s1'))!.snoozedUntil, isNull);

      final siblingUntil = until.add(const Duration(minutes: 12));
      final appliedSibling = await applyPendingSnoozesInHive(
        shifts: shifts,
        snoozes: [PendingSnooze('s1', 'alarm-2', siblingUntil)],
        now: now,
      );
      expect(appliedSibling, 1);
      expect((await shifts.getById('s1'))!.snoozedUntil, siblingUntil);
    });
  });

  group('one-off snooze store (Hive-backed)', () {
    late FakeShiftRepository shifts;

    setUp(() async {
      shifts = FakeShiftRepository();
      Hive.init(tempDir.path);
      await Hive.openBox('settings');
    });
    tearDown(() async {
      await Hive.close();
    });

    test('apply routes a NONE / shift-less snooze to the map by appAlarmId',
        () async {
      final applied = await applyPendingSnoozesInHive(
        shifts: shifts,
        snoozes: [PendingSnooze(noShiftPayloadSentinel, 'alarm-x', until)],
        now: now,
      );
      expect(applied, 1);
      expect(readOneOffSnoozes(now: now)['alarm-x'], until);
    });

    test('upsert keeps the latest and prunes elapsed entries on read', () async {
      await upsertOneOffSnooze('a', until, now: now);
      await upsertOneOffSnooze('a', until.add(const Duration(minutes: 3)),
          now: now);
      await upsertOneOffSnooze('stale', DateTime(2026, 6, 15, 4, 0), now: now);
      final map = readOneOffSnoozes(now: now);
      expect(map['a'], until.add(const Duration(minutes: 3)));
      expect(map.containsKey('stale'), isFalse); // elapsed → pruned
    });
  });
}
