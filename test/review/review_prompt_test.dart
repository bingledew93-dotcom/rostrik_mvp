import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/legal/legal.dart';
import 'package:rostrik_mvp/review/review_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The store never tells you whether its review sheet appeared, so the guards
/// here are the only thing standing between a user and a badly-timed prompt.
/// They are pinned individually.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final installed = DateTime(2026, 9, 1, 8);
  final elevenDaysLater = DateTime(2026, 9, 12, 8);

  late int requests;

  ReviewPrompt build({
    bool available = true,
    DateTime? now,
  }) {
    return ReviewPrompt(
      isAvailable: () async => available,
      request: () async => requests++,
      clock: () => now ?? elevenDaysLater,
    );
  }

  setUp(() {
    requests = 0;
    // Legal consent up to date in the default fixture: the prompt refuses to
    // speak over an open gate, so without this every test below would skip.
    SharedPreferences.setMockInitialValues({
      'flutter.$kAcceptedLegalVersionKey': kCurrentLegalVersion,
    });
  });

  Future<String> ask(
    ReviewPrompt prompt, {
    DateTime? installedAt,
    bool locked = false,
    bool healthy = true,
  }) =>
      prompt.maybeAsk(
        installedAt: installedAt ?? installed,
        locked: locked,
        alarmsHealthy: healthy,
      );

  test('asks once the app is 10 days old and nothing is wrong', () async {
    expect(await ask(build()), ReviewPrompt.asked);
    expect(requests, 1);
  });

  test('says nothing before 10 days', () async {
    final dayNine = installed.add(const Duration(days: 9, hours: 23));
    expect(await ask(build(now: dayNine)), ReviewPrompt.skippedTooNew);
    expect(requests, 0);
  });

  test('10 days exactly is enough', () async {
    final exactly = installed.add(ReviewPrompt.minimumAge);
    expect(await ask(build(now: exactly)), ReviewPrompt.asked);
  });

  test('never asks without an install date', () async {
    // A null date means first launch has not written the trial origin yet —
    // age is unknowable, so there is nothing to be confident about.
    final prompt = build();
    expect(
      await prompt.maybeAsk(
          installedAt: null, locked: false, alarmsHealthy: true),
      ReviewPrompt.skippedNoInstallDate,
    );
    expect(requests, 0);
  });

  group('bad moments', () {
    test('never asks a user whose trial has just lapsed', () async {
      // They are looking at a paywall. The sheet would arrive with a star
      // rating under their thumb at the worst possible moment.
      expect(await ask(build(), locked: true), ReviewPrompt.skippedLocked);
      expect(requests, 0);
    });

    test('never asks a user whose alarms cannot ring', () async {
      expect(
          await ask(build(), healthy: false), ReviewPrompt.skippedUnhealthy);
      expect(requests, 0);
    });

    test('a bad moment does not burn the one prompt — it asks later',
        () async {
      expect(await ask(build(), locked: true), ReviewPrompt.skippedLocked);
      expect(await ask(build()), ReviewPrompt.asked,
          reason: 'the skip must not have recorded an ask');
      expect(requests, 1);
    });
  });

  test('asks only once, ever', () async {
    expect(await ask(build()), ReviewPrompt.asked);
    expect(await ask(build()), ReviewPrompt.skippedAlreadyAsked);
    expect(await ask(build()), ReviewPrompt.skippedAlreadyAsked);
    expect(requests, 1);
  });

  test('an unavailable store is not recorded as an ask', () async {
    expect(await ask(build(available: false)), ReviewPrompt.skippedUnavailable);
    expect(requests, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(ReviewPrompt.askedAtKey), isFalse);
  });

  test('a throwing store request is swallowed and counts as asked', () async {
    // Recorded BEFORE the request precisely so a half-way failure cannot
    // re-prompt: as far as the user is concerned the sheet may well have shown.
    final prompt = ReviewPrompt(
      isAvailable: () async => true,
      request: () async => throw StateError('no store'),
      clock: () => elevenDaysLater,
    );
    expect(
      await prompt.maybeAsk(
          installedAt: installed, locked: false, alarmsHealthy: true),
      ReviewPrompt.skippedUnavailable,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(ReviewPrompt.askedAtKey), isTrue,
        reason: 'must not ask again after a failed request');
  });

  test('the recorded timestamp is when it asked', () async {
    await ask(build());
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getInt(ReviewPrompt.askedAtKey),
      elevenDaysLater.millisecondsSinceEpoch,
    );
  });

  test('ten days is the documented threshold', () {
    expect(ReviewPrompt.minimumAge, const Duration(days: 10));
  });

  group('never speaks over an open legal gate', () {
    // Found on a Pixel 2026-09-18. The legal update notice renders OVER the
    // running app, so the Dashboard built and probed underneath it and fired
    // this — the Play review sheet landed on top of a consent the user had not
    // given. Two stacked prompts, five stars in front.
    test('a pending legal UPDATE silences it', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.$kAcceptedLegalVersionKey': '2026-06-15',
      });
      expect(await ask(build()), ReviewPrompt.skippedLegalPending);
      expect(requests, 0);
    });

    test('a first-run user with no consent yet silences it', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await ask(build()), ReviewPrompt.skippedLegalPending);
      expect(requests, 0);
    });

    test('and it does not burn the one prompt — it asks once accepted',
        () async {
      SharedPreferences.setMockInitialValues({
        'flutter.$kAcceptedLegalVersionKey': '2026-06-15',
      });
      expect(await ask(build()), ReviewPrompt.skippedLegalPending);

      // The user accepts; the gate closes.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kAcceptedLegalVersionKey, kCurrentLegalVersion);

      expect(await ask(build()), ReviewPrompt.asked);
      expect(requests, 1);
    });
  });
}
