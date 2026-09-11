import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:rostrik_mvp/purchase/entitlement.dart';
import 'package:rostrik_mvp/purchase/entitlement_service.dart';
import 'package:rostrik_mvp/purchase/entitlement_store.dart';

import '../reminders/fakes.dart';

/// Minimal in-memory stand-in for the store plugin. Only the members the
/// service actually touches are implemented; anything else throws via [Fake].
class _FakeIap extends Fake implements InAppPurchase {
  bool available = true;
  bool throwOnIsAvailable = false;
  int restoreCalls = 0;
  int queryCalls = 0;
  final List<PurchaseDetails> completed = [];
  bool streamListened = false;

  late final StreamController<List<PurchaseDetails>> controller =
      StreamController<List<PurchaseDetails>>.broadcast(
    onListen: () => streamListened = true,
  );

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async {
    if (throwOnIsAvailable) throw StateError('billing exploded');
    return available;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(
      Set<String> identifiers) async {
    queryCalls++;
    return ProductDetailsResponse(
      productDetails: const [],
      notFoundIDs: identifiers.toList(),
    );
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restoreCalls++;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }
}

PurchaseDetails _purchase(String productId,
    {PurchaseStatus status = PurchaseStatus.purchased}) {
  return PurchaseDetails(
    purchaseID: 'txn-1',
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'fake_store',
    ),
    transactionDate: '0',
    status: status,
  )..pendingCompletePurchase = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box box;
  late _FakeIap iap;
  late FakeActivityReminderScheduler reminders;
  late EntitlementService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rostrik_ent_svc_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('settings');
    iap = _FakeIap();
    reminders = FakeActivityReminderScheduler();
    service = EntitlementService(
      settingsBox: box,
      reminderScheduler: reminders,
      iap: iap,
    );
  });

  tearDown(() async {
    service.dispose();
    await iap.controller.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // Let the stream listener's async purchase handling (box writes + flushes)
  // fully settle before asserting.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 100));

  test('init() is billing-free: no subscription, no store calls', () async {
    await service.init();
    expect(iap.streamListened, isFalse);
    expect(iap.restoreCalls, 0);
    expect(iap.queryCalls, 0);
    // The local half still ran: the trial clock was recorded.
    expect(EntitlementStore.trialStartedAt(box), isNotNull);
  });

  test('startBilling() restores an owned purchase when the store is up',
      () async {
    await service.init();
    await service.startBilling();
    expect(iap.streamListened, isTrue);
    expect(iap.restoreCalls, 1);
  });

  test(
      'REGRESSION: a purchase arriving after the availability probe said "no" '
      'is still heard, granted, and acknowledged', () async {
    iap.available = false;
    await service.init();
    await service.startBilling();
    // Store probe said unavailable — but the stream MUST be subscribed, or a
    // later successful buy() completes at the store with nobody listening
    // (user paid, stayed locked until next launch).
    expect(iap.streamListened, isTrue);
    expect(iap.restoreCalls, 0);

    iap.controller.add([_purchase(kFullAccessProductId)]);
    await settle();

    expect(EntitlementStore.isPurchased(box), isTrue);
    expect(service.entitlement.purchased, isTrue);
    expect(iap.completed, hasLength(1),
        reason: 'unacknowledged purchases auto-refund after 3 days');
  });

  test('a purchase for some OTHER product grants nothing', () async {
    await service.init();
    await service.startBilling();
    iap.controller.add([_purchase('somebody_elses_product')]);
    await settle();
    expect(EntitlementStore.isPurchased(box), isFalse);
    // And it is deliberately NOT acknowledged: an unknown product is money
    // for something this app will never deliver, and leaving it
    // unacknowledged makes Play auto-refund the buyer within 3 days.
    expect(iap.completed, isEmpty);
  });

  test('an isAvailable() explosion degrades to trial-only, no crash',
      () async {
    iap.throwOnIsAvailable = true;
    await service.init();
    await service.startBilling();
    expect(iap.streamListened, isTrue);
    expect(iap.restoreCalls, 0);
    expect(service.entitlement.withinTrial, isTrue);
  });

  test('buy() re-probes availability instead of trusting the startup snapshot',
      () async {
    iap.available = false;
    await service.init();
    await service.startBilling();

    // Billing comes up later (e.g. connectivity returned). buy() must probe
    // again; the product query still resolves nothing in this fake, so the
    // flow reports false — but the probe and query must both have happened.
    iap.available = true;
    final launched = await service.buy();
    expect(launched, isFalse);
    expect(iap.queryCalls, greaterThan(0));
  });
}
