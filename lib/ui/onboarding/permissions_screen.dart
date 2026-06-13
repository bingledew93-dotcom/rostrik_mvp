import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'battery_survival_dialog.dart';

/// Step 2 of onboarding. Notifications + Exact Alarms are standard toggles
/// wired to `permission_handler`; Battery Unrestricted is NOT a toggle — it
/// opens the educational [showBatterySurvivalDialog] instead, because the
/// stock system toggle doesn't reach the vendor-specific app-killers that
/// actually reap alarms on OEM skins (see that file). All are skippable —
/// "Continue" is always enabled; a hard block here would trap a user who
/// tapped "Don't allow" at the system prompt.
///
/// Statuses auto-refresh on `AppLifecycleState.resumed` so every card —
/// including the battery card's "Unrestricted" badge — reflects the user's
/// choice the moment they return from the OS settings page.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  PermissionStatus _notifications = PermissionStatus.denied;
  PermissionStatus _exactAlarms = PermissionStatus.denied;
  PermissionStatus _batteryUnrestricted = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshAll();
  }

  Future<void> _refreshAll() async {
    final n = await Permission.notification.status;
    // The two below are Android-only. On iOS, `status` returns
    // `restricted` (the platform's "n/a" response) — we map that to
    // "granted" visually so the tile doesn't look broken on iOS.
    final e = await Permission.scheduleExactAlarm.status;
    final b = await Permission.ignoreBatteryOptimizations.status;
    if (!mounted) return;
    setState(() {
      _notifications = n;
      _exactAlarms = e;
      _batteryUnrestricted = b;
    });
  }

  Future<void> _request(Permission permission) async {
    final current = await permission.status;
    if (current.isPermanentlyDenied) {
      // Re-requesting after permanent denial is a silent no-op — the OS
      // won't show the prompt again. Send the user to system settings
      // instead so they have a path to recovery.
      await openAppSettings();
      return;
    }
    await permission.request();
    await _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Permissions'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                child: Text(
                  'Rostrik needs a few permissions to fire alarms '
                  'reliably. You can change these later in system '
                  'settings.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _PermissionTile(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                subtitle: 'Required to show the wake-up screen.',
                status: _notifications,
                onTap: () => _request(Permission.notification),
              ),
              const SizedBox(height: 8),
              _PermissionTile(
                icon: Icons.alarm_outlined,
                title: 'Exact Alarms',
                subtitle: 'Lets alarms fire at the exact scheduled time.',
                status: _exactAlarms,
                onTap: () => _request(Permission.scheduleExactAlarm),
                // Android 12+ surface; iOS treats it as restricted.
                hideOniOS: true,
              ),
              const SizedBox(height: 8),
              _BatteryEducationTile(
                status: _batteryUnrestricted,
                // Education flow, not a system toggle — explains the OEM
                // killer problem and deep-links to the app settings page.
                onTap: () => showBatterySurvivalDialog(context),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: FilledButton(
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

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
    this.hideOniOS = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final PermissionStatus status;
  final VoidCallback onTap;
  final bool hideOniOS;

  @override
  Widget build(BuildContext context) {
    if (hideOniOS && Platform.isIOS) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final granted = status.isGranted;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          icon,
          color: granted
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Switch.adaptive(
          value: granted,
          onChanged: granted ? null : (_) => onTap(),
        ),
        onTap: granted ? null : onTap,
      ),
    );
  }
}

/// The Battery Unrestricted card. Deliberately NOT a [_PermissionTile]:
/// there's no toggle, because the value isn't a single yes/no the OS will
/// flip for us — the educational dialog ([showBatterySurvivalDialog]) walks
/// the user to the settings page instead. When the status reads granted we
/// swap the chevron for a green "Unrestricted" badge so the win is obvious
/// on return (the parent re-reads status on resume). Always tappable, even
/// when granted, so the user can revisit the steps.
class _BatteryEducationTile extends StatelessWidget {
  const _BatteryEducationTile({
    required this.status,
    required this.onTap,
  });

  final PermissionStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Android-only surface; iOS has no battery-optimisation concept.
    if (Platform.isIOS) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final granted = status.isGranted;
    // A green that reads as "good to go" against the pitch-black theme,
    // independent of the orange primary (which means "action needed" here).
    const okGreen = Color(0xFF4CAF50);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          Icons.battery_charging_full_outlined,
          color: granted ? okGreen : scheme.onSurfaceVariant,
        ),
        title: Text(
          'Battery Unrestricted',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          granted
              ? 'Alarms are protected from battery optimisation.'
              : 'Some phones kill background apps. Tap to fix.',
        ),
        trailing: granted
            ? _UnrestrictedBadge(color: okGreen)
            : Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}

/// Compact "Unrestricted" pill with a checkmark — the granted-state trailing
/// affordance on the battery card.
class _UnrestrictedBadge extends StatelessWidget {
  const _UnrestrictedBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('battery-unrestricted-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            'Unrestricted',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
