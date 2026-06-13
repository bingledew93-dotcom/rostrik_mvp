import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/repositories/alarm_settings_repository.dart';
import 'package:rostrik_mvp/ui/onboarding/welcome_screen.dart';

import '../../alarms/fakes.dart';

void main() {
  Future<FakeAlarmSettingsRepository> pumpWelcome(
    WidgetTester tester, {
    VoidCallback? onContinue,
    VoidCallback? onSkip,
    AlarmSettings settings = AlarmSettings.defaults,
  }) async {
    final repo = FakeAlarmSettingsRepository();
    await repo.write(settings);
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AlarmSettingsRepository>.value(value: repo),
          Provider<AlarmSettings>.value(value: settings),
        ],
        child: MaterialApp(
          home: WelcomeScreen(
            onContinue: onContinue ?? () {},
            onSkip: onSkip ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('shows Get Started and a Skip / Set up later exit',
      (tester) async {
    var started = false;
    var skipped = false;
    await pumpWelcome(
      tester,
      onContinue: () => started = true,
      onSkip: () => skipped = true,
    );

    expect(find.byKey(const ValueKey('welcome-get-started')), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-skip-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('welcome-skip-button')));
    expect(skipped, isTrue);
    expect(started, isFalse);

    await tester.tap(find.byKey(const ValueKey('welcome-get-started')));
    expect(started, isTrue);
  });

  testWidgets('lead-time dropdown defaults to the persisted value (1 h)',
      (tester) async {
    await pumpWelcome(tester); // defaults = 60 min
    expect(find.byKey(const ValueKey('welcome-lead-time-dropdown')),
        findsOneWidget);
    // The closed field shows the formatted default.
    expect(find.text('1 h'), findsOneWidget);
  });

  testWidgets('picking a lead time persists it to the settings repo',
      (tester) async {
    final repo = await pumpWelcome(tester);

    // Open the dropdown menu, then choose 30 min (absent from the closed field).
    await tester.tap(find.byKey(const ValueKey('welcome-lead-time-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 min').last);
    await tester.pumpAndSettle();

    final persisted = await repo.read();
    expect(persisted.leadTime, const Duration(minutes: 30));
    // The field now reflects the new selection.
    expect(find.text('30 min'), findsOneWidget);
  });
}
