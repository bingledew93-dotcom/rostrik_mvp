/// Legal-consent constants, shared by the gate ([LegalConsentScreen] + the
/// `main()` router) and the Settings "Legal & About" links.
///
/// Bumping [kCurrentLegalVersion] re-gates EVERY existing user: on next launch
/// their stored `acceptedLegalVersion` no longer matches, so they're routed
/// back through the consent screen before they can use the app again. The
/// version is the date the legal docs last materially changed.
library;

/// The legal-docs version currently in force. Stored verbatim on acceptance.
///
/// 2026-09-18: documents moved to rostrik.com.au with minor wording changes.
const String kCurrentLegalVersion = '2026-09-18';

/// What the router must show a user, given the legal version they last
/// accepted. The two un-accepted cases are deliberately distinct: someone who
/// has never seen the documents needs the full gate, while someone who
/// accepted an earlier version has already read the substance and only needs
/// telling what changed. Treating both the same way would drag every existing
/// user back through onboarding's front door.
enum LegalGate {
  /// Up to date — the router does nothing.
  accepted,

  /// Never accepted anything: the full consent screen, ahead of everything.
  firstRun,

  /// Accepted an older version: the app opens as normal with an update notice
  /// over it.
  updated,
}

/// Classifies the stored `acceptedLegalVersion` ([kAcceptedLegalVersionKey]).
///
/// A stored version that is merely *different* — including one somehow NEWER
/// than the build in force, which a downgrade would produce — counts as
/// [LegalGate.updated]. Re-asking is harmless; silently treating it as
/// accepted would not be.
LegalGate legalGateFor(String? acceptedVersion) {
  if (acceptedVersion == kCurrentLegalVersion) return LegalGate.accepted;
  if (acceptedVersion == null || acceptedVersion.isEmpty) {
    return LegalGate.firstRun;
  }
  return LegalGate.updated;
}

/// `shared_preferences` key holding the legal version the user last accepted.
const String kAcceptedLegalVersionKey = 'acceptedLegalVersion';

/// `shared_preferences` key holding the ISO-8601 instant of acceptance.
const String kAcceptedLegalAtKey = 'acceptedLegalAt';

/// External legal documents (opened via `url_launcher`).
///
/// Moved off Google Sites onto the real domain 2026-09-18. Both pages are
/// served from rostrik.com.au; `/terms-of-use/` also resolves, but `/terms/` is
/// the canonical spelling and matches `/privacy/`.
///
/// These are ALSO entered separately in Play Console (Store listing → Privacy
/// policy) and App Store Connect — changing them here does not change them
/// there.
const String kPrivacyPolicyUrl = 'https://rostrik.com.au/privacy/';
const String kTermsOfUseUrl = 'https://rostrik.com.au/terms/';
