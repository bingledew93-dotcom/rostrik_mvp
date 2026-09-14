// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'Before you start';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik is built to get you up for every shift. One honest heads-up: on any phone, the operating system — not the app — has the final say, and in rare cases it can delay or silence any alarm app (aggressive battery savers, force-stops, or right after system updates).';

  @override
  String get legalBodyBackupAdvice =>
      'For shifts you absolutely cannot miss, keep a second alarm as a backup — good practice with any alarm, including the one built into your phone.';

  @override
  String get legalReviewAndAccept => 'Please review and accept:';

  @override
  String get legalPrivacyPolicy => 'Privacy Policy';

  @override
  String get legalTermsOfUse => 'Terms of Use';

  @override
  String get legalConsentCheckbox =>
      'I understand the operating system can affect any alarm app, and I accept the Privacy Policy and Terms of Use.';

  @override
  String get legalAgreeContinue => 'Agree & Continue';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonCouldNotOpenLink => 'Could not open the link.';
}
