import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../legal/legal.dart';

/// Shown to an EXISTING user when the legal documents change — as a notice
/// over the app they already know, not the full first-run consent screen.
///
/// The distinction is the point. Someone who has already accepted has read the
/// substance once; sending them back through the front door reads as "start
/// again" and buries what actually changed. Someone who has never accepted
/// gets [LegalConsentScreen] instead — see [legalGateFor].
///
/// It is still a hard gate, just a lighter-looking one: no barrier dismiss, no
/// back button, no close affordance. The only way out is the accept button, so
/// nobody reaches the app on stale terms.
///
/// Writes the same two keys the consent screen writes, so there is one source
/// of truth for "what has this user accepted, and when".
class LegalUpdateDialog extends StatefulWidget {
  const LegalUpdateDialog({super.key, required this.onAccepted});

  /// Invoked once, after the new version is persisted.
  final VoidCallback onAccepted;

  /// Puts the notice over whatever is on screen. Returns when it is accepted.
  /// Not dismissible by tap-outside or back — see the class doc.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onAccepted,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LegalUpdateDialog(onAccepted: onAccepted),
    );
  }

  @override
  State<LegalUpdateDialog> createState() => _LegalUpdateDialogState();
}

class _LegalUpdateDialogState extends State<LegalUpdateDialog> {
  bool _saving = false;

  Future<void> _accept() async {
    if (_saving) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    // Persist BEFORE closing, and in the same order as the consent screen: the
    // router reads the version key, so a crash between the two writes must
    // leave the user un-accepted rather than accepted-at-an-unknown-time.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kAcceptedLegalVersionKey, kCurrentLegalVersion);
    await prefs.setString(
      kAcceptedLegalAtKey,
      DateTime.now().toIso8601String(),
    );
    if (!mounted) return;
    navigator.pop();
    widget.onAccepted();
  }

  Future<void> _openUrl(String url) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = context.l10n.commonCouldNotOpenLink;
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      messenger?.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return PopScope(
      // The back gesture must not be a way past updated terms.
      canPop: false,
      child: AlertDialog(
        key: const ValueKey('legal-update-dialog'),
        icon: Icon(Icons.gavel_rounded, color: theme.colorScheme.primary),
        title: Text(l10n.legalUpdatedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.legalUpdatedBody,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            _DialogLink(
              key: const ValueKey('legal-update-privacy'),
              label: l10n.legalPrivacyPolicy,
              onTap: () => _openUrl(kPrivacyPolicyUrl),
            ),
            _DialogLink(
              key: const ValueKey('legal-update-terms'),
              label: l10n.legalTermsOfUse,
              onTap: () => _openUrl(kTermsOfUseUrl),
            ),
          ],
        ),
        actions: [
          FilledButton(
            key: const ValueKey('legal-update-accept'),
            onPressed: _saving ? null : _accept,
            child: Text(_saving ? l10n.commonSaving : l10n.legalUpdatedAccept),
          ),
        ],
      ),
    );
  }
}

/// A document link, styled as a link rather than a button so the accept action
/// stays the only thing that looks like the way forward.
class _DialogLink extends StatelessWidget {
  const _DialogLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_new_rounded,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
