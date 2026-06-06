import 'package:flutter/material.dart';

/// Slim segmented step indicator for the onboarding core flow — filled
/// segments in the high-vis accent, remaining steps in muted grey. Implements
/// [PreferredSizeWidget] so it drops straight into an `AppBar.bottom`, giving
/// the three roster steps (Choose rotation → Set start date → Automate) a
/// consistent "X of 3" cue without a heavyweight stepper.
class OnboardingProgressBar extends StatelessWidget
    implements PreferredSizeWidget {
  const OnboardingProgressBar({
    super.key,
    required this.step,
    this.total = 3,
  });

  /// 1-based index of the current step (1..[total]).
  final int step;
  final int total;

  @override
  Size get preferredSize => const Size.fromHeight(16);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          for (var i = 1; i <= total; i++) ...[
            if (i > 1) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
