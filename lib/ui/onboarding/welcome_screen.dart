import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_preferences.dart';

/// Step 1 of onboarding. Brand hero + value-prop, two instant-save Quick
/// Preferences (clock format, calendar start day), and two exits: the primary
/// "Get Started" (→ permissions/roster flow) and a secondary "Skip / Set up
/// later" so a user who just wants to look around isn't trapped in the funnel.
///
/// Stateless: the Quick Preferences read/write [AppPreferences] (a
/// `ChangeNotifier`) directly, so `context.watch` rebuilds this screen the
/// instant a toggle writes. Provider lookups are tolerant (`<T?>`): pumped
/// without the provider (a bare widget test) the toggles fall back to defaults
/// and writes are no-ops. (The alarm lead time moved to the "Automate my
/// alarms" step, where it sits next to the alarms it shapes.)
class WelcomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = context.watch<AppPreferences?>();
    final use24Hour = prefs?.use24HourTime ?? false;
    final startWeekOnMonday = prefs?.startWeekOnMonday ?? true;

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
              const SizedBox(height: 28),
              Text(
                'The smart alarm clock built for shift workers.',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Alarms that follow your rotating roster — not just weekdays.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 2),
              // Quick Preferences — captured up front, saved the instant they're
              // tapped (no commit step), so the rest of onboarding already
              // renders in the user's chosen clock + week-start.
              _QuickPreferences(
                use24Hour: use24Hour,
                startWeekOnMonday: startWeekOnMonday,
                onTimeFormatChanged: (v) =>
                    context.read<AppPreferences?>()?.setUse24HourTime(v),
                onWeekStartChanged: (mon) =>
                    context.read<AppPreferences?>()?.setStartWeekOnMonday(mon),
              ),
              const Spacer(flex: 2),
              SizedBox(
                height: 56,
                child: FilledButton(
                  key: const ValueKey('welcome-get-started'),
                  onPressed: onContinue,
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
                onPressed: onSkip,
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

/// Two compact A/B preference toggles (clock format, week start). Pure
/// presentation — the parent owns the values + persistence, so each change
/// saves instantly.
class _QuickPreferences extends StatelessWidget {
  const _QuickPreferences({
    required this.use24Hour,
    required this.startWeekOnMonday,
    required this.onTimeFormatChanged,
    required this.onWeekStartChanged,
  });

  final bool use24Hour;
  final bool startWeekOnMonday;
  final ValueChanged<bool> onTimeFormatChanged;
  final ValueChanged<bool> onWeekStartChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _PrefRow(
            icon: Icons.schedule,
            label: 'Time format',
            child: SegmentedButton<bool>(
              key: const ValueKey('welcome-pref-timeformat'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('12h')),
                ButtonSegment(value: true, label: Text('24h')),
              ],
              selected: {use24Hour},
              onSelectionChanged: (s) => onTimeFormatChanged(s.first),
            ),
          ),
          const Divider(height: 8),
          _PrefRow(
            icon: Icons.calendar_today_outlined,
            label: 'Week starts',
            child: SegmentedButton<bool>(
              key: const ValueKey('welcome-pref-weekstart'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Sun')),
                ButtonSegment(value: true, label: Text('Mon')),
              ],
              selected: {startWeekOnMonday},
              onSelectionChanged: (s) => onWeekStartChanged(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
