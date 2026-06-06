import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_preferences.dart';
import '../pattern_picker_screen.dart';
import '../settings_screen.dart';
import '../shift_editor_modal.dart';

/// The roster **manipulation** hub (post the "Great Migration"). Viewing lives
/// on the Timeline tab; this tab is purely for acting on the roster.
///
/// Three action cards, UI-first: only "Generate Rotation" is wired (to the
/// existing pattern-picker setup flow). "Add Custom Shift" and "Pause Schedule"
/// are intentionally inert placeholders for upcoming phases.
class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const _SectionHeader('ROSTER TOOLS'),
            const SizedBox(height: 4),
            Text(
              'Build and adjust the shifts that drive your alarms and sleep '
              'plan.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            _ActionCard(
              key: const ValueKey('manage-generate-rotation'),
              icon: Icons.event_repeat,
              title: 'Generate Rotation',
              subtitle: 'Build a repeating shift pattern from a template.',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PatternPickerScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              key: const ValueKey('manage-add-custom-shift'),
              icon: Icons.add_circle_outline,
              title: 'Add Custom Shift',
              subtitle: 'Drop a single one-off shift onto your roster.',
              trailing: const Icon(Icons.chevron_right),
              // The quick-add modal that used to hang off the Timeline FAB now
              // lives here, on the manipulation hub.
              onTap: () => showShiftEditorModal(context),
            ),
            const SizedBox(height: 12),
            const _PauseScheduleCard(),
          ],
        ),
      ),
    );
  }
}

/// M3 small-caps section label — same rhythm as Settings / Sleep.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// A tappable roster-tool card: orange-tinted glyph, title + subtitle, and a
/// trailing affordance (chevron for actions; a control for stateful cards).
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                IconTheme.merge(
                  data: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Pause Schedule / Holiday Mode" — live. Bound to
/// [AppPreferences.isSchedulePaused]; flipping it on disarms every alarm and
/// dorments the Sleep plan (roster data untouched). When armed-off the switch
/// goes warning-red — deliberately NOT the armed-orange — so a disarmed app
/// reads as a distinct, slightly alarming state at a glance.
class _PauseScheduleCard extends StatelessWidget {
  const _PauseScheduleCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Tolerant read so the card renders even where AppPreferences isn't in the
    // tree (e.g. an isolated widget test); the write is likewise guarded.
    final paused = AppPreferences.isSchedulePausedOf(context);
    return _ActionCard(
      icon: paused ? Icons.pause_circle : Icons.pause_circle_outline,
      title: 'Pause Schedule',
      subtitle: paused
          ? 'Holiday mode ON — alarms are silenced, your roster is safe.'
          : "Holiday mode — silence alarms while you're off-roster.",
      trailing: Switch(
        key: const ValueKey('manage-pause-toggle'),
        value: paused,
        onChanged: (v) =>
            context.read<AppPreferences?>()?.setIsSchedulePaused(v),
        // Disarmed = warning red, never the armed-orange the rest of the app
        // uses for "active" states.
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? theme.colorScheme.error
              : null,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? theme.colorScheme.onError
              : null,
        ),
      ),
    );
  }
}
