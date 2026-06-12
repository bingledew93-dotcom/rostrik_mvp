import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_sync_service.dart'
    show noShiftPayloadSentinel;
import 'package:rostrik_mvp/alarms/pending_dismissal_guard.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

import 'fakes.dart';

/// Native dismiss fail-safe (Zombie-UI hardening, round 2).
///
/// The Pixel-9 field failure: the OS reaped the FLN background isolate
/// before its Hive write, so the dismissal was lost entirely. The fail-safe
/// is a flat ledger file written by the isolate's FIRST instruction
/// (synchronous + flushed — in the kernel before the reap can matter), read
/// and cleared natively by Kotlin, and replayed into Hive on boot. These
/// tests pin both halves the Dart side owns: the ledger file semantics and
/// the idempotent Hive replay.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('rostrik_guard_');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // best-effort temp cleanup.
    }
  });

  group('pending-dismissals ledger file', () {
    test('mark → read round-trips the shift id', () {
      markPendingDismissal(tempDir, 'shift-a');
      expect(readPendingDismissals(tempDir), ['shift-a']);
    });

    test('the write is already durable on disk when mark returns', () {
      // The whole point of the fail-safe: a synchronous flushed write means
      // the OS reaping the isolate immediately after cannot lose the entry.
      // Re-read through a FRESH File handle straight off the filesystem.
      markPendingDismissal(tempDir, 'shift-a');
      final onDisk =
          File('${tempDir.path}/$pendingDismissalsFileName').readAsStringSync();
      expect(onDisk, contains('shift-a'));
    });

    test('marks accumulate across taps and read de-duplicates', () {
      markPendingDismissal(tempDir, 'shift-a');
      markPendingDismissal(tempDir, 'shift-b');
      markPendingDismissal(tempDir, 'shift-a'); // rapid double-tap
      final ids = readPendingDismissals(tempDir);
      expect(ids, hasLength(2));
      expect(ids, containsAll(['shift-a', 'shift-b']));
    });

    test('the NONE sentinel and empty ids are never recorded', () {
      markPendingDismissal(tempDir, noShiftPayloadSentinel);
      markPendingDismissal(tempDir, '');
      expect(readPendingDismissals(tempDir), isEmpty);
      expect(
        File('${tempDir.path}/$pendingDismissalsFileName').existsSync(),
        isFalse,
        reason: 'nothing to record — no ledger file should even exist',
      );
    });

    test('a missing ledger reads as empty, never an error', () {
      expect(readPendingDismissals(tempDir), isEmpty);
    });

    test('clear deletes the ledger; clearing again is a no-op', () {
      markPendingDismissal(tempDir, 'shift-a');
      clearPendingDismissals(tempDir);
      expect(readPendingDismissals(tempDir), isEmpty);
      clearPendingDismissals(tempDir); // must not throw
    });
  });

  group('ackPendingDismissalsInHive — the boot-time replay', () {
    late FakeShiftRepository shifts;

    setUp(() {
      shifts = FakeShiftRepository();
    });

    Shift mkShift({
      String id = 's1',
      bool isAcknowledged = false,
      DateTime? snoozedUntil,
    }) =>
        Shift(
          id: id,
          date: DateTime(2026, 6, 11),
          type: ShiftType.day,
          startMinutes: 7 * 60,
          endMinutes: 15 * 60,
          isAcknowledged: isAcknowledged,
          snoozedUntil: snoozedUntil,
        );

    test('acks the shift and clears its snooze — the write the reaped '
        'isolate never made', () async {
      await shifts.upsert(
        mkShift(snoozedUntil: DateTime(2026, 6, 11, 6, 9)),
      );

      final acked = await ackPendingDismissalsInHive(
        shifts: shifts,
        shiftIds: const ['s1'],
      );

      expect(acked, 1);
      final stored = await shifts.getById('s1');
      expect(stored!.isAcknowledged, isTrue);
      expect(stored.snoozedUntil, isNull);
    });

    test('replaying the same ledger twice is idempotent', () async {
      await shifts.upsert(mkShift());
      expect(
        await ackPendingDismissalsInHive(shifts: shifts, shiftIds: ['s1']),
        1,
      );
      expect(
        await ackPendingDismissalsInHive(shifts: shifts, shiftIds: ['s1']),
        0,
        reason: 'already-acked shifts must not be rewritten',
      );
    });

    test('vanished shifts, sentinels and empty ids are skipped safely',
        () async {
      await shifts.upsert(mkShift());
      final acked = await ackPendingDismissalsInHive(
        shifts: shifts,
        shiftIds: ['ghost', noShiftPayloadSentinel, '', 's1'],
      );
      expect(acked, 1);
      expect((await shifts.getById('s1'))!.isAcknowledged, isTrue);
    });

    test('the replayed state satisfies the wake-route gate predicate',
        () async {
      // End-to-end intent: ledger replay must be sufficient for
      // Shift.isAlarmHandledAt to suppress the zombie WakeUpScreen.
      await shifts.upsert(mkShift());
      await ackPendingDismissalsInHive(shifts: shifts, shiftIds: ['s1']);
      final stored = await shifts.getById('s1');
      expect(stored!.isAlarmHandledAt(DateTime(2026, 6, 11, 9, 0)), isTrue);
    });
  });
}
