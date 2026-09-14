import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rostrik'**
  String get appTitle;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get legalTitle;

  /// No description provided for @legalBodyOsCaveat.
  ///
  /// In en, this message translates to:
  /// **'Rostrik is built to get you up for every shift. One honest heads-up: on any phone, the operating system — not the app — has the final say, and in rare cases it can delay or silence any alarm app (aggressive battery savers, force-stops, or right after system updates).'**
  String get legalBodyOsCaveat;

  /// No description provided for @legalBodyBackupAdvice.
  ///
  /// In en, this message translates to:
  /// **'For shifts you absolutely cannot miss, keep a second alarm as a backup — good practice with any alarm, including the one built into your phone.'**
  String get legalBodyBackupAdvice;

  /// No description provided for @legalReviewAndAccept.
  ///
  /// In en, this message translates to:
  /// **'Please review and accept:'**
  String get legalReviewAndAccept;

  /// No description provided for @legalPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyPolicy;

  /// No description provided for @legalTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get legalTermsOfUse;

  /// No description provided for @legalConsentCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I understand the operating system can affect any alarm app, and I accept the Privacy Policy and Terms of Use.'**
  String get legalConsentCheckbox;

  /// No description provided for @legalAgreeContinue.
  ///
  /// In en, this message translates to:
  /// **'Agree & Continue'**
  String get legalAgreeContinue;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get commonSaving;

  /// No description provided for @commonCouldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get commonCouldNotOpenLink;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'The smart alarm clock built for shift workers.'**
  String get welcomeTagline;

  /// No description provided for @welcomeSubTagline.
  ///
  /// In en, this message translates to:
  /// **'Alarms that follow your rotating roster — not just weekdays.'**
  String get welcomeSubTagline;

  /// No description provided for @welcomeTrialTitle.
  ///
  /// In en, this message translates to:
  /// **'{days}-day free trial'**
  String welcomeTrialTitle(int days);

  /// No description provided for @welcomeTrialBody.
  ///
  /// In en, this message translates to:
  /// **'Full access to every feature — no card needed. Just a one-time purchase after, never a subscription.'**
  String get welcomeTrialBody;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomeSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip / Set up later'**
  String get welcomeSkip;

  /// No description provided for @welcomeTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time format'**
  String get welcomeTimeFormat;

  /// No description provided for @welcomeWeekStarts.
  ///
  /// In en, this message translates to:
  /// **'Week starts'**
  String get welcomeWeekStarts;

  /// No description provided for @common12h.
  ///
  /// In en, this message translates to:
  /// **'12h'**
  String get common12h;

  /// No description provided for @common24h.
  ///
  /// In en, this message translates to:
  /// **'24h'**
  String get common24h;

  /// No description provided for @commonSundayShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get commonSundayShort;

  /// No description provided for @commonMondayShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get commonMondayShort;

  /// No description provided for @rosterTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a roster type'**
  String get rosterTypeTitle;

  /// No description provided for @rosterTypeQuestion.
  ///
  /// In en, this message translates to:
  /// **'What does your roster look like?'**
  String get rosterTypeQuestion;

  /// No description provided for @rosterTypeDay.
  ///
  /// In en, this message translates to:
  /// **'Day Shifts'**
  String get rosterTypeDay;

  /// No description provided for @rosterTypeNight.
  ///
  /// In en, this message translates to:
  /// **'Night Shifts'**
  String get rosterTypeNight;

  /// No description provided for @rosterTypeRotating.
  ///
  /// In en, this message translates to:
  /// **'Rotating'**
  String get rosterTypeRotating;

  /// No description provided for @rosterTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get rosterTypeCustom;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get commonComingSoon;

  /// No description provided for @permsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permsTitle;

  /// No description provided for @permsIntro.
  ///
  /// In en, this message translates to:
  /// **'Rostrik needs a few permissions to fire alarms reliably. You can change these later in system settings.'**
  String get permsIntro;

  /// No description provided for @permsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permsNotifications;

  /// No description provided for @permsNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Required to show the wake-up screen.'**
  String get permsNotificationsSub;

  /// No description provided for @permsExactAlarms.
  ///
  /// In en, this message translates to:
  /// **'Exact Alarms'**
  String get permsExactAlarms;

  /// No description provided for @permsExactAlarmsSub.
  ///
  /// In en, this message translates to:
  /// **'Lets alarms fire at the exact scheduled time.'**
  String get permsExactAlarmsSub;

  /// No description provided for @permsBatteryUnrestricted.
  ///
  /// In en, this message translates to:
  /// **'Battery Unrestricted'**
  String get permsBatteryUnrestricted;

  /// No description provided for @permsBatteryGrantedSub.
  ///
  /// In en, this message translates to:
  /// **'Alarms are protected from battery optimisation.'**
  String get permsBatteryGrantedSub;

  /// No description provided for @permsBatteryDeniedSub.
  ///
  /// In en, this message translates to:
  /// **'Some phones kill background apps. Tap to fix.'**
  String get permsBatteryDeniedSub;

  /// No description provided for @permsUnrestrictedBadge.
  ///
  /// In en, this message translates to:
  /// **'Unrestricted'**
  String get permsUnrestrictedBadge;

  /// No description provided for @batteryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep alarms alive'**
  String get batteryDialogTitle;

  /// No description provided for @batteryDialogIntro.
  ///
  /// In en, this message translates to:
  /// **'Some phones (Samsung, Xiaomi, Oppo, Huawei) aggressively shut down background apps to save battery. If that happens to Rostrik, an alarm can be silenced before it fires.'**
  String get batteryDialogIntro;

  /// No description provided for @batteryDialogMarkUnrestricted.
  ///
  /// In en, this message translates to:
  /// **'Mark Rostrik as Unrestricted to stop this:'**
  String get batteryDialogMarkUnrestricted;

  /// No description provided for @batteryStep1.
  ///
  /// In en, this message translates to:
  /// **'Open this app’s settings (button below).'**
  String get batteryStep1;

  /// No description provided for @batteryStep2.
  ///
  /// In en, this message translates to:
  /// **'Tap Battery (or \"App battery usage\").'**
  String get batteryStep2;

  /// No description provided for @batteryStep3.
  ///
  /// In en, this message translates to:
  /// **'Choose Unrestricted (not \"Optimised\" or \"Restricted\").'**
  String get batteryStep3;

  /// No description provided for @batteryStep4.
  ///
  /// In en, this message translates to:
  /// **'If you see \"Allow background activity\", switch it on too.'**
  String get batteryStep4;

  /// No description provided for @batteryStep5.
  ///
  /// In en, this message translates to:
  /// **'Turn OFF \"Pause app activity if unused\" (or \"Remove permissions if app is unused\") so Android can’t revoke alarm permissions while you’re away.'**
  String get batteryStep5;

  /// No description provided for @commonNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get commonNotNow;

  /// No description provided for @batteryGoToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get batteryGoToSettings;

  /// No description provided for @armEngineTitle.
  ///
  /// In en, this message translates to:
  /// **'Arm your alarms'**
  String get armEngineTitle;

  /// No description provided for @armEngineRosterReady.
  ///
  /// In en, this message translates to:
  /// **'Your roster is ready'**
  String get armEngineRosterReady;

  /// No description provided for @armEngineCycleStarts.
  ///
  /// In en, this message translates to:
  /// **'{label} · starts {date}'**
  String armEngineCycleStarts(String label, String date);

  /// No description provided for @armEngineSwitchOn.
  ///
  /// In en, this message translates to:
  /// **'We\'ll switch on {summary} wake-up alarms before every matching shift.'**
  String armEngineSwitchOn(String summary);

  /// No description provided for @armEngineArming.
  ///
  /// In en, this message translates to:
  /// **'Arming…'**
  String get armEngineArming;

  /// No description provided for @armEngineCta.
  ///
  /// In en, this message translates to:
  /// **'Automate My Alarms'**
  String get armEngineCta;

  /// No description provided for @armEngineLeadTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Alarm lead time'**
  String get armEngineLeadTimeLabel;

  /// No description provided for @armEngineLeadTimeHelper.
  ///
  /// In en, this message translates to:
  /// **'How early the alarm rings before a shift starts.'**
  String get armEngineLeadTimeHelper;

  /// No description provided for @shiftTypeDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get shiftTypeDay;

  /// No description provided for @shiftTypeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get shiftTypeAfternoon;

  /// No description provided for @shiftTypeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get shiftTypeNight;

  /// No description provided for @shiftTypeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get shiftTypeOff;

  /// No description provided for @weekdaysNone.
  ///
  /// In en, this message translates to:
  /// **'No days'**
  String get weekdaysNone;

  /// No description provided for @weekdaysEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get weekdaysEveryDay;

  /// No description provided for @weekdaysWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get weekdaysWeekdays;

  /// No description provided for @weekdaysWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get weekdaysWeekends;

  /// No description provided for @durationMin.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String durationMin(int m);

  /// No description provided for @durationH.
  ///
  /// In en, this message translates to:
  /// **'{h} h'**
  String durationH(int h);

  /// No description provided for @durationHMin.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min'**
  String durationHMin(int h, int m);

  /// No description provided for @durationMinShort.
  ///
  /// In en, this message translates to:
  /// **'{m}m'**
  String durationMinShort(int m);

  /// No description provided for @durationHShort.
  ///
  /// In en, this message translates to:
  /// **'{h}h'**
  String durationHShort(int h);

  /// No description provided for @durationHMinShort.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String durationHMinShort(int h, int m);

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @walkthroughIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'A 60-second tour'**
  String get walkthroughIntroTitle;

  /// No description provided for @walkthroughIntroBodyTwo.
  ///
  /// In en, this message translates to:
  /// **'Two things that make Rostrik click. You can skip anytime.'**
  String get walkthroughIntroBodyTwo;

  /// No description provided for @walkthroughIntroBodyOne.
  ///
  /// In en, this message translates to:
  /// **'The thing that makes Rostrik click. You can skip anytime.'**
  String get walkthroughIntroBodyOne;

  /// No description provided for @walkthroughPaintLabel.
  ///
  /// In en, this message translates to:
  /// **'Paint your roster'**
  String get walkthroughPaintLabel;

  /// No description provided for @walkthroughPaintDetail.
  ///
  /// In en, this message translates to:
  /// **'Tap the days you work — that fast.'**
  String get walkthroughPaintDetail;

  /// No description provided for @walkthroughShakeLabel.
  ///
  /// In en, this message translates to:
  /// **'Shake to dismiss'**
  String get walkthroughShakeLabel;

  /// No description provided for @walkthroughShakeDetail.
  ///
  /// In en, this message translates to:
  /// **'A firm shake switches off a critical alarm.'**
  String get walkthroughShakeDetail;

  /// No description provided for @walkthroughTryEach.
  ///
  /// In en, this message translates to:
  /// **'Tap Next to try each one.'**
  String get walkthroughTryEach;

  /// No description provided for @walkthroughTryIt.
  ///
  /// In en, this message translates to:
  /// **'Tap Next to try it.'**
  String get walkthroughTryIt;

  /// No description provided for @walkthroughPaintBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the days you work. In the real builder you can add more blocks (afternoons, nights) the same way.'**
  String get walkthroughPaintBody;

  /// No description provided for @walkthroughPaintPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to paint a Day shift onto it.'**
  String get walkthroughPaintPrompt;

  /// No description provided for @walkthroughPaintFeedback.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Nice! That day is a Day block. Untapped days stay Off — that easy.} other{Nice! Those {count} days are a Day block. Untapped days stay Off — that easy.}}'**
  String walkthroughPaintFeedback(int count);

  /// No description provided for @walkthroughShakeBody.
  ///
  /// In en, this message translates to:
  /// **'Critical-Shift alarms need a firm, steady shake to switch off, so a half-asleep tap can’t. Give it a go — shake your phone.'**
  String get walkthroughShakeBody;

  /// No description provided for @walkthroughShakeSuccess.
  ///
  /// In en, this message translates to:
  /// **'You’ve got it!'**
  String get walkthroughShakeSuccess;

  /// No description provided for @walkthroughShakeSuccessDetail.
  ///
  /// In en, this message translates to:
  /// **'That’s exactly how you’ll silence a critical alarm.'**
  String get walkthroughShakeSuccessDetail;

  /// No description provided for @walkthroughDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You’re all set'**
  String get walkthroughDoneTitle;

  /// No description provided for @walkthroughDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Build a roster anytime from Manage, and revisit this tour from Settings → Help whenever you like.'**
  String get walkthroughDoneBody;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get navTimeline;

  /// No description provided for @navManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get navManage;

  /// No description provided for @navAlarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get navAlarms;

  /// No description provided for @navSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get navSleep;

  /// No description provided for @onbPatternTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your rotation'**
  String get onbPatternTitle;

  /// No description provided for @purchaseTrialEnded.
  ///
  /// In en, this message translates to:
  /// **'Your free trial has ended'**
  String get purchaseTrialEnded;

  /// No description provided for @purchaseBody.
  ///
  /// In en, this message translates to:
  /// **'Unlock Rostrik once to keep your shift alarms firing. Your roster, alarms and settings are all safe — they resume the moment you unlock.'**
  String get purchaseBody;

  /// No description provided for @purchaseAlarmsWontRing.
  ///
  /// In en, this message translates to:
  /// **'Until then, alarms won’t ring.'**
  String get purchaseAlarmsWontRing;

  /// No description provided for @purchaseUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock full access'**
  String get purchaseUnlock;

  /// No description provided for @purchaseUnlockWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Unlock full access · {price}'**
  String purchaseUnlockWithPrice(String price);

  /// No description provided for @purchaseRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get purchaseRestore;

  /// No description provided for @purchaseOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase. No subscription.'**
  String get purchaseOneTime;

  /// No description provided for @purchaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases aren’t available right now. Check your connection and try again.'**
  String get purchaseUnavailable;

  /// No description provided for @purchaseCheckingPrevious.
  ///
  /// In en, this message translates to:
  /// **'Checking for a previous purchase…'**
  String get purchaseCheckingPrevious;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
