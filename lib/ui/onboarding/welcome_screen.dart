import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/alarm_settings.dart';
import '../../data/repositories/alarm_settings_repository.dart';
import '../shift_format.dart';

/// Step 1 of onboarding. Brand hero + tagline, a "Default alarm lead time"
/// dropdown that captures the engine preference up front, and two exits:
/// the primary "Get Started" (→ permissions/roster flow) and a secondary
/// "Skip / Set up later" so a user who just wants to look around isn't
/// trapped in the funnel.
///
/// Stateful only to mirror the dropdown selection during a pick; the lead
/// time is persisted to [AlarmSettingsRepository] the instant it changes, so
/// the engine has it even if the user skips the rest of onboarding. Provider
/// lookups are tolerant (`<T?>`): pumped without providers (a bare widget
/// test) the dropdown still works against its local fallback.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  final VoidCallback onContinue;

  /// "Set up later" — completes onboarding straight to the dashboard without
  /// generating a roster or arming alarms (the user can do both later).
  final VoidCallback onSkip;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  /// The lead-time presets offered in onboarding (minutes). The Settings
  /// slider still allows any 5-min step; these are the sane starting points.
  static const List<int> _presets = [15, 30, 45, 60, 90, 120];

  /// Local mirror of the picked value. Null until the user changes it — while
  /// null we render from the persisted [AlarmSettings] (or the default).
  int? _picked;

  /// Snaps an arbitrary minute value to the nearest preset so the dropdown
  /// always has a matching item (a previously slider-set 25 min still selects
  /// cleanly) and never trips DropdownButton's value-must-match assert.
  int _nearestPreset(int minutes) {
    var best = _presets.first;
    for (final p in _presets) {
      if ((p - minutes).abs() < (best - minutes).abs()) best = p;
    }
    return best;
  }

  void _commit(int minutes) {
    setState(() => _picked = minutes);
    // Persist immediately so the engine captures it even on Skip. Tolerant:
    // no repo in the tree (bare test) → the local mirror still drives the UI.
    context
        .read<AlarmSettingsRepository?>()
        ?.write(AlarmSettings(leadTime: Duration(minutes: minutes)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Persisted value (tolerant) → local pick wins while the user is choosing.
    final persisted = context.watch<AlarmSettings?>()?.leadTime.inMinutes ??
        AlarmSettings.defaultLeadTime.inMinutes;
    final selected = _nearestPreset(_picked ?? persisted);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              // Brand hero. Uses the bundled logo when present; until
              // `assets/images/rostrik_logo.png` is dropped in, errorBuilder
              // falls back to the original alarm glyph so the screen never
              // shows a broken-image box.
              Center(
                child: Image.asset(
                  'assets/images/rostrik_logo.png',
                  height: 132,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.alarm,
                    size: 96,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to Rostrik',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The reliable alarm and roster app for shift workers.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 2),
              // Lead-time preference, captured before the first roster so the
              // engine fires the very first alarm at the user's chosen offset.
              _LeadTimeField(
                value: selected,
                presets: _presets,
                onChanged: _commit,
              ),
              const Spacer(flex: 2),
              SizedBox(
                height: 56,
                child: FilledButton(
                  key: const ValueKey('welcome-get-started'),
                  onPressed: widget.onContinue,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                key: const ValueKey('welcome-skip-button'),
                onPressed: widget.onSkip,
                child: Text(
                  'Skip / Set up later',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined "Default alarm lead time" dropdown. Pure presentation; the parent
/// owns the value + persistence.
class _LeadTimeField extends StatelessWidget {
  const _LeadTimeField({
    required this.value,
    required this.presets,
    required this.onChanged,
  });

  final int value;
  final List<int> presets;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<int>(
      key: const ValueKey('welcome-lead-time-dropdown'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Default alarm lead time',
        helperText: 'How early the alarm rings before a shift starts.',
        prefixIcon: Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      items: [
        for (final m in presets)
          DropdownMenuItem<int>(
            value: m,
            child: Text(formatLeadTime(m)),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
