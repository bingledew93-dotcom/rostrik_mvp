import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../main_layout.dart';
import '../pattern_picker_body.dart';
import 'arm_engine_screen.dart';
import 'onboarding_flow.dart';
import 'onboarding_progress.dart';
import 'onboarding_state.dart';

/// Step 4 of onboarding.
///
/// Thin Scaffold wrapper around [PatternPickerBody], filtered to the
/// [rosterType] picked on step 3. Both the preset path AND the Custom
/// Builder path route through the body's unified `onGenerated`
/// callback — which here flips the `onboardingCompleteKey` Hive flag
/// and `pushAndRemoveUntil`s the [MainLayout] chassis.
///
/// Constructor surface is tiny — the body owns selection, time
/// editing, validation, and generator calls. This wrapper just
/// supplies onboarding-specific chrome (back button) and the
/// onboarding-specific success behaviour.
class PatternPickerOnboardingScreen extends StatelessWidget {
  const PatternPickerOnboardingScreen({
    super.key,
    required this.rosterType,
    required this.onBack,
  });

  final RosterType rosterType;
  final VoidCallback onBack;

  /// The roster is now in Hive. Hand off to the final "Arm your alarms"
  /// step rather than completing here — that screen seeds the default
  /// alarms and only THEN marks onboarding complete (see [_complete]).
  Future<void> _onGenerated(BuildContext context) async {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => ArmEngineScreen(
          onArmComplete: () => _complete(context),
          onBack: navigator.pop,
        ),
      ),
    );
  }

  /// Final completion, invoked by the Arm Engine screen AFTER alarms are
  /// seeded. Flips the first-launch flag and replaces the whole stack with
  /// the Dashboard.
  ///
  /// `onboardingCompleteKey` lives in `onboarding_flow.dart` so main.dart's
  /// first-launch gate reads the same constant we write here — don't
  /// duplicate it. If the user kills the app between the cycle write and this
  /// flag write they re-do onboarding next launch — benign, recoverable via
  /// the cycles list.
  Future<void> _complete(BuildContext context) async {
    final navigator = Navigator.of(context);
    await Hive.box('settings').put(onboardingCompleteKey, true);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainLayout()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text('Pick your rotation'),
        bottom: const OnboardingProgressBar(step: 2),
      ),
      body: PatternPickerBody(
        restrictToType: rosterType,
        onGenerated: () => _onGenerated(context),
      ),
    );
  }
}
