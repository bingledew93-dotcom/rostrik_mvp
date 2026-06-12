import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:rostrik_mvp/alarms/alarm_payload.dart';
import 'package:rostrik_mvp/alarms/notification_response_handler.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/hive_app_alarm_repository.dart';
import 'package:rostrik_mvp/data/repositories/hive_shift_repository.dart';

/// Zombie-UI regression suite: the KILLED-APP Dismiss/Snooze Hive writes.
///
/// These tests run [performBackgroundDismissWrite] /
/// [performBackgroundSnoozeWrite] against a REAL on-disk Hive in a temp dir,
/// with every box CLOSED before the call — the exact state of a background
/// notification tap while the main UI isolate is completely dead. The field
/// bug: Dismiss from the notification panel stopped the audio, but the
/// `isAcknowledged` write never landed durably, so a later cold boot routed
/// to a silent, dead WakeUpScreen off the stale FSI payload.
///
/// Every test also asserts the boxes can be re-opened immediately after the
/// call — the close-in-`finally` contract that releases the file handle/lock
/// so a main-isolate boot can never contend with a lingering background
/// handle (the "no isolate deadlocks" requirement).
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('rostrik_bg_handler_');
    Hive.init(tempDir.path);
    // Mirror _ensureBackgroundIsolateInit's adapter set (Hive-only — the
    // platform-channel steps are exactly what these tests bypass).
    Hive.registerAdapter(ShiftTypeAdapter());
    Hive.registerAdapter(ShiftAdapter());
    Hive.registerAdapter(AppAlarmRepeatTypeAdapter());
    Hive.registerAdapter(AppAlarmAdapter());
  });

  tearDown(() async {
    // Fixed production box names — wipe between tests for isolation.
    await Hive.deleteBoxFromDisk(HiveShiftRepository.boxName);
    await Hive.deleteBoxFromDisk(HiveAppAlarmRepository.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  AlarmPayload payload({
    String shiftId = 's1',
    String appAlarmId = '',
  }) =>
      AlarmPayload(
        shiftId: shiftId,
        notificationId: 7,
        isCritical: false,
        soundKey: 'classic',
        appAlarmId: appAlarmId,
      );

  /// Seeds the shifts box with [shift] and CLOSES it — on-disk state exists,
  /// no box is open, no lock is held: the dead-main-isolate baseline.
  Future<void> seedShiftThenDie(Shift shift) async {
    final box = await Hive.openBox<Shift>(HiveShiftRepository.boxName);
    await box.put(shift.id, shift);
    await box.close();
  }

  Shift ringingShift({String id = 's1', DateTime? snoozedUntil}) => Shift(
        id: id,
        date: DateTime(2026, 6, 11),
        type: ShiftType.day,
        startMinutes: 7 * 60,
        endMinutes: 15 * 60,
        snoozedUntil: snoozedUntil,
      );

  group('performBackgroundDismissWrite — main isolate dead', () {
    test('marks the shift isAcknowledged and the write is durable on disk',
        () async {
      await seedShiftThenDie(ringingShift());

      await performBackgroundDismissWrite(payload());

      // Re-open from DISK (the function closed its handle): the acknowledged
      // flag must be there — this is what the cold-booting main isolate
      // reads, and what kills the Zombie WakeUpScreen.
      final box = await Hive.openBox<Shift>(HiveShiftRepository.boxName);
      final stored = box.get('s1');
      expect(stored, isNotNull, reason: 'the Shift record is never deleted');
      expect(stored!.isAcknowledged, isTrue,
          reason: 'the database must know the alarm was handled');
      await box.close();
    });

    test('clears a pending snooze — Dismiss means fully handled', () async {
      await seedShiftThenDie(
        ringingShift(snoozedUntil: DateTime(2026, 6, 11, 6, 9)),
      );

      await performBackgroundDismissWrite(payload());

      final box = await Hive.openBox<Shift>(HiveShiftRepository.boxName);
      expect(box.get('s1')!.snoozedUntil, isNull);
      expect(box.get('s1')!.isAcknowledged, isTrue);
      await box.close();
    });

    test('releases the box afterwards — no lock contention, no deadlock',
        () async {
      await seedShiftThenDie(ringingShift());

      await performBackgroundDismissWrite(payload());
      // A second background tap on the (already-closed) box must work…
      await performBackgroundDismissWrite(payload());
      // …and a "main isolate boot" straight after opens the box cleanly.
      final box = await Hive.openBox<Shift>(HiveShiftRepository.boxName);
      expect(box.get('s1')!.isAcknowledged, isTrue);
      await box.close();
    });

    test('auto-deletes a fired one-time alarm flagged autoDeleteAfterFiring',
        () async {
      await seedShiftThenDie(ringingShift());
      final alarmBox =
          await Hive.openBox<AppAlarm>(HiveAppAlarmRepository.boxName);
      await alarmBox.put(
        'rule-1',
        AppAlarm(
          id: 'rule-1',
          minutesOfDay: 6 * 60,
          label: 'Once',
          repeatType: AppAlarmRepeatType.oneTime,
          autoDeleteAfterFiring: true,
        ),
      );
      await alarmBox.close();

      await performBackgroundDismissWrite(payload(appAlarmId: 'rule-1'));

      final reopened =
          await Hive.openBox<AppAlarm>(HiveAppAlarmRepository.boxName);
      expect(reopened.get('rule-1'), isNull,
          reason: 'auto-delete must work from the killed-app path too');
      await reopened.close();
    });

    test('a non-auto-delete rule survives the dismiss', () async {
      await seedShiftThenDie(ringingShift());
      final alarmBox =
          await Hive.openBox<AppAlarm>(HiveAppAlarmRepository.boxName);
      await alarmBox.put(
        'rule-2',
        AppAlarm(
          id: 'rule-2',
          minutesOfDay: 6 * 60,
          label: 'Rotation',
          repeatType: AppAlarmRepeatType.followsRotation,
          linkedShiftType: ShiftType.day,
        ),
      );
      await alarmBox.close();

      await performBackgroundDismissWrite(payload(appAlarmId: 'rule-2'));

      final reopened =
          await Hive.openBox<AppAlarm>(HiveAppAlarmRepository.boxName);
      expect(reopened.get('rule-2'), isNotNull);
      await reopened.close();
    });

    test('an unknown shift id is a safe no-op (box still closed after)',
        () async {
      await seedShiftThenDie(ringingShift());

      await performBackgroundDismissWrite(payload(shiftId: 'ghost'));

      final box = await Hive.openBox<Shift>(HiveShiftRepository.boxName);
      expect(box.get('s1')!.isAcknowledged, isFalse,
          reason: 'an unrelated shift must not be touched');
      await box.close();
    });
  });

  group('performBackgroundSnoozeWrite — main isolate dead', () {
    test('persists snoozedUntil durably and returns the updated shift',
        () async {
      await seedShiftThenDie(ringingShift());
      final until = DateTime(2026, 6, 11, 6, 9);

      final updated = await performBackgroundSnoozeWrite(payload(), until);
      expect(updated, isNotNull);
      expect(updated!.snoozedUntil, until);

      final box = await Hive.openBox<Shift>(HiveShiftRepository.boxName);
      expect(box.get('s1')!.snoozedUntil, until,
          reason: 'the snooze must survive a cold start');
      await box.close();
    });

    test('returns null for a vanished shift and still releases the box',
        () async {
      await seedShiftThenDie(ringingShift());

      final updated = await performBackgroundSnoozeWrite(
        payload(shiftId: 'ghost'),
        DateTime(2026, 6, 11, 6, 9),
      );
      expect(updated, isNull);

      final box = await Hive.openBox<Shift>(HiveShiftRepository.boxName);
      expect(box.isOpen, isTrue); // re-open succeeded — lock was released
      await box.close();
    });
  });
}
