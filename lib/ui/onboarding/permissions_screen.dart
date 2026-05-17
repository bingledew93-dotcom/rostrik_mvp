import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Step 2 of onboarding. Three permission toggles wired to
/// `permission_handler`. All three are skippable — "Continue" is always
/// enabled. Alarms degrade gracefully without battery-unrestricted, and
/// a hard block here would create an unrecoverable state if the user
/// has tapped "Don't allow" at the system prompt.
///
/// Statuses auto-refresh on `AppLifecycleState.resumed` so the toggles
/// reflect the user's choice as soon as they return from the OS
/// settings page.
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
              _PermissionTile(
                icon: Icons.battery_charging_full_outlined,
                title: 'Battery Unrestricted',
                subtitle:
                    'Stops the OS killing alarms while the phone is idle.',
                status: _batteryUnrestricted,
                onTap: () =>
                    _request(Permission.ignoreBatteryOptimizations),
                hideOniOS: true,
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
