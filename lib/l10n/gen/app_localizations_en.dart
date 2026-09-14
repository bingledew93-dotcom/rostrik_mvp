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

  @override
  String get welcomeTagline => 'The smart alarm clock built for shift workers.';

  @override
  String get welcomeSubTagline =>
      'Alarms that follow your rotating roster — not just weekdays.';

  @override
  String welcomeTrialTitle(int days) {
    return '$days-day free trial';
  }

  @override
  String get welcomeTrialBody =>
      'Full access to every feature — no card needed. Just a one-time purchase after, never a subscription.';

  @override
  String get welcomeGetStarted => 'Get Started';

  @override
  String get welcomeSkip => 'Skip / Set up later';

  @override
  String get welcomeTimeFormat => 'Time format';

  @override
  String get welcomeWeekStarts => 'Week starts';

  @override
  String get common12h => '12h';

  @override
  String get common24h => '24h';

  @override
  String get commonSundayShort => 'Sun';

  @override
  String get commonMondayShort => 'Mon';

  @override
  String get rosterTypeTitle => 'Choose a roster type';

  @override
  String get rosterTypeQuestion => 'What does your roster look like?';

  @override
  String get rosterTypeDay => 'Day Shifts';

  @override
  String get rosterTypeNight => 'Night Shifts';

  @override
  String get rosterTypeRotating => 'Rotating';

  @override
  String get rosterTypeCustom => 'Custom';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonComingSoon => 'Coming soon';

  @override
  String get permsTitle => 'Permissions';

  @override
  String get permsIntro =>
      'Rostrik needs a few permissions to fire alarms reliably. You can change these later in system settings.';

  @override
  String get permsNotifications => 'Notifications';

  @override
  String get permsNotificationsSub => 'Required to show the wake-up screen.';

  @override
  String get permsExactAlarms => 'Exact Alarms';

  @override
  String get permsExactAlarmsSub =>
      'Lets alarms fire at the exact scheduled time.';

  @override
  String get permsBatteryUnrestricted => 'Battery Unrestricted';

  @override
  String get permsBatteryGrantedSub =>
      'Alarms are protected from battery optimisation.';

  @override
  String get permsBatteryDeniedSub =>
      'Some phones kill background apps. Tap to fix.';

  @override
  String get permsUnrestrictedBadge => 'Unrestricted';

  @override
  String get batteryDialogTitle => 'Keep alarms alive';

  @override
  String get batteryDialogIntro =>
      'Some phones (Samsung, Xiaomi, Oppo, Huawei) aggressively shut down background apps to save battery. If that happens to Rostrik, an alarm can be silenced before it fires.';

  @override
  String get batteryDialogMarkUnrestricted =>
      'Mark Rostrik as Unrestricted to stop this:';

  @override
  String get batteryStep1 => 'Open this app’s settings (button below).';

  @override
  String get batteryStep2 => 'Tap Battery (or \"App battery usage\").';

  @override
  String get batteryStep3 =>
      'Choose Unrestricted (not \"Optimised\" or \"Restricted\").';

  @override
  String get batteryStep4 =>
      'If you see \"Allow background activity\", switch it on too.';

  @override
  String get batteryStep5 =>
      'Turn OFF \"Pause app activity if unused\" (or \"Remove permissions if app is unused\") so Android can’t revoke alarm permissions while you’re away.';

  @override
  String get commonNotNow => 'Not now';

  @override
  String get batteryGoToSettings => 'Go to Settings';

  @override
  String get armEngineTitle => 'Arm your alarms';

  @override
  String get armEngineRosterReady => 'Your roster is ready';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · starts $date';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'We\'ll switch on $summary wake-up alarms before every matching shift.';
  }

  @override
  String get armEngineArming => 'Arming…';

  @override
  String get armEngineCta => 'Automate My Alarms';

  @override
  String get armEngineLeadTimeLabel => 'Alarm lead time';

  @override
  String get armEngineLeadTimeHelper =>
      'How early the alarm rings before a shift starts.';

  @override
  String get shiftTypeDay => 'Day';

  @override
  String get shiftTypeAfternoon => 'Afternoon';

  @override
  String get shiftTypeNight => 'Night';

  @override
  String get shiftTypeOff => 'Off';

  @override
  String get weekdaysNone => 'No days';

  @override
  String get weekdaysEveryDay => 'Every day';

  @override
  String get weekdaysWeekdays => 'Weekdays';

  @override
  String get weekdaysWeekends => 'Weekends';

  @override
  String durationMin(int m) {
    return '$m min';
  }

  @override
  String durationH(int h) {
    return '$h h';
  }

  @override
  String durationHMin(int h, int m) {
    return '$h h $m min';
  }

  @override
  String durationMinShort(int m) {
    return '${m}m';
  }

  @override
  String durationHShort(int h) {
    return '${h}h';
  }

  @override
  String durationHMinShort(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String get commonClose => 'Close';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDone => 'Done';

  @override
  String get commonNext => 'Next';

  @override
  String get walkthroughIntroTitle => 'A 60-second tour';

  @override
  String get walkthroughIntroBodyTwo =>
      'Two things that make Rostrik click. You can skip anytime.';

  @override
  String get walkthroughIntroBodyOne =>
      'The thing that makes Rostrik click. You can skip anytime.';

  @override
  String get walkthroughPaintLabel => 'Paint your roster';

  @override
  String get walkthroughPaintDetail => 'Tap the days you work — that fast.';

  @override
  String get walkthroughShakeLabel => 'Shake to dismiss';

  @override
  String get walkthroughShakeDetail =>
      'A firm shake switches off a critical alarm.';

  @override
  String get walkthroughTryEach => 'Tap Next to try each one.';

  @override
  String get walkthroughTryIt => 'Tap Next to try it.';

  @override
  String get walkthroughPaintBody =>
      'Tap the days you work. In the real builder you can add more blocks (afternoons, nights) the same way.';

  @override
  String get walkthroughPaintPrompt =>
      'Tap a day to paint a Day shift onto it.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Nice! Those $count days are a Day block. Untapped days stay Off — that easy.',
      one: 'Nice! That day is a Day block. Untapped days stay Off — that easy.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'Critical-Shift alarms need a firm, steady shake to switch off, so a half-asleep tap can’t. Give it a go — shake your phone.';

  @override
  String get walkthroughShakeSuccess => 'You’ve got it!';

  @override
  String get walkthroughShakeSuccessDetail =>
      'That’s exactly how you’ll silence a critical alarm.';

  @override
  String get walkthroughDoneTitle => 'You’re all set';

  @override
  String get walkthroughDoneBody =>
      'Build a roster anytime from Manage, and revisit this tour from Settings → Help whenever you like.';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTimeline => 'Timeline';

  @override
  String get navManage => 'Manage';

  @override
  String get navAlarms => 'Alarms';

  @override
  String get navSleep => 'Sleep';

  @override
  String get onbPatternTitle => 'Pick your rotation';

  @override
  String get purchaseTrialEnded => 'Your free trial has ended';

  @override
  String get purchaseBody =>
      'Unlock Rostrik once to keep your shift alarms firing. Your roster, alarms and settings are all safe — they resume the moment you unlock.';

  @override
  String get purchaseAlarmsWontRing => 'Until then, alarms won’t ring.';

  @override
  String get purchaseUnlock => 'Unlock full access';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'Unlock full access · $price';
  }

  @override
  String get purchaseRestore => 'Restore purchase';

  @override
  String get purchaseOneTime => 'One-time purchase. No subscription.';

  @override
  String get purchaseUnavailable =>
      'Purchases aren’t available right now. Check your connection and try again.';

  @override
  String get purchaseCheckingPrevious => 'Checking for a previous purchase…';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLegalAbout => 'LEGAL & ABOUT';

  @override
  String get settingsHelp => 'HELP';

  @override
  String get settingsHowItWorks => 'How it works';

  @override
  String get settingsReplayTourShake =>
      'Replay the quick tour — paint a roster + shake-to-dismiss';

  @override
  String get settingsReplayTour => 'Replay the quick tour — paint a roster';

  @override
  String get settingsScreenTips => 'Show screen tips';

  @override
  String get settingsScreenTipsSub =>
      'One-time hints on each screen. Turn on to see them again.';

  @override
  String get settingsFullAccess => 'FULL ACCESS';

  @override
  String get settingsFullAccessUnlocked => 'Full access unlocked';

  @override
  String get settingsThanks => 'Thanks for supporting Rostrik.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Free trial — $days days left',
      one: 'Free trial — 1 day left',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'Free trial ended';

  @override
  String get settingsUnlockPitch =>
      'Unlock once to keep your shift alarms firing when the trial ends — a one-time purchase, never a subscription.';

  @override
  String get settingsRestore => 'Restore';

  @override
  String get settingsBrandTagline => 'Alarms built outside the 9–5';

  @override
  String get settingsLeadTime => 'Lead time';

  @override
  String get settingsLeadTimeSub =>
      'Alarm fires this long before each shift starts.';

  @override
  String get settingsSnoozeDuration => 'Snooze duration';

  @override
  String get settingsSnoozeDurationSub =>
      'How far forward the Snooze button pushes a firing alarm.';

  @override
  String get settingsMinutesLabel => 'Minutes';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => 'SHIFT CYCLES';

  @override
  String get settingsShiftCyclesSub =>
      'Rosters you have generated from a pattern or template.';

  @override
  String get settingsAddShiftCycle => 'Add Shift Cycle';

  @override
  String get settingsNoRosters => 'You haven\'t generated any rosters yet.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get settingsDeleteRosterTitle => 'Delete roster?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts',
      one: '1 shift',
    );
    return 'Delete \"$label\"? This will cancel any pending alarms and remove $_temp0.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return 'Deleted \"$label\"';
  }

  @override
  String get commonActive => 'Active';

  @override
  String get commonUpcoming => 'Upcoming';

  @override
  String get commonPast => 'Past';

  @override
  String get settingsWorkHistory => 'WORK HISTORY';

  @override
  String get settingsWorkHistorySub =>
      'Review and export your completed custom shifts to verify payslips.';

  @override
  String get settingsViewWorkHistory => 'View & Export Work History';

  @override
  String get settingsPreferences => 'PREFERENCES';

  @override
  String get settingsPreferencesSub =>
      'How your schedule is displayed across the app.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSub =>
      'Dark is Rostrik’s default. Light uses a warm cream palette.';

  @override
  String get settings24h => 'Use 24-Hour Time';

  @override
  String get settings24hOn => 'Times show as 14:30';

  @override
  String get settings24hOff => 'Times show as 02:30 PM';

  @override
  String get settingsWeekStartTitle => 'Start Calendar on Monday';

  @override
  String get settingsWeekStartMon => 'Weeks begin on Monday';

  @override
  String get settingsWeekStartSun => 'Weeks begin on Sunday';

  @override
  String get settingsTimelineOpensOn => 'Timeline opens on';

  @override
  String get commonList => 'List';

  @override
  String get commonMonth => 'Month';

  @override
  String get settingsCalendar => 'CALENDAR';

  @override
  String get settingsCalendarSync => 'Sync to Google / Device Calendar';

  @override
  String get settingsCalendarSyncSub =>
      'Automatically mirror your shifts to a dedicated \"Rostrik Roster\" calendar on your phone.';

  @override
  String get settingsCalSyncOff =>
      'Calendar sync off. Upcoming \"Rostrik Roster\" events were cleared.';

  @override
  String get settingsCalSyncMirroring =>
      'Mirroring your roster to the \"Rostrik Roster\" calendar…';

  @override
  String get settingsCalPermNeeded =>
      'Calendar permission is needed to sync your roster.';

  @override
  String get settingsCalBlocked =>
      'Calendar access is blocked. Enable it in system settings to sync.';

  @override
  String get settingsCalOpenSettings => 'Settings';

  @override
  String get settingsCalUnsupported =>
      'Calendar sync isn\'t available on this device.';

  @override
  String get settingsDangerZone => 'DANGER ZONE';

  @override
  String get settingsDangerZoneSub =>
      'Deletes your roster, alarms, and settings, then restarts onboarding from scratch.';

  @override
  String get settingsResetAppData => 'Reset App Data';

  @override
  String get settingsResetTitle => 'Reset app?';

  @override
  String get settingsResetBody =>
      'Are you sure? This will delete your roster, alarms, and settings.';

  @override
  String get settingsResetConfirm => 'Reset';
}
