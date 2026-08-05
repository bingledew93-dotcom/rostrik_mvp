import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../reminders/activity_reminder_scheduler.dart';
import '../reminders/reminder_id.dart';
import '../util/clock.dart';
import 'entitlement.dart';
import 'entitlement_store.dart';

/// Stable sentinel the trial-ending reminder id is derived from, in the same
/// id-space as activity reminders (astronomically unlikely to collide with a
/// real activity's UUID hash, and never managed by `ActivityReminderService`).
const String _kTrialReminderSentinel = '__rostrik_trial_ending__';

/// Owns the 14-day trial + one-time full-access purchase (feature #4).
///
/// A [ChangeNotifier] so the root gate rebuilds the instant entitlement changes
/// (a purchase completes, or the trial lapses while the app is open). It:
///   * starts the trial clock on first launch and persists it;
///   * writes the derived lock + horizon-cap flags the alarm sync reads, so a
///     LOCKED app fires no alarms and an in-trial app arms nothing past the
///     trial (see [EntitlementStore]);
///   * schedules a friendly "trial ends tomorrow" reminder on the isolated
///     reminder channel (never the shift-alarm path);
///   * drives Google Play Billing for the one-time [kFullAccessProductId]
///     unlock, degrading gracefully when billing is unavailable (the trial and
///     lock logic still work).
///
/// [onEntitlementChanged] is called after every state change so `main()` can
/// re-run the alarm reconcile (disarm on lock, restore on purchase).
class EntitlementService extends ChangeNotifier with WidgetsBindingObserver {
  EntitlementService({
    required Box settingsBox,
    required ActivityReminderScheduler reminderScheduler,
    VoidCallback? onEntitlementChanged,
    Clock clock = const SystemClock(),
    InAppPurchase? iap,
  })  : _box = settingsBox,
        _reminders = reminderScheduler,
        _onChanged = onEntitlementChanged,
        _clock = clock,
        _iap = iap ?? InAppPurchase.instance;

  final Box _box;
  final ActivityReminderScheduler _reminders;
  final VoidCallback? _onChanged;
  final Clock _clock;
  final InAppPurchase _iap;

  int get _reminderId => reminderNotificationId(_kTrialReminderSentinel);

  // Placeholder until [init]'s first refresh; the `late` initializer defers to
  // first access, by when `_clock` is set (a fresh install reads as in-trial).
  late Entitlement _entitlement = Entitlement(
    purchased: false,
    trialStartedAt: null,
    now: _clock.now(),
  );

  Entitlement get entitlement => _entitlement;
  bool get locked => _entitlement.locked;

  ProductDetails? _product;
  bool _billingAvailable = false;

  /// Human-facing price ("$4.99"), or null until billing resolves the product.
  String? get price => _product?.price;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Timer? _lapseTimer;

  /// Records the trial start (once), writes the derived gates, schedules the
  /// reminder, and wires up billing. Safe to call once at startup.
  Future<void> init() async {
    EntitlementStore.ensureTrialStarted(_box, _clock.now());
    // Re-check on resume: the trial may have lapsed while backgrounded.
    WidgetsBinding.instance.addObserver(this);
    await _refresh();

    // Billing is best-effort: if the device/account can't reach Play Billing,
    // the trial + lock logic still governs access.
    try {
      _billingAvailable = await _iap.isAvailable();
    } catch (_) {
      _billingAvailable = false;
    }
    if (_billingAvailable) {
      _purchaseSub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) => debugPrint('[Entitlement] purchase stream: $e'),
      );
      await _queryProduct();
      // Pick up a purchase already owned (reinstall / new device).
      try {
        await _iap.restorePurchases();
      } catch (e) {
        debugPrint('[Entitlement] restore on init failed: $e');
      }
    }
  }

  /// Recompute after a possible trial lapse while the app was backgrounded, and
  /// re-arm the lapse timer. Call from an app-lifecycle resume.
  Future<void> onAppResumed() => _refresh();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final now = _clock.now();
    _entitlement = await EntitlementStore.refreshLock(_box, now);
    await _syncReminder();
    _armLapseTimer(now);
    notifyListeners();
    _onChanged?.call();
  }

  /// Schedules (or cancels) the "trial ends tomorrow" reminder to match the
  /// current entitlement — cancelled once purchased or past the reminder point.
  Future<void> _syncReminder() async {
    final at = _entitlement.trialEndingReminderAt;
    if (at == null) {
      await _reminders.cancel(_reminderId);
      return;
    }
    await _reminders.schedule(
      id: _reminderId,
      at: at,
      title: 'Your Rostrik trial ends tomorrow',
      body: 'Unlock full access to keep your shift alarms firing.',
    );
  }

  /// Fires a local re-check exactly when the trial lapses, so an app left open
  /// across the boundary flips to the locked wall without waiting for a resume.
  void _armLapseTimer(DateTime now) {
    _lapseTimer?.cancel();
    _lapseTimer = null;
    if (_entitlement.purchased || !_entitlement.withinTrial) return;
    final untilLapse = _entitlement.trialEndsAt.difference(now);
    if (untilLapse <= Duration.zero) return;
    _lapseTimer = Timer(untilLapse, () {
      _refresh();
    });
  }

  Future<void> _queryProduct() async {
    try {
      final resp = await _iap.queryProductDetails({kFullAccessProductId});
      if (resp.productDetails.isNotEmpty) {
        _product = resp.productDetails.first;
        notifyListeners();
      } else {
        debugPrint('[Entitlement] product not found: ${resp.notFoundIDs}');
      }
    } catch (e) {
      debugPrint('[Entitlement] queryProduct failed: $e');
    }
  }

  /// Starts the purchase flow for the one-time unlock. Returns false when
  /// billing/product isn't ready (the UI can surface a "try again" message).
  Future<bool> buy() async {
    final product = _product;
    if (!_billingAvailable || product == null) {
      // Late-resolve attempt in case billing came up after init.
      await _queryProduct();
      if (_product == null) return false;
    }
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _product!),
      );
      return true;
    } catch (e) {
      debugPrint('[Entitlement] buy failed: $e');
      return false;
    }
  }

  /// Restores a previously-bought unlock (Play remembers non-consumables).
  Future<void> restore() async {
    if (!_billingAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[Entitlement] restore failed: $e');
    }
  }

  // ---- DEBUG-ONLY test shortcuts (compiled to no-ops in release) -----------
  // Let a tester exercise the purchase wall without waiting 14 days. Every one
  // is gated on kDebugMode so it can never fire in a release build.

  /// Forces the trial to read as lapsed (and clears any purchase) so the lock
  /// wall appears on the next gate rebuild.
  Future<void> debugExpireTrial() async {
    if (!kDebugMode) return;
    await EntitlementStore.setPurchased(_box, false);
    final start = _clock
        .now()
        .subtract(kTrialDuration + const Duration(days: 1))
        .millisecondsSinceEpoch;
    await _box.put(EntitlementStore.trialStartedAtKey, start);
    await _box.flush();
    await _refresh();
  }

  /// Restarts the trial clock at "now" and clears any purchase — a fresh 14-day
  /// trial, unlocked.
  Future<void> debugResetTrial() async {
    if (!kDebugMode) return;
    await EntitlementStore.setPurchased(_box, false);
    await _box.put(
      EntitlementStore.trialStartedAtKey,
      _clock.now().millisecondsSinceEpoch,
    );
    await _box.flush();
    await _refresh();
  }

  /// Simulates a completed purchase (unlocks permanently, no billing round-trip)
  /// so the post-purchase state can be verified.
  Future<void> debugGrantPurchase() async {
    if (!kDebugMode) return;
    await EntitlementStore.setPurchased(_box, true);
    await _refresh();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    var granted = false;
    for (final p in purchases) {
      if (p.productID != kFullAccessProductId) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          granted = true;
        case PurchaseStatus.error:
          debugPrint('[Entitlement] purchase error: ${p.error}');
        case PurchaseStatus.pending:
        case PurchaseStatus.canceled:
          break;
      }
      // Always acknowledge, or Play auto-refunds after 3 days.
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (e) {
          debugPrint('[Entitlement] completePurchase failed: $e');
        }
      }
    }
    if (granted && !EntitlementStore.isPurchased(_box)) {
      await EntitlementStore.setPurchased(_box, true);
      await _refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchaseSub?.cancel();
    _lapseTimer?.cancel();
    super.dispose();
  }
}
