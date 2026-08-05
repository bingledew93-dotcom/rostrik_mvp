import 'package:hive_ce_flutter/hive_flutter.dart';

import 'entitlement.dart';

/// Persists the trial + purchase state on the always-open `settings` box, and
/// derives the current [Entitlement]. Hive-guarded so tests / early boot that
/// haven't opened the box degrade gracefully.
///
/// The trial clock is stored app-side (a one-time product has no server-side
/// trial). A determined user could clear app data to reset it — acceptable for
/// v1: clearing data also wipes their roster/alarms, so it's self-limiting.
class EntitlementStore {
  EntitlementStore._();

  /// Epoch millis of first launch — the trial clock's origin. Written once.
  static const String trialStartedAtKey = 'trial_started_at';

  /// Whether the one-time full-access product has been purchased/restored.
  static const String purchasedKey = 'full_access_purchased';

  /// Derived "app is locked" flag, written whenever entitlement is recomputed.
  /// `AlarmSyncService` reads this SAME key (OR-ed with Holiday Mode) so a
  /// locked app fires no alarms. MUST stay in lock-step with the sync's read.
  static const String lockedKey = 'entitlement_locked';

  /// Derived cap (epoch millis) on how far ahead alarms may be scheduled while
  /// the user is UNPURCHASED — the trial-end instant. `AlarmSyncService` shrinks
  /// its scheduling horizon to this, so NO alarm is ever armed past the trial
  /// (belt-and-braces alongside [lockedKey], which empties the set once lapsed).
  /// Absent once purchased. MUST stay in lock-step with the sync's read.
  static const String horizonCapKey = 'alarm_horizon_cap_ms';

  /// Records the trial start on first ever call and returns it; subsequent calls
  /// return the stored instant unchanged.
  static DateTime ensureTrialStarted(Box box, DateTime now) {
    final existing = box.get(trialStartedAtKey);
    if (existing is int) return DateTime.fromMillisecondsSinceEpoch(existing);
    box.put(trialStartedAtKey, now.millisecondsSinceEpoch);
    box.flush();
    return now;
  }

  static DateTime? trialStartedAt(Box box) {
    final v = box.get(trialStartedAtKey);
    return v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
  }

  static bool isPurchased(Box box) =>
      box.get(purchasedKey, defaultValue: false) as bool;

  static Future<void> setPurchased(Box box, bool value) async {
    await box.put(purchasedKey, value);
    await box.flush();
  }

  static bool isLocked(Box box) =>
      box.get(lockedKey, defaultValue: false) as bool;

  /// The current scheduling-horizon cap, or null when uncapped (purchased).
  static DateTime? horizonCap(Box box) {
    final v = box.get(horizonCapKey);
    return v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null;
  }

  static Future<void> _setLocked(Box box, bool value) async {
    if (box.get(lockedKey) == value) return; // no-op write avoids waking watchers
    await box.put(lockedKey, value);
    await box.flush();
  }

  static Future<void> _setHorizonCap(Box box, DateTime? at) async {
    final ms = at?.millisecondsSinceEpoch;
    if (box.get(horizonCapKey) == ms) return; // unchanged — don't wake watchers
    if (ms == null) {
      await box.delete(horizonCapKey);
    } else {
      await box.put(horizonCapKey, ms);
    }
    await box.flush();
  }

  /// The current entitlement from stored state.
  static Entitlement compute(Box box, DateTime now) => Entitlement(
        purchased: isPurchased(box),
        trialStartedAt: trialStartedAt(box),
        now: now,
      );

  /// Recomputes entitlement and persists the derived gates the alarm sync reads
  /// — [lockedKey] (empties the set once lapsed) and [horizonCapKey] (caps
  /// scheduling at the trial end while unpurchased). Returns the entitlement.
  static Future<Entitlement> refreshLock(Box box, DateTime now) async {
    final e = compute(box, now);
    await _setLocked(box, e.locked);
    await _setHorizonCap(box, e.purchased ? null : e.trialEndsAt);
    return e;
  }
}
