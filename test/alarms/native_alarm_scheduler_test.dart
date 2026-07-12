import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:rostrik_mvp/alarms/native_alarm_scheduler.dart';

/// Hydration semantics of the native scheduler's persisted id→fireAt ledger.
///
/// The ledger is the ONLY record of what lives inside Android's AlarmManager
/// (which exposes no enumeration API), so a hydration miss is not cosmetic:
/// `pendingIds()` drives the reconciler's orphan-cancel pass, and `cancelAll`
/// can only reach ids the ledger knows. The regression pinned here: a call
/// arriving BEFORE `Hive.openBox('settings')` resolves must NOT latch the
/// one-shot hydration flag — it must retry on the next call and pick up the
/// on-disk ledger once the box is available. (Both production init paths open
/// the box first; this guards the ordering against future refactors.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The wire key the scheduler persists its ledger under in the `settings`
  /// box — part of the persistence contract, mirrored here by name.
  const ledgerKey = 'native_alarms.scheduled';

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('rostrik_native_sched_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // best-effort temp cleanup.
    }
  });

  test(
      'a call before the settings box opens must NOT latch hydration — '
      'the ledger re-reads once the box is available', () async {
    final scheduler = NativeAlarmScheduler();

    // Too early: the box isn't open yet. Defensive empty answer is correct —
    // but it must be a RETRY, not a permanent verdict.
    expect(await scheduler.pendingIds(), isEmpty);

    final box = await Hive.openBox('settings');
    await box.put(ledgerKey, <int, int>{7: 1111, 9: 2222});

    expect(
      await scheduler.pendingIds(),
      {7, 9},
      reason: 'a latched early miss would leave this ledger permanently '
          'blind: the reconciler would treat every pending OS alarm as '
          'unknown, and cancelAll could never reach them (AlarmManager '
          'cannot be enumerated)',
    );
  });

  test('hydration is one-shot once the box has been read', () async {
    final box = await Hive.openBox('settings');
    await box.put(ledgerKey, <int, int>{7: 1111});

    final scheduler = NativeAlarmScheduler();
    expect(await scheduler.pendingIds(), {7});

    // A later disk write does NOT re-enter an already-hydrated ledger — the
    // in-memory map is the live truth between persists.
    await box.put(ledgerKey, <int, int>{8: 2222});
    expect(await scheduler.pendingIds(), {7});
  });

  test(
      'late hydration merges disk entries WITHOUT clobbering fresher '
      'in-memory state', () async {
    const channel = MethodChannel(NativeAlarmScheduler.channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final scheduler = NativeAlarmScheduler(channel: channel);
    final liveFireAt = DateTime(2026, 7, 12, 6, 0);

    // Box still closed: this schedule lands in memory only (persist no-ops),
    // and hydration must still be pending.
    await scheduler.scheduleAt(
      id: 7,
      fireAt: liveFireAt,
      title: 'Wake',
      body: '',
      soundKey: 'classic',
    );

    // The box opens carrying a STALE entry for id 7 plus an unknown id 8.
    final box = await Hive.openBox('settings');
    await box.put(ledgerKey, <int, int>{7: 1, 8: 2});

    // The retried hydration merges: disk fills the gap (8), the live entry
    // for 7 wins over the stale persisted one.
    expect(await scheduler.pendingIds(), {7, 8});

    // Any mutation persists the merged ledger — verify 7 kept its LIVE
    // fireAt, not the stale disk value.
    await scheduler.cancel(8);
    final persisted = box.get(ledgerKey) as Map;
    expect(persisted[7], liveFireAt.millisecondsSinceEpoch);
    expect(persisted.containsKey(8), isFalse);
  });

  test(
      'pendingIds validates the ledger against the OS and prunes wiped ids '
      '(the force-stop / reboot recovery)', () async {
    // The Pixel 9 XL field bug: a force-stop cancelled every OS alarm but the
    // persisted ledger still claimed them armed, so the reconciler re-issued
    // nothing — a silent outage. The OS-truth probe (PendingIntent existence)
    // must win over the ledger, and the phantoms must be pruned so they stay
    // gone.
    final box = await Hive.openBox('settings');
    await box.put(ledgerKey, <int, int>{7: 1111, 8: 2222, 9: 3333});

    const channel = MethodChannel(NativeAlarmScheduler.channelName);
    final asked = <List<Object?>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAliveAlarmIds') {
        asked.add((call.arguments as Map)['ids'] as List<Object?>);
        return <int>[8]; // the OS only still holds id 8 — 7 and 9 were wiped
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final scheduler = NativeAlarmScheduler(channel: channel);
    expect(await scheduler.pendingIds(), {8},
        reason: 'the reconciler must see wiped alarms as NOT pending so it '
            're-arms them');
    expect(asked.single.toSet(), {7, 8, 9},
        reason: 'the whole ledger is offered for validation');

    // The phantoms are pruned from the persisted ledger too.
    final persisted = box.get(ledgerKey) as Map;
    expect(persisted.keys.toSet(), {8});
  });

  test(
      'a refused native schedule (exact-alarm permission revoked) neither '
      'throws nor writes a phantom ledger entry', () async {
    const channel = MethodChannel(NativeAlarmScheduler.channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      // What MainActivity/AlarmSyncWorker's handler replies when Android
      // 12/12L has "Alarms & reminders" revoked and setAlarmClock refuses.
      throw PlatformException(code: 'EXACT_ALARM_DENIED', message: 'revoked');
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final box = await Hive.openBox('settings');
    final scheduler = NativeAlarmScheduler(channel: channel);

    // Must complete normally: a rethrow would abort the whole reconcile —
    // which on cold start runs BEFORE runApp and would strand the splash.
    await scheduler.scheduleAt(
      id: 7,
      fireAt: DateTime(2026, 7, 12, 6, 0),
      title: 'Wake',
      body: '',
      soundKey: 'classic',
    );

    // And the ledger must stay honest: no phantom entry, so the next
    // reconcile re-issues the schedule once the permission is restored.
    expect(await scheduler.pendingIds(), isEmpty);
    expect(box.get(ledgerKey), anyOf(isNull, isEmpty));
  });
}
