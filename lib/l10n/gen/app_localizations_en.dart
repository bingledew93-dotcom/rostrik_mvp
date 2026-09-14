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
}
