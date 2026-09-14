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

  @override
  String get dashNoUpcomingShifts => 'No upcoming shifts';

  @override
  String get dashEnjoyTimeOff => 'Enjoy your time off.';

  @override
  String dashHeroShift(String type) {
    return '$type shift';
  }

  @override
  String get dashInProgress => 'IN PROGRESS';

  @override
  String get dashRotation => 'Rotation';

  @override
  String get dashAlarmsCantRing => 'Alarms can\'t ring reliably';

  @override
  String get dashNotifsOffIssue =>
      'Notifications are off — a ringing alarm can\'t show its wake screen or be dismissed.';

  @override
  String get dashOpenSettings => 'Open settings';

  @override
  String get dashExactBlockedIssue =>
      'Exact alarms are blocked — wake-ups can\'t be scheduled at all.';

  @override
  String get dashAllow => 'Allow';

  @override
  String get dashSlideToSkip => 'Slide to skip this alarm';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Slide to skip all $count alarms',
      one: 'Slide to skip the alarm',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'Dismiss upcoming alarm · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Skip all $count alarms for this shift',
      one: 'Skip the alarm for this shift',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'Keep alarm';

  @override
  String get dashMyRotation => 'My Rotation';

  @override
  String get dashCalendarUpcoming => 'Calendar & upcoming shifts';

  @override
  String get dashNextShifts => 'Next shifts';

  @override
  String get dashOpenTimeline => 'Open Timeline';

  @override
  String heroStartsIn(String countdown) {
    return 'Starts in $countdown';
  }

  @override
  String heroEndsIn(String countdown) {
    return 'Ends in $countdown';
  }

  @override
  String get heroStartsInPrefix => 'Starts in';

  @override
  String get heroEndsInPrefix => 'Ends in';

  @override
  String heroStartsTodayAt(String time) {
    return 'Starts today at $time';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'Started today at $time';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'Starts tomorrow at $time';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'Started yesterday at $time';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'Starts yesterday at $time';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return 'Starts $date at $time';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return 'Started $date at $time';
  }

  @override
  String get shiftTypeDayShift => 'Day shift';

  @override
  String get shiftTypeAfternoonShift => 'Afternoon shift';

  @override
  String get shiftTypeNightShift => 'Night shift';

  @override
  String heroDayXofY(int x, int y, String label) {
    return 'Day $x of $y — $label';
  }

  @override
  String get heroOffTomorrow => 'Off tomorrow';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Off in $days days',
      one: 'Off in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'Back on tomorrow';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Back on in $days days',
      one: 'Back on in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'Off / RDO';

  @override
  String durationDayShort(int d) {
    return '${d}d';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '${d}d ${h}h';
  }

  @override
  String get alarmsTitle => 'Alarms';

  @override
  String get alarmsAddTooltip => 'Add alarm';

  @override
  String get alarmsSortTooltip => 'Sort alarms';

  @override
  String get alarmsSortByTime => 'By time';

  @override
  String get alarmsSortByShiftType => 'By shift type';

  @override
  String get alarmsEmptyTitle => 'No alarms yet.';

  @override
  String get alarmsEmptyBody => 'Tap + to add one.';

  @override
  String get alarmsNextAlarm => 'NEXT ALARM';

  @override
  String get alarmsHolidayMode => 'Holiday mode';

  @override
  String get alarmsHolidayModeSub => 'Alarms are paused — nothing will ring.';

  @override
  String get alarmsNoUpcoming => 'No upcoming shift alarm';

  @override
  String get alarmsNoUpcomingSub =>
      'Add a follows-rotation alarm, or generate a roster.';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'for your $type shift · $day';
  }

  @override
  String get commonToday => 'Today';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get alarmsOffWontRing => 'Off — won\'t ring';

  @override
  String get alarmsNoUpcomingRing => 'No upcoming ring scheduled';

  @override
  String alarmsNextRing(String day, String time) {
    return 'Next ring: $day at $time';
  }

  @override
  String get alarmsSwipeToDelete => 'Swipe to delete';

  @override
  String get alarmsRingsOnceAutoDelete => 'Rings once · auto-deletes';

  @override
  String get alarmsRingsOnce => 'Rings one time only';

  @override
  String get alarmsYourShift => 'your shift';

  @override
  String alarmsShiftsOfType(String type) {
    return '$type shifts';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'Exact time · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$lead before $shift · default';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$lead before $shift';
  }

  @override
  String get createEditAlarm => 'Edit alarm';

  @override
  String get createNewAlarm => 'New alarm';

  @override
  String get createDefaultLabel => 'Wake Up';

  @override
  String get createFallbackLabel => 'Alarm';

  @override
  String get createPickBecomesDefault =>
      'Your pick becomes the default for new alarms.';

  @override
  String get createSelectFromFiles => 'Select from Files';

  @override
  String get createFilesSub => 'Pick an audio file saved on your device';

  @override
  String get createSelectSystemTone => 'Select System Tone';

  @override
  String get createSystemToneSub => 'Choose from your device\'s alarm sounds';

  @override
  String get createAlarmTiming => 'Alarm timing';

  @override
  String get createLeadTimeMode => 'Lead time';

  @override
  String get createExactTimeMode => 'Exact time';

  @override
  String createFiresAt(String time) {
    return 'Fires at $time';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return '$lead before shift start';
  }

  @override
  String get createLinkedShift => 'Linked shift';

  @override
  String get createRepeatOn => 'Repeat on';

  @override
  String get createLabelField => 'Label';

  @override
  String get createLabelHint => 'e.g. Wake Up';

  @override
  String get createCriticalShift => 'Critical shift';

  @override
  String get createCriticalShiftSub =>
      'Shake to dismiss · 3-second hold fail-safe';

  @override
  String get createRingtone => 'Ringtone';

  @override
  String get commonStop => 'Stop';

  @override
  String get commonPlay => 'Play';

  @override
  String get createVibrate => 'Vibrate';

  @override
  String get createRepeat => 'Repeat';

  @override
  String get createRepeatRotation => 'Rotation';

  @override
  String get createRepeatWeekly => 'Weekly';

  @override
  String get createRepeatOneTime => 'One time';

  @override
  String get createPickOneDay => 'Pick at least one day';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaveChanges => 'Save changes';

  @override
  String get createTimeBeforeShift => 'Time before shift';

  @override
  String get commonOk => 'OK';

  @override
  String get sleepTitle => 'Sleep';

  @override
  String get sleepTargetHeader => 'SLEEP TARGET';

  @override
  String get sleepTargetSub =>
      'How many hours you want. Rostrik counts back from your next wake-up alarm to set tonight’s bedtime.';

  @override
  String get sleepRemindersHeader => 'REMINDERS';

  @override
  String get sleepWindDownHeader => 'WIND-DOWN LEAD';

  @override
  String get sleepWindDownSub =>
      'How long before bedtime the wind-down nudge lands.';

  @override
  String get sleepSoundsHeader => 'SLEEP SOUNDS';

  @override
  String get sleepSoundsSub =>
      'White & brown noise to drift off to. Pick an auto-stop timer and tap a sound.';

  @override
  String get sleepNothingToPlan => 'Nothing to plan tonight';

  @override
  String get sleepNothingToPlanSub =>
      'Add a shift to your roster and Rostrik will build a personalised bedtime around your next wake-up.';

  @override
  String get sleepTransitionDay => 'TRANSITION DAY';

  @override
  String get sleepTransitionTitle =>
      'Tomorrow is a Night Shift. Consider sleeping in.';

  @override
  String get sleepTransitionBody =>
      'It\'s a transition day — you have a rest day before nights, so there\'s no early alarm to chase. Bank extra rest now and let your body drift later tonight.';

  @override
  String get sleepRestRecovery => 'REST & RECOVERY';

  @override
  String get sleepNoEarlyAlarm => 'No early alarm to chase';

  @override
  String get sleepRestBody =>
      'Your next shift is more than a day away, so there\'s no wake-up to plan tonight. Sleep on your own clock and bank some recovery — Rostrik will build your bedtime plan as it draws closer.';

  @override
  String get sleepTonightsPlan => 'TONIGHT\'S PLAN';

  @override
  String get sleepTargetBedtime => 'Target bedtime';

  @override
  String get sleepWindDownStat => 'Wind-down';

  @override
  String get sleepWakeUpStat => 'Wake up';

  @override
  String get sleepDurationStat => 'Duration';

  @override
  String get sleepBedtimeReminder => 'Bedtime Reminder';

  @override
  String sleepNudgeAtBedtime(String time) {
    return 'Nudge me at $time to head to bed';
  }

  @override
  String get sleepBedtimeSub => 'A nudge when it\'s time to head to bed';

  @override
  String get sleepWindDownReminder => 'Wind-Down Reminder';

  @override
  String sleepNudgeAtWindDown(String time) {
    return 'Nudge me at $time to start winding down';
  }

  @override
  String get sleepWindDownReminderSub =>
      'An earlier heads-up to start winding down';

  @override
  String get commonOff => 'Off';

  @override
  String get sleepSoundWhiteNoise => 'White Noise';

  @override
  String get sleepSoundPinkNoise => 'Pink Noise';

  @override
  String get sleepSoundBrownNoise => 'Brown Noise';

  @override
  String get sleepSoundFan => 'Fan';

  @override
  String get sleepSoundOcean => 'Ocean';

  @override
  String get sleepSoundRain => 'Rain';

  @override
  String get manageTitle => 'Manage';

  @override
  String get manageRosterTools => 'ROSTER TOOLS';

  @override
  String get manageRosterToolsSub =>
      'Build and adjust the shifts that drive your alarms and sleep plan.';

  @override
  String get manageGenerateRotation => 'Generate Rotation';

  @override
  String get manageGenerateRotationSub =>
      'Build a repeating shift pattern from a template.';

  @override
  String get manageAddCustomShift => 'Add Custom Shift';

  @override
  String get manageAddCustomShiftSub =>
      'Drop a single one-off shift onto your roster.';

  @override
  String get manageMarkLeave => 'Mark Leave / Time Off';

  @override
  String get manageMarkLeaveSub =>
      'Paint the days you\'re off (annual leave, sick) in one go.';

  @override
  String get managePauseSchedule => 'Pause Schedule';

  @override
  String get managePausedSub =>
      'Holiday mode ON — alarms are silenced, your roster is safe.';

  @override
  String get manageNotPausedSub =>
      'Holiday mode — silence alarms while you\'re off-roster.';

  @override
  String get markLeaveTitle => 'Mark leave';

  @override
  String get markLeaveIntro =>
      'Tap the days you’re off, choose a reason, then apply. Alarms on those days won’t fire — your roster stays intact.';

  @override
  String get leaveAnnual => 'Annual Leave';

  @override
  String get leaveSick => 'Sick';

  @override
  String get leavePublicHoliday => 'Public Holiday';

  @override
  String get markLeaveReason => 'Reason';

  @override
  String get markLeaveFallbackReason => 'leave';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Marked $count shifts as $reason.',
      one: 'Marked 1 shift as $reason.',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => 'Select days to mark';

  @override
  String get markLeaveNoShifts => 'No shifts on those days';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Apply to $count shifts',
      one: 'Apply to 1 shift',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => 'Work History';

  @override
  String get workHistoryExportTooltip => 'Export History';

  @override
  String workHistoryExportFailed(String error) {
    return 'Could not export history: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts worked',
      one: '1 shift worked',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours h';
  }

  @override
  String get commonPaused => 'Paused';

  @override
  String workHistoryPausedReason(String reason) {
    return 'Paused · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'Rotation';

  @override
  String get workHistoryAdHocBadge => 'Ad-Hoc';

  @override
  String get workHistoryEmptyTitle => 'No completed shifts yet';

  @override
  String get workHistoryEmptyBody =>
      'Your worked shifts — rotation and custom alike — appear here once they finish, ready to export for payslip verification.';

  @override
  String get workHistoryShareSubject => 'Rostrik Work History';

  @override
  String get workHistoryShareText => 'My Rostrik work history export.';

  @override
  String get shiftEdAddShift => 'Add shift';

  @override
  String get shiftEdEditShift => 'Edit shift';

  @override
  String get shiftEdDate => 'Date';

  @override
  String get shiftEdPickDate => 'Pick date';

  @override
  String get shiftEdStarts => 'Starts';

  @override
  String get shiftEdEnds => 'Ends';

  @override
  String get shiftEdPickTime => 'Pick time';

  @override
  String get shiftEdEndsNextDay => 'Ends next day';

  @override
  String get shiftEdPauseTitle => 'Pause / cancel this shift';

  @override
  String get shiftEdPausedSub =>
      'Alarm won\'t fire. Stays on your calendar as a record.';

  @override
  String get shiftEdNotPausedSub =>
      'Mark a day off (sick, leave, holiday) without deleting it.';

  @override
  String get shiftEdReasonOptional => 'Reason (optional)';

  @override
  String get dayShifts => 'Shifts';

  @override
  String get dayActivities => 'Activities';

  @override
  String get dayAddAnotherShift => 'Add another shift';

  @override
  String get dayAddActivity => 'Add activity';

  @override
  String get dayAddActivitySub => 'Event, task or birthday';

  @override
  String get dayReminder => 'Reminder';

  @override
  String get actEditActivity => 'Edit activity';

  @override
  String get actLeadAtTime => 'At time';

  @override
  String get actLead10Min => '10 min before';

  @override
  String get actLead30Min => '30 min before';

  @override
  String get actLead1Hour => '1 hour before';

  @override
  String get actLead1Day => '1 day before';

  @override
  String get actEvent => 'Event';

  @override
  String get actTask => 'Task';

  @override
  String get actBirthday => 'Birthday';

  @override
  String get actTitleField => 'Title';

  @override
  String get actAllDay => 'All day';

  @override
  String get actTimeField => 'Time';

  @override
  String get actRemindMe => 'Remind me';

  @override
  String get actRemindMeSub =>
      'A gentle notification — separate from your shift alarms.';

  @override
  String get actRemindAt => 'Remind at';

  @override
  String get actReminderPassed =>
      'That time has already passed — this reminder won’t fire.';

  @override
  String get actNoteOptional => 'Note (optional)';

  @override
  String get actCompleted => 'Completed';

  @override
  String get tipDashboardTitle => 'Your dashboard';

  @override
  String get tipDashboardBody =>
      'Home base. See your next shift with a live countdown and where you are in your rotation. Tap a tile to jump straight to the details.';

  @override
  String get tipTimelineTitle => 'Your whole roster';

  @override
  String get tipTimelineBody =>
      'Switch between a List and a Month calendar up top. Tap any day to edit a shift — or add an event, task or birthday.';

  @override
  String get tipManageTitle => 'Build & adjust';

  @override
  String get tipManageBody =>
      'Create a rotating roster, add a one-off (overtime) shift, or pause your whole schedule for leave — all from here.';

  @override
  String get tipAlarmsTitle => 'Your alarms';

  @override
  String get tipAlarmsBody =>
      'Every alarm your shifts create, plus any you add yourself. Tap one to change its time or tone, or make it a shake-to-dismiss Critical Shift alarm.';

  @override
  String get tipSleepTitle => 'Sleep plan';

  @override
  String get tipSleepBody =>
      'A wind-down plan that follows your roster: set a sleep goal and get ready for your next shift feeling rested.';

  @override
  String get tipReplayHint =>
      'Replay these anytime from Settings › How it works.';

  @override
  String get tipDontShow => 'Don\'t show tips';

  @override
  String get tipGotIt => 'Got it';

  @override
  String get timelineListView => 'List View';

  @override
  String get timelineMonthView => 'Month View';

  @override
  String get shiftTypeAftShort => 'Aft';

  @override
  String get timelineNoShifts => 'No shifts scheduled. Tap + to add one.';

  @override
  String timelineNoMatch(String filter) {
    return 'No shifts match the $filter filter.';
  }

  @override
  String get timelineRestDay => 'Rest day';

  @override
  String timelineRestDayReason(String reason) {
    return 'Rest day · $reason';
  }

  @override
  String get timelineAllDay => 'All day';

  @override
  String get calLegendPausedLeave => 'Paused / Leave';

  @override
  String get calLegendActivity => 'Activity';

  @override
  String get filterAll => 'All';

  @override
  String get filterWork => 'Work';

  @override
  String get criticalHoldToDismiss => 'Or hold to dismiss';

  @override
  String get patternChoosePattern => 'Choose a pattern';

  @override
  String get patternRotatingSwings => 'Rotating Swings';

  @override
  String get patternDaySwings => 'Day Only Swings';

  @override
  String get patternNightSwings => 'Night Only Swings';

  @override
  String get patternShiftTimes => 'Shift times';

  @override
  String get patternGenerate => 'Set Day 1 & Generate';

  @override
  String get patternSelectDay1 => 'Select your Next Day 1';

  @override
  String patternDay1Hint(String label) {
    return 'First day of your $label block';
  }

  @override
  String get patternNextDay1 => 'Next Day 1';

  @override
  String get patternUseThisDate => 'Use this date';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Generated $count shifts',
      one: 'Generated 1 shift',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'Generation failed: $error';
  }

  @override
  String get patternFirstBlockFallback => 'first';

  @override
  String get patternBuildCustom => 'Build custom roster';

  @override
  String get patternBuildCustomSub =>
      'Doesn\'t fit a preset? Compose your own blocks.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Days',
      one: '1 Day',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Afternoons',
      one: '1 Afternoon',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Nights',
      one: '1 Night',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '$n Off';
  }

  @override
  String get builderNewRoster => 'New Shift Roster';

  @override
  String get builderEditRoster => 'Edit Roster';

  @override
  String get builderNewSub => 'Set up your shift rotation pattern';

  @override
  String get builderEditSub => 'Change and replace this saved roster';

  @override
  String get builderNameHint => 'Roster name (e.g. My 14-Day Rotation)';

  @override
  String get builderCycleLength => 'CYCLE LENGTH';

  @override
  String get builderStartDate => 'START DATE';

  @override
  String get builderShiftBlocks => 'SHIFT BLOCKS';

  @override
  String get builderAddShiftBlock => 'Add Shift Block';

  @override
  String get builderCreateRoster => 'Create Roster';

  @override
  String get builderSaveChanges => 'Save Changes';

  @override
  String get builderReplaceWarning =>
      'Saving replaces this roster. Any leave / time-off marks painted on it will reset.';

  @override
  String get builderBackToOptions => 'Back to options';

  @override
  String get builderOrImport => 'OR IMPORT AN EXISTING ROSTER';

  @override
  String get builderImportViaAi => 'Import via AI';

  @override
  String get builderScanning => 'Scanning…';

  @override
  String get builderScanInstead => 'Scan a roster photo instead';

  @override
  String get builderCustomChip => 'Custom';

  @override
  String get builderCycleLengthLabel => 'Cycle length';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'Pick a date';

  @override
  String get builderNoBlocksYet => 'No blocks yet';

  @override
  String get builderNoBlocksSub => 'Add shift blocks to define your rotation';

  @override
  String builderDaysLine(String ranges) {
    return 'Days $ranges';
  }

  @override
  String get builderEditBlock => 'Edit block';

  @override
  String get builderRemoveBlock => 'Remove block';

  @override
  String get builderPickRosterStart => 'Pick the roster start date';

  @override
  String get builderPickScanStart =>
      'Pick the start date for the scanned roster';

  @override
  String get builderScanCamera => 'Scan with camera';

  @override
  String get builderImportScreenshot => 'Import a screenshot';

  @override
  String builderScanFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'No shift times recognised. Try cropping tighter around the grid.';

  @override
  String get builderCustomRosterFallback => 'Custom roster';

  @override
  String get builderScannedRosterFallback => 'Scanned roster';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Roster updated — $count shifts scheduled',
      one: 'Roster updated — 1 shift scheduled',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Created — $count shifts scheduled',
      one: 'Created — 1 shift scheduled',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'Could not create the roster: $error';
  }

  @override
  String get builderRosterImported => 'Roster imported to your calendar';

  @override
  String builderCouldNotImport(String error) {
    return 'Could not import the roster: $error';
  }

  @override
  String get blockAddTitle => 'Add shift block';

  @override
  String get blockEditTitle => 'Edit shift block';

  @override
  String get blockStart => 'Start';

  @override
  String get blockEnd => 'End';

  @override
  String get blockTapDays => 'Tap the days this shift covers';

  @override
  String get blockUntappedOff => 'Un-tapped days are Off.';

  @override
  String blockOverlap(String ranges) {
    return 'This time overlaps another shift on day $ranges — change the time or those days.';
  }

  @override
  String get blockAdd => 'Add block';

  @override
  String get blockSave => 'Save block';

  @override
  String get aiPromptCopied =>
      'Prompt copied! Paste it into your AI app along with your roster.';

  @override
  String get aiNothingToPaste => 'Nothing to paste from the clipboard.';

  @override
  String get aiNoValidShifts =>
      'No valid shifts detected. Make sure you used the copied AI prompt.';

  @override
  String get aiStep1 => 'Copy the prompt';

  @override
  String get aiCopied => 'Copied!';

  @override
  String get aiCopyPrompt => 'Copy AI Prompt';

  @override
  String get aiStep1Sub =>
      'Paste it into ChatGPT, Gemini or any AI app, then add your roster text or a photo/screenshot and send.';

  @override
  String get aiStep2 => 'Paste the AI\'s reply';

  @override
  String get aiPaste => 'Paste';

  @override
  String get aiParsePreview => 'Parse & Preview';

  @override
  String get aiStep3 => 'Review the detected shifts';

  @override
  String get aiStep3Sub =>
      'Tap a badge to switch it between Day, Afternoon and Night if the AI got one wrong.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count days',
      one: 'Import 1 day',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'Turn any roster text into shifts with the help of an AI app.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0 · $working working · $off off';
  }

  @override
  String get draftReviewTitle => 'Review scanned roster';

  @override
  String draftRemovedDay(String date) {
    return 'Removed $date';
  }

  @override
  String get draftUndo => 'Undo';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved $count days to your roster',
      one: 'Saved 1 day to your roster',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'Roster name';

  @override
  String get draftScannedImage => 'Scanned image';

  @override
  String get draftScannedImageSub => 'Tap the image to enlarge and compare';

  @override
  String get draftImageError => 'Could not display the scanned image.';

  @override
  String get draftRemove => 'Remove';

  @override
  String get draftNoEndTime =>
      'Scanned without an end time — set it to enable Save.';

  @override
  String get draftTime => 'Time';

  @override
  String get draftSetEnd => 'Set end';

  @override
  String get draftConfirmSave => 'Confirm & Save';

  @override
  String notifBeforeYourShift(String type) {
    return 'Before your $type shift';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind at $time';
  }

  @override
  String get notifWindDownTitle => 'Time to wind down 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'Ease off the screens — target bedtime is $time.';
  }

  @override
  String get notifWindDownBody =>
      'Ease off the screens and start winding down for the night.';

  @override
  String get notifBedtimeTitle => 'Bedtime 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return 'Head to bed for ~${hours}h before your $shift — wake-up at $time.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return 'Head to bed to hit your ${hours}h sleep goal.';
  }

  @override
  String get notifShiftDay => 'day shift';

  @override
  String get notifShiftAfternoon => 'afternoon shift';

  @override
  String get notifShiftNight => 'night shift';

  @override
  String get notifShiftGeneric => 'shift';

  @override
  String get notifTrialEndsTitle => 'Your Rostrik trial ends tomorrow';

  @override
  String get notifTrialEndsBody =>
      'Unlock full access to keep your shift alarms firing.';

  @override
  String seedWakeUpLabel(String type) {
    return '$type wake-up';
  }

  @override
  String get seedShiftGeneric => 'Shift';

  @override
  String commonListAnd(String items, String last) {
    return '$items & $last';
  }

  @override
  String get soundClassic => 'Classic';

  @override
  String get soundSiren => 'Siren';

  @override
  String get soundDigital => 'Digital';

  @override
  String get soundChime => 'Chime';

  @override
  String get patternFirstResponder => 'First Responder Standard';

  @override
  String get ocrCropTitle => 'Crop to YOUR row only — not the whole team';

  @override
  String get draftNameHint => 'e.g. May roster';
}
