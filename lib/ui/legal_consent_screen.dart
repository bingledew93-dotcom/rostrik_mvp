import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../legal/legal.dart';

/// The legal consent gate — the FIRST screen a user (or a returning user after a
/// legal-docs bump) sees, before onboarding or the dashboard.
///
/// It makes the safety-critical caveat explicit — the OS, not the app, has
/// the final say over any alarm, so safety-critical wake-ups deserve a second,
/// independent backup — while framing Rostrik itself with confidence. The
/// caveat is deliberately worded as universal to ALL alarm apps: early copy
/// called Rostrik "a BACKUP alarm", which read as "this app doesn't work" and
/// measurably scared new users off (field feedback 2026-09-14). The strong
/// liability wording lives in the linked Terms of Use, not here. Consent is an
/// UNTICKED checkbox + an "Agree & Continue" button that stays disabled until
/// it's ticked.
///
/// On agreement it records `acceptedLegalVersion` + `acceptedLegalAt` in
/// `shared_preferences` (the source of truth the `main()` router reads), then
/// invokes [onAccepted] to advance. The persistence lives here — not in the
/// router — so the write is atomic with the user's tap.
class LegalConsentScreen extends StatefulWidget {
  const LegalConsentScreen({super.key, required this.onAccepted});

  /// Invoked once, after consent is persisted, to advance past the gate.
  final VoidCallback onAccepted;

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen> {
  bool _checked = false;
  bool _saving = false;

  Future<void> _onAgree() async {
    if (!_checked || _saving) return;
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kAcceptedLegalVersionKey, kCurrentLegalVersion);
    await prefs.setString(
      kAcceptedLegalAtKey,
      DateTime.now().toIso8601String(),
    );
    if (!mounted) return;
    widget.onAccepted();
  }

  Future<void> _openUrl(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonCouldNotOpenLink)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Icon(Icons.alarm_on_rounded, size: 48, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.legalTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              // The scrollable explanation — keeps the checkbox + CTA reachable
              // on short screens without clipping the disclaimer.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.legalBodyOsCaveat,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.legalBodyBackupAdvice,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.legalReviewAndAccept,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _LegalLink(
                        label: l10n.legalPrivacyPolicy,
                        onTap: () => _openUrl(kPrivacyPolicyUrl),
                      ),
                      _LegalLink(
                        label: l10n.legalTermsOfUse,
                        onTap: () => _openUrl(kTermsOfUseUrl),
                      ),
                    ],
                  ),
                ),
              ),
              // The consent itself — unticked by default; the CTA is gated on it.
              CheckboxListTile(
                key: const ValueKey('legal-consent-checkbox'),
                value: _checked,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _checked = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.legalConsentCheckbox,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: FilledButton(
                  key: const ValueKey('legal-consent-agree'),
                  // Disabled until the box is ticked — the gate can't be
                  // skipped past.
                  onPressed: (_checked && !_saving) ? _onAgree : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    _saving ? l10n.commonSaving : l10n.legalAgreeContinue,
                  ),
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

/// A single tappable legal-doc link row (opens externally via url_launcher).
class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.open_in_new, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
