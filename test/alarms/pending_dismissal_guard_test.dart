import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_sync_service.dart'
    show noShiftPayloadSentinel;
import 'package:rostrik_mvp/alarms/pending_dismissal_guard.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

import 'fakes.dart';

/// Native dismiss fail-safe (Zombie-UI hardening, round 2) + the
/// PER-OCCURRENCE dismissal contract.
///
/// The Pixel-9 field failure: the OS reaped the FLN background isolate
/// before its Hive write, so the dismissal was lost entirely. The fail-safe
/// is a flat ledger file written synchronously + flushed (in the kernel
/// before the reap can matter), read and cleared natively by Kotlin, and
/// replayed into Hive on boot.
///
/// Round 3 (the blanket-cancel bug): a ledger entry now carries the ring's
/// owning `appAlarmId` (`<shiftId>|<appAlarmId>`), and the replay records it
/// in `Shift.dismissedAlarmIds` instead of stamping the whole-shift
/// `isAcknowledged` — so dismissing the first of a shift's several alarms
/// can never disarm the rest. A legacy bare `<shiftId>` line still degrades
/// to the whole-shift ack.
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
    test('mark → read round-trips the (shiftId, appAlarmId) pair', () {
      markPendingDismissal(tempDir, 'shift-a', appAlarmId: 'alarm-1');
      final entries = readPendingDismissals(tempDir);
      expect(entries, hasLength(1));
      expect(entries.single.shiftId, 'shift-a');
      expect(entries.single.appAlarmId, 'alarm-1');
      expect(entries.single.isTargeted, isTrue);
    });

    test('a mark without an alarm id round-trips as a legacy blanket entry',
        () {
      markPendingDismissal(tempDir, 'shift-a');
      final entries = readPendingDismissals(tempDir);
      expect(entries.single.shiftId, 'shift-a');
      expect(entries.single.isTargeted, isFalse);
    });

    test('the write is already durable on disk when mark returns', () {
      // The whole point of the fail-safe: a synchronous flushed write means
      // the OS reaping the isolate immediately after cannot lose the entry.
      // Re-read through a FRESH File handle straight off the filesystem.
      markPendingDismissal(tempDir, 'shift-a', appAlarmId: 'alarm-1');
      final onDisk =
          File('${tempDir.path}/$pendingDismissalsFileName').readAsStringSync();
      expect(onDisk, contains('shift-a|alarm-1'));
    });

    test('marks accumulate across taps and read de-duplicates per occurrence',
        () {
      markPendingDismissal(tempDir, 'shift-a', appAlarmId: 'alarm-1');
      markPendingDismissal(tempDir, 'shift-b', appAlarmId: 'alarm-1');
      // Same shift, DIFFERENT alarm — a distinct occurrence, must survive.
      markPendingDismissal(tempDir, 'shift-a', appAlarmId: 'alarm-2');
      // Rapid double-tap — an exact duplicate, must collapse.
      markPendingDismissal(tempDir, 'shift-a', appAlarmId: 'alarm-1');
      final entries = readPendingDismissals(tempDir);
      expect(entries, hasLength(3));
      expect(
        entries.map((e) => '${e.shiftId}|${e.appAlarmId}'),
        containsAll(['shift-a|alarm-1', 'shift-b|alarm-1', 'shift-a|alarm-2']),
      );
    });

    test('the NONE sentinel and empty ids are never recorded', () {
      markPendingDismissal(tempDir, noShiftPayloadSentinel,
          appAlarmId: 'alarm-1');
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
      markPendingDismissal(tempDir, 'shift-a', appAlarmId: 'alarm-1');
      clearPendingDismissals(tempDir);
      expect(readPendingDismissals(tempDir), isEmpty);
      clearPendingDismissals(tempDir); // must not throw
    });
  });

  group('parsePendingDismissalLine — the shared channel/file decoder', () {
    test('decodes both wire shapes and rejects junk', () {
      final targeted = parsePendingDismissalLine('s1|a1');
      expect(targeted!.shiftId, 's1');
      expect(targeted.appAlarmId, 'a1');

      final legacy = parsePendingDismissalLine('s1');
      expect(legacy!.shiftId, 's1');
      expect(legacy.isTargeted, isFalse);

      expect(parsePendingDismissalLine(''), isNull);
      expect(parsePendingDismissalLine('   '), isNull);
      expect(parsePendingDismissalLine(noShiftPayloadSentinel), isNull);
      expect(parsePendingDismissalLine('|a1'), isNull,
          reason: 'an empty shiftId cannot be resolved to a row');
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
      List<String> dismissedAlarmIds = const [],
    }) =>
        Shift(
          id: id,
          date: DateTime(2026, 6, 11),
          type: ShiftType.day,
          startMinutes: 7 * 60,
          endMinutes: 15 * 60,
          isAcknowledged: isAcknowledged,
          snoozedUntil: snoozedUntil,
          dismissedAlarmIds: dismissedAlarmIds,
        );

    test('a targeted entry records ONLY its ring — the whole-shift ack stays '
        'untouched (the blanket-cancel regression)', () async {
      await shifts.upsert(mkShift());

      final acked = await ackPendingDismissalsInHive(
        shifts: shifts,
        dismissals: const [PendingDismissal('s1', 'alarm-1')],
      );

      expect(acked, 1);
      final stored = await shifts.getById('s1');
      expect(stored!.dismissedAlarmIds, ['alarm-1']);
      expect(stored.isAcknowledged, isFalse,
          reason: 'a per-ring dismissal must never blanket-ack the shift — '
              'that is exactly what cancelled the sibling alarms');
    });

    test('two targeted entries for the same shift accumulate both rings',
        () async {
      await shifts.upsert(mkShift());
      final acked = await ackPendingDismissalsInHive(
        shifts: shifts,
        dismissals: const [
          PendingDismissal('s1', 'alarm-1'),
          PendingDismissal('s1', 'alarm-2'),
        ],
      );
      expect(acked, 2);
      expect((await shifts.getById('s1'))!.dismissedAlarmIds,
          containsAll(['alarm-1', 'alarm-2']));
    });

    test('a targeted entry leaves snoozedUntil alone — it may belong to a '
        'sibling alarm\'s still-active snooze', () async {
      final siblingSnooze = DateTime(2026, 6, 11, 6, 30);
      await shifts.upsert(mkShift(snoozedUntil: siblingSnooze));
      await ackPendingDismissalsInHive(
        shifts: shifts,
        dismissals: const [PendingDismissal('s1', 'alarm-1')],
      );
      expect((await shifts.getById('s1'))!.snoozedUntil, siblingSnooze);
    });

    test('a LEGACY entry (no alarm identity) still whole-shift acks and '
        'clears the snooze — the write the reaped isolate never made',
        () async {
      await shifts.upsert(
        mkShift(snoozedUntil: DateTime(2026, 6, 11, 6, 9)),
      );

      final acked = await ackPendingDismissalsInHive(
        shifts: shifts,
        dismissals: const [PendingDismissal('s1', '')],
      );

      expect(acked, 1);
      final stored = await shifts.getById('s1');
      expect(stored!.isAcknowledged, isTrue);
      expect(stored.snoozedUntil, isNull);
    });

    test('replaying the same ledger twice is idempotent (both shapes)',
        () async {
      await shifts.upsert(mkShift());
      const batch = [
        PendingDismissal('s1', 'alarm-1'),
        PendingDismissal('s1', ''),
      ];
      expect(
        await ackPendingDismissalsInHive(shifts: shifts, dismissals: batch),
        2,
      );
      expect(
        await ackPendingDismissalsInHive(shifts: shifts, dismissals: batch),
        0,
        reason: 'already-recorded rings / already-acked shifts must not be '
            'rewritten',
      );
    });

    test('vanished shifts, sentinels and empty ids are skipped safely',
        () async {
      await shifts.upsert(mkShift());
      final acked = await ackPendingDismissalsInHive(
        shifts: shifts,
        dismissals: const [
          PendingDismissal('ghost', 'alarm-1'),
          PendingDismissal(noShiftPayloadSentinel, 'alarm-1'),
          PendingDismissal('', ''),
          PendingDismissal('s1', 'alarm-1'),
        ],
      );
      expect(acked, 1);
      expect((await shifts.getById('s1'))!.dismissedAlarmIds, ['alarm-1']);
    });

    test('the legacy replayed state satisfies the wake-route gate predicate',
        () async {
      // End-to-end intent: a whole-shift ledger replay must be sufficient for
      // Shift.isAlarmHandledAt to suppress the zombie WakeUpScreen.
      await shifts.upsert(mkShift());
      await ackPendingDismissalsInHive(
        shifts: shifts,
        dismissals: const [PendingDismissal('s1', '')],
      );
      final stored = await shifts.getById('s1');
      expect(stored!.isAlarmHandledAt(DateTime(2026, 6, 11, 9, 0)), isTrue);
    });
  });
}
