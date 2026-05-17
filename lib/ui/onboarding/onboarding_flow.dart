import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../custom_builder_screen.dart';
import '../main_layout.dart';
import 'onboarding_state.dart';
import 'pattern_picker_onboarding_screen.dart';
import 'permissions_screen.dart';
import 'roster_type_screen.dart';
import 'welcome_screen.dart';

/// Hive box key the first-launch gate reads to decide whether to show
/// onboarding or the MainLayout chassis. Lives on the existing
/// `settings` box (no schema bump). False by default; flipped to true
/// only after a successful step-4 generation, which is handled inside
/// [PatternPickerOnboardingScreen]'s onGenerated callback.
///
/// Kept here (not co-located with the writer) because `main.dart`'s
/// first-launch gate also reads it; this is the canonical export site.
const String onboardingCompleteKey = 'onboarding_complete';

/// Root widget for the 4-step onboarding flow. Holds the shared
/// [OnboardingState] and renders the active step via `switch (_step)`.
///
/// Step 4 (the pattern picker) drives generation + the post-success
/// navigation itself via [PatternPickerBody]'s onGenerated callback —
/// this controller is only responsible for stepping forward/back and
/// passing the picked rosterType down.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final OnboardingState _state = OnboardingState();
  int _step = 0;

  void _next() => setState(() => _step += 1);
  void _back() => setState(() => _step = (_step - 1).clamp(0, 3));

  /// Custom-card path on step 3. Skips the preset picker entirely —
  /// pushes [CustomBuilderScreen] directly. If the user generates a
  /// roster there (the screen pops `true`), we mark onboarding
  /// complete and replace the whole stack with [MainLayout]. If they
  /// back out (`null`), we just return to step 3 with no state
  /// change.
  Future<void> _launchCustomBuilder() async {
    final navigator = Navigator.of(context);
    final generated = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => const CustomBuilderScreen()),
    );
    if (generated != true || !mounted) return;
    await Hive.box('settings').put(onboardingCompleteKey, true);
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainLayout()),
      (_) => false,
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return WelcomeScreen(onContinue: _next);
      case 1:
        return PermissionsScreen(
          onBack: _back,
          onContinue: _next,
        );
      case 2:
        return RosterTypeScreen(
          selected: _state.rosterType,
          onSelect: (t) => setState(() => _state.rosterType = t),
          onCustomTap: _launchCustomBuilder,
          onBack: _back,
          onContinue: _next,
        );
      case 3:
        return PatternPickerOnboardingScreen(
          // `rosterType` is guaranteed non-null by the step-3 Continue
          // gate (which only enables for day / night / rotating).
          rosterType: _state.rosterType!,
          onBack: _back,
        );
      default:
        // Unreachable — _step is clamped 0..3. Defensive fallback so
        // the build doesn't return null on a programming error.
        return WelcomeScreen(onContinue: _next);
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope intercepts the system back gesture: if we're past step 0
    // we step back; on step 0 we let the OS pop (which on a fresh
    // install closes the app — the right behaviour).
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _back();
      },
      child: _buildStep(),
    );
  }
}
