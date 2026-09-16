// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'Prima di iniziare';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik è fatto per svegliarti per ogni turno. Un avviso onesto: su qualsiasi telefono è il sistema operativo, non l\'app, ad avere l\'ultima parola e, in rari casi, può ritardare o silenziare qualsiasi app sveglia (risparmio energetico aggressivo, chiusure forzate o subito dopo un aggiornamento di sistema).';

  @override
  String get legalBodyBackupAdvice =>
      'Per i turni che non puoi assolutamente perdere, tieni una seconda sveglia di riserva: è una buona abitudine con qualsiasi sveglia, anche quella del telefono.';

  @override
  String get legalReviewAndAccept => 'Leggi e accetta:';

  @override
  String get legalPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get legalTermsOfUse => 'Termini di utilizzo';

  @override
  String get legalConsentCheckbox =>
      'Capisco che il sistema operativo può influire su qualsiasi app sveglia e accetto l\'Informativa sulla privacy e i Termini di utilizzo.';

  @override
  String get legalAgreeContinue => 'Accetta e continua';

  @override
  String get commonSaving => 'Salvataggio…';

  @override
  String get commonCouldNotOpenLink => 'Impossibile aprire il link.';

  @override
  String get welcomeTagline =>
      'La sveglia intelligente per chi lavora a turni.';

  @override
  String get welcomeSubTagline =>
      'Sveglie che seguono i tuoi turni a rotazione, non solo i giorni feriali.';

  @override
  String welcomeTrialTitle(int days) {
    return 'Prova gratuita di $days giorni';
  }

  @override
  String get welcomeTrialBody =>
      'Accesso completo a tutte le funzioni, senza carta. Poi un acquisto una tantum, mai un abbonamento.';

  @override
  String get welcomeGetStarted => 'Inizia';

  @override
  String get welcomeSkip => 'Salta / Configura dopo';

  @override
  String get welcomeTimeFormat => 'Formato ora';

  @override
  String get welcomeWeekStarts => 'Inizio settimana';

  @override
  String get common12h => '12 h';

  @override
  String get common24h => '24 h';

  @override
  String get commonSundayShort => 'Dom';

  @override
  String get commonMondayShort => 'Lun';

  @override
  String get rosterTypeTitle => 'Scegli il tipo di turni';

  @override
  String get rosterTypeQuestion => 'Come sono i tuoi turni?';

  @override
  String get rosterTypeDay => 'Turni diurni';

  @override
  String get rosterTypeNight => 'Turni notturni';

  @override
  String get rosterTypeRotating => 'A rotazione';

  @override
  String get rosterTypeCustom => 'Personalizzati';

  @override
  String get commonContinue => 'Continua';

  @override
  String get commonComingSoon => 'In arrivo';

  @override
  String get permsTitle => 'Autorizzazioni';

  @override
  String get permsIntro =>
      'Rostrik ha bisogno di alcune autorizzazioni per far suonare le sveglie in modo affidabile. Puoi modificarle in seguito dalle impostazioni di sistema.';

  @override
  String get permsNotifications => 'Notifiche';

  @override
  String get permsNotificationsSub =>
      'Necessarie per mostrare la schermata di sveglia.';

  @override
  String get permsExactAlarms => 'Sveglie esatte';

  @override
  String get permsExactAlarmsSub => 'Fa suonare le sveglie all\'orario esatto.';

  @override
  String get permsBatteryUnrestricted => 'Batteria senza restrizioni';

  @override
  String get permsBatteryGrantedSub =>
      'Le sveglie sono protette dall\'ottimizzazione della batteria.';

  @override
  String get permsBatteryDeniedSub =>
      'Alcuni telefoni chiudono le app in background. Tocca per risolvere.';

  @override
  String get permsUnrestrictedBadge => 'Senza restrizioni';

  @override
  String get batteryDialogTitle => 'Tieni attive le sveglie';

  @override
  String get batteryDialogIntro =>
      'Alcuni telefoni (Samsung, Xiaomi, Oppo, Huawei) chiudono in modo aggressivo le app in background per risparmiare batteria. Se succede a Rostrik, una sveglia potrebbe restare muta.';

  @override
  String get batteryDialogMarkUnrestricted =>
      'Imposta Rostrik su Senza restrizioni per evitarlo:';

  @override
  String get batteryStep1 =>
      'Apri le impostazioni di questa app (pulsante qui sotto).';

  @override
  String get batteryStep2 => 'Tocca Batteria (o \"Utilizzo batteria app\").';

  @override
  String get batteryStep3 =>
      'Scegli Senza restrizioni (non \"Ottimizzata\" o \"Con restrizioni\").';

  @override
  String get batteryStep4 =>
      'Se vedi \"Consenti attività in background\", attiva anche quella.';

  @override
  String get batteryStep5 =>
      'Disattiva \"Sospendi attività app se non utilizzata\" (o \"Rimuovi autorizzazioni se l\'app non viene usata\") così Android non revoca i permessi della sveglia mentre sei via.';

  @override
  String get commonNotNow => 'Non ora';

  @override
  String get batteryGoToSettings => 'Vai alle impostazioni';

  @override
  String get armEngineTitle => 'Attiva le sveglie';

  @override
  String get armEngineRosterReady => 'I tuoi turni sono pronti';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · dal $date';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'Attiveremo le sveglie ($summary) prima di ogni turno corrispondente.';
  }

  @override
  String get armEngineArming => 'Attivazione…';

  @override
  String get armEngineCta => 'Automatizza le mie sveglie';

  @override
  String get armEngineLeadTimeLabel => 'Anticipo della sveglia';

  @override
  String get armEngineLeadTimeHelper =>
      'Quanto prima dell\'inizio del turno suona la sveglia.';

  @override
  String get shiftTypeDay => 'Giorno';

  @override
  String get shiftTypeAfternoon => 'Pomeriggio';

  @override
  String get shiftTypeNight => 'Notte';

  @override
  String get shiftTypeOff => 'Riposo';

  @override
  String get weekdaysNone => 'Nessun giorno';

  @override
  String get weekdaysEveryDay => 'Ogni giorno';

  @override
  String get weekdaysWeekdays => 'Feriali';

  @override
  String get weekdaysWeekends => 'Weekend';

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
    return '$m min';
  }

  @override
  String durationHShort(int h) {
    return '$h h';
  }

  @override
  String durationHMinShort(int h, int m) {
    return '$h h $m min';
  }

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonSkip => 'Salta';

  @override
  String get commonBack => 'Indietro';

  @override
  String get commonDone => 'Fine';

  @override
  String get commonNext => 'Avanti';

  @override
  String get walkthroughIntroTitle => 'Un tour di 60 secondi';

  @override
  String get walkthroughIntroBodyTwo =>
      'Due cose che rendono Rostrik speciale. Puoi saltare quando vuoi.';

  @override
  String get walkthroughIntroBodyOne =>
      'Ciò che rende Rostrik speciale. Puoi saltare quando vuoi.';

  @override
  String get walkthroughPaintLabel => 'Dipingi i tuoi turni';

  @override
  String get walkthroughPaintDetail =>
      'Tocca i giorni in cui lavori, tutto qui.';

  @override
  String get walkthroughShakeLabel => 'Scuoti per spegnere';

  @override
  String get walkthroughShakeDetail =>
      'Una scossa decisa spegne una sveglia critica.';

  @override
  String get walkthroughTryEach => 'Tocca Avanti per provarle entrambe.';

  @override
  String get walkthroughTryIt => 'Tocca Avanti per provarla.';

  @override
  String get walkthroughPaintBody =>
      'Tocca i giorni in cui lavori. Nell\'editor vero aggiungi altri blocchi (pomeriggi, notti) allo stesso modo.';

  @override
  String get walkthroughPaintPrompt =>
      'Tocca un giorno per dipingere un turno diurno.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ottimo! Quei $count giorni sono un blocco diurno. I giorni non toccati restano di riposo. Facile così.',
      one:
          'Ottimo! Quel giorno è un blocco diurno. I giorni non toccati restano di riposo. Facile così.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'Le sveglie dei turni critici richiedono una scossa decisa e continua per spegnersi, così un tocco nel dormiveglia non basta. Prova: scuoti il telefono.';

  @override
  String get walkthroughShakeSuccess => 'Ce l\'hai fatta!';

  @override
  String get walkthroughShakeSuccessDetail =>
      'È proprio così che silenzierai una sveglia critica.';

  @override
  String get walkthroughDoneTitle => 'Tutto pronto';

  @override
  String get walkthroughDoneBody =>
      'Crea i tuoi turni quando vuoi da Gestisci e rivedi questo tour in Impostazioni → Aiuto.';

  @override
  String get navDashboard => 'Home';

  @override
  String get navTimeline => 'Agenda';

  @override
  String get navManage => 'Gestisci';

  @override
  String get navAlarms => 'Sveglie';

  @override
  String get navSleep => 'Sonno';

  @override
  String get onbPatternTitle => 'Scegli la rotazione';

  @override
  String get purchaseTrialEnded => 'La prova gratuita è terminata';

  @override
  String get purchaseBody =>
      'Sblocca Rostrik una volta sola per continuare a far suonare le sveglie dei turni. Turni, sveglie e impostazioni sono al sicuro e ripartono appena sblocchi.';

  @override
  String get purchaseAlarmsWontRing =>
      'Fino ad allora, le sveglie non suoneranno.';

  @override
  String get purchaseUnlock => 'Sblocca l\'accesso completo';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'Sblocca l\'accesso completo · $price';
  }

  @override
  String get purchaseRestore => 'Ripristina acquisto';

  @override
  String get purchaseOneTime => 'Acquisto una tantum. Nessun abbonamento.';

  @override
  String get purchaseUnavailable =>
      'Gli acquisti non sono disponibili al momento. Controlla la connessione e riprova.';

  @override
  String get purchaseCheckingPrevious => 'Ricerca di un acquisto precedente…';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsLegalAbout => 'NOTE LEGALI E INFO';

  @override
  String get settingsHelp => 'AIUTO';

  @override
  String get settingsHowItWorks => 'Come funziona';

  @override
  String get settingsReplayTourShake =>
      'Rivedi il tour: dipingi i turni + scuoti per spegnere';

  @override
  String get settingsReplayTour => 'Rivedi il tour: dipingi i turni';

  @override
  String get settingsScreenTips => 'Mostra suggerimenti';

  @override
  String get settingsScreenTipsSub =>
      'Suggerimenti una tantum in ogni schermata. Attiva per rivederli.';

  @override
  String get settingsFullAccess => 'ACCESSO COMPLETO';

  @override
  String get settingsFullAccessUnlocked => 'Accesso completo sbloccato';

  @override
  String get settingsThanks => 'Grazie per sostenere Rostrik.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Prova gratuita: mancano $days giorni',
      one: 'Prova gratuita: manca 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'Prova gratuita terminata';

  @override
  String get settingsUnlockPitch =>
      'Sblocca una volta per continuare a far suonare le sveglie dopo la prova: acquisto una tantum, mai un abbonamento.';

  @override
  String get settingsRestore => 'Ripristina';

  @override
  String get settingsBrandTagline => 'Sveglie oltre l\'orario d\'ufficio';

  @override
  String get settingsLeadTime => 'Anticipo';

  @override
  String get settingsLeadTimeSub =>
      'La sveglia suona con questo anticipo prima di ogni turno.';

  @override
  String get settingsSnoozeDuration => 'Durata del posticipo';

  @override
  String get settingsSnoozeDurationSub =>
      'Di quanto il pulsante Posticipa rimanda una sveglia che suona.';

  @override
  String get settingsMinutesLabel => 'Minuti';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m minuti',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => 'CICLI DI TURNI';

  @override
  String get settingsShiftCyclesSub =>
      'Turni generati da uno schema o modello.';

  @override
  String get settingsAddShiftCycle => 'Aggiungi ciclo di turni';

  @override
  String get settingsNoRosters => 'Non hai ancora generato nessun piano turni.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'Modifica';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get settingsDeleteRosterTitle => 'Eliminare il piano turni?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'verranno rimossi $count turni',
      one: 'verrà rimosso 1 turno',
    );
    return 'Eliminare \"$label\"? Le sveglie in sospeso verranno annullate e $_temp0.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return '\"$label\" eliminato';
  }

  @override
  String get commonActive => 'Attivo';

  @override
  String get commonUpcoming => 'In arrivo';

  @override
  String get commonPast => 'Passato';

  @override
  String get settingsWorkHistory => 'STORICO LAVORO';

  @override
  String get settingsWorkHistorySub =>
      'Rivedi ed esporta i turni personalizzati completati per verificare le buste paga.';

  @override
  String get settingsViewWorkHistory => 'Vedi ed esporta lo storico';

  @override
  String get settingsPreferences => 'PREFERENZE';

  @override
  String get settingsPreferencesSub =>
      'Come vengono mostrati i tuoi turni nell\'app.';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsThemeSub =>
      'Scuro è il tema predefinito di Rostrik. Chiaro usa una calda palette color crema.';

  @override
  String get settings24h => 'Usa formato 24 ore';

  @override
  String get settings24hOn => 'Orari mostrati come 14:30';

  @override
  String get settings24hOff => 'Orari mostrati come 02:30 PM';

  @override
  String get settingsWeekStartTitle => 'Inizia il calendario di lunedì';

  @override
  String get settingsWeekStartMon => 'Le settimane iniziano di lunedì';

  @override
  String get settingsWeekStartSun => 'Le settimane iniziano di domenica';

  @override
  String get settingsTimelineOpensOn => 'L\'agenda si apre su';

  @override
  String get commonList => 'Elenco';

  @override
  String get commonMonth => 'Mese';

  @override
  String get settingsCalendar => 'CALENDARIO';

  @override
  String get settingsCalendarSync =>
      'Sincronizza con Google / calendario del dispositivo';

  @override
  String get settingsCalendarSyncSub =>
      'Copia automaticamente i tuoi turni in un calendario \"Rostrik Roster\" dedicato sul telefono.';

  @override
  String get settingsCalSyncOff =>
      'Sincronizzazione disattivata. Gli eventi futuri di \"Rostrik Roster\" sono stati rimossi.';

  @override
  String get settingsCalSyncMirroring =>
      'Copia dei turni nel calendario \"Rostrik Roster\"…';

  @override
  String get settingsCalPermNeeded =>
      'Serve l\'accesso al calendario per sincronizzare i turni.';

  @override
  String get settingsCalBlocked =>
      'L\'accesso al calendario è bloccato. Attivalo nelle impostazioni di sistema per sincronizzare.';

  @override
  String get settingsCalOpenSettings => 'Impostazioni';

  @override
  String get settingsCalUnsupported =>
      'La sincronizzazione del calendario non è disponibile su questo dispositivo.';

  @override
  String get settingsDangerZone => 'ZONA PERICOLOSA';

  @override
  String get settingsDangerZoneSub =>
      'Elimina turni, sveglie e impostazioni e riavvia la configurazione da zero.';

  @override
  String get settingsResetAppData => 'Reimposta dati dell\'app';

  @override
  String get settingsResetTitle => 'Reimpostare l\'app?';

  @override
  String get settingsResetBody =>
      'Sei sicuro? Verranno eliminati turni, sveglie e impostazioni.';

  @override
  String get settingsResetConfirm => 'Reimposta';

  @override
  String get dashNoUpcomingShifts => 'Nessun turno in arrivo';

  @override
  String get dashEnjoyTimeOff => 'Goditi il riposo.';

  @override
  String get dashInProgress => 'IN CORSO';

  @override
  String get dashRotation => 'Rotazione';

  @override
  String get dashAlarmsCantRing =>
      'Le sveglie non possono suonare in modo affidabile';

  @override
  String get dashNotifsOffIssue =>
      'Le notifiche sono disattivate: una sveglia che suona non può mostrare la sua schermata né essere spenta.';

  @override
  String get dashOpenSettings => 'Apri impostazioni';

  @override
  String get dashExactBlockedIssue =>
      'Le sveglie esatte sono bloccate: nessuna sveglia può essere programmata.';

  @override
  String get dashAlarmsWontTakeOverScreen =>
      'Le sveglie non occuperanno lo schermo';

  @override
  String get dashFullScreenBlockedIssue =>
      'Le sveglie a schermo intero sono disattivate: a telefono bloccato vedrai una notifica invece della schermata della sveglia.';

  @override
  String get dashAllow => 'Consenti';

  @override
  String get dashSlideToSkip => 'Scorri per saltare questa sveglia';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Scorri per saltare tutte le $count sveglie',
      one: 'Scorri per saltare la sveglia',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'Annulla prossima sveglia · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Salta tutte le $count sveglie di questo turno',
      one: 'Salta la sveglia di questo turno',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'Mantieni sveglia';

  @override
  String get dashMyRotation => 'La mia rotazione';

  @override
  String get dashCalendarUpcoming => 'Calendario e prossimi turni';

  @override
  String get dashNextShifts => 'Prossimi turni';

  @override
  String get dashOpenTimeline => 'Apri agenda';

  @override
  String heroStartsIn(String countdown) {
    return 'Inizia tra $countdown';
  }

  @override
  String heroEndsIn(String countdown) {
    return 'Finisce tra $countdown';
  }

  @override
  String get heroStartsInPrefix => 'Inizia tra';

  @override
  String get heroEndsInPrefix => 'Finisce tra';

  @override
  String heroStartsTodayAt(String time) {
    return 'Inizia oggi alle $time';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'Iniziato oggi alle $time';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'Inizia domani alle $time';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'Iniziato ieri alle $time';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'Inizia ieri alle $time';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return 'Inizia $date alle $time';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return 'Iniziato $date alle $time';
  }

  @override
  String get shiftTypeDayShift => 'Turno diurno';

  @override
  String get shiftTypeAfternoonShift => 'Turno pomeridiano';

  @override
  String get shiftTypeNightShift => 'Turno notturno';

  @override
  String heroDayXofY(int x, int y, String label) {
    return 'Giorno $x di $y – $label';
  }

  @override
  String get heroOffTomorrow => 'Riposo domani';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Riposo tra $days giorni',
      one: 'Riposo tra 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'Rientro domani';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Rientro tra $days giorni',
      one: 'Rientro tra 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'Riposo';

  @override
  String durationDayShort(int d) {
    return '$d g';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d g $h h';
  }

  @override
  String get alarmsTitle => 'Sveglie';

  @override
  String get alarmsAddTooltip => 'Aggiungi sveglia';

  @override
  String get alarmsSortTooltip => 'Ordina sveglie';

  @override
  String get alarmsSortByTime => 'Per orario';

  @override
  String get alarmsSortByShiftType => 'Per tipo di turno';

  @override
  String get alarmsEmptyTitle => 'Ancora nessuna sveglia.';

  @override
  String get alarmsEmptyBody => 'Tocca + per aggiungerne una.';

  @override
  String get alarmsNextAlarm => 'PROSSIMA SVEGLIA';

  @override
  String get alarmsHolidayMode => 'Modalità vacanza';

  @override
  String get alarmsHolidayModeSub => 'Sveglie in pausa: non suonerà nulla.';

  @override
  String get alarmsNoUpcoming => 'Nessuna sveglia di turno in arrivo';

  @override
  String get alarmsNoUpcomingSub =>
      'Aggiungi una sveglia che segue la rotazione o genera un piano turni.';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'per il tuo turno ($type) · $day';
  }

  @override
  String get commonToday => 'Oggi';

  @override
  String get commonTomorrow => 'Domani';

  @override
  String get alarmsOffWontRing => 'Disattivata: non suonerà';

  @override
  String get alarmsNoUpcomingRing => 'Nessun suono programmato';

  @override
  String alarmsNextRing(String day, String time) {
    return 'Prossimo suono: $day alle $time';
  }

  @override
  String get alarmsSwipeToDelete => 'Scorri per eliminare';

  @override
  String get alarmsRingsOnceAutoDelete => 'Suona una volta · si elimina';

  @override
  String get alarmsRingsOnce => 'Suona una sola volta';

  @override
  String get alarmsYourShift => 'Il tuo turno';

  @override
  String alarmsShiftsOfType(String type) {
    return 'Turni ($type)';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'Orario esatto · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$shift: $lead prima · predefinito';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$shift: $lead prima';
  }

  @override
  String get createEditAlarm => 'Modifica sveglia';

  @override
  String get createNewAlarm => 'Nuova sveglia';

  @override
  String get createDefaultLabel => 'Sveglia';

  @override
  String get createFallbackLabel => 'Sveglia';

  @override
  String get createPickBecomesDefault =>
      'La tua scelta diventa quella predefinita per le nuove sveglie.';

  @override
  String get createSelectFromFiles => 'Scegli da File';

  @override
  String get createFilesSub => 'Scegli un file audio salvato sul dispositivo';

  @override
  String get createSelectSystemTone => 'Scegli suoneria di sistema';

  @override
  String get createSystemToneSub =>
      'Scegli tra i suoni sveglia del dispositivo';

  @override
  String get createAlarmTiming => 'Quando suona';

  @override
  String get createLeadTimeMode => 'Anticipo';

  @override
  String get createExactTimeMode => 'Orario esatto';

  @override
  String createFiresAt(String time) {
    return 'Suona alle $time';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return '$lead prima dell\'inizio del turno';
  }

  @override
  String get createLinkedShift => 'Turno collegato';

  @override
  String get createRepeatOn => 'Ripeti il';

  @override
  String get createLabelField => 'Nome';

  @override
  String get createLabelHint => 'es. Sveglia';

  @override
  String get createCriticalShift => 'Turno critico';

  @override
  String get createCriticalShiftSub =>
      'Scuoti per spegnere · tieni premuto 3 secondi come riserva';

  @override
  String get createRingtone => 'Suoneria';

  @override
  String get commonStop => 'Stop';

  @override
  String get commonPlay => 'Riproduci';

  @override
  String get createVibrate => 'Vibrazione';

  @override
  String get createRepeat => 'Ripeti';

  @override
  String get createRepeatRotation => 'Rotazione';

  @override
  String get createRepeatWeekly => 'Settimanale';

  @override
  String get createRepeatOneTime => 'Una volta';

  @override
  String get createPickOneDay => 'Scegli almeno un giorno';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonSaveChanges => 'Salva modifiche';

  @override
  String get createTimeBeforeShift => 'Tempo prima del turno';

  @override
  String get commonOk => 'OK';

  @override
  String get sleepTitle => 'Sonno';

  @override
  String get sleepTargetHeader => 'OBIETTIVO DI SONNO';

  @override
  String get sleepTargetSub =>
      'Quante ore vuoi dormire. Rostrik conta a ritroso dalla prossima sveglia per stabilire l\'ora di andare a letto stasera.';

  @override
  String get sleepRemindersHeader => 'PROMEMORIA';

  @override
  String get sleepWindDownHeader => 'ANTICIPO PER RILASSARSI';

  @override
  String get sleepWindDownSub =>
      'Quanto prima di andare a letto arriva il promemoria per rilassarti.';

  @override
  String get sleepSoundsHeader => 'SUONI PER DORMIRE';

  @override
  String get sleepSoundsSub =>
      'Rumore bianco e marrone per addormentarti. Scegli un timer e tocca un suono.';

  @override
  String get sleepNothingToPlan => 'Niente da pianificare stasera';

  @override
  String get sleepNothingToPlanSub =>
      'Aggiungi un turno e Rostrik creerà un orario per andare a letto su misura per la tua prossima sveglia.';

  @override
  String get sleepTransitionDay => 'GIORNO DI TRANSIZIONE';

  @override
  String get sleepTransitionTitle =>
      'Domani c\'è il turno di notte. Puoi dormire di più.';

  @override
  String get sleepTransitionBody =>
      'È un giorno di transizione: hai un riposo prima delle notti, quindi niente sveglia presto. Accumula riposo ora e lascia che il corpo vada a letto più tardi stasera.';

  @override
  String get sleepRestRecovery => 'RIPOSO E RECUPERO';

  @override
  String get sleepNoEarlyAlarm => 'Niente sveglia presto';

  @override
  String get sleepRestBody =>
      'Il prossimo turno è tra più di un giorno, quindi stasera non c\'è sveglia da pianificare. Dormi con i tuoi ritmi e recupera: Rostrik preparerà il piano quando si avvicina.';

  @override
  String get sleepTonightsPlan => 'PIANO PER STASERA';

  @override
  String get sleepTargetBedtime => 'Ora di andare a letto';

  @override
  String get sleepWindDownStat => 'Rilassarsi';

  @override
  String get sleepWakeUpStat => 'Sveglia';

  @override
  String get sleepDurationStat => 'Durata';

  @override
  String get sleepBedtimeReminder => 'Promemoria per andare a letto';

  @override
  String sleepNudgeAtBedtime(String time) {
    return 'Avvisami alle $time di andare a letto';
  }

  @override
  String get sleepBedtimeSub => 'Un avviso quando è ora di andare a letto';

  @override
  String get sleepWindDownReminder => 'Promemoria per rilassarsi';

  @override
  String sleepNudgeAtWindDown(String time) {
    return 'Avvisami alle $time di iniziare a rilassarmi';
  }

  @override
  String get sleepWindDownReminderSub =>
      'Un avviso anticipato per iniziare a rilassarti';

  @override
  String get commonOff => 'No';

  @override
  String get sleepSoundWhiteNoise => 'Rumore bianco';

  @override
  String get sleepSoundPinkNoise => 'Rumore rosa';

  @override
  String get sleepSoundBrownNoise => 'Rumore marrone';

  @override
  String get sleepSoundFan => 'Ventilatore';

  @override
  String get sleepSoundOcean => 'Oceano';

  @override
  String get sleepSoundRain => 'Pioggia';

  @override
  String get manageTitle => 'Gestisci';

  @override
  String get manageRosterTools => 'STRUMENTI TURNI';

  @override
  String get manageRosterToolsSub =>
      'Crea e regola i turni che guidano sveglie e piano del sonno.';

  @override
  String get manageGenerateRotation => 'Genera rotazione';

  @override
  String get manageGenerateRotationSub =>
      'Crea uno schema di turni ripetuto da un modello.';

  @override
  String get manageAddCustomShift => 'Aggiungi turno singolo';

  @override
  String get manageAddCustomShiftSub =>
      'Inserisci un turno isolato nel tuo piano.';

  @override
  String get manageMarkLeave => 'Segna ferie / assenze';

  @override
  String get manageMarkLeaveSub =>
      'Dipingi in un colpo i giorni di assenza (ferie, malattia).';

  @override
  String get managePauseSchedule => 'Metti in pausa i turni';

  @override
  String get managePausedSub =>
      'Modalità vacanza ATTIVA: sveglie silenziate, i tuoi turni sono al sicuro.';

  @override
  String get manageNotPausedSub =>
      'Modalità vacanza: silenzia le sveglie mentre sei fuori turno.';

  @override
  String get markLeaveTitle => 'Segna ferie';

  @override
  String get markLeaveIntro =>
      'Tocca i giorni di assenza, scegli un motivo e applica. Le sveglie di quei giorni non suoneranno e i turni restano intatti.';

  @override
  String get leaveAnnual => 'Ferie';

  @override
  String get leaveSick => 'Malattia';

  @override
  String get leavePublicHoliday => 'Festivo';

  @override
  String get markLeaveReason => 'Motivo';

  @override
  String get markLeaveFallbackReason => 'assenza';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turni segnati come $reason.',
      one: '1 turno segnato come $reason.',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => 'Scegli i giorni da segnare';

  @override
  String get markLeaveNoShifts => 'Nessun turno in quei giorni';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Applica a $count turni',
      one: 'Applica a 1 turno',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => 'Storico lavoro';

  @override
  String get workHistoryExportTooltip => 'Esporta storico';

  @override
  String workHistoryExportFailed(String error) {
    return 'Impossibile esportare lo storico: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turni lavorati',
      one: '1 turno lavorato',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours h';
  }

  @override
  String get commonPaused => 'In pausa';

  @override
  String workHistoryPausedReason(String reason) {
    return 'In pausa · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'Rotazione';

  @override
  String get workHistoryAdHocBadge => 'Extra';

  @override
  String get workHistoryEmptyTitle => 'Ancora nessun turno completato';

  @override
  String get workHistoryEmptyBody =>
      'I turni lavorati, a rotazione o personalizzati, compaiono qui una volta terminati, pronti da esportare per verificare le buste paga.';

  @override
  String get workHistoryShareSubject => 'Storico lavoro Rostrik';

  @override
  String get workHistoryShareText =>
      'Il mio storico lavoro esportato da Rostrik.';

  @override
  String get shiftEdAddShift => 'Aggiungi turno';

  @override
  String get shiftEdEditShift => 'Modifica turno';

  @override
  String get shiftEdDate => 'Data';

  @override
  String get shiftEdPickDate => 'Scegli data';

  @override
  String get shiftEdStarts => 'Inizio';

  @override
  String get shiftEdEnds => 'Fine';

  @override
  String get shiftEdPickTime => 'Scegli orario';

  @override
  String get shiftEdEndsNextDay => 'Termina il giorno dopo';

  @override
  String get shiftEdPauseTitle => 'Metti in pausa / annulla questo turno';

  @override
  String get shiftEdPausedSub =>
      'La sveglia non suonerà. Resta nel calendario come registrazione.';

  @override
  String get shiftEdNotPausedSub =>
      'Segna un giorno libero (malattia, ferie, festivo) senza eliminarlo.';

  @override
  String get shiftEdReasonOptional => 'Motivo (facoltativo)';

  @override
  String get dayShifts => 'Turni';

  @override
  String get dayActivities => 'Attività';

  @override
  String get dayAddAnotherShift => 'Aggiungi un altro turno';

  @override
  String get dayAddActivity => 'Aggiungi attività';

  @override
  String get dayAddActivitySub => 'Evento, promemoria o compleanno';

  @override
  String get dayReminder => 'Promemoria';

  @override
  String get actEditActivity => 'Modifica attività';

  @override
  String get actLeadAtTime => 'All\'orario';

  @override
  String get actLead10Min => '10 min prima';

  @override
  String get actLead30Min => '30 min prima';

  @override
  String get actLead1Hour => '1 ora prima';

  @override
  String get actLead1Day => '1 giorno prima';

  @override
  String get actEvent => 'Evento';

  @override
  String get actTask => 'Attività';

  @override
  String get actBirthday => 'Compleanno';

  @override
  String get actTitleField => 'Titolo';

  @override
  String get actAllDay => 'Tutto il giorno';

  @override
  String get actTimeField => 'Orario';

  @override
  String get actRemindMe => 'Ricordamelo';

  @override
  String get actRemindMeSub =>
      'Una notifica discreta, separata dalle sveglie dei turni.';

  @override
  String get actRemindAt => 'Ricorda alle';

  @override
  String get actReminderPassed =>
      'Quell\'orario è già passato: questo promemoria non arriverà.';

  @override
  String get actNoteOptional => 'Nota (facoltativa)';

  @override
  String get actCompleted => 'Completata';

  @override
  String get tipDashboardTitle => 'La tua home';

  @override
  String get tipDashboardBody =>
      'Il tuo punto di partenza. Vedi il prossimo turno con il conto alla rovescia in tempo reale e a che punto sei della rotazione. Tocca un riquadro per i dettagli.';

  @override
  String get tipTimelineTitle => 'Tutti i tuoi turni';

  @override
  String get tipTimelineBody =>
      'In alto passi dall\'elenco al calendario mensile. Tocca un giorno per modificare un turno o aggiungere un evento, un\'attività o un compleanno.';

  @override
  String get tipManageTitle => 'Crea e modifica';

  @override
  String get tipManageBody =>
      'Crea una rotazione, aggiungi un turno singolo (straordinario) o metti in pausa tutti i turni per le ferie, tutto da qui.';

  @override
  String get tipAlarmsTitle => 'Le tue sveglie';

  @override
  String get tipAlarmsBody =>
      'Tutte le sveglie create dai turni più quelle aggiunte da te. Toccane una per cambiare orario o suoneria, o trasformala in una sveglia da turno critico che si spegne scuotendo.';

  @override
  String get tipSleepTitle => 'Piano del sonno';

  @override
  String get tipSleepBody =>
      'Un piano per rilassarti che segue i tuoi turni: fissa un obiettivo di sonno e arriva riposato al prossimo turno.';

  @override
  String get tipReplayHint =>
      'Rivedili quando vuoi in Impostazioni › Come funziona.';

  @override
  String get tipDontShow => 'Non mostrare più';

  @override
  String get tipGotIt => 'Ho capito';

  @override
  String get timelineListView => 'Elenco';

  @override
  String get timelineMonthView => 'Mese';

  @override
  String get shiftTypeAftShort => 'Pom.';

  @override
  String get timelineNoShifts =>
      'Nessun turno programmato. Tocca + per aggiungerne uno.';

  @override
  String timelineNoMatch(String filter) {
    return 'Nessun turno corrisponde al filtro $filter.';
  }

  @override
  String get timelineRestDay => 'Giorno di riposo';

  @override
  String timelineRestDayReason(String reason) {
    return 'Giorno di riposo · $reason';
  }

  @override
  String get timelineAllDay => 'Tutto il giorno';

  @override
  String get calLegendPausedLeave => 'In pausa / Ferie';

  @override
  String get calLegendActivity => 'Attività';

  @override
  String get filterAll => 'Tutti';

  @override
  String get filterWork => 'Lavoro';

  @override
  String get criticalHoldToDismiss => 'Oppure tieni premuto per spegnere';

  @override
  String get patternChoosePattern => 'Scegli uno schema';

  @override
  String get patternRotatingSwings => 'Rotazioni miste';

  @override
  String get patternDaySwings => 'Solo turni diurni';

  @override
  String get patternNightSwings => 'Solo turni notturni';

  @override
  String get patternShiftTimes => 'Orari dei turni';

  @override
  String get patternGenerate => 'Imposta il giorno 1 e genera';

  @override
  String get patternSelectDay1 => 'Scegli il prossimo giorno 1';

  @override
  String patternDay1Hint(String label) {
    return 'Primo giorno del tuo blocco ($label)';
  }

  @override
  String get patternNextDay1 => 'Prossimo giorno 1';

  @override
  String get patternUseThisDate => 'Usa questa data';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turni generati',
      one: '1 turno generato',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'Generazione non riuscita: $error';
  }

  @override
  String get patternFirstBlockFallback => 'primo';

  @override
  String get patternBuildCustom => 'Crea turni personalizzati';

  @override
  String get patternBuildCustomSub =>
      'Nessuno schema va bene? Componi i tuoi blocchi.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pomeriggi',
      one: '1 pomeriggio',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n notti',
      one: '1 notte',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '$n di riposo';
  }

  @override
  String get builderNewRoster => 'Nuovo piano turni';

  @override
  String get builderEditRoster => 'Modifica piano turni';

  @override
  String get builderNewSub => 'Imposta il tuo schema di rotazione';

  @override
  String get builderEditSub => 'Modifica e sostituisci questo piano salvato';

  @override
  String get builderNameHint => 'Nome (es. La mia rotazione di 14 giorni)';

  @override
  String get builderCycleLength => 'DURATA DEL CICLO';

  @override
  String get builderStartDate => 'DATA DI INIZIO';

  @override
  String get builderShiftBlocks => 'BLOCCHI DI TURNO';

  @override
  String get builderAddShiftBlock => 'Aggiungi blocco di turno';

  @override
  String get builderCreateRoster => 'Crea piano turni';

  @override
  String get builderSaveChanges => 'Salva modifiche';

  @override
  String get builderReplaceWarning =>
      'Salvando sostituisci questo piano. Ferie e assenze segnate verranno azzerate.';

  @override
  String get builderBackToOptions => 'Torna alle opzioni';

  @override
  String get builderOrImport => 'OPPURE IMPORTA UN PIANO ESISTENTE';

  @override
  String get builderImportViaAi => 'Importa con l\'IA';

  @override
  String get builderScanning => 'Scansione…';

  @override
  String get builderScanInstead => 'Scansiona una foto dei turni';

  @override
  String get builderCustomChip => 'Altro';

  @override
  String get builderCycleLengthLabel => 'Durata del ciclo';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'Scegli una data';

  @override
  String get builderNoBlocksYet => 'Ancora nessun blocco';

  @override
  String get builderNoBlocksSub =>
      'Aggiungi blocchi di turno per definire la rotazione';

  @override
  String builderDaysLine(String ranges) {
    return 'Giorni $ranges';
  }

  @override
  String get builderEditBlock => 'Modifica blocco';

  @override
  String get builderRemoveBlock => 'Rimuovi blocco';

  @override
  String get builderPickRosterStart => 'Scegli la data di inizio del piano';

  @override
  String get builderPickScanStart =>
      'Scegli la data di inizio del piano scansionato';

  @override
  String get builderScanCamera => 'Scansiona con la fotocamera';

  @override
  String get builderImportScreenshot => 'Importa uno screenshot';

  @override
  String builderScanFailed(String error) {
    return 'Scansione non riuscita: $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'Nessun orario riconosciuto. Prova a ritagliare più vicino alla tabella.';

  @override
  String get builderCustomRosterFallback => 'Turni personalizzati';

  @override
  String get builderScannedRosterFallback => 'Turni scansionati';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Piano aggiornato: $count turni programmati',
      one: 'Piano aggiornato: 1 turno programmato',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Creato: $count turni programmati',
      one: 'Creato: 1 turno programmato',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'Impossibile creare il piano turni: $error';
  }

  @override
  String get builderRosterImported => 'Turni importati nel calendario';

  @override
  String builderCouldNotImport(String error) {
    return 'Impossibile importare i turni: $error';
  }

  @override
  String get blockAddTitle => 'Aggiungi blocco di turno';

  @override
  String get blockEditTitle => 'Modifica blocco di turno';

  @override
  String get blockStart => 'Inizio';

  @override
  String get blockEnd => 'Fine';

  @override
  String get blockTapDays => 'Tocca i giorni coperti da questo turno';

  @override
  String get blockUntappedOff => 'I giorni non toccati sono di riposo.';

  @override
  String blockOverlap(String ranges) {
    return 'Questo orario si sovrappone a un altro turno nel giorno $ranges: cambia l\'orario o quei giorni.';
  }

  @override
  String get blockAdd => 'Aggiungi blocco';

  @override
  String get blockSave => 'Salva blocco';

  @override
  String get aiPromptCopied =>
      'Prompt copiato! Incollalo nella tua app di IA insieme ai tuoi turni.';

  @override
  String get aiNothingToPaste => 'Negli appunti non c\'è nulla da incollare.';

  @override
  String get aiNoValidShifts =>
      'Nessun turno valido rilevato. Assicurati di aver usato il prompt copiato.';

  @override
  String get aiStep1 => 'Copia il prompt';

  @override
  String get aiCopied => 'Copiato!';

  @override
  String get aiCopyPrompt => 'Copia prompt IA';

  @override
  String get aiStep1Sub =>
      'Incollalo in ChatGPT, Gemini o un\'altra app di IA, aggiungi il testo dei turni o una foto/screenshot e invia.';

  @override
  String get aiStep2 => 'Incolla la risposta dell\'IA';

  @override
  String get aiPaste => 'Incolla';

  @override
  String get aiParsePreview => 'Analizza e anteprima';

  @override
  String get aiStep3 => 'Controlla i turni rilevati';

  @override
  String get aiStep3Sub =>
      'Tocca un\'etichetta per passare tra Giorno, Pomeriggio e Notte se l\'IA ha sbagliato.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importa $count giorni',
      one: 'Importa 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'Trasforma qualsiasi testo di turni in turni veri con l\'aiuto di un\'app di IA.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0 · $working di lavoro · $off di riposo';
  }

  @override
  String get draftReviewTitle => 'Controlla i turni scansionati';

  @override
  String draftRemovedDay(String date) {
    return '$date rimosso';
  }

  @override
  String get draftUndo => 'Annulla';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni salvati nei turni',
      one: '1 giorno salvato nei turni',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'Nome del piano';

  @override
  String get draftScannedImage => 'Immagine scansionata';

  @override
  String get draftScannedImageSub =>
      'Tocca l\'immagine per ingrandirla e confrontare';

  @override
  String get draftImageError => 'Impossibile mostrare l\'immagine scansionata.';

  @override
  String get draftRemove => 'Rimuovi';

  @override
  String get draftNoEndTime =>
      'Scansionato senza orario di fine: impostalo per poter salvare.';

  @override
  String get draftTime => 'Orario';

  @override
  String get draftSetEnd => 'Imposta fine';

  @override
  String get draftConfirmSave => 'Conferma e salva';

  @override
  String notifBeforeYourShift(String type) {
    return 'Prima del tuo turno ($type)';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind alle $time';
  }

  @override
  String get notifWindDownTitle => 'È ora di rilassarsi 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'Metti via gli schermi: si va a letto alle $time.';
  }

  @override
  String get notifWindDownBody =>
      'Metti via gli schermi e inizia a rilassarti per la notte.';

  @override
  String get notifBedtimeTitle => 'A letto 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return 'Vai a letto per dormire ~$hours h prima del tuo $shift: sveglia alle $time.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return 'Vai a letto per raggiungere il tuo obiettivo di $hours h di sonno.';
  }

  @override
  String get notifShiftDay => 'turno diurno';

  @override
  String get notifShiftAfternoon => 'turno pomeridiano';

  @override
  String get notifShiftNight => 'turno notturno';

  @override
  String get notifShiftGeneric => 'turno';

  @override
  String get notifTrialEndsTitle => 'La tua prova di Rostrik finisce domani';

  @override
  String get notifTrialEndsBody =>
      'Sblocca l\'accesso completo per continuare a far suonare le sveglie dei turni.';

  @override
  String seedWakeUpLabel(String type) {
    return 'Sveglia ($type)';
  }

  @override
  String get seedShiftGeneric => 'Turno';

  @override
  String commonListAnd(String items, String last) {
    return '$items e $last';
  }

  @override
  String get soundClassic => 'Classica';

  @override
  String get soundSiren => 'Sirena';

  @override
  String get soundDigital => 'Digitale';

  @override
  String get soundChime => 'Carillon';

  @override
  String get patternFirstResponder => 'Standard soccorso';

  @override
  String get ocrCropTitle => 'Ritaglia SOLO la tua riga, non tutta la squadra';

  @override
  String get draftNameHint => 'es. Turni di maggio';
}
