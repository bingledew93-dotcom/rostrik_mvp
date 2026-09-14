import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_tr.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('id'),
    Locale('it'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('tr'),
  ];

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

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLegalAbout.
  ///
  /// In en, this message translates to:
  /// **'LEGAL & ABOUT'**
  String get settingsLegalAbout;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'HELP'**
  String get settingsHelp;

  /// No description provided for @settingsHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get settingsHowItWorks;

  /// No description provided for @settingsReplayTourShake.
  ///
  /// In en, this message translates to:
  /// **'Replay the quick tour — paint a roster + shake-to-dismiss'**
  String get settingsReplayTourShake;

  /// No description provided for @settingsReplayTour.
  ///
  /// In en, this message translates to:
  /// **'Replay the quick tour — paint a roster'**
  String get settingsReplayTour;

  /// No description provided for @settingsScreenTips.
  ///
  /// In en, this message translates to:
  /// **'Show screen tips'**
  String get settingsScreenTips;

  /// No description provided for @settingsScreenTipsSub.
  ///
  /// In en, this message translates to:
  /// **'One-time hints on each screen. Turn on to see them again.'**
  String get settingsScreenTipsSub;

  /// No description provided for @settingsFullAccess.
  ///
  /// In en, this message translates to:
  /// **'FULL ACCESS'**
  String get settingsFullAccess;

  /// No description provided for @settingsFullAccessUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Full access unlocked'**
  String get settingsFullAccessUnlocked;

  /// No description provided for @settingsThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for supporting Rostrik.'**
  String get settingsThanks;

  /// No description provided for @settingsTrialDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Free trial — 1 day left} other{Free trial — {days} days left}}'**
  String settingsTrialDaysLeft(int days);

  /// No description provided for @settingsTrialEnded.
  ///
  /// In en, this message translates to:
  /// **'Free trial ended'**
  String get settingsTrialEnded;

  /// No description provided for @settingsUnlockPitch.
  ///
  /// In en, this message translates to:
  /// **'Unlock once to keep your shift alarms firing when the trial ends — a one-time purchase, never a subscription.'**
  String get settingsUnlockPitch;

  /// No description provided for @settingsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get settingsRestore;

  /// No description provided for @settingsBrandTagline.
  ///
  /// In en, this message translates to:
  /// **'Alarms built outside the 9–5'**
  String get settingsBrandTagline;

  /// No description provided for @settingsLeadTime.
  ///
  /// In en, this message translates to:
  /// **'Lead time'**
  String get settingsLeadTime;

  /// No description provided for @settingsLeadTimeSub.
  ///
  /// In en, this message translates to:
  /// **'Alarm fires this long before each shift starts.'**
  String get settingsLeadTimeSub;

  /// No description provided for @settingsSnoozeDuration.
  ///
  /// In en, this message translates to:
  /// **'Snooze duration'**
  String get settingsSnoozeDuration;

  /// No description provided for @settingsSnoozeDurationSub.
  ///
  /// In en, this message translates to:
  /// **'How far forward the Snooze button pushes a firing alarm.'**
  String get settingsSnoozeDurationSub;

  /// No description provided for @settingsMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get settingsMinutesLabel;

  /// No description provided for @commonMinutes.
  ///
  /// In en, this message translates to:
  /// **'{m, plural, one{1 minute} other{{m} minutes}}'**
  String commonMinutes(int m);

  /// No description provided for @settingsShiftCycles.
  ///
  /// In en, this message translates to:
  /// **'SHIFT CYCLES'**
  String get settingsShiftCycles;

  /// No description provided for @settingsShiftCyclesSub.
  ///
  /// In en, this message translates to:
  /// **'Rosters you have generated from a pattern or template.'**
  String get settingsShiftCyclesSub;

  /// No description provided for @settingsAddShiftCycle.
  ///
  /// In en, this message translates to:
  /// **'Add Shift Cycle'**
  String get settingsAddShiftCycle;

  /// No description provided for @settingsNoRosters.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t generated any rosters yet.'**
  String get settingsNoRosters;

  /// No description provided for @commonDateRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String commonDateRange(String start, String end);

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @settingsDeleteRosterTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete roster?'**
  String get settingsDeleteRosterTitle;

  /// No description provided for @settingsDeleteRosterBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{label}\"? This will cancel any pending alarms and remove {count, plural, one{1 shift} other{{count} shifts}}.'**
  String settingsDeleteRosterBody(String label, int count);

  /// No description provided for @settingsDeletedRoster.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{label}\"'**
  String settingsDeletedRoster(String label);

  /// No description provided for @commonActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// No description provided for @commonUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get commonUpcoming;

  /// No description provided for @commonPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get commonPast;

  /// No description provided for @settingsWorkHistory.
  ///
  /// In en, this message translates to:
  /// **'WORK HISTORY'**
  String get settingsWorkHistory;

  /// No description provided for @settingsWorkHistorySub.
  ///
  /// In en, this message translates to:
  /// **'Review and export your completed custom shifts to verify payslips.'**
  String get settingsWorkHistorySub;

  /// No description provided for @settingsViewWorkHistory.
  ///
  /// In en, this message translates to:
  /// **'View & Export Work History'**
  String get settingsViewWorkHistory;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get settingsPreferences;

  /// No description provided for @settingsPreferencesSub.
  ///
  /// In en, this message translates to:
  /// **'How your schedule is displayed across the app.'**
  String get settingsPreferencesSub;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSub.
  ///
  /// In en, this message translates to:
  /// **'Dark is Rostrik’s default. Light uses a warm cream palette.'**
  String get settingsThemeSub;

  /// No description provided for @settings24h.
  ///
  /// In en, this message translates to:
  /// **'Use 24-Hour Time'**
  String get settings24h;

  /// No description provided for @settings24hOn.
  ///
  /// In en, this message translates to:
  /// **'Times show as 14:30'**
  String get settings24hOn;

  /// No description provided for @settings24hOff.
  ///
  /// In en, this message translates to:
  /// **'Times show as 02:30 PM'**
  String get settings24hOff;

  /// No description provided for @settingsWeekStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Calendar on Monday'**
  String get settingsWeekStartTitle;

  /// No description provided for @settingsWeekStartMon.
  ///
  /// In en, this message translates to:
  /// **'Weeks begin on Monday'**
  String get settingsWeekStartMon;

  /// No description provided for @settingsWeekStartSun.
  ///
  /// In en, this message translates to:
  /// **'Weeks begin on Sunday'**
  String get settingsWeekStartSun;

  /// No description provided for @settingsTimelineOpensOn.
  ///
  /// In en, this message translates to:
  /// **'Timeline opens on'**
  String get settingsTimelineOpensOn;

  /// No description provided for @commonList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get commonList;

  /// No description provided for @commonMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get commonMonth;

  /// No description provided for @settingsCalendar.
  ///
  /// In en, this message translates to:
  /// **'CALENDAR'**
  String get settingsCalendar;

  /// No description provided for @settingsCalendarSync.
  ///
  /// In en, this message translates to:
  /// **'Sync to Google / Device Calendar'**
  String get settingsCalendarSync;

  /// No description provided for @settingsCalendarSyncSub.
  ///
  /// In en, this message translates to:
  /// **'Automatically mirror your shifts to a dedicated \"Rostrik Roster\" calendar on your phone.'**
  String get settingsCalendarSyncSub;

  /// No description provided for @settingsCalSyncOff.
  ///
  /// In en, this message translates to:
  /// **'Calendar sync off. Upcoming \"Rostrik Roster\" events were cleared.'**
  String get settingsCalSyncOff;

  /// No description provided for @settingsCalSyncMirroring.
  ///
  /// In en, this message translates to:
  /// **'Mirroring your roster to the \"Rostrik Roster\" calendar…'**
  String get settingsCalSyncMirroring;

  /// No description provided for @settingsCalPermNeeded.
  ///
  /// In en, this message translates to:
  /// **'Calendar permission is needed to sync your roster.'**
  String get settingsCalPermNeeded;

  /// No description provided for @settingsCalBlocked.
  ///
  /// In en, this message translates to:
  /// **'Calendar access is blocked. Enable it in system settings to sync.'**
  String get settingsCalBlocked;

  /// No description provided for @settingsCalOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsCalOpenSettings;

  /// No description provided for @settingsCalUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Calendar sync isn\'t available on this device.'**
  String get settingsCalUnsupported;

  /// No description provided for @settingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get settingsDangerZone;

  /// No description provided for @settingsDangerZoneSub.
  ///
  /// In en, this message translates to:
  /// **'Deletes your roster, alarms, and settings, then restarts onboarding from scratch.'**
  String get settingsDangerZoneSub;

  /// No description provided for @settingsResetAppData.
  ///
  /// In en, this message translates to:
  /// **'Reset App Data'**
  String get settingsResetAppData;

  /// No description provided for @settingsResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset app?'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will delete your roster, alarms, and settings.'**
  String get settingsResetBody;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsResetConfirm;

  /// No description provided for @dashNoUpcomingShifts.
  ///
  /// In en, this message translates to:
  /// **'No upcoming shifts'**
  String get dashNoUpcomingShifts;

  /// No description provided for @dashEnjoyTimeOff.
  ///
  /// In en, this message translates to:
  /// **'Enjoy your time off.'**
  String get dashEnjoyTimeOff;

  /// No description provided for @dashInProgress.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get dashInProgress;

  /// No description provided for @dashRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get dashRotation;

  /// No description provided for @dashAlarmsCantRing.
  ///
  /// In en, this message translates to:
  /// **'Alarms can\'t ring reliably'**
  String get dashAlarmsCantRing;

  /// No description provided for @dashNotifsOffIssue.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off — a ringing alarm can\'t show its wake screen or be dismissed.'**
  String get dashNotifsOffIssue;

  /// No description provided for @dashOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get dashOpenSettings;

  /// No description provided for @dashExactBlockedIssue.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are blocked — wake-ups can\'t be scheduled at all.'**
  String get dashExactBlockedIssue;

  /// No description provided for @dashAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get dashAllow;

  /// No description provided for @dashSlideToSkip.
  ///
  /// In en, this message translates to:
  /// **'Slide to skip this alarm'**
  String get dashSlideToSkip;

  /// No description provided for @dashSlideToSkipAll.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Slide to skip the alarm} other{Slide to skip all {count} alarms}}'**
  String dashSlideToSkipAll(int count);

  /// No description provided for @dashDismissUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Dismiss upcoming alarm · {time}'**
  String dashDismissUpcoming(String time);

  /// No description provided for @dashSkipAllForShift.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Skip the alarm for this shift} other{Skip all {count} alarms for this shift}}'**
  String dashSkipAllForShift(int count);

  /// No description provided for @dashKeepAlarm.
  ///
  /// In en, this message translates to:
  /// **'Keep alarm'**
  String get dashKeepAlarm;

  /// No description provided for @dashMyRotation.
  ///
  /// In en, this message translates to:
  /// **'My Rotation'**
  String get dashMyRotation;

  /// No description provided for @dashCalendarUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Calendar & upcoming shifts'**
  String get dashCalendarUpcoming;

  /// No description provided for @dashNextShifts.
  ///
  /// In en, this message translates to:
  /// **'Next shifts'**
  String get dashNextShifts;

  /// No description provided for @dashOpenTimeline.
  ///
  /// In en, this message translates to:
  /// **'Open Timeline'**
  String get dashOpenTimeline;

  /// No description provided for @heroStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in {countdown}'**
  String heroStartsIn(String countdown);

  /// No description provided for @heroEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Ends in {countdown}'**
  String heroEndsIn(String countdown);

  /// No description provided for @heroStartsInPrefix.
  ///
  /// In en, this message translates to:
  /// **'Starts in'**
  String get heroStartsInPrefix;

  /// No description provided for @heroEndsInPrefix.
  ///
  /// In en, this message translates to:
  /// **'Ends in'**
  String get heroEndsInPrefix;

  /// No description provided for @heroStartsTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Starts today at {time}'**
  String heroStartsTodayAt(String time);

  /// No description provided for @heroStartedTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Started today at {time}'**
  String heroStartedTodayAt(String time);

  /// No description provided for @heroStartsTomorrowAt.
  ///
  /// In en, this message translates to:
  /// **'Starts tomorrow at {time}'**
  String heroStartsTomorrowAt(String time);

  /// No description provided for @heroStartedYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Started yesterday at {time}'**
  String heroStartedYesterdayAt(String time);

  /// No description provided for @heroStartsYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Starts yesterday at {time}'**
  String heroStartsYesterdayAt(String time);

  /// No description provided for @heroStartsOnAt.
  ///
  /// In en, this message translates to:
  /// **'Starts {date} at {time}'**
  String heroStartsOnAt(String date, String time);

  /// No description provided for @heroStartedOnAt.
  ///
  /// In en, this message translates to:
  /// **'Started {date} at {time}'**
  String heroStartedOnAt(String date, String time);

  /// No description provided for @shiftTypeDayShift.
  ///
  /// In en, this message translates to:
  /// **'Day shift'**
  String get shiftTypeDayShift;

  /// No description provided for @shiftTypeAfternoonShift.
  ///
  /// In en, this message translates to:
  /// **'Afternoon shift'**
  String get shiftTypeAfternoonShift;

  /// No description provided for @shiftTypeNightShift.
  ///
  /// In en, this message translates to:
  /// **'Night shift'**
  String get shiftTypeNightShift;

  /// No description provided for @heroDayXofY.
  ///
  /// In en, this message translates to:
  /// **'Day {x} of {y} — {label}'**
  String heroDayXofY(int x, int y, String label);

  /// No description provided for @heroOffTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Off tomorrow'**
  String get heroOffTomorrow;

  /// No description provided for @heroOffInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Off in 1 day} other{Off in {days} days}}'**
  String heroOffInDays(int days);

  /// No description provided for @heroBackOnTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Back on tomorrow'**
  String get heroBackOnTomorrow;

  /// No description provided for @heroBackOnInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Back on in 1 day} other{Back on in {days} days}}'**
  String heroBackOnInDays(int days);

  /// No description provided for @heroOffRdo.
  ///
  /// In en, this message translates to:
  /// **'Off / RDO'**
  String get heroOffRdo;

  /// No description provided for @durationDayShort.
  ///
  /// In en, this message translates to:
  /// **'{d}d'**
  String durationDayShort(int d);

  /// No description provided for @durationDayHourShort.
  ///
  /// In en, this message translates to:
  /// **'{d}d {h}h'**
  String durationDayHourShort(int d, int h);

  /// No description provided for @alarmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarmsTitle;

  /// No description provided for @alarmsAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add alarm'**
  String get alarmsAddTooltip;

  /// No description provided for @alarmsSortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort alarms'**
  String get alarmsSortTooltip;

  /// No description provided for @alarmsSortByTime.
  ///
  /// In en, this message translates to:
  /// **'By time'**
  String get alarmsSortByTime;

  /// No description provided for @alarmsSortByShiftType.
  ///
  /// In en, this message translates to:
  /// **'By shift type'**
  String get alarmsSortByShiftType;

  /// No description provided for @alarmsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No alarms yet.'**
  String get alarmsEmptyTitle;

  /// No description provided for @alarmsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add one.'**
  String get alarmsEmptyBody;

  /// No description provided for @alarmsNextAlarm.
  ///
  /// In en, this message translates to:
  /// **'NEXT ALARM'**
  String get alarmsNextAlarm;

  /// No description provided for @alarmsHolidayMode.
  ///
  /// In en, this message translates to:
  /// **'Holiday mode'**
  String get alarmsHolidayMode;

  /// No description provided for @alarmsHolidayModeSub.
  ///
  /// In en, this message translates to:
  /// **'Alarms are paused — nothing will ring.'**
  String get alarmsHolidayModeSub;

  /// No description provided for @alarmsNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming shift alarm'**
  String get alarmsNoUpcoming;

  /// No description provided for @alarmsNoUpcomingSub.
  ///
  /// In en, this message translates to:
  /// **'Add a follows-rotation alarm, or generate a roster.'**
  String get alarmsNoUpcomingSub;

  /// No description provided for @alarmsForYourShift.
  ///
  /// In en, this message translates to:
  /// **'for your {type} shift · {day}'**
  String alarmsForYourShift(String type, String day);

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get commonTomorrow;

  /// No description provided for @alarmsOffWontRing.
  ///
  /// In en, this message translates to:
  /// **'Off — won\'t ring'**
  String get alarmsOffWontRing;

  /// No description provided for @alarmsNoUpcomingRing.
  ///
  /// In en, this message translates to:
  /// **'No upcoming ring scheduled'**
  String get alarmsNoUpcomingRing;

  /// No description provided for @alarmsNextRing.
  ///
  /// In en, this message translates to:
  /// **'Next ring: {day} at {time}'**
  String alarmsNextRing(String day, String time);

  /// No description provided for @alarmsSwipeToDelete.
  ///
  /// In en, this message translates to:
  /// **'Swipe to delete'**
  String get alarmsSwipeToDelete;

  /// No description provided for @alarmsRingsOnceAutoDelete.
  ///
  /// In en, this message translates to:
  /// **'Rings once · auto-deletes'**
  String get alarmsRingsOnceAutoDelete;

  /// No description provided for @alarmsRingsOnce.
  ///
  /// In en, this message translates to:
  /// **'Rings one time only'**
  String get alarmsRingsOnce;

  /// No description provided for @alarmsYourShift.
  ///
  /// In en, this message translates to:
  /// **'your shift'**
  String get alarmsYourShift;

  /// No description provided for @alarmsShiftsOfType.
  ///
  /// In en, this message translates to:
  /// **'{type} shifts'**
  String alarmsShiftsOfType(String type);

  /// No description provided for @alarmsExactTime.
  ///
  /// In en, this message translates to:
  /// **'Exact time · {shift}'**
  String alarmsExactTime(String shift);

  /// No description provided for @alarmsLeadBeforeDefault.
  ///
  /// In en, this message translates to:
  /// **'{lead} before {shift} · default'**
  String alarmsLeadBeforeDefault(String lead, String shift);

  /// No description provided for @alarmsLeadBefore.
  ///
  /// In en, this message translates to:
  /// **'{lead} before {shift}'**
  String alarmsLeadBefore(String lead, String shift);

  /// No description provided for @createEditAlarm.
  ///
  /// In en, this message translates to:
  /// **'Edit alarm'**
  String get createEditAlarm;

  /// No description provided for @createNewAlarm.
  ///
  /// In en, this message translates to:
  /// **'New alarm'**
  String get createNewAlarm;

  /// No description provided for @createDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Wake Up'**
  String get createDefaultLabel;

  /// No description provided for @createFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get createFallbackLabel;

  /// No description provided for @createPickBecomesDefault.
  ///
  /// In en, this message translates to:
  /// **'Your pick becomes the default for new alarms.'**
  String get createPickBecomesDefault;

  /// No description provided for @createSelectFromFiles.
  ///
  /// In en, this message translates to:
  /// **'Select from Files'**
  String get createSelectFromFiles;

  /// No description provided for @createFilesSub.
  ///
  /// In en, this message translates to:
  /// **'Pick an audio file saved on your device'**
  String get createFilesSub;

  /// No description provided for @createSelectSystemTone.
  ///
  /// In en, this message translates to:
  /// **'Select System Tone'**
  String get createSelectSystemTone;

  /// No description provided for @createSystemToneSub.
  ///
  /// In en, this message translates to:
  /// **'Choose from your device\'s alarm sounds'**
  String get createSystemToneSub;

  /// No description provided for @createAlarmTiming.
  ///
  /// In en, this message translates to:
  /// **'Alarm timing'**
  String get createAlarmTiming;

  /// No description provided for @createLeadTimeMode.
  ///
  /// In en, this message translates to:
  /// **'Lead time'**
  String get createLeadTimeMode;

  /// No description provided for @createExactTimeMode.
  ///
  /// In en, this message translates to:
  /// **'Exact time'**
  String get createExactTimeMode;

  /// No description provided for @createFiresAt.
  ///
  /// In en, this message translates to:
  /// **'Fires at {time}'**
  String createFiresAt(String time);

  /// No description provided for @createLeadBeforeShiftStart.
  ///
  /// In en, this message translates to:
  /// **'{lead} before shift start'**
  String createLeadBeforeShiftStart(String lead);

  /// No description provided for @createLinkedShift.
  ///
  /// In en, this message translates to:
  /// **'Linked shift'**
  String get createLinkedShift;

  /// No description provided for @createRepeatOn.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get createRepeatOn;

  /// No description provided for @createLabelField.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get createLabelField;

  /// No description provided for @createLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Wake Up'**
  String get createLabelHint;

  /// No description provided for @createCriticalShift.
  ///
  /// In en, this message translates to:
  /// **'Critical shift'**
  String get createCriticalShift;

  /// No description provided for @createCriticalShiftSub.
  ///
  /// In en, this message translates to:
  /// **'Shake to dismiss · 3-second hold fail-safe'**
  String get createCriticalShiftSub;

  /// No description provided for @createRingtone.
  ///
  /// In en, this message translates to:
  /// **'Ringtone'**
  String get createRingtone;

  /// No description provided for @commonStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get commonStop;

  /// No description provided for @commonPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get commonPlay;

  /// No description provided for @createVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get createVibrate;

  /// No description provided for @createRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get createRepeat;

  /// No description provided for @createRepeatRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get createRepeatRotation;

  /// No description provided for @createRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get createRepeatWeekly;

  /// No description provided for @createRepeatOneTime.
  ///
  /// In en, this message translates to:
  /// **'One time'**
  String get createRepeatOneTime;

  /// No description provided for @createPickOneDay.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day'**
  String get createPickOneDay;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get commonSaveChanges;

  /// No description provided for @createTimeBeforeShift.
  ///
  /// In en, this message translates to:
  /// **'Time before shift'**
  String get createTimeBeforeShift;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @sleepTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepTitle;

  /// No description provided for @sleepTargetHeader.
  ///
  /// In en, this message translates to:
  /// **'SLEEP TARGET'**
  String get sleepTargetHeader;

  /// No description provided for @sleepTargetSub.
  ///
  /// In en, this message translates to:
  /// **'How many hours you want. Rostrik counts back from your next wake-up alarm to set tonight’s bedtime.'**
  String get sleepTargetSub;

  /// No description provided for @sleepRemindersHeader.
  ///
  /// In en, this message translates to:
  /// **'REMINDERS'**
  String get sleepRemindersHeader;

  /// No description provided for @sleepWindDownHeader.
  ///
  /// In en, this message translates to:
  /// **'WIND-DOWN LEAD'**
  String get sleepWindDownHeader;

  /// No description provided for @sleepWindDownSub.
  ///
  /// In en, this message translates to:
  /// **'How long before bedtime the wind-down nudge lands.'**
  String get sleepWindDownSub;

  /// No description provided for @sleepSoundsHeader.
  ///
  /// In en, this message translates to:
  /// **'SLEEP SOUNDS'**
  String get sleepSoundsHeader;

  /// No description provided for @sleepSoundsSub.
  ///
  /// In en, this message translates to:
  /// **'White & brown noise to drift off to. Pick an auto-stop timer and tap a sound.'**
  String get sleepSoundsSub;

  /// No description provided for @sleepNothingToPlan.
  ///
  /// In en, this message translates to:
  /// **'Nothing to plan tonight'**
  String get sleepNothingToPlan;

  /// No description provided for @sleepNothingToPlanSub.
  ///
  /// In en, this message translates to:
  /// **'Add a shift to your roster and Rostrik will build a personalised bedtime around your next wake-up.'**
  String get sleepNothingToPlanSub;

  /// No description provided for @sleepTransitionDay.
  ///
  /// In en, this message translates to:
  /// **'TRANSITION DAY'**
  String get sleepTransitionDay;

  /// No description provided for @sleepTransitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is a Night Shift. Consider sleeping in.'**
  String get sleepTransitionTitle;

  /// No description provided for @sleepTransitionBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s a transition day — you have a rest day before nights, so there\'s no early alarm to chase. Bank extra rest now and let your body drift later tonight.'**
  String get sleepTransitionBody;

  /// No description provided for @sleepRestRecovery.
  ///
  /// In en, this message translates to:
  /// **'REST & RECOVERY'**
  String get sleepRestRecovery;

  /// No description provided for @sleepNoEarlyAlarm.
  ///
  /// In en, this message translates to:
  /// **'No early alarm to chase'**
  String get sleepNoEarlyAlarm;

  /// No description provided for @sleepRestBody.
  ///
  /// In en, this message translates to:
  /// **'Your next shift is more than a day away, so there\'s no wake-up to plan tonight. Sleep on your own clock and bank some recovery — Rostrik will build your bedtime plan as it draws closer.'**
  String get sleepRestBody;

  /// No description provided for @sleepTonightsPlan.
  ///
  /// In en, this message translates to:
  /// **'TONIGHT\'S PLAN'**
  String get sleepTonightsPlan;

  /// No description provided for @sleepTargetBedtime.
  ///
  /// In en, this message translates to:
  /// **'Target bedtime'**
  String get sleepTargetBedtime;

  /// No description provided for @sleepWindDownStat.
  ///
  /// In en, this message translates to:
  /// **'Wind-down'**
  String get sleepWindDownStat;

  /// No description provided for @sleepWakeUpStat.
  ///
  /// In en, this message translates to:
  /// **'Wake up'**
  String get sleepWakeUpStat;

  /// No description provided for @sleepDurationStat.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sleepDurationStat;

  /// No description provided for @sleepBedtimeReminder.
  ///
  /// In en, this message translates to:
  /// **'Bedtime Reminder'**
  String get sleepBedtimeReminder;

  /// No description provided for @sleepNudgeAtBedtime.
  ///
  /// In en, this message translates to:
  /// **'Nudge me at {time} to head to bed'**
  String sleepNudgeAtBedtime(String time);

  /// No description provided for @sleepBedtimeSub.
  ///
  /// In en, this message translates to:
  /// **'A nudge when it\'s time to head to bed'**
  String get sleepBedtimeSub;

  /// No description provided for @sleepWindDownReminder.
  ///
  /// In en, this message translates to:
  /// **'Wind-Down Reminder'**
  String get sleepWindDownReminder;

  /// No description provided for @sleepNudgeAtWindDown.
  ///
  /// In en, this message translates to:
  /// **'Nudge me at {time} to start winding down'**
  String sleepNudgeAtWindDown(String time);

  /// No description provided for @sleepWindDownReminderSub.
  ///
  /// In en, this message translates to:
  /// **'An earlier heads-up to start winding down'**
  String get sleepWindDownReminderSub;

  /// No description provided for @commonOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get commonOff;

  /// No description provided for @sleepSoundWhiteNoise.
  ///
  /// In en, this message translates to:
  /// **'White Noise'**
  String get sleepSoundWhiteNoise;

  /// No description provided for @sleepSoundPinkNoise.
  ///
  /// In en, this message translates to:
  /// **'Pink Noise'**
  String get sleepSoundPinkNoise;

  /// No description provided for @sleepSoundBrownNoise.
  ///
  /// In en, this message translates to:
  /// **'Brown Noise'**
  String get sleepSoundBrownNoise;

  /// No description provided for @sleepSoundFan.
  ///
  /// In en, this message translates to:
  /// **'Fan'**
  String get sleepSoundFan;

  /// No description provided for @sleepSoundOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get sleepSoundOcean;

  /// No description provided for @sleepSoundRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get sleepSoundRain;

  /// No description provided for @manageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageTitle;

  /// No description provided for @manageRosterTools.
  ///
  /// In en, this message translates to:
  /// **'ROSTER TOOLS'**
  String get manageRosterTools;

  /// No description provided for @manageRosterToolsSub.
  ///
  /// In en, this message translates to:
  /// **'Build and adjust the shifts that drive your alarms and sleep plan.'**
  String get manageRosterToolsSub;

  /// No description provided for @manageGenerateRotation.
  ///
  /// In en, this message translates to:
  /// **'Generate Rotation'**
  String get manageGenerateRotation;

  /// No description provided for @manageGenerateRotationSub.
  ///
  /// In en, this message translates to:
  /// **'Build a repeating shift pattern from a template.'**
  String get manageGenerateRotationSub;

  /// No description provided for @manageAddCustomShift.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Shift'**
  String get manageAddCustomShift;

  /// No description provided for @manageAddCustomShiftSub.
  ///
  /// In en, this message translates to:
  /// **'Drop a single one-off shift onto your roster.'**
  String get manageAddCustomShiftSub;

  /// No description provided for @manageMarkLeave.
  ///
  /// In en, this message translates to:
  /// **'Mark Leave / Time Off'**
  String get manageMarkLeave;

  /// No description provided for @manageMarkLeaveSub.
  ///
  /// In en, this message translates to:
  /// **'Paint the days you\'re off (annual leave, sick) in one go.'**
  String get manageMarkLeaveSub;

  /// No description provided for @managePauseSchedule.
  ///
  /// In en, this message translates to:
  /// **'Pause Schedule'**
  String get managePauseSchedule;

  /// No description provided for @managePausedSub.
  ///
  /// In en, this message translates to:
  /// **'Holiday mode ON — alarms are silenced, your roster is safe.'**
  String get managePausedSub;

  /// No description provided for @manageNotPausedSub.
  ///
  /// In en, this message translates to:
  /// **'Holiday mode — silence alarms while you\'re off-roster.'**
  String get manageNotPausedSub;

  /// No description provided for @markLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark leave'**
  String get markLeaveTitle;

  /// No description provided for @markLeaveIntro.
  ///
  /// In en, this message translates to:
  /// **'Tap the days you’re off, choose a reason, then apply. Alarms on those days won’t fire — your roster stays intact.'**
  String get markLeaveIntro;

  /// No description provided for @leaveAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual Leave'**
  String get leaveAnnual;

  /// No description provided for @leaveSick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get leaveSick;

  /// No description provided for @leavePublicHoliday.
  ///
  /// In en, this message translates to:
  /// **'Public Holiday'**
  String get leavePublicHoliday;

  /// No description provided for @markLeaveReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get markLeaveReason;

  /// No description provided for @markLeaveFallbackReason.
  ///
  /// In en, this message translates to:
  /// **'leave'**
  String get markLeaveFallbackReason;

  /// No description provided for @markLeaveMarked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Marked 1 shift as {reason}.} other{Marked {count} shifts as {reason}.}}'**
  String markLeaveMarked(int count, String reason);

  /// No description provided for @markLeaveSelectDays.
  ///
  /// In en, this message translates to:
  /// **'Select days to mark'**
  String get markLeaveSelectDays;

  /// No description provided for @markLeaveNoShifts.
  ///
  /// In en, this message translates to:
  /// **'No shifts on those days'**
  String get markLeaveNoShifts;

  /// No description provided for @markLeaveApplyTo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Apply to 1 shift} other{Apply to {count} shifts}}'**
  String markLeaveApplyTo(int count);

  /// No description provided for @workHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Work History'**
  String get workHistoryTitle;

  /// No description provided for @workHistoryExportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export History'**
  String get workHistoryExportTooltip;

  /// No description provided for @workHistoryExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export history: {error}'**
  String workHistoryExportFailed(String error);

  /// No description provided for @workHistoryWorked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 shift worked} other{{count} shifts worked}}'**
  String workHistoryWorked(int count);

  /// No description provided for @workHistoryHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String workHistoryHours(String hours);

  /// No description provided for @commonPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get commonPaused;

  /// No description provided for @workHistoryPausedReason.
  ///
  /// In en, this message translates to:
  /// **'Paused · {reason}'**
  String workHistoryPausedReason(String reason);

  /// No description provided for @workHistoryRotationBadge.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get workHistoryRotationBadge;

  /// No description provided for @workHistoryAdHocBadge.
  ///
  /// In en, this message translates to:
  /// **'Ad-Hoc'**
  String get workHistoryAdHocBadge;

  /// No description provided for @workHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No completed shifts yet'**
  String get workHistoryEmptyTitle;

  /// No description provided for @workHistoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your worked shifts — rotation and custom alike — appear here once they finish, ready to export for payslip verification.'**
  String get workHistoryEmptyBody;

  /// No description provided for @workHistoryShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Rostrik Work History'**
  String get workHistoryShareSubject;

  /// No description provided for @workHistoryShareText.
  ///
  /// In en, this message translates to:
  /// **'My Rostrik work history export.'**
  String get workHistoryShareText;

  /// No description provided for @shiftEdAddShift.
  ///
  /// In en, this message translates to:
  /// **'Add shift'**
  String get shiftEdAddShift;

  /// No description provided for @shiftEdEditShift.
  ///
  /// In en, this message translates to:
  /// **'Edit shift'**
  String get shiftEdEditShift;

  /// No description provided for @shiftEdDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get shiftEdDate;

  /// No description provided for @shiftEdPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get shiftEdPickDate;

  /// No description provided for @shiftEdStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get shiftEdStarts;

  /// No description provided for @shiftEdEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get shiftEdEnds;

  /// No description provided for @shiftEdPickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick time'**
  String get shiftEdPickTime;

  /// No description provided for @shiftEdEndsNextDay.
  ///
  /// In en, this message translates to:
  /// **'Ends next day'**
  String get shiftEdEndsNextDay;

  /// No description provided for @shiftEdPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause / cancel this shift'**
  String get shiftEdPauseTitle;

  /// No description provided for @shiftEdPausedSub.
  ///
  /// In en, this message translates to:
  /// **'Alarm won\'t fire. Stays on your calendar as a record.'**
  String get shiftEdPausedSub;

  /// No description provided for @shiftEdNotPausedSub.
  ///
  /// In en, this message translates to:
  /// **'Mark a day off (sick, leave, holiday) without deleting it.'**
  String get shiftEdNotPausedSub;

  /// No description provided for @shiftEdReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get shiftEdReasonOptional;

  /// No description provided for @dayShifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get dayShifts;

  /// No description provided for @dayActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get dayActivities;

  /// No description provided for @dayAddAnotherShift.
  ///
  /// In en, this message translates to:
  /// **'Add another shift'**
  String get dayAddAnotherShift;

  /// No description provided for @dayAddActivity.
  ///
  /// In en, this message translates to:
  /// **'Add activity'**
  String get dayAddActivity;

  /// No description provided for @dayAddActivitySub.
  ///
  /// In en, this message translates to:
  /// **'Event, task or birthday'**
  String get dayAddActivitySub;

  /// No description provided for @dayReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get dayReminder;

  /// No description provided for @actEditActivity.
  ///
  /// In en, this message translates to:
  /// **'Edit activity'**
  String get actEditActivity;

  /// No description provided for @actLeadAtTime.
  ///
  /// In en, this message translates to:
  /// **'At time'**
  String get actLeadAtTime;

  /// No description provided for @actLead10Min.
  ///
  /// In en, this message translates to:
  /// **'10 min before'**
  String get actLead10Min;

  /// No description provided for @actLead30Min.
  ///
  /// In en, this message translates to:
  /// **'30 min before'**
  String get actLead30Min;

  /// No description provided for @actLead1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get actLead1Hour;

  /// No description provided for @actLead1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get actLead1Day;

  /// No description provided for @actEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get actEvent;

  /// No description provided for @actTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get actTask;

  /// No description provided for @actBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get actBirthday;

  /// No description provided for @actTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get actTitleField;

  /// No description provided for @actAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get actAllDay;

  /// No description provided for @actTimeField.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get actTimeField;

  /// No description provided for @actRemindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get actRemindMe;

  /// No description provided for @actRemindMeSub.
  ///
  /// In en, this message translates to:
  /// **'A gentle notification — separate from your shift alarms.'**
  String get actRemindMeSub;

  /// No description provided for @actRemindAt.
  ///
  /// In en, this message translates to:
  /// **'Remind at'**
  String get actRemindAt;

  /// No description provided for @actReminderPassed.
  ///
  /// In en, this message translates to:
  /// **'That time has already passed — this reminder won’t fire.'**
  String get actReminderPassed;

  /// No description provided for @actNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get actNoteOptional;

  /// No description provided for @actCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get actCompleted;

  /// No description provided for @tipDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your dashboard'**
  String get tipDashboardTitle;

  /// No description provided for @tipDashboardBody.
  ///
  /// In en, this message translates to:
  /// **'Home base. See your next shift with a live countdown and where you are in your rotation. Tap a tile to jump straight to the details.'**
  String get tipDashboardBody;

  /// No description provided for @tipTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Your whole roster'**
  String get tipTimelineTitle;

  /// No description provided for @tipTimelineBody.
  ///
  /// In en, this message translates to:
  /// **'Switch between a List and a Month calendar up top. Tap any day to edit a shift — or add an event, task or birthday.'**
  String get tipTimelineBody;

  /// No description provided for @tipManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Build & adjust'**
  String get tipManageTitle;

  /// No description provided for @tipManageBody.
  ///
  /// In en, this message translates to:
  /// **'Create a rotating roster, add a one-off (overtime) shift, or pause your whole schedule for leave — all from here.'**
  String get tipManageBody;

  /// No description provided for @tipAlarmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your alarms'**
  String get tipAlarmsTitle;

  /// No description provided for @tipAlarmsBody.
  ///
  /// In en, this message translates to:
  /// **'Every alarm your shifts create, plus any you add yourself. Tap one to change its time or tone, or make it a shake-to-dismiss Critical Shift alarm.'**
  String get tipAlarmsBody;

  /// No description provided for @tipSleepTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep plan'**
  String get tipSleepTitle;

  /// No description provided for @tipSleepBody.
  ///
  /// In en, this message translates to:
  /// **'A wind-down plan that follows your roster: set a sleep goal and get ready for your next shift feeling rested.'**
  String get tipSleepBody;

  /// No description provided for @tipReplayHint.
  ///
  /// In en, this message translates to:
  /// **'Replay these anytime from Settings › How it works.'**
  String get tipReplayHint;

  /// No description provided for @tipDontShow.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show tips'**
  String get tipDontShow;

  /// No description provided for @tipGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get tipGotIt;

  /// No description provided for @timelineListView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get timelineListView;

  /// No description provided for @timelineMonthView.
  ///
  /// In en, this message translates to:
  /// **'Month View'**
  String get timelineMonthView;

  /// No description provided for @shiftTypeAftShort.
  ///
  /// In en, this message translates to:
  /// **'Aft'**
  String get shiftTypeAftShort;

  /// No description provided for @timelineNoShifts.
  ///
  /// In en, this message translates to:
  /// **'No shifts scheduled. Tap + to add one.'**
  String get timelineNoShifts;

  /// No description provided for @timelineNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No shifts match the {filter} filter.'**
  String timelineNoMatch(String filter);

  /// No description provided for @timelineRestDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get timelineRestDay;

  /// No description provided for @timelineRestDayReason.
  ///
  /// In en, this message translates to:
  /// **'Rest day · {reason}'**
  String timelineRestDayReason(String reason);

  /// No description provided for @timelineAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get timelineAllDay;

  /// No description provided for @calLegendPausedLeave.
  ///
  /// In en, this message translates to:
  /// **'Paused / Leave'**
  String get calLegendPausedLeave;

  /// No description provided for @calLegendActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get calLegendActivity;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get filterWork;

  /// No description provided for @criticalHoldToDismiss.
  ///
  /// In en, this message translates to:
  /// **'Or hold to dismiss'**
  String get criticalHoldToDismiss;

  /// No description provided for @patternChoosePattern.
  ///
  /// In en, this message translates to:
  /// **'Choose a pattern'**
  String get patternChoosePattern;

  /// No description provided for @patternRotatingSwings.
  ///
  /// In en, this message translates to:
  /// **'Rotating Swings'**
  String get patternRotatingSwings;

  /// No description provided for @patternDaySwings.
  ///
  /// In en, this message translates to:
  /// **'Day Only Swings'**
  String get patternDaySwings;

  /// No description provided for @patternNightSwings.
  ///
  /// In en, this message translates to:
  /// **'Night Only Swings'**
  String get patternNightSwings;

  /// No description provided for @patternShiftTimes.
  ///
  /// In en, this message translates to:
  /// **'Shift times'**
  String get patternShiftTimes;

  /// No description provided for @patternGenerate.
  ///
  /// In en, this message translates to:
  /// **'Set Day 1 & Generate'**
  String get patternGenerate;

  /// No description provided for @patternSelectDay1.
  ///
  /// In en, this message translates to:
  /// **'Select your Next Day 1'**
  String get patternSelectDay1;

  /// No description provided for @patternDay1Hint.
  ///
  /// In en, this message translates to:
  /// **'First day of your {label} block'**
  String patternDay1Hint(String label);

  /// No description provided for @patternNextDay1.
  ///
  /// In en, this message translates to:
  /// **'Next Day 1'**
  String get patternNextDay1;

  /// No description provided for @patternUseThisDate.
  ///
  /// In en, this message translates to:
  /// **'Use this date'**
  String get patternUseThisDate;

  /// No description provided for @patternGenerated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Generated 1 shift} other{Generated {count} shifts}}'**
  String patternGenerated(int count);

  /// No description provided for @patternGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Generation failed: {error}'**
  String patternGenerationFailed(String error);

  /// No description provided for @patternFirstBlockFallback.
  ///
  /// In en, this message translates to:
  /// **'first'**
  String get patternFirstBlockFallback;

  /// No description provided for @patternBuildCustom.
  ///
  /// In en, this message translates to:
  /// **'Build custom roster'**
  String get patternBuildCustom;

  /// No description provided for @patternBuildCustomSub.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t fit a preset? Compose your own blocks.'**
  String get patternBuildCustomSub;

  /// No description provided for @patternBlockDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{1 Day} other{{n} Days}}'**
  String patternBlockDays(int n);

  /// No description provided for @patternBlockAfternoons.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{1 Afternoon} other{{n} Afternoons}}'**
  String patternBlockAfternoons(int n);

  /// No description provided for @patternBlockNights.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{1 Night} other{{n} Nights}}'**
  String patternBlockNights(int n);

  /// No description provided for @patternBlockOff.
  ///
  /// In en, this message translates to:
  /// **'{n} Off'**
  String patternBlockOff(int n);

  /// No description provided for @builderNewRoster.
  ///
  /// In en, this message translates to:
  /// **'New Shift Roster'**
  String get builderNewRoster;

  /// No description provided for @builderEditRoster.
  ///
  /// In en, this message translates to:
  /// **'Edit Roster'**
  String get builderEditRoster;

  /// No description provided for @builderNewSub.
  ///
  /// In en, this message translates to:
  /// **'Set up your shift rotation pattern'**
  String get builderNewSub;

  /// No description provided for @builderEditSub.
  ///
  /// In en, this message translates to:
  /// **'Change and replace this saved roster'**
  String get builderEditSub;

  /// No description provided for @builderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Roster name (e.g. My 14-Day Rotation)'**
  String get builderNameHint;

  /// No description provided for @builderCycleLength.
  ///
  /// In en, this message translates to:
  /// **'CYCLE LENGTH'**
  String get builderCycleLength;

  /// No description provided for @builderStartDate.
  ///
  /// In en, this message translates to:
  /// **'START DATE'**
  String get builderStartDate;

  /// No description provided for @builderShiftBlocks.
  ///
  /// In en, this message translates to:
  /// **'SHIFT BLOCKS'**
  String get builderShiftBlocks;

  /// No description provided for @builderAddShiftBlock.
  ///
  /// In en, this message translates to:
  /// **'Add Shift Block'**
  String get builderAddShiftBlock;

  /// No description provided for @builderCreateRoster.
  ///
  /// In en, this message translates to:
  /// **'Create Roster'**
  String get builderCreateRoster;

  /// No description provided for @builderSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get builderSaveChanges;

  /// No description provided for @builderReplaceWarning.
  ///
  /// In en, this message translates to:
  /// **'Saving replaces this roster. Any leave / time-off marks painted on it will reset.'**
  String get builderReplaceWarning;

  /// No description provided for @builderBackToOptions.
  ///
  /// In en, this message translates to:
  /// **'Back to options'**
  String get builderBackToOptions;

  /// No description provided for @builderOrImport.
  ///
  /// In en, this message translates to:
  /// **'OR IMPORT AN EXISTING ROSTER'**
  String get builderOrImport;

  /// No description provided for @builderImportViaAi.
  ///
  /// In en, this message translates to:
  /// **'Import via AI'**
  String get builderImportViaAi;

  /// No description provided for @builderScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get builderScanning;

  /// No description provided for @builderScanInstead.
  ///
  /// In en, this message translates to:
  /// **'Scan a roster photo instead'**
  String get builderScanInstead;

  /// No description provided for @builderCustomChip.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get builderCustomChip;

  /// No description provided for @builderCycleLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Cycle length'**
  String get builderCycleLengthLabel;

  /// No description provided for @builderDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{1 day} other{{n} days}}'**
  String builderDaysCount(int n);

  /// No description provided for @builderPickADate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get builderPickADate;

  /// No description provided for @builderNoBlocksYet.
  ///
  /// In en, this message translates to:
  /// **'No blocks yet'**
  String get builderNoBlocksYet;

  /// No description provided for @builderNoBlocksSub.
  ///
  /// In en, this message translates to:
  /// **'Add shift blocks to define your rotation'**
  String get builderNoBlocksSub;

  /// No description provided for @builderDaysLine.
  ///
  /// In en, this message translates to:
  /// **'Days {ranges}'**
  String builderDaysLine(String ranges);

  /// No description provided for @builderEditBlock.
  ///
  /// In en, this message translates to:
  /// **'Edit block'**
  String get builderEditBlock;

  /// No description provided for @builderRemoveBlock.
  ///
  /// In en, this message translates to:
  /// **'Remove block'**
  String get builderRemoveBlock;

  /// No description provided for @builderPickRosterStart.
  ///
  /// In en, this message translates to:
  /// **'Pick the roster start date'**
  String get builderPickRosterStart;

  /// No description provided for @builderPickScanStart.
  ///
  /// In en, this message translates to:
  /// **'Pick the start date for the scanned roster'**
  String get builderPickScanStart;

  /// No description provided for @builderScanCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan with camera'**
  String get builderScanCamera;

  /// No description provided for @builderImportScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Import a screenshot'**
  String get builderImportScreenshot;

  /// No description provided for @builderScanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed: {error}'**
  String builderScanFailed(String error);

  /// No description provided for @builderNoTimesRecognised.
  ///
  /// In en, this message translates to:
  /// **'No shift times recognised. Try cropping tighter around the grid.'**
  String get builderNoTimesRecognised;

  /// No description provided for @builderCustomRosterFallback.
  ///
  /// In en, this message translates to:
  /// **'Custom roster'**
  String get builderCustomRosterFallback;

  /// No description provided for @builderScannedRosterFallback.
  ///
  /// In en, this message translates to:
  /// **'Scanned roster'**
  String get builderScannedRosterFallback;

  /// No description provided for @builderRosterUpdated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Roster updated — 1 shift scheduled} other{Roster updated — {count} shifts scheduled}}'**
  String builderRosterUpdated(int count);

  /// No description provided for @builderRosterCreated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Created — 1 shift scheduled} other{Created — {count} shifts scheduled}}'**
  String builderRosterCreated(int count);

  /// No description provided for @builderCouldNotCreate.
  ///
  /// In en, this message translates to:
  /// **'Could not create the roster: {error}'**
  String builderCouldNotCreate(String error);

  /// No description provided for @builderRosterImported.
  ///
  /// In en, this message translates to:
  /// **'Roster imported to your calendar'**
  String get builderRosterImported;

  /// No description provided for @builderCouldNotImport.
  ///
  /// In en, this message translates to:
  /// **'Could not import the roster: {error}'**
  String builderCouldNotImport(String error);

  /// No description provided for @blockAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add shift block'**
  String get blockAddTitle;

  /// No description provided for @blockEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit shift block'**
  String get blockEditTitle;

  /// No description provided for @blockStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get blockStart;

  /// No description provided for @blockEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get blockEnd;

  /// No description provided for @blockTapDays.
  ///
  /// In en, this message translates to:
  /// **'Tap the days this shift covers'**
  String get blockTapDays;

  /// No description provided for @blockUntappedOff.
  ///
  /// In en, this message translates to:
  /// **'Un-tapped days are Off.'**
  String get blockUntappedOff;

  /// No description provided for @blockOverlap.
  ///
  /// In en, this message translates to:
  /// **'This time overlaps another shift on day {ranges} — change the time or those days.'**
  String blockOverlap(String ranges);

  /// No description provided for @blockAdd.
  ///
  /// In en, this message translates to:
  /// **'Add block'**
  String get blockAdd;

  /// No description provided for @blockSave.
  ///
  /// In en, this message translates to:
  /// **'Save block'**
  String get blockSave;

  /// No description provided for @aiPromptCopied.
  ///
  /// In en, this message translates to:
  /// **'Prompt copied! Paste it into your AI app along with your roster.'**
  String get aiPromptCopied;

  /// No description provided for @aiNothingToPaste.
  ///
  /// In en, this message translates to:
  /// **'Nothing to paste from the clipboard.'**
  String get aiNothingToPaste;

  /// No description provided for @aiNoValidShifts.
  ///
  /// In en, this message translates to:
  /// **'No valid shifts detected. Make sure you used the copied AI prompt.'**
  String get aiNoValidShifts;

  /// No description provided for @aiStep1.
  ///
  /// In en, this message translates to:
  /// **'Copy the prompt'**
  String get aiStep1;

  /// No description provided for @aiCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get aiCopied;

  /// No description provided for @aiCopyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy AI Prompt'**
  String get aiCopyPrompt;

  /// No description provided for @aiStep1Sub.
  ///
  /// In en, this message translates to:
  /// **'Paste it into ChatGPT, Gemini or any AI app, then add your roster text or a photo/screenshot and send.'**
  String get aiStep1Sub;

  /// No description provided for @aiStep2.
  ///
  /// In en, this message translates to:
  /// **'Paste the AI\'s reply'**
  String get aiStep2;

  /// No description provided for @aiPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get aiPaste;

  /// No description provided for @aiParsePreview.
  ///
  /// In en, this message translates to:
  /// **'Parse & Preview'**
  String get aiParsePreview;

  /// No description provided for @aiStep3.
  ///
  /// In en, this message translates to:
  /// **'Review the detected shifts'**
  String get aiStep3;

  /// No description provided for @aiStep3Sub.
  ///
  /// In en, this message translates to:
  /// **'Tap a badge to switch it between Day, Afternoon and Night if the AI got one wrong.'**
  String get aiStep3Sub;

  /// No description provided for @aiImportDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Import 1 day} other{Import {count} days}}'**
  String aiImportDays(int count);

  /// No description provided for @aiTitleSub.
  ///
  /// In en, this message translates to:
  /// **'Turn any roster text into shifts with the help of an AI app.'**
  String get aiTitleSub;

  /// No description provided for @aiSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day} other{{count} days}} · {working} working · {off} off'**
  String aiSummaryLine(int count, int working, int off);

  /// No description provided for @draftReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review scanned roster'**
  String get draftReviewTitle;

  /// No description provided for @draftRemovedDay.
  ///
  /// In en, this message translates to:
  /// **'Removed {date}'**
  String draftRemovedDay(String date);

  /// No description provided for @draftUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get draftUndo;

  /// No description provided for @draftSavedDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Saved 1 day to your roster} other{Saved {count} days to your roster}}'**
  String draftSavedDays(int count);

  /// No description provided for @draftRosterName.
  ///
  /// In en, this message translates to:
  /// **'Roster name'**
  String get draftRosterName;

  /// No description provided for @draftScannedImage.
  ///
  /// In en, this message translates to:
  /// **'Scanned image'**
  String get draftScannedImage;

  /// No description provided for @draftScannedImageSub.
  ///
  /// In en, this message translates to:
  /// **'Tap the image to enlarge and compare'**
  String get draftScannedImageSub;

  /// No description provided for @draftImageError.
  ///
  /// In en, this message translates to:
  /// **'Could not display the scanned image.'**
  String get draftImageError;

  /// No description provided for @draftRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get draftRemove;

  /// No description provided for @draftNoEndTime.
  ///
  /// In en, this message translates to:
  /// **'Scanned without an end time — set it to enable Save.'**
  String get draftNoEndTime;

  /// No description provided for @draftTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get draftTime;

  /// No description provided for @draftSetEnd.
  ///
  /// In en, this message translates to:
  /// **'Set end'**
  String get draftSetEnd;

  /// No description provided for @draftConfirmSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Save'**
  String get draftConfirmSave;

  /// No description provided for @notifBeforeYourShift.
  ///
  /// In en, this message translates to:
  /// **'Before your {type} shift'**
  String notifBeforeYourShift(String type);

  /// No description provided for @notifActivityAt.
  ///
  /// In en, this message translates to:
  /// **'{kind} at {time}'**
  String notifActivityAt(String kind, String time);

  /// No description provided for @notifWindDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to wind down 🌙'**
  String get notifWindDownTitle;

  /// No description provided for @notifWindDownBodyTarget.
  ///
  /// In en, this message translates to:
  /// **'Ease off the screens — target bedtime is {time}.'**
  String notifWindDownBodyTarget(String time);

  /// No description provided for @notifWindDownBody.
  ///
  /// In en, this message translates to:
  /// **'Ease off the screens and start winding down for the night.'**
  String get notifWindDownBody;

  /// No description provided for @notifBedtimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Bedtime 😴'**
  String get notifBedtimeTitle;

  /// No description provided for @notifBedtimeBodyWake.
  ///
  /// In en, this message translates to:
  /// **'Head to bed for ~{hours}h before your {shift} — wake-up at {time}.'**
  String notifBedtimeBodyWake(int hours, String shift, String time);

  /// No description provided for @notifBedtimeBody.
  ///
  /// In en, this message translates to:
  /// **'Head to bed to hit your {hours}h sleep goal.'**
  String notifBedtimeBody(int hours);

  /// No description provided for @notifShiftDay.
  ///
  /// In en, this message translates to:
  /// **'day shift'**
  String get notifShiftDay;

  /// No description provided for @notifShiftAfternoon.
  ///
  /// In en, this message translates to:
  /// **'afternoon shift'**
  String get notifShiftAfternoon;

  /// No description provided for @notifShiftNight.
  ///
  /// In en, this message translates to:
  /// **'night shift'**
  String get notifShiftNight;

  /// No description provided for @notifShiftGeneric.
  ///
  /// In en, this message translates to:
  /// **'shift'**
  String get notifShiftGeneric;

  /// No description provided for @notifTrialEndsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Rostrik trial ends tomorrow'**
  String get notifTrialEndsTitle;

  /// No description provided for @notifTrialEndsBody.
  ///
  /// In en, this message translates to:
  /// **'Unlock full access to keep your shift alarms firing.'**
  String get notifTrialEndsBody;

  /// No description provided for @seedWakeUpLabel.
  ///
  /// In en, this message translates to:
  /// **'{type} wake-up'**
  String seedWakeUpLabel(String type);

  /// No description provided for @seedShiftGeneric.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get seedShiftGeneric;

  /// No description provided for @commonListAnd.
  ///
  /// In en, this message translates to:
  /// **'{items} & {last}'**
  String commonListAnd(String items, String last);

  /// No description provided for @soundClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get soundClassic;

  /// No description provided for @soundSiren.
  ///
  /// In en, this message translates to:
  /// **'Siren'**
  String get soundSiren;

  /// No description provided for @soundDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get soundDigital;

  /// No description provided for @soundChime.
  ///
  /// In en, this message translates to:
  /// **'Chime'**
  String get soundChime;

  /// No description provided for @patternFirstResponder.
  ///
  /// In en, this message translates to:
  /// **'First Responder Standard'**
  String get patternFirstResponder;

  /// No description provided for @ocrCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop to YOUR row only — not the whole team'**
  String get ocrCropTitle;

  /// No description provided for @draftNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. May roster'**
  String get draftNameHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'id',
    'it',
    'nl',
    'pl',
    'pt',
    'tr',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
