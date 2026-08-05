import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/alarm_settings.dart';
import '../../data/models/app_alarm.dart';
import '../../data/models/shift.dart';
import '../../logic/sleep_plan.dart';
import '../../state/app_preferences.dart';
import '../app_theme.dart';
import '../settings_screen.dart';
import '../shift_format.dart';

/// Context-aware Sleep tab. Reads the live roster (`List<Shift>`), alarm rules,
/// the global lead time, and the user's sleep preferences, then renders a
/// dynamic hero plan plus the (UI-only, for now) reminder / wind-down / sounds
/// controls.
///
/// All the planning brains live in the pure [computeSleepPlan]; this screen is
/// presentation only. It degrades gracefully to a calm empty state when there
/// is no upcoming shift.
class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shifts = context.watch<List<Shift>>();
    final alarms = context.watch<List<AppAlarm>>();
    final settings = context.watch<AlarmSettings>();
    final prefs = context.watch<AppPreferences>();

    final plan = computeSleepPlan(
      shifts: shifts,
      alarms: alarms,
      globalLeadMinutes: settings.leadTime.inMinutes,
      sleepGoalHours: prefs.sleepGoalHours,
      windDownMinutes: prefs.windDownMinutes,
      now: DateTime.now(),
      isSchedulePaused: prefs.isSchedulePaused,
    );
    final use24Hour = prefs.use24HourTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep'),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // BETA LOCKDOWN: the reminders / wind-down / sounds backend is a
            // Phase-2 item, so the controls below are shown (so testers see the
            // plan) but disabled — wrapped in [_LockedControl], which fades them
            // and routes any tap to the "coming soon" snackbar.
            const _BetaLimitationBanner(),
            const SizedBox(height: 16),
            _SleepHeroCard(plan: plan, use24Hour: use24Hour),
            const SizedBox(height: 28),
            const _SectionHeader('REMINDERS'),
            const SizedBox(height: 4),
            _LockedControl(
              child:
                  _RemindersSection(plan: plan, prefs: prefs, use24Hour: use24Hour),
            ),
            const SizedBox(height: 28),
            const _SectionHeader('WIND-DOWN DURATION'),
            const SizedBox(height: 12),
            _LockedControl(
              child: _WindDownDurationChips(selectedMinutes: prefs.windDownMinutes),
            ),
            const SizedBox(height: 28),
            const _SectionHeader('SLEEP SOUNDS'),
            const SizedBox(height: 12),
            const _LockedControl(child: _SleepSoundsGrid()),
          ],
        ),
      ),
    );
  }
}

/// M3 small-caps section label — same rhythm as the Settings screen sections.
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

// ─── Beta lockdown ──────────────────────────────────────────────────────────

/// Shown whenever a gated Sleep control is tapped while the Phase-2 backend is
/// still under construction.
const String _kComingSoonMessage =
    'Coming soon! We are perfecting the alarm engine first.';

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text(_kComingSoonMessage)));
}

/// Premium "under construction" banner pinned at the top of the Sleep tab. It
/// uses the brand orange so it reads as an intentional status, not an error.
class _BetaLimitationBanner extends StatelessWidget {
  const _BetaLimitationBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('sleep-beta-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kRostrikOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kRostrikOrange.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.construction, color: kRostrikOrange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beta Limitation',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: kRostrikOrange,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sleep & Wind-down intelligence is currently under '
                  'construction for Phase 2.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a not-yet-functional control: fades it (so it reads as disabled) and
/// IgnorePointers its inner gestures, then lays a transparent tap-catcher over
/// the whole thing so ANY tap surfaces the "coming soon" snackbar instead of
/// silently doing nothing.
class _LockedControl extends StatelessWidget {
  const _LockedControl({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.45,
          child: IgnorePointer(child: child),
        ),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showComingSoon(context),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Hero card ──────────────────────────────────────────────────────────────

/// Premium, roster-aware hero. Switches presentation on [SleepPlan.state].
class _SleepHeroCard extends StatelessWidget {
  const _SleepHeroCard({required this.plan, required this.use24Hour});

  final SleepPlan plan;
  final bool use24Hour;

  @override
  Widget build(BuildContext context) {
    final Widget content = switch (plan.state) {
      SleepPlanState.none => const _NoPlanContent(),
      SleepPlanState.nightTransition => const _NightTransitionContent(),
      SleepPlanState.restRecovery => const _RestRecoveryContent(),
      SleepPlanState.activeTarget =>
        _ActiveTargetContent(plan: plan, use24Hour: use24Hour),
    };
    return _HeroShell(child: content);
  }
}

/// Deep indigo→black gradient panel with a faint orange edge — reads as
/// "night" while staying inside the app's dark/orange identity.
class _HeroShell extends StatelessWidget {
  const _HeroShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1C30), Color(0xFF0D0D12)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kRostrikOrange.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
}

/// State 0 — no upcoming shift. Calm, non-alarming.
class _NoPlanContent extends StatelessWidget {
  const _NoPlanContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.bedtime_outlined,
            color: theme.colorScheme.primary, size: 30),
        const SizedBox(height: 14),
        Text(
          'Nothing to plan tonight',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add a shift to your roster and Rostrik will build a personalised '
          'bedtime around your next wake-up.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// State 1 — next working shift is a future Night shift (rest day before it).
/// Advisory copy only: this is a transition day, so "sleep in".
class _NightTransitionContent extends StatelessWidget {
  const _NightTransitionContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.nightlight_round,
                color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'TRANSITION DAY',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Tomorrow is a Night Shift. Consider sleeping in.',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "It's a transition day — you have a rest day before nights, so "
          "there's no early alarm to chase. Bank extra rest now and let your "
          'body drift later tonight.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// State — next working shift is beyond the 36h planning horizon. Calm,
/// non-prescriptive: no bedtime to chase, recovery is the message. Shares the
/// label + headline + body rhythm of the other advisory states.
class _RestRecoveryContent extends StatelessWidget {
  const _RestRecoveryContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.spa_outlined,
                color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'REST & RECOVERY',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'No early alarm to chase',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Your next shift is more than a day away, so there's no wake-up to "
          'plan tonight. Sleep on your own clock and bank some recovery — '
          'Rostrik will build your bedtime plan as it draws closer.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// State 2 — a normal wake target. Bedtime is the hero; wind-down / wake /
/// duration are the supporting stats.
class _ActiveTargetContent extends StatelessWidget {
  const _ActiveTargetContent({required this.plan, required this.use24Hour});

  final SleepPlan plan;
  final bool use24Hour;

  String _clock(DateTime? t) =>
      t == null ? '—' : formatClock(t.hour * 60 + t.minute, use24Hour: use24Hour);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TONIGHT'S PLAN",
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.bedtime,
                color: theme.colorScheme.primary, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target bedtime',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _clock(plan.targetBedtime),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
        const SizedBox(height: 14),
        Row(
          children: [
            _PlanStat(label: 'Wind-down', value: _clock(plan.windDownTime)),
            _PlanStat(label: 'Wake up', value: _clock(plan.wakeTime)),
            _PlanStat(label: 'Duration', value: '${plan.sleepGoalHours}h'),
          ],
        ),
      ],
    );
  }
}

/// One labelled stat in the active-plan stat row. Expands so three sit evenly.
class _PlanStat extends StatelessWidget {
  const _PlanStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reminders ────────────────────────────────────────────────────────────

/// Two reminder toggles. State + persistence only (no notification wiring yet);
/// subtitles surface the computed times when a concrete plan exists. Active
/// track inherits the theme's safety-orange via `switchTheme`.
class _RemindersSection extends StatelessWidget {
  const _RemindersSection({
    required this.plan,
    required this.prefs,
    required this.use24Hour,
  });

  final SleepPlan plan;
  final AppPreferences prefs;
  final bool use24Hour;

  String? _clock(DateTime? t) =>
      t == null ? null : formatClock(t.hour * 60 + t.minute, use24Hour: use24Hour);

  @override
  Widget build(BuildContext context) {
    final bedtime = plan.state == SleepPlanState.activeTarget
        ? _clock(plan.targetBedtime)
        : null;
    final windDown = plan.state == SleepPlanState.activeTarget
        ? _clock(plan.windDownTime)
        : null;
    return Column(
      children: [
        SwitchListTile(
          key: const ValueKey('sleep-bedtime-reminder-toggle'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Bedtime Reminder'),
          subtitle: Text(
            bedtime != null
                ? 'Nudge me at $bedtime to head to bed'
                : "A nudge when it's time to head to bed",
          ),
          value: prefs.bedtimeReminderEnabled,
          // Disabled for the beta — onChanged:null renders the greyed switch;
          // the [_LockedControl] overlay catches taps and shows the snackbar.
          onChanged: null,
        ),
        SwitchListTile(
          key: const ValueKey('sleep-winddown-reminder-toggle'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Wind-Down Reminder'),
          subtitle: Text(
            windDown != null
                ? 'Nudge me at $windDown to start winding down'
                : 'An earlier heads-up to start winding down',
          ),
          value: prefs.windDownReminderEnabled,
          onChanged: null,
        ),
      ],
    );
  }
}

// ─── Wind-down duration chips ────────────────────────────────────────────────

class _WindDownDurationChips extends StatelessWidget {
  const _WindDownDurationChips({required this.selectedMinutes});

  final int selectedMinutes;

  static const List<int> _options = <int>[15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      children: _options.map((m) {
        final selected = selectedMinutes == m;
        return ChoiceChip(
          label: Text('${m}m'),
          selected: selected,
          showCheckmark: false,
          selectedColor: kRostrikOrange,
          // Disabled for the beta — onSelected:null greys the chip; the
          // [_LockedControl] overlay catches taps and shows the snackbar.
          onSelected: null,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            color: selected ? Colors.black : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

// ─── Sleep sounds (mocked) ──────────────────────────────────────────────────

class _SleepSoundsGrid extends StatelessWidget {
  const _SleepSoundsGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _SoundCard(icon: Icons.grain, label: 'Rain')),
        SizedBox(width: 12),
        Expanded(child: _SoundCard(icon: Icons.waves, label: 'Ocean')),
        SizedBox(width: 12),
        Expanded(
          child: _SoundCard(icon: Icons.graphic_eq, label: 'White Noise'),
        ),
      ],
    );
  }
}

/// A premium sound tile. The audio engine is a Phase-2 item; the whole grid is
/// wrapped in [_LockedControl], so this is a pure visual — taps are caught by
/// the overlay and routed to the "coming soon" snackbar.
class _SoundCard extends StatelessWidget {
  const _SoundCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 30),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
