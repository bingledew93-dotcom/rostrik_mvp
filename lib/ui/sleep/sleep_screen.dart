import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/alarm_settings.dart';
import '../../data/models/app_alarm.dart';
import '../../data/models/shift.dart';
import '../../logic/sleep_plan.dart';
import '../../sleep/sleep_sound_controller.dart';
import '../../sleep/sleep_sounds_catalog.dart';
import '../../state/app_preferences.dart';
import '../app_theme.dart';
import '../settings_screen.dart';
import '../shift_format.dart';

/// Context-aware Sleep tab. Reads the live roster (`List<Shift>`), alarm rules,
/// the global lead time, and the user's sleep preferences, then renders a
/// dynamic hero plan plus the working reminder / wind-down / sound controls.
///
/// The planning brains live in the pure [computeSleepPlan]; the reminder
/// scheduling is handled off-screen by `SleepReminderService` (which watches the
/// same preferences these toggles write), and sound playback by the native
/// `SleepSoundService` via [SleepSoundController]. This screen is presentation +
/// preference writes only.
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
            _SleepHeroCard(plan: plan, use24Hour: use24Hour),
            const SizedBox(height: 28),

            // ── Sleep target (hours) ─────────────────────────────────────────
            const _SectionHeader('SLEEP TARGET'),
            const SizedBox(height: 4),
            const _SectionSub(
              'How many hours you want. Rostrik counts back from your next '
              'wake-up alarm to set tonight’s bedtime.',
            ),
            const SizedBox(height: 12),
            _TargetHoursChips(
              selectedHours: prefs.sleepGoalHours,
              onSelected: (h) => context.read<AppPreferences>().setSleepGoalHours(h),
            ),
            const SizedBox(height: 28),

            // ── Reminders ────────────────────────────────────────────────────
            const _SectionHeader('REMINDERS'),
            const SizedBox(height: 4),
            _RemindersSection(
              plan: plan,
              prefs: prefs,
              use24Hour: use24Hour,
              onBedtimeChanged: (v) =>
                  context.read<AppPreferences>().setBedtimeReminderEnabled(v),
              onWindDownChanged: (v) =>
                  context.read<AppPreferences>().setWindDownReminderEnabled(v),
            ),
            const SizedBox(height: 28),

            // ── Wind-down lead (how early the wind-down nudge fires) ─────────
            const _SectionHeader('WIND-DOWN LEAD'),
            const SizedBox(height: 4),
            const _SectionSub(
              'How long before bedtime the wind-down nudge lands.',
            ),
            const SizedBox(height: 12),
            _WindDownDurationChips(
              selectedMinutes: prefs.windDownMinutes,
              onSelected: (m) =>
                  context.read<AppPreferences>().setWindDownMinutes(m),
            ),
            const SizedBox(height: 28),

            // ── Sleep sounds ─────────────────────────────────────────────────
            const _SectionHeader('SLEEP SOUNDS'),
            const SizedBox(height: 4),
            const _SectionSub(
              'White & brown noise to drift off to. Pick an auto-stop timer and '
              'tap a sound.',
            ),
            const SizedBox(height: 12),
            _SleepTimerChips(
              selectedMinutes: prefs.sleepSoundTimerMinutes,
              onSelected: (m) => _onTimerChanged(context, m),
            ),
            const SizedBox(height: 14),
            _SleepSoundsGrid(timerMinutes: prefs.sleepSoundTimerMinutes),
          ],
        ),
      ),
    );
  }

  /// Persists the new auto-stop timer, and — if a sound is already playing —
  /// restarts it with the new timer so the change takes effect immediately.
  void _onTimerChanged(BuildContext context, int minutes) {
    context.read<AppPreferences>().setSleepSoundTimerMinutes(minutes);
    final controller = context.read<SleepSoundController?>();
    final playing = controller?.playingResource;
    if (controller != null && playing != null) {
      final sound = kSleepSounds.firstWhere(
        (s) => s.resource == playing,
        orElse: () => kSleepSounds.first,
      );
      controller.play(sound, timerMinutes: minutes);
    }
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

/// Muted one-line description under a section header.
class _SectionSub extends StatelessWidget {
  const _SectionSub(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.35,
      ),
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
/// non-prescriptive: no bedtime to chase, recovery is the message.
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

// ─── Sleep target chips ──────────────────────────────────────────────────────

class _TargetHoursChips extends StatelessWidget {
  const _TargetHoursChips({
    required this.selectedHours,
    required this.onSelected,
  });

  final int selectedHours;
  final ValueChanged<int> onSelected;

  static const List<int> _options = <int>[6, 7, 8, 9, 10];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _options.map((h) {
        final selected = selectedHours == h;
        return ChoiceChip(
          key: ValueKey('sleep-goal-$h'),
          label: Text('${h}h'),
          selected: selected,
          showCheckmark: false,
          selectedColor: kRostrikOrange,
          onSelected: (_) => onSelected(h),
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            color: selected ? Colors.black : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

// ─── Reminders ────────────────────────────────────────────────────────────

/// Two wired reminder toggles. Persisting to [AppPreferences] flips the pref
/// that `SleepReminderService` watches, which schedules / cancels the nudge.
/// Subtitles surface the computed times when a concrete plan exists.
class _RemindersSection extends StatelessWidget {
  const _RemindersSection({
    required this.plan,
    required this.prefs,
    required this.use24Hour,
    required this.onBedtimeChanged,
    required this.onWindDownChanged,
  });

  final SleepPlan plan;
  final AppPreferences prefs;
  final bool use24Hour;
  final ValueChanged<bool> onBedtimeChanged;
  final ValueChanged<bool> onWindDownChanged;

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
          onChanged: onBedtimeChanged,
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
          onChanged: onWindDownChanged,
        ),
      ],
    );
  }
}

// ─── Wind-down duration chips ────────────────────────────────────────────────

class _WindDownDurationChips extends StatelessWidget {
  const _WindDownDurationChips({
    required this.selectedMinutes,
    required this.onSelected,
  });

  final int selectedMinutes;
  final ValueChanged<int> onSelected;

  static const List<int> _options = <int>[15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _options.map((m) {
        final selected = selectedMinutes == m;
        return ChoiceChip(
          key: ValueKey('sleep-winddown-$m'),
          label: Text('${m}m'),
          selected: selected,
          showCheckmark: false,
          selectedColor: kRostrikOrange,
          onSelected: (_) => onSelected(m),
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            color: selected ? Colors.black : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

// ─── Sleep-sound auto-stop timer chips ───────────────────────────────────────

class _SleepTimerChips extends StatelessWidget {
  const _SleepTimerChips({
    required this.selectedMinutes,
    required this.onSelected,
  });

  final int selectedMinutes;
  final ValueChanged<int> onSelected;

  /// 0 == "Off" (play until stopped).
  static const List<int> _options = <int>[0, 15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _options.map((m) {
        final selected = selectedMinutes == m;
        return ChoiceChip(
          key: ValueKey('sleep-timer-$m'),
          label: Text(m == 0 ? 'Off' : '${m}m'),
          selected: selected,
          showCheckmark: false,
          selectedColor: kRostrikOrange,
          onSelected: (_) => onSelected(m),
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            color: selected ? Colors.black : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

// ─── Sleep sounds grid ───────────────────────────────────────────────────────

/// The 6-sound grid. Watches [SleepSoundController] so the playing tile
/// highlights and shows its wind-down countdown; tapping toggles play/stop.
/// Tolerant of a missing controller (a bare widget test) — the tiles still
/// render, taps just no-op.
class _SleepSoundsGrid extends StatelessWidget {
  const _SleepSoundsGrid({required this.timerMinutes});

  final int timerMinutes;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SleepSoundController?>();
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.92,
      children: [
        for (final sound in kSleepSounds)
          _SoundCard(
            sound: sound,
            playing: controller?.isPlayingResource(sound.resource) ?? false,
            remaining: controller?.isPlayingResource(sound.resource) ?? false
                ? controller?.remaining
                : null,
            onTap: controller == null
                ? null
                : () => controller.toggle(sound, timerMinutes: timerMinutes),
          ),
      ],
    );
  }
}

/// A premium sound tile. Highlights (orange) while playing and shows a stop
/// glyph + the remaining countdown when an auto-stop timer is set.
class _SoundCard extends StatelessWidget {
  const _SoundCard({
    required this.sound,
    required this.playing,
    required this.remaining,
    required this.onTap,
  });

  final SleepSound sound;
  final bool playing;
  final Duration? remaining;
  final VoidCallback? onTap;

  static String _fmt(Duration d) {
    final total = d.inSeconds;
    final m = total ~/ 60;
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      key: ValueKey('sleep-sound-${sound.resource}'),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: playing
              ? kRostrikOrange.withValues(alpha: 0.16)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: playing
                ? kRostrikOrange
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: playing ? 1.6 : 1,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              playing ? Icons.stop_rounded : sound.icon,
              color: playing ? kRostrikOrange : theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              sound.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: playing ? kRostrikOrange : theme.colorScheme.onSurface,
              ),
            ),
            if (playing && remaining != null) ...[
              const SizedBox(height: 2),
              Text(
                _fmt(remaining!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
