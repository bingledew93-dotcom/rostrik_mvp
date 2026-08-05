import 'package:flutter/material.dart';

import 'screen_tip.dart';

/// The first-run coach card for a screen: a soft scrim to draw the eye plus a
/// card explaining what the screen is for and how to use it. Pure presentation —
/// the host ([MainLayout]) owns when to show it and persists the dismissal, so
/// this widget just renders [tip] and reports intent via callbacks.
///
/// Two exits: [onDismiss] ("Got it" / tapping the scrim) hides this one tip;
/// [onDisable] ("Don't show tips") turns the whole system off. Both are
/// reversible from Settings → How it works.
class ScreenTipOverlay extends StatelessWidget {
  const ScreenTipOverlay({
    super.key,
    required this.tip,
    required this.onDismiss,
    required this.onDisable,
  });

  final ScreenTip tip;
  final VoidCallback onDismiss;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      key: const ValueKey('screen-tip-overlay'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Stack(
        children: [
          // Scrim — dims the screen to focus the card; tapping it dismisses
          // (same as "Got it"), the expected "I've read it" gesture.
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('screen-tip-scrim'),
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
            ),
          ),
          // Card, anchored toward the bottom so it never fights a screen's
          // AppBar and sits near the nav bar the tip is about to be used from.
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Material(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(tip.icon,
                                  color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                tip.title,
                                key: const ValueKey('screen-tip-title'),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tip.body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Replay these anytime from Settings › How it works.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton(
                              key: const ValueKey('screen-tip-disable'),
                              onPressed: onDisable,
                              child: Text(
                                "Don't show tips",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const Spacer(),
                            FilledButton(
                              key: const ValueKey('screen-tip-got-it'),
                              onPressed: onDismiss,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
