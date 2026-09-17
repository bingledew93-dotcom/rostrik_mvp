/// Legal-consent constants, shared by the gate ([LegalConsentScreen] + the
/// `main()` router) and the Settings "Legal & About" links.
///
/// Bumping [kCurrentLegalVersion] re-gates EVERY existing user: on next launch
/// their stored `acceptedLegalVersion` no longer matches, so they're routed
/// back through the consent screen before they can use the app again. The
/// version is the date the legal docs last materially changed.
library;

/// The legal-docs version currently in force. Stored verbatim on acceptance.
const String kCurrentLegalVersion = '2026-06-15';

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
