// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'Başlamadan önce';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik seni her vardiyaya uyandırmak için tasarlandı. Dürüst bir uyarı: Her telefonda son söz uygulamada değil, işletim sistemindedir. Nadir durumlarda işletim sistemi her alarm uygulamasını geciktirebilir veya susturabilir (agresif pil tasarrufu, zorla durdurma ya da sistem güncellemesinin hemen ardından).';

  @override
  String get legalBodyBackupAdvice =>
      'Kesinlikle kaçıramayacağın vardiyalar için yedek olarak ikinci bir alarm kur. Bu, telefonunun kendi alarmı dahil her alarm için iyi bir alışkanlıktır.';

  @override
  String get legalReviewAndAccept => 'Lütfen incele ve kabul et:';

  @override
  String get legalPrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get legalTermsOfUse => 'Kullanım Koşulları';

  @override
  String get legalConsentCheckbox =>
      'İşletim sisteminin her alarm uygulamasını etkileyebileceğini anlıyorum; Gizlilik Politikası\'nı ve Kullanım Koşulları\'nı kabul ediyorum.';

  @override
  String get legalAgreeContinue => 'Kabul et ve devam et';

  @override
  String get commonSaving => 'Kaydediliyor…';

  @override
  String get commonCouldNotOpenLink => 'Bağlantı açılamadı.';

  @override
  String get welcomeTagline => 'Vardiyalı çalışanlar için akıllı çalar saat.';

  @override
  String get welcomeSubTagline =>
      'Sadece hafta içini değil, dönüşümlü vardiya çizelgeni takip eden alarmlar.';

  @override
  String welcomeTrialTitle(int days) {
    return '$days günlük ücretsiz deneme';
  }

  @override
  String get welcomeTrialBody =>
      'Tüm özelliklere tam erişim, kart gerekmez. Sonrasında tek seferlik satın alma, asla abonelik yok.';

  @override
  String get welcomeGetStarted => 'Başla';

  @override
  String get welcomeSkip => 'Atla / Sonra ayarla';

  @override
  String get welcomeTimeFormat => 'Saat biçimi';

  @override
  String get welcomeWeekStarts => 'Hafta başlangıcı';

  @override
  String get common12h => '12 sa';

  @override
  String get common24h => '24 sa';

  @override
  String get commonSundayShort => 'Paz';

  @override
  String get commonMondayShort => 'Pzt';

  @override
  String get rosterTypeTitle => 'Çizelge türünü seç';

  @override
  String get rosterTypeQuestion => 'Vardiya çizelgen nasıl?';

  @override
  String get rosterTypeDay => 'Gündüz vardiyaları';

  @override
  String get rosterTypeNight => 'Gece vardiyaları';

  @override
  String get rosterTypeRotating => 'Dönüşümlü';

  @override
  String get rosterTypeCustom => 'Özel';

  @override
  String get commonContinue => 'Devam';

  @override
  String get commonComingSoon => 'Yakında';

  @override
  String get permsTitle => 'İzinler';

  @override
  String get permsIntro =>
      'Rostrik\'in alarmları güvenilir şekilde çaldırmak için birkaç izne ihtiyacı var. Bunları daha sonra sistem ayarlarından değiştirebilirsin.';

  @override
  String get permsNotifications => 'Bildirimler';

  @override
  String get permsNotificationsSub => 'Uyanma ekranını göstermek için gerekli.';

  @override
  String get permsExactAlarms => 'Tam zamanlı alarmlar';

  @override
  String get permsExactAlarmsSub =>
      'Alarmların tam planlanan saatte çalmasını sağlar.';

  @override
  String get permsBatteryUnrestricted => 'Pil: Kısıtlamasız';

  @override
  String get permsBatteryGrantedSub =>
      'Alarmlar pil optimizasyonundan korunuyor.';

  @override
  String get permsBatteryDeniedSub =>
      'Bazı telefonlar arka plandaki uygulamaları kapatır. Düzeltmek için dokun.';

  @override
  String get permsUnrestrictedBadge => 'Kısıtlamasız';

  @override
  String get batteryDialogTitle => 'Alarmları canlı tut';

  @override
  String get batteryDialogIntro =>
      'Bazı telefonlar (Samsung, Xiaomi, Oppo, Huawei) pil tasarrufu için arka plandaki uygulamaları agresif şekilde kapatır. Bu Rostrik\'in başına gelirse bir alarm çalmadan susabilir.';

  @override
  String get batteryDialogMarkUnrestricted =>
      'Bunu önlemek için Rostrik\'i Kısıtlamasız olarak ayarla:';

  @override
  String get batteryStep1 => 'Bu uygulamanın ayarlarını aç (aşağıdaki düğme).';

  @override
  String get batteryStep2 => 'Pil\'e dokun (veya \"Uygulama pil kullanımı\").';

  @override
  String get batteryStep3 =>
      'Kısıtlamasız\'ı seç (\"Optimize edilmiş\" veya \"Kısıtlanmış\" değil).';

  @override
  String get batteryStep4 =>
      '\"Arka plan etkinliğine izin ver\" görürsen onu da aç.';

  @override
  String get batteryStep5 =>
      '\"Kullanılmıyorsa uygulama etkinliğini duraklat\" (veya \"Kullanılmıyorsa izinleri kaldır\") seçeneğini KAPAT; böylece sen yokken Android alarm izinlerini geri almaz.';

  @override
  String get commonNotNow => 'Şimdi değil';

  @override
  String get batteryGoToSettings => 'Ayarlara git';

  @override
  String get armEngineTitle => 'Alarmlarını kur';

  @override
  String get armEngineRosterReady => 'Çizelgen hazır';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · başlangıç $date';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'Eşleşen her vardiyadan önce uyandırma alarmlarını ($summary) açacağız.';
  }

  @override
  String get armEngineArming => 'Kuruluyor…';

  @override
  String get armEngineCta => 'Alarmlarımı otomatikleştir';

  @override
  String get armEngineLeadTimeLabel => 'Alarm ön süresi';

  @override
  String get armEngineLeadTimeHelper =>
      'Alarmın vardiya başlamadan ne kadar önce çalacağı.';

  @override
  String get shiftTypeDay => 'Gündüz';

  @override
  String get shiftTypeAfternoon => 'Akşam';

  @override
  String get shiftTypeNight => 'Gece';

  @override
  String get shiftTypeOff => 'İzin';

  @override
  String get weekdaysNone => 'Gün yok';

  @override
  String get weekdaysEveryDay => 'Her gün';

  @override
  String get weekdaysWeekdays => 'Hafta içi';

  @override
  String get weekdaysWeekends => 'Hafta sonu';

  @override
  String durationMin(int m) {
    return '$m dk';
  }

  @override
  String durationH(int h) {
    return '$h sa';
  }

  @override
  String durationHMin(int h, int m) {
    return '$h sa $m dk';
  }

  @override
  String durationMinShort(int m) {
    return '$m dk';
  }

  @override
  String durationHShort(int h) {
    return '$h sa';
  }

  @override
  String durationHMinShort(int h, int m) {
    return '$h sa $m dk';
  }

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonSkip => 'Atla';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonDone => 'Bitti';

  @override
  String get commonNext => 'İleri';

  @override
  String get walkthroughIntroTitle => '60 saniyelik tur';

  @override
  String get walkthroughIntroBodyTwo =>
      'Rostrik\'i işe yarar kılan iki şey. İstediğin zaman atlayabilirsin.';

  @override
  String get walkthroughIntroBodyOne =>
      'Rostrik\'i işe yarar kılan şey. İstediğin zaman atlayabilirsin.';

  @override
  String get walkthroughPaintLabel => 'Çizelgeni boya';

  @override
  String get walkthroughPaintDetail =>
      'Çalıştığın günlere dokun, bu kadar hızlı.';

  @override
  String get walkthroughShakeLabel => 'Kapatmak için salla';

  @override
  String get walkthroughShakeDetail =>
      'Sert bir sallama kritik alarmı kapatır.';

  @override
  String get walkthroughTryEach => 'Her birini denemek için İleri\'ye dokun.';

  @override
  String get walkthroughTryIt => 'Denemek için İleri\'ye dokun.';

  @override
  String get walkthroughPaintBody =>
      'Çalıştığın günlere dokun. Gerçek düzenleyicide aynı şekilde daha fazla blok (akşam, gece) ekleyebilirsin.';

  @override
  String get walkthroughPaintPrompt =>
      'Gündüz vardiyası boyamak için bir güne dokun.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Harika! Bu $count gün artık bir gündüz bloğu. Dokunulmayan günler izinli kalır. Bu kadar kolay.',
      one:
          'Harika! O gün artık bir gündüz bloğu. Dokunulmayan günler izinli kalır. Bu kadar kolay.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'Kritik vardiya alarmları ancak sert ve sürekli sallamayla kapanır; yarı uykulu bir dokunuş yetmez. Dene: telefonunu salla.';

  @override
  String get walkthroughShakeSuccess => 'Başardın!';

  @override
  String get walkthroughShakeSuccessDetail =>
      'Kritik bir alarmı tam olarak böyle susturacaksın.';

  @override
  String get walkthroughDoneTitle => 'Her şey hazır';

  @override
  String get walkthroughDoneBody =>
      'İstediğin zaman Yönet\'ten çizelge oluştur; bu turu Ayarlar → Yardım\'dan tekrar izleyebilirsin.';

  @override
  String get navDashboard => 'Özet';

  @override
  String get navTimeline => 'Takvim';

  @override
  String get navManage => 'Yönet';

  @override
  String get navAlarms => 'Alarmlar';

  @override
  String get navSleep => 'Uyku';

  @override
  String get onbPatternTitle => 'Düzenini seç';

  @override
  String get purchaseTrialEnded => 'Ücretsiz deneme süren doldu';

  @override
  String get purchaseBody =>
      'Vardiya alarmlarının çalmaya devam etmesi için Rostrik\'in kilidini bir kez aç. Çizelgen, alarmların ve ayarların güvende; kilidi açtığın an kaldığı yerden devam eder.';

  @override
  String get purchaseAlarmsWontRing => 'O zamana kadar alarmlar çalmayacak.';

  @override
  String get purchaseUnlock => 'Tam erişimin kilidini aç';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'Tam erişimin kilidini aç · $price';
  }

  @override
  String get purchaseRestore => 'Satın almayı geri yükle';

  @override
  String get purchaseOneTime => 'Tek seferlik satın alma. Abonelik yok.';

  @override
  String get purchaseUnavailable =>
      'Satın alma şu anda kullanılamıyor. Bağlantını kontrol edip tekrar dene.';

  @override
  String get purchaseCheckingPrevious => 'Önceki satın alma aranıyor…';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLegalAbout => 'YASAL VE HAKKINDA';

  @override
  String get settingsHelp => 'YARDIM';

  @override
  String get settingsHowItWorks => 'Nasıl çalışır';

  @override
  String get settingsReplayTourShake =>
      'Turu tekrar izle: çizelge boyama + kapatmak için sallama';

  @override
  String get settingsReplayTour => 'Turu tekrar izle: çizelge boyama';

  @override
  String get settingsScreenTips => 'Ekran ipuçlarını göster';

  @override
  String get settingsScreenTipsSub =>
      'Her ekranda bir kerelik ipuçları. Tekrar görmek için aç.';

  @override
  String get settingsFullAccess => 'TAM ERİŞİM';

  @override
  String get settingsFullAccessUnlocked => 'Tam erişim açık';

  @override
  String get settingsThanks => 'Rostrik\'e destek olduğun için teşekkürler.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Ücretsiz deneme: $days gün kaldı',
      one: 'Ücretsiz deneme: 1 gün kaldı',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'Ücretsiz deneme bitti';

  @override
  String get settingsUnlockPitch =>
      'Deneme bittiğinde vardiya alarmlarının çalmaya devam etmesi için bir kez kilidi aç: tek seferlik satın alma, asla abonelik değil.';

  @override
  String get settingsRestore => 'Geri yükle';

  @override
  String get settingsBrandTagline => 'Mesai saatlerinin ötesi için alarmlar';

  @override
  String get settingsLeadTime => 'Ön süre';

  @override
  String get settingsLeadTimeSub => 'Alarm her vardiyadan bu kadar önce çalar.';

  @override
  String get settingsSnoozeDuration => 'Erteleme süresi';

  @override
  String get settingsSnoozeDurationSub =>
      'Ertele düğmesinin çalan alarmı ne kadar ileri attığı.';

  @override
  String get settingsMinutesLabel => 'Dakika';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m dakika',
      one: '1 dakika',
    );
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => 'VARDİYA DÖNGÜLERİ';

  @override
  String get settingsShiftCyclesSub =>
      'Bir düzen veya şablondan oluşturduğun çizelgeler.';

  @override
  String get settingsAddShiftCycle => 'Vardiya döngüsü ekle';

  @override
  String get settingsNoRosters => 'Henüz hiç çizelge oluşturmadın.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'Düzenle';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonCancel => 'İptal';

  @override
  String get settingsDeleteRosterTitle => 'Çizelge silinsin mi?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vardiya',
      one: '1 vardiya',
    );
    return '\"$label\" silinsin mi? Bekleyen alarmlar iptal edilir ve $_temp0 kaldırılır.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return '\"$label\" silindi';
  }

  @override
  String get commonActive => 'Aktif';

  @override
  String get commonUpcoming => 'Yaklaşan';

  @override
  String get commonPast => 'Geçmiş';

  @override
  String get settingsWorkHistory => 'ÇALIŞMA GEÇMİŞİ';

  @override
  String get settingsWorkHistorySub =>
      'Maaş bordronu doğrulamak için tamamlanan ek vardiyalarını incele ve dışa aktar.';

  @override
  String get settingsViewWorkHistory => 'Geçmişi görüntüle ve dışa aktar';

  @override
  String get settingsPreferences => 'TERCİHLER';

  @override
  String get settingsPreferencesSub =>
      'Programının uygulamada nasıl görüneceği.';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsThemeSub =>
      'Koyu, Rostrik\'in varsayılanıdır. Açık tema sıcak krem tonları kullanır.';

  @override
  String get settings24h => '24 saat biçimini kullan';

  @override
  String get settings24hOn => 'Saatler 14:30 olarak görünür';

  @override
  String get settings24hOff => 'Saatler 02:30 PM olarak görünür';

  @override
  String get settingsWeekStartTitle => 'Takvimi pazartesi başlat';

  @override
  String get settingsWeekStartMon => 'Haftalar pazartesi başlar';

  @override
  String get settingsWeekStartSun => 'Haftalar pazar başlar';

  @override
  String get settingsTimelineOpensOn => 'Takvim açılış görünümü';

  @override
  String get commonList => 'Liste';

  @override
  String get commonMonth => 'Ay';

  @override
  String get settingsCalendar => 'TAKVİM';

  @override
  String get settingsCalendarSync => 'Google / cihaz takvimiyle eşitle';

  @override
  String get settingsCalendarSyncSub =>
      'Vardiyalarını telefonundaki ayrı bir \"Rostrik Roster\" takvimine otomatik kopyalar.';

  @override
  String get settingsCalSyncOff =>
      'Takvim eşitleme kapalı. Yaklaşan \"Rostrik Roster\" etkinlikleri silindi.';

  @override
  String get settingsCalSyncMirroring =>
      'Çizelgen \"Rostrik Roster\" takvimine kopyalanıyor…';

  @override
  String get settingsCalPermNeeded =>
      'Çizelgeni eşitlemek için takvim izni gerekli.';

  @override
  String get settingsCalBlocked =>
      'Takvim erişimi engelli. Eşitlemek için sistem ayarlarından aç.';

  @override
  String get settingsCalOpenSettings => 'Ayarlar';

  @override
  String get settingsCalUnsupported =>
      'Bu cihazda takvim eşitleme kullanılamıyor.';

  @override
  String get settingsDangerZone => 'TEHLİKELİ BÖLGE';

  @override
  String get settingsDangerZoneSub =>
      'Çizelgeni, alarmlarını ve ayarlarını siler, ardından kurulumu baştan başlatır.';

  @override
  String get settingsResetAppData => 'Uygulama verilerini sıfırla';

  @override
  String get settingsResetTitle => 'Uygulama sıfırlansın mı?';

  @override
  String get settingsResetBody =>
      'Emin misin? Çizelgen, alarmların ve ayarların silinecek.';

  @override
  String get settingsResetConfirm => 'Sıfırla';

  @override
  String get dashNoUpcomingShifts => 'Yaklaşan vardiya yok';

  @override
  String get dashEnjoyTimeOff => 'İznin tadını çıkar.';

  @override
  String get dashInProgress => 'DEVAM EDİYOR';

  @override
  String get dashRotation => 'Düzen';

  @override
  String get dashAlarmsCantRing => 'Alarmlar güvenilir şekilde çalamıyor';

  @override
  String get dashNotifsOffIssue =>
      'Bildirimler kapalı: Çalan bir alarm uyanma ekranını gösteremez ve kapatılamaz.';

  @override
  String get dashOpenSettings => 'Ayarları aç';

  @override
  String get dashExactBlockedIssue =>
      'Tam zamanlı alarmlar engelli: Hiçbir uyandırma planlanamaz.';

  @override
  String get dashAllow => 'İzin ver';

  @override
  String get dashSlideToSkip => 'Bu alarmı atlamak için kaydır';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alarmın hepsini atlamak için kaydır',
      one: 'Alarmı atlamak için kaydır',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'Yaklaşan alarmı kapat · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu vardiyanın $count alarmını da atla',
      one: 'Bu vardiyanın alarmını atla',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'Alarmı koru';

  @override
  String get dashMyRotation => 'Düzenim';

  @override
  String get dashCalendarUpcoming => 'Takvim ve yaklaşan vardiyalar';

  @override
  String get dashNextShifts => 'Sonraki vardiyalar';

  @override
  String get dashOpenTimeline => 'Takvimi aç';

  @override
  String heroStartsIn(String countdown) {
    return '$countdown sonra başlıyor';
  }

  @override
  String heroEndsIn(String countdown) {
    return '$countdown sonra bitiyor';
  }

  @override
  String get heroStartsInPrefix => 'Başlamasına:';

  @override
  String get heroEndsInPrefix => 'Bitmesine:';

  @override
  String heroStartsTodayAt(String time) {
    return 'Bugün $time başlıyor';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'Bugün $time başladı';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'Yarın $time başlıyor';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'Dün $time başladı';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'Dün $time başlıyor';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return '$date $time başlıyor';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return '$date $time başladı';
  }

  @override
  String get shiftTypeDayShift => 'Gündüz vardiyası';

  @override
  String get shiftTypeAfternoonShift => 'Akşam vardiyası';

  @override
  String get shiftTypeNightShift => 'Gece vardiyası';

  @override
  String heroDayXofY(int x, int y, String label) {
    return '$y günün $x. günü – $label';
  }

  @override
  String get heroOffTomorrow => 'Yarın izinli';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün sonra izinli',
      one: '1 gün sonra izinli',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'Yarın işbaşı';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün sonra işbaşı',
      one: '1 gün sonra işbaşı',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'İzinli';

  @override
  String durationDayShort(int d) {
    return '$d g';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d g $h sa';
  }

  @override
  String get alarmsTitle => 'Alarmlar';

  @override
  String get alarmsAddTooltip => 'Alarm ekle';

  @override
  String get alarmsSortTooltip => 'Alarmları sırala';

  @override
  String get alarmsSortByTime => 'Saate göre';

  @override
  String get alarmsSortByShiftType => 'Vardiya türüne göre';

  @override
  String get alarmsEmptyTitle => 'Henüz alarm yok.';

  @override
  String get alarmsEmptyBody => 'Eklemek için + simgesine dokun.';

  @override
  String get alarmsNextAlarm => 'SONRAKİ ALARM';

  @override
  String get alarmsHolidayMode => 'Tatil modu';

  @override
  String get alarmsHolidayModeSub =>
      'Alarmlar duraklatıldı: hiçbir şey çalmayacak.';

  @override
  String get alarmsNoUpcoming => 'Yaklaşan vardiya alarmı yok';

  @override
  String get alarmsNoUpcomingSub =>
      'Düzeni takip eden bir alarm ekle ya da çizelge oluştur.';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'vardiyan için ($type) · $day';
  }

  @override
  String get commonToday => 'Bugün';

  @override
  String get commonTomorrow => 'Yarın';

  @override
  String get alarmsOffWontRing => 'Kapalı: çalmayacak';

  @override
  String get alarmsNoUpcomingRing => 'Planlanmış çalma yok';

  @override
  String alarmsNextRing(String day, String time) {
    return 'Sonraki çalma: $day $time';
  }

  @override
  String get alarmsSwipeToDelete => 'Silmek için kaydır';

  @override
  String get alarmsRingsOnceAutoDelete => 'Bir kez çalar · kendini siler';

  @override
  String get alarmsRingsOnce => 'Yalnızca bir kez çalar';

  @override
  String get alarmsYourShift => 'Vardiyan';

  @override
  String alarmsShiftsOfType(String type) {
    return 'Vardiyalar ($type)';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'Tam saat · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$shift: $lead önce · varsayılan';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$shift: $lead önce';
  }

  @override
  String get createEditAlarm => 'Alarmı düzenle';

  @override
  String get createNewAlarm => 'Yeni alarm';

  @override
  String get createDefaultLabel => 'Uyanma';

  @override
  String get createFallbackLabel => 'Alarm';

  @override
  String get createPickBecomesDefault =>
      'Seçimin yeni alarmlar için varsayılan olur.';

  @override
  String get createSelectFromFiles => 'Dosyalardan seç';

  @override
  String get createFilesSub => 'Cihazında kayıtlı bir ses dosyası seç';

  @override
  String get createSelectSystemTone => 'Sistem sesi seç';

  @override
  String get createSystemToneSub => 'Cihazının alarm seslerinden seç';

  @override
  String get createAlarmTiming => 'Alarm zamanlaması';

  @override
  String get createLeadTimeMode => 'Ön süre';

  @override
  String get createExactTimeMode => 'Tam saat';

  @override
  String createFiresAt(String time) {
    return '$time çalar';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return 'Vardiya başlangıcından $lead önce';
  }

  @override
  String get createLinkedShift => 'Bağlı vardiya';

  @override
  String get createRepeatOn => 'Tekrar günleri';

  @override
  String get createLabelField => 'Etiket';

  @override
  String get createLabelHint => 'örn. Uyanma';

  @override
  String get createCriticalShift => 'Kritik vardiya';

  @override
  String get createCriticalShiftSub =>
      'Kapatmak için salla · yedek olarak 3 saniye basılı tut';

  @override
  String get createRingtone => 'Zil sesi';

  @override
  String get commonStop => 'Durdur';

  @override
  String get commonPlay => 'Oynat';

  @override
  String get createVibrate => 'Titreşim';

  @override
  String get createRepeat => 'Tekrar';

  @override
  String get createRepeatRotation => 'Düzen';

  @override
  String get createRepeatWeekly => 'Haftalık';

  @override
  String get createRepeatOneTime => 'Bir kez';

  @override
  String get createPickOneDay => 'En az bir gün seç';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonSaveChanges => 'Değişiklikleri kaydet';

  @override
  String get createTimeBeforeShift => 'Vardiyadan önceki süre';

  @override
  String get commonOk => 'Tamam';

  @override
  String get sleepTitle => 'Uyku';

  @override
  String get sleepTargetHeader => 'UYKU HEDEFİ';

  @override
  String get sleepTargetSub =>
      'Kaç saat uyumak istediğin. Rostrik bu geceki yatma saatini belirlemek için bir sonraki alarmından geriye doğru sayar.';

  @override
  String get sleepRemindersHeader => 'HATIRLATICILAR';

  @override
  String get sleepWindDownHeader => 'SAKİNLEŞME ÖN SÜRESİ';

  @override
  String get sleepWindDownSub =>
      'Sakinleşme hatırlatmasının yatma saatinden ne kadar önce geleceği.';

  @override
  String get sleepSoundsHeader => 'UYKU SESLERİ';

  @override
  String get sleepSoundsSub =>
      'Uykuya dalmak için beyaz ve kahverengi gürültü. Bir zamanlayıcı seç ve bir sese dokun.';

  @override
  String get sleepNothingToPlan => 'Bu gece planlanacak bir şey yok';

  @override
  String get sleepNothingToPlanSub =>
      'Çizelgene bir vardiya ekle, Rostrik bir sonraki uyanışına göre kişisel bir yatma saati belirlesin.';

  @override
  String get sleepTransitionDay => 'GEÇİŞ GÜNÜ';

  @override
  String get sleepTransitionTitle =>
      'Yarın gece vardiyan var. Geç kalkabilirsin.';

  @override
  String get sleepTransitionBody =>
      'Bugün geçiş günü: Gecelerden önce izinlisin, yani erken alarm yok. Şimdiden fazladan dinlen ve bu gece daha geç yat.';

  @override
  String get sleepRestRecovery => 'DİNLENME VE TOPARLANMA';

  @override
  String get sleepNoEarlyAlarm => 'Erken alarm yok';

  @override
  String get sleepRestBody =>
      'Sonraki vardiyan bir günden daha uzakta, bu gece planlanacak bir uyanış yok. Kendi saatine göre uyu ve toparlan; vardiya yaklaşınca Rostrik yatma planını hazırlar.';

  @override
  String get sleepTonightsPlan => 'BU GECEKİ PLAN';

  @override
  String get sleepTargetBedtime => 'Yatma saati';

  @override
  String get sleepWindDownStat => 'Sakinleşme';

  @override
  String get sleepWakeUpStat => 'Uyanma';

  @override
  String get sleepDurationStat => 'Süre';

  @override
  String get sleepBedtimeReminder => 'Yatma saati hatırlatıcısı';

  @override
  String sleepNudgeAtBedtime(String time) {
    return 'Yatmam için saat $time beni uyar';
  }

  @override
  String get sleepBedtimeSub => 'Yatma zamanı geldiğinde bir uyarı';

  @override
  String get sleepWindDownReminder => 'Sakinleşme hatırlatıcısı';

  @override
  String sleepNudgeAtWindDown(String time) {
    return 'Sakinleşmeye başlamam için saat $time beni uyar';
  }

  @override
  String get sleepWindDownReminderSub =>
      'Sakinleşmeye başlamak için daha erken bir uyarı';

  @override
  String get commonOff => 'Kapalı';

  @override
  String get sleepSoundWhiteNoise => 'Beyaz gürültü';

  @override
  String get sleepSoundPinkNoise => 'Pembe gürültü';

  @override
  String get sleepSoundBrownNoise => 'Kahverengi gürültü';

  @override
  String get sleepSoundFan => 'Vantilatör';

  @override
  String get sleepSoundOcean => 'Okyanus';

  @override
  String get sleepSoundRain => 'Yağmur';

  @override
  String get manageTitle => 'Yönet';

  @override
  String get manageRosterTools => 'ÇİZELGE ARAÇLARI';

  @override
  String get manageRosterToolsSub =>
      'Alarmlarını ve uyku planını yöneten vardiyaları oluştur ve düzenle.';

  @override
  String get manageGenerateRotation => 'Düzen oluştur';

  @override
  String get manageGenerateRotationSub =>
      'Bir şablondan tekrarlanan vardiya düzeni oluştur.';

  @override
  String get manageAddCustomShift => 'Tek seferlik vardiya ekle';

  @override
  String get manageAddCustomShiftSub => 'Çizelgene tek bir ek vardiya ekle.';

  @override
  String get manageMarkLeave => 'İzin / tatil işaretle';

  @override
  String get manageMarkLeaveSub =>
      'İzinli olduğun günleri (yıllık izin, hastalık) tek seferde boya.';

  @override
  String get managePauseSchedule => 'Programı duraklat';

  @override
  String get managePausedSub =>
      'Tatil modu AÇIK: Alarmlar sessiz, çizelgen güvende.';

  @override
  String get manageNotPausedSub =>
      'Tatil modu: Vardiya dışındayken alarmları sustur.';

  @override
  String get markLeaveTitle => 'İzin işaretle';

  @override
  String get markLeaveIntro =>
      'İzinli olduğun günlere dokun, bir neden seç ve uygula. O günlerdeki alarmlar çalmaz, çizelgen olduğu gibi kalır.';

  @override
  String get leaveAnnual => 'Yıllık izin';

  @override
  String get leaveSick => 'Hastalık';

  @override
  String get leavePublicHoliday => 'Resmi tatil';

  @override
  String get markLeaveReason => 'Neden';

  @override
  String get markLeaveFallbackReason => 'izin';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vardiya $reason olarak işaretlendi.',
      one: '1 vardiya $reason olarak işaretlendi.',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => 'İşaretlenecek günleri seç';

  @override
  String get markLeaveNoShifts => 'O günlerde vardiya yok';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vardiyaya uygula',
      one: '1 vardiyaya uygula',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => 'Çalışma geçmişi';

  @override
  String get workHistoryExportTooltip => 'Geçmişi dışa aktar';

  @override
  String workHistoryExportFailed(String error) {
    return 'Geçmiş dışa aktarılamadı: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vardiya çalışıldı',
      one: '1 vardiya çalışıldı',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours sa';
  }

  @override
  String get commonPaused => 'Duraklatıldı';

  @override
  String workHistoryPausedReason(String reason) {
    return 'Duraklatıldı · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'Düzen';

  @override
  String get workHistoryAdHocBadge => 'Ek';

  @override
  String get workHistoryEmptyTitle => 'Henüz tamamlanan vardiya yok';

  @override
  String get workHistoryEmptyBody =>
      'Çalıştığın vardiyalar, düzenli ya da ek fark etmeksizin, bitince burada görünür ve bordro kontrolü için dışa aktarılmaya hazır olur.';

  @override
  String get workHistoryShareSubject => 'Rostrik Çalışma Geçmişi';

  @override
  String get workHistoryShareText =>
      'Rostrik\'ten dışa aktardığım çalışma geçmişim.';

  @override
  String get shiftEdAddShift => 'Vardiya ekle';

  @override
  String get shiftEdEditShift => 'Vardiyayı düzenle';

  @override
  String get shiftEdDate => 'Tarih';

  @override
  String get shiftEdPickDate => 'Tarih seç';

  @override
  String get shiftEdStarts => 'Başlangıç';

  @override
  String get shiftEdEnds => 'Bitiş';

  @override
  String get shiftEdPickTime => 'Saat seç';

  @override
  String get shiftEdEndsNextDay => 'Ertesi gün biter';

  @override
  String get shiftEdPauseTitle => 'Bu vardiyayı duraklat / iptal et';

  @override
  String get shiftEdPausedSub => 'Alarm çalmaz. Kayıt olarak takviminde kalır.';

  @override
  String get shiftEdNotPausedSub =>
      'Silmeden bir izin günü (hastalık, izin, tatil) işaretle.';

  @override
  String get shiftEdReasonOptional => 'Neden (isteğe bağlı)';

  @override
  String get dayShifts => 'Vardiyalar';

  @override
  String get dayActivities => 'Etkinlikler';

  @override
  String get dayAddAnotherShift => 'Başka vardiya ekle';

  @override
  String get dayAddActivity => 'Etkinlik ekle';

  @override
  String get dayAddActivitySub => 'Etkinlik, görev veya doğum günü';

  @override
  String get dayReminder => 'Hatırlatıcı';

  @override
  String get actEditActivity => 'Etkinliği düzenle';

  @override
  String get actLeadAtTime => 'Tam zamanında';

  @override
  String get actLead10Min => '10 dk önce';

  @override
  String get actLead30Min => '30 dk önce';

  @override
  String get actLead1Hour => '1 saat önce';

  @override
  String get actLead1Day => '1 gün önce';

  @override
  String get actEvent => 'Etkinlik';

  @override
  String get actTask => 'Görev';

  @override
  String get actBirthday => 'Doğum günü';

  @override
  String get actTitleField => 'Başlık';

  @override
  String get actAllDay => 'Tüm gün';

  @override
  String get actTimeField => 'Saat';

  @override
  String get actRemindMe => 'Bana hatırlat';

  @override
  String get actRemindMeSub =>
      'Vardiya alarmlarından ayrı, nazik bir bildirim.';

  @override
  String get actRemindAt => 'Hatırlatma saati';

  @override
  String get actReminderPassed => 'Bu saat geçti: bu hatırlatıcı gelmeyecek.';

  @override
  String get actNoteOptional => 'Not (isteğe bağlı)';

  @override
  String get actCompleted => 'Tamamlandı';

  @override
  String get tipDashboardTitle => 'Özet ekranın';

  @override
  String get tipDashboardBody =>
      'Merkezin burası. Sonraki vardiyanı canlı geri sayımla ve düzende nerede olduğunu gör. Ayrıntılar için bir kutucuğa dokun.';

  @override
  String get tipTimelineTitle => 'Tüm çizelgen';

  @override
  String get tipTimelineBody =>
      'Üstten liste ve aylık takvim arasında geçiş yap. Bir vardiyayı düzenlemek ya da etkinlik, görev veya doğum günü eklemek için bir güne dokun.';

  @override
  String get tipManageTitle => 'Oluştur ve düzenle';

  @override
  String get tipManageBody =>
      'Dönüşümlü çizelge oluştur, tek seferlik (fazla mesai) vardiya ekle ya da izin için tüm programı duraklat; hepsi burada.';

  @override
  String get tipAlarmsTitle => 'Alarmların';

  @override
  String get tipAlarmsBody =>
      'Vardiyalarının oluşturduğu tüm alarmlar ve senin eklediklerin. Saatini veya sesini değiştirmek ya da sallayarak kapanan kritik vardiya alarmına çevirmek için birine dokun.';

  @override
  String get tipSleepTitle => 'Uyku planı';

  @override
  String get tipSleepBody =>
      'Çizelgeni takip eden bir sakinleşme planı: Uyku hedefi belirle ve sonraki vardiyana dinlenmiş git.';

  @override
  String get tipReplayHint =>
      'İstediğin zaman Ayarlar › Nasıl çalışır\'dan tekrar izle.';

  @override
  String get tipDontShow => 'İpuçlarını gösterme';

  @override
  String get tipGotIt => 'Anladım';

  @override
  String get timelineListView => 'Liste';

  @override
  String get timelineMonthView => 'Ay';

  @override
  String get shiftTypeAftShort => 'Akş';

  @override
  String get timelineNoShifts =>
      'Planlanmış vardiya yok. Eklemek için + simgesine dokun.';

  @override
  String timelineNoMatch(String filter) {
    return '\"$filter\" filtresine uyan vardiya yok.';
  }

  @override
  String get timelineRestDay => 'Dinlenme günü';

  @override
  String timelineRestDayReason(String reason) {
    return 'Dinlenme günü · $reason';
  }

  @override
  String get timelineAllDay => 'Tüm gün';

  @override
  String get calLegendPausedLeave => 'Duraklatıldı / İzin';

  @override
  String get calLegendActivity => 'Etkinlik';

  @override
  String get filterAll => 'Tümü';

  @override
  String get filterWork => 'İş';

  @override
  String get criticalHoldToDismiss => 'Ya da kapatmak için basılı tut';

  @override
  String get patternChoosePattern => 'Bir düzen seç';

  @override
  String get patternRotatingSwings => 'Karma düzenler';

  @override
  String get patternDaySwings => 'Yalnız gündüz';

  @override
  String get patternNightSwings => 'Yalnız gece';

  @override
  String get patternShiftTimes => 'Vardiya saatleri';

  @override
  String get patternGenerate => '1. günü ayarla ve oluştur';

  @override
  String get patternSelectDay1 => 'Sonraki 1. gününü seç';

  @override
  String patternDay1Hint(String label) {
    return 'Bloğunun ilk günü ($label)';
  }

  @override
  String get patternNextDay1 => 'Sonraki 1. gün';

  @override
  String get patternUseThisDate => 'Bu tarihi kullan';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vardiya oluşturuldu',
      one: '1 vardiya oluşturuldu',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'Oluşturulamadı: $error';
  }

  @override
  String get patternFirstBlockFallback => 'ilk';

  @override
  String get patternBuildCustom => 'Özel çizelge oluştur';

  @override
  String get patternBuildCustomSub =>
      'Hiçbir şablon uymuyor mu? Kendi bloklarını oluştur.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Gündüz',
      one: '1 Gündüz',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Akşam',
      one: '1 Akşam',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Gece',
      one: '1 Gece',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '$n İzin';
  }

  @override
  String get builderNewRoster => 'Yeni vardiya çizelgesi';

  @override
  String get builderEditRoster => 'Çizelgeyi düzenle';

  @override
  String get builderNewSub => 'Vardiya düzenini ayarla';

  @override
  String get builderEditSub => 'Bu kayıtlı çizelgeyi değiştir ve yerine koy';

  @override
  String get builderNameHint => 'Çizelge adı (örn. 14 günlük düzenim)';

  @override
  String get builderCycleLength => 'DÖNGÜ UZUNLUĞU';

  @override
  String get builderStartDate => 'BAŞLANGIÇ TARİHİ';

  @override
  String get builderShiftBlocks => 'VARDİYA BLOKLARI';

  @override
  String get builderAddShiftBlock => 'Vardiya bloğu ekle';

  @override
  String get builderCreateRoster => 'Çizelge oluştur';

  @override
  String get builderSaveChanges => 'Değişiklikleri kaydet';

  @override
  String get builderReplaceWarning =>
      'Kaydetmek bu çizelgenin yerini alır. Üzerine boyanmış izin / tatil işaretleri sıfırlanır.';

  @override
  String get builderBackToOptions => 'Seçeneklere dön';

  @override
  String get builderOrImport => 'YA DA MEVCUT BİR ÇİZELGEYİ İÇE AKTAR';

  @override
  String get builderImportViaAi => 'Yapay zekâ ile içe aktar';

  @override
  String get builderScanning => 'Taranıyor…';

  @override
  String get builderScanInstead => 'Bunun yerine çizelge fotoğrafı tara';

  @override
  String get builderCustomChip => 'Özel';

  @override
  String get builderCycleLengthLabel => 'Döngü uzunluğu';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gün',
      one: '1 gün',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'Tarih seç';

  @override
  String get builderNoBlocksYet => 'Henüz blok yok';

  @override
  String get builderNoBlocksSub =>
      'Düzenini tanımlamak için vardiya blokları ekle';

  @override
  String builderDaysLine(String ranges) {
    return 'Günler $ranges';
  }

  @override
  String get builderEditBlock => 'Bloğu düzenle';

  @override
  String get builderRemoveBlock => 'Bloğu kaldır';

  @override
  String get builderPickRosterStart => 'Çizelge başlangıç tarihini seç';

  @override
  String get builderPickScanStart =>
      'Taranan çizelgenin başlangıç tarihini seç';

  @override
  String get builderScanCamera => 'Kamerayla tara';

  @override
  String get builderImportScreenshot => 'Ekran görüntüsü içe aktar';

  @override
  String builderScanFailed(String error) {
    return 'Tarama başarısız: $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'Vardiya saati tanınmadı. Tabloya daha yakın kırpmayı dene.';

  @override
  String get builderCustomRosterFallback => 'Özel çizelge';

  @override
  String get builderScannedRosterFallback => 'Taranan çizelge';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çizelge güncellendi: $count vardiya planlandı',
      one: 'Çizelge güncellendi: 1 vardiya planlandı',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Oluşturuldu: $count vardiya planlandı',
      one: 'Oluşturuldu: 1 vardiya planlandı',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'Çizelge oluşturulamadı: $error';
  }

  @override
  String get builderRosterImported => 'Çizelge takvimine aktarıldı';

  @override
  String builderCouldNotImport(String error) {
    return 'Çizelge içe aktarılamadı: $error';
  }

  @override
  String get blockAddTitle => 'Vardiya bloğu ekle';

  @override
  String get blockEditTitle => 'Vardiya bloğunu düzenle';

  @override
  String get blockStart => 'Başlangıç';

  @override
  String get blockEnd => 'Bitiş';

  @override
  String get blockTapDays => 'Bu vardiyanın kapsadığı günlere dokun';

  @override
  String get blockUntappedOff => 'Dokunulmayan günler izinlidir.';

  @override
  String blockOverlap(String ranges) {
    return 'Bu saat $ranges. günde başka bir vardiyayla çakışıyor: saati ya da o günleri değiştir.';
  }

  @override
  String get blockAdd => 'Blok ekle';

  @override
  String get blockSave => 'Bloğu kaydet';

  @override
  String get aiPromptCopied =>
      'Komut kopyalandı! Çizelgenle birlikte yapay zekâ uygulamana yapıştır.';

  @override
  String get aiNothingToPaste => 'Panoda yapıştırılacak bir şey yok.';

  @override
  String get aiNoValidShifts =>
      'Geçerli vardiya bulunamadı. Kopyalanan yapay zekâ komutunu kullandığından emin ol.';

  @override
  String get aiStep1 => 'Komutu kopyala';

  @override
  String get aiCopied => 'Kopyalandı!';

  @override
  String get aiCopyPrompt => 'Yapay zekâ komutunu kopyala';

  @override
  String get aiStep1Sub =>
      'ChatGPT, Gemini veya başka bir yapay zekâ uygulamasına yapıştır, çizelge metnini ya da fotoğraf/ekran görüntüsünü ekleyip gönder.';

  @override
  String get aiStep2 => 'Yapay zekânın yanıtını yapıştır';

  @override
  String get aiPaste => 'Yapıştır';

  @override
  String get aiParsePreview => 'Çözümle ve önizle';

  @override
  String get aiStep3 => 'Bulunan vardiyaları kontrol et';

  @override
  String get aiStep3Sub =>
      'Yapay zekâ yanlış yaptıysa etikete dokunarak Gündüz, Akşam ve Gece arasında geçiş yap.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count günü içe aktar',
      one: '1 günü içe aktar',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'Bir yapay zekâ uygulaması yardımıyla herhangi bir çizelge metnini vardiyalara dönüştür.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
      one: '1 gün',
    );
    return '$_temp0 · $working çalışma · $off izin';
  }

  @override
  String get draftReviewTitle => 'Taranan çizelgeyi incele';

  @override
  String draftRemovedDay(String date) {
    return '$date kaldırıldı';
  }

  @override
  String get draftUndo => 'Geri al';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çizelgene $count gün kaydedildi',
      one: 'Çizelgene 1 gün kaydedildi',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'Çizelge adı';

  @override
  String get draftScannedImage => 'Taranan görüntü';

  @override
  String get draftScannedImageSub =>
      'Büyütüp karşılaştırmak için görüntüye dokun';

  @override
  String get draftImageError => 'Taranan görüntü gösterilemedi.';

  @override
  String get draftRemove => 'Kaldır';

  @override
  String get draftNoEndTime =>
      'Bitiş saati olmadan tarandı: Kaydetmek için ayarla.';

  @override
  String get draftTime => 'Saat';

  @override
  String get draftSetEnd => 'Bitişi ayarla';

  @override
  String get draftConfirmSave => 'Onayla ve kaydet';

  @override
  String notifBeforeYourShift(String type) {
    return 'Vardiyandan önce ($type)';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind · $time';
  }

  @override
  String get notifWindDownTitle => 'Sakinleşme vakti 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'Ekranları bırak: Yatma saatin $time.';
  }

  @override
  String get notifWindDownBody =>
      'Ekranları bırak ve gece için sakinleşmeye başla.';

  @override
  String get notifBedtimeTitle => 'Yatma vakti 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return '$shift öncesi ~$hours sa uyku için yat: Uyanma $time.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return '$hours saatlik uyku hedefine ulaşmak için yat.';
  }

  @override
  String get notifShiftDay => 'gündüz vardiyası';

  @override
  String get notifShiftAfternoon => 'akşam vardiyası';

  @override
  String get notifShiftNight => 'gece vardiyası';

  @override
  String get notifShiftGeneric => 'vardiya';

  @override
  String get notifTrialEndsTitle => 'Rostrik denemen yarın bitiyor';

  @override
  String get notifTrialEndsBody =>
      'Vardiya alarmlarının çalmaya devam etmesi için tam erişimin kilidini aç.';

  @override
  String seedWakeUpLabel(String type) {
    return 'Uyanma ($type)';
  }

  @override
  String get seedShiftGeneric => 'Vardiya';

  @override
  String commonListAnd(String items, String last) {
    return '$items ve $last';
  }

  @override
  String get soundClassic => 'Klasik';

  @override
  String get soundSiren => 'Siren';

  @override
  String get soundDigital => 'Dijital';

  @override
  String get soundChime => 'Çan';

  @override
  String get patternFirstResponder => 'Acil servis standardı';

  @override
  String get ocrCropTitle => 'Tüm ekibi değil, SADECE kendi satırını kırp';

  @override
  String get draftNameHint => 'örn. Mayıs çizelgesi';
}
