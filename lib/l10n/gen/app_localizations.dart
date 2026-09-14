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

  /// No description provided for @dashHeroShift.
  ///
  /// In en, this message translates to:
  /// **'{type} shift'**
  String dashHeroShift(String type);

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
