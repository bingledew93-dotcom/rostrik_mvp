// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'قبل أن تبدأ';

  @override
  String get legalBodyOsCaveat =>
      'صُمم Rostrik ليوقظك لكل وردية. وللأمانة: في أي هاتف، الكلمة الأخيرة لنظام التشغيل وليس للتطبيق، وفي حالات نادرة قد يؤخّر أو يُسكت أي تطبيق منبه (توفير البطارية الصارم، أو الإيقاف الإجباري، أو مباشرة بعد تحديثات النظام).';

  @override
  String get legalBodyBackupAdvice =>
      'للورديات التي لا يمكنك تفويتها أبدًا، اضبط منبهًا ثانيًا احتياطيًا. هذه عادة جيدة مع أي منبه، حتى المنبه المدمج في هاتفك.';

  @override
  String get legalReviewAndAccept => 'يُرجى المراجعة والموافقة:';

  @override
  String get legalPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get legalTermsOfUse => 'شروط الاستخدام';

  @override
  String get legalConsentCheckbox =>
      'أفهم أن نظام التشغيل قد يؤثر في أي تطبيق منبه، وأوافق على سياسة الخصوصية وشروط الاستخدام.';

  @override
  String get legalAgreeContinue => 'موافق ومتابعة';

  @override
  String get commonSaving => 'جارٍ الحفظ…';

  @override
  String get commonCouldNotOpenLink => 'تعذّر فتح الرابط.';

  @override
  String get welcomeTagline => 'المنبه الذكي لمن يعملون بنظام الورديات.';

  @override
  String get welcomeSubTagline =>
      'منبهات تتبع جدول وردياتك المتناوب، لا أيام الأسبوع فقط.';

  @override
  String welcomeTrialTitle(int days) {
    return 'تجربة مجانية لمدة $days يومًا';
  }

  @override
  String get welcomeTrialBody =>
      'وصول كامل إلى كل الميزات دون بطاقة. بعدها شراء لمرة واحدة، وليس اشتراكًا أبدًا.';

  @override
  String get welcomeGetStarted => 'ابدأ';

  @override
  String get welcomeSkip => 'تخطٍّ / الإعداد لاحقًا';

  @override
  String get welcomeTimeFormat => 'تنسيق الوقت';

  @override
  String get welcomeWeekStarts => 'بداية الأسبوع';

  @override
  String get common12h => '12 ساعة';

  @override
  String get common24h => '24 ساعة';

  @override
  String get commonSundayShort => 'أحد';

  @override
  String get commonMondayShort => 'إثنين';

  @override
  String get rosterTypeTitle => 'اختر نوع الجدول';

  @override
  String get rosterTypeQuestion => 'كيف يبدو جدول وردياتك؟';

  @override
  String get rosterTypeDay => 'ورديات نهارية';

  @override
  String get rosterTypeNight => 'ورديات ليلية';

  @override
  String get rosterTypeRotating => 'متناوبة';

  @override
  String get rosterTypeCustom => 'مخصص';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonComingSoon => 'قريبًا';

  @override
  String get permsTitle => 'الأذونات';

  @override
  String get permsIntro =>
      'يحتاج Rostrik إلى بعض الأذونات لتعمل المنبهات بموثوقية. يمكنك تغييرها لاحقًا من إعدادات النظام.';

  @override
  String get permsNotifications => 'الإشعارات';

  @override
  String get permsNotificationsSub => 'مطلوبة لعرض شاشة الاستيقاظ.';

  @override
  String get permsExactAlarms => 'المنبهات الدقيقة';

  @override
  String get permsExactAlarmsSub =>
      'تتيح للمنبهات أن ترن في الوقت المحدد تمامًا.';

  @override
  String get permsBatteryUnrestricted => 'البطارية بلا قيود';

  @override
  String get permsBatteryGrantedSub => 'المنبهات محمية من تحسين البطارية.';

  @override
  String get permsBatteryDeniedSub =>
      'بعض الهواتف تُغلق التطبيقات في الخلفية. انقر للإصلاح.';

  @override
  String get permsUnrestrictedBadge => 'بلا قيود';

  @override
  String get batteryDialogTitle => 'أبقِ المنبهات تعمل';

  @override
  String get batteryDialogIntro =>
      'بعض الهواتف (Samsung وXiaomi وOppo وHuawei) تُغلق تطبيقات الخلفية بقوة لتوفير البطارية. إذا حدث ذلك مع Rostrik، فقد لا يرن المنبه.';

  @override
  String get batteryDialogMarkUnrestricted =>
      'اضبط Rostrik على «بلا قيود» لمنع ذلك:';

  @override
  String get batteryStep1 => 'افتح إعدادات هذا التطبيق (الزر أدناه).';

  @override
  String get batteryStep2 =>
      'انقر على البطارية (أو «استخدام التطبيق للبطارية»).';

  @override
  String get batteryStep3 => 'اختر «بلا قيود» (وليس «محسَّن» أو «مقيَّد»).';

  @override
  String get batteryStep4 =>
      'إذا ظهر خيار «السماح بالنشاط في الخلفية»، ففعّله أيضًا.';

  @override
  String get batteryStep5 =>
      'أوقف «إيقاف نشاط التطبيق مؤقتًا عند عدم استخدامه» (أو «إزالة الأذونات إذا لم يُستخدم التطبيق») حتى لا يسحب Android أذونات المنبه أثناء غيابك.';

  @override
  String get commonNotNow => 'ليس الآن';

  @override
  String get batteryGoToSettings => 'الانتقال إلى الإعدادات';

  @override
  String get armEngineTitle => 'فعّل منبهاتك';

  @override
  String get armEngineRosterReady => 'جدولك جاهز';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · يبدأ $date';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'سنفعّل منبهات الاستيقاظ ($summary) قبل كل وردية مطابقة.';
  }

  @override
  String get armEngineArming => 'جارٍ التفعيل…';

  @override
  String get armEngineCta => 'أتمتة منبهاتي';

  @override
  String get armEngineLeadTimeLabel => 'وقت التنبيه المسبق';

  @override
  String get armEngineLeadTimeHelper => 'كم قبل بداية الوردية يرن المنبه.';

  @override
  String get shiftTypeDay => 'نهارية';

  @override
  String get shiftTypeAfternoon => 'مسائية';

  @override
  String get shiftTypeNight => 'ليلية';

  @override
  String get shiftTypeOff => 'راحة';

  @override
  String get weekdaysNone => 'لا أيام';

  @override
  String get weekdaysEveryDay => 'كل يوم';

  @override
  String get weekdaysWeekdays => 'أيام العمل';

  @override
  String get weekdaysWeekends => 'عطلة نهاية الأسبوع';

  @override
  String durationMin(int m) {
    return '$m د';
  }

  @override
  String durationH(int h) {
    return '$h س';
  }

  @override
  String durationHMin(int h, int m) {
    return '$h س $m د';
  }

  @override
  String durationMinShort(int m) {
    return '$m د';
  }

  @override
  String durationHShort(int h) {
    return '$h س';
  }

  @override
  String durationHMinShort(int h, int m) {
    return '$h س $m د';
  }

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonSkip => 'تخطٍّ';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonDone => 'تم';

  @override
  String get commonNext => 'التالي';

  @override
  String get walkthroughIntroTitle => 'جولة في 60 ثانية';

  @override
  String get walkthroughIntroBodyTwo =>
      'أمران يجعلان Rostrik مفيدًا. يمكنك التخطي في أي وقت.';

  @override
  String get walkthroughIntroBodyOne =>
      'ما يجعل Rostrik مفيدًا. يمكنك التخطي في أي وقت.';

  @override
  String get walkthroughPaintLabel => 'لوّن جدولك';

  @override
  String get walkthroughPaintDetail => 'انقر على أيام عملك، بهذه السرعة.';

  @override
  String get walkthroughShakeLabel => 'هزّ للإيقاف';

  @override
  String get walkthroughShakeDetail => 'هزّة قوية تُوقف المنبه الحرج.';

  @override
  String get walkthroughTryEach => 'انقر على التالي لتجربة كل منهما.';

  @override
  String get walkthroughTryIt => 'انقر على التالي للتجربة.';

  @override
  String get walkthroughPaintBody =>
      'انقر على أيام عملك. في المحرر الفعلي تضيف كتلًا أخرى (مسائية، ليلية) بالطريقة نفسها.';

  @override
  String get walkthroughPaintPrompt => 'انقر على يوم لتلوينه بوردية نهارية.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'رائع! هذه الأيام الـ$count أصبحت كتلة نهارية. الأيام التي لم تنقر عليها تبقى راحة. بهذه السهولة.',
      many:
          'رائع! هذه الأيام الـ$count أصبحت كتلة نهارية. الأيام التي لم تنقر عليها تبقى راحة. بهذه السهولة.',
      few:
          'رائع! هذه الأيام الـ$count أصبحت كتلة نهارية. الأيام التي لم تنقر عليها تبقى راحة. بهذه السهولة.',
      two:
          'رائع! هذان اليومان أصبحا كتلة نهارية. الأيام التي لم تنقر عليها تبقى راحة. بهذه السهولة.',
      one:
          'رائع! هذا اليوم أصبح كتلة نهارية. الأيام التي لم تنقر عليها تبقى راحة. بهذه السهولة.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'منبهات الورديات الحرجة لا تتوقف إلا بهزّ قوي ومتواصل، حتى لا تكفي نقرة وأنت نصف نائم. جرّب: هزّ هاتفك.';

  @override
  String get walkthroughShakeSuccess => 'أحسنت!';

  @override
  String get walkthroughShakeSuccessDetail =>
      'هكذا بالضبط ستُسكت المنبه الحرج.';

  @override
  String get walkthroughDoneTitle => 'كل شيء جاهز';

  @override
  String get walkthroughDoneBody =>
      'أنشئ جدولًا في أي وقت من «إدارة»، وأعد مشاهدة هذه الجولة من الإعدادات ← المساعدة.';

  @override
  String get navDashboard => 'الرئيسية';

  @override
  String get navTimeline => 'الجدول';

  @override
  String get navManage => 'إدارة';

  @override
  String get navAlarms => 'المنبهات';

  @override
  String get navSleep => 'النوم';

  @override
  String get onbPatternTitle => 'اختر نمط التناوب';

  @override
  String get purchaseTrialEnded => 'انتهت تجربتك المجانية';

  @override
  String get purchaseBody =>
      'افتح Rostrik مرة واحدة لتستمر منبهات وردياتك في الرنين. جدولك ومنبهاتك وإعداداتك محفوظة بأمان وتعود فور فتح القفل.';

  @override
  String get purchaseAlarmsWontRing => 'حتى ذلك الحين، لن ترن المنبهات.';

  @override
  String get purchaseUnlock => 'فتح الوصول الكامل';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'فتح الوصول الكامل · $price';
  }

  @override
  String get purchaseRestore => 'استعادة الشراء';

  @override
  String get purchaseOneTime => 'شراء لمرة واحدة. بلا اشتراك.';

  @override
  String get purchaseUnavailable =>
      'الشراء غير متاح حاليًا. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get purchaseCheckingPrevious => 'جارٍ البحث عن عملية شراء سابقة…';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLegalAbout => 'المعلومات القانونية وحول التطبيق';

  @override
  String get settingsHelp => 'المساعدة';

  @override
  String get settingsHowItWorks => 'طريقة العمل';

  @override
  String get settingsReplayTourShake =>
      'إعادة الجولة السريعة: تلوين الجدول + الهزّ للإيقاف';

  @override
  String get settingsReplayTour => 'إعادة الجولة السريعة: تلوين الجدول';

  @override
  String get settingsScreenTips => 'عرض تلميحات الشاشة';

  @override
  String get settingsScreenTipsSub =>
      'تلميحات تظهر مرة واحدة في كل شاشة. فعّلها لرؤيتها مجددًا.';

  @override
  String get settingsFullAccess => 'الوصول الكامل';

  @override
  String get settingsFullAccessUnlocked => 'تم فتح الوصول الكامل';

  @override
  String get settingsThanks => 'شكرًا لدعمك Rostrik.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'التجربة المجانية: بقي $days يوم',
      many: 'التجربة المجانية: بقي $days يومًا',
      few: 'التجربة المجانية: بقيت $days أيام',
      two: 'التجربة المجانية: بقي يومان',
      one: 'التجربة المجانية: بقي يوم واحد',
      zero: 'التجربة المجانية: ينتهي اليوم',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'انتهت التجربة المجانية';

  @override
  String get settingsUnlockPitch =>
      'افتح القفل مرة واحدة لتستمر منبهات وردياتك بعد انتهاء التجربة، شراء لمرة واحدة وليس اشتراكًا أبدًا.';

  @override
  String get settingsRestore => 'استعادة';

  @override
  String get settingsBrandTagline => 'منبهات لمن يعمل خارج ساعات الدوام';

  @override
  String get settingsLeadTime => 'التنبيه المسبق';

  @override
  String get settingsLeadTimeSub => 'يرن المنبه قبل بداية كل وردية بهذه المدة.';

  @override
  String get settingsSnoozeDuration => 'مدة الغفوة';

  @override
  String get settingsSnoozeDurationSub =>
      'المدة التي يؤجل بها زر الغفوة المنبه الذي يرن.';

  @override
  String get settingsMinutesLabel => 'الدقائق';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m دقيقة',
      many: '$m دقيقة',
      few: '$m دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '$m دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => 'دورات الورديات';

  @override
  String get settingsShiftCyclesSub => 'جداول أنشأتها من نمط أو قالب.';

  @override
  String get settingsAddShiftCycle => 'إضافة دورة ورديات';

  @override
  String get settingsNoRosters => 'لم تُنشئ أي جدول بعد.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get settingsDeleteRosterTitle => 'حذف الجدول؟';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وردية',
      many: '$count وردية',
      few: '$count ورديات',
      two: 'ورديتان',
      one: 'وردية واحدة',
      zero: '$count وردية',
    );
    return 'هل تريد حذف «$label»؟ سيُلغى أي منبه معلّق وسيُحذف $_temp0.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return 'تم حذف «$label»';
  }

  @override
  String get commonActive => 'نشط';

  @override
  String get commonUpcoming => 'قادم';

  @override
  String get commonPast => 'سابق';

  @override
  String get settingsWorkHistory => 'سجل العمل';

  @override
  String get settingsWorkHistorySub =>
      'راجع وصدّر وردياتك المخصصة المكتملة للتحقق من كشوف الرواتب.';

  @override
  String get settingsViewWorkHistory => 'عرض سجل العمل وتصديره';

  @override
  String get settingsPreferences => 'التفضيلات';

  @override
  String get settingsPreferencesSub => 'طريقة عرض جدولك في التطبيق.';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsThemeSystem => 'النظام';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeSub =>
      'الداكن هو المظهر الافتراضي لـ Rostrik. الفاتح يستخدم ألوانًا كريمية دافئة.';

  @override
  String get settings24h => 'استخدام نظام 24 ساعة';

  @override
  String get settings24hOn => 'تظهر الأوقات بالشكل 14:30';

  @override
  String get settings24hOff => 'تظهر الأوقات بالشكل 02:30 PM';

  @override
  String get settingsWeekStartTitle => 'بدء التقويم يوم الإثنين';

  @override
  String get settingsWeekStartMon => 'يبدأ الأسبوع يوم الإثنين';

  @override
  String get settingsWeekStartSun => 'يبدأ الأسبوع يوم الأحد';

  @override
  String get settingsTimelineOpensOn => 'يفتح الجدول على';

  @override
  String get commonList => 'قائمة';

  @override
  String get commonMonth => 'شهر';

  @override
  String get settingsCalendar => 'التقويم';

  @override
  String get settingsCalendarSync => 'المزامنة مع Google / تقويم الجهاز';

  @override
  String get settingsCalendarSyncSub =>
      'انسخ وردياتك تلقائيًا إلى تقويم مخصص باسم «Rostrik Roster» على هاتفك.';

  @override
  String get settingsCalSyncOff =>
      'أُوقفت مزامنة التقويم. حُذفت أحداث «Rostrik Roster» القادمة.';

  @override
  String get settingsCalSyncMirroring =>
      'جارٍ نسخ جدولك إلى تقويم «Rostrik Roster»…';

  @override
  String get settingsCalPermNeeded => 'يلزم إذن التقويم لمزامنة جدولك.';

  @override
  String get settingsCalBlocked =>
      'الوصول إلى التقويم محظور. فعّله من إعدادات النظام للمزامنة.';

  @override
  String get settingsCalOpenSettings => 'الإعدادات';

  @override
  String get settingsCalUnsupported =>
      'مزامنة التقويم غير متاحة على هذا الجهاز.';

  @override
  String get settingsDangerZone => 'منطقة الخطر';

  @override
  String get settingsDangerZoneSub =>
      'يحذف جدولك ومنبهاتك وإعداداتك، ثم يعيد الإعداد من البداية.';

  @override
  String get settingsResetAppData => 'إعادة تعيين بيانات التطبيق';

  @override
  String get settingsResetTitle => 'إعادة تعيين التطبيق؟';

  @override
  String get settingsResetBody =>
      'هل أنت متأكد؟ سيُحذف جدولك ومنبهاتك وإعداداتك.';

  @override
  String get settingsResetConfirm => 'إعادة تعيين';

  @override
  String get dashNoUpcomingShifts => 'لا ورديات قادمة';

  @override
  String get dashEnjoyTimeOff => 'استمتع بوقت راحتك.';

  @override
  String get dashInProgress => 'جارية الآن';

  @override
  String get dashRotation => 'التناوب';

  @override
  String get dashAlarmsCantRing => 'لا يمكن للمنبهات أن ترن بموثوقية';

  @override
  String get dashNotifsOffIssue =>
      'الإشعارات متوقفة: لا يستطيع المنبه عرض شاشة الاستيقاظ أو إيقافه.';

  @override
  String get dashOpenSettings => 'فتح الإعدادات';

  @override
  String get dashExactBlockedIssue =>
      'المنبهات الدقيقة محظورة: لا يمكن جدولة أي منبه.';

  @override
  String get dashAlarmsWontTakeOverScreen => 'لن تستحوذ المنبهات على الشاشة';

  @override
  String get dashFullScreenBlockedIssue =>
      'منبهات ملء الشاشة معطّلة: عندما يكون الهاتف مقفلاً سيظهر إشعار بدلاً من شاشة المنبه.';

  @override
  String get dashAllow => 'سماح';

  @override
  String get dashSlideToSkip => 'اسحب لتخطي هذا المنبه';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اسحب لتخطي $count منبه',
      many: 'اسحب لتخطي $count منبهًا',
      few: 'اسحب لتخطي $count منبهات',
      two: 'اسحب لتخطي المنبهَين',
      one: 'اسحب لتخطي المنبه',
      zero: 'اسحب لتخطي المنبهات',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'إيقاف المنبه القادم · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تخطي $count منبه لهذه الوردية',
      many: 'تخطي $count منبهًا لهذه الوردية',
      few: 'تخطي $count منبهات لهذه الوردية',
      two: 'تخطي منبهَي هذه الوردية',
      one: 'تخطي منبه هذه الوردية',
      zero: 'تخطي منبهات هذه الوردية',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'إبقاء المنبه';

  @override
  String get dashMyRotation => 'تناوبي';

  @override
  String get dashCalendarUpcoming => 'التقويم والورديات القادمة';

  @override
  String get dashNextShifts => 'الورديات التالية';

  @override
  String get dashOpenTimeline => 'فتح الجدول';

  @override
  String heroStartsIn(String countdown) {
    return 'تبدأ بعد $countdown';
  }

  @override
  String heroEndsIn(String countdown) {
    return 'تنتهي بعد $countdown';
  }

  @override
  String get heroStartsInPrefix => 'تبدأ بعد';

  @override
  String get heroEndsInPrefix => 'تنتهي بعد';

  @override
  String heroStartsTodayAt(String time) {
    return 'تبدأ اليوم الساعة $time';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'بدأت اليوم الساعة $time';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'تبدأ غدًا الساعة $time';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'بدأت أمس الساعة $time';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'تبدأ أمس الساعة $time';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return 'تبدأ $date الساعة $time';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return 'بدأت $date الساعة $time';
  }

  @override
  String get shiftTypeDayShift => 'وردية نهارية';

  @override
  String get shiftTypeAfternoonShift => 'وردية مسائية';

  @override
  String get shiftTypeNightShift => 'وردية ليلية';

  @override
  String heroDayXofY(int x, int y, String label) {
    return 'اليوم $x من $y – $label';
  }

  @override
  String get heroOffTomorrow => 'راحة غدًا';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'راحة بعد $days يوم',
      many: 'راحة بعد $days يومًا',
      few: 'راحة بعد $days أيام',
      two: 'راحة بعد يومين',
      one: 'راحة بعد يوم واحد',
      zero: 'راحة اليوم',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'العودة إلى العمل غدًا';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'العودة إلى العمل بعد $days يوم',
      many: 'العودة إلى العمل بعد $days يومًا',
      few: 'العودة إلى العمل بعد $days أيام',
      two: 'العودة إلى العمل بعد يومين',
      one: 'العودة إلى العمل بعد يوم واحد',
      zero: 'العودة إلى العمل اليوم',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'راحة';

  @override
  String durationDayShort(int d) {
    return '$d ي';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d ي $h س';
  }

  @override
  String get alarmsTitle => 'المنبهات';

  @override
  String get alarmsAddTooltip => 'إضافة منبه';

  @override
  String get alarmsSortTooltip => 'ترتيب المنبهات';

  @override
  String get alarmsSortByTime => 'حسب الوقت';

  @override
  String get alarmsSortByShiftType => 'حسب نوع الوردية';

  @override
  String get alarmsEmptyTitle => 'لا منبهات بعد.';

  @override
  String get alarmsEmptyBody => 'انقر على + للإضافة.';

  @override
  String get alarmsNextAlarm => 'المنبه التالي';

  @override
  String get alarmsHolidayMode => 'وضع الإجازة';

  @override
  String get alarmsHolidayModeSub => 'المنبهات متوقفة مؤقتًا: لن يرن شيء.';

  @override
  String get alarmsNoUpcoming => 'لا منبه وردية قادم';

  @override
  String get alarmsNoUpcomingSub => 'أضف منبهًا يتبع التناوب، أو أنشئ جدولًا.';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'لورديتك ($type) · $day';
  }

  @override
  String get commonToday => 'اليوم';

  @override
  String get commonTomorrow => 'غدًا';

  @override
  String get alarmsOffWontRing => 'متوقف: لن يرن';

  @override
  String get alarmsNoUpcomingRing => 'لا رنين مجدول';

  @override
  String alarmsNextRing(String day, String time) {
    return 'الرنين التالي: $day الساعة $time';
  }

  @override
  String get alarmsSwipeToDelete => 'اسحب للحذف';

  @override
  String get alarmsRingsOnceAutoDelete => 'يرن مرة واحدة · يُحذف تلقائيًا';

  @override
  String get alarmsRingsOnce => 'يرن مرة واحدة فقط';

  @override
  String get alarmsYourShift => 'ورديتك';

  @override
  String alarmsShiftsOfType(String type) {
    return 'الورديات ($type)';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'وقت محدد · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$lead قبل $shift · افتراضي';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$lead قبل $shift';
  }

  @override
  String get createEditAlarm => 'تعديل المنبه';

  @override
  String get createNewAlarm => 'منبه جديد';

  @override
  String get createDefaultLabel => 'استيقاظ';

  @override
  String get createFallbackLabel => 'منبه';

  @override
  String get createPickBecomesDefault =>
      'يصبح اختيارك الافتراضي للمنبهات الجديدة.';

  @override
  String get createSelectFromFiles => 'اختيار من الملفات';

  @override
  String get createFilesSub => 'اختر ملفًا صوتيًا محفوظًا على جهازك';

  @override
  String get createSelectSystemTone => 'اختيار نغمة النظام';

  @override
  String get createSystemToneSub => 'اختر من أصوات المنبه في جهازك';

  @override
  String get createAlarmTiming => 'توقيت المنبه';

  @override
  String get createLeadTimeMode => 'تنبيه مسبق';

  @override
  String get createExactTimeMode => 'وقت محدد';

  @override
  String createFiresAt(String time) {
    return 'يرن الساعة $time';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return '$lead قبل بداية الوردية';
  }

  @override
  String get createLinkedShift => 'الوردية المرتبطة';

  @override
  String get createRepeatOn => 'التكرار في';

  @override
  String get createLabelField => 'التسمية';

  @override
  String get createLabelHint => 'مثل: استيقاظ';

  @override
  String get createCriticalShift => 'وردية حرجة';

  @override
  String get createCriticalShiftSub =>
      'هزّ للإيقاف · اضغط مطولًا 3 ثوانٍ كحل احتياطي';

  @override
  String get createRingtone => 'النغمة';

  @override
  String get commonStop => 'إيقاف';

  @override
  String get commonPlay => 'تشغيل';

  @override
  String get createVibrate => 'اهتزاز';

  @override
  String get createRepeat => 'التكرار';

  @override
  String get createRepeatRotation => 'تناوب';

  @override
  String get createRepeatWeekly => 'أسبوعي';

  @override
  String get createRepeatOneTime => 'مرة واحدة';

  @override
  String get createPickOneDay => 'اختر يومًا واحدًا على الأقل';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonSaveChanges => 'حفظ التغييرات';

  @override
  String get createTimeBeforeShift => 'الوقت قبل الوردية';

  @override
  String get commonOk => 'حسنًا';

  @override
  String get sleepTitle => 'النوم';

  @override
  String get sleepTargetHeader => 'هدف النوم';

  @override
  String get sleepTargetSub =>
      'عدد ساعات النوم التي تريدها. يعدّ Rostrik تنازليًا من منبهك التالي لتحديد موعد نومك الليلة.';

  @override
  String get sleepRemindersHeader => 'التذكيرات';

  @override
  String get sleepWindDownHeader => 'وقت الاسترخاء المسبق';

  @override
  String get sleepWindDownSub => 'كم قبل موعد النوم يصلك تذكير الاسترخاء.';

  @override
  String get sleepSoundsHeader => 'أصوات النوم';

  @override
  String get sleepSoundsSub =>
      'ضوضاء بيضاء وبنية تساعدك على النوم. اختر مؤقت إيقاف ثم انقر على صوت.';

  @override
  String get sleepNothingToPlan => 'لا شيء للتخطيط الليلة';

  @override
  String get sleepNothingToPlanSub =>
      'أضف وردية إلى جدولك وسيحدد Rostrik موعد نوم مناسبًا لاستيقاظك التالي.';

  @override
  String get sleepTransitionDay => 'يوم انتقالي';

  @override
  String get sleepTransitionTitle =>
      'غدًا وردية ليلية. يمكنك النوم لوقت متأخر.';

  @override
  String get sleepTransitionBody =>
      'إنه يوم انتقالي: لديك راحة قبل الليالي، فلا منبه مبكر. خزّن مزيدًا من الراحة الآن ودع جسمك يسهر أكثر الليلة.';

  @override
  String get sleepRestRecovery => 'الراحة والتعافي';

  @override
  String get sleepNoEarlyAlarm => 'لا منبه مبكر';

  @override
  String get sleepRestBody =>
      'ورديتك التالية بعد أكثر من يوم، لذا لا استيقاظ للتخطيط الليلة. نم على راحتك واستعد نشاطك، وسيُعدّ Rostrik خطة نومك مع اقتراب الوردية.';

  @override
  String get sleepTonightsPlan => 'خطة الليلة';

  @override
  String get sleepTargetBedtime => 'موعد النوم المستهدف';

  @override
  String get sleepWindDownStat => 'الاسترخاء';

  @override
  String get sleepWakeUpStat => 'الاستيقاظ';

  @override
  String get sleepDurationStat => 'المدة';

  @override
  String get sleepBedtimeReminder => 'تذكير موعد النوم';

  @override
  String sleepNudgeAtBedtime(String time) {
    return 'ذكّرني الساعة $time بالذهاب إلى السرير';
  }

  @override
  String get sleepBedtimeSub => 'تذكير عندما يحين وقت النوم';

  @override
  String get sleepWindDownReminder => 'تذكير الاسترخاء';

  @override
  String sleepNudgeAtWindDown(String time) {
    return 'ذكّرني الساعة $time ببدء الاسترخاء';
  }

  @override
  String get sleepWindDownReminderSub => 'تذكير مبكر لبدء الاسترخاء';

  @override
  String get commonOff => 'إيقاف';

  @override
  String get sleepSoundWhiteNoise => 'ضوضاء بيضاء';

  @override
  String get sleepSoundPinkNoise => 'ضوضاء وردية';

  @override
  String get sleepSoundBrownNoise => 'ضوضاء بنية';

  @override
  String get sleepSoundFan => 'مروحة';

  @override
  String get sleepSoundOcean => 'محيط';

  @override
  String get sleepSoundRain => 'مطر';

  @override
  String get manageTitle => 'إدارة';

  @override
  String get manageRosterTools => 'أدوات الجدول';

  @override
  String get manageRosterToolsSub =>
      'أنشئ وعدّل الورديات التي تتحكم في منبهاتك وخطة نومك.';

  @override
  String get manageGenerateRotation => 'إنشاء تناوب';

  @override
  String get manageGenerateRotationSub => 'أنشئ نمط ورديات متكررًا من قالب.';

  @override
  String get manageAddCustomShift => 'إضافة وردية منفردة';

  @override
  String get manageAddCustomShiftSub => 'أضف وردية واحدة منفصلة إلى جدولك.';

  @override
  String get manageMarkLeave => 'تحديد إجازة / أيام راحة';

  @override
  String get manageMarkLeaveSub =>
      'لوّن أيام غيابك (إجازة سنوية، مرضية) دفعة واحدة.';

  @override
  String get managePauseSchedule => 'إيقاف الجدول مؤقتًا';

  @override
  String get managePausedSub =>
      'وضع الإجازة مفعّل: المنبهات صامتة وجدولك محفوظ.';

  @override
  String get manageNotPausedSub =>
      'وضع الإجازة: أسكت المنبهات وأنت خارج الجدول.';

  @override
  String get markLeaveTitle => 'تحديد إجازة';

  @override
  String get markLeaveIntro =>
      'انقر على أيام غيابك واختر سببًا ثم طبّق. لن ترن المنبهات في تلك الأيام ويبقى جدولك كما هو.';

  @override
  String get leaveAnnual => 'إجازة سنوية';

  @override
  String get leaveSick => 'إجازة مرضية';

  @override
  String get leavePublicHoliday => 'عطلة رسمية';

  @override
  String get markLeaveReason => 'السبب';

  @override
  String get markLeaveFallbackReason => 'إجازة';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حُددت $count وردية كـ$reason.',
      many: 'حُددت $count وردية كـ$reason.',
      few: 'حُددت $count ورديات كـ$reason.',
      two: 'حُددت ورديتان كـ$reason.',
      one: 'حُددت وردية واحدة كـ$reason.',
      zero: 'لم تُحدَّد أي وردية.',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => 'اختر الأيام لتحديدها';

  @override
  String get markLeaveNoShifts => 'لا ورديات في تلك الأيام';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تطبيق على $count وردية',
      many: 'تطبيق على $count وردية',
      few: 'تطبيق على $count ورديات',
      two: 'تطبيق على ورديتين',
      one: 'تطبيق على وردية واحدة',
      zero: 'تطبيق',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => 'سجل العمل';

  @override
  String get workHistoryExportTooltip => 'تصدير السجل';

  @override
  String workHistoryExportFailed(String error) {
    return 'تعذّر تصدير السجل: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وردية مُنجزة',
      many: '$count وردية مُنجزة',
      few: '$count ورديات مُنجزة',
      two: 'ورديتان مُنجزتان',
      one: 'وردية واحدة مُنجزة',
      zero: 'لا ورديات مُنجزة',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours س';
  }

  @override
  String get commonPaused => 'متوقفة مؤقتًا';

  @override
  String workHistoryPausedReason(String reason) {
    return 'متوقفة مؤقتًا · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'تناوب';

  @override
  String get workHistoryAdHocBadge => 'إضافية';

  @override
  String get workHistoryEmptyTitle => 'لا ورديات مكتملة بعد';

  @override
  String get workHistoryEmptyBody =>
      'ستظهر هنا الورديات التي عملتها، سواء من التناوب أو المخصصة، بعد انتهائها، جاهزة للتصدير للتحقق من كشف الراتب.';

  @override
  String get workHistoryShareSubject => 'سجل العمل في Rostrik';

  @override
  String get workHistoryShareText => 'سجل عملي المُصدَّر من Rostrik.';

  @override
  String get shiftEdAddShift => 'إضافة وردية';

  @override
  String get shiftEdEditShift => 'تعديل الوردية';

  @override
  String get shiftEdDate => 'التاريخ';

  @override
  String get shiftEdPickDate => 'اختيار التاريخ';

  @override
  String get shiftEdStarts => 'تبدأ';

  @override
  String get shiftEdEnds => 'تنتهي';

  @override
  String get shiftEdPickTime => 'اختيار الوقت';

  @override
  String get shiftEdEndsNextDay => 'تنتهي في اليوم التالي';

  @override
  String get shiftEdPauseTitle => 'إيقاف / إلغاء هذه الوردية';

  @override
  String get shiftEdPausedSub => 'لن يرن المنبه. تبقى الوردية في التقويم كسجل.';

  @override
  String get shiftEdNotPausedSub =>
      'حدّد يوم راحة (مرض، إجازة، عطلة) دون حذفه.';

  @override
  String get shiftEdReasonOptional => 'السبب (اختياري)';

  @override
  String get dayShifts => 'الورديات';

  @override
  String get dayActivities => 'الأنشطة';

  @override
  String get dayAddAnotherShift => 'إضافة وردية أخرى';

  @override
  String get dayAddActivity => 'إضافة نشاط';

  @override
  String get dayAddActivitySub => 'حدث أو مهمة أو عيد ميلاد';

  @override
  String get dayReminder => 'تذكير';

  @override
  String get actEditActivity => 'تعديل النشاط';

  @override
  String get actLeadAtTime => 'في الموعد';

  @override
  String get actLead10Min => 'قبل 10 دقائق';

  @override
  String get actLead30Min => 'قبل 30 دقيقة';

  @override
  String get actLead1Hour => 'قبل ساعة';

  @override
  String get actLead1Day => 'قبل يوم';

  @override
  String get actEvent => 'حدث';

  @override
  String get actTask => 'مهمة';

  @override
  String get actBirthday => 'عيد ميلاد';

  @override
  String get actTitleField => 'العنوان';

  @override
  String get actAllDay => 'طوال اليوم';

  @override
  String get actTimeField => 'الوقت';

  @override
  String get actRemindMe => 'ذكّرني';

  @override
  String get actRemindMeSub => 'إشعار لطيف منفصل عن منبهات وردياتك.';

  @override
  String get actRemindAt => 'التذكير الساعة';

  @override
  String get actReminderPassed => 'هذا الوقت مضى بالفعل: لن يظهر هذا التذكير.';

  @override
  String get actNoteOptional => 'ملاحظة (اختياري)';

  @override
  String get actCompleted => 'مكتملة';

  @override
  String get tipDashboardTitle => 'لوحتك الرئيسية';

  @override
  String get tipDashboardBody =>
      'مركزك الأساسي. شاهد ورديتك التالية مع عدّ تنازلي مباشر وموقعك في التناوب. انقر على أي مربع لعرض التفاصيل.';

  @override
  String get tipTimelineTitle => 'جدولك بالكامل';

  @override
  String get tipTimelineBody =>
      'بدّل في الأعلى بين القائمة والتقويم الشهري. انقر على أي يوم لتعديل وردية، أو لإضافة حدث أو مهمة أو عيد ميلاد.';

  @override
  String get tipManageTitle => 'أنشئ وعدّل';

  @override
  String get tipManageBody =>
      'أنشئ جدولًا متناوبًا، أو أضف وردية منفردة (عمل إضافي)، أو أوقف جدولك كله مؤقتًا في الإجازة، كل ذلك من هنا.';

  @override
  String get tipAlarmsTitle => 'منبهاتك';

  @override
  String get tipAlarmsBody =>
      'كل المنبهات التي تنشئها وردياتك، إضافة إلى ما تضيفه بنفسك. انقر على أي منبه لتغيير وقته أو نغمته، أو اجعله منبه وردية حرجة يتوقف بالهزّ.';

  @override
  String get tipSleepTitle => 'خطة النوم';

  @override
  String get tipSleepBody =>
      'خطة استرخاء تتبع جدولك: حدّد هدف نوم واستعد لورديتك التالية وأنت مرتاح.';

  @override
  String get tipReplayHint =>
      'أعد مشاهدتها في أي وقت من الإعدادات › طريقة العمل.';

  @override
  String get tipDontShow => 'عدم عرض التلميحات';

  @override
  String get tipGotIt => 'فهمت';

  @override
  String get timelineListView => 'قائمة';

  @override
  String get timelineMonthView => 'شهر';

  @override
  String get shiftTypeAftShort => 'مسائية';

  @override
  String get timelineNoShifts => 'لا ورديات مجدولة. انقر على + للإضافة.';

  @override
  String timelineNoMatch(String filter) {
    return 'لا ورديات تطابق عامل التصفية «$filter».';
  }

  @override
  String get timelineRestDay => 'يوم راحة';

  @override
  String timelineRestDayReason(String reason) {
    return 'يوم راحة · $reason';
  }

  @override
  String get timelineAllDay => 'طوال اليوم';

  @override
  String get calLegendPausedLeave => 'متوقفة / إجازة';

  @override
  String get calLegendActivity => 'نشاط';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterWork => 'عمل';

  @override
  String get criticalHoldToDismiss => 'أو اضغط مطولًا للإيقاف';

  @override
  String get patternChoosePattern => 'اختر نمطًا';

  @override
  String get patternRotatingSwings => 'أنماط متناوبة';

  @override
  String get patternDaySwings => 'نهارية فقط';

  @override
  String get patternNightSwings => 'ليلية فقط';

  @override
  String get patternShiftTimes => 'أوقات الورديات';

  @override
  String get patternGenerate => 'حدد اليوم 1 وأنشئ';

  @override
  String get patternSelectDay1 => 'اختر يومك الأول القادم';

  @override
  String patternDay1Hint(String label) {
    return 'أول يوم في كتلة ($label)';
  }

  @override
  String get patternNextDay1 => 'اليوم الأول القادم';

  @override
  String get patternUseThisDate => 'استخدام هذا التاريخ';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُنشئت $count وردية',
      many: 'أُنشئت $count وردية',
      few: 'أُنشئت $count ورديات',
      two: 'أُنشئت ورديتان',
      one: 'أُنشئت وردية واحدة',
      zero: 'لم تُنشأ ورديات',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'تعذّر الإنشاء: $error';
  }

  @override
  String get patternFirstBlockFallback => 'الأولى';

  @override
  String get patternBuildCustom => 'إنشاء جدول مخصص';

  @override
  String get patternBuildCustomSub => 'لا يناسبك أي قالب؟ كوّن كتلك بنفسك.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يوم نهاري',
      many: '$n يومًا نهاريًا',
      few: '$n أيام نهارية',
      two: 'يومان نهاريان',
      one: 'يوم نهاري',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يوم مسائي',
      many: '$n يومًا مسائيًا',
      few: '$n أيام مسائية',
      two: 'يومان مسائيان',
      one: 'يوم مسائي',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ليلة',
      many: '$n ليلة',
      few: '$n ليالٍ',
      two: 'ليلتان',
      one: 'ليلة واحدة',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return 'راحة $n';
  }

  @override
  String get builderNewRoster => 'جدول ورديات جديد';

  @override
  String get builderEditRoster => 'تعديل الجدول';

  @override
  String get builderNewSub => 'اضبط نمط تناوب وردياتك';

  @override
  String get builderEditSub => 'عدّل هذا الجدول المحفوظ واستبدله';

  @override
  String get builderNameHint => 'اسم الجدول (مثل: تناوبي كل 14 يومًا)';

  @override
  String get builderCycleLength => 'طول الدورة';

  @override
  String get builderStartDate => 'تاريخ البدء';

  @override
  String get builderShiftBlocks => 'كتل الورديات';

  @override
  String get builderAddShiftBlock => 'إضافة كتلة ورديات';

  @override
  String get builderCreateRoster => 'إنشاء الجدول';

  @override
  String get builderSaveChanges => 'حفظ التغييرات';

  @override
  String get builderReplaceWarning =>
      'الحفظ يستبدل هذا الجدول. ستُعاد تعيين علامات الإجازة وأيام الراحة الملونة عليه.';

  @override
  String get builderBackToOptions => 'العودة إلى الخيارات';

  @override
  String get builderOrImport => 'أو استورد جدولًا موجودًا';

  @override
  String get builderImportViaAi => 'الاستيراد بالذكاء الاصطناعي';

  @override
  String get builderScanning => 'جارٍ المسح…';

  @override
  String get builderScanInstead => 'امسح صورة الجدول بدلًا من ذلك';

  @override
  String get builderCustomChip => 'مخصص';

  @override
  String get builderCycleLengthLabel => 'طول الدورة';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يوم',
      many: '$n يومًا',
      few: '$n أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'اختر تاريخًا';

  @override
  String get builderNoBlocksYet => 'لا كتل بعد';

  @override
  String get builderNoBlocksSub => 'أضف كتل ورديات لتحديد تناوبك';

  @override
  String builderDaysLine(String ranges) {
    return 'الأيام $ranges';
  }

  @override
  String get builderEditBlock => 'تعديل الكتلة';

  @override
  String get builderRemoveBlock => 'إزالة الكتلة';

  @override
  String get builderPickRosterStart => 'اختر تاريخ بدء الجدول';

  @override
  String get builderPickScanStart => 'اختر تاريخ بدء الجدول الممسوح';

  @override
  String get builderScanCamera => 'المسح بالكاميرا';

  @override
  String get builderImportScreenshot => 'استيراد لقطة شاشة';

  @override
  String builderScanFailed(String error) {
    return 'فشل المسح: $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'لم يُتعرَّف على أوقات الورديات. جرّب قصّ الصورة أقرب حول الجدول.';

  @override
  String get builderCustomRosterFallback => 'جدول مخصص';

  @override
  String get builderScannedRosterFallback => 'جدول ممسوح';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حُدّث الجدول: جُدولت $count وردية',
      many: 'حُدّث الجدول: جُدولت $count وردية',
      few: 'حُدّث الجدول: جُدولت $count ورديات',
      two: 'حُدّث الجدول: جُدولت ورديتان',
      one: 'حُدّث الجدول: جُدولت وردية واحدة',
      zero: 'حُدّث الجدول',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُنشئ: جُدولت $count وردية',
      many: 'أُنشئ: جُدولت $count وردية',
      few: 'أُنشئ: جُدولت $count ورديات',
      two: 'أُنشئ: جُدولت ورديتان',
      one: 'أُنشئ: جُدولت وردية واحدة',
      zero: 'أُنشئ الجدول',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'تعذّر إنشاء الجدول: $error';
  }

  @override
  String get builderRosterImported => 'استُورد الجدول إلى تقويمك';

  @override
  String builderCouldNotImport(String error) {
    return 'تعذّر استيراد الجدول: $error';
  }

  @override
  String get blockAddTitle => 'إضافة كتلة ورديات';

  @override
  String get blockEditTitle => 'تعديل كتلة الورديات';

  @override
  String get blockStart => 'البداية';

  @override
  String get blockEnd => 'النهاية';

  @override
  String get blockTapDays => 'انقر على الأيام التي تشملها هذه الوردية';

  @override
  String get blockUntappedOff => 'الأيام التي لم تنقر عليها أيام راحة.';

  @override
  String blockOverlap(String ranges) {
    return 'هذا الوقت يتداخل مع وردية أخرى في اليوم $ranges: غيّر الوقت أو تلك الأيام.';
  }

  @override
  String get blockAdd => 'إضافة الكتلة';

  @override
  String get blockSave => 'حفظ الكتلة';

  @override
  String get aiPromptCopied =>
      'نُسخ الموجّه! الصقه في تطبيق الذكاء الاصطناعي مع جدولك.';

  @override
  String get aiNothingToPaste => 'لا يوجد شيء للصق في الحافظة.';

  @override
  String get aiNoValidShifts =>
      'لم تُكتشف ورديات صالحة. تأكد من استخدام الموجّه المنسوخ.';

  @override
  String get aiStep1 => 'انسخ الموجّه';

  @override
  String get aiCopied => 'نُسخ!';

  @override
  String get aiCopyPrompt => 'نسخ موجّه الذكاء الاصطناعي';

  @override
  String get aiStep1Sub =>
      'الصقه في ChatGPT أو Gemini أو أي تطبيق ذكاء اصطناعي، وأضف نص جدولك أو صورة / لقطة شاشة ثم أرسل.';

  @override
  String get aiStep2 => 'الصق رد الذكاء الاصطناعي';

  @override
  String get aiPaste => 'لصق';

  @override
  String get aiParsePreview => 'التحليل والمعاينة';

  @override
  String get aiStep3 => 'راجع الورديات المكتشفة';

  @override
  String get aiStep3Sub =>
      'انقر على الشارة للتبديل بين نهارية ومسائية وليلية إذا أخطأ الذكاء الاصطناعي.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استيراد $count يوم',
      many: 'استيراد $count يومًا',
      few: 'استيراد $count أيام',
      two: 'استيراد يومين',
      one: 'استيراد يوم واحد',
      zero: 'استيراد',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'حوّل أي نص جدول إلى ورديات بمساعدة تطبيق ذكاء اصطناعي.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0 · عمل $working · راحة $off';
  }

  @override
  String get draftReviewTitle => 'مراجعة الجدول الممسوح';

  @override
  String draftRemovedDay(String date) {
    return 'أُزيل $date';
  }

  @override
  String get draftUndo => 'تراجع';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حُفظ $count يوم في جدولك',
      many: 'حُفظ $count يومًا في جدولك',
      few: 'حُفظت $count أيام في جدولك',
      two: 'حُفظ يومان في جدولك',
      one: 'حُفظ يوم واحد في جدولك',
      zero: 'لم يُحفظ شيء',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'اسم الجدول';

  @override
  String get draftScannedImage => 'الصورة الممسوحة';

  @override
  String get draftScannedImageSub => 'انقر على الصورة لتكبيرها والمقارنة';

  @override
  String get draftImageError => 'تعذّر عرض الصورة الممسوحة.';

  @override
  String get draftRemove => 'إزالة';

  @override
  String get draftNoEndTime => 'مُسحت دون وقت انتهاء: حدّده لتفعيل الحفظ.';

  @override
  String get draftTime => 'الوقت';

  @override
  String get draftSetEnd => 'تحديد النهاية';

  @override
  String get draftConfirmSave => 'تأكيد وحفظ';

  @override
  String notifBeforeYourShift(String type) {
    return 'قبل ورديتك ($type)';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind الساعة $time';
  }

  @override
  String get notifWindDownTitle => 'حان وقت الاسترخاء 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'ابتعد عن الشاشات: موعد نومك الساعة $time.';
  }

  @override
  String get notifWindDownBody =>
      'ابتعد عن الشاشات وابدأ الاسترخاء استعدادًا لليل.';

  @override
  String get notifBedtimeTitle => 'حان وقت النوم 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return 'اذهب إلى السرير لتنام نحو $hours س قبل $shift: الاستيقاظ الساعة $time.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return 'اذهب إلى السرير لتحقق هدف نوم $hours س.';
  }

  @override
  String get notifShiftDay => 'الوردية النهارية';

  @override
  String get notifShiftAfternoon => 'الوردية المسائية';

  @override
  String get notifShiftNight => 'الوردية الليلية';

  @override
  String get notifShiftGeneric => 'الوردية';

  @override
  String get notifTrialEndsTitle => 'تنتهي تجربتك في Rostrik غدًا';

  @override
  String get notifTrialEndsBody =>
      'افتح الوصول الكامل لتستمر منبهات وردياتك في الرنين.';

  @override
  String seedWakeUpLabel(String type) {
    return 'استيقاظ ($type)';
  }

  @override
  String get seedShiftGeneric => 'وردية';

  @override
  String commonListAnd(String items, String last) {
    return '$items و$last';
  }

  @override
  String get soundClassic => 'كلاسيكي';

  @override
  String get soundSiren => 'صفارة';

  @override
  String get soundDigital => 'رقمي';

  @override
  String get soundChime => 'رنين';

  @override
  String get patternFirstResponder => 'معيار فرق الطوارئ';

  @override
  String get ocrCropTitle => 'قُصّ صفّك أنت فقط، لا الفريق كله';

  @override
  String get draftNameHint => 'مثل: جدول مايو';
}
