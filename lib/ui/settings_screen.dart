import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../alarms/alarm_scheduler.dart';
import '../data/models/alarm_settings.dart';
import '../data/models/shift_cycle.dart';
import '../data/repositories/alarm_settings_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../data/storage/local_storage.dart';
import '../legal/legal.dart';
import '../logic/cycle_service.dart';
import '../state/app_preferences.dart';
import 'onboarding/onboarding_flow.dart';
import 'onboarding/walkthrough_flow.dart';
import 'pattern_picker_screen.dart';
import 'shift_format.dart';
import 'tips/screen_tip.dart';
import 'work_history_screen.dart';

/// Global alarm-settings screen. Reads via `context.watch<AlarmSettings>()`,
/// writes via `context.read<AlarmSettingsRepository>().write(...)`.
///
/// Deliberately ignorant of the AlarmEngine. The engine subscribes to the
/// settings stream itself and re-reconciles (debounced) on every change —
/// the UI's only job is to land the write.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      // SafeArea(bottom) so the "+ Add Shift Cycle" button can't sit
      // under the Android gesture-pill / 3-button bar.
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: const [
            _LeadTimeSection(),
            Divider(height: 32),
            _SnoozeDurationSection(),
            Divider(height: 32),
            _ShiftCyclesSection(),
            Divider(height: 32),
            _WorkHistorySection(),
            Divider(height: 32),
            _PreferencesSection(),
            Divider(height: 32),
            _HelpSection(),
            Divider(height: 32),
            _FactoryResetSection(),
            Divider(height: 32),
            _LegalAboutSection(),
            _BrandingFooter(),
          ],
        ),
      ),
    );
  }
}

/// "LEGAL & ABOUT" — Privacy Policy + Terms of Use tiles that open the external
/// docs via url_launcher. Sits just above the footer so the legal links are the
/// last thing in Settings, mirroring the consent the user gave at first launch.
class _LegalAboutSection extends StatelessWidget {
  const _LegalAboutSection();

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Text(
            'LEGAL & ABOUT',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ListTile(
          key: const ValueKey('settings-privacy-policy'),
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => _open(context, kPrivacyPolicyUrl),
        ),
        ListTile(
          key: const ValueKey('settings-terms-of-use'),
          leading: const Icon(Icons.description_outlined),
          title: const Text('Terms of Use'),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => _open(context, kTermsOfUseUrl),
        ),
      ],
    );
  }
}

/// "HELP" — a single tile that replays the first-launch walkthrough (paint-a-
/// roster practice + shake-to-dismiss test-run). Pushes the SAME [WalkthroughFlow]
/// the onboarding flow shows; here [WalkthroughFlow.onFinish] just pops back to
/// Settings, so it's a pure, side-effect-free replay the user can revisit
/// anytime.
class _HelpSection extends StatelessWidget {
  const _HelpSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Text(
            'HELP',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ListTile(
          key: const ValueKey('settings-replay-tutorial'),
          leading: const Icon(Icons.school_outlined),
          title: const Text('How it works'),
          subtitle: const Text('Replay the quick tour — paint a roster + '
              'shake-to-dismiss'),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (routeContext) => WalkthroughFlow(
                onFinish: () => Navigator.of(routeContext).pop(),
              ),
            ),
          ),
        ),
        const _ScreenTipsToggle(),
      ],
    );
  }
}

/// "Show screen tips" — the master switch for the one-time per-screen coach
/// cards. Turning it ON REPLAYS every tip (clears the per-screen seen flags via
/// [ScreenTipsPrefs.setEnabled]), so it doubles as "show them to me again".
/// Reactive: bound to the `settings` box so the switch reflects a tip's
/// "Don't show tips" dismissal the moment it happens.
class _ScreenTipsToggle extends StatelessWidget {
  const _ScreenTipsToggle();

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('settings')) return const SizedBox.shrink();
    final box = Hive.box('settings');
    return ValueListenableBuilder<Box>(
      valueListenable: box.listenable(keys: [ScreenTipsPrefs.enabledKey]),
      builder: (context, box, _) => SwitchListTile(
        key: const ValueKey('settings-screen-tips-toggle'),
        secondary: const Icon(Icons.lightbulb_outline),
        title: const Text('Show screen tips'),
        subtitle: const Text('One-time hints on each screen. Turn on to see '
            'them again.'),
        value: ScreenTipsPrefs.isEnabled(box),
        onChanged: (v) => ScreenTipsPrefs.setEnabled(box, v),
      ),
    );
  }
}

/// Subtle brand sign-off at the very bottom of Settings: a dimmed logo + muted
/// wordmark. Deliberately low-contrast — it's a quiet mark, not a CTA, so it
/// reads as "you've reached the end" without competing with the live controls
/// above. Uses the same asset + errorBuilder fallback as the WelcomeScreen
/// hero, so it degrades to the alarm glyph if the logo is ever missing.
class _BrandingFooter extends StatelessWidget {
  const _BrandingFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      key: const ValueKey('settings-branding-footer'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        children: [
          Opacity(
            opacity: 0.30,
            child: Image.asset(
              'assets/images/rostrik_logo.png',
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.alarm, size: 32, color: muted),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ROSTRIK',
            style: theme.textTheme.labelMedium?.copyWith(
              color: muted.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Alarms built outside the 9–5',
            style: theme.textTheme.labelSmall?.copyWith(
              color: muted.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadTimeSection extends StatefulWidget {
  const _LeadTimeSection();

  @override
  State<_LeadTimeSection> createState() => _LeadTimeSectionState();
}

class _LeadTimeSectionState extends State<_LeadTimeSection> {
  // Snaps every 5 min from 0 to 120 → 24 intervals, 25 distinct positions.
  static const _maxMinutes = 120.0;
  static const _divisions = 24;

  /// Local mirror of the slider position during a drag. Null when idle —
  /// in that case we render directly from the watched settings, so an
  /// external write (e.g. another device, a future "reset" button) shows up
  /// immediately. Set on first onChanged of a gesture, cleared on
  /// onChangeEnd after the repo write commits.
  double? _dragMinutes;

  void _commit(double minutes) {
    final settings = AlarmSettings(leadTime: Duration(minutes: minutes.toInt()));
    context.read<AlarmSettingsRepository>().write(settings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<AlarmSettings>();
    final canonical = settings.leadTime.inMinutes.toDouble();
    final shown = (_dragMinutes ?? canonical).clamp(0.0, _maxMinutes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lead time', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Alarm fires this long before each shift starts.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _formatLeadTime(shown.toInt()),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: shown,
            min: 0,
            max: _maxMinutes,
            divisions: _divisions,
            label: _formatLeadTime(shown.toInt()),
            onChanged: (v) => setState(() => _dragMinutes = v),
            onChangeEnd: (v) {
              _commit(v);
              setState(() => _dragMinutes = null);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 min', style: theme.textTheme.bodySmall),
              Text('${_maxMinutes.toInt()} min',
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// Snooze duration picker. Backed by the generic `'settings'` Hive box
/// (not the typed AlarmSettings store — that's for engine-level config
/// like lead time; snooze duration is a notification-UX preference and
/// is also consumed by the bg isolate, which only opens this untyped
/// box). Reactive via `box.listenable()` so an external write (e.g. a
/// future reset action, a hot-restart with a stale Hive cache, etc.)
/// reflects in the dropdown without manual setState plumbing.
class _SnoozeDurationSection extends StatelessWidget {
  const _SnoozeDurationSection();

  /// Stays in sync with the read-default in the dispatcher, the bg
  /// isolate, and the WakeUpScreen — change here, change there.
  static const int _defaultMinutes = 1;

  /// Fixed option set. Kept small to keep the dropdown tappable at 4 AM
  /// and to avoid the "snoozing forever" failure mode an open input
  /// would invite. 1 minute is included primarily for end-to-end testing
  /// of the snooze → reschedule loop without a long wait.
  static const List<int> _options = <int>[1, 5, 10, 15, 30];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Snooze duration', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'How far forward the Snooze button pushes a firing alarm.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<Box>(
            valueListenable: Hive.box('settings').listenable(
              keys: const <String>['snooze_duration'],
            ),
            builder: (context, box, _) {
              final stored =
                  box.get('snooze_duration', defaultValue: _defaultMinutes)
                      as int;
              // Defensive clamp — if a future migration changes the
              // option set, an out-of-range stored value would otherwise
              // throw inside DropdownButton's assert.
              final current = _options.contains(stored) ? stored : _defaultMinutes;
              return DropdownButtonFormField<int>(
                initialValue: current,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Minutes',
                ),
                items: _options
                    .map(
                      (m) => DropdownMenuItem<int>(
                        value: m,
                        child: Text('$m minutes'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  // put + flush: on an aggressive-reap device a bare put can be
                  // dropped before Hive's lazy flush, reverting the snooze
                  // interval to the 1-min default. The bg isolate reads this
                  // same key, so a lost write also mis-times a killed-app
                  // snooze. Fire-and-forget — the listenable updates the
                  // dropdown synchronously.
                  final box = Hive.box('settings');
                  box.put('snooze_duration', v).then((_) => box.flush());
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Inline "SHIFT CYCLES" management: the saved-rosters list + a primary
/// entry point to the pattern-picker generator, both surfaced inside
/// Settings rather than as a separate screen behind an AppBar folder.
///
/// Reactive via the `StreamProvider<List<ShiftCycle>>` installed by
/// `AppProviders` — the list updates as soon as Generate writes a new
/// cycle or `CycleService.deleteCycle` removes one, no setState
/// plumbing needed at this layer.
class _ShiftCyclesSection extends StatelessWidget {
  const _ShiftCyclesSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cycles = context.watch<List<ShiftCycle>>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // M3 conventional "section header" — small-caps tracking, used
          // by Material settings layouts to delimit groupings. Reads as
          // a peer to the screen's other section titles.
          Text(
            'SHIFT CYCLES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rosters you have generated from a pattern or template.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (cycles.isEmpty)
            _EmptyCyclesPanel()
          else
            for (final c in cycles) _CycleCard(cycle: c),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PatternPickerScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Shift Cycle'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact "no cycles yet" panel inside the SHIFT CYCLES section.
/// Inline (not a full-screen empty state) because Settings hosts other
/// content above and below — the user always has a "+ Add Shift Cycle"
/// button right beneath this panel as the obvious next step.
class _EmptyCyclesPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "You haven't generated any rosters yet.",
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One row in the inline cycles list. Shows the cycle's label, an
/// active/upcoming/past status chip derived from `[startDate, endDate]`
/// against today's date, the human-readable date range, and a delete
/// IconButton wired to [CycleService.deleteCycle] (with a confirm
/// dialog — cycle deletion is destructive and cascades through every
/// child shift + pending OS notification).
class _CycleCard extends StatelessWidget {
  const _CycleCard({required this.cycle});

  final ShiftCycle cycle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _CycleStatus.forDate(cycle, DateTime.now());
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          cycle.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatShiftDate(cycle.startDate)} – '
                    '${formatShiftDate(cycle.endDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () => _confirmAndDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    // Capture before the await — BuildContext mustn't be read after a
    // suspension.
    final service = context.read<CycleService>();
    final shifts = context.read<ShiftRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final count = (await shifts.getByCycleId(cycle.id)).length;
    if (!context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete roster?'),
        content: Text(
          'Delete "${cycle.label}"? This will cancel any pending alarms '
          'and remove $count shift${count == 1 ? '' : 's'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogCtx).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(dialogCtx).colorScheme.errorContainer,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await service.deleteCycle(cycle.id);
    messenger.showSnackBar(
      SnackBar(content: Text('Deleted "${cycle.label}"')),
    );
  }
}

enum _CycleStatus {
  active,
  upcoming,
  past;

  /// Today within [startDate, endDate] (inclusive) → active. Both dates
  /// are midnight-normalised by the model, so the compare is date-only.
  static _CycleStatus forDate(ShiftCycle c, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (today.isBefore(c.startDate)) return _CycleStatus.upcoming;
    if (today.isAfter(c.endDate)) return _CycleStatus.past;
    return _CycleStatus.active;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _CycleStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, bg, fg) = switch (status) {
      _CycleStatus.active => (
          'Active',
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
        ),
      _CycleStatus.upcoming => (
          'Upcoming',
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer,
        ),
      _CycleStatus.past => (
          'Past',
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Delegates to the shared formatter in shift_format.dart so the slider and the
// onboarding lead-time dropdown stay phrased identically.
String _formatLeadTime(int totalMinutes) => formatLeadTime(totalMinutes);

/// "WORK HISTORY" entry point — opens the [WorkHistoryScreen] where completed
/// ad-hoc shifts are listed and exported as CSV for payslip verification.
/// A plain navigation tile (no inline state) — all the data work lives on the
/// destination screen.
class _WorkHistorySection extends StatelessWidget {
  const _WorkHistorySection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORK HISTORY',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Review and export your completed custom shifts to verify payslips.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              key: const ValueKey('settings-open-work-history'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkHistoryScreen()),
              ),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('View & Export Work History'),
            ),
          ),
        ],
      ),
    );
  }
}

/// User display preferences — clock format and calendar week-start. Both are
/// pure presentation toggles backed by [AppPreferences] (the generic 'settings'
/// box); flipping either re-renders the affected surfaces live via the
/// ChangeNotifierProvider. The active switch track is the theme's safety-orange
/// (switchTheme maps a selected switch → primary), matching the alarm/permission
/// toggles — no inline colour needed.
class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = context.watch<AppPreferences>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREFERENCES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How your schedule is displayed across the app.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const ValueKey('settings-use-24h-toggle'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Use 24-Hour Time'),
            subtitle: Text(
              prefs.use24HourTime
                  ? 'Times show as 14:30'
                  : 'Times show as 02:30 PM',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            value: prefs.use24HourTime,
            onChanged: (v) =>
                context.read<AppPreferences>().setUse24HourTime(v),
          ),
          SwitchListTile(
            key: const ValueKey('settings-week-start-toggle'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Start Calendar on Monday'),
            subtitle: Text(
              prefs.startWeekOnMonday
                  ? 'Weeks begin on Monday'
                  : 'Weeks begin on Sunday',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            value: prefs.startWeekOnMonday,
            onChanged: (v) =>
                context.read<AppPreferences>().setStartWeekOnMonday(v),
          ),
          const SizedBox(height: 8),
          Text(
            'Timeline opens on',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            key: const ValueKey('settings-timeline-default-view'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('List'),
                icon: Icon(Icons.view_agenda_outlined),
              ),
              ButtonSegment(
                value: true,
                label: Text('Month'),
                icon: Icon(Icons.calendar_month),
              ),
            ],
            selected: {prefs.timelineDefaultsToMonth},
            onSelectionChanged: (s) =>
                context.read<AppPreferences>().setTimelineDefaultsToMonth(s.first),
          ),
        ],
      ),
    );
  }
}

/// Destructive "Reset App Data" action — wipes all local data and kicks the
/// user back through onboarding. Styled with the theme's error colour so it
/// reads as dangerous against the otherwise-orange surface. Primarily a
/// testing affordance (re-run the first-launch flow without reinstalling), but
/// also a legitimate user "start over" path.
class _FactoryResetSection extends StatelessWidget {
  const _FactoryResetSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DANGER ZONE',
            style: theme.textTheme.labelMedium?.copyWith(
              color: error,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Deletes your roster, alarms, and settings, then restarts '
            'onboarding from scratch.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('settings-reset-app-data'),
              onPressed: () => _confirmAndReset(context),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Reset App Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: error,
                side: BorderSide(color: error.withValues(alpha: 0.6)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndReset(BuildContext context) async {
    // Capture context-bound handles BEFORE any await — BuildContext must not
    // be read across an async gap, and the Navigator must outlive this widget
    // (we replace the whole stack at the end).
    final scheduler = context.read<AlarmScheduler>();
    final storage = context.read<LocalStorage>();
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final scheme = Theme.of(dialogCtx).colorScheme;
        return AlertDialog(
          title: const Text('Reset app?'),
          content: const Text(
            'Are you sure? This will delete your roster, alarms, and '
            'settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('settings-reset-confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    // 1. Cancel every pending OS alarm so none fires from the wiped roster.
    await scheduler.cancelAll();
    // 2. Wipe the typed data boxes (shifts, cycles, alarms, settings, ids).
    await storage.reset();
    // 3. Reset the app-prefs box: drops the scheduled-fire cache + snooze
    //    pref, and forces re-onboarding on the next first-launch gate read.
    final prefs = Hive.box('settings');
    await prefs.clear();
    await prefs.put(onboardingCompleteKey, false);
    // 4. Clear the whole nav stack back to a fresh onboarding flow.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingFlow()),
      (_) => false,
    );
  }
}
