import 'dart:io';
import 'dart:isolate' show ReceivePort;
// Prefixed for the same reason as background_sync_entrypoint.dart: `hive_ce`
// pulls in an instance-based `IsolateNameServer` that shadows `dart:ui`'s
// static, platform-backed one. We must register against the SAME platform
// registry that `mainIsolateIsAlive()` queries, so go through `ui.`.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:rostrik_mvp/alarms/alarm_sync_service.dart';
import 'package:rostrik_mvp/alarms/background_sync_entrypoint.dart';
import 'package:rostrik_mvp/alarms/notification_action_dispatcher.dart'
    show alarmActionPortName;
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';

import 'fakes.dart';

/// Mirrors the helpers in `alarm_sync_service_test.dart` so this file is
/// self-contained.
AppAlarm followsRotation({
  String id = 'fr',
  int minutesOfDay = 6 * 60,
  String label = 'Wake Up',
  ShiftType? linkedShiftType = ShiftType.day,
  bool enabled = true,
}) =>
    AppAlarm(
      id: id,
      minutesOfDay: minutesOfDay,
      label: label,
      repeatType: AppAlarmRepeatType.followsRotation,
      enabled: enabled,
      linkedShiftType: linkedShiftType,
    );

Shift mkShift({
  required String id,
  required DateTime date,
  required ShiftType type,
  int startMin = 7 * 60,
  int endMin = 15 * 60,
}) =>
    Shift(
      id: id,
      date: date,
      type: type,
      startMinutes: startMin,
      endMinutes: endMin,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---- A1: hydrate() makes the one-shot background reconcile non-redundant.
  group('AlarmSyncService.hydrate() — background re-sync dedup (A1)', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('rostrik_bgsync_');
      Hive.init(tempDir.path);
    });

    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    late FakeAppAlarmRepository alarms;
    late FakeShiftRepository shifts;
    late FakeShiftCycleRepository cycles;
    // Shared across the two service instances: they model the on-disk /
    // OS state that the main isolate and a background isolate both see.
    late FakeAlarmScheduler scheduler;
    late InMemoryNotificationIdMap idMap;
    late FrozenClock clock;
    late FakeAlarmSettingsRepository settings;

    setUp(() async {
      // A REAL settings box so persist + hydrate actually touch disk — the
      // rest of the suite uses fakes and never opens it, which is exactly
      // why those tests never exercised this path.
      await Hive.openBox('settings');
      alarms = FakeAppAlarmRepository();
      shifts = FakeShiftRepository();
      cycles = FakeShiftCycleRepository();
      settings = FakeAlarmSettingsRepository();
      scheduler = FakeAlarmScheduler();
      idMap = InMemoryNotificationIdMap();
      clock = FrozenClock(DateTime(2026, 6, 1, 5, 0));
    });

    tearDown(() async {
      await alarms.dispose();
      await shifts.dispose();
      await cycles.dispose();
      await settings.dispose();
      await Hive.box('settings').deleteFromDisk();
    });

    AlarmSyncService makeService() => AlarmSyncService(
          alarms: alarms,
          shifts: shifts,
          cycles: cycles,
          alarmSettings: settings,
          scheduler: scheduler,
          idMap: idMap,
          clock: clock,
        );

    test('hydrate() before a background sync issues zero redundant calls',
        () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation());

      // Foreground / main isolate: schedules the alarm and persists
      // `_scheduledFireAt` to the settings box.
      final main = makeService();
      await main.syncAlarms();
      expect(scheduler.scheduled, hasLength(1),
          reason: 'baseline: exactly one Day alarm scheduled + persisted');
      scheduler.clearLog();

      // Background isolate: a fresh service (empty in-memory
      // `_scheduledFireAt`) sharing the same persisted box + idMap + OS
      // pending set. Hydrating first must let it converge with no calls.
      final background = makeService();
      background.hydrate();
      await background.syncAlarms();

      expect(scheduler.callLog, isEmpty,
          reason: 'hydrate primed _scheduledFireAt; pending + persisted '
              'agree, so the background reconcile issues no scheduleAt/cancel');
    });

    test('WITHOUT hydrate() the background sync re-issues scheduleAt '
        '(the regression A1 fixes)', () async {
      await shifts.upsert(
        mkShift(id: 'd1', date: DateTime(2026, 6, 2), type: ShiftType.day),
      );
      await alarms.upsert(followsRotation());

      final main = makeService();
      await main.syncAlarms();
      scheduler.clearLog();

      final background = makeService();
      // Intentionally NO hydrate() — reproduces the pre-fix background path.
      await background.syncAlarms();

      expect(
        scheduler.callLog.where((c) => c.startsWith('schedule:')),
        hasLength(1),
        reason: 'empty _scheduledFireAt ⇒ lastKnown==null for every id ⇒ '
            'scheduleAt re-issued even though the OS already holds it',
      );
    });
  });

  // ---- A2: bail when the main UI isolate is alive in this process.
  group('mainIsolateIsAlive() — background-sync bail guard (A2)', () {
    test('tracks the presence of the main-isolate action port', () {
      expect(mainIsolateIsAlive(), isFalse,
          reason: 'no port registered ⇒ no live main isolate ⇒ bg sync runs');

      final port = ReceivePort();
      addTearDown(port.close);
      final registered = ui.IsolateNameServer.registerPortWithName(
        port.sendPort,
        alarmActionPortName,
      );
      addTearDown(
        () => ui.IsolateNameServer.removePortNameMapping(alarmActionPortName),
      );
      expect(registered, isTrue);

      expect(mainIsolateIsAlive(), isTrue,
          reason: 'dispatcher port present ⇒ main isolate alive ⇒ bg bails');

      ui.IsolateNameServer.removePortNameMapping(alarmActionPortName);
      expect(mainIsolateIsAlive(), isFalse,
          reason: 'port gone (process killed) ⇒ bg sync may proceed');
    });
  });
}
