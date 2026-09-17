// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'Avant de commencer';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik est conçu pour vous réveiller à chaque poste. Soyons honnêtes : sur tout téléphone, c\'est le système d\'exploitation – et non l\'application – qui a le dernier mot. Dans de rares cas, il peut retarder ou couper n\'importe quelle application de réveil (économie de batterie agressive, arrêt forcé ou juste après une mise à jour du système).';

  @override
  String get legalBodyBackupAdvice =>
      'Pour les postes que vous ne pouvez absolument pas manquer, gardez un second réveil de secours. C\'est une bonne habitude avec n\'importe quel réveil, y compris celui de votre téléphone.';

  @override
  String get legalReviewAndAccept => 'Veuillez lire et accepter :';

  @override
  String get legalPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get legalTermsOfUse => 'Conditions d\'utilisation';

  @override
  String get legalConsentCheckbox =>
      'Je comprends que le système d\'exploitation peut affecter toute application de réveil, et j\'accepte la Politique de confidentialité et les Conditions d\'utilisation.';

  @override
  String get legalAgreeContinue => 'Accepter et continuer';

  @override
  String get legalUpdatedTitle => 'Nous avons mis à jour nos conditions';

  @override
  String get legalUpdatedBody =>
      'Notre Politique de confidentialité et nos Conditions d\'utilisation ont changé. Prenez un instant pour les consulter avant de continuer.';

  @override
  String get legalUpdatedAccept => 'J\'ai lu et j\'accepte';

  @override
  String get commonSaving => 'Enregistrement…';

  @override
  String get commonCouldNotOpenLink => 'Impossible d\'ouvrir le lien.';

  @override
  String get welcomeTagline =>
      'Le réveil intelligent pensé pour le travail posté.';

  @override
  String get welcomeSubTagline =>
      'Des alarmes qui suivent votre planning en rotation, pas seulement les jours de semaine.';

  @override
  String welcomeTrialTitle(int days) {
    return 'Essai gratuit de $days jours';
  }

  @override
  String get welcomeTrialBody =>
      'Accès complet à toutes les fonctionnalités, sans carte bancaire. Ensuite, un achat unique, jamais d\'abonnement.';

  @override
  String get welcomeGetStarted => 'Commencer';

  @override
  String get welcomeSkip => 'Passer / Configurer plus tard';

  @override
  String get welcomeTimeFormat => 'Format de l\'heure';

  @override
  String get welcomeWeekStarts => 'Début de semaine';

  @override
  String get common12h => '12 h';

  @override
  String get common24h => '24 h';

  @override
  String get commonSundayShort => 'Dim';

  @override
  String get commonMondayShort => 'Lun';

  @override
  String get rosterTypeTitle => 'Choisissez un type de planning';

  @override
  String get rosterTypeQuestion => 'À quoi ressemble votre planning ?';

  @override
  String get rosterTypeDay => 'Postes de jour';

  @override
  String get rosterTypeNight => 'Postes de nuit';

  @override
  String get rosterTypeRotating => 'En rotation';

  @override
  String get rosterTypeCustom => 'Personnalisé';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonComingSoon => 'Bientôt';

  @override
  String get permsTitle => 'Autorisations';

  @override
  String get permsIntro =>
      'Rostrik a besoin de quelques autorisations pour déclencher les alarmes de façon fiable. Vous pourrez les modifier plus tard dans les réglages du système.';

  @override
  String get permsNotifications => 'Notifications';

  @override
  String get permsNotificationsSub =>
      'Nécessaires pour afficher l\'écran de réveil.';

  @override
  String get permsExactAlarms => 'Alarmes exactes';

  @override
  String get permsExactAlarmsSub =>
      'Permet aux alarmes de sonner à l\'heure exacte prévue.';

  @override
  String get permsBatteryUnrestricted => 'Batterie non restreinte';

  @override
  String get permsBatteryGrantedSub =>
      'Les alarmes sont protégées de l\'optimisation de la batterie.';

  @override
  String get permsBatteryDeniedSub =>
      'Certains téléphones ferment les apps en arrière-plan. Touchez pour corriger.';

  @override
  String get permsUnrestrictedBadge => 'Non restreinte';

  @override
  String get batteryDialogTitle => 'Garder les alarmes actives';

  @override
  String get batteryDialogIntro =>
      'Certains téléphones (Samsung, Xiaomi, Oppo, Huawei) ferment agressivement les apps en arrière-plan pour économiser la batterie. Si cela arrive à Rostrik, une alarme peut être coupée avant de sonner.';

  @override
  String get batteryDialogMarkUnrestricted =>
      'Réglez Rostrik sur Non restreinte pour l\'éviter :';

  @override
  String get batteryStep1 =>
      'Ouvrez les réglages de cette app (bouton ci-dessous).';

  @override
  String get batteryStep2 =>
      'Touchez Batterie (ou « Utilisation de la batterie par l\'app »).';

  @override
  String get batteryStep3 =>
      'Choisissez Non restreinte (et non « Optimisée » ou « Restreinte »).';

  @override
  String get batteryStep4 =>
      'Si « Autoriser l\'activité en arrière-plan » apparaît, activez-le aussi.';

  @override
  String get batteryStep5 =>
      'Désactivez « Suspendre l\'activité si l\'app est inutilisée » (ou « Supprimer les autorisations si l\'app est inutilisée ») pour qu\'Android ne retire pas les autorisations d\'alarme pendant votre absence.';

  @override
  String get commonNotNow => 'Plus tard';

  @override
  String get batteryGoToSettings => 'Ouvrir les réglages';

  @override
  String get armEngineTitle => 'Activez vos alarmes';

  @override
  String get armEngineRosterReady => 'Votre planning est prêt';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · début le $date';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'Nous activerons des alarmes de réveil ($summary) avant chaque poste correspondant.';
  }

  @override
  String get armEngineArming => 'Activation…';

  @override
  String get armEngineCta => 'Automatiser mes alarmes';

  @override
  String get armEngineLeadTimeLabel => 'Avance de l\'alarme';

  @override
  String get armEngineLeadTimeHelper =>
      'Combien de temps avant le début du poste l\'alarme sonne.';

  @override
  String get shiftTypeDay => 'Jour';

  @override
  String get shiftTypeAfternoon => 'Après-midi';

  @override
  String get shiftTypeNight => 'Nuit';

  @override
  String get shiftTypeOff => 'Repos';

  @override
  String get weekdaysNone => 'Aucun jour';

  @override
  String get weekdaysEveryDay => 'Tous les jours';

  @override
  String get weekdaysWeekdays => 'En semaine';

  @override
  String get weekdaysWeekends => 'Le week-end';

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
    return '$h h $m';
  }

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonSkip => 'Passer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonNext => 'Suivant';

  @override
  String get walkthroughIntroTitle => 'Visite en 60 secondes';

  @override
  String get walkthroughIntroBodyTwo =>
      'Deux choses qui font tout l\'intérêt de Rostrik. Vous pouvez passer à tout moment.';

  @override
  String get walkthroughIntroBodyOne =>
      'Ce qui fait tout l\'intérêt de Rostrik. Vous pouvez passer à tout moment.';

  @override
  String get walkthroughPaintLabel => 'Peignez votre planning';

  @override
  String get walkthroughPaintDetail =>
      'Touchez vos jours travaillés, c\'est tout.';

  @override
  String get walkthroughShakeLabel => 'Secouer pour arrêter';

  @override
  String get walkthroughShakeDetail =>
      'Une secousse franche arrête une alarme critique.';

  @override
  String get walkthroughTryEach => 'Touchez Suivant pour essayer chacune.';

  @override
  String get walkthroughTryIt => 'Touchez Suivant pour essayer.';

  @override
  String get walkthroughPaintBody =>
      'Touchez vos jours travaillés. Dans l\'éditeur réel, vous ajoutez d\'autres blocs (après-midi, nuits) de la même manière.';

  @override
  String get walkthroughPaintPrompt =>
      'Touchez un jour pour y peindre un poste de jour.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bravo ! Ces $count jours forment un bloc de jour. Les jours non touchés restent en repos. C\'est aussi simple que ça.',
      one:
          'Bravo ! Ce jour est un bloc de jour. Les jours non touchés restent en repos. C\'est aussi simple que ça.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'Les alarmes de poste critique exigent une secousse franche et soutenue pour s\'arrêter : un geste à moitié endormi ne suffit pas. Essayez : secouez votre téléphone.';

  @override
  String get walkthroughShakeSuccess => 'C\'est ça !';

  @override
  String get walkthroughShakeSuccessDetail =>
      'C\'est exactement ainsi que vous arrêterez une alarme critique.';

  @override
  String get walkthroughDoneTitle => 'Tout est prêt';

  @override
  String get walkthroughDoneBody =>
      'Créez un planning à tout moment depuis Gérer, et revoyez cette visite dans Réglages → Aide.';

  @override
  String get navDashboard => 'Accueil';

  @override
  String get navTimeline => 'Planning';

  @override
  String get navManage => 'Gérer';

  @override
  String get navAlarms => 'Alarmes';

  @override
  String get navSleep => 'Sommeil';

  @override
  String get onbPatternTitle => 'Choisissez votre rotation';

  @override
  String get purchaseTrialEnded => 'Votre essai gratuit est terminé';

  @override
  String get purchaseBody =>
      'Débloquez Rostrik une fois pour que vos alarmes de poste continuent de sonner. Votre planning, vos alarmes et vos réglages sont en sécurité : tout reprend dès le déblocage.';

  @override
  String get purchaseAlarmsWontRing =>
      'D\'ici là, les alarmes ne sonneront pas.';

  @override
  String get purchaseUnlock => 'Débloquer l\'accès complet';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'Débloquer l\'accès complet · $price';
  }

  @override
  String get purchaseRestore => 'Restaurer l\'achat';

  @override
  String get purchaseOneTime => 'Achat unique. Pas d\'abonnement.';

  @override
  String get purchaseUnavailable =>
      'Les achats sont indisponibles pour le moment. Vérifiez votre connexion et réessayez.';

  @override
  String get purchaseCheckingPrevious => 'Recherche d\'un achat précédent…';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsLegalAbout => 'MENTIONS ET À PROPOS';

  @override
  String get settingsHelp => 'AIDE';

  @override
  String get settingsHowItWorks => 'Fonctionnement';

  @override
  String get settingsReplayTourShake =>
      'Revoir la visite : peindre un planning + secouer pour arrêter';

  @override
  String get settingsReplayTour => 'Revoir la visite : peindre un planning';

  @override
  String get settingsScreenTips => 'Afficher les astuces';

  @override
  String get settingsScreenTipsSub =>
      'Astuces uniques sur chaque écran. Activez pour les revoir.';

  @override
  String get settingsFullAccess => 'ACCÈS COMPLET';

  @override
  String get settingsFullAccessUnlocked => 'Accès complet débloqué';

  @override
  String get settingsThanks => 'Merci de soutenir Rostrik.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Essai gratuit : $days jours restants',
      one: 'Essai gratuit : 1 jour restant',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'Essai gratuit terminé';

  @override
  String get settingsUnlockPitch =>
      'Débloquez une fois pour que vos alarmes de poste continuent après l\'essai : un achat unique, jamais d\'abonnement.';

  @override
  String get settingsRestore => 'Restaurer';

  @override
  String get settingsBrandTagline => 'Des alarmes pensées hors du 9 h – 17 h';

  @override
  String get settingsLeadTime => 'Avance';

  @override
  String get settingsLeadTimeSub =>
      'L\'alarme sonne avec cette avance avant chaque poste.';

  @override
  String get settingsSnoozeDuration => 'Durée de répétition';

  @override
  String get settingsSnoozeDurationSub =>
      'De combien le bouton Répéter repousse une alarme qui sonne.';

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
  String get settingsShiftCycles => 'CYCLES DE POSTES';

  @override
  String get settingsShiftCyclesSub =>
      'Plannings générés à partir d\'un modèle.';

  @override
  String get settingsAddShiftCycle => 'Ajouter un cycle';

  @override
  String get settingsNoRosters => 'Vous n\'avez encore généré aucun planning.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get settingsDeleteRosterTitle => 'Supprimer le planning ?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count postes seront supprimés',
      one: '1 poste sera supprimé',
    );
    return 'Supprimer « $label » ? Les alarmes en attente seront annulées et $_temp0.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return '« $label » supprimé';
  }

  @override
  String get commonActive => 'Actif';

  @override
  String get commonUpcoming => 'À venir';

  @override
  String get commonPast => 'Passé';

  @override
  String get settingsWorkHistory => 'HISTORIQUE DE TRAVAIL';

  @override
  String get settingsWorkHistorySub =>
      'Consultez et exportez vos postes personnalisés terminés pour vérifier vos fiches de paie.';

  @override
  String get settingsViewWorkHistory => 'Voir et exporter l\'historique';

  @override
  String get settingsPreferences => 'PRÉFÉRENCES';

  @override
  String get settingsPreferencesSub =>
      'Comment votre planning s\'affiche dans l\'app.';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeSub =>
      'Le thème sombre est celui par défaut. Le clair utilise une palette crème chaleureuse.';

  @override
  String get settings24h => 'Format 24 heures';

  @override
  String get settings24hOn => 'Heures affichées comme 14:30';

  @override
  String get settings24hOff => 'Heures affichées comme 02:30 PM';

  @override
  String get settingsWeekStartTitle => 'Commencer le calendrier le lundi';

  @override
  String get settingsWeekStartMon => 'Les semaines commencent le lundi';

  @override
  String get settingsWeekStartSun => 'Les semaines commencent le dimanche';

  @override
  String get settingsTimelineOpensOn => 'Le planning s\'ouvre sur';

  @override
  String get commonList => 'Liste';

  @override
  String get commonMonth => 'Mois';

  @override
  String get settingsCalendar => 'CALENDRIER';

  @override
  String get settingsCalendarSync =>
      'Synchroniser avec Google / l\'agenda de l\'appareil';

  @override
  String get settingsCalendarSyncSub =>
      'Copie automatiquement vos postes dans un agenda « Rostrik Roster » dédié sur votre téléphone.';

  @override
  String get settingsCalSyncOff =>
      'Synchronisation désactivée. Les prochains événements « Rostrik Roster » ont été effacés.';

  @override
  String get settingsCalSyncMirroring =>
      'Copie de votre planning dans l\'agenda « Rostrik Roster »…';

  @override
  String get settingsCalPermNeeded =>
      'L\'accès à l\'agenda est nécessaire pour synchroniser votre planning.';

  @override
  String get settingsCalBlocked =>
      'L\'accès à l\'agenda est bloqué. Activez-le dans les réglages du système pour synchroniser.';

  @override
  String get settingsCalOpenSettings => 'Réglages';

  @override
  String get settingsCalUnsupported =>
      'La synchronisation d\'agenda n\'est pas disponible sur cet appareil.';

  @override
  String get settingsDangerZone => 'ZONE DE DANGER';

  @override
  String get settingsDangerZoneSub =>
      'Supprime votre planning, vos alarmes et vos réglages, puis relance la configuration depuis le début.';

  @override
  String get settingsResetAppData => 'Réinitialiser les données';

  @override
  String get settingsResetTitle => 'Réinitialiser l\'app ?';

  @override
  String get settingsResetBody =>
      'Êtes-vous sûr ? Votre planning, vos alarmes et vos réglages seront supprimés.';

  @override
  String get settingsResetConfirm => 'Réinitialiser';

  @override
  String get dashNoUpcomingShifts => 'Aucun poste à venir';

  @override
  String get dashEnjoyTimeOff => 'Profitez de votre repos.';

  @override
  String get dashInProgress => 'EN COURS';

  @override
  String get dashRotation => 'Rotation';

  @override
  String get dashAlarmsCantRing =>
      'Les alarmes ne peuvent pas sonner de façon fiable';

  @override
  String get dashNotifsOffIssue =>
      'Les notifications sont désactivées : une alarme qui sonne ne peut ni afficher son écran ni être arrêtée.';

  @override
  String get dashOpenSettings => 'Ouvrir les réglages';

  @override
  String get dashExactBlockedIssue =>
      'Les alarmes exactes sont bloquées : aucun réveil ne peut être programmé.';

  @override
  String get dashAlarmsWontTakeOverScreen =>
      'Les alarmes ne prendront pas tout l\'écran';

  @override
  String get dashFullScreenBlockedIssue =>
      'Les alarmes en plein écran sont désactivées : téléphone verrouillé, vous verrez une notification au lieu de l\'écran d\'alarme.';

  @override
  String get dashAllow => 'Autoriser';

  @override
  String get dashSlideToSkip => 'Glissez pour ignorer cette alarme';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Glissez pour ignorer les $count alarmes',
      one: 'Glissez pour ignorer l\'alarme',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'Ignorer la prochaine alarme · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ignorer les $count alarmes de ce poste',
      one: 'Ignorer l\'alarme de ce poste',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'Garder l\'alarme';

  @override
  String get dashMyRotation => 'Ma rotation';

  @override
  String get dashCalendarUpcoming => 'Calendrier et postes à venir';

  @override
  String get dashNextShifts => 'Prochains postes';

  @override
  String get dashOpenTimeline => 'Ouvrir le planning';

  @override
  String heroStartsIn(String countdown) {
    return 'Début dans $countdown';
  }

  @override
  String heroEndsIn(String countdown) {
    return 'Fin dans $countdown';
  }

  @override
  String get heroStartsInPrefix => 'Début dans';

  @override
  String get heroEndsInPrefix => 'Fin dans';

  @override
  String heroStartsTodayAt(String time) {
    return 'Commence aujourd\'hui à $time';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'A commencé aujourd\'hui à $time';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'Commence demain à $time';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'A commencé hier à $time';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'Commence hier à $time';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return 'Commence le $date à $time';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return 'A commencé le $date à $time';
  }

  @override
  String get shiftTypeDayShift => 'Poste de jour';

  @override
  String get shiftTypeAfternoonShift => 'Poste d\'après-midi';

  @override
  String get shiftTypeNightShift => 'Poste de nuit';

  @override
  String heroDayXofY(int x, int y, String label) {
    return 'Jour $x sur $y – $label';
  }

  @override
  String get heroOffTomorrow => 'Repos demain';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Repos dans $days jours',
      one: 'Repos dans 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'Reprise demain';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Reprise dans $days jours',
      one: 'Reprise dans 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'Repos';

  @override
  String durationDayShort(int d) {
    return '$d j';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d j $h h';
  }

  @override
  String get alarmsTitle => 'Alarmes';

  @override
  String get alarmsAddTooltip => 'Ajouter une alarme';

  @override
  String get alarmsSortTooltip => 'Trier les alarmes';

  @override
  String get alarmsSortByTime => 'Par heure';

  @override
  String get alarmsSortByShiftType => 'Par type de poste';

  @override
  String get alarmsEmptyTitle => 'Aucune alarme pour l\'instant.';

  @override
  String get alarmsEmptyBody => 'Touchez + pour en ajouter une.';

  @override
  String get alarmsNextAlarm => 'PROCHAINE ALARME';

  @override
  String get alarmsHolidayMode => 'Mode vacances';

  @override
  String get alarmsHolidayModeSub => 'Alarmes en pause : rien ne sonnera.';

  @override
  String get alarmsNoUpcoming => 'Aucune alarme de poste à venir';

  @override
  String get alarmsNoUpcomingSub =>
      'Ajoutez une alarme qui suit la rotation, ou générez un planning.';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'pour votre poste ($type) · $day';
  }

  @override
  String get commonToday => 'Aujourd\'hui';

  @override
  String get commonTomorrow => 'Demain';

  @override
  String get alarmsOffWontRing => 'Désactivée : ne sonnera pas';

  @override
  String get alarmsNoUpcomingRing => 'Aucune sonnerie programmée';

  @override
  String alarmsNextRing(String day, String time) {
    return 'Prochaine sonnerie : $day à $time';
  }

  @override
  String get alarmsSwipeToDelete => 'Glissez pour supprimer';

  @override
  String get alarmsRingsOnceAutoDelete => 'Sonne une fois · se supprime';

  @override
  String get alarmsRingsOnce => 'Sonne une seule fois';

  @override
  String get alarmsYourShift => 'votre poste';

  @override
  String alarmsShiftsOfType(String type) {
    return 'postes ($type)';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'Heure exacte · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$lead avant $shift · par défaut';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$lead avant $shift';
  }

  @override
  String get createEditAlarm => 'Modifier l\'alarme';

  @override
  String get createNewAlarm => 'Nouvelle alarme';

  @override
  String get createDefaultLabel => 'Réveil';

  @override
  String get createFallbackLabel => 'Alarme';

  @override
  String get createPickBecomesDefault =>
      'Votre choix devient le son par défaut des nouvelles alarmes.';

  @override
  String get createSelectFromFiles => 'Choisir dans Fichiers';

  @override
  String get createFilesSub =>
      'Choisissez un fichier audio enregistré sur l\'appareil';

  @override
  String get createSelectSystemTone => 'Choisir une sonnerie système';

  @override
  String get createSystemToneSub =>
      'Choisissez parmi les sons d\'alarme de l\'appareil';

  @override
  String get createAlarmTiming => 'Moment de l\'alarme';

  @override
  String get createLeadTimeMode => 'Avance';

  @override
  String get createExactTimeMode => 'Heure exacte';

  @override
  String createFiresAt(String time) {
    return 'Sonne à $time';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return '$lead avant le début du poste';
  }

  @override
  String get createLinkedShift => 'Poste associé';

  @override
  String get createRepeatOn => 'Répéter le';

  @override
  String get createLabelField => 'Nom';

  @override
  String get createLabelHint => 'ex. Réveil';

  @override
  String get createCriticalShift => 'Poste critique';

  @override
  String get createCriticalShiftSub =>
      'Secouer pour arrêter · appui de 3 s en secours';

  @override
  String get createRingtone => 'Sonnerie';

  @override
  String get commonStop => 'Arrêter';

  @override
  String get commonPlay => 'Écouter';

  @override
  String get createVibrate => 'Vibrer';

  @override
  String get createRepeat => 'Répéter';

  @override
  String get createRepeatRotation => 'Rotation';

  @override
  String get createRepeatWeekly => 'Hebdo';

  @override
  String get createRepeatOneTime => 'Une fois';

  @override
  String get createPickOneDay => 'Choisissez au moins un jour';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonSaveChanges => 'Enregistrer';

  @override
  String get createTimeBeforeShift => 'Temps avant le poste';

  @override
  String get commonOk => 'OK';

  @override
  String get sleepTitle => 'Sommeil';

  @override
  String get sleepTargetHeader => 'OBJECTIF DE SOMMEIL';

  @override
  String get sleepTargetSub =>
      'Combien d\'heures vous voulez dormir. Rostrik compte à rebours depuis votre prochaine alarme pour fixer l\'heure du coucher ce soir.';

  @override
  String get sleepRemindersHeader => 'RAPPELS';

  @override
  String get sleepWindDownHeader => 'AVANCE POUR DÉCOMPRESSER';

  @override
  String get sleepWindDownSub =>
      'Combien de temps avant le coucher arrive le rappel pour décompresser.';

  @override
  String get sleepSoundsHeader => 'SONS POUR DORMIR';

  @override
  String get sleepSoundsSub =>
      'Bruit blanc et bruit brun pour s\'endormir. Choisissez une minuterie puis touchez un son.';

  @override
  String get sleepNothingToPlan => 'Rien à planifier ce soir';

  @override
  String get sleepNothingToPlanSub =>
      'Ajoutez un poste à votre planning et Rostrik fixera une heure de coucher adaptée à votre prochain réveil.';

  @override
  String get sleepTransitionDay => 'JOUR DE TRANSITION';

  @override
  String get sleepTransitionTitle =>
      'Demain, c\'est un poste de nuit. Vous pouvez faire la grasse matinée.';

  @override
  String get sleepTransitionBody =>
      'C\'est un jour de transition : vous avez un repos avant les nuits, donc pas de réveil matinal. Faites le plein de repos et laissez votre corps se coucher plus tard ce soir.';

  @override
  String get sleepRestRecovery => 'REPOS ET RÉCUPÉRATION';

  @override
  String get sleepNoEarlyAlarm => 'Pas de réveil matinal';

  @override
  String get sleepRestBody =>
      'Votre prochain poste est dans plus d\'une journée : pas de réveil à planifier ce soir. Dormez à votre rythme et récupérez ; Rostrik préparera votre plan à l\'approche du poste.';

  @override
  String get sleepTonightsPlan => 'PLAN DE CE SOIR';

  @override
  String get sleepTargetBedtime => 'Heure du coucher';

  @override
  String get sleepWindDownStat => 'Décompresser';

  @override
  String get sleepWakeUpStat => 'Réveil';

  @override
  String get sleepDurationStat => 'Durée';

  @override
  String get sleepBedtimeReminder => 'Rappel du coucher';

  @override
  String sleepNudgeAtBedtime(String time) {
    return 'Me prévenir à $time pour aller me coucher';
  }

  @override
  String get sleepBedtimeSub =>
      'Un rappel quand il est l\'heure d\'aller au lit';

  @override
  String get sleepWindDownReminder => 'Rappel pour décompresser';

  @override
  String sleepNudgeAtWindDown(String time) {
    return 'Me prévenir à $time pour commencer à décompresser';
  }

  @override
  String get sleepWindDownReminderSub =>
      'Un rappel plus tôt pour commencer à décompresser';

  @override
  String get commonOff => 'Non';

  @override
  String get sleepSoundWhiteNoise => 'Bruit blanc';

  @override
  String get sleepSoundPinkNoise => 'Bruit rose';

  @override
  String get sleepSoundBrownNoise => 'Bruit brun';

  @override
  String get sleepSoundFan => 'Ventilateur';

  @override
  String get sleepSoundOcean => 'Océan';

  @override
  String get sleepSoundRain => 'Pluie';

  @override
  String get manageTitle => 'Gérer';

  @override
  String get manageRosterTools => 'OUTILS DE PLANNING';

  @override
  String get manageRosterToolsSub =>
      'Créez et ajustez les postes qui pilotent vos alarmes et votre plan de sommeil.';

  @override
  String get manageGenerateRotation => 'Générer une rotation';

  @override
  String get manageGenerateRotationSub =>
      'Créez un cycle de postes répétitif à partir d\'un modèle.';

  @override
  String get manageAddCustomShift => 'Ajouter un poste ponctuel';

  @override
  String get manageAddCustomShiftSub =>
      'Ajoutez un poste isolé à votre planning.';

  @override
  String get manageMarkLeave => 'Poser des congés / absences';

  @override
  String get manageMarkLeaveSub =>
      'Peignez vos jours d\'absence (congés, maladie) en une fois.';

  @override
  String get managePauseSchedule => 'Mettre le planning en pause';

  @override
  String get managePausedSub =>
      'Mode vacances ACTIVÉ : alarmes coupées, votre planning est en sécurité.';

  @override
  String get manageNotPausedSub =>
      'Mode vacances : coupe les alarmes pendant vos absences.';

  @override
  String get markLeaveTitle => 'Poser des congés';

  @override
  String get markLeaveIntro =>
      'Touchez vos jours d\'absence, choisissez un motif, puis appliquez. Les alarmes de ces jours ne sonneront pas et votre planning reste intact.';

  @override
  String get leaveAnnual => 'Congés payés';

  @override
  String get leaveSick => 'Maladie';

  @override
  String get leavePublicHoliday => 'Jour férié';

  @override
  String get markLeaveReason => 'Motif';

  @override
  String get markLeaveFallbackReason => 'congé';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count postes marqués : $reason.',
      one: '1 poste marqué : $reason.',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => 'Choisissez les jours à marquer';

  @override
  String get markLeaveNoShifts => 'Aucun poste ces jours-là';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Appliquer à $count postes',
      one: 'Appliquer à 1 poste',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => 'Historique de travail';

  @override
  String get workHistoryExportTooltip => 'Exporter l\'historique';

  @override
  String workHistoryExportFailed(String error) {
    return 'Impossible d\'exporter l\'historique : $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count postes travaillés',
      one: '1 poste travaillé',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours h';
  }

  @override
  String get commonPaused => 'En pause';

  @override
  String workHistoryPausedReason(String reason) {
    return 'En pause · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'Rotation';

  @override
  String get workHistoryAdHocBadge => 'Ponctuel';

  @override
  String get workHistoryEmptyTitle => 'Aucun poste terminé';

  @override
  String get workHistoryEmptyBody =>
      'Vos postes travaillés, en rotation comme ponctuels, apparaissent ici une fois terminés, prêts à être exportés pour vérifier vos fiches de paie.';

  @override
  String get workHistoryShareSubject => 'Historique de travail Rostrik';

  @override
  String get workHistoryShareText =>
      'Mon historique de travail exporté depuis Rostrik.';

  @override
  String get shiftEdAddShift => 'Ajouter un poste';

  @override
  String get shiftEdEditShift => 'Modifier le poste';

  @override
  String get shiftEdDate => 'Date';

  @override
  String get shiftEdPickDate => 'Choisir la date';

  @override
  String get shiftEdStarts => 'Début';

  @override
  String get shiftEdEnds => 'Fin';

  @override
  String get shiftEdPickTime => 'Choisir l\'heure';

  @override
  String get shiftEdEndsNextDay => 'Se termine le lendemain';

  @override
  String get shiftEdPauseTitle => 'Mettre en pause / annuler ce poste';

  @override
  String get shiftEdPausedSub =>
      'L\'alarme ne sonnera pas. Le poste reste dans votre calendrier.';

  @override
  String get shiftEdNotPausedSub =>
      'Marquer un jour d\'absence (maladie, congé, férié) sans le supprimer.';

  @override
  String get shiftEdReasonOptional => 'Motif (facultatif)';

  @override
  String get dayShifts => 'Postes';

  @override
  String get dayActivities => 'Activités';

  @override
  String get dayAddAnotherShift => 'Ajouter un autre poste';

  @override
  String get dayAddActivity => 'Ajouter une activité';

  @override
  String get dayAddActivitySub => 'Événement, tâche ou anniversaire';

  @override
  String get dayReminder => 'Rappel';

  @override
  String get actEditActivity => 'Modifier l\'activité';

  @override
  String get actLeadAtTime => 'À l\'heure';

  @override
  String get actLead10Min => '10 min avant';

  @override
  String get actLead30Min => '30 min avant';

  @override
  String get actLead1Hour => '1 heure avant';

  @override
  String get actLead1Day => '1 jour avant';

  @override
  String get actEvent => 'Événement';

  @override
  String get actTask => 'Tâche';

  @override
  String get actBirthday => 'Anniversaire';

  @override
  String get actTitleField => 'Titre';

  @override
  String get actAllDay => 'Toute la journée';

  @override
  String get actTimeField => 'Heure';

  @override
  String get actRemindMe => 'Me le rappeler';

  @override
  String get actRemindMeSub =>
      'Une notification discrète, distincte de vos alarmes de poste.';

  @override
  String get actRemindAt => 'Rappeler à';

  @override
  String get actReminderPassed =>
      'Cette heure est déjà passée : ce rappel ne s\'affichera pas.';

  @override
  String get actNoteOptional => 'Note (facultative)';

  @override
  String get actCompleted => 'Terminée';

  @override
  String get tipDashboardTitle => 'Votre accueil';

  @override
  String get tipDashboardBody =>
      'Votre point de départ. Voyez votre prochain poste avec un compte à rebours en direct et où vous en êtes dans la rotation. Touchez un bloc pour les détails.';

  @override
  String get tipTimelineTitle => 'Tout votre planning';

  @override
  String get tipTimelineBody =>
      'Basculez en haut entre la liste et le calendrier mensuel. Touchez un jour pour modifier un poste, ou ajouter un événement, une tâche ou un anniversaire.';

  @override
  String get tipManageTitle => 'Créer et ajuster';

  @override
  String get tipManageBody =>
      'Créez une rotation, ajoutez un poste ponctuel (heures sup) ou mettez tout le planning en pause pendant vos congés, tout ça ici.';

  @override
  String get tipAlarmsTitle => 'Vos alarmes';

  @override
  String get tipAlarmsBody =>
      'Toutes les alarmes créées par vos postes, plus celles que vous ajoutez. Touchez-en une pour changer l\'heure ou la sonnerie, ou en faire une alarme de poste critique qui s\'arrête en secouant.';

  @override
  String get tipSleepTitle => 'Plan de sommeil';

  @override
  String get tipSleepBody =>
      'Un plan pour décompresser qui suit votre planning : fixez un objectif de sommeil et arrivez reposé à votre prochain poste.';

  @override
  String get tipReplayHint =>
      'À revoir à tout moment dans Réglages › Fonctionnement.';

  @override
  String get tipDontShow => 'Ne plus afficher';

  @override
  String get tipGotIt => 'Compris';

  @override
  String get timelineListView => 'Liste';

  @override
  String get timelineMonthView => 'Mois';

  @override
  String get shiftTypeAftShort => 'Aprem';

  @override
  String get timelineNoShifts =>
      'Aucun poste prévu. Touchez + pour en ajouter un.';

  @override
  String timelineNoMatch(String filter) {
    return 'Aucun poste ne correspond au filtre « $filter ».';
  }

  @override
  String get timelineRestDay => 'Jour de repos';

  @override
  String timelineRestDayReason(String reason) {
    return 'Jour de repos · $reason';
  }

  @override
  String get timelineAllDay => 'Toute la journée';

  @override
  String get calLegendPausedLeave => 'En pause / Congé';

  @override
  String get calLegendActivity => 'Activité';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterWork => 'Travail';

  @override
  String get criticalHoldToDismiss => 'Ou maintenez pour arrêter';

  @override
  String get patternChoosePattern => 'Choisissez un modèle';

  @override
  String get patternRotatingSwings => 'Rotations mixtes';

  @override
  String get patternDaySwings => 'Jours uniquement';

  @override
  String get patternNightSwings => 'Nuits uniquement';

  @override
  String get patternShiftTimes => 'Horaires des postes';

  @override
  String get patternGenerate => 'Fixer le jour 1 et générer';

  @override
  String get patternSelectDay1 => 'Choisissez votre prochain jour 1';

  @override
  String patternDay1Hint(String label) {
    return 'Premier jour de votre bloc ($label)';
  }

  @override
  String get patternNextDay1 => 'Prochain jour 1';

  @override
  String get patternUseThisDate => 'Utiliser cette date';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count postes générés',
      one: '1 poste généré',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'Échec de la génération : $error';
  }

  @override
  String get patternFirstBlockFallback => 'premier';

  @override
  String get patternBuildCustom => 'Créer un planning personnalisé';

  @override
  String get patternBuildCustomSub =>
      'Aucun modèle ne convient ? Composez vos propres blocs.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n après-midi',
      one: '1 après-midi',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nuits',
      one: '1 nuit',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '$n repos';
  }

  @override
  String get builderNewRoster => 'Nouveau planning';

  @override
  String get builderEditRoster => 'Modifier le planning';

  @override
  String get builderNewSub => 'Configurez votre cycle de rotation';

  @override
  String get builderEditSub => 'Modifier et remplacer ce planning enregistré';

  @override
  String get builderNameHint => 'Nom (ex. Ma rotation de 14 jours)';

  @override
  String get builderCycleLength => 'DURÉE DU CYCLE';

  @override
  String get builderStartDate => 'DATE DE DÉBUT';

  @override
  String get builderShiftBlocks => 'BLOCS DE POSTES';

  @override
  String get builderAddShiftBlock => 'Ajouter un bloc';

  @override
  String get builderCreateRoster => 'Créer le planning';

  @override
  String get builderSaveChanges => 'Enregistrer';

  @override
  String get builderReplaceWarning =>
      'L\'enregistrement remplace ce planning. Les congés et absences peints dessus seront réinitialisés.';

  @override
  String get builderBackToOptions => 'Retour aux options';

  @override
  String get builderOrImport => 'OU IMPORTER UN PLANNING EXISTANT';

  @override
  String get builderImportViaAi => 'Importer avec l\'IA';

  @override
  String get builderScanning => 'Numérisation…';

  @override
  String get builderScanInstead => 'Numériser une photo du planning';

  @override
  String get builderCustomChip => 'Autre';

  @override
  String get builderCycleLengthLabel => 'Durée du cycle';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'Choisir une date';

  @override
  String get builderNoBlocksYet => 'Aucun bloc';

  @override
  String get builderNoBlocksSub =>
      'Ajoutez des blocs de postes pour définir votre rotation';

  @override
  String builderDaysLine(String ranges) {
    return 'Jours $ranges';
  }

  @override
  String get builderEditBlock => 'Modifier le bloc';

  @override
  String get builderRemoveBlock => 'Retirer le bloc';

  @override
  String get builderPickRosterStart =>
      'Choisissez la date de début du planning';

  @override
  String get builderPickScanStart =>
      'Choisissez la date de début du planning numérisé';

  @override
  String get builderScanCamera => 'Numériser avec l\'appareil photo';

  @override
  String get builderImportScreenshot => 'Importer une capture d\'écran';

  @override
  String builderScanFailed(String error) {
    return 'Échec de la numérisation : $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'Aucun horaire reconnu. Recadrez plus près du tableau.';

  @override
  String get builderCustomRosterFallback => 'Planning personnalisé';

  @override
  String get builderScannedRosterFallback => 'Planning numérisé';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Planning mis à jour : $count postes programmés',
      one: 'Planning mis à jour : 1 poste programmé',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Créé : $count postes programmés',
      one: 'Créé : 1 poste programmé',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'Impossible de créer le planning : $error';
  }

  @override
  String get builderRosterImported => 'Planning importé dans votre calendrier';

  @override
  String builderCouldNotImport(String error) {
    return 'Impossible d\'importer le planning : $error';
  }

  @override
  String get blockAddTitle => 'Ajouter un bloc';

  @override
  String get blockEditTitle => 'Modifier le bloc';

  @override
  String get blockStart => 'Début';

  @override
  String get blockEnd => 'Fin';

  @override
  String get blockTapDays => 'Touchez les jours couverts par ce poste';

  @override
  String get blockUntappedOff => 'Les jours non touchés sont en repos.';

  @override
  String blockOverlap(String ranges) {
    return 'Cet horaire chevauche un autre poste le jour $ranges : changez l\'heure ou ces jours.';
  }

  @override
  String get blockAdd => 'Ajouter le bloc';

  @override
  String get blockSave => 'Enregistrer le bloc';

  @override
  String get aiPromptCopied =>
      'Consigne copiée ! Collez-la dans votre app d\'IA avec votre planning.';

  @override
  String get aiNothingToPaste => 'Rien à coller dans le presse-papiers.';

  @override
  String get aiNoValidShifts =>
      'Aucun poste valide détecté. Vérifiez que vous avez utilisé la consigne copiée.';

  @override
  String get aiStep1 => 'Copiez la consigne';

  @override
  String get aiCopied => 'Copiée !';

  @override
  String get aiCopyPrompt => 'Copier la consigne IA';

  @override
  String get aiStep1Sub =>
      'Collez-la dans ChatGPT, Gemini ou une autre app d\'IA, ajoutez le texte de votre planning ou une photo / capture, puis envoyez.';

  @override
  String get aiStep2 => 'Collez la réponse de l\'IA';

  @override
  String get aiPaste => 'Coller';

  @override
  String get aiParsePreview => 'Analyser et prévisualiser';

  @override
  String get aiStep3 => 'Vérifiez les postes détectés';

  @override
  String get aiStep3Sub =>
      'Touchez une étiquette pour basculer entre Jour, Après-midi et Nuit si l\'IA s\'est trompée.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importer $count jours',
      one: 'Importer 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'Transformez n\'importe quel texte de planning en postes grâce à une app d\'IA.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0 · $working travaillés · $off repos';
  }

  @override
  String get draftReviewTitle => 'Vérifier le planning numérisé';

  @override
  String draftRemovedDay(String date) {
    return '$date retiré';
  }

  @override
  String get draftUndo => 'Annuler';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours ajoutés à votre planning',
      one: '1 jour ajouté à votre planning',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'Nom du planning';

  @override
  String get draftScannedImage => 'Image numérisée';

  @override
  String get draftScannedImageSub =>
      'Touchez l\'image pour l\'agrandir et comparer';

  @override
  String get draftImageError => 'Impossible d\'afficher l\'image numérisée.';

  @override
  String get draftRemove => 'Retirer';

  @override
  String get draftNoEndTime =>
      'Numérisé sans heure de fin : ajoutez-la pour pouvoir enregistrer.';

  @override
  String get draftTime => 'Heure';

  @override
  String get draftSetEnd => 'Définir la fin';

  @override
  String get draftConfirmSave => 'Confirmer et enregistrer';

  @override
  String notifBeforeYourShift(String type) {
    return 'Avant votre poste ($type)';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind à $time';
  }

  @override
  String get notifWindDownTitle => 'L\'heure de décompresser 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'Lâchez les écrans : coucher prévu à $time.';
  }

  @override
  String get notifWindDownBody =>
      'Lâchez les écrans et commencez à décompresser pour la nuit.';

  @override
  String get notifBedtimeTitle => 'Au lit 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return 'Couchez-vous pour dormir ~$hours h avant votre $shift : réveil à $time.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return 'Couchez-vous pour atteindre votre objectif de $hours h de sommeil.';
  }

  @override
  String get notifShiftDay => 'poste de jour';

  @override
  String get notifShiftAfternoon => 'poste d\'après-midi';

  @override
  String get notifShiftNight => 'poste de nuit';

  @override
  String get notifShiftGeneric => 'poste';

  @override
  String get notifTrialEndsTitle => 'Votre essai Rostrik se termine demain';

  @override
  String get notifTrialEndsBody =>
      'Débloquez l\'accès complet pour que vos alarmes de poste continuent de sonner.';

  @override
  String seedWakeUpLabel(String type) {
    return 'Réveil ($type)';
  }

  @override
  String get seedShiftGeneric => 'Poste';

  @override
  String commonListAnd(String items, String last) {
    return '$items et $last';
  }

  @override
  String get soundClassic => 'Classique';

  @override
  String get soundSiren => 'Sirène';

  @override
  String get soundDigital => 'Numérique';

  @override
  String get soundChime => 'Carillon';

  @override
  String get patternFirstResponder => 'Standard secours';

  @override
  String get ocrCropTitle =>
      'Recadrez UNIQUEMENT votre ligne, pas toute l\'équipe';

  @override
  String get draftNameHint => 'ex. Planning de mai';
}
