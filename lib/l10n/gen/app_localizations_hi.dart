// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'शुरू करने से पहले';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik हर शिफ्ट के लिए आपको समय पर जगाने के लिए बना है। एक ईमानदार जानकारी: किसी भी फ़ोन पर आख़िरी फ़ैसला ऐप का नहीं, ऑपरेटिंग सिस्टम का होता है। कभी-कभार सिस्टम किसी भी अलार्म ऐप को देर से बजा सकता है या चुप करा सकता है (ज़्यादा सख़्त बैटरी सेवर, फ़ोर्स स्टॉप, या सिस्टम अपडेट के तुरंत बाद)।';

  @override
  String get legalBodyBackupAdvice =>
      'जिन शिफ्ट को आप किसी भी हाल में नहीं छोड़ सकते, उनके लिए बैकअप के तौर पर एक दूसरा अलार्म भी लगाएँ। यह हर अलार्म के साथ अच्छी आदत है, फ़ोन के अपने अलार्म के साथ भी।';

  @override
  String get legalReviewAndAccept => 'कृपया पढ़ें और स्वीकार करें:';

  @override
  String get legalPrivacyPolicy => 'निजता नीति';

  @override
  String get legalTermsOfUse => 'उपयोग की शर्तें';

  @override
  String get legalConsentCheckbox =>
      'मैं समझता/समझती हूँ कि ऑपरेटिंग सिस्टम किसी भी अलार्म ऐप पर असर डाल सकता है, और मैं निजता नीति और उपयोग की शर्तें स्वीकार करता/करती हूँ।';

  @override
  String get legalAgreeContinue => 'सहमत हूँ, आगे बढ़ें';

  @override
  String get commonSaving => 'सेव हो रहा है…';

  @override
  String get commonCouldNotOpenLink => 'लिंक नहीं खुल सका।';

  @override
  String get welcomeTagline =>
      'शिफ्ट में काम करने वालों के लिए स्मार्ट अलार्म।';

  @override
  String get welcomeSubTagline =>
      'ऐसे अलार्म जो सिर्फ़ हफ़्ते के दिनों को नहीं, आपके बदलते रोस्टर को मानते हैं।';

  @override
  String welcomeTrialTitle(int days) {
    return '$days दिन का मुफ़्त ट्रायल';
  }

  @override
  String get welcomeTrialBody =>
      'बिना कार्ड के सारी सुविधाएँ इस्तेमाल करें। उसके बाद बस एक बार ख़रीदें, कोई सब्सक्रिप्शन नहीं।';

  @override
  String get welcomeGetStarted => 'शुरू करें';

  @override
  String get welcomeSkip => 'छोड़ें / बाद में सेट करें';

  @override
  String get welcomeTimeFormat => 'समय का फ़ॉर्मैट';

  @override
  String get welcomeWeekStarts => 'हफ़्ता शुरू';

  @override
  String get common12h => '12 घंटे';

  @override
  String get common24h => '24 घंटे';

  @override
  String get commonSundayShort => 'रवि';

  @override
  String get commonMondayShort => 'सोम';

  @override
  String get rosterTypeTitle => 'रोस्टर का प्रकार चुनें';

  @override
  String get rosterTypeQuestion => 'आपका रोस्टर कैसा है?';

  @override
  String get rosterTypeDay => 'दिन की शिफ्ट';

  @override
  String get rosterTypeNight => 'रात की शिफ्ट';

  @override
  String get rosterTypeRotating => 'बदलती शिफ्ट';

  @override
  String get rosterTypeCustom => 'कस्टम';

  @override
  String get commonContinue => 'जारी रखें';

  @override
  String get commonComingSoon => 'जल्द आ रहा है';

  @override
  String get permsTitle => 'अनुमतियाँ';

  @override
  String get permsIntro =>
      'अलार्म भरोसे से बजें, इसके लिए Rostrik को कुछ अनुमतियाँ चाहिए। आप इन्हें बाद में सिस्टम सेटिंग में बदल सकते हैं।';

  @override
  String get permsNotifications => 'सूचनाएँ';

  @override
  String get permsNotificationsSub =>
      'जगाने वाली स्क्रीन दिखाने के लिए ज़रूरी।';

  @override
  String get permsExactAlarms => 'सटीक अलार्म';

  @override
  String get permsExactAlarmsSub => 'अलार्म ठीक तय समय पर बजते हैं।';

  @override
  String get permsBatteryUnrestricted => 'बैटरी: बिना पाबंदी';

  @override
  String get permsBatteryGrantedSub =>
      'अलार्म बैटरी ऑप्टिमाइज़ेशन से सुरक्षित हैं।';

  @override
  String get permsBatteryDeniedSub =>
      'कुछ फ़ोन बैकग्राउंड ऐप बंद कर देते हैं। ठीक करने के लिए टैप करें।';

  @override
  String get permsUnrestrictedBadge => 'बिना पाबंदी';

  @override
  String get batteryDialogTitle => 'अलार्म चालू रखें';

  @override
  String get batteryDialogIntro =>
      'कुछ फ़ोन (Samsung, Xiaomi, Oppo, Huawei) बैटरी बचाने के लिए बैकग्राउंड ऐप को ज़बरदस्ती बंद कर देते हैं। अगर Rostrik के साथ ऐसा हुआ, तो अलार्म बजने से पहले ही चुप हो सकता है।';

  @override
  String get batteryDialogMarkUnrestricted =>
      'इससे बचने के लिए Rostrik को \"बिना पाबंदी\" पर सेट करें:';

  @override
  String get batteryStep1 => 'इस ऐप की सेटिंग खोलें (नीचे वाला बटन)।';

  @override
  String get batteryStep2 => 'बैटरी (या \"ऐप का बैटरी इस्तेमाल\") पर टैप करें।';

  @override
  String get batteryStep3 =>
      '\"बिना पाबंदी\" चुनें (\"ऑप्टिमाइज़्ड\" या \"सीमित\" नहीं)।';

  @override
  String get batteryStep4 =>
      'अगर \"बैकग्राउंड गतिविधि की अनुमति दें\" दिखे, तो उसे भी चालू करें।';

  @override
  String get batteryStep5 =>
      '\"इस्तेमाल न होने पर ऐप गतिविधि रोकें\" (या \"ऐप इस्तेमाल न होने पर अनुमतियाँ हटाएँ\") बंद करें, ताकि आपके दूर रहने पर Android अलार्म की अनुमतियाँ वापस न ले।';

  @override
  String get commonNotNow => 'अभी नहीं';

  @override
  String get batteryGoToSettings => 'सेटिंग पर जाएँ';

  @override
  String get armEngineTitle => 'अलार्म चालू करें';

  @override
  String get armEngineRosterReady => 'आपका रोस्टर तैयार है';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · $date से शुरू';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'हम हर मेल खाती शिफ्ट से पहले जगाने वाले अलार्म ($summary) चालू कर देंगे।';
  }

  @override
  String get armEngineArming => 'चालू हो रहा है…';

  @override
  String get armEngineCta => 'मेरे अलार्म अपने-आप लगाएँ';

  @override
  String get armEngineLeadTimeLabel => 'अलार्म कितना पहले';

  @override
  String get armEngineLeadTimeHelper =>
      'शिफ्ट शुरू होने से कितनी देर पहले अलार्म बजे।';

  @override
  String get shiftTypeDay => 'दिन';

  @override
  String get shiftTypeAfternoon => 'दोपहर';

  @override
  String get shiftTypeNight => 'रात';

  @override
  String get shiftTypeOff => 'छुट्टी';

  @override
  String get weekdaysNone => 'कोई दिन नहीं';

  @override
  String get weekdaysEveryDay => 'हर दिन';

  @override
  String get weekdaysWeekdays => 'सोम–शुक्र';

  @override
  String get weekdaysWeekends => 'सप्ताहांत';

  @override
  String durationMin(int m) {
    return '$m मिनट';
  }

  @override
  String durationH(int h) {
    return '$h घंटे';
  }

  @override
  String durationHMin(int h, int m) {
    return '$h घंटे $m मिनट';
  }

  @override
  String durationMinShort(int m) {
    return '$m मि';
  }

  @override
  String durationHShort(int h) {
    return '$h घं';
  }

  @override
  String durationHMinShort(int h, int m) {
    return '$h घं $m मि';
  }

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonSkip => 'छोड़ें';

  @override
  String get commonBack => 'पीछे';

  @override
  String get commonDone => 'हो गया';

  @override
  String get commonNext => 'आगे';

  @override
  String get walkthroughIntroTitle => '60 सेकंड का परिचय';

  @override
  String get walkthroughIntroBodyTwo =>
      'दो चीज़ें जो Rostrik को ख़ास बनाती हैं। आप कभी भी छोड़ सकते हैं।';

  @override
  String get walkthroughIntroBodyOne =>
      'वह चीज़ जो Rostrik को ख़ास बनाती है। आप कभी भी छोड़ सकते हैं।';

  @override
  String get walkthroughPaintLabel => 'रोस्टर में रंग भरें';

  @override
  String get walkthroughPaintDetail =>
      'जिन दिनों काम है, उन पर टैप करें। बस इतना।';

  @override
  String get walkthroughShakeLabel => 'बंद करने के लिए हिलाएँ';

  @override
  String get walkthroughShakeDetail =>
      'ज़ोर से हिलाने पर ज़रूरी अलार्म बंद होता है।';

  @override
  String get walkthroughTryEach => 'हर एक आज़माने के लिए आगे पर टैप करें।';

  @override
  String get walkthroughTryIt => 'आज़माने के लिए आगे पर टैप करें।';

  @override
  String get walkthroughPaintBody =>
      'जिन दिनों काम है, उन पर टैप करें। असली बिल्डर में आप इसी तरह और ब्लॉक (दोपहर, रात) जोड़ सकते हैं।';

  @override
  String get walkthroughPaintPrompt =>
      'किसी दिन पर दिन की शिफ्ट भरने के लिए टैप करें।';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'बढ़िया! वे $count दिन अब दिन की शिफ्ट का ब्लॉक हैं। बिना टैप वाले दिन छुट्टी रहेंगे। इतना आसान।',
      one:
          'बढ़िया! वह दिन अब दिन की शिफ्ट का ब्लॉक है। बिना टैप वाले दिन छुट्टी रहेंगे। इतना आसान।',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'ज़रूरी शिफ्ट के अलार्म सिर्फ़ ज़ोर से और लगातार हिलाने पर बंद होते हैं, ताकि आधी नींद में किया टैप काम न करे। आज़माएँ: अपना फ़ोन हिलाएँ।';

  @override
  String get walkthroughShakeSuccess => 'हो गया!';

  @override
  String get walkthroughShakeSuccessDetail =>
      'ज़रूरी अलार्म ठीक ऐसे ही बंद होगा।';

  @override
  String get walkthroughDoneTitle => 'सब तैयार है';

  @override
  String get walkthroughDoneBody =>
      'कभी भी प्रबंधन से रोस्टर बनाएँ, और यह परिचय सेटिंग → मदद में दोबारा देखें।';

  @override
  String get navDashboard => 'होम';

  @override
  String get navTimeline => 'टाइमलाइन';

  @override
  String get navManage => 'प्रबंधन';

  @override
  String get navAlarms => 'अलार्म';

  @override
  String get navSleep => 'नींद';

  @override
  String get onbPatternTitle => 'अपना रोटेशन चुनें';

  @override
  String get purchaseTrialEnded => 'आपका मुफ़्त ट्रायल ख़त्म हो गया';

  @override
  String get purchaseBody =>
      'शिफ्ट के अलार्म चलते रहें, इसके लिए Rostrik को एक बार अनलॉक करें। आपका रोस्टर, अलार्म और सेटिंग सुरक्षित हैं, अनलॉक करते ही फिर से चालू हो जाएँगे।';

  @override
  String get purchaseAlarmsWontRing => 'तब तक अलार्म नहीं बजेंगे।';

  @override
  String get purchaseUnlock => 'पूरी सुविधा अनलॉक करें';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'पूरी सुविधा अनलॉक करें · $price';
  }

  @override
  String get purchaseRestore => 'ख़रीद वापस लाएँ';

  @override
  String get purchaseOneTime => 'एक बार की ख़रीद। कोई सब्सक्रिप्शन नहीं।';

  @override
  String get purchaseUnavailable =>
      'अभी ख़रीद उपलब्ध नहीं है। अपना कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get purchaseCheckingPrevious => 'पिछली ख़रीद ढूँढी जा रही है…';

  @override
  String get settingsTitle => 'सेटिंग';

  @override
  String get settingsLegalAbout => 'क़ानूनी जानकारी और परिचय';

  @override
  String get settingsHelp => 'मदद';

  @override
  String get settingsHowItWorks => 'यह कैसे काम करता है';

  @override
  String get settingsReplayTourShake =>
      'परिचय फिर देखें: रोस्टर भरना + हिलाकर बंद करना';

  @override
  String get settingsReplayTour => 'परिचय फिर देखें: रोस्टर भरना';

  @override
  String get settingsScreenTips => 'स्क्रीन टिप्स दिखाएँ';

  @override
  String get settingsScreenTipsSub =>
      'हर स्क्रीन पर एक बार दिखने वाले संकेत। दोबारा देखने के लिए चालू करें।';

  @override
  String get settingsFullAccess => 'पूरी सुविधा';

  @override
  String get settingsFullAccessUnlocked => 'पूरी सुविधा अनलॉक है';

  @override
  String get settingsThanks => 'Rostrik का साथ देने के लिए धन्यवाद।';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'मुफ़्त ट्रायल: $days दिन बाक़ी',
      one: 'मुफ़्त ट्रायल: 1 दिन बाक़ी',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'मुफ़्त ट्रायल ख़त्म';

  @override
  String get settingsUnlockPitch =>
      'ट्रायल ख़त्म होने पर भी शिफ्ट के अलार्म बजते रहें, इसके लिए एक बार अनलॉक करें। एक बार की ख़रीद, कभी सब्सक्रिप्शन नहीं।';

  @override
  String get settingsRestore => 'वापस लाएँ';

  @override
  String get settingsBrandTagline =>
      '9 से 5 के बाहर काम करने वालों के लिए अलार्म';

  @override
  String get settingsLeadTime => 'कितना पहले';

  @override
  String get settingsLeadTimeSub =>
      'हर शिफ्ट शुरू होने से इतना पहले अलार्म बजता है।';

  @override
  String get settingsSnoozeDuration => 'स्नूज़ की अवधि';

  @override
  String get settingsSnoozeDurationSub =>
      'स्नूज़ बटन बजते अलार्म को कितना आगे खिसकाए।';

  @override
  String get settingsMinutesLabel => 'मिनट';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m मिनट',
      one: '1 मिनट',
    );
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => 'शिफ्ट चक्र';

  @override
  String get settingsShiftCyclesSub => 'पैटर्न या टेम्पलेट से बनाए गए रोस्टर।';

  @override
  String get settingsAddShiftCycle => 'शिफ्ट चक्र जोड़ें';

  @override
  String get settingsNoRosters => 'आपने अभी तक कोई रोस्टर नहीं बनाया है।';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'बदलें';

  @override
  String get commonDelete => 'हटाएँ';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get settingsDeleteRosterTitle => 'रोस्टर हटाएँ?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count शिफ्ट',
      one: '1 शिफ्ट',
    );
    return '\"$label\" हटाएँ? बाक़ी अलार्म रद्द हो जाएँगे और $_temp0 हट जाएँगी।';
  }

  @override
  String settingsDeletedRoster(String label) {
    return '\"$label\" हटाया गया';
  }

  @override
  String get commonActive => 'चालू';

  @override
  String get commonUpcoming => 'आने वाला';

  @override
  String get commonPast => 'बीता हुआ';

  @override
  String get settingsWorkHistory => 'काम का इतिहास';

  @override
  String get settingsWorkHistorySub =>
      'पे-स्लिप जाँचने के लिए पूरी हो चुकी कस्टम शिफ्ट देखें और एक्सपोर्ट करें।';

  @override
  String get settingsViewWorkHistory => 'काम का इतिहास देखें और एक्सपोर्ट करें';

  @override
  String get settingsPreferences => 'पसंद';

  @override
  String get settingsPreferencesSub => 'ऐप में आपका शेड्यूल कैसे दिखे।';

  @override
  String get settingsAppearance => 'रूप';

  @override
  String get settingsThemeSystem => 'सिस्टम';

  @override
  String get settingsThemeLight => 'लाइट';

  @override
  String get settingsThemeDark => 'डार्क';

  @override
  String get settingsThemeSub =>
      'डार्क Rostrik का डिफ़ॉल्ट है। लाइट में गर्म क्रीम रंग हैं।';

  @override
  String get settings24h => '24 घंटे का समय इस्तेमाल करें';

  @override
  String get settings24hOn => 'समय 14:30 जैसा दिखेगा';

  @override
  String get settings24hOff => 'समय 02:30 PM जैसा दिखेगा';

  @override
  String get settingsWeekStartTitle => 'कैलेंडर सोमवार से शुरू करें';

  @override
  String get settingsWeekStartMon => 'हफ़्ता सोमवार से शुरू होता है';

  @override
  String get settingsWeekStartSun => 'हफ़्ता रविवार से शुरू होता है';

  @override
  String get settingsTimelineOpensOn => 'टाइमलाइन इसमें खुले';

  @override
  String get commonList => 'सूची';

  @override
  String get commonMonth => 'महीना';

  @override
  String get settingsCalendar => 'कैलेंडर';

  @override
  String get settingsCalendarSync => 'Google / डिवाइस कैलेंडर से सिंक करें';

  @override
  String get settingsCalendarSyncSub =>
      'आपकी शिफ्ट अपने-आप फ़ोन के अलग \"Rostrik Roster\" कैलेंडर में कॉपी होती हैं।';

  @override
  String get settingsCalSyncOff =>
      'कैलेंडर सिंक बंद। आने वाले \"Rostrik Roster\" इवेंट हटा दिए गए।';

  @override
  String get settingsCalSyncMirroring =>
      'आपका रोस्टर \"Rostrik Roster\" कैलेंडर में कॉपी हो रहा है…';

  @override
  String get settingsCalPermNeeded =>
      'रोस्टर सिंक करने के लिए कैलेंडर की अनुमति चाहिए।';

  @override
  String get settingsCalBlocked =>
      'कैलेंडर की पहुँच बंद है। सिंक करने के लिए सिस्टम सेटिंग में चालू करें।';

  @override
  String get settingsCalOpenSettings => 'सेटिंग';

  @override
  String get settingsCalUnsupported =>
      'इस डिवाइस पर कैलेंडर सिंक उपलब्ध नहीं है।';

  @override
  String get settingsDangerZone => 'सावधानी वाला हिस्सा';

  @override
  String get settingsDangerZoneSub =>
      'आपका रोस्टर, अलार्म और सेटिंग मिटाकर शुरुआती सेटअप फिर से शुरू करता है।';

  @override
  String get settingsResetAppData => 'ऐप डेटा रीसेट करें';

  @override
  String get settingsResetTitle => 'ऐप रीसेट करें?';

  @override
  String get settingsResetBody =>
      'पक्का? आपका रोस्टर, अलार्म और सेटिंग मिट जाएँगी।';

  @override
  String get settingsResetConfirm => 'रीसेट करें';

  @override
  String get dashNoUpcomingShifts => 'कोई आने वाली शिफ्ट नहीं';

  @override
  String get dashEnjoyTimeOff => 'छुट्टी का मज़ा लें।';

  @override
  String get dashInProgress => 'चल रही है';

  @override
  String get dashRotation => 'रोटेशन';

  @override
  String get dashAlarmsCantRing => 'अलार्म भरोसे से नहीं बज सकते';

  @override
  String get dashNotifsOffIssue =>
      'सूचनाएँ बंद हैं: बजता हुआ अलार्म जगाने वाली स्क्रीन नहीं दिखा सकता और बंद भी नहीं हो सकता।';

  @override
  String get dashOpenSettings => 'सेटिंग खोलें';

  @override
  String get dashExactBlockedIssue =>
      'सटीक अलार्म बंद हैं: कोई भी अलार्म शेड्यूल नहीं हो सकता।';

  @override
  String get dashAllow => 'अनुमति दें';

  @override
  String get dashSlideToSkip => 'यह अलार्म छोड़ने के लिए खिसकाएँ';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'सभी $count अलार्म छोड़ने के लिए खिसकाएँ',
      one: 'अलार्म छोड़ने के लिए खिसकाएँ',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'अगला अलार्म बंद करें · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'इस शिफ्ट के सभी $count अलार्म छोड़ें',
      one: 'इस शिफ्ट का अलार्म छोड़ें',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'अलार्म रहने दें';

  @override
  String get dashMyRotation => 'मेरा रोटेशन';

  @override
  String get dashCalendarUpcoming => 'कैलेंडर और आने वाली शिफ्ट';

  @override
  String get dashNextShifts => 'अगली शिफ्ट';

  @override
  String get dashOpenTimeline => 'टाइमलाइन खोलें';

  @override
  String heroStartsIn(String countdown) {
    return '$countdown में शुरू';
  }

  @override
  String heroEndsIn(String countdown) {
    return '$countdown में ख़त्म';
  }

  @override
  String get heroStartsInPrefix => 'शुरू होने में';

  @override
  String get heroEndsInPrefix => 'ख़त्म होने में';

  @override
  String heroStartsTodayAt(String time) {
    return 'आज $time बजे शुरू';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'आज $time बजे शुरू हुई';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'कल $time बजे शुरू';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'कल $time बजे शुरू हुई';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'कल $time बजे शुरू';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return '$date को $time बजे शुरू';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return '$date को $time बजे शुरू हुई';
  }

  @override
  String get shiftTypeDayShift => 'दिन की शिफ्ट';

  @override
  String get shiftTypeAfternoonShift => 'दोपहर की शिफ्ट';

  @override
  String get shiftTypeNightShift => 'रात की शिफ्ट';

  @override
  String heroDayXofY(int x, int y, String label) {
    return '$y में से दिन $x – $label';
  }

  @override
  String get heroOffTomorrow => 'कल छुट्टी';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन में छुट्टी',
      one: '1 दिन में छुट्टी',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'कल से काम पर';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन में काम पर वापसी',
      one: '1 दिन में काम पर वापसी',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'छुट्टी';

  @override
  String durationDayShort(int d) {
    return '$d दि';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d दि $h घं';
  }

  @override
  String get alarmsTitle => 'अलार्म';

  @override
  String get alarmsAddTooltip => 'अलार्म जोड़ें';

  @override
  String get alarmsSortTooltip => 'अलार्म क्रम से लगाएँ';

  @override
  String get alarmsSortByTime => 'समय के हिसाब से';

  @override
  String get alarmsSortByShiftType => 'शिफ्ट के प्रकार से';

  @override
  String get alarmsEmptyTitle => 'अभी कोई अलार्म नहीं।';

  @override
  String get alarmsEmptyBody => 'जोड़ने के लिए + पर टैप करें।';

  @override
  String get alarmsNextAlarm => 'अगला अलार्म';

  @override
  String get alarmsHolidayMode => 'छुट्टी मोड';

  @override
  String get alarmsHolidayModeSub => 'अलार्म रुके हुए हैं: कुछ नहीं बजेगा।';

  @override
  String get alarmsNoUpcoming => 'कोई आने वाला शिफ्ट अलार्म नहीं';

  @override
  String get alarmsNoUpcomingSub =>
      'रोटेशन के साथ चलने वाला अलार्म जोड़ें, या रोस्टर बनाएँ।';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'आपकी $type शिफ्ट के लिए · $day';
  }

  @override
  String get commonToday => 'आज';

  @override
  String get commonTomorrow => 'कल';

  @override
  String get alarmsOffWontRing => 'बंद: नहीं बजेगा';

  @override
  String get alarmsNoUpcomingRing => 'कोई बजना तय नहीं';

  @override
  String alarmsNextRing(String day, String time) {
    return 'अगली बार: $day $time बजे';
  }

  @override
  String get alarmsSwipeToDelete => 'हटाने के लिए स्वाइप करें';

  @override
  String get alarmsRingsOnceAutoDelete => 'एक बार बजेगा · अपने-आप हटेगा';

  @override
  String get alarmsRingsOnce => 'सिर्फ़ एक बार बजेगा';

  @override
  String get alarmsYourShift => 'आपकी शिफ्ट';

  @override
  String alarmsShiftsOfType(String type) {
    return '$type शिफ्ट';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'तय समय · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$shift से $lead पहले · डिफ़ॉल्ट';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$shift से $lead पहले';
  }

  @override
  String get createEditAlarm => 'अलार्म बदलें';

  @override
  String get createNewAlarm => 'नया अलार्म';

  @override
  String get createDefaultLabel => 'उठने का समय';

  @override
  String get createFallbackLabel => 'अलार्म';

  @override
  String get createPickBecomesDefault =>
      'आपकी पसंद नए अलार्म के लिए डिफ़ॉल्ट बन जाएगी।';

  @override
  String get createSelectFromFiles => 'फ़ाइलों से चुनें';

  @override
  String get createFilesSub => 'डिवाइस में सेव की गई ऑडियो फ़ाइल चुनें';

  @override
  String get createSelectSystemTone => 'सिस्टम टोन चुनें';

  @override
  String get createSystemToneSub => 'डिवाइस की अलार्म ध्वनियों में से चुनें';

  @override
  String get createAlarmTiming => 'अलार्म का समय';

  @override
  String get createLeadTimeMode => 'कितना पहले';

  @override
  String get createExactTimeMode => 'तय समय';

  @override
  String createFiresAt(String time) {
    return '$time बजे बजेगा';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return 'शिफ्ट शुरू होने से $lead पहले';
  }

  @override
  String get createLinkedShift => 'जुड़ी शिफ्ट';

  @override
  String get createRepeatOn => 'इन दिनों दोहराएँ';

  @override
  String get createLabelField => 'नाम';

  @override
  String get createLabelHint => 'जैसे: उठने का समय';

  @override
  String get createCriticalShift => 'ज़रूरी शिफ्ट';

  @override
  String get createCriticalShiftSub =>
      'हिलाकर बंद करें · बैकअप के लिए 3 सेकंड दबाकर रखें';

  @override
  String get createRingtone => 'रिंगटोन';

  @override
  String get commonStop => 'रोकें';

  @override
  String get commonPlay => 'चलाएँ';

  @override
  String get createVibrate => 'वाइब्रेट';

  @override
  String get createRepeat => 'दोहराएँ';

  @override
  String get createRepeatRotation => 'रोटेशन';

  @override
  String get createRepeatWeekly => 'साप्ताहिक';

  @override
  String get createRepeatOneTime => 'एक बार';

  @override
  String get createPickOneDay => 'कम से कम एक दिन चुनें';

  @override
  String get commonSave => 'सेव करें';

  @override
  String get commonSaveChanges => 'बदलाव सेव करें';

  @override
  String get createTimeBeforeShift => 'शिफ्ट से पहले का समय';

  @override
  String get commonOk => 'ठीक है';

  @override
  String get sleepTitle => 'नींद';

  @override
  String get sleepTargetHeader => 'नींद का लक्ष्य';

  @override
  String get sleepTargetSub =>
      'आप कितने घंटे सोना चाहते हैं। Rostrik आपके अगले अलार्म से पीछे गिनकर आज रात सोने का समय तय करता है।';

  @override
  String get sleepRemindersHeader => 'रिमाइंडर';

  @override
  String get sleepWindDownHeader => 'आराम शुरू करने का समय';

  @override
  String get sleepWindDownSub =>
      'सोने के समय से कितना पहले आराम शुरू करने का संकेत आए।';

  @override
  String get sleepSoundsHeader => 'नींद की आवाज़ें';

  @override
  String get sleepSoundsSub =>
      'नींद के लिए व्हाइट और ब्राउन नॉइज़। अपने-आप रुकने का टाइमर चुनें और किसी आवाज़ पर टैप करें।';

  @override
  String get sleepNothingToPlan => 'आज रात योजना बनाने को कुछ नहीं';

  @override
  String get sleepNothingToPlanSub =>
      'रोस्टर में शिफ्ट जोड़ें, Rostrik आपके अगले उठने के समय के हिसाब से सोने का समय तय करेगा।';

  @override
  String get sleepTransitionDay => 'बदलाव का दिन';

  @override
  String get sleepTransitionTitle => 'कल रात की शिफ्ट है। देर तक सो सकते हैं।';

  @override
  String get sleepTransitionBody =>
      'आज बदलाव का दिन है: रात की शिफ्ट से पहले आपकी छुट्टी है, इसलिए सुबह जल्दी अलार्म नहीं है। अभी भरपूर आराम करें और आज रात देर से सोएँ।';

  @override
  String get sleepRestRecovery => 'आराम और रिकवरी';

  @override
  String get sleepNoEarlyAlarm => 'सुबह जल्दी अलार्म नहीं';

  @override
  String get sleepRestBody =>
      'आपकी अगली शिफ्ट एक दिन से ज़्यादा दूर है, इसलिए आज रात उठने की कोई योजना नहीं। अपनी मर्ज़ी से सोएँ और थकान उतारें; शिफ्ट पास आने पर Rostrik सोने की योजना बना देगा।';

  @override
  String get sleepTonightsPlan => 'आज रात की योजना';

  @override
  String get sleepTargetBedtime => 'सोने का समय';

  @override
  String get sleepWindDownStat => 'आराम';

  @override
  String get sleepWakeUpStat => 'उठना';

  @override
  String get sleepDurationStat => 'अवधि';

  @override
  String get sleepBedtimeReminder => 'सोने का रिमाइंडर';

  @override
  String sleepNudgeAtBedtime(String time) {
    return '$time बजे मुझे सोने की याद दिलाएँ';
  }

  @override
  String get sleepBedtimeSub => 'सोने का समय होने पर याद दिलाएँ';

  @override
  String get sleepWindDownReminder => 'आराम का रिमाइंडर';

  @override
  String sleepNudgeAtWindDown(String time) {
    return '$time बजे मुझे आराम शुरू करने की याद दिलाएँ';
  }

  @override
  String get sleepWindDownReminderSub =>
      'आराम शुरू करने के लिए थोड़ा पहले याद दिलाएँ';

  @override
  String get commonOff => 'बंद';

  @override
  String get sleepSoundWhiteNoise => 'व्हाइट नॉइज़';

  @override
  String get sleepSoundPinkNoise => 'पिंक नॉइज़';

  @override
  String get sleepSoundBrownNoise => 'ब्राउन नॉइज़';

  @override
  String get sleepSoundFan => 'पंखा';

  @override
  String get sleepSoundOcean => 'समुद्र';

  @override
  String get sleepSoundRain => 'बारिश';

  @override
  String get manageTitle => 'प्रबंधन';

  @override
  String get manageRosterTools => 'रोस्टर टूल';

  @override
  String get manageRosterToolsSub =>
      'वे शिफ्ट बनाएँ और बदलें जिनसे आपके अलार्म और नींद की योजना चलती है।';

  @override
  String get manageGenerateRotation => 'रोटेशन बनाएँ';

  @override
  String get manageGenerateRotationSub =>
      'टेम्पलेट से दोहराने वाला शिफ्ट पैटर्न बनाएँ।';

  @override
  String get manageAddCustomShift => 'अलग शिफ्ट जोड़ें';

  @override
  String get manageAddCustomShiftSub => 'रोस्टर में एक अकेली शिफ्ट जोड़ें।';

  @override
  String get manageMarkLeave => 'छुट्टी दर्ज करें';

  @override
  String get manageMarkLeaveSub =>
      'अपनी छुट्टी के दिन (वार्षिक छुट्टी, बीमारी) एक साथ भरें।';

  @override
  String get managePauseSchedule => 'शेड्यूल रोकें';

  @override
  String get managePausedSub =>
      'छुट्टी मोड चालू: अलार्म चुप हैं, आपका रोस्टर सुरक्षित है।';

  @override
  String get manageNotPausedSub =>
      'छुट्टी मोड: जब शिफ्ट न हो, तब अलार्म चुप रखें।';

  @override
  String get markLeaveTitle => 'छुट्टी दर्ज करें';

  @override
  String get markLeaveIntro =>
      'छुट्टी वाले दिनों पर टैप करें, कारण चुनें और लागू करें। उन दिनों अलार्म नहीं बजेंगे और रोस्टर वैसा ही रहेगा।';

  @override
  String get leaveAnnual => 'वार्षिक छुट्टी';

  @override
  String get leaveSick => 'बीमारी';

  @override
  String get leavePublicHoliday => 'सार्वजनिक अवकाश';

  @override
  String get markLeaveReason => 'कारण';

  @override
  String get markLeaveFallbackReason => 'छुट्टी';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count शिफ्ट को $reason के रूप में दर्ज किया।',
      one: '1 शिफ्ट को $reason के रूप में दर्ज किया।',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => 'दर्ज करने के लिए दिन चुनें';

  @override
  String get markLeaveNoShifts => 'उन दिनों कोई शिफ्ट नहीं';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count शिफ्ट पर लागू करें',
      one: '1 शिफ्ट पर लागू करें',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => 'काम का इतिहास';

  @override
  String get workHistoryExportTooltip => 'इतिहास एक्सपोर्ट करें';

  @override
  String workHistoryExportFailed(String error) {
    return 'इतिहास एक्सपोर्ट नहीं हो सका: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count शिफ्ट पूरी कीं',
      one: '1 शिफ्ट पूरी की',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours घं';
  }

  @override
  String get commonPaused => 'रुकी हुई';

  @override
  String workHistoryPausedReason(String reason) {
    return 'रुकी हुई · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'रोटेशन';

  @override
  String get workHistoryAdHocBadge => 'अतिरिक्त';

  @override
  String get workHistoryEmptyTitle => 'अभी कोई पूरी शिफ्ट नहीं';

  @override
  String get workHistoryEmptyBody =>
      'आपकी पूरी की गई शिफ्ट, रोटेशन हों या कस्टम, ख़त्म होने पर यहाँ दिखेंगी और पे-स्लिप जाँचने के लिए एक्सपोर्ट की जा सकेंगी।';

  @override
  String get workHistoryShareSubject => 'Rostrik काम का इतिहास';

  @override
  String get workHistoryShareText =>
      'Rostrik से एक्सपोर्ट किया गया मेरा काम का इतिहास।';

  @override
  String get shiftEdAddShift => 'शिफ्ट जोड़ें';

  @override
  String get shiftEdEditShift => 'शिफ्ट बदलें';

  @override
  String get shiftEdDate => 'तारीख़';

  @override
  String get shiftEdPickDate => 'तारीख़ चुनें';

  @override
  String get shiftEdStarts => 'शुरू';

  @override
  String get shiftEdEnds => 'ख़त्म';

  @override
  String get shiftEdPickTime => 'समय चुनें';

  @override
  String get shiftEdEndsNextDay => 'अगले दिन ख़त्म';

  @override
  String get shiftEdPauseTitle => 'यह शिफ्ट रोकें / रद्द करें';

  @override
  String get shiftEdPausedSub =>
      'अलार्म नहीं बजेगा। रिकॉर्ड के तौर पर कैलेंडर में रहेगी।';

  @override
  String get shiftEdNotPausedSub =>
      'बिना हटाए छुट्टी का दिन (बीमारी, छुट्टी, अवकाश) दर्ज करें।';

  @override
  String get shiftEdReasonOptional => 'कारण (वैकल्पिक)';

  @override
  String get dayShifts => 'शिफ्ट';

  @override
  String get dayActivities => 'गतिविधियाँ';

  @override
  String get dayAddAnotherShift => 'एक और शिफ्ट जोड़ें';

  @override
  String get dayAddActivity => 'गतिविधि जोड़ें';

  @override
  String get dayAddActivitySub => 'इवेंट, काम या जन्मदिन';

  @override
  String get dayReminder => 'रिमाइंडर';

  @override
  String get actEditActivity => 'गतिविधि बदलें';

  @override
  String get actLeadAtTime => 'ठीक समय पर';

  @override
  String get actLead10Min => '10 मिनट पहले';

  @override
  String get actLead30Min => '30 मिनट पहले';

  @override
  String get actLead1Hour => '1 घंटा पहले';

  @override
  String get actLead1Day => '1 दिन पहले';

  @override
  String get actEvent => 'इवेंट';

  @override
  String get actTask => 'काम';

  @override
  String get actBirthday => 'जन्मदिन';

  @override
  String get actTitleField => 'शीर्षक';

  @override
  String get actAllDay => 'पूरे दिन';

  @override
  String get actTimeField => 'समय';

  @override
  String get actRemindMe => 'मुझे याद दिलाएँ';

  @override
  String get actRemindMeSub => 'एक हल्की सूचना, शिफ्ट के अलार्म से अलग।';

  @override
  String get actRemindAt => 'याद दिलाने का समय';

  @override
  String get actReminderPassed => 'यह समय निकल चुका है: यह रिमाइंडर नहीं आएगा।';

  @override
  String get actNoteOptional => 'नोट (वैकल्पिक)';

  @override
  String get actCompleted => 'पूरा हुआ';

  @override
  String get tipDashboardTitle => 'आपका होम';

  @override
  String get tipDashboardBody =>
      'यह आपका मुख्य ठिकाना है। अगली शिफ्ट का लाइव काउंटडाउन और रोटेशन में आप कहाँ हैं, यहाँ देखें। ब्यौरे के लिए किसी टाइल पर टैप करें।';

  @override
  String get tipTimelineTitle => 'आपका पूरा रोस्टर';

  @override
  String get tipTimelineBody =>
      'ऊपर सूची और महीने के कैलेंडर के बीच बदलें। शिफ्ट बदलने या इवेंट, काम या जन्मदिन जोड़ने के लिए किसी भी दिन पर टैप करें।';

  @override
  String get tipManageTitle => 'बनाएँ और बदलें';

  @override
  String get tipManageBody =>
      'बदलता रोस्टर बनाएँ, एक अलग (ओवरटाइम) शिफ्ट जोड़ें, या छुट्टी के लिए पूरा शेड्यूल रोकें, सब यहीं से।';

  @override
  String get tipAlarmsTitle => 'आपके अलार्म';

  @override
  String get tipAlarmsBody =>
      'आपकी शिफ्ट से बने सारे अलार्म, और आपके ख़ुद जोड़े गए अलार्म। समय या टोन बदलने के लिए किसी पर टैप करें, या उसे हिलाकर बंद होने वाला ज़रूरी शिफ्ट अलार्म बनाएँ।';

  @override
  String get tipSleepTitle => 'नींद की योजना';

  @override
  String get tipSleepBody =>
      'आपके रोस्टर के साथ चलने वाली आराम की योजना: नींद का लक्ष्य तय करें और अगली शिफ्ट पर तरोताज़ा पहुँचें।';

  @override
  String get tipReplayHint =>
      'इन्हें कभी भी सेटिंग › यह कैसे काम करता है में दोबारा देखें।';

  @override
  String get tipDontShow => 'टिप्स न दिखाएँ';

  @override
  String get tipGotIt => 'समझ गया';

  @override
  String get timelineListView => 'सूची';

  @override
  String get timelineMonthView => 'महीना';

  @override
  String get shiftTypeAftShort => 'दोपहर';

  @override
  String get timelineNoShifts =>
      'कोई शिफ्ट तय नहीं। जोड़ने के लिए + पर टैप करें।';

  @override
  String timelineNoMatch(String filter) {
    return '$filter फ़िल्टर से कोई शिफ्ट मेल नहीं खाती।';
  }

  @override
  String get timelineRestDay => 'आराम का दिन';

  @override
  String timelineRestDayReason(String reason) {
    return 'आराम का दिन · $reason';
  }

  @override
  String get timelineAllDay => 'पूरे दिन';

  @override
  String get calLegendPausedLeave => 'रुकी / छुट्टी';

  @override
  String get calLegendActivity => 'गतिविधि';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterWork => 'काम';

  @override
  String get criticalHoldToDismiss => 'या बंद करने के लिए दबाकर रखें';

  @override
  String get patternChoosePattern => 'पैटर्न चुनें';

  @override
  String get patternRotatingSwings => 'दिन-रात रोटेशन';

  @override
  String get patternDaySwings => 'सिर्फ़ दिन की शिफ्ट';

  @override
  String get patternNightSwings => 'सिर्फ़ रात की शिफ्ट';

  @override
  String get patternShiftTimes => 'शिफ्ट का समय';

  @override
  String get patternGenerate => 'दिन 1 तय करें और बनाएँ';

  @override
  String get patternSelectDay1 => 'अपना अगला दिन 1 चुनें';

  @override
  String patternDay1Hint(String label) {
    return 'आपके $label ब्लॉक का पहला दिन';
  }

  @override
  String get patternNextDay1 => 'अगला दिन 1';

  @override
  String get patternUseThisDate => 'यह तारीख़ इस्तेमाल करें';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count शिफ्ट बनाई गईं',
      one: '1 शिफ्ट बनाई गई',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'बन नहीं सका: $error';
  }

  @override
  String get patternFirstBlockFallback => 'पहले';

  @override
  String get patternBuildCustom => 'कस्टम रोस्टर बनाएँ';

  @override
  String get patternBuildCustomSub =>
      'कोई टेम्पलेट नहीं जमा? अपने ब्लॉक ख़ुद बनाएँ।';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n दिन',
      one: '1 दिन',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n दोपहर',
      one: '1 दोपहर',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n रातें',
      one: '1 रात',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '$n छुट्टी';
  }

  @override
  String get builderNewRoster => 'नया शिफ्ट रोस्टर';

  @override
  String get builderEditRoster => 'रोस्टर बदलें';

  @override
  String get builderNewSub => 'अपना शिफ्ट रोटेशन पैटर्न सेट करें';

  @override
  String get builderEditSub => 'यह सेव किया रोस्टर बदलें और उसकी जगह रखें';

  @override
  String get builderNameHint => 'रोस्टर का नाम (जैसे: मेरा 14-दिन रोटेशन)';

  @override
  String get builderCycleLength => 'चक्र की लंबाई';

  @override
  String get builderStartDate => 'शुरू होने की तारीख़';

  @override
  String get builderShiftBlocks => 'शिफ्ट ब्लॉक';

  @override
  String get builderAddShiftBlock => 'शिफ्ट ब्लॉक जोड़ें';

  @override
  String get builderCreateRoster => 'रोस्टर बनाएँ';

  @override
  String get builderSaveChanges => 'बदलाव सेव करें';

  @override
  String get builderReplaceWarning =>
      'सेव करने पर यह रोस्टर बदल जाएगा। इस पर भरी गई छुट्टियाँ रीसेट हो जाएँगी।';

  @override
  String get builderBackToOptions => 'विकल्पों पर वापस';

  @override
  String get builderOrImport => 'या मौजूदा रोस्टर इम्पोर्ट करें';

  @override
  String get builderImportViaAi => 'AI से इम्पोर्ट करें';

  @override
  String get builderScanning => 'स्कैन हो रहा है…';

  @override
  String get builderScanInstead => 'इसके बजाय रोस्टर की फ़ोटो स्कैन करें';

  @override
  String get builderCustomChip => 'कस्टम';

  @override
  String get builderCycleLengthLabel => 'चक्र की लंबाई';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n दिन',
      one: '1 दिन',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'तारीख़ चुनें';

  @override
  String get builderNoBlocksYet => 'अभी कोई ब्लॉक नहीं';

  @override
  String get builderNoBlocksSub =>
      'अपना रोटेशन तय करने के लिए शिफ्ट ब्लॉक जोड़ें';

  @override
  String builderDaysLine(String ranges) {
    return 'दिन $ranges';
  }

  @override
  String get builderEditBlock => 'ब्लॉक बदलें';

  @override
  String get builderRemoveBlock => 'ब्लॉक हटाएँ';

  @override
  String get builderPickRosterStart => 'रोस्टर शुरू होने की तारीख़ चुनें';

  @override
  String get builderPickScanStart => 'स्कैन किए रोस्टर की शुरुआती तारीख़ चुनें';

  @override
  String get builderScanCamera => 'कैमरे से स्कैन करें';

  @override
  String get builderImportScreenshot => 'स्क्रीनशॉट इम्पोर्ट करें';

  @override
  String builderScanFailed(String error) {
    return 'स्कैन नहीं हो सका: $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'शिफ्ट का समय नहीं पहचाना गया। टेबल के आसपास और कसकर क्रॉप करें।';

  @override
  String get builderCustomRosterFallback => 'कस्टम रोस्टर';

  @override
  String get builderScannedRosterFallback => 'स्कैन किया रोस्टर';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'रोस्टर अपडेट हुआ: $count शिफ्ट तय',
      one: 'रोस्टर अपडेट हुआ: 1 शिफ्ट तय',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'बन गया: $count शिफ्ट तय',
      one: 'बन गया: 1 शिफ्ट तय',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'रोस्टर नहीं बन सका: $error';
  }

  @override
  String get builderRosterImported => 'रोस्टर आपके कैलेंडर में इम्पोर्ट हो गया';

  @override
  String builderCouldNotImport(String error) {
    return 'रोस्टर इम्पोर्ट नहीं हो सका: $error';
  }

  @override
  String get blockAddTitle => 'शिफ्ट ब्लॉक जोड़ें';

  @override
  String get blockEditTitle => 'शिफ्ट ब्लॉक बदलें';

  @override
  String get blockStart => 'शुरू';

  @override
  String get blockEnd => 'ख़त्म';

  @override
  String get blockTapDays => 'जिन दिनों यह शिफ्ट है, उन पर टैप करें';

  @override
  String get blockUntappedOff => 'बिना टैप वाले दिन छुट्टी हैं।';

  @override
  String blockOverlap(String ranges) {
    return 'यह समय दिन $ranges पर दूसरी शिफ्ट से टकराता है। समय या वे दिन बदलें।';
  }

  @override
  String get blockAdd => 'ब्लॉक जोड़ें';

  @override
  String get blockSave => 'ब्लॉक सेव करें';

  @override
  String get aiPromptCopied =>
      'प्रॉम्प्ट कॉपी हो गया! इसे अपने रोस्टर के साथ AI ऐप में पेस्ट करें।';

  @override
  String get aiNothingToPaste => 'क्लिपबोर्ड में पेस्ट करने को कुछ नहीं है।';

  @override
  String get aiNoValidShifts =>
      'कोई सही शिफ्ट नहीं मिली। पक्का करें कि आपने कॉपी किया AI प्रॉम्प्ट इस्तेमाल किया।';

  @override
  String get aiStep1 => 'प्रॉम्प्ट कॉपी करें';

  @override
  String get aiCopied => 'कॉपी हो गया!';

  @override
  String get aiCopyPrompt => 'AI प्रॉम्प्ट कॉपी करें';

  @override
  String get aiStep1Sub =>
      'इसे ChatGPT, Gemini या किसी भी AI ऐप में पेस्ट करें, फिर अपने रोस्टर का टेक्स्ट या फ़ोटो/स्क्रीनशॉट जोड़कर भेजें।';

  @override
  String get aiStep2 => 'AI का जवाब पेस्ट करें';

  @override
  String get aiPaste => 'पेस्ट करें';

  @override
  String get aiParsePreview => 'पढ़ें और झलक देखें';

  @override
  String get aiStep3 => 'मिली हुई शिफ्ट जाँचें';

  @override
  String get aiStep3Sub =>
      'अगर AI से ग़लती हुई हो, तो बैज पर टैप करके दिन, दोपहर और रात के बीच बदलें।';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन इम्पोर्ट करें',
      one: '1 दिन इम्पोर्ट करें',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'AI ऐप की मदद से किसी भी रोस्टर टेक्स्ट को शिफ्ट में बदलें।';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
      one: '1 दिन',
    );
    return '$_temp0 · $working काम · $off छुट्टी';
  }

  @override
  String get draftReviewTitle => 'स्कैन किया रोस्टर जाँचें';

  @override
  String draftRemovedDay(String date) {
    return '$date हटाया गया';
  }

  @override
  String get draftUndo => 'वापस लें';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'रोस्टर में $count दिन सेव हुए',
      one: 'रोस्टर में 1 दिन सेव हुआ',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'रोस्टर का नाम';

  @override
  String get draftScannedImage => 'स्कैन की गई तस्वीर';

  @override
  String get draftScannedImageSub =>
      'बड़ा करके मिलान करने के लिए तस्वीर पर टैप करें';

  @override
  String get draftImageError => 'स्कैन की गई तस्वीर नहीं दिख सकी।';

  @override
  String get draftRemove => 'हटाएँ';

  @override
  String get draftNoEndTime =>
      'ख़त्म होने का समय स्कैन नहीं हुआ: सेव करने के लिए उसे सेट करें।';

  @override
  String get draftTime => 'समय';

  @override
  String get draftSetEnd => 'ख़त्म होने का समय';

  @override
  String get draftConfirmSave => 'पक्का करें और सेव करें';

  @override
  String notifBeforeYourShift(String type) {
    return 'आपकी $type शिफ्ट से पहले';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind · $time';
  }

  @override
  String get notifWindDownTitle => 'आराम करने का समय 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'स्क्रीन से दूर हो जाएँ: सोने का समय $time है।';
  }

  @override
  String get notifWindDownBody =>
      'स्क्रीन से दूर हो जाएँ और रात के लिए आराम शुरू करें।';

  @override
  String get notifBedtimeTitle => 'सोने का समय 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return 'अपनी $shift से पहले ~$hours घंटे की नींद के लिए सो जाएँ: $time बजे उठना है।';
  }

  @override
  String notifBedtimeBody(int hours) {
    return '$hours घंटे की नींद का लक्ष्य पूरा करने के लिए सो जाएँ।';
  }

  @override
  String get notifShiftDay => 'दिन की शिफ्ट';

  @override
  String get notifShiftAfternoon => 'दोपहर की शिफ्ट';

  @override
  String get notifShiftNight => 'रात की शिफ्ट';

  @override
  String get notifShiftGeneric => 'शिफ्ट';

  @override
  String get notifTrialEndsTitle => 'आपका Rostrik ट्रायल कल ख़त्म हो रहा है';

  @override
  String get notifTrialEndsBody =>
      'शिफ्ट के अलार्म बजते रहें, इसके लिए पूरी सुविधा अनलॉक करें।';

  @override
  String seedWakeUpLabel(String type) {
    return '$type शिफ्ट पर उठना';
  }

  @override
  String get seedShiftGeneric => 'शिफ्ट';

  @override
  String commonListAnd(String items, String last) {
    return '$items और $last';
  }

  @override
  String get soundClassic => 'क्लासिक';

  @override
  String get soundSiren => 'सायरन';

  @override
  String get soundDigital => 'डिजिटल';

  @override
  String get soundChime => 'घंटी';

  @override
  String get patternFirstResponder => 'आपातकालीन सेवा मानक';

  @override
  String get ocrCropTitle => 'पूरी टीम नहीं, सिर्फ़ अपनी पंक्ति क्रॉप करें';

  @override
  String get draftNameHint => 'जैसे: मई का रोस्टर';
}
