import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// The educational "Battery Survival" dialog.
///
/// WHY THIS EXISTS instead of the stock battery-optimisation toggle:
/// `Permission.ignoreBatteryOptimizations.request()` pops the standard
/// Android system sheet, but aggressive OEM skins (Samsung One UI on the
/// A-series, Xiaomi MIUI, Oppo/Realme ColorOS, Huawei EMUI) bury a SECOND,
/// vendor-specific app-killer that the standard toggle doesn't touch — so a
/// user can grant "unrestricted" and still have the OS reap the process and
/// silence the alarm. There's no public API to flip those vendor switches, so
/// the only reliable fix is to *teach* the user the manual path and drop them
/// at the app's settings page to walk it.
///
/// Returns a `Future<void>` that completes when the dialog is dismissed (by
/// "Go to Settings", "Not now", barrier tap, or back). The lifecycle re-check
/// on [PermissionsScreen] picks up any change when the user returns.
Future<void> showBatterySurvivalDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _BatterySurvivalDialog(),
  );
}

/// The manual recovery path, as plain steps. Phrased generically — the exact
/// wording differs per OEM, so we name the destination ("Unrestricted") and
/// the breadcrumb rather than promising a pixel-perfect match.
const List<String> _batterySteps = <String>[
  'Open this app’s settings (button below).',
  'Tap Battery (or "App battery usage").',
  'Choose Unrestricted (not "Optimised" or "Restricted").',
  'If you see "Allow background activity", switch it on too.',
];

class _BatterySurvivalDialog extends StatelessWidget {
  const _BatterySurvivalDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AlertDialog(
      key: const ValueKey('battery-survival-dialog'),
      icon: Icon(Icons.battery_alert_outlined, color: scheme.primary, size: 32),
      title: const Text('Keep alarms alive'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Some phones (Samsung, Xiaomi, Oppo, Huawei) aggressively '
              'shut down background apps to save battery. If that happens to '
              'Rostrik, an alarm can be silenced before it fires.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mark Rostrik as Unrestricted to stop this:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _batterySteps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Numbered chip keeps the step order scannable at a glance.
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _batterySteps[i],
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not now'),
        ),
        FilledButton.icon(
          key: const ValueKey('battery-go-to-settings'),
          onPressed: () async {
            // Fire-and-forget: open the OS settings page, then close the
            // dialog. The permissions screen re-reads the battery status on
            // AppLifecycleState.resumed, so the card updates on return.
            await openAppSettings();
            if (context.mounted) Navigator.of(context).pop();
          },
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Go to Settings'),
        ),
      ],
    );
  }
}
