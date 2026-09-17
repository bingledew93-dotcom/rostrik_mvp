import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for a store review once the user has had Rostrik long enough to have
/// an opinion of it — 10 days after first launch.
///
/// Both stores show their own sheet in-app (Play's In-App Review API,
/// StoreKit's `SKStoreReviewController`) and both silently throttle it: the
/// request may show nothing at all, and neither tells you which happened. So
/// this is fire-and-forget by nature — nothing in the app may depend on the
/// outcome, and there is no "did they review" to read back.
///
/// Because the stores stay silent, the ONLY thing that keeps this from
/// pestering people is the guard set below. Asking at a bad moment is worse
/// than not asking: the sheet arrives with a star rating already under the
/// user's thumb, so a user who is annoyed right now is being handed the means
/// to say so.
class ReviewPrompt {
  ReviewPrompt({
    Future<bool> Function()? isAvailable,
    Future<void> Function()? request,
    DateTime Function()? clock,
  })  : _isAvailable = isAvailable ?? InAppReview.instance.isAvailable,
        _request = request ?? InAppReview.instance.requestReview,
        _clock = clock ?? DateTime.now;

  final Future<bool> Function() _isAvailable;
  final Future<void> Function() _request;
  final DateTime Function() _clock;

  /// How long someone must have had the app before being asked. Ten days is
  /// long enough to have been woken by it for a full roster rotation.
  static const Duration minimumAge = Duration(days: 10);

  /// `shared_preferences` key holding the epoch millis of the last request.
  /// Deliberately NOT in the entitlement Hive box: that box is wiped by
  /// Settings → Reset App Data, and a reset should not earn the user a second
  /// review prompt.
  static const String askedAtKey = 'review_prompt_asked_at';

  /// Why a given call did nothing. Returned rather than logged so the decision
  /// is testable — the stores themselves report nothing at all.
  static const String skippedNoInstallDate = 'no install date';
  static const String skippedTooNew = 'installed less than 10 days ago';
  static const String skippedAlreadyAsked = 'already asked';
  static const String skippedLocked = 'trial lapsed — bad moment to ask';
  static const String skippedUnhealthy = 'alarms are broken — bad moment to ask';
  static const String skippedUnavailable = 'store review not available';
  static const String asked = 'asked';

  /// Requests a review if every condition is met. Never throws, never blocks
  /// anything the user is doing. Returns one of the constants above, which is
  /// what the tests assert on.
  ///
  /// [installedAt] is the first-launch instant (the trial clock's origin —
  /// `EntitlementStore.trialStartedAt`). [locked] and [alarmsHealthy] are the
  /// two "is this a good moment" gates; see the class doc for why they matter
  /// more than the timing does.
  Future<String> maybeAsk({
    required DateTime? installedAt,
    required bool locked,
    required bool alarmsHealthy,
  }) async {
    if (installedAt == null) return skippedNoInstallDate;
    if (_clock().difference(installedAt) < minimumAge) return skippedTooNew;

    // Never ask someone we have just cut off from the app they paid attention
    // to for ten days, or someone whose alarms cannot ring. Both are moments
    // where the honest review is a bad one, and neither is the app at its best.
    if (locked) return skippedLocked;
    if (!alarmsHealthy) return skippedUnhealthy;

    if (await _alreadyAsked()) return skippedAlreadyAsked;

    try {
      if (!await _isAvailable()) return skippedUnavailable;
      // Record BEFORE requesting. If the request throws half-way, or the store
      // shows its sheet and the app dies, the user has still been asked as far
      // as they are concerned — asking again is the worse failure.
      await _recordAsked();
      await _request();
      return asked;
    } catch (e) {
      debugPrint('[ReviewPrompt] request failed: $e');
      return skippedUnavailable;
    }
  }

  Future<bool> _alreadyAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(askedAtKey);
    } catch (_) {
      // No preferences (tests, or a broken platform channel): treat as already
      // asked. Failing CLOSED means a storage fault can never turn into a
      // prompt on every single launch.
      return true;
    }
  }

  Future<void> _recordAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(askedAtKey, _clock().millisecondsSinceEpoch);
    } catch (_) {
      // Best-effort; the guard above already fails closed.
    }
  }
}
