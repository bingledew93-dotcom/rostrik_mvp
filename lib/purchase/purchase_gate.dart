import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'entitlement_service.dart';

/// The full-lock wall shown once the 14-day trial lapses without a purchase
/// (feature #4). While this is up the app is inaccessible AND the alarm engine
/// is disarmed (the sync reads the same lock flag). Buying the one-time unlock
/// — or restoring a previous purchase — clears the lock and the app returns
/// exactly as it was; nothing is deleted.
class PurchaseGate extends StatefulWidget {
  const PurchaseGate({super.key, required this.service});

  final EntitlementService service;

  @override
  State<PurchaseGate> createState() => _PurchaseGateState();
}

class _PurchaseGateState extends State<PurchaseGate> {
  bool _busy = false;

  Future<void> _buy() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final launched = await widget.service.buy();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Purchases aren’t available right now. Check your connection and '
            'try again.',
          ),
        ),
      );
    }
    // On success the purchase completes asynchronously; the service notifies and
    // the root gate swaps this screen out for the app.
  }

  Future<void> _restore() async {
    final messenger = ScaffoldMessenger.of(context);
    await widget.service.restore();
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Checking for a previous purchase…')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = widget.service.price;
    final unlockLabel =
        price == null ? 'Unlock full access' : 'Unlock full access · $price';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Image.asset(
                  'assets/images/rostrik_logo.png',
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.lock_outline,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Your free trial has ended',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Unlock Rostrik once to keep your shift alarms firing. Your '
                'roster, alarms and settings are all safe — they resume the '
                'moment you unlock.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'Until then, alarms won’t ring.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                height: 56,
                child: FilledButton(
                  key: const ValueKey('purchase-unlock'),
                  onPressed: _busy ? null : _buy,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(unlockLabel),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const ValueKey('purchase-restore'),
                onPressed: _busy ? null : _restore,
                child: Text(
                  'Restore purchase',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'One-time purchase. No subscription.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7),
                ),
              ),
              // DEBUG-ONLY escape hatch so a tester isn't stranded on the wall
              // when there's no purchasable product yet. Gone in release builds.
              if (kDebugMode)
                TextButton(
                  key: const ValueKey('debug-gate-reset-trial'),
                  onPressed: () => widget.service.debugResetTrial(),
                  child: Text(
                    'Reset trial (debug)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error.withValues(alpha: 0.8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
