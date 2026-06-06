import 'package:flutter/material.dart';

import '../../data/models/shift_type.dart';
import '../roster/shift_visuals.dart';
import 'onboarding_progress.dart';
import 'onboarding_state.dart';

/// Step 3 of onboarding. 2×2 grid of roster types.
///
/// Day / Night / Rotating route to step 4 (the categorized preset
/// picker) via [onSelect] → [onContinue]. **Custom** is an immediate
/// action — tapping it fires [onCustomTap], which the flow controller
/// uses to push [CustomBuilderScreen] directly (bypassing step 4) and
/// to complete onboarding when the user generates a roster there.
class RosterTypeScreen extends StatelessWidget {
  const RosterTypeScreen({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onCustomTap,
    required this.onBack,
    required this.onContinue,
  });

  final RosterType? selected;
  final ValueChanged<RosterType> onSelect;

  /// Fired when the user taps the Custom card. Skips the per-roster
  /// preset picker entirely and lands on [CustomBuilderScreen].
  final VoidCallback onCustomTap;

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text('Choose a roster type'),
        bottom: const OnboardingProgressBar(step: 1),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                child: Text(
                  'What does your roster look like?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  // Cards are colour-coded by shift type so a user can ID a
                  // roster at a glance — the same palette the calendar and
                  // timeline use (`visualFor`): Day = amber, Night = indigo.
                  _RosterTypeCard(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Day Shifts',
                    enabled: true,
                    accent: visualFor(ShiftType.day).color,
                    selected: selected == RosterType.day,
                    onTap: () => onSelect(RosterType.day),
                  ),
                  _RosterTypeCard(
                    icon: Icons.nightlight_outlined,
                    label: 'Night Shifts',
                    enabled: true,
                    accent: visualFor(ShiftType.night).color,
                    selected: selected == RosterType.night,
                    onTap: () => onSelect(RosterType.night),
                  ),
                  _RosterTypeCard(
                    icon: Icons.sync_outlined,
                    label: 'Rotating',
                    enabled: true,
                    // Rotating mixes Day + Night, so its accent alternates the
                    // two via a gradient.
                    accent: visualFor(ShiftType.day).color,
                    accentGradient: [
                      visualFor(ShiftType.day).color,
                      visualFor(ShiftType.night).color,
                    ],
                    selected: selected == RosterType.rotating,
                    onTap: () => onSelect(RosterType.rotating),
                  ),
                  _RosterTypeCard(
                    icon: Icons.tune_outlined,
                    label: 'Custom',
                    enabled: true,
                    // Custom isn't a shift type — keep the brand accent.
                    accent: theme.colorScheme.primary,
                    // Custom is action-on-tap, not selection. It never
                    // sets `selected = RosterType.custom`; tapping
                    // pushes the builder via the flow controller.
                    selected: false,
                    onTap: onCustomTap,
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: FilledButton(
                  // Continue gates on having picked one of the three
                  // preset-driven types. Custom is its own
                  // immediate-action path (see `onCustomTap`) and
                  // never sets `selected`, so it can't satisfy this
                  // gate — that's intentional.
                  onPressed: (selected == RosterType.day ||
                          selected == RosterType.night ||
                          selected == RosterType.rotating)
                      ? onContinue
                      : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RosterTypeCard extends StatelessWidget {
  const _RosterTypeCard({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.accent,
    this.accentGradient,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  /// Shift-type colour for this card (the selected border + icon tint).
  final Color accent;

  /// When set (Rotating), the icon is painted with this gradient instead of a
  /// flat [accent] — conveying that the roster mixes shift types.
  final List<Color>? accentGradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColour =
        selected ? accent : theme.colorScheme.outlineVariant;
    final borderWidth = selected ? 2.5 : 1.0;
    final gradient = accentGradient;
    final iconWidget = gradient == null
        ? Icon(icon, size: 40, color: accent)
        : ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(rect),
            child: Icon(icon, size: 40, color: Colors.white),
          );
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColour, width: borderWidth),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    iconWidget,
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!enabled)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Coming soon',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
