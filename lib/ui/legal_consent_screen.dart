import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../legal/legal.dart';

/// The legal consent gate — the FIRST screen a user (or a returning user after a
/// legal-docs bump) sees, before onboarding or the dashboard.
///
/// It makes the safety-critical caveat explicit: Rostrik is a *backup* alarm
/// layered on top of an OS that can delay or suppress it, so the user must not
/// treat it as their only wake-up. Consent is an UNTICKED checkbox + an
/// "Agree & Continue" button that stays disabled until it's ticked.
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
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Icon(Icons.gavel_outlined, size: 48, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'Before you rely on Rostrik',
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
                        'Rostrik is a BACKUP alarm. Your phone’s operating '
                        'system can still delay, silence, or kill alarms — '
                        'especially after updates, in battery-saver, or if the '
                        'app is force-stopped.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Always keep a second, independent alarm for anything '
                        'safety-critical (getting to work, medication, '
                        'childcare). Do not depend on Rostrik alone.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please review and accept:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _LegalLink(
                        label: 'Privacy Policy',
                        onTap: () => _openUrl(kPrivacyPolicyUrl),
                      ),
                      _LegalLink(
                        label: 'Terms of Use',
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
                  'I understand Rostrik is a backup alarm — not a replacement '
                  'for my phone’s primary alarm — and I accept the Privacy '
                  'Policy and Terms of Use.',
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
                  child: Text(_saving ? 'Saving…' : 'Agree & Continue'),
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
