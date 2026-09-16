// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'Zanim zaczniesz';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik powstał, żeby budzić cię na każdą zmianę. Uczciwie uprzedzamy: na każdym telefonie ostatnie słowo ma system operacyjny, a nie aplikacja. W rzadkich przypadkach może opóźnić lub wyciszyć każdą aplikację z budzikiem (agresywne oszczędzanie baterii, wymuszone zamknięcie lub zaraz po aktualizacji systemu).';

  @override
  String get legalBodyBackupAdvice =>
      'Na zmiany, których nie możesz przegapić, ustaw drugi budzik jako zapasowy. To dobra praktyka przy każdym budziku, także tym wbudowanym w telefon.';

  @override
  String get legalReviewAndAccept => 'Przeczytaj i zaakceptuj:';

  @override
  String get legalPrivacyPolicy => 'Polityka prywatności';

  @override
  String get legalTermsOfUse => 'Warunki korzystania';

  @override
  String get legalConsentCheckbox =>
      'Rozumiem, że system operacyjny może wpływać na każdą aplikację z budzikiem, i akceptuję Politykę prywatności oraz Warunki korzystania.';

  @override
  String get legalAgreeContinue => 'Akceptuję i dalej';

  @override
  String get commonSaving => 'Zapisywanie…';

  @override
  String get commonCouldNotOpenLink => 'Nie udało się otworzyć linku.';

  @override
  String get welcomeTagline => 'Inteligentny budzik dla pracujących na zmiany.';

  @override
  String get welcomeSubTagline =>
      'Budziki, które podążają za twoim grafikiem zmianowym, a nie tylko za dniami roboczymi.';

  @override
  String welcomeTrialTitle(int days) {
    return '$days dni za darmo';
  }

  @override
  String get welcomeTrialBody =>
      'Pełny dostęp do wszystkich funkcji, bez karty. Potem jednorazowy zakup, nigdy subskrypcja.';

  @override
  String get welcomeGetStarted => 'Zaczynamy';

  @override
  String get welcomeSkip => 'Pomiń / Skonfiguruj później';

  @override
  String get welcomeTimeFormat => 'Format godziny';

  @override
  String get welcomeWeekStarts => 'Początek tygodnia';

  @override
  String get common12h => '12 h';

  @override
  String get common24h => '24 h';

  @override
  String get commonSundayShort => 'Nd';

  @override
  String get commonMondayShort => 'Pn';

  @override
  String get rosterTypeTitle => 'Wybierz typ grafiku';

  @override
  String get rosterTypeQuestion => 'Jak wygląda twój grafik?';

  @override
  String get rosterTypeDay => 'Zmiany dzienne';

  @override
  String get rosterTypeNight => 'Zmiany nocne';

  @override
  String get rosterTypeRotating => 'Rotacyjny';

  @override
  String get rosterTypeCustom => 'Własny';

  @override
  String get commonContinue => 'Dalej';

  @override
  String get commonComingSoon => 'Wkrótce';

  @override
  String get permsTitle => 'Uprawnienia';

  @override
  String get permsIntro =>
      'Rostrik potrzebuje kilku uprawnień, żeby budziki dzwoniły niezawodnie. Możesz je później zmienić w ustawieniach systemu.';

  @override
  String get permsNotifications => 'Powiadomienia';

  @override
  String get permsNotificationsSub =>
      'Wymagane do wyświetlenia ekranu budzenia.';

  @override
  String get permsExactAlarms => 'Dokładne budziki';

  @override
  String get permsExactAlarmsSub =>
      'Pozwala budzikom dzwonić dokładnie o zaplanowanej godzinie.';

  @override
  String get permsBatteryUnrestricted => 'Bateria bez ograniczeń';

  @override
  String get permsBatteryGrantedSub =>
      'Budziki są chronione przed optymalizacją baterii.';

  @override
  String get permsBatteryDeniedSub =>
      'Niektóre telefony zamykają aplikacje w tle. Dotknij, aby naprawić.';

  @override
  String get permsUnrestrictedBadge => 'Bez ograniczeń';

  @override
  String get batteryDialogTitle => 'Utrzymaj budziki przy życiu';

  @override
  String get batteryDialogIntro =>
      'Niektóre telefony (Samsung, Xiaomi, Oppo, Huawei) agresywnie zamykają aplikacje w tle, żeby oszczędzać baterię. Jeśli spotka to Rostrik, budzik może nie zadzwonić.';

  @override
  String get batteryDialogMarkUnrestricted =>
      'Ustaw Rostrik na „Bez ograniczeń”, aby temu zapobiec:';

  @override
  String get batteryStep1 =>
      'Otwórz ustawienia tej aplikacji (przycisk poniżej).';

  @override
  String get batteryStep2 =>
      'Dotknij Bateria (lub „Użycie baterii przez aplikację”).';

  @override
  String get batteryStep3 =>
      'Wybierz „Bez ograniczeń” (nie „Zoptymalizowane” ani „Ograniczone”).';

  @override
  String get batteryStep4 =>
      'Jeśli widzisz „Zezwalaj na aktywność w tle”, też to włącz.';

  @override
  String get batteryStep5 =>
      'WYŁĄCZ „Wstrzymuj aktywność aplikacji, jeśli nieużywana” (lub „Usuń uprawnienia, jeśli aplikacja nie jest używana”), żeby Android nie odebrał uprawnień budzika pod twoją nieobecność.';

  @override
  String get commonNotNow => 'Nie teraz';

  @override
  String get batteryGoToSettings => 'Przejdź do ustawień';

  @override
  String get armEngineTitle => 'Włącz budziki';

  @override
  String get armEngineRosterReady => 'Twój grafik jest gotowy';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · od $date';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'Włączymy budziki ($summary) przed każdą pasującą zmianą.';
  }

  @override
  String get armEngineArming => 'Włączanie…';

  @override
  String get armEngineCta => 'Automatyzuj moje budziki';

  @override
  String get armEngineLeadTimeLabel => 'Wyprzedzenie budzika';

  @override
  String get armEngineLeadTimeHelper =>
      'Ile przed początkiem zmiany dzwoni budzik.';

  @override
  String get shiftTypeDay => 'Dzień';

  @override
  String get shiftTypeAfternoon => 'Popołudnie';

  @override
  String get shiftTypeNight => 'Noc';

  @override
  String get shiftTypeOff => 'Wolne';

  @override
  String get weekdaysNone => 'Brak dni';

  @override
  String get weekdaysEveryDay => 'Codziennie';

  @override
  String get weekdaysWeekdays => 'Dni robocze';

  @override
  String get weekdaysWeekends => 'Weekendy';

  @override
  String durationMin(int m) {
    return '$m min';
  }

  @override
  String durationH(int h) {
    return '$h godz.';
  }

  @override
  String durationHMin(int h, int m) {
    return '$h godz. $m min';
  }

  @override
  String durationMinShort(int m) {
    return '$m min';
  }

  @override
  String durationHShort(int h) {
    return '$h godz.';
  }

  @override
  String durationHMinShort(int h, int m) {
    return '$h godz. $m min';
  }

  @override
  String get commonClose => 'Zamknij';

  @override
  String get commonSkip => 'Pomiń';

  @override
  String get commonBack => 'Wstecz';

  @override
  String get commonDone => 'Gotowe';

  @override
  String get commonNext => 'Dalej';

  @override
  String get walkthroughIntroTitle => '60-sekundowy przewodnik';

  @override
  String get walkthroughIntroBodyTwo =>
      'Dwie rzeczy, dzięki którym Rostrik działa. Możesz pominąć w każdej chwili.';

  @override
  String get walkthroughIntroBodyOne =>
      'To, dzięki czemu Rostrik działa. Możesz pominąć w każdej chwili.';

  @override
  String get walkthroughPaintLabel => 'Namaluj grafik';

  @override
  String get walkthroughPaintDetail =>
      'Dotknij dni, w które pracujesz. Tak szybko.';

  @override
  String get walkthroughShakeLabel => 'Potrząśnij, aby wyłączyć';

  @override
  String get walkthroughShakeDetail =>
      'Mocne potrząśnięcie wyłącza budzik krytyczny.';

  @override
  String get walkthroughTryEach => 'Dotknij Dalej, aby wypróbować obie.';

  @override
  String get walkthroughTryIt => 'Dotknij Dalej, aby wypróbować.';

  @override
  String get walkthroughPaintBody =>
      'Dotknij dni, w które pracujesz. W prawdziwym edytorze tak samo dodasz kolejne bloki (popołudnia, noce).';

  @override
  String get walkthroughPaintPrompt =>
      'Dotknij dnia, aby namalować na nim zmianę dzienną.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Świetnie! Tych $count dni to blok dzienny. Niedotknięte dni zostają wolne. Proste.',
      many:
          'Świetnie! Tych $count dni to blok dzienny. Niedotknięte dni zostają wolne. Proste.',
      few:
          'Świetnie! Te $count dni to blok dzienny. Niedotknięte dni zostają wolne. Proste.',
      one:
          'Świetnie! Ten dzień to blok dzienny. Niedotknięte dni zostają wolne. Proste.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'Budziki zmian krytycznych wyłącza tylko mocne, ciągłe potrząsanie, więc zaspane dotknięcie nie wystarczy. Spróbuj: potrząśnij telefonem.';

  @override
  String get walkthroughShakeSuccess => 'Udało się!';

  @override
  String get walkthroughShakeSuccessDetail =>
      'Dokładnie tak wyłączysz budzik krytyczny.';

  @override
  String get walkthroughDoneTitle => 'Wszystko gotowe';

  @override
  String get walkthroughDoneBody =>
      'Grafik utworzysz w każdej chwili w zakładce Zarządzaj, a ten przewodnik znajdziesz w Ustawienia → Pomoc.';

  @override
  String get navDashboard => 'Pulpit';

  @override
  String get navTimeline => 'Oś czasu';

  @override
  String get navManage => 'Zarządzaj';

  @override
  String get navAlarms => 'Budziki';

  @override
  String get navSleep => 'Sen';

  @override
  String get onbPatternTitle => 'Wybierz rotację';

  @override
  String get purchaseTrialEnded => 'Twój darmowy okres się skończył';

  @override
  String get purchaseBody =>
      'Odblokuj Rostrik jednorazowo, żeby budziki na zmiany dalej dzwoniły. Twój grafik, budziki i ustawienia są bezpieczne i wrócą zaraz po odblokowaniu.';

  @override
  String get purchaseAlarmsWontRing => 'Do tego czasu budziki nie zadzwonią.';

  @override
  String get purchaseUnlock => 'Odblokuj pełny dostęp';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'Odblokuj pełny dostęp · $price';
  }

  @override
  String get purchaseRestore => 'Przywróć zakup';

  @override
  String get purchaseOneTime => 'Jednorazowy zakup. Bez subskrypcji.';

  @override
  String get purchaseUnavailable =>
      'Zakupy są teraz niedostępne. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get purchaseCheckingPrevious => 'Szukanie wcześniejszego zakupu…';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsLegalAbout => 'INFORMACJE PRAWNE';

  @override
  String get settingsHelp => 'POMOC';

  @override
  String get settingsHowItWorks => 'Jak to działa';

  @override
  String get settingsReplayTourShake =>
      'Obejrzyj przewodnik ponownie – malowanie grafiku + potrząśnij, aby wyłączyć';

  @override
  String get settingsReplayTour =>
      'Obejrzyj przewodnik ponownie – malowanie grafiku';

  @override
  String get settingsScreenTips => 'Pokazuj wskazówki';

  @override
  String get settingsScreenTipsSub =>
      'Jednorazowe wskazówki na każdym ekranie. Włącz, aby zobaczyć je znowu.';

  @override
  String get settingsFullAccess => 'PEŁNY DOSTĘP';

  @override
  String get settingsFullAccessUnlocked => 'Pełny dostęp odblokowany';

  @override
  String get settingsThanks => 'Dziękujemy za wsparcie Rostrik.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Darmowy okres – zostało $days dni',
      many: 'Darmowy okres – zostało $days dni',
      few: 'Darmowy okres – zostały $days dni',
      one: 'Darmowy okres – został 1 dzień',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'Darmowy okres zakończony';

  @override
  String get settingsUnlockPitch =>
      'Odblokuj raz, żeby budziki na zmiany dzwoniły po okresie próbnym – jednorazowy zakup, nigdy subskrypcja.';

  @override
  String get settingsRestore => 'Przywróć';

  @override
  String get settingsBrandTagline => 'Budziki poza godzinami biurowymi';

  @override
  String get settingsLeadTime => 'Wyprzedzenie';

  @override
  String get settingsLeadTimeSub =>
      'Budzik dzwoni z takim wyprzedzeniem przed każdą zmianą.';

  @override
  String get settingsSnoozeDuration => 'Czas drzemki';

  @override
  String get settingsSnoozeDurationSub =>
      'O ile przycisk Drzemka przesuwa dzwoniący budzik.';

  @override
  String get settingsMinutesLabel => 'Minuty';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m minut',
      many: '$m minut',
      few: '$m minuty',
      one: '1 minuta',
    );
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => 'CYKLE ZMIAN';

  @override
  String get settingsShiftCyclesSub =>
      'Grafiki utworzone z wzorca lub szablonu.';

  @override
  String get settingsAddShiftCycle => 'Dodaj cykl zmian';

  @override
  String get settingsNoRosters => 'Nie masz jeszcze żadnych grafików.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'Edytuj';

  @override
  String get commonDelete => 'Usuń';

  @override
  String get commonCancel => 'Anuluj';

  @override
  String get settingsDeleteRosterTitle => 'Usunąć grafik?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'zostanie usuniętych $count zmian',
      many: 'zostanie usuniętych $count zmian',
      few: 'zostaną usunięte $count zmiany',
      one: 'zostanie usunięta 1 zmiana',
    );
    return 'Usunąć „$label”? Oczekujące budziki zostaną anulowane i $_temp0.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return 'Usunięto „$label”';
  }

  @override
  String get commonActive => 'Aktywny';

  @override
  String get commonUpcoming => 'Nadchodzący';

  @override
  String get commonPast => 'Miniony';

  @override
  String get settingsWorkHistory => 'HISTORIA PRACY';

  @override
  String get settingsWorkHistorySub =>
      'Przeglądaj i eksportuj zakończone zmiany dodatkowe, żeby sprawdzić paski wypłat.';

  @override
  String get settingsViewWorkHistory => 'Zobacz i eksportuj historię';

  @override
  String get settingsPreferences => 'PREFERENCJE';

  @override
  String get settingsPreferencesSub =>
      'Jak twój grafik wyświetla się w aplikacji.';

  @override
  String get settingsAppearance => 'Wygląd';

  @override
  String get settingsThemeSystem => 'Systemowy';

  @override
  String get settingsThemeLight => 'Jasny';

  @override
  String get settingsThemeDark => 'Ciemny';

  @override
  String get settingsThemeSub =>
      'Ciemny to domyślny motyw Rostrik. Jasny ma ciepłą, kremową paletę.';

  @override
  String get settings24h => 'Format 24-godzinny';

  @override
  String get settings24hOn => 'Godziny wyświetlane jako 14:30';

  @override
  String get settings24hOff => 'Godziny wyświetlane jako 02:30 PM';

  @override
  String get settingsWeekStartTitle => 'Zaczynaj kalendarz od poniedziałku';

  @override
  String get settingsWeekStartMon => 'Tydzień zaczyna się w poniedziałek';

  @override
  String get settingsWeekStartSun => 'Tydzień zaczyna się w niedzielę';

  @override
  String get settingsTimelineOpensOn => 'Oś czasu otwiera się w widoku';

  @override
  String get commonList => 'Lista';

  @override
  String get commonMonth => 'Miesiąc';

  @override
  String get settingsCalendar => 'KALENDARZ';

  @override
  String get settingsCalendarSync =>
      'Synchronizuj z Google / kalendarzem urządzenia';

  @override
  String get settingsCalendarSyncSub =>
      'Automatycznie kopiuje twoje zmiany do osobnego kalendarza „Rostrik Roster” w telefonie.';

  @override
  String get settingsCalSyncOff =>
      'Synchronizacja wyłączona. Nadchodzące wydarzenia „Rostrik Roster” zostały usunięte.';

  @override
  String get settingsCalSyncMirroring =>
      'Kopiowanie grafiku do kalendarza „Rostrik Roster”…';

  @override
  String get settingsCalPermNeeded =>
      'Do synchronizacji grafiku potrzebny jest dostęp do kalendarza.';

  @override
  String get settingsCalBlocked =>
      'Dostęp do kalendarza jest zablokowany. Włącz go w ustawieniach systemu.';

  @override
  String get settingsCalOpenSettings => 'Ustawienia';

  @override
  String get settingsCalUnsupported =>
      'Synchronizacja kalendarza nie jest dostępna na tym urządzeniu.';

  @override
  String get settingsDangerZone => 'STREFA ZAGROŻENIA';

  @override
  String get settingsDangerZoneSub =>
      'Usuwa grafik, budziki i ustawienia, a potem zaczyna konfigurację od nowa.';

  @override
  String get settingsResetAppData => 'Zresetuj dane aplikacji';

  @override
  String get settingsResetTitle => 'Zresetować aplikację?';

  @override
  String get settingsResetBody =>
      'Na pewno? Twój grafik, budziki i ustawienia zostaną usunięte.';

  @override
  String get settingsResetConfirm => 'Resetuj';

  @override
  String get dashNoUpcomingShifts => 'Brak nadchodzących zmian';

  @override
  String get dashEnjoyTimeOff => 'Miłego wolnego.';

  @override
  String get dashInProgress => 'W TRAKCIE';

  @override
  String get dashRotation => 'Rotacja';

  @override
  String get dashAlarmsCantRing => 'Budziki nie mogą dzwonić niezawodnie';

  @override
  String get dashNotifsOffIssue =>
      'Powiadomienia są wyłączone – dzwoniący budzik nie pokaże ekranu budzenia i nie da się go wyłączyć.';

  @override
  String get dashOpenSettings => 'Otwórz ustawienia';

  @override
  String get dashExactBlockedIssue =>
      'Dokładne budziki są zablokowane – nie da się zaplanować żadnej pobudki.';

  @override
  String get dashAlarmsWontTakeOverScreen => 'Alarmy nie przejmą ekranu';

  @override
  String get dashFullScreenBlockedIssue =>
      'Alarmy pełnoekranowe są wyłączone — na zablokowanym telefonie zobaczysz powiadomienie zamiast ekranu alarmu.';

  @override
  String get dashAllow => 'Zezwól';

  @override
  String get dashSlideToSkip => 'Przesuń, aby pominąć ten budzik';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Przesuń aby pominąć $count budzików',
      many: 'Przesuń aby pominąć $count budzików',
      few: 'Przesuń aby pominąć $count budziki',
      one: 'Przesuń aby pominąć budzik',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'Wyłącz nadchodzący budzik · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pomiń $count budzików tej zmiany',
      many: 'Pomiń $count budzików tej zmiany',
      few: 'Pomiń $count budziki tej zmiany',
      one: 'Pomiń budzik tej zmiany',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'Zachowaj budzik';

  @override
  String get dashMyRotation => 'Moja rotacja';

  @override
  String get dashCalendarUpcoming => 'Kalendarz i nadchodzące zmiany';

  @override
  String get dashNextShifts => 'Następne zmiany';

  @override
  String get dashOpenTimeline => 'Otwórz oś czasu';

  @override
  String heroStartsIn(String countdown) {
    return 'Za $countdown';
  }

  @override
  String heroEndsIn(String countdown) {
    return 'Koniec za $countdown';
  }

  @override
  String get heroStartsInPrefix => 'Za';

  @override
  String get heroEndsInPrefix => 'Koniec za';

  @override
  String heroStartsTodayAt(String time) {
    return 'Zaczyna się dziś o $time';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'Zaczęła się dziś o $time';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'Zaczyna się jutro o $time';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'Zaczęła się wczoraj o $time';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'Zaczyna się wczoraj o $time';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return 'Zaczyna się $date o $time';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return 'Zaczęła się $date o $time';
  }

  @override
  String get shiftTypeDayShift => 'Zmiana dzienna';

  @override
  String get shiftTypeAfternoonShift => 'Zmiana popołudniowa';

  @override
  String get shiftTypeNightShift => 'Zmiana nocna';

  @override
  String heroDayXofY(int x, int y, String label) {
    return 'Dzień $x z $y – $label';
  }

  @override
  String get heroOffTomorrow => 'Jutro wolne';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Wolne za $days dni',
      many: 'Wolne za $days dni',
      few: 'Wolne za $days dni',
      one: 'Wolne za 1 dzień',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'Jutro wracasz do pracy';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Powrót do pracy za $days dni',
      many: 'Powrót do pracy za $days dni',
      few: 'Powrót do pracy za $days dni',
      one: 'Powrót do pracy za 1 dzień',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'Wolne';

  @override
  String durationDayShort(int d) {
    return '$d d.';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d d. $h godz.';
  }

  @override
  String get alarmsTitle => 'Budziki';

  @override
  String get alarmsAddTooltip => 'Dodaj budzik';

  @override
  String get alarmsSortTooltip => 'Sortuj budziki';

  @override
  String get alarmsSortByTime => 'Według godziny';

  @override
  String get alarmsSortByShiftType => 'Według typu zmiany';

  @override
  String get alarmsEmptyTitle => 'Brak budzików.';

  @override
  String get alarmsEmptyBody => 'Dotknij +, aby dodać.';

  @override
  String get alarmsNextAlarm => 'NASTĘPNY BUDZIK';

  @override
  String get alarmsHolidayMode => 'Tryb urlopowy';

  @override
  String get alarmsHolidayModeSub => 'Budziki wstrzymane – nic nie zadzwoni.';

  @override
  String get alarmsNoUpcoming => 'Brak nadchodzącego budzika na zmianę';

  @override
  String get alarmsNoUpcomingSub =>
      'Dodaj budzik podążający za rotacją albo utwórz grafik.';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'na twoją zmianę ($type) · $day';
  }

  @override
  String get commonToday => 'Dziś';

  @override
  String get commonTomorrow => 'Jutro';

  @override
  String get alarmsOffWontRing => 'Wyłączony – nie zadzwoni';

  @override
  String get alarmsNoUpcomingRing => 'Brak zaplanowanego dzwonienia';

  @override
  String alarmsNextRing(String day, String time) {
    return 'Następnie: $day o $time';
  }

  @override
  String get alarmsSwipeToDelete => 'Przesuń, aby usunąć';

  @override
  String get alarmsRingsOnceAutoDelete => 'Dzwoni raz · usuwa się sam';

  @override
  String get alarmsRingsOnce => 'Dzwoni tylko raz';

  @override
  String get alarmsYourShift => 'Twoja zmiana';

  @override
  String alarmsShiftsOfType(String type) {
    return 'Zmiany ($type)';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'Dokładna godzina · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$shift: $lead wcześniej · domyślnie';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$shift: $lead wcześniej';
  }

  @override
  String get createEditAlarm => 'Edytuj budzik';

  @override
  String get createNewAlarm => 'Nowy budzik';

  @override
  String get createDefaultLabel => 'Pobudka';

  @override
  String get createFallbackLabel => 'Budzik';

  @override
  String get createPickBecomesDefault =>
      'Twój wybór stanie się domyślny dla nowych budzików.';

  @override
  String get createSelectFromFiles => 'Wybierz z Plików';

  @override
  String get createFilesSub => 'Wybierz plik audio zapisany na urządzeniu';

  @override
  String get createSelectSystemTone => 'Wybierz dźwięk systemowy';

  @override
  String get createSystemToneSub =>
      'Wybierz spośród dźwięków budzika urządzenia';

  @override
  String get createAlarmTiming => 'Moment budzika';

  @override
  String get createLeadTimeMode => 'Wyprzedzenie';

  @override
  String get createExactTimeMode => 'Dokładna godzina';

  @override
  String createFiresAt(String time) {
    return 'Dzwoni o $time';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return '$lead przed początkiem zmiany';
  }

  @override
  String get createLinkedShift => 'Powiązana zmiana';

  @override
  String get createRepeatOn => 'Powtarzaj w';

  @override
  String get createLabelField => 'Nazwa';

  @override
  String get createLabelHint => 'np. Pobudka';

  @override
  String get createCriticalShift => 'Zmiana krytyczna';

  @override
  String get createCriticalShiftSub =>
      'Potrząśnij, aby wyłączyć · awaryjnie przytrzymaj 3 s';

  @override
  String get createRingtone => 'Dźwięk';

  @override
  String get commonStop => 'Stop';

  @override
  String get commonPlay => 'Odtwórz';

  @override
  String get createVibrate => 'Wibracje';

  @override
  String get createRepeat => 'Powtarzaj';

  @override
  String get createRepeatRotation => 'Rotacja';

  @override
  String get createRepeatWeekly => 'Co tydzień';

  @override
  String get createRepeatOneTime => 'Raz';

  @override
  String get createPickOneDay => 'Wybierz co najmniej jeden dzień';

  @override
  String get commonSave => 'Zapisz';

  @override
  String get commonSaveChanges => 'Zapisz zmiany';

  @override
  String get createTimeBeforeShift => 'Czas przed zmianą';

  @override
  String get commonOk => 'OK';

  @override
  String get sleepTitle => 'Sen';

  @override
  String get sleepTargetHeader => 'CEL SNU';

  @override
  String get sleepTargetSub =>
      'Ile godzin chcesz spać. Rostrik liczy wstecz od następnego budzika, żeby ustalić dzisiejszą porę snu.';

  @override
  String get sleepRemindersHeader => 'PRZYPOMNIENIA';

  @override
  String get sleepWindDownHeader => 'CZAS NA WYCISZENIE';

  @override
  String get sleepWindDownSub =>
      'Ile przed snem przyjdzie przypomnienie o wyciszeniu.';

  @override
  String get sleepSoundsHeader => 'DŹWIĘKI DO SNU';

  @override
  String get sleepSoundsSub =>
      'Biały i brązowy szum do zasypiania. Wybierz wyłącznik czasowy i dotknij dźwięku.';

  @override
  String get sleepNothingToPlan => 'Dziś nie ma czego planować';

  @override
  String get sleepNothingToPlanSub =>
      'Dodaj zmianę do grafiku, a Rostrik ustali porę snu dopasowaną do następnej pobudki.';

  @override
  String get sleepTransitionDay => 'DZIEŃ PRZEJŚCIOWY';

  @override
  String get sleepTransitionTitle => 'Jutro zmiana nocna. Możesz się wyspać.';

  @override
  String get sleepTransitionBody =>
      'To dzień przejściowy – przed nocami masz wolne, więc nie ma wczesnego budzika. Odpocznij teraz na zapas i pozwól sobie dziś położyć się później.';

  @override
  String get sleepRestRecovery => 'ODPOCZYNEK I REGENERACJA';

  @override
  String get sleepNoEarlyAlarm => 'Bez wczesnego budzika';

  @override
  String get sleepRestBody =>
      'Następna zmiana jest za ponad dobę, więc dziś nie ma pobudki do planowania. Śpij we własnym rytmie i regeneruj się – Rostrik przygotuje plan, gdy zmiana się zbliży.';

  @override
  String get sleepTonightsPlan => 'PLAN NA DZIŚ';

  @override
  String get sleepTargetBedtime => 'Pora snu';

  @override
  String get sleepWindDownStat => 'Wyciszenie';

  @override
  String get sleepWakeUpStat => 'Pobudka';

  @override
  String get sleepDurationStat => 'Czas';

  @override
  String get sleepBedtimeReminder => 'Przypomnienie o śnie';

  @override
  String sleepNudgeAtBedtime(String time) {
    return 'Przypomnij mi o $time, żeby iść spać';
  }

  @override
  String get sleepBedtimeSub => 'Przypomnienie, gdy czas iść do łóżka';

  @override
  String get sleepWindDownReminder => 'Przypomnienie o wyciszeniu';

  @override
  String sleepNudgeAtWindDown(String time) {
    return 'Przypomnij mi o $time, żeby się wyciszyć';
  }

  @override
  String get sleepWindDownReminderSub =>
      'Wcześniejsze przypomnienie o wyciszeniu';

  @override
  String get commonOff => 'Wył.';

  @override
  String get sleepSoundWhiteNoise => 'Biały szum';

  @override
  String get sleepSoundPinkNoise => 'Różowy szum';

  @override
  String get sleepSoundBrownNoise => 'Brązowy szum';

  @override
  String get sleepSoundFan => 'Wentylator';

  @override
  String get sleepSoundOcean => 'Ocean';

  @override
  String get sleepSoundRain => 'Deszcz';

  @override
  String get manageTitle => 'Zarządzaj';

  @override
  String get manageRosterTools => 'NARZĘDZIA GRAFIKU';

  @override
  String get manageRosterToolsSub =>
      'Twórz i zmieniaj zmiany, które sterują budzikami i planem snu.';

  @override
  String get manageGenerateRotation => 'Utwórz rotację';

  @override
  String get manageGenerateRotationSub =>
      'Zbuduj powtarzalny wzór zmian z szablonu.';

  @override
  String get manageAddCustomShift => 'Dodaj pojedynczą zmianę';

  @override
  String get manageAddCustomShiftSub =>
      'Wstaw jedną dodatkową zmianę do grafiku.';

  @override
  String get manageMarkLeave => 'Oznacz urlop / wolne';

  @override
  String get manageMarkLeaveSub =>
      'Zaznacz naraz dni wolne (urlop, zwolnienie).';

  @override
  String get managePauseSchedule => 'Wstrzymaj grafik';

  @override
  String get managePausedSub =>
      'Tryb urlopowy WŁĄCZONY – budziki wyciszone, grafik bezpieczny.';

  @override
  String get manageNotPausedSub =>
      'Tryb urlopowy – wycisz budziki, gdy nie masz zmian.';

  @override
  String get markLeaveTitle => 'Oznacz urlop';

  @override
  String get markLeaveIntro =>
      'Dotknij dni wolnych, wybierz powód i zatwierdź. Budziki w te dni nie zadzwonią, a grafik zostanie nienaruszony.';

  @override
  String get leaveAnnual => 'Urlop wypoczynkowy';

  @override
  String get leaveSick => 'Zwolnienie lekarskie';

  @override
  String get leavePublicHoliday => 'Święto';

  @override
  String get markLeaveReason => 'Powód';

  @override
  String get markLeaveFallbackReason => 'urlop';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Oznaczono $count zmian jako: $reason.',
      many: 'Oznaczono $count zmian jako: $reason.',
      few: 'Oznaczono $count zmiany jako: $reason.',
      one: 'Oznaczono 1 zmianę jako: $reason.',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => 'Wybierz dni do oznaczenia';

  @override
  String get markLeaveNoShifts => 'Brak zmian w te dni';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zastosuj do $count zmian',
      many: 'Zastosuj do $count zmian',
      few: 'Zastosuj do $count zmian',
      one: 'Zastosuj do 1 zmiany',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => 'Historia pracy';

  @override
  String get workHistoryExportTooltip => 'Eksportuj historię';

  @override
  String workHistoryExportFailed(String error) {
    return 'Nie udało się wyeksportować historii: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count przepracowanych zmian',
      many: '$count przepracowanych zmian',
      few: '$count przepracowane zmiany',
      one: '1 przepracowana zmiana',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours godz.';
  }

  @override
  String get commonPaused => 'Wstrzymana';

  @override
  String workHistoryPausedReason(String reason) {
    return 'Wstrzymana · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'Rotacja';

  @override
  String get workHistoryAdHocBadge => 'Dodatkowa';

  @override
  String get workHistoryEmptyTitle => 'Brak zakończonych zmian';

  @override
  String get workHistoryEmptyBody =>
      'Przepracowane zmiany – z rotacji i dodatkowe – pojawią się tu po zakończeniu, gotowe do eksportu i sprawdzenia paska wypłaty.';

  @override
  String get workHistoryShareSubject => 'Historia pracy Rostrik';

  @override
  String get workHistoryShareText =>
      'Moja historia pracy wyeksportowana z Rostrik.';

  @override
  String get shiftEdAddShift => 'Dodaj zmianę';

  @override
  String get shiftEdEditShift => 'Edytuj zmianę';

  @override
  String get shiftEdDate => 'Data';

  @override
  String get shiftEdPickDate => 'Wybierz datę';

  @override
  String get shiftEdStarts => 'Początek';

  @override
  String get shiftEdEnds => 'Koniec';

  @override
  String get shiftEdPickTime => 'Wybierz godzinę';

  @override
  String get shiftEdEndsNextDay => 'Kończy się następnego dnia';

  @override
  String get shiftEdPauseTitle => 'Wstrzymaj / odwołaj tę zmianę';

  @override
  String get shiftEdPausedSub =>
      'Budzik nie zadzwoni. Zmiana zostanie w kalendarzu jako wpis.';

  @override
  String get shiftEdNotPausedSub =>
      'Oznacz dzień wolny (zwolnienie, urlop, święto) bez usuwania go.';

  @override
  String get shiftEdReasonOptional => 'Powód (opcjonalnie)';

  @override
  String get dayShifts => 'Zmiany';

  @override
  String get dayActivities => 'Aktywności';

  @override
  String get dayAddAnotherShift => 'Dodaj kolejną zmianę';

  @override
  String get dayAddActivity => 'Dodaj aktywność';

  @override
  String get dayAddActivitySub => 'Wydarzenie, zadanie lub urodziny';

  @override
  String get dayReminder => 'Przypomnienie';

  @override
  String get actEditActivity => 'Edytuj aktywność';

  @override
  String get actLeadAtTime => 'O czasie';

  @override
  String get actLead10Min => '10 min wcześniej';

  @override
  String get actLead30Min => '30 min wcześniej';

  @override
  String get actLead1Hour => '1 godz. wcześniej';

  @override
  String get actLead1Day => '1 dzień wcześniej';

  @override
  String get actEvent => 'Wydarzenie';

  @override
  String get actTask => 'Zadanie';

  @override
  String get actBirthday => 'Urodziny';

  @override
  String get actTitleField => 'Tytuł';

  @override
  String get actAllDay => 'Cały dzień';

  @override
  String get actTimeField => 'Godzina';

  @override
  String get actRemindMe => 'Przypomnij mi';

  @override
  String get actRemindMeSub =>
      'Delikatne powiadomienie – niezależne od budzików na zmiany.';

  @override
  String get actRemindAt => 'Przypomnij o';

  @override
  String get actReminderPassed =>
      'Ta godzina już minęła – to przypomnienie się nie pojawi.';

  @override
  String get actNoteOptional => 'Notatka (opcjonalnie)';

  @override
  String get actCompleted => 'Ukończone';

  @override
  String get tipDashboardTitle => 'Twój pulpit';

  @override
  String get tipDashboardBody =>
      'Twoja baza. Zobacz następną zmianę z odliczaniem na żywo i miejsce w rotacji. Dotknij kafelka, aby zobaczyć szczegóły.';

  @override
  String get tipTimelineTitle => 'Cały twój grafik';

  @override
  String get tipTimelineBody =>
      'Na górze przełączaj między listą a kalendarzem miesięcznym. Dotknij dnia, aby edytować zmianę albo dodać wydarzenie, zadanie lub urodziny.';

  @override
  String get tipManageTitle => 'Twórz i zmieniaj';

  @override
  String get tipManageBody =>
      'Utwórz grafik rotacyjny, dodaj pojedynczą zmianę (nadgodziny) lub wstrzymaj cały grafik na urlop – wszystko tutaj.';

  @override
  String get tipAlarmsTitle => 'Twoje budziki';

  @override
  String get tipAlarmsBody =>
      'Wszystkie budziki tworzone przez zmiany i te dodane przez ciebie. Dotknij budzika, aby zmienić godzinę lub dźwięk, albo zrób z niego budzik zmiany krytycznej wyłączany potrząśnięciem.';

  @override
  String get tipSleepTitle => 'Plan snu';

  @override
  String get tipSleepBody =>
      'Plan wyciszenia, który podąża za grafikiem: ustaw cel snu i przyjdź wypoczęty na następną zmianę.';

  @override
  String get tipReplayHint =>
      'Obejrzysz je znowu w Ustawienia › Jak to działa.';

  @override
  String get tipDontShow => 'Nie pokazuj wskazówek';

  @override
  String get tipGotIt => 'Rozumiem';

  @override
  String get timelineListView => 'Lista';

  @override
  String get timelineMonthView => 'Miesiąc';

  @override
  String get shiftTypeAftShort => 'Pop.';

  @override
  String get timelineNoShifts =>
      'Brak zaplanowanych zmian. Dotknij +, aby dodać.';

  @override
  String timelineNoMatch(String filter) {
    return 'Brak zmian dla filtra „$filter”.';
  }

  @override
  String get timelineRestDay => 'Dzień wolny';

  @override
  String timelineRestDayReason(String reason) {
    return 'Dzień wolny · $reason';
  }

  @override
  String get timelineAllDay => 'Cały dzień';

  @override
  String get calLegendPausedLeave => 'Wstrzymane / Urlop';

  @override
  String get calLegendActivity => 'Aktywność';

  @override
  String get filterAll => 'Wszystkie';

  @override
  String get filterWork => 'Praca';

  @override
  String get criticalHoldToDismiss => 'Lub przytrzymaj, aby wyłączyć';

  @override
  String get patternChoosePattern => 'Wybierz wzór';

  @override
  String get patternRotatingSwings => 'Rotacje mieszane';

  @override
  String get patternDaySwings => 'Tylko dzienne';

  @override
  String get patternNightSwings => 'Tylko nocne';

  @override
  String get patternShiftTimes => 'Godziny zmian';

  @override
  String get patternGenerate => 'Ustaw dzień 1 i utwórz';

  @override
  String get patternSelectDay1 => 'Wybierz najbliższy dzień 1';

  @override
  String patternDay1Hint(String label) {
    return 'Pierwszy dzień bloku ($label)';
  }

  @override
  String get patternNextDay1 => 'Najbliższy dzień 1';

  @override
  String get patternUseThisDate => 'Użyj tej daty';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Utworzono $count zmian',
      many: 'Utworzono $count zmian',
      few: 'Utworzono $count zmiany',
      one: 'Utworzono 1 zmianę',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'Nie udało się utworzyć: $error';
  }

  @override
  String get patternFirstBlockFallback => 'pierwszego';

  @override
  String get patternBuildCustom => 'Utwórz własny grafik';

  @override
  String get patternBuildCustomSub =>
      'Żaden szablon nie pasuje? Złóż własne bloki.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dni',
      many: '$n dni',
      few: '$n dni',
      one: '1 dzień',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n popołudni',
      many: '$n popołudni',
      few: '$n popołudnia',
      one: '1 popołudnie',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nocy',
      many: '$n nocy',
      few: '$n noce',
      one: '1 noc',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '$n wolne';
  }

  @override
  String get builderNewRoster => 'Nowy grafik zmian';

  @override
  String get builderEditRoster => 'Edytuj grafik';

  @override
  String get builderNewSub => 'Ustaw swój wzór rotacji';

  @override
  String get builderEditSub => 'Zmień i zastąp ten zapisany grafik';

  @override
  String get builderNameHint => 'Nazwa grafiku (np. Moja rotacja 14-dniowa)';

  @override
  String get builderCycleLength => 'DŁUGOŚĆ CYKLU';

  @override
  String get builderStartDate => 'DATA ROZPOCZĘCIA';

  @override
  String get builderShiftBlocks => 'BLOKI ZMIAN';

  @override
  String get builderAddShiftBlock => 'Dodaj blok zmian';

  @override
  String get builderCreateRoster => 'Utwórz grafik';

  @override
  String get builderSaveChanges => 'Zapisz zmiany';

  @override
  String get builderReplaceWarning =>
      'Zapisanie zastąpi ten grafik. Oznaczone na nim urlopy i dni wolne zostaną zresetowane.';

  @override
  String get builderBackToOptions => 'Wróć do opcji';

  @override
  String get builderOrImport => 'LUB ZAIMPORTUJ ISTNIEJĄCY GRAFIK';

  @override
  String get builderImportViaAi => 'Importuj przez AI';

  @override
  String get builderScanning => 'Skanowanie…';

  @override
  String get builderScanInstead => 'Zeskanuj zdjęcie grafiku';

  @override
  String get builderCustomChip => 'Inna';

  @override
  String get builderCycleLengthLabel => 'Długość cyklu';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dni',
      many: '$n dni',
      few: '$n dni',
      one: '1 dzień',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'Wybierz datę';

  @override
  String get builderNoBlocksYet => 'Brak bloków';

  @override
  String get builderNoBlocksSub => 'Dodaj bloki zmian, aby ustalić rotację';

  @override
  String builderDaysLine(String ranges) {
    return 'Dni $ranges';
  }

  @override
  String get builderEditBlock => 'Edytuj blok';

  @override
  String get builderRemoveBlock => 'Usuń blok';

  @override
  String get builderPickRosterStart => 'Wybierz datę rozpoczęcia grafiku';

  @override
  String get builderPickScanStart =>
      'Wybierz datę rozpoczęcia zeskanowanego grafiku';

  @override
  String get builderScanCamera => 'Skanuj aparatem';

  @override
  String get builderImportScreenshot => 'Importuj zrzut ekranu';

  @override
  String builderScanFailed(String error) {
    return 'Skanowanie nie powiodło się: $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'Nie rozpoznano godzin. Spróbuj przyciąć zdjęcie ciaśniej wokół tabeli.';

  @override
  String get builderCustomRosterFallback => 'Własny grafik';

  @override
  String get builderScannedRosterFallback => 'Zeskanowany grafik';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Grafik zaktualizowany – zaplanowano $count zmian',
      many: 'Grafik zaktualizowany – zaplanowano $count zmian',
      few: 'Grafik zaktualizowany – zaplanowano $count zmiany',
      one: 'Grafik zaktualizowany – zaplanowano 1 zmianę',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Utworzono – zaplanowano $count zmian',
      many: 'Utworzono – zaplanowano $count zmian',
      few: 'Utworzono – zaplanowano $count zmiany',
      one: 'Utworzono – zaplanowano 1 zmianę',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'Nie udało się utworzyć grafiku: $error';
  }

  @override
  String get builderRosterImported => 'Grafik zaimportowany do kalendarza';

  @override
  String builderCouldNotImport(String error) {
    return 'Nie udało się zaimportować grafiku: $error';
  }

  @override
  String get blockAddTitle => 'Dodaj blok zmian';

  @override
  String get blockEditTitle => 'Edytuj blok zmian';

  @override
  String get blockStart => 'Początek';

  @override
  String get blockEnd => 'Koniec';

  @override
  String get blockTapDays => 'Dotknij dni tej zmiany';

  @override
  String get blockUntappedOff => 'Niedotknięte dni są wolne.';

  @override
  String blockOverlap(String ranges) {
    return 'Ta godzina nachodzi na inną zmianę w dniu $ranges – zmień godzinę lub te dni.';
  }

  @override
  String get blockAdd => 'Dodaj blok';

  @override
  String get blockSave => 'Zapisz blok';

  @override
  String get aiPromptCopied =>
      'Skopiowano polecenie! Wklej je do aplikacji AI razem z grafikiem.';

  @override
  String get aiNothingToPaste => 'Schowek jest pusty.';

  @override
  String get aiNoValidShifts =>
      'Nie wykryto poprawnych zmian. Upewnij się, że użyto skopiowanego polecenia AI.';

  @override
  String get aiStep1 => 'Skopiuj polecenie';

  @override
  String get aiCopied => 'Skopiowano!';

  @override
  String get aiCopyPrompt => 'Kopiuj polecenie AI';

  @override
  String get aiStep1Sub =>
      'Wklej je do ChatGPT, Gemini lub innej aplikacji AI, dodaj tekst grafiku albo zdjęcie/zrzut ekranu i wyślij.';

  @override
  String get aiStep2 => 'Wklej odpowiedź AI';

  @override
  String get aiPaste => 'Wklej';

  @override
  String get aiParsePreview => 'Analizuj i podejrzyj';

  @override
  String get aiStep3 => 'Sprawdź wykryte zmiany';

  @override
  String get aiStep3Sub =>
      'Dotknij etykiety, aby przełączyć Dzień, Popołudnie i Noc, jeśli AI się pomyliło.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importuj $count dni',
      many: 'Importuj $count dni',
      few: 'Importuj $count dni',
      one: 'Importuj 1 dzień',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'Zamień dowolny tekst grafiku na zmiany z pomocą aplikacji AI.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dni',
      many: '$count dni',
      few: '$count dni',
      one: '1 dzień',
    );
    return '$_temp0 · pracujące: $working · wolne: $off';
  }

  @override
  String get draftReviewTitle => 'Sprawdź zeskanowany grafik';

  @override
  String draftRemovedDay(String date) {
    return 'Usunięto $date';
  }

  @override
  String get draftUndo => 'Cofnij';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zapisano $count dni w grafiku',
      many: 'Zapisano $count dni w grafiku',
      few: 'Zapisano $count dni w grafiku',
      one: 'Zapisano 1 dzień w grafiku',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'Nazwa grafiku';

  @override
  String get draftScannedImage => 'Zeskanowany obraz';

  @override
  String get draftScannedImageSub =>
      'Dotknij obrazu, aby powiększyć i porównać';

  @override
  String get draftImageError =>
      'Nie udało się wyświetlić zeskanowanego obrazu.';

  @override
  String get draftRemove => 'Usuń';

  @override
  String get draftNoEndTime =>
      'Zeskanowano bez godziny końca – ustaw ją, aby zapisać.';

  @override
  String get draftTime => 'Godzina';

  @override
  String get draftSetEnd => 'Ustaw koniec';

  @override
  String get draftConfirmSave => 'Potwierdź i zapisz';

  @override
  String notifBeforeYourShift(String type) {
    return 'Przed twoją zmianą ($type)';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind o $time';
  }

  @override
  String get notifWindDownTitle => 'Czas się wyciszyć 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'Odłóż ekrany – pora snu o $time.';
  }

  @override
  String get notifWindDownBody =>
      'Odłóż ekrany i zacznij wyciszać się przed nocą.';

  @override
  String get notifBedtimeTitle => 'Pora spać 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return 'Idź spać, żeby przespać ~$hours godz. przed zmianą ($shift) – pobudka o $time.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return 'Idź spać, żeby osiągnąć cel $hours godz. snu.';
  }

  @override
  String get notifShiftDay => 'dzienna';

  @override
  String get notifShiftAfternoon => 'popołudniowa';

  @override
  String get notifShiftNight => 'nocna';

  @override
  String get notifShiftGeneric => 'zmiana';

  @override
  String get notifTrialEndsTitle =>
      'Twój okres próbny Rostrik kończy się jutro';

  @override
  String get notifTrialEndsBody =>
      'Odblokuj pełny dostęp, żeby budziki na zmiany dalej dzwoniły.';

  @override
  String seedWakeUpLabel(String type) {
    return 'Pobudka ($type)';
  }

  @override
  String get seedShiftGeneric => 'Zmiana';

  @override
  String commonListAnd(String items, String last) {
    return '$items i $last';
  }

  @override
  String get soundClassic => 'Klasyczny';

  @override
  String get soundSiren => 'Syrena';

  @override
  String get soundDigital => 'Cyfrowy';

  @override
  String get soundChime => 'Dzwonki';

  @override
  String get patternFirstResponder => 'Standard ratowniczy';

  @override
  String get ocrCropTitle => 'Przytnij TYLKO swój wiersz, nie cały zespół';

  @override
  String get draftNameHint => 'np. Grafik na maj';
}
