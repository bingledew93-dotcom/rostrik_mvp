/// Pure, device-free entitlement logic for the 14-day free trial + one-time
/// "full access" purchase (feature #4).
///
/// Rostrik gives full access for [kTrialDuration] from first launch. After that
/// the app is LOCKED until the one-time [kFullAccessProductId] purchase is made
/// — and a locked app fires no alarms (the alarm sync treats lockout like
/// Holiday Mode). Kept pure (inputs → [Entitlement]) so the trial maths is
/// unit-tested with a frozen clock, mirroring `SustainedShakeDetector` and the
/// injected-clock services.
library;

/// How long full access lasts from first launch before a purchase is required.
const Duration kTrialDuration = Duration(days: 14);

/// Google Play product id for the one-time full-access unlock. MUST match the
/// managed product created in the Play Console.
const String kFullAccessProductId = 'rostrik_full_access';

/// A snapshot of the user's access rights at a given [now].
class Entitlement {
  const Entitlement({
    required this.purchased,
    required this.trialStartedAt,
    required this.now,
    this.trialDuration = kTrialDuration,
  });

  /// Whether the one-time full-access product has been bought (or restored).
  final bool purchased;

  /// When the trial clock started (first launch). Null means "not started yet"
  /// — treated as if it starts now, so a brand-new install is inside its trial.
  final DateTime? trialStartedAt;

  final DateTime now;
  final Duration trialDuration;

  /// The instant the trial lapses. For a not-yet-started trial this is
  /// `now + trialDuration` (the install is on day 0).
  DateTime get trialEndsAt =>
      (trialStartedAt ?? now).add(trialDuration);

  /// True while the free trial is still running.
  bool get withinTrial => now.isBefore(trialEndsAt);

  /// Full access is granted while purchased OR inside the trial.
  bool get entitled => purchased || withinTrial;

  /// The app is locked (and alarms suppressed) when not entitled.
  bool get locked => !entitled;

  /// Whole days of trial remaining (rounded up so "18 hours left" reads as
  /// "1 day"). 0 once purchased or once the trial has lapsed.
  int get trialDaysLeft {
    if (purchased || !withinTrial) return 0;
    final ms = trialEndsAt.difference(now).inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / Duration.millisecondsPerDay).ceil();
  }

  /// When to fire the "trial ends tomorrow" reminder — one day before expiry.
  /// Null when there's no useful reminder to schedule (already purchased, or the
  /// reminder instant is already in the past).
  DateTime? get trialEndingReminderAt {
    if (purchased) return null;
    final at = trialEndsAt.subtract(const Duration(days: 1));
    return at.isAfter(now) ? at : null;
  }
}
