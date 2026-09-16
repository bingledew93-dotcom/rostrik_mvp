// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'Voordat je begint';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik is gemaakt om je voor elke dienst wakker te maken. Eerlijk is eerlijk: op elke telefoon heeft het besturingssysteem – niet de app – het laatste woord, en in zeldzame gevallen kan het elke wekker-app vertragen of stilzetten (agressieve batterijbesparing, geforceerd stoppen of vlak na systeemupdates).';

  @override
  String get legalBodyBackupAdvice =>
      'Voor diensten die je echt niet mag missen: zet een tweede wekker als back-up. Dat is slim bij elke wekker, ook bij die van je telefoon.';

  @override
  String get legalReviewAndAccept => 'Lees en accepteer:';

  @override
  String get legalPrivacyPolicy => 'Privacybeleid';

  @override
  String get legalTermsOfUse => 'Gebruiksvoorwaarden';

  @override
  String get legalConsentCheckbox =>
      'Ik begrijp dat het besturingssysteem elke wekker-app kan beïnvloeden, en ik accepteer het privacybeleid en de gebruiksvoorwaarden.';

  @override
  String get legalAgreeContinue => 'Akkoord en doorgaan';

  @override
  String get commonSaving => 'Opslaan…';

  @override
  String get commonCouldNotOpenLink => 'De link kan niet worden geopend.';

  @override
  String get welcomeTagline => 'De slimme wekker voor ploegendienst.';

  @override
  String get welcomeSubTagline =>
      'Wekkers die je wisselende rooster volgen, niet alleen werkdagen.';

  @override
  String welcomeTrialTitle(int days) {
    return '$days dagen gratis proberen';
  }

  @override
  String get welcomeTrialBody =>
      'Volledige toegang tot alle functies, zonder creditcard. Daarna een eenmalige aankoop, nooit een abonnement.';

  @override
  String get welcomeGetStarted => 'Aan de slag';

  @override
  String get welcomeSkip => 'Overslaan / Later instellen';

  @override
  String get welcomeTimeFormat => 'Tijdnotatie';

  @override
  String get welcomeWeekStarts => 'Week begint';

  @override
  String get common12h => '12 u';

  @override
  String get common24h => '24 u';

  @override
  String get commonSundayShort => 'zo';

  @override
  String get commonMondayShort => 'ma';

  @override
  String get rosterTypeTitle => 'Kies een roostertype';

  @override
  String get rosterTypeQuestion => 'Hoe ziet je rooster eruit?';

  @override
  String get rosterTypeDay => 'Dagdiensten';

  @override
  String get rosterTypeNight => 'Nachtdiensten';

  @override
  String get rosterTypeRotating => 'Wisselend';

  @override
  String get rosterTypeCustom => 'Eigen';

  @override
  String get commonContinue => 'Doorgaan';

  @override
  String get commonComingSoon => 'Binnenkort';

  @override
  String get permsTitle => 'Toestemmingen';

  @override
  String get permsIntro =>
      'Rostrik heeft een paar toestemmingen nodig om wekkers betrouwbaar af te laten gaan. Je kunt dit later wijzigen in de systeeminstellingen.';

  @override
  String get permsNotifications => 'Meldingen';

  @override
  String get permsNotificationsSub => 'Nodig om het wekscherm te tonen.';

  @override
  String get permsExactAlarms => 'Exacte wekkers';

  @override
  String get permsExactAlarmsSub => 'Laat wekkers precies op tijd afgaan.';

  @override
  String get permsBatteryUnrestricted => 'Batterij onbeperkt';

  @override
  String get permsBatteryGrantedSub =>
      'Wekkers zijn beschermd tegen batterijoptimalisatie.';

  @override
  String get permsBatteryDeniedSub =>
      'Sommige telefoons stoppen apps op de achtergrond. Tik om te verhelpen.';

  @override
  String get permsUnrestrictedBadge => 'Onbeperkt';

  @override
  String get batteryDialogTitle => 'Houd wekkers actief';

  @override
  String get batteryDialogIntro =>
      'Sommige telefoons (Samsung, Xiaomi, Oppo, Huawei) sluiten achtergrond-apps agressief af om batterij te sparen. Gebeurt dat met Rostrik, dan kan een wekker stil blijven.';

  @override
  String get batteryDialogMarkUnrestricted =>
      'Zet Rostrik op Onbeperkt om dit te voorkomen:';

  @override
  String get batteryStep1 =>
      'Open de instellingen van deze app (knop hieronder).';

  @override
  String get batteryStep2 => 'Tik op Batterij (of \"Batterijgebruik app\").';

  @override
  String get batteryStep3 =>
      'Kies Onbeperkt (niet \"Geoptimaliseerd\" of \"Beperkt\").';

  @override
  String get batteryStep4 =>
      'Zie je \"Achtergrondactiviteit toestaan\", zet dat dan ook aan.';

  @override
  String get batteryStep5 =>
      'Zet \"App-activiteit pauzeren als app niet wordt gebruikt\" (of \"Rechten verwijderen als app niet wordt gebruikt\") UIT, zodat Android de wekkerrechten niet intrekt terwijl je weg bent.';

  @override
  String get commonNotNow => 'Niet nu';

  @override
  String get batteryGoToSettings => 'Naar instellingen';

  @override
  String get armEngineTitle => 'Zet je wekkers aan';

  @override
  String get armEngineRosterReady => 'Je rooster staat klaar';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · start $date';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'We zetten wekkers ($summary) aan vóór elke passende dienst.';
  }

  @override
  String get armEngineArming => 'Aanzetten…';

  @override
  String get armEngineCta => 'Automatiseer mijn wekkers';

  @override
  String get armEngineLeadTimeLabel => 'Wektijd vooraf';

  @override
  String get armEngineLeadTimeHelper =>
      'Hoe lang vóór het begin van je dienst de wekker afgaat.';

  @override
  String get shiftTypeDay => 'Dag';

  @override
  String get shiftTypeAfternoon => 'Avond';

  @override
  String get shiftTypeNight => 'Nacht';

  @override
  String get shiftTypeOff => 'Vrij';

  @override
  String get weekdaysNone => 'Geen dagen';

  @override
  String get weekdaysEveryDay => 'Elke dag';

  @override
  String get weekdaysWeekdays => 'Doordeweeks';

  @override
  String get weekdaysWeekends => 'Weekenden';

  @override
  String durationMin(int m) {
    return '$m min';
  }

  @override
  String durationH(int h) {
    return '$h u';
  }

  @override
  String durationHMin(int h, int m) {
    return '$h u $m min';
  }

  @override
  String durationMinShort(int m) {
    return '$m min';
  }

  @override
  String durationHShort(int h) {
    return '$h u';
  }

  @override
  String durationHMinShort(int h, int m) {
    return '$h u $m min';
  }

  @override
  String get commonClose => 'Sluiten';

  @override
  String get commonSkip => 'Overslaan';

  @override
  String get commonBack => 'Terug';

  @override
  String get commonDone => 'Klaar';

  @override
  String get commonNext => 'Volgende';

  @override
  String get walkthroughIntroTitle => 'Een rondleiding van 60 seconden';

  @override
  String get walkthroughIntroBodyTwo =>
      'Twee dingen die Rostrik laten werken. Je kunt altijd overslaan.';

  @override
  String get walkthroughIntroBodyOne =>
      'Wat Rostrik laat werken. Je kunt altijd overslaan.';

  @override
  String get walkthroughPaintLabel => 'Schilder je rooster';

  @override
  String get walkthroughPaintDetail =>
      'Tik op je werkdagen – zo snel gaat het.';

  @override
  String get walkthroughShakeLabel => 'Schud om te stoppen';

  @override
  String get walkthroughShakeDetail =>
      'Stevig schudden zet een kritieke wekker uit.';

  @override
  String get walkthroughTryEach => 'Tik op Volgende om ze allebei te proberen.';

  @override
  String get walkthroughTryIt => 'Tik op Volgende om het te proberen.';

  @override
  String get walkthroughPaintBody =>
      'Tik op je werkdagen. In de echte editor voeg je meer blokken (avonden, nachten) op dezelfde manier toe.';

  @override
  String get walkthroughPaintPrompt =>
      'Tik op een dag om er een dagdienst op te schilderen.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Top! Die $count dagen zijn nu een dagblok. Dagen zonder tik blijven vrij. Zo simpel.',
      one:
          'Top! Die dag is nu een dagblok. Dagen zonder tik blijven vrij. Zo simpel.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'Wekkers voor kritieke diensten gaan pas uit na stevig, aanhoudend schudden, zodat een slaperige tik niet genoeg is. Probeer het: schud je telefoon.';

  @override
  String get walkthroughShakeSuccess => 'Gelukt!';

  @override
  String get walkthroughShakeSuccessDetail =>
      'Precies zo zet je een kritieke wekker uit.';

  @override
  String get walkthroughDoneTitle => 'Je bent klaar';

  @override
  String get walkthroughDoneBody =>
      'Maak op elk moment een rooster via Beheren en bekijk deze rondleiding opnieuw via Instellingen → Hulp.';

  @override
  String get navDashboard => 'Overzicht';

  @override
  String get navTimeline => 'Tijdlijn';

  @override
  String get navManage => 'Beheren';

  @override
  String get navAlarms => 'Wekkers';

  @override
  String get navSleep => 'Slaap';

  @override
  String get onbPatternTitle => 'Kies je ritme';

  @override
  String get purchaseTrialEnded => 'Je gratis proefperiode is voorbij';

  @override
  String get purchaseBody =>
      'Ontgrendel Rostrik één keer zodat je dienstwekkers blijven afgaan. Je rooster, wekkers en instellingen blijven bewaard en werken meteen weer na ontgrendelen.';

  @override
  String get purchaseAlarmsWontRing => 'Tot die tijd gaan wekkers niet af.';

  @override
  String get purchaseUnlock => 'Volledige toegang ontgrendelen';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'Volledige toegang ontgrendelen · $price';
  }

  @override
  String get purchaseRestore => 'Aankoop herstellen';

  @override
  String get purchaseOneTime => 'Eenmalige aankoop. Geen abonnement.';

  @override
  String get purchaseUnavailable =>
      'Aankopen zijn nu niet beschikbaar. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get purchaseCheckingPrevious => 'Zoeken naar een eerdere aankoop…';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsLegalAbout => 'JURIDISCH & OVER';

  @override
  String get settingsHelp => 'HULP';

  @override
  String get settingsHowItWorks => 'Hoe het werkt';

  @override
  String get settingsReplayTourShake =>
      'Rondleiding opnieuw – rooster schilderen + schudden om te stoppen';

  @override
  String get settingsReplayTour => 'Rondleiding opnieuw – rooster schilderen';

  @override
  String get settingsScreenTips => 'Schermtips tonen';

  @override
  String get settingsScreenTipsSub =>
      'Eenmalige tips op elk scherm. Zet aan om ze opnieuw te zien.';

  @override
  String get settingsFullAccess => 'VOLLEDIGE TOEGANG';

  @override
  String get settingsFullAccessUnlocked => 'Volledige toegang ontgrendeld';

  @override
  String get settingsThanks => 'Bedankt dat je Rostrik steunt.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Proefperiode – nog $days dagen',
      one: 'Proefperiode – nog 1 dag',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'Proefperiode voorbij';

  @override
  String get settingsUnlockPitch =>
      'Ontgrendel één keer zodat je dienstwekkers na de proefperiode blijven afgaan – een eenmalige aankoop, nooit een abonnement.';

  @override
  String get settingsRestore => 'Herstellen';

  @override
  String get settingsBrandTagline => 'Wekkers voor buiten kantoortijden';

  @override
  String get settingsLeadTime => 'Wektijd vooraf';

  @override
  String get settingsLeadTimeSub =>
      'De wekker gaat zo lang vóór elke dienst af.';

  @override
  String get settingsSnoozeDuration => 'Sluimerduur';

  @override
  String get settingsSnoozeDurationSub =>
      'Hoe ver de sluimerknop een afgaande wekker uitstelt.';

  @override
  String get settingsMinutesLabel => 'Minuten';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m minuten',
      one: '1 minuut',
    );
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => 'DIENSTCYCLI';

  @override
  String get settingsShiftCyclesSub =>
      'Roosters die je hebt gemaakt vanuit een patroon of sjabloon.';

  @override
  String get settingsAddShiftCycle => 'Dienstcyclus toevoegen';

  @override
  String get settingsNoRosters => 'Je hebt nog geen roosters gemaakt.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'Bewerken';

  @override
  String get commonDelete => 'Verwijderen';

  @override
  String get commonCancel => 'Annuleren';

  @override
  String get settingsDeleteRosterTitle => 'Rooster verwijderen?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diensten worden',
      one: '1 dienst wordt',
    );
    return '\"$label\" verwijderen? Openstaande wekkers worden geannuleerd en $_temp0 verwijderd.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return '\"$label\" verwijderd';
  }

  @override
  String get commonActive => 'Actief';

  @override
  String get commonUpcoming => 'Gepland';

  @override
  String get commonPast => 'Verleden';

  @override
  String get settingsWorkHistory => 'WERKGESCHIEDENIS';

  @override
  String get settingsWorkHistorySub =>
      'Bekijk en exporteer je afgeronde losse diensten om je loonstrook te controleren.';

  @override
  String get settingsViewWorkHistory => 'Geschiedenis bekijken en exporteren';

  @override
  String get settingsPreferences => 'VOORKEUREN';

  @override
  String get settingsPreferencesSub =>
      'Hoe je rooster in de app wordt getoond.';

  @override
  String get settingsAppearance => 'Weergave';

  @override
  String get settingsThemeSystem => 'Systeem';

  @override
  String get settingsThemeLight => 'Licht';

  @override
  String get settingsThemeDark => 'Donker';

  @override
  String get settingsThemeSub =>
      'Donker is de standaard van Rostrik. Licht gebruikt een warm crèmekleurig palet.';

  @override
  String get settings24h => '24-uursnotatie gebruiken';

  @override
  String get settings24hOn => 'Tijden worden getoond als 14:30';

  @override
  String get settings24hOff => 'Tijden worden getoond als 02:30 PM';

  @override
  String get settingsWeekStartTitle => 'Kalender op maandag laten beginnen';

  @override
  String get settingsWeekStartMon => 'Weken beginnen op maandag';

  @override
  String get settingsWeekStartSun => 'Weken beginnen op zondag';

  @override
  String get settingsTimelineOpensOn => 'Tijdlijn opent in';

  @override
  String get commonList => 'Lijst';

  @override
  String get commonMonth => 'Maand';

  @override
  String get settingsCalendar => 'AGENDA';

  @override
  String get settingsCalendarSync =>
      'Synchroniseren met Google / apparaatagenda';

  @override
  String get settingsCalendarSyncSub =>
      'Zet je diensten automatisch in een aparte agenda \"Rostrik Roster\" op je telefoon.';

  @override
  String get settingsCalSyncOff =>
      'Agendasynchronisatie uit. Komende \"Rostrik Roster\"-afspraken zijn gewist.';

  @override
  String get settingsCalSyncMirroring =>
      'Je rooster wordt naar de agenda \"Rostrik Roster\" gezet…';

  @override
  String get settingsCalPermNeeded =>
      'Agendatoegang is nodig om je rooster te synchroniseren.';

  @override
  String get settingsCalBlocked =>
      'Agendatoegang is geblokkeerd. Zet deze aan in de systeeminstellingen.';

  @override
  String get settingsCalOpenSettings => 'Instellingen';

  @override
  String get settingsCalUnsupported =>
      'Agendasynchronisatie is niet beschikbaar op dit apparaat.';

  @override
  String get settingsDangerZone => 'GEVARENZONE';

  @override
  String get settingsDangerZoneSub =>
      'Verwijdert je rooster, wekkers en instellingen en start de installatie opnieuw.';

  @override
  String get settingsResetAppData => 'App-gegevens resetten';

  @override
  String get settingsResetTitle => 'App resetten?';

  @override
  String get settingsResetBody =>
      'Weet je het zeker? Je rooster, wekkers en instellingen worden verwijderd.';

  @override
  String get settingsResetConfirm => 'Resetten';

  @override
  String get dashNoUpcomingShifts => 'Geen komende diensten';

  @override
  String get dashEnjoyTimeOff => 'Geniet van je vrije tijd.';

  @override
  String get dashInProgress => 'BEZIG';

  @override
  String get dashRotation => 'Ritme';

  @override
  String get dashAlarmsCantRing => 'Wekkers kunnen niet betrouwbaar afgaan';

  @override
  String get dashNotifsOffIssue =>
      'Meldingen staan uit – een afgaande wekker kan geen wekscherm tonen en niet worden uitgezet.';

  @override
  String get dashOpenSettings => 'Instellingen openen';

  @override
  String get dashExactBlockedIssue =>
      'Exacte wekkers zijn geblokkeerd – er kunnen geen wekmomenten worden gepland.';

  @override
  String get dashAlarmsWontTakeOverScreen =>
      'Alarmen nemen het scherm niet over';

  @override
  String get dashFullScreenBlockedIssue =>
      'Schermvullende alarmen staan uit — op een vergrendelde telefoon zie je een melding in plaats van het alarmscherm.';

  @override
  String get dashAllow => 'Toestaan';

  @override
  String get dashSlideToSkip => 'Veeg om deze wekker over te slaan';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Veeg om alle $count wekkers over te slaan',
      one: 'Veeg om de wekker over te slaan',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'Komende wekker uitzetten · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count wekkers voor deze dienst overslaan',
      one: 'Wekker voor deze dienst overslaan',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'Wekker houden';

  @override
  String get dashMyRotation => 'Mijn ritme';

  @override
  String get dashCalendarUpcoming => 'Kalender & komende diensten';

  @override
  String get dashNextShifts => 'Volgende diensten';

  @override
  String get dashOpenTimeline => 'Tijdlijn openen';

  @override
  String heroStartsIn(String countdown) {
    return 'Begint over $countdown';
  }

  @override
  String heroEndsIn(String countdown) {
    return 'Eindigt over $countdown';
  }

  @override
  String get heroStartsInPrefix => 'Begint over';

  @override
  String get heroEndsInPrefix => 'Eindigt over';

  @override
  String heroStartsTodayAt(String time) {
    return 'Begint vandaag om $time';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'Vandaag begonnen om $time';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'Begint morgen om $time';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'Gisteren begonnen om $time';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'Begint gisteren om $time';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return 'Begint $date om $time';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return 'Begonnen $date om $time';
  }

  @override
  String get shiftTypeDayShift => 'Dagdienst';

  @override
  String get shiftTypeAfternoonShift => 'Avonddienst';

  @override
  String get shiftTypeNightShift => 'Nachtdienst';

  @override
  String heroDayXofY(int x, int y, String label) {
    return 'Dag $x van $y – $label';
  }

  @override
  String get heroOffTomorrow => 'Morgen vrij';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Over $days dagen vrij',
      one: 'Over 1 dag vrij',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'Morgen weer aan het werk';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Over $days dagen weer aan het werk',
      one: 'Over 1 dag weer aan het werk',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'Vrij';

  @override
  String durationDayShort(int d) {
    return '$d d';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d d $h u';
  }

  @override
  String get alarmsTitle => 'Wekkers';

  @override
  String get alarmsAddTooltip => 'Wekker toevoegen';

  @override
  String get alarmsSortTooltip => 'Wekkers sorteren';

  @override
  String get alarmsSortByTime => 'Op tijd';

  @override
  String get alarmsSortByShiftType => 'Op diensttype';

  @override
  String get alarmsEmptyTitle => 'Nog geen wekkers.';

  @override
  String get alarmsEmptyBody => 'Tik op + om er een toe te voegen.';

  @override
  String get alarmsNextAlarm => 'VOLGENDE WEKKER';

  @override
  String get alarmsHolidayMode => 'Vakantiemodus';

  @override
  String get alarmsHolidayModeSub =>
      'Wekkers staan op pauze – er gaat niets af.';

  @override
  String get alarmsNoUpcoming => 'Geen komende dienstwekker';

  @override
  String get alarmsNoUpcomingSub =>
      'Voeg een ritmewekker toe of maak een rooster.';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'voor je dienst ($type) · $day';
  }

  @override
  String get commonToday => 'Vandaag';

  @override
  String get commonTomorrow => 'Morgen';

  @override
  String get alarmsOffWontRing => 'Uit – gaat niet af';

  @override
  String get alarmsNoUpcomingRing => 'Geen wekmoment gepland';

  @override
  String alarmsNextRing(String day, String time) {
    return 'Volgende keer: $day om $time';
  }

  @override
  String get alarmsSwipeToDelete => 'Veeg om te verwijderen';

  @override
  String get alarmsRingsOnceAutoDelete =>
      'Gaat één keer af · verwijdert zichzelf';

  @override
  String get alarmsRingsOnce => 'Gaat maar één keer af';

  @override
  String get alarmsYourShift => 'je dienst';

  @override
  String alarmsShiftsOfType(String type) {
    return 'diensten ($type)';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'Exacte tijd · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$lead vóór $shift · standaard';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$lead vóór $shift';
  }

  @override
  String get createEditAlarm => 'Wekker bewerken';

  @override
  String get createNewAlarm => 'Nieuwe wekker';

  @override
  String get createDefaultLabel => 'Opstaan';

  @override
  String get createFallbackLabel => 'Wekker';

  @override
  String get createPickBecomesDefault =>
      'Je keuze wordt de standaard voor nieuwe wekkers.';

  @override
  String get createSelectFromFiles => 'Kiezen uit Bestanden';

  @override
  String get createFilesSub => 'Kies een audiobestand op je apparaat';

  @override
  String get createSelectSystemTone => 'Systeemgeluid kiezen';

  @override
  String get createSystemToneSub =>
      'Kies uit de wekkergeluiden van je apparaat';

  @override
  String get createAlarmTiming => 'Wekmoment';

  @override
  String get createLeadTimeMode => 'Vooraf';

  @override
  String get createExactTimeMode => 'Exacte tijd';

  @override
  String createFiresAt(String time) {
    return 'Gaat af om $time';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return '$lead vóór begin dienst';
  }

  @override
  String get createLinkedShift => 'Gekoppelde dienst';

  @override
  String get createRepeatOn => 'Herhalen op';

  @override
  String get createLabelField => 'Naam';

  @override
  String get createLabelHint => 'bijv. Opstaan';

  @override
  String get createCriticalShift => 'Kritieke dienst';

  @override
  String get createCriticalShiftSub =>
      'Schud om te stoppen · 3 sec. vasthouden als noodoptie';

  @override
  String get createRingtone => 'Beltoon';

  @override
  String get commonStop => 'Stop';

  @override
  String get commonPlay => 'Afspelen';

  @override
  String get createVibrate => 'Trillen';

  @override
  String get createRepeat => 'Herhalen';

  @override
  String get createRepeatRotation => 'Ritme';

  @override
  String get createRepeatWeekly => 'Wekelijks';

  @override
  String get createRepeatOneTime => 'Eenmalig';

  @override
  String get createPickOneDay => 'Kies minstens één dag';

  @override
  String get commonSave => 'Opslaan';

  @override
  String get commonSaveChanges => 'Wijzigingen opslaan';

  @override
  String get createTimeBeforeShift => 'Tijd vóór dienst';

  @override
  String get commonOk => 'OK';

  @override
  String get sleepTitle => 'Slaap';

  @override
  String get sleepTargetHeader => 'SLAAPDOEL';

  @override
  String get sleepTargetSub =>
      'Hoeveel uur je wilt slapen. Rostrik rekent terug vanaf je volgende wekker om je bedtijd van vanavond te bepalen.';

  @override
  String get sleepRemindersHeader => 'HERINNERINGEN';

  @override
  String get sleepWindDownHeader => 'TIJD OM TOT RUST TE KOMEN';

  @override
  String get sleepWindDownSub =>
      'Hoe lang vóór bedtijd de herinnering om tot rust te komen verschijnt.';

  @override
  String get sleepSoundsHeader => 'SLAAPGELUIDEN';

  @override
  String get sleepSoundsSub =>
      'Witte en bruine ruis om bij in slaap te vallen. Kies een timer en tik op een geluid.';

  @override
  String get sleepNothingToPlan => 'Vanavond niets te plannen';

  @override
  String get sleepNothingToPlanSub =>
      'Voeg een dienst toe aan je rooster en Rostrik plant een persoonlijke bedtijd rond je volgende wekmoment.';

  @override
  String get sleepTransitionDay => 'OVERGANGSDAG';

  @override
  String get sleepTransitionTitle =>
      'Morgen heb je nachtdienst. Slaap gerust uit.';

  @override
  String get sleepTransitionBody =>
      'Het is een overgangsdag – je hebt een vrije dag vóór de nachten, dus geen vroege wekker. Sla nu extra rust op en ga vanavond later naar bed.';

  @override
  String get sleepRestRecovery => 'RUST & HERSTEL';

  @override
  String get sleepNoEarlyAlarm => 'Geen vroege wekker';

  @override
  String get sleepRestBody =>
      'Je volgende dienst is meer dan een dag weg, dus vanavond valt er niets te plannen. Slaap op je eigen ritme en herstel – Rostrik maakt je bedtijdplan zodra de dienst dichterbij komt.';

  @override
  String get sleepTonightsPlan => 'PLAN VOOR VANNACHT';

  @override
  String get sleepTargetBedtime => 'Bedtijd';

  @override
  String get sleepWindDownStat => 'Tot rust komen';

  @override
  String get sleepWakeUpStat => 'Opstaan';

  @override
  String get sleepDurationStat => 'Duur';

  @override
  String get sleepBedtimeReminder => 'Bedtijdherinnering';

  @override
  String sleepNudgeAtBedtime(String time) {
    return 'Herinner me om $time om naar bed te gaan';
  }

  @override
  String get sleepBedtimeSub => 'Een seintje als het bedtijd is';

  @override
  String get sleepWindDownReminder => 'Rustherinnering';

  @override
  String sleepNudgeAtWindDown(String time) {
    return 'Herinner me om $time om tot rust te komen';
  }

  @override
  String get sleepWindDownReminderSub =>
      'Een eerder seintje om tot rust te komen';

  @override
  String get commonOff => 'Uit';

  @override
  String get sleepSoundWhiteNoise => 'Witte ruis';

  @override
  String get sleepSoundPinkNoise => 'Roze ruis';

  @override
  String get sleepSoundBrownNoise => 'Bruine ruis';

  @override
  String get sleepSoundFan => 'Ventilator';

  @override
  String get sleepSoundOcean => 'Oceaan';

  @override
  String get sleepSoundRain => 'Regen';

  @override
  String get manageTitle => 'Beheren';

  @override
  String get manageRosterTools => 'ROOSTERTOOLS';

  @override
  String get manageRosterToolsSub =>
      'Maak en pas de diensten aan die je wekkers en slaapplan sturen.';

  @override
  String get manageGenerateRotation => 'Ritme maken';

  @override
  String get manageGenerateRotationSub =>
      'Maak een terugkerend dienstpatroon vanuit een sjabloon.';

  @override
  String get manageAddCustomShift => 'Losse dienst toevoegen';

  @override
  String get manageAddCustomShiftSub => 'Zet één losse dienst in je rooster.';

  @override
  String get manageMarkLeave => 'Verlof / vrije dagen markeren';

  @override
  String get manageMarkLeaveSub =>
      'Schilder in één keer de dagen dat je vrij bent (verlof, ziek).';

  @override
  String get managePauseSchedule => 'Rooster pauzeren';

  @override
  String get managePausedSub =>
      'Vakantiemodus AAN – wekkers staan stil, je rooster blijft bewaard.';

  @override
  String get manageNotPausedSub =>
      'Vakantiemodus – zet wekkers stil terwijl je niet ingeroosterd bent.';

  @override
  String get markLeaveTitle => 'Verlof markeren';

  @override
  String get markLeaveIntro =>
      'Tik op de dagen dat je vrij bent, kies een reden en pas toe. Wekkers op die dagen gaan niet af – je rooster blijft intact.';

  @override
  String get leaveAnnual => 'Vakantieverlof';

  @override
  String get leaveSick => 'Ziek';

  @override
  String get leavePublicHoliday => 'Feestdag';

  @override
  String get markLeaveReason => 'Reden';

  @override
  String get markLeaveFallbackReason => 'verlof';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diensten gemarkeerd als $reason.',
      one: '1 dienst gemarkeerd als $reason.',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => 'Kies dagen om te markeren';

  @override
  String get markLeaveNoShifts => 'Geen diensten op die dagen';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Toepassen op $count diensten',
      one: 'Toepassen op 1 dienst',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => 'Werkgeschiedenis';

  @override
  String get workHistoryExportTooltip => 'Geschiedenis exporteren';

  @override
  String workHistoryExportFailed(String error) {
    return 'Geschiedenis kon niet worden geëxporteerd: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diensten gewerkt',
      one: '1 dienst gewerkt',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours u';
  }

  @override
  String get commonPaused => 'Gepauzeerd';

  @override
  String workHistoryPausedReason(String reason) {
    return 'Gepauzeerd · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'Ritme';

  @override
  String get workHistoryAdHocBadge => 'Los';

  @override
  String get workHistoryEmptyTitle => 'Nog geen afgeronde diensten';

  @override
  String get workHistoryEmptyBody =>
      'Je gewerkte diensten – uit je ritme én losse – verschijnen hier zodra ze voorbij zijn, klaar om te exporteren voor je loonstrook.';

  @override
  String get workHistoryShareSubject => 'Rostrik werkgeschiedenis';

  @override
  String get workHistoryShareText =>
      'Mijn werkgeschiedenis, geëxporteerd uit Rostrik.';

  @override
  String get shiftEdAddShift => 'Dienst toevoegen';

  @override
  String get shiftEdEditShift => 'Dienst bewerken';

  @override
  String get shiftEdDate => 'Datum';

  @override
  String get shiftEdPickDate => 'Datum kiezen';

  @override
  String get shiftEdStarts => 'Begint';

  @override
  String get shiftEdEnds => 'Eindigt';

  @override
  String get shiftEdPickTime => 'Tijd kiezen';

  @override
  String get shiftEdEndsNextDay => 'Eindigt de volgende dag';

  @override
  String get shiftEdPauseTitle => 'Deze dienst pauzeren / annuleren';

  @override
  String get shiftEdPausedSub =>
      'De wekker gaat niet af. De dienst blijft als registratie in je agenda.';

  @override
  String get shiftEdNotPausedSub =>
      'Markeer een vrije dag (ziek, verlof, feestdag) zonder de dienst te verwijderen.';

  @override
  String get shiftEdReasonOptional => 'Reden (optioneel)';

  @override
  String get dayShifts => 'Diensten';

  @override
  String get dayActivities => 'Activiteiten';

  @override
  String get dayAddAnotherShift => 'Nog een dienst toevoegen';

  @override
  String get dayAddActivity => 'Activiteit toevoegen';

  @override
  String get dayAddActivitySub => 'Afspraak, taak of verjaardag';

  @override
  String get dayReminder => 'Herinnering';

  @override
  String get actEditActivity => 'Activiteit bewerken';

  @override
  String get actLeadAtTime => 'Op tijd';

  @override
  String get actLead10Min => '10 min vooraf';

  @override
  String get actLead30Min => '30 min vooraf';

  @override
  String get actLead1Hour => '1 uur vooraf';

  @override
  String get actLead1Day => '1 dag vooraf';

  @override
  String get actEvent => 'Afspraak';

  @override
  String get actTask => 'Taak';

  @override
  String get actBirthday => 'Verjaardag';

  @override
  String get actTitleField => 'Titel';

  @override
  String get actAllDay => 'Hele dag';

  @override
  String get actTimeField => 'Tijd';

  @override
  String get actRemindMe => 'Herinner mij';

  @override
  String get actRemindMeSub =>
      'Een rustige melding – los van je dienstwekkers.';

  @override
  String get actRemindAt => 'Herinneren om';

  @override
  String get actReminderPassed =>
      'Dat tijdstip is al voorbij – deze herinnering komt niet.';

  @override
  String get actNoteOptional => 'Notitie (optioneel)';

  @override
  String get actCompleted => 'Afgerond';

  @override
  String get tipDashboardTitle => 'Je overzicht';

  @override
  String get tipDashboardBody =>
      'Je thuisbasis. Zie je volgende dienst met live aftellen en waar je in je ritme zit. Tik op een tegel voor de details.';

  @override
  String get tipTimelineTitle => 'Je hele rooster';

  @override
  String get tipTimelineBody =>
      'Wissel bovenaan tussen lijst en maandkalender. Tik op een dag om een dienst te bewerken – of een afspraak, taak of verjaardag toe te voegen.';

  @override
  String get tipManageTitle => 'Maken & aanpassen';

  @override
  String get tipManageBody =>
      'Maak een wisselend rooster, voeg een losse dienst (overwerk) toe of pauzeer je hele rooster voor verlof – allemaal hier.';

  @override
  String get tipAlarmsTitle => 'Je wekkers';

  @override
  String get tipAlarmsBody =>
      'Alle wekkers die je diensten maken, plus je eigen wekkers. Tik op een wekker om tijd of geluid te wijzigen, of maak er een schudwekker voor kritieke diensten van.';

  @override
  String get tipSleepTitle => 'Slaapplan';

  @override
  String get tipSleepBody =>
      'Een plan om tot rust te komen dat je rooster volgt: stel een slaapdoel in en begin uitgerust aan je volgende dienst.';

  @override
  String get tipReplayHint =>
      'Bekijk ze altijd opnieuw via Instellingen › Hoe het werkt.';

  @override
  String get tipDontShow => 'Geen tips tonen';

  @override
  String get tipGotIt => 'Begrepen';

  @override
  String get timelineListView => 'Lijst';

  @override
  String get timelineMonthView => 'Maand';

  @override
  String get shiftTypeAftShort => 'Avond';

  @override
  String get timelineNoShifts =>
      'Geen diensten gepland. Tik op + om er een toe te voegen.';

  @override
  String timelineNoMatch(String filter) {
    return 'Geen diensten voor filter \"$filter\".';
  }

  @override
  String get timelineRestDay => 'Rustdag';

  @override
  String timelineRestDayReason(String reason) {
    return 'Rustdag · $reason';
  }

  @override
  String get timelineAllDay => 'Hele dag';

  @override
  String get calLegendPausedLeave => 'Gepauzeerd / Verlof';

  @override
  String get calLegendActivity => 'Activiteit';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterWork => 'Werk';

  @override
  String get criticalHoldToDismiss => 'Of houd vast om te stoppen';

  @override
  String get patternChoosePattern => 'Kies een patroon';

  @override
  String get patternRotatingSwings => 'Wisselende ritmes';

  @override
  String get patternDaySwings => 'Alleen dagdiensten';

  @override
  String get patternNightSwings => 'Alleen nachtdiensten';

  @override
  String get patternShiftTimes => 'Diensttijden';

  @override
  String get patternGenerate => 'Dag 1 instellen & maken';

  @override
  String get patternSelectDay1 => 'Kies je volgende dag 1';

  @override
  String patternDay1Hint(String label) {
    return 'Eerste dag van je blok ($label)';
  }

  @override
  String get patternNextDay1 => 'Volgende dag 1';

  @override
  String get patternUseThisDate => 'Deze datum gebruiken';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diensten gemaakt',
      one: '1 dienst gemaakt',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'Maken mislukt: $error';
  }

  @override
  String get patternFirstBlockFallback => 'eerste';

  @override
  String get patternBuildCustom => 'Eigen rooster maken';

  @override
  String get patternBuildCustomSub =>
      'Past geen sjabloon? Stel je eigen blokken samen.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dagen',
      one: '1 dag',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n avonden',
      one: '1 avond',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nachten',
      one: '1 nacht',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '$n vrij';
  }

  @override
  String get builderNewRoster => 'Nieuw dienstrooster';

  @override
  String get builderEditRoster => 'Rooster bewerken';

  @override
  String get builderNewSub => 'Stel je dienstritme in';

  @override
  String get builderEditSub => 'Wijzig en vervang dit opgeslagen rooster';

  @override
  String get builderNameHint => 'Naam (bijv. Mijn 14-daagse ritme)';

  @override
  String get builderCycleLength => 'CYCLUSLENGTE';

  @override
  String get builderStartDate => 'STARTDATUM';

  @override
  String get builderShiftBlocks => 'DIENSTBLOKKEN';

  @override
  String get builderAddShiftBlock => 'Dienstblok toevoegen';

  @override
  String get builderCreateRoster => 'Rooster maken';

  @override
  String get builderSaveChanges => 'Wijzigingen opslaan';

  @override
  String get builderReplaceWarning =>
      'Opslaan vervangt dit rooster. Verlof- en vrije-dagmarkeringen erop worden gereset.';

  @override
  String get builderBackToOptions => 'Terug naar opties';

  @override
  String get builderOrImport => 'OF IMPORTEER EEN BESTAAND ROOSTER';

  @override
  String get builderImportViaAi => 'Importeren met AI';

  @override
  String get builderScanning => 'Scannen…';

  @override
  String get builderScanInstead => 'Liever een foto van het rooster scannen';

  @override
  String get builderCustomChip => 'Anders';

  @override
  String get builderCycleLengthLabel => 'Cycluslengte';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dagen',
      one: '1 dag',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'Kies een datum';

  @override
  String get builderNoBlocksYet => 'Nog geen blokken';

  @override
  String get builderNoBlocksSub =>
      'Voeg dienstblokken toe om je ritme vast te leggen';

  @override
  String builderDaysLine(String ranges) {
    return 'Dagen $ranges';
  }

  @override
  String get builderEditBlock => 'Blok bewerken';

  @override
  String get builderRemoveBlock => 'Blok verwijderen';

  @override
  String get builderPickRosterStart => 'Kies de startdatum van het rooster';

  @override
  String get builderPickScanStart =>
      'Kies de startdatum van het gescande rooster';

  @override
  String get builderScanCamera => 'Scannen met camera';

  @override
  String get builderImportScreenshot => 'Screenshot importeren';

  @override
  String builderScanFailed(String error) {
    return 'Scannen mislukt: $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'Geen diensttijden herkend. Snijd de foto strakker bij rond de tabel.';

  @override
  String get builderCustomRosterFallback => 'Eigen rooster';

  @override
  String get builderScannedRosterFallback => 'Gescand rooster';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rooster bijgewerkt – $count diensten gepland',
      one: 'Rooster bijgewerkt – 1 dienst gepland',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gemaakt – $count diensten gepland',
      one: 'Gemaakt – 1 dienst gepland',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'Rooster kon niet worden gemaakt: $error';
  }

  @override
  String get builderRosterImported => 'Rooster geïmporteerd in je agenda';

  @override
  String builderCouldNotImport(String error) {
    return 'Rooster kon niet worden geïmporteerd: $error';
  }

  @override
  String get blockAddTitle => 'Dienstblok toevoegen';

  @override
  String get blockEditTitle => 'Dienstblok bewerken';

  @override
  String get blockStart => 'Begin';

  @override
  String get blockEnd => 'Einde';

  @override
  String get blockTapDays => 'Tik op de dagen van deze dienst';

  @override
  String get blockUntappedOff => 'Dagen zonder tik zijn vrij.';

  @override
  String blockOverlap(String ranges) {
    return 'Deze tijd overlapt met een andere dienst op dag $ranges – wijzig de tijd of die dagen.';
  }

  @override
  String get blockAdd => 'Blok toevoegen';

  @override
  String get blockSave => 'Blok opslaan';

  @override
  String get aiPromptCopied =>
      'Prompt gekopieerd! Plak hem samen met je rooster in je AI-app.';

  @override
  String get aiNothingToPaste => 'Niets om te plakken op het klembord.';

  @override
  String get aiNoValidShifts =>
      'Geen geldige diensten gevonden. Controleer of je de gekopieerde AI-prompt hebt gebruikt.';

  @override
  String get aiStep1 => 'Kopieer de prompt';

  @override
  String get aiCopied => 'Gekopieerd!';

  @override
  String get aiCopyPrompt => 'AI-prompt kopiëren';

  @override
  String get aiStep1Sub =>
      'Plak hem in ChatGPT, Gemini of een andere AI-app, voeg de tekst of een foto/screenshot van je rooster toe en verstuur.';

  @override
  String get aiStep2 => 'Plak het antwoord van de AI';

  @override
  String get aiPaste => 'Plakken';

  @override
  String get aiParsePreview => 'Verwerken & voorbeeld';

  @override
  String get aiStep3 => 'Controleer de gevonden diensten';

  @override
  String get aiStep3Sub =>
      'Tik op een label om te wisselen tussen Dag, Avond en Nacht als de AI zich vergiste.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen importeren',
      one: '1 dag importeren',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'Maak met hulp van een AI-app van elke roostertekst echte diensten.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen',
      one: '1 dag',
    );
    return '$_temp0 · $working werk · $off vrij';
  }

  @override
  String get draftReviewTitle => 'Gescand rooster controleren';

  @override
  String draftRemovedDay(String date) {
    return '$date verwijderd';
  }

  @override
  String get draftUndo => 'Ongedaan maken';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen opgeslagen in je rooster',
      one: '1 dag opgeslagen in je rooster',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'Roosternaam';

  @override
  String get draftScannedImage => 'Gescande afbeelding';

  @override
  String get draftScannedImageSub =>
      'Tik op de afbeelding om te vergroten en te vergelijken';

  @override
  String get draftImageError =>
      'De gescande afbeelding kan niet worden getoond.';

  @override
  String get draftRemove => 'Verwijderen';

  @override
  String get draftNoEndTime =>
      'Gescand zonder eindtijd – stel die in om op te slaan.';

  @override
  String get draftTime => 'Tijd';

  @override
  String get draftSetEnd => 'Einde instellen';

  @override
  String get draftConfirmSave => 'Bevestigen & opslaan';

  @override
  String notifBeforeYourShift(String type) {
    return 'Vóór je dienst ($type)';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind om $time';
  }

  @override
  String get notifWindDownTitle => 'Tijd om tot rust te komen 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'Leg de schermen weg – bedtijd is $time.';
  }

  @override
  String get notifWindDownBody =>
      'Leg de schermen weg en kom tot rust voor de nacht.';

  @override
  String get notifBedtimeTitle => 'Bedtijd 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return 'Ga naar bed voor ~$hours u slaap vóór je $shift – wekker om $time.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return 'Ga naar bed om je slaapdoel van $hours u te halen.';
  }

  @override
  String get notifShiftDay => 'dagdienst';

  @override
  String get notifShiftAfternoon => 'avonddienst';

  @override
  String get notifShiftNight => 'nachtdienst';

  @override
  String get notifShiftGeneric => 'dienst';

  @override
  String get notifTrialEndsTitle => 'Je Rostrik-proefperiode eindigt morgen';

  @override
  String get notifTrialEndsBody =>
      'Ontgrendel volledige toegang zodat je dienstwekkers blijven afgaan.';

  @override
  String seedWakeUpLabel(String type) {
    return 'Wekker ($type)';
  }

  @override
  String get seedShiftGeneric => 'Dienst';

  @override
  String commonListAnd(String items, String last) {
    return '$items & $last';
  }

  @override
  String get soundClassic => 'Klassiek';

  @override
  String get soundSiren => 'Sirene';

  @override
  String get soundDigital => 'Digitaal';

  @override
  String get soundChime => 'Klokkenspel';

  @override
  String get patternFirstResponder => 'Hulpdiensten-standaard';

  @override
  String get ocrCropTitle => 'Snijd ALLEEN jouw rij bij – niet het hele team';

  @override
  String get draftNameHint => 'bijv. Rooster mei';
}
