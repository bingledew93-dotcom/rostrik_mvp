import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../main_layout.dart';
import '../pattern_picker_body.dart';
import 'onboarding_flow.dart';
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

  Future<void> _onGenerated(BuildContext context) async {
    // Mark complete only after a successful generate (handled by the
    // body before this callback fires). If the user kills the app
    // between the cycle write and this flag write, they re-do
    // onboarding next launch — benign degraded mode, recoverable
    // via the cycles list.
    //
    // `onboardingCompleteKey` lives in `onboarding_flow.dart` so
    // main.dart's first-launch gate reads the same constant we write
    // here. Don't duplicate it.
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
      ),
      body: PatternPickerBody(
        restrictToType: rosterType,
        onGenerated: () => _onGenerated(context),
      ),
    );
  }
}
