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
const String kPrivacyPolicyUrl =
    'https://sites.google.com/view/rostrik-privacy-policy/home';
const String kTermsOfUseUrl =
    'https://sites.google.com/view/rostrik-terms-of-use/home';
