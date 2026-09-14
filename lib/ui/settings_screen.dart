import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../alarms/alarm_capabilities.dart';
import '../alarms/alarm_scheduler.dart';
import '../alarms/alarmkit_bringup.dart';
import '../calendar_sync/device_calendar_service.dart';
import '../data/models/alarm_settings.dart';
import '../data/models/shift_cycle.dart';
import '../data/repositories/alarm_settings_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../data/storage/local_storage.dart';
import '../legal/legal.dart';
import '../logic/cycle_service.dart';
import '../logic/cycle_to_painted.dart' show isCycleEditable;
import '../purchase/entitlement_service.dart';
import '../purchase/entitlement_store.dart';
import '../state/app_preferences.dart';
import '../l10n/l10n.dart';
import 'custom_builder_screen.dart';
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
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      // SafeArea(bottom) so the "+ Add Shift Cycle" button can't sit
      // under the Android gesture-pill / 3-button bar.
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: const [
            // Trial / full-access status first, so a user always knows where
            // they stand (renders its own divider; nothing when no entitlement
            // service is in the tree, e.g. a bare widget test).
            _FullAccessSection(),
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
            _CalendarSyncSection(),
            Divider(height: 32),
            _HelpSection(),
            Divider(height: 32),
            // Debug-only trial/purchase shortcuts — renders nothing in release.
            _DebugTrialSection(),
            // Phase B bring-up — renders nothing in release or off iOS.
            _DebugAlarmKitSection(),
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
    final couldNotOpen = context.l10n.commonCouldNotOpenLink;
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(couldNotOpen)),
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
            context.l10n.settingsLegalAbout,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: labelTracking(context, 1.2),
            ),
          ),
        ),
        ListTile(
          key: const ValueKey('settings-privacy-policy'),
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(context.l10n.legalPrivacyPolicy),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => _open(context, kPrivacyPolicyUrl),
        ),
        ListTile(
          key: const ValueKey('settings-terms-of-use'),
          leading: const Icon(Icons.description_outlined),
          title: Text(context.l10n.legalTermsOfUse),
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
            context.l10n.settingsHelp,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: labelTracking(context, 1.2),
            ),
          ),
        ),
        ListTile(
          key: const ValueKey('settings-replay-tutorial'),
          leading: const Icon(Icons.school_outlined),
          title: Text(context.l10n.settingsHowItWorks),
          // The tour drops its shake lesson where the gesture does nothing, so
          // the subtitle must not advertise it either.
          subtitle: Text(
            AlarmCapabilities.current.shakeToDismiss
                ? context.l10n.settingsReplayTourShake
                : context.l10n.settingsReplayTour,
          ),
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
        title: Text(context.l10n.settingsScreenTips),
        subtitle: Text(context.l10n.settingsScreenTipsSub),
        value: ScreenTipsPrefs.isEnabled(box),
        onChanged: (v) => ScreenTipsPrefs.setEnabled(box, v),
      ),
    );
  }
}

/// Release-visible "FULL ACCESS" status — the user's live trial / purchase
/// standing, plus a way to unlock or restore any time. This is what makes the
/// free trial discoverable in-app (previously it was invisible until the day-14
/// paywall). Renders nothing when no [EntitlementService] is in the tree (a bare
/// widget test), and carries its own trailing divider so it leaves no stray rule
/// when hidden.
class _FullAccessSection extends StatelessWidget {
  const _FullAccessSection();

  Future<void> _buy(BuildContext context, EntitlementService service) async {
    final messenger = ScaffoldMessenger.of(context);
    final unavailable = context.l10n.purchaseUnavailable;
    final launched = await service.buy();
    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text(unavailable)));
    }
    // On success the purchase completes asynchronously; the entitlement stream
    // notifies and this section rebuilds to the unlocked state.
  }

  Future<void> _restore(BuildContext context, EntitlementService service) async {
    final messenger = ScaffoldMessenger.of(context);
    final checking = context.l10n.purchaseCheckingPrevious;
    await service.restore();
    messenger.showSnackBar(SnackBar(content: Text(checking)));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<EntitlementService?>();
    if (service == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final e = service.entitlement;
    final price = service.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Text(
            context.l10n.settingsFullAccess,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: labelTracking(context, 1.2),
            ),
          ),
        ),
        if (e.purchased)
          // Bought — a calm "thank you" confirmation, no CTA.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.verified_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.settingsFullAccessUnlocked,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.settingsThanks,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          // In trial (or, defensively, lapsed): show the standing + an early
          // unlock path so nobody is surprised by the paywall.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.card_giftcard_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.withinTrial
                            ? context.l10n
                                .settingsTrialDaysLeft(e.trialDaysLeft)
                            : context.l10n.settingsTrialEnded,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.settingsUnlockPitch,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('settings-unlock-full-access'),
                    onPressed: () => _buy(context, service),
                    child: Text(
                      price == null
                          ? context.l10n.purchaseUnlock
                          : context.l10n.purchaseUnlockWithPrice(price),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  key: const ValueKey('settings-restore-purchase'),
                  onPressed: () => _restore(context, service),
                  child: Text(context.l10n.settingsRestore),
                ),
              ],
            ),
          ),
        ],
        const Divider(height: 32),
      ],
    );
  }
}

/// DEBUG-ONLY trial/purchase shortcuts so the 14-day paywall can be exercised
/// on-device without waiting. Renders nothing in a release build (`kDebugMode`)
/// AND when no [EntitlementService] is in the tree (a bare widget test), so it
/// can never ship or break tests.
class _DebugTrialSection extends StatelessWidget {
  const _DebugTrialSection();

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final service = context.watch<EntitlementService?>();
    if (service == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final e = service.entitlement;
    final state = e.locked
        ? 'LOCKED (trial ended, not purchased)'
        : e.purchased
            ? 'Purchased — unlocked'
            : 'Trial — ${e.trialDaysLeft} day${e.trialDaysLeft == 1 ? '' : 's'} left';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Text(
            'DEBUG · TRIAL',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
              letterSpacing: labelTracking(context, 1.2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            'State: $state',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                key: const ValueKey('debug-expire-trial'),
                onPressed: () async {
                  await service.debugExpireTrial();
                  // Pop back to the (now-locked) root so the wall appears.
                  if (context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
                child: const Text('Expire trial now'),
              ),
              OutlinedButton(
                key: const ValueKey('debug-reset-trial'),
                onPressed: () => service.debugResetTrial(),
                child: const Text('Reset trial (14 days)'),
              ),
              OutlinedButton(
                key: const ValueKey('debug-grant-purchase'),
                onPressed: () => service.debugGrantPurchase(),
                child: const Text('Grant purchase'),
              ),
            ],
          ),
        ),
        const Divider(height: 32),
      ],
    );
  }
}

/// Phase B bring-up: arms one real AlarmKit alarm so it can be watched firing.
///
/// Renders nothing in a release build AND nothing off iOS, so it can neither
/// ship nor appear in a widget test. Gated on `kReleaseMode` rather than
/// `kDebugMode` — unlike [_DebugTrialSection] — because a debug build cannot
/// launch standalone on the device at all ("Cannot create a FlutterEngine
/// instance in debug mode"), so device testing happens on profile builds. A
/// `kDebugMode` gate would hide this in exactly the place it is needed.
///
/// The question it exists to answer: an AlarmKit alert is a Live Activity, and
/// there is no widget extension yet to render one. Whether the alert still
/// presents, and whether the tone rings past the ~30s that caps the notification
/// path, is only observable by letting one fire.
class _DebugAlarmKitSection extends StatefulWidget {
  const _DebugAlarmKitSection();

  @override
  State<_DebugAlarmKitSection> createState() => _DebugAlarmKitSectionState();
}

class _DebugAlarmKitSectionState extends State<_DebugAlarmKitSection> {
  static const _leadSeconds = 60;

  Map<String, dynamic> _status = const {};
  String? _outcome;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final status = await readAlarmKitStatus();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _fire() async {
    final armed = await fireAlarmKitTestAlarm(seconds: _leadSeconds);
    if (!mounted) return;
    setState(() {
      _outcome = armed
          ? 'Armed for ${TimeOfDay.fromDateTime(DateTime.now().add(const Duration(seconds: _leadSeconds))).format(context)}'
              ' — lock the phone and wait.'
          : 'Refused. Check the device console for the AlarmKit error.';
    });
  }

  /// Moves REAL alarms between backends. The scheduler comes from the tree
  /// because the flip has to cancel on the outgoing backend first — see
  /// [setAlarmKitBackendEnabled].
  Future<void> _setBackend(bool enabled) async {
    setState(() => _busy = true);
    await setAlarmKitBackendEnabled(
      enabled,
      scheduler: context.read<AlarmScheduler>(),
    );
    await _refreshStatus();
    if (mounted) {
      setState(() {
        _busy = false;
        _outcome = enabled
            ? 'Real alarms now run on AlarmKit. Re-armed from scratch.'
            : 'Real alarms back on notifications.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode || !Platform.isIOS) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final available = _status['available'] == true;
    final enabled = _status['enabled'] == true;
    final authorized = _status['authorized'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Text(
            'DEBUG · ALARMKIT',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
              letterSpacing: labelTracking(context, 1.2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            _outcome ??
                (available
                    // `active` is what the backend factory really picks;
                    // `enabled` is only the preference. They diverge when
                    // AlarmKit is preferred but unauthorised, and reporting the
                    // preference would claim alarms run on a backend they do
                    // not.
                    ? 'Real alarms run on '
                        '${_status['active'] == true ? 'AlarmKit' : 'notifications'}'
                        '${enabled && !authorized ? ' — AlarmKit preferred but NOT authorised' : ''}.'
                    : 'AlarmKit needs iOS 26. This device uses notifications.'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (available)
          SwitchListTile(
            key: const ValueKey('debug-alarmkit-backend'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            title: const Text('Use AlarmKit for real alarms'),
            subtitle: const Text(
              'Cancels everything on the current backend, then re-arms on the '
              'other one.',
            ),
            value: enabled,
            onChanged: _busy ? null : _setBackend,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: OutlinedButton(
            key: const ValueKey('debug-alarmkit-fire'),
            onPressed: _busy ? null : _fire,
            child: const Text('Fire test alarm (bypasses your rules)'),
          ),
        ),
        const Divider(height: 32),
      ],
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
              letterSpacing: labelTracking(context, 3),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.settingsBrandTagline,
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
          Text(context.l10n.settingsLeadTime,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            context.l10n.settingsLeadTimeSub,
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
              Text(context.l10n.durationMin(0),
                  style: theme.textTheme.bodySmall),
              Text(context.l10n.durationMin(_maxMinutes.toInt()),
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
          Text(context.l10n.settingsSnoozeDuration,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            context.l10n.settingsSnoozeDurationSub,
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
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: context.l10n.settingsMinutesLabel,
                ),
                items: _options
                    .map(
                      (m) => DropdownMenuItem<int>(
                        value: m,
                        child: Text(context.l10n.commonMinutes(m)),
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
            context.l10n.settingsShiftCycles,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: labelTracking(context, 1.2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.settingsShiftCyclesSub,
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
              label: Text(context.l10n.settingsAddShiftCycle),
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
        context.l10n.settingsNoRosters,
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
                    context.l10n.commonDateRange(
                      formatShiftDate(cycle.startDate),
                      formatShiftDate(cycle.endDate),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit is offered only for cycles the builder can reconstruct
                // (anchored + within its cycle-length range). Template / legacy
                // rosters keep the delete-and-rebuild path.
                if (isCycleEditable(cycle))
                  IconButton(
                    key: ValueKey('cycle-edit-${cycle.id}'),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: context.l10n.commonEdit,
                    onPressed: () => _openEdit(context),
                  ),
                IconButton(
                  key: ValueKey('cycle-delete-${cycle.id}'),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: context.l10n.commonDelete,
                  onPressed: () => _confirmAndDelete(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the builder in EDIT mode, pre-filled from this roster. Saving there
  /// replaces the cycle; the list updates reactively via the cycles stream.
  Future<void> _openEdit(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CustomBuilderScreen(editCycle: cycle)),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    // Capture before the await — BuildContext mustn't be read after a
    // suspension.
    final service = context.read<CycleService>();
    final shifts = context.read<ShiftRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final count = (await shifts.getByCycleId(cycle.id)).length;
    if (!context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.settingsDeleteRosterTitle),
        content: Text(
          l10n.settingsDeleteRosterBody(cycle.label, count),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogCtx).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(dialogCtx).colorScheme.errorContainer,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await service.deleteCycle(cycle.id);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.settingsDeletedRoster(cycle.label))),
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
          context.l10n.commonActive,
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
        ),
      _CycleStatus.upcoming => (
          context.l10n.commonUpcoming,
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer,
        ),
      _CycleStatus.past => (
          context.l10n.commonPast,
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
            context.l10n.settingsWorkHistory,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: labelTracking(context, 1.2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.settingsWorkHistorySub,
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
              label: Text(context.l10n.settingsViewWorkHistory),
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
            context.l10n.settingsPreferences,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: labelTracking(context, 1.2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.settingsPreferencesSub,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.settingsAppearance,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            key: const ValueKey('settings-theme-mode'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(context.l10n.settingsThemeSystem),
                icon: const Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(context.l10n.settingsThemeLight),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(context.l10n.settingsThemeDark),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {prefs.themeMode},
            onSelectionChanged: (s) =>
                context.read<AppPreferences>().setThemeMode(s.first),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.settingsThemeSub,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            key: const ValueKey('settings-use-24h-toggle'),
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.settings24h),
            subtitle: Text(
              prefs.use24HourTime
                  ? context.l10n.settings24hOn
                  : context.l10n.settings24hOff,
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
            title: Text(context.l10n.settingsWeekStartTitle),
            subtitle: Text(
              prefs.startWeekOnMonday
                  ? context.l10n.settingsWeekStartMon
                  : context.l10n.settingsWeekStartSun,
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
            context.l10n.settingsTimelineOpensOn,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            key: const ValueKey('settings-timeline-default-view'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text(context.l10n.commonList),
                icon: const Icon(Icons.view_agenda_outlined),
              ),
              ButtonSegment(
                value: true,
                label: Text(context.l10n.commonMonth),
                icon: const Icon(Icons.calendar_month),
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

/// "CALENDAR" — the optional Device Calendar Sync toggle (feature
/// `feature-calendar-sync`). Turning it ON is the ONLY thing that requests
/// calendar permission; on grant it mirrors the roster to a dedicated "Rostrik
/// Roster" calendar and keeps it in sync as the roster changes. Turning it OFF
/// stops syncing and clears that calendar's future events.
///
/// Watches [DeviceCalendarService] (a ChangeNotifier) so the switch reflects the
/// live enabled/busy state. Null-guarded: pumped without the provider (a bare
/// widget test) it renders nothing rather than throwing.
class _CalendarSyncSection extends StatelessWidget {
  const _CalendarSyncSection();

  Future<void> _toggle(
    BuildContext context,
    DeviceCalendarService service,
    bool value,
  ) async {
    // Capture the messenger + strings before the await — BuildContext must
    // not be used across the async gap.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    if (!value) {
      await service.disableSync();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsCalSyncOff)),
      );
      return;
    }

    final result = await service.enableSync();
    switch (result) {
      case CalendarSyncEnableResult.enabled:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsCalSyncMirroring)),
        );
      case CalendarSyncEnableResult.denied:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsCalPermNeeded)),
        );
      case CalendarSyncEnableResult.permanentlyDenied:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.settingsCalBlocked),
            action: SnackBarAction(
              label: l10n.settingsCalOpenSettings,
              onPressed: service.openSystemSettings,
            ),
          ),
        );
      case CalendarSyncEnableResult.unsupported:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsCalUnsupported)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DeviceCalendarService?>();
    if (service == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.settingsCalendar,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: labelTracking(context, 1.2),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            key: const ValueKey('settings-calendar-sync-toggle'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.event_available_outlined),
            title: Text(context.l10n.settingsCalendarSync),
            subtitle: Text(
              context.l10n.settingsCalendarSyncSub,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            value: service.enabled,
            // Disabled mid-request so taps can't overlap; the trailing spinner
            // shows the round-trip is in flight.
            onChanged:
                service.busy ? null : (v) => _toggle(context, service, v),
          ),
          if (service.busy)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(minHeight: 2),
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
            context.l10n.settingsDangerZone,
            style: theme.textTheme.labelMedium?.copyWith(
              color: error,
              fontWeight: FontWeight.w700,
              letterSpacing: labelTracking(context, 1.2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.settingsDangerZoneSub,
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
              label: Text(context.l10n.settingsResetAppData),
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
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final scheme = Theme.of(dialogCtx).colorScheme;
        return AlertDialog(
          title: Text(l10n.settingsResetTitle),
          content: Text(l10n.settingsResetBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              key: const ValueKey('settings-reset-confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(l10n.settingsResetConfirm),
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
    //    Entitlement standing (trial clock, purchase, derived gates) is
    //    preserved — this button deletes the user's DATA, never their 14-day
    //    trial position or their paid unlock. A plain clear() here was an
    //    in-app unlimited-trial reset.
    final prefs = Hive.box('settings');
    await EntitlementStore.clearPreservingStanding(prefs);
    await prefs.put(onboardingCompleteKey, false);
    // 4. Clear the whole nav stack back to a fresh onboarding flow.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingFlow()),
      (_) => false,
    );
  }
}
