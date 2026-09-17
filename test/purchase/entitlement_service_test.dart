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
  /// What the store answers with. Empty (the default) keeps every existing
  /// test on the "product not found" path they were written against.
  List<ProductDetails> products = const [];
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
      productDetails: products,
      notFoundIDs: products.isEmpty ? identifiers.toList() : const [],
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

  group('the price always comes from the store', () {
    // Ben's question, pinned: a user in another country must see THEIR price.
    // The app never computes, converts or formats it — Play and Apple hand
    // back a string already in the buyer's currency for the buyer's country,
    // and the app's only job is not to mangle it on the way to the screen.
    ProductDetails product(String formatted, String currency, double raw) =>
        ProductDetails(
          id: kFullAccessProductId,
          title: 'Rostrik full access',
          description: 'One-time unlock',
          price: formatted,
          rawPrice: raw,
          currencyCode: currency,
        );

    test('the store\'s formatted string is surfaced verbatim', () async {
      iap.products = [product('R\$ 27,90', 'BRL', 27.90)];
      await service.init();
      await service.startBilling();
      // Not "27.90", not converted from AUD, not re-formatted by intl —
      // exactly what the store said, comma decimal separator and all.
      expect(service.price, 'R\$ 27,90');
    });

    test('a different country simply yields a different string', () async {
      iap.products = [product('¥800', 'JPY', 800)];
      await service.init();
      await service.startBilling();
      expect(service.price, '¥800');
    });

    test('no product yet means no price, never a guess', () async {
      await service.init();
      await service.startBilling();
      expect(service.price, isNull,
          reason: 'the gate shows an unpriced button rather than invent one');
    });
  });

  group('refreshPriceIfMissing', () {
    test('re-asks when the launch-time query came up empty', () async {
      // Offline at launch: no product, no price.
      iap.available = false;
      await service.init();
      await service.startBilling();
      final atLaunch = iap.queryCalls;
      expect(service.price, isNull);

      // Connectivity returns and the user reaches the paywall.
      iap.available = true;
      iap.products = [
        ProductDetails(
          id: kFullAccessProductId,
          title: 'Rostrik full access',
          description: 'One-time unlock',
          price: '\u00a34.99',
          rawPrice: 4.99,
          currencyCode: 'GBP',
        )
      ];
      await service.refreshPriceIfMissing();
      expect(iap.queryCalls, greaterThan(atLaunch));
      expect(service.price, '\u00a34.99');
    });

    test('does nothing once a price is held', () async {
      iap.products = [
        ProductDetails(
          id: kFullAccessProductId,
          title: 'Rostrik full access',
          description: 'One-time unlock',
          price: '\u00a34.99',
          rawPrice: 4.99,
          currencyCode: 'GBP',
        )
      ];
      await service.init();
      await service.startBilling();
      final settled = iap.queryCalls;

      await service.refreshPriceIfMissing();
      await service.refreshPriceIfMissing();
      expect(iap.queryCalls, settled,
          reason: 'opening the gate repeatedly must not re-query');
    });

    test('stays quiet while billing is unavailable', () async {
      iap.available = false;
      await service.init();
      await service.startBilling();
      final settled = iap.queryCalls;
      await service.refreshPriceIfMissing();
      expect(iap.queryCalls, settled);
      expect(service.price, isNull);
    });
  });
}
