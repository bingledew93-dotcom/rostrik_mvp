import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
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

  @override
  void initState() {
    super.initState();
    // Ask the store for the price again if launch-time billing came up empty.
    // Fire-and-forget: the service notifies on success and `main`'s
    // `context.watch` rebuilds this screen with the price filled in.
    unawaited(widget.service.refreshPriceIfMissing());
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final launched = await widget.service.buy();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!launched) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.purchaseUnavailable)),
      );
    }
    // On success the purchase completes asynchronously; the service notifies and
    // the root gate swaps this screen out for the app.
  }

  Future<void> _restore() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.purchaseCheckingPrevious;
    await widget.service.restore();
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final price = widget.service.price;
    final unlockLabel = price == null
        ? l10n.purchaseUnlock
        : l10n.purchaseUnlockWithPrice(price);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          // Scrollable only when it has to be. The Spacers below centre the
          // content on a normal screen and are the design; they also cannot
          // shrink, so a short viewport (a phone in landscape has ~360dp of
          // height) overflowed by 580px.
          //
          // minHeight = the viewport, plus IntrinsicHeight to give the Column a
          // bounded height inside the scroll view — without that the Spacers
          // have no space to divide and throw. Net effect: on a tall screen the
          // Column is exactly viewport-height and lays out EXACTLY as before,
          // Spacer ratios intact; on a short one it grows to its natural height
          // and scrolls. Deliberately conservative — this is the paywall, and a
          // visual regression here costs money. The 15-language smoke test at
          // 360x760 is what proves the normal case is untouched.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                        l10n.purchaseTrialEnded,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.purchaseBody,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.purchaseAlarmsWontRing,
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(unlockLabel),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        key: const ValueKey('purchase-restore'),
                        onPressed: _busy ? null : _restore,
                        child: Text(
                          l10n.purchaseRestore,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.purchaseOneTime,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
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
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
