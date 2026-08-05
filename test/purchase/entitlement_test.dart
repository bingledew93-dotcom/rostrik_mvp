import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:rostrik_mvp/purchase/entitlement.dart';
import 'package:rostrik_mvp/purchase/entitlement_store.dart';

void main() {
  final now = DateTime(2026, 8, 1, 12, 0);

  group('Entitlement', () {
    test('a fresh install (no start recorded) is inside its trial', () {
      final e = Entitlement(purchased: false, trialStartedAt: null, now: now);
      expect(e.entitled, isTrue);
      expect(e.withinTrial, isTrue);
      expect(e.locked, isFalse);
      expect(e.trialDaysLeft, 14);
    });

    test('mid-trial reports the days remaining', () {
      final e = Entitlement(
        purchased: false,
        trialStartedAt: now.subtract(const Duration(days: 5)),
        now: now,
      );
      expect(e.entitled, isTrue);
      expect(e.trialDaysLeft, 9);
    });

    test('a lapsed trial with no purchase is locked', () {
      final e = Entitlement(
        purchased: false,
        trialStartedAt: now.subtract(const Duration(days: 20)),
        now: now,
      );
      expect(e.withinTrial, isFalse);
      expect(e.entitled, isFalse);
      expect(e.locked, isTrue);
      expect(e.trialDaysLeft, 0);
    });

    test('a purchase grants access even after the trial lapses', () {
      final e = Entitlement(
        purchased: true,
        trialStartedAt: now.subtract(const Duration(days: 20)),
        now: now,
      );
      expect(e.entitled, isTrue);
      expect(e.locked, isFalse);
      expect(e.trialDaysLeft, 0);
      expect(e.trialEndingReminderAt, isNull);
    });

    test('the reminder fires one day before expiry', () {
      final started = now.subtract(const Duration(days: 5));
      final e =
          Entitlement(purchased: false, trialStartedAt: started, now: now);
      expect(
        e.trialEndingReminderAt,
        started.add(kTrialDuration).subtract(const Duration(days: 1)),
      );
    });

    test('no reminder when it would already be in the past', () {
      // 13.5 days in → the "1 day before" instant has already passed.
      final e = Entitlement(
        purchased: false,
        trialStartedAt: now.subtract(const Duration(days: 13, hours: 12)),
        now: now,
      );
      expect(e.trialEndingReminderAt, isNull);
    });
  });

  group('EntitlementStore', () {
    late Directory tempDir;
    late Box box;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('rostrik_ent_test');
      Hive.init(tempDir.path);
      box = await Hive.openBox('settings');
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('ensureTrialStarted records once, then is stable', () {
      final first = EntitlementStore.ensureTrialStarted(box, now);
      expect(first, now);
      final later = EntitlementStore.ensureTrialStarted(
        box,
        now.add(const Duration(days: 3)),
      );
      // Second call must NOT reset the clock.
      expect(later, now);
    });

    test('purchase state round-trips', () async {
      expect(EntitlementStore.isPurchased(box), isFalse);
      await EntitlementStore.setPurchased(box, true);
      expect(EntitlementStore.isPurchased(box), isTrue);
    });

    test('refreshLock writes the derived lock flag for the alarm sync',
        () async {
      // Lapsed trial, no purchase → locked flag true.
      EntitlementStore.ensureTrialStarted(
        box,
        now.subtract(const Duration(days: 30)),
      );
      final e = await EntitlementStore.refreshLock(box, now);
      expect(e.locked, isTrue);
      expect(EntitlementStore.isLocked(box), isTrue);

      // Purchasing clears the lock on next refresh.
      await EntitlementStore.setPurchased(box, true);
      final e2 = await EntitlementStore.refreshLock(box, now);
      expect(e2.locked, isFalse);
      expect(EntitlementStore.isLocked(box), isFalse);
    });

    test('refreshLock caps the horizon at trial end while unpurchased', () async {
      final started = now.subtract(const Duration(days: 5));
      EntitlementStore.ensureTrialStarted(box, started);
      await EntitlementStore.refreshLock(box, now);
      // Unpurchased → capped at the trial end (9 days out).
      expect(EntitlementStore.horizonCap(box), started.add(kTrialDuration));

      // Purchasing lifts the cap entirely.
      await EntitlementStore.setPurchased(box, true);
      await EntitlementStore.refreshLock(box, now);
      expect(EntitlementStore.horizonCap(box), isNull);
    });
  });
}
