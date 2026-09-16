// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'Bevor du loslegst';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik weckt dich zuverlässig für jede Schicht. Ein ehrlicher Hinweis: Auf jedem Handy hat das Betriebssystem – nicht die App – das letzte Wort. In seltenen Fällen kann es jede Wecker-App verzögern oder stummschalten (aggressive Energiesparmodi, erzwungenes Beenden oder direkt nach Systemupdates).';

  @override
  String get legalBodyBackupAdvice =>
      'Für Schichten, die du auf keinen Fall verpassen darfst, stell dir einen zweiten Wecker als Backup. Das ist bei jedem Wecker sinnvoll, auch beim eingebauten.';

  @override
  String get legalReviewAndAccept => 'Bitte lesen und akzeptieren:';

  @override
  String get legalPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get legalTermsOfUse => 'Nutzungsbedingungen';

  @override
  String get legalConsentCheckbox =>
      'Ich verstehe, dass das Betriebssystem jede Wecker-App beeinflussen kann, und akzeptiere die Datenschutzerklärung und die Nutzungsbedingungen.';

  @override
  String get legalAgreeContinue => 'Zustimmen und weiter';

  @override
  String get commonSaving => 'Wird gespeichert…';

  @override
  String get commonCouldNotOpenLink => 'Der Link konnte nicht geöffnet werden.';

  @override
  String get welcomeTagline => 'Der smarte Wecker für Schichtarbeitende.';

  @override
  String get welcomeSubTagline =>
      'Wecker, die deinem Schichtplan folgen – nicht nur den Wochentagen.';

  @override
  String welcomeTrialTitle(int days) {
    return '$days Tage kostenlos testen';
  }

  @override
  String get welcomeTrialBody =>
      'Voller Zugriff auf alle Funktionen, ohne Karte. Danach ein einmaliger Kauf, niemals ein Abo.';

  @override
  String get welcomeGetStarted => 'Los geht\'s';

  @override
  String get welcomeSkip => 'Überspringen / Später einrichten';

  @override
  String get welcomeTimeFormat => 'Zeitformat';

  @override
  String get welcomeWeekStarts => 'Wochenbeginn';

  @override
  String get common12h => '12 Std.';

  @override
  String get common24h => '24 Std.';

  @override
  String get commonSundayShort => 'So';

  @override
  String get commonMondayShort => 'Mo';

  @override
  String get rosterTypeTitle => 'Dienstplan-Art wählen';

  @override
  String get rosterTypeQuestion => 'Wie sieht dein Dienstplan aus?';

  @override
  String get rosterTypeDay => 'Tagschichten';

  @override
  String get rosterTypeNight => 'Nachtschichten';

  @override
  String get rosterTypeRotating => 'Wechselschicht';

  @override
  String get rosterTypeCustom => 'Eigener';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonComingSoon => 'Demnächst';

  @override
  String get permsTitle => 'Berechtigungen';

  @override
  String get permsIntro =>
      'Rostrik braucht ein paar Berechtigungen, damit Wecker zuverlässig klingeln. Du kannst sie später in den Systemeinstellungen ändern.';

  @override
  String get permsNotifications => 'Benachrichtigungen';

  @override
  String get permsNotificationsSub =>
      'Nötig, um den Weckbildschirm anzuzeigen.';

  @override
  String get permsExactAlarms => 'Exakte Wecker';

  @override
  String get permsExactAlarmsSub =>
      'Lässt Wecker genau zur geplanten Zeit klingeln.';

  @override
  String get permsBatteryUnrestricted => 'Akku: Uneingeschränkt';

  @override
  String get permsBatteryGrantedSub =>
      'Wecker sind vor der Akkuoptimierung geschützt.';

  @override
  String get permsBatteryDeniedSub =>
      'Manche Handys beenden Apps im Hintergrund. Tippe zum Beheben.';

  @override
  String get permsUnrestrictedBadge => 'Uneingeschränkt';

  @override
  String get batteryDialogTitle => 'Wecker am Leben halten';

  @override
  String get batteryDialogIntro =>
      'Manche Handys (Samsung, Xiaomi, Oppo, Huawei) beenden Hintergrund-Apps aggressiv, um Akku zu sparen. Passiert das mit Rostrik, kann ein Wecker stumm bleiben.';

  @override
  String get batteryDialogMarkUnrestricted =>
      'Stell Rostrik auf „Uneingeschränkt“, um das zu verhindern:';

  @override
  String get batteryStep1 =>
      'Öffne die Einstellungen dieser App (Button unten).';

  @override
  String get batteryStep2 => 'Tippe auf Akku (oder „Akkunutzung der App“).';

  @override
  String get batteryStep3 =>
      'Wähle „Uneingeschränkt“ (nicht „Optimiert“ oder „Eingeschränkt“).';

  @override
  String get batteryStep4 =>
      'Falls „Hintergrundaktivität zulassen“ angezeigt wird, schalte das auch ein.';

  @override
  String get batteryStep5 =>
      'Schalte „App-Aktivität pausieren, wenn nicht verwendet“ (oder „Berechtigungen entfernen, wenn App nicht verwendet wird“) AUS, damit Android dir die Wecker-Berechtigungen nicht entzieht, während du weg bist.';

  @override
  String get commonNotNow => 'Nicht jetzt';

  @override
  String get batteryGoToSettings => 'Zu den Einstellungen';

  @override
  String get armEngineTitle => 'Wecker aktivieren';

  @override
  String get armEngineRosterReady => 'Dein Dienstplan ist fertig';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · ab $date';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'Wir aktivieren Weckrufe ($summary) vor jeder passenden Schicht.';
  }

  @override
  String get armEngineArming => 'Wird aktiviert…';

  @override
  String get armEngineCta => 'Meine Wecker automatisieren';

  @override
  String get armEngineLeadTimeLabel => 'Weckvorlauf';

  @override
  String get armEngineLeadTimeHelper =>
      'Wie lange vor Schichtbeginn der Wecker klingelt.';

  @override
  String get shiftTypeDay => 'Tag';

  @override
  String get shiftTypeAfternoon => 'Spät';

  @override
  String get shiftTypeNight => 'Nacht';

  @override
  String get shiftTypeOff => 'Frei';

  @override
  String get weekdaysNone => 'Keine Tage';

  @override
  String get weekdaysEveryDay => 'Jeden Tag';

  @override
  String get weekdaysWeekdays => 'Werktags';

  @override
  String get weekdaysWeekends => 'Am Wochenende';

  @override
  String durationMin(int m) {
    return '$m Min.';
  }

  @override
  String durationH(int h) {
    return '$h Std.';
  }

  @override
  String durationHMin(int h, int m) {
    return '$h Std. $m Min.';
  }

  @override
  String durationMinShort(int m) {
    return '$m Min.';
  }

  @override
  String durationHShort(int h) {
    return '$h Std.';
  }

  @override
  String durationHMinShort(int h, int m) {
    return '$h Std. $m Min.';
  }

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonSkip => 'Überspringen';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonNext => 'Weiter';

  @override
  String get walkthroughIntroTitle => 'Eine 60-Sekunden-Tour';

  @override
  String get walkthroughIntroBodyTwo =>
      'Zwei Dinge, die Rostrik ausmachen. Du kannst jederzeit überspringen.';

  @override
  String get walkthroughIntroBodyOne =>
      'Das, was Rostrik ausmacht. Du kannst jederzeit überspringen.';

  @override
  String get walkthroughPaintLabel => 'Dienstplan malen';

  @override
  String get walkthroughPaintDetail =>
      'Tippe auf deine Arbeitstage – so schnell geht\'s.';

  @override
  String get walkthroughShakeLabel => 'Schütteln zum Beenden';

  @override
  String get walkthroughShakeDetail =>
      'Kräftiges Schütteln beendet einen kritischen Wecker.';

  @override
  String get walkthroughTryEach =>
      'Tippe auf Weiter, um beides auszuprobieren.';

  @override
  String get walkthroughTryIt => 'Tippe auf Weiter, um es auszuprobieren.';

  @override
  String get walkthroughPaintBody =>
      'Tippe auf deine Arbeitstage. Im echten Editor fügst du weitere Blöcke (Spät, Nacht) genauso hinzu.';

  @override
  String get walkthroughPaintPrompt =>
      'Tippe auf einen Tag, um eine Tagschicht einzutragen.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Super! Diese $count Tage sind jetzt ein Tagschicht-Block. Nicht angetippte Tage bleiben frei – ganz einfach.',
      one:
          'Super! Dieser Tag ist jetzt ein Tagschicht-Block. Nicht angetippte Tage bleiben frei – ganz einfach.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'Wecker für kritische Schichten brauchen kräftiges, anhaltendes Schütteln – ein verschlafenes Tippen reicht nicht. Probier\'s aus: Schüttel dein Handy.';

  @override
  String get walkthroughShakeSuccess => 'Geschafft!';

  @override
  String get walkthroughShakeSuccessDetail =>
      'Genau so beendest du einen kritischen Wecker.';

  @override
  String get walkthroughDoneTitle => 'Alles startklar';

  @override
  String get walkthroughDoneBody =>
      'Erstelle jederzeit einen Dienstplan unter „Verwalten“ und sieh dir diese Tour unter Einstellungen → Hilfe erneut an.';

  @override
  String get navDashboard => 'Übersicht';

  @override
  String get navTimeline => 'Zeitplan';

  @override
  String get navManage => 'Verwalten';

  @override
  String get navAlarms => 'Wecker';

  @override
  String get navSleep => 'Schlaf';

  @override
  String get onbPatternTitle => 'Schichtrhythmus wählen';

  @override
  String get purchaseTrialEnded => 'Dein Testzeitraum ist abgelaufen';

  @override
  String get purchaseBody =>
      'Schalte Rostrik einmalig frei, damit deine Schichtwecker weiter klingeln. Dienstplan, Wecker und Einstellungen bleiben erhalten und laufen sofort nach dem Freischalten weiter.';

  @override
  String get purchaseAlarmsWontRing => 'Bis dahin klingeln keine Wecker.';

  @override
  String get purchaseUnlock => 'Vollzugriff freischalten';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'Vollzugriff freischalten · $price';
  }

  @override
  String get purchaseRestore => 'Kauf wiederherstellen';

  @override
  String get purchaseOneTime => 'Einmaliger Kauf. Kein Abo.';

  @override
  String get purchaseUnavailable =>
      'Käufe sind gerade nicht verfügbar. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get purchaseCheckingPrevious => 'Suche nach früherem Kauf…';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLegalAbout => 'RECHTLICHES & INFO';

  @override
  String get settingsHelp => 'HILFE';

  @override
  String get settingsHowItWorks => 'So funktioniert\'s';

  @override
  String get settingsReplayTourShake =>
      'Tour erneut ansehen – Dienstplan malen + Schütteln zum Beenden';

  @override
  String get settingsReplayTour => 'Tour erneut ansehen – Dienstplan malen';

  @override
  String get settingsScreenTips => 'Bildschirmtipps anzeigen';

  @override
  String get settingsScreenTipsSub =>
      'Einmalige Hinweise auf jedem Bildschirm. Einschalten, um sie erneut zu sehen.';

  @override
  String get settingsFullAccess => 'VOLLZUGRIFF';

  @override
  String get settingsFullAccessUnlocked => 'Vollzugriff freigeschaltet';

  @override
  String get settingsThanks => 'Danke, dass du Rostrik unterstützt.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Testzeitraum – noch $days Tage',
      one: 'Testzeitraum – noch 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'Testzeitraum abgelaufen';

  @override
  String get settingsUnlockPitch =>
      'Schalte einmalig frei, damit deine Schichtwecker nach dem Test weiter klingeln – ein einmaliger Kauf, niemals ein Abo.';

  @override
  String get settingsRestore => 'Wiederherstellen';

  @override
  String get settingsBrandTagline => 'Wecker jenseits von 9 bis 5';

  @override
  String get settingsLeadTime => 'Weckvorlauf';

  @override
  String get settingsLeadTimeSub =>
      'So lange vor jedem Schichtbeginn klingelt der Wecker.';

  @override
  String get settingsSnoozeDuration => 'Schlummerdauer';

  @override
  String get settingsSnoozeDurationSub =>
      'Wie weit „Schlummern“ einen klingelnden Wecker verschiebt.';

  @override
  String get settingsMinutesLabel => 'Minuten';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => 'SCHICHTZYKLEN';

  @override
  String get settingsShiftCyclesSub =>
      'Dienstpläne, die du aus einem Muster oder einer Vorlage erstellt hast.';

  @override
  String get settingsAddShiftCycle => 'Schichtzyklus hinzufügen';

  @override
  String get settingsNoRosters => 'Du hast noch keine Dienstpläne erstellt.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get settingsDeleteRosterTitle => 'Dienstplan löschen?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten werden',
      one: '1 Schicht wird',
    );
    return '„$label“ löschen? Ausstehende Wecker werden abgebrochen und $_temp0 entfernt.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return '„$label“ gelöscht';
  }

  @override
  String get commonActive => 'Aktiv';

  @override
  String get commonUpcoming => 'Anstehend';

  @override
  String get commonPast => 'Vergangen';

  @override
  String get settingsWorkHistory => 'ARBEITSVERLAUF';

  @override
  String get settingsWorkHistorySub =>
      'Sieh dir deine abgeschlossenen Zusatzschichten an und exportiere sie, um die Gehaltsabrechnung zu prüfen.';

  @override
  String get settingsViewWorkHistory => 'Verlauf ansehen & exportieren';

  @override
  String get settingsPreferences => 'EINSTELLUNGEN';

  @override
  String get settingsPreferencesSub =>
      'Wie dein Plan in der App angezeigt wird.';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsThemeSub =>
      'Dunkel ist Rostriks Standard. Hell nutzt eine warme Cremepalette.';

  @override
  String get settings24h => '24-Stunden-Format';

  @override
  String get settings24hOn => 'Zeiten erscheinen als 14:30';

  @override
  String get settings24hOff => 'Zeiten erscheinen als 02:30 PM';

  @override
  String get settingsWeekStartTitle => 'Kalender am Montag beginnen';

  @override
  String get settingsWeekStartMon => 'Wochen beginnen am Montag';

  @override
  String get settingsWeekStartSun => 'Wochen beginnen am Sonntag';

  @override
  String get settingsTimelineOpensOn => 'Zeitplan öffnet in';

  @override
  String get commonList => 'Liste';

  @override
  String get commonMonth => 'Monat';

  @override
  String get settingsCalendar => 'KALENDER';

  @override
  String get settingsCalendarSync =>
      'Mit Google-/Gerätekalender synchronisieren';

  @override
  String get settingsCalendarSyncSub =>
      'Überträgt deine Schichten automatisch in einen eigenen Kalender „Rostrik Roster“ auf deinem Handy.';

  @override
  String get settingsCalSyncOff =>
      'Kalendersync aus. Anstehende „Rostrik Roster“-Termine wurden entfernt.';

  @override
  String get settingsCalSyncMirroring =>
      'Dienstplan wird in den Kalender „Rostrik Roster“ übertragen…';

  @override
  String get settingsCalPermNeeded =>
      'Zum Synchronisieren wird Kalenderzugriff benötigt.';

  @override
  String get settingsCalBlocked =>
      'Kalenderzugriff ist blockiert. Aktiviere ihn in den Systemeinstellungen.';

  @override
  String get settingsCalOpenSettings => 'Einstellungen';

  @override
  String get settingsCalUnsupported =>
      'Kalendersync ist auf diesem Gerät nicht verfügbar.';

  @override
  String get settingsDangerZone => 'GEFAHRENBEREICH';

  @override
  String get settingsDangerZoneSub =>
      'Löscht Dienstplan, Wecker und Einstellungen und startet die Einrichtung von vorn.';

  @override
  String get settingsResetAppData => 'App-Daten zurücksetzen';

  @override
  String get settingsResetTitle => 'App zurücksetzen?';

  @override
  String get settingsResetBody =>
      'Bist du sicher? Dienstplan, Wecker und Einstellungen werden gelöscht.';

  @override
  String get settingsResetConfirm => 'Zurücksetzen';

  @override
  String get dashNoUpcomingShifts => 'Keine anstehenden Schichten';

  @override
  String get dashEnjoyTimeOff => 'Genieß deine freie Zeit.';

  @override
  String get dashInProgress => 'LÄUFT';

  @override
  String get dashRotation => 'Schichtrhythmus';

  @override
  String get dashAlarmsCantRing => 'Wecker können nicht zuverlässig klingeln';

  @override
  String get dashNotifsOffIssue =>
      'Benachrichtigungen sind aus – ein klingelnder Wecker kann keinen Weckbildschirm zeigen und nicht beendet werden.';

  @override
  String get dashOpenSettings => 'Einstellungen öffnen';

  @override
  String get dashExactBlockedIssue =>
      'Exakte Wecker sind blockiert – es können keine Weckrufe geplant werden.';

  @override
  String get dashAlarmsWontTakeOverScreen =>
      'Wecker übernehmen den Bildschirm nicht';

  @override
  String get dashFullScreenBlockedIssue =>
      'Vollbild-Wecker sind deaktiviert – bei gesperrtem Handy erscheint eine Benachrichtigung statt des Weckbildschirms.';

  @override
  String get dashAllow => 'Erlauben';

  @override
  String get dashSlideToSkip => 'Zum Überspringen dieses Weckers wischen';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zum Überspringen aller $count Wecker wischen',
      one: 'Zum Überspringen des Weckers wischen',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'Nächsten Wecker beenden · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Wecker für diese Schicht überspringen',
      one: 'Wecker für diese Schicht überspringen',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'Wecker behalten';

  @override
  String get dashMyRotation => 'Mein Schichtrhythmus';

  @override
  String get dashCalendarUpcoming => 'Kalender & anstehende Schichten';

  @override
  String get dashNextShifts => 'Nächste Schichten';

  @override
  String get dashOpenTimeline => 'Zeitplan öffnen';

  @override
  String heroStartsIn(String countdown) {
    return 'Beginnt in $countdown';
  }

  @override
  String heroEndsIn(String countdown) {
    return 'Endet in $countdown';
  }

  @override
  String get heroStartsInPrefix => 'Beginnt in';

  @override
  String get heroEndsInPrefix => 'Endet in';

  @override
  String heroStartsTodayAt(String time) {
    return 'Beginnt heute um $time';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'Hat heute um $time begonnen';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'Beginnt morgen um $time';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'Hat gestern um $time begonnen';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'Beginnt gestern um $time';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return 'Beginnt $date um $time';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return 'Hat $date um $time begonnen';
  }

  @override
  String get shiftTypeDayShift => 'Tagschicht';

  @override
  String get shiftTypeAfternoonShift => 'Spätschicht';

  @override
  String get shiftTypeNightShift => 'Nachtschicht';

  @override
  String heroDayXofY(int x, int y, String label) {
    return 'Tag $x von $y – $label';
  }

  @override
  String get heroOffTomorrow => 'Morgen frei';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days Tagen frei',
      one: 'In 1 Tag frei',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'Morgen wieder im Dienst';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days Tagen wieder im Dienst',
      one: 'In 1 Tag wieder im Dienst',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'Frei';

  @override
  String durationDayShort(int d) {
    return '$d T.';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d T. $h Std.';
  }

  @override
  String get alarmsTitle => 'Wecker';

  @override
  String get alarmsAddTooltip => 'Wecker hinzufügen';

  @override
  String get alarmsSortTooltip => 'Wecker sortieren';

  @override
  String get alarmsSortByTime => 'Nach Uhrzeit';

  @override
  String get alarmsSortByShiftType => 'Nach Schichtart';

  @override
  String get alarmsEmptyTitle => 'Noch keine Wecker.';

  @override
  String get alarmsEmptyBody => 'Tippe auf +, um einen hinzuzufügen.';

  @override
  String get alarmsNextAlarm => 'NÄCHSTER WECKER';

  @override
  String get alarmsHolidayMode => 'Urlaubsmodus';

  @override
  String get alarmsHolidayModeSub => 'Wecker sind pausiert – nichts klingelt.';

  @override
  String get alarmsNoUpcoming => 'Kein anstehender Schichtwecker';

  @override
  String get alarmsNoUpcomingSub =>
      'Füge einen Schichtrhythmus-Wecker hinzu oder erstelle einen Dienstplan.';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'für deine Schicht ($type) · $day';
  }

  @override
  String get commonToday => 'Heute';

  @override
  String get commonTomorrow => 'Morgen';

  @override
  String get alarmsOffWontRing => 'Aus – klingelt nicht';

  @override
  String get alarmsNoUpcomingRing => 'Kein Klingeln geplant';

  @override
  String alarmsNextRing(String day, String time) {
    return 'Nächstes Klingeln: $day um $time';
  }

  @override
  String get alarmsSwipeToDelete => 'Wischen zum Löschen';

  @override
  String get alarmsRingsOnceAutoDelete =>
      'Klingelt einmal · löscht sich selbst';

  @override
  String get alarmsRingsOnce => 'Klingelt nur einmal';

  @override
  String get alarmsYourShift => 'deiner Schicht';

  @override
  String alarmsShiftsOfType(String type) {
    return 'Schichten ($type)';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'Exakte Zeit · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$lead vor $shift · Standard';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$lead vor $shift';
  }

  @override
  String get createEditAlarm => 'Wecker bearbeiten';

  @override
  String get createNewAlarm => 'Neuer Wecker';

  @override
  String get createDefaultLabel => 'Aufwachen';

  @override
  String get createFallbackLabel => 'Wecker';

  @override
  String get createPickBecomesDefault =>
      'Deine Auswahl wird zum Standard für neue Wecker.';

  @override
  String get createSelectFromFiles => 'Aus Dateien wählen';

  @override
  String get createFilesSub =>
      'Eine auf dem Gerät gespeicherte Audiodatei wählen';

  @override
  String get createSelectSystemTone => 'Systemton wählen';

  @override
  String get createSystemToneSub => 'Aus den Weckertönen deines Geräts wählen';

  @override
  String get createAlarmTiming => 'Weckzeitpunkt';

  @override
  String get createLeadTimeMode => 'Vorlauf';

  @override
  String get createExactTimeMode => 'Exakte Zeit';

  @override
  String createFiresAt(String time) {
    return 'Klingelt um $time';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return '$lead vor Schichtbeginn';
  }

  @override
  String get createLinkedShift => 'Verknüpfte Schicht';

  @override
  String get createRepeatOn => 'Wiederholen am';

  @override
  String get createLabelField => 'Name';

  @override
  String get createLabelHint => 'z. B. Aufwachen';

  @override
  String get createCriticalShift => 'Kritische Schicht';

  @override
  String get createCriticalShiftSub =>
      'Schütteln zum Beenden · 3 Sek. halten als Notlösung';

  @override
  String get createRingtone => 'Klingelton';

  @override
  String get commonStop => 'Stopp';

  @override
  String get commonPlay => 'Abspielen';

  @override
  String get createVibrate => 'Vibrieren';

  @override
  String get createRepeat => 'Wiederholen';

  @override
  String get createRepeatRotation => 'Rhythmus';

  @override
  String get createRepeatWeekly => 'Wöchentlich';

  @override
  String get createRepeatOneTime => 'Einmalig';

  @override
  String get createPickOneDay => 'Wähle mindestens einen Tag';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonSaveChanges => 'Änderungen speichern';

  @override
  String get createTimeBeforeShift => 'Zeit vor der Schicht';

  @override
  String get commonOk => 'OK';

  @override
  String get sleepTitle => 'Schlaf';

  @override
  String get sleepTargetHeader => 'SCHLAFZIEL';

  @override
  String get sleepTargetSub =>
      'Wie viele Stunden du schlafen möchtest. Rostrik rechnet von deinem nächsten Wecker zurück und legt deine Schlafenszeit für heute fest.';

  @override
  String get sleepRemindersHeader => 'ERINNERUNGEN';

  @override
  String get sleepWindDownHeader => 'VORLAUF ZUM RUNTERKOMMEN';

  @override
  String get sleepWindDownSub =>
      'Wie lange vor der Schlafenszeit der Hinweis zum Runterkommen kommt.';

  @override
  String get sleepSoundsHeader => 'SCHLAFGERÄUSCHE';

  @override
  String get sleepSoundsSub =>
      'Weißes und braunes Rauschen zum Einschlafen. Wähle einen Timer und tippe auf ein Geräusch.';

  @override
  String get sleepNothingToPlan => 'Heute nichts zu planen';

  @override
  String get sleepNothingToPlanSub =>
      'Füge deinem Dienstplan eine Schicht hinzu und Rostrik plant eine persönliche Schlafenszeit passend zu deinem nächsten Wecker.';

  @override
  String get sleepTransitionDay => 'ÜBERGANGSTAG';

  @override
  String get sleepTransitionTitle =>
      'Morgen ist Nachtschicht. Schlaf dich ruhig aus.';

  @override
  String get sleepTransitionBody =>
      'Heute ist ein Übergangstag – vor den Nächten hast du frei, also kein früher Wecker. Tank jetzt Ruhe und lass deinen Körper heute Abend später schlafen gehen.';

  @override
  String get sleepRestRecovery => 'RUHE & ERHOLUNG';

  @override
  String get sleepNoEarlyAlarm => 'Kein früher Wecker';

  @override
  String get sleepRestBody =>
      'Deine nächste Schicht ist mehr als einen Tag entfernt, heute gibt es also keinen Weckruf zu planen. Schlaf nach deinem eigenen Rhythmus und erhol dich – Rostrik plant deine Schlafenszeit, wenn es näher rückt.';

  @override
  String get sleepTonightsPlan => 'PLAN FÜR HEUTE NACHT';

  @override
  String get sleepTargetBedtime => 'Schlafenszeit';

  @override
  String get sleepWindDownStat => 'Runterkommen';

  @override
  String get sleepWakeUpStat => 'Aufwachen';

  @override
  String get sleepDurationStat => 'Dauer';

  @override
  String get sleepBedtimeReminder => 'Schlafenszeit-Erinnerung';

  @override
  String sleepNudgeAtBedtime(String time) {
    return 'Erinnere mich um $time ans Schlafengehen';
  }

  @override
  String get sleepBedtimeSub => 'Ein Hinweis, wenn es Zeit fürs Bett ist';

  @override
  String get sleepWindDownReminder => 'Runterkommen-Erinnerung';

  @override
  String sleepNudgeAtWindDown(String time) {
    return 'Erinnere mich um $time ans Runterkommen';
  }

  @override
  String get sleepWindDownReminderSub =>
      'Ein früherer Hinweis zum Runterkommen';

  @override
  String get commonOff => 'Aus';

  @override
  String get sleepSoundWhiteNoise => 'Weißes Rauschen';

  @override
  String get sleepSoundPinkNoise => 'Rosa Rauschen';

  @override
  String get sleepSoundBrownNoise => 'Braunes Rauschen';

  @override
  String get sleepSoundFan => 'Ventilator';

  @override
  String get sleepSoundOcean => 'Meer';

  @override
  String get sleepSoundRain => 'Regen';

  @override
  String get manageTitle => 'Verwalten';

  @override
  String get manageRosterTools => 'DIENSTPLAN-TOOLS';

  @override
  String get manageRosterToolsSub =>
      'Erstelle und passe die Schichten an, die deine Wecker und deinen Schlafplan steuern.';

  @override
  String get manageGenerateRotation => 'Schichtrhythmus erstellen';

  @override
  String get manageGenerateRotationSub =>
      'Erstelle aus einer Vorlage ein wiederkehrendes Schichtmuster.';

  @override
  String get manageAddCustomShift => 'Einzelschicht hinzufügen';

  @override
  String get manageAddCustomShiftSub =>
      'Trag eine einzelne Zusatzschicht in deinen Plan ein.';

  @override
  String get manageMarkLeave => 'Urlaub / freie Tage eintragen';

  @override
  String get manageMarkLeaveSub =>
      'Markiere deine freien Tage (Urlaub, krank) in einem Rutsch.';

  @override
  String get managePauseSchedule => 'Plan pausieren';

  @override
  String get managePausedSub =>
      'Urlaubsmodus AN – Wecker sind stumm, dein Dienstplan bleibt erhalten.';

  @override
  String get manageNotPausedSub =>
      'Urlaubsmodus – Wecker stummschalten, solange du nicht im Dienst bist.';

  @override
  String get markLeaveTitle => 'Urlaub eintragen';

  @override
  String get markLeaveIntro =>
      'Tippe auf deine freien Tage, wähle einen Grund und übernimm. An diesen Tagen klingeln keine Wecker – dein Dienstplan bleibt unverändert.';

  @override
  String get leaveAnnual => 'Urlaub';

  @override
  String get leaveSick => 'Krank';

  @override
  String get leavePublicHoliday => 'Feiertag';

  @override
  String get markLeaveReason => 'Grund';

  @override
  String get markLeaveFallbackReason => 'Urlaub';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten als $reason markiert.',
      one: '1 Schicht als $reason markiert.',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => 'Tage zum Markieren wählen';

  @override
  String get markLeaveNoShifts => 'An diesen Tagen keine Schichten';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Auf $count Schichten anwenden',
      one: 'Auf 1 Schicht anwenden',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => 'Arbeitsverlauf';

  @override
  String get workHistoryExportTooltip => 'Verlauf exportieren';

  @override
  String workHistoryExportFailed(String error) {
    return 'Verlauf konnte nicht exportiert werden: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten gearbeitet',
      one: '1 Schicht gearbeitet',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours Std.';
  }

  @override
  String get commonPaused => 'Pausiert';

  @override
  String workHistoryPausedReason(String reason) {
    return 'Pausiert · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'Rhythmus';

  @override
  String get workHistoryAdHocBadge => 'Zusatz';

  @override
  String get workHistoryEmptyTitle => 'Noch keine abgeschlossenen Schichten';

  @override
  String get workHistoryEmptyBody =>
      'Deine gearbeiteten Schichten – aus dem Rhythmus wie auch eigene – erscheinen hier nach Ende, bereit zum Export für die Gehaltsprüfung.';

  @override
  String get workHistoryShareSubject => 'Rostrik Arbeitsverlauf';

  @override
  String get workHistoryShareText => 'Mein Rostrik-Arbeitsverlauf als Export.';

  @override
  String get shiftEdAddShift => 'Schicht hinzufügen';

  @override
  String get shiftEdEditShift => 'Schicht bearbeiten';

  @override
  String get shiftEdDate => 'Datum';

  @override
  String get shiftEdPickDate => 'Datum wählen';

  @override
  String get shiftEdStarts => 'Beginn';

  @override
  String get shiftEdEnds => 'Ende';

  @override
  String get shiftEdPickTime => 'Uhrzeit wählen';

  @override
  String get shiftEdEndsNextDay => 'Endet am nächsten Tag';

  @override
  String get shiftEdPauseTitle => 'Schicht pausieren / absagen';

  @override
  String get shiftEdPausedSub =>
      'Der Wecker klingelt nicht. Die Schicht bleibt als Eintrag im Kalender.';

  @override
  String get shiftEdNotPausedSub =>
      'Einen freien Tag (krank, Urlaub, Feiertag) markieren, ohne ihn zu löschen.';

  @override
  String get shiftEdReasonOptional => 'Grund (optional)';

  @override
  String get dayShifts => 'Schichten';

  @override
  String get dayActivities => 'Termine';

  @override
  String get dayAddAnotherShift => 'Weitere Schicht hinzufügen';

  @override
  String get dayAddActivity => 'Termin hinzufügen';

  @override
  String get dayAddActivitySub => 'Ereignis, Aufgabe oder Geburtstag';

  @override
  String get dayReminder => 'Erinnerung';

  @override
  String get actEditActivity => 'Termin bearbeiten';

  @override
  String get actLeadAtTime => 'Zur Startzeit';

  @override
  String get actLead10Min => '10 Min. vorher';

  @override
  String get actLead30Min => '30 Min. vorher';

  @override
  String get actLead1Hour => '1 Std. vorher';

  @override
  String get actLead1Day => '1 Tag vorher';

  @override
  String get actEvent => 'Ereignis';

  @override
  String get actTask => 'Aufgabe';

  @override
  String get actBirthday => 'Geburtstag';

  @override
  String get actTitleField => 'Titel';

  @override
  String get actAllDay => 'Ganztägig';

  @override
  String get actTimeField => 'Uhrzeit';

  @override
  String get actRemindMe => 'Erinnere mich';

  @override
  String get actRemindMeSub =>
      'Eine sanfte Benachrichtigung – getrennt von deinen Schichtweckern.';

  @override
  String get actRemindAt => 'Erinnern um';

  @override
  String get actReminderPassed =>
      'Diese Zeit ist bereits vorbei – diese Erinnerung kommt nicht.';

  @override
  String get actNoteOptional => 'Notiz (optional)';

  @override
  String get actCompleted => 'Erledigt';

  @override
  String get tipDashboardTitle => 'Deine Übersicht';

  @override
  String get tipDashboardBody =>
      'Deine Zentrale. Sieh deine nächste Schicht mit Live-Countdown und wo du im Schichtrhythmus stehst. Tippe auf eine Kachel für Details.';

  @override
  String get tipTimelineTitle => 'Dein ganzer Dienstplan';

  @override
  String get tipTimelineBody =>
      'Wechsle oben zwischen Liste und Monatskalender. Tippe auf einen Tag, um eine Schicht zu bearbeiten – oder ein Ereignis, eine Aufgabe oder einen Geburtstag hinzuzufügen.';

  @override
  String get tipManageTitle => 'Erstellen & anpassen';

  @override
  String get tipManageBody =>
      'Erstelle einen Schichtrhythmus, füge eine Einzelschicht (Überstunden) hinzu oder pausiere deinen ganzen Plan für den Urlaub – alles hier.';

  @override
  String get tipAlarmsTitle => 'Deine Wecker';

  @override
  String get tipAlarmsBody =>
      'Alle Wecker aus deinen Schichten plus deine eigenen. Tippe auf einen, um Zeit oder Ton zu ändern, oder mach ihn zu einem Schüttel-Wecker für kritische Schichten.';

  @override
  String get tipSleepTitle => 'Schlafplan';

  @override
  String get tipSleepBody =>
      'Ein Plan zum Runterkommen, der deinem Dienstplan folgt: Setz ein Schlafziel und starte ausgeruht in deine nächste Schicht.';

  @override
  String get tipReplayHint =>
      'Jederzeit erneut ansehen unter Einstellungen › So funktioniert\'s.';

  @override
  String get tipDontShow => 'Keine Tipps zeigen';

  @override
  String get tipGotIt => 'Verstanden';

  @override
  String get timelineListView => 'Liste';

  @override
  String get timelineMonthView => 'Monat';

  @override
  String get shiftTypeAftShort => 'Spät';

  @override
  String get timelineNoShifts =>
      'Keine Schichten geplant. Tippe auf +, um eine hinzuzufügen.';

  @override
  String timelineNoMatch(String filter) {
    return 'Keine Schichten passen zum Filter „$filter“.';
  }

  @override
  String get timelineRestDay => 'Ruhetag';

  @override
  String timelineRestDayReason(String reason) {
    return 'Ruhetag · $reason';
  }

  @override
  String get timelineAllDay => 'Ganztägig';

  @override
  String get calLegendPausedLeave => 'Pausiert / Urlaub';

  @override
  String get calLegendActivity => 'Termin';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterWork => 'Arbeit';

  @override
  String get criticalHoldToDismiss => 'Oder gedrückt halten zum Beenden';

  @override
  String get patternChoosePattern => 'Muster wählen';

  @override
  String get patternRotatingSwings => 'Wechselschicht-Rhythmen';

  @override
  String get patternDaySwings => 'Nur Tagschichten';

  @override
  String get patternNightSwings => 'Nur Nachtschichten';

  @override
  String get patternShiftTimes => 'Schichtzeiten';

  @override
  String get patternGenerate => 'Tag 1 festlegen & erstellen';

  @override
  String get patternSelectDay1 => 'Wähle deinen nächsten Tag 1';

  @override
  String patternDay1Hint(String label) {
    return 'Erster Tag deines Blocks ($label)';
  }

  @override
  String get patternNextDay1 => 'Nächster Tag 1';

  @override
  String get patternUseThisDate => 'Dieses Datum verwenden';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schichten erstellt',
      one: '1 Schicht erstellt',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'Erstellen fehlgeschlagen: $error';
  }

  @override
  String get patternFirstBlockFallback => 'ersten';

  @override
  String get patternBuildCustom => 'Eigenen Dienstplan erstellen';

  @override
  String get patternBuildCustomSub =>
      'Keine Vorlage passt? Stell deine eigenen Blöcke zusammen.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Spät',
      one: '1 Spät',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Nächte',
      one: '1 Nacht',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '$n frei';
  }

  @override
  String get builderNewRoster => 'Neuer Dienstplan';

  @override
  String get builderEditRoster => 'Dienstplan bearbeiten';

  @override
  String get builderNewSub => 'Richte deinen Schichtrhythmus ein';

  @override
  String get builderEditSub =>
      'Diesen gespeicherten Dienstplan ändern und ersetzen';

  @override
  String get builderNameHint => 'Name (z. B. Mein 14-Tage-Rhythmus)';

  @override
  String get builderCycleLength => 'ZYKLUSLÄNGE';

  @override
  String get builderStartDate => 'STARTDATUM';

  @override
  String get builderShiftBlocks => 'SCHICHTBLÖCKE';

  @override
  String get builderAddShiftBlock => 'Schichtblock hinzufügen';

  @override
  String get builderCreateRoster => 'Dienstplan erstellen';

  @override
  String get builderSaveChanges => 'Änderungen speichern';

  @override
  String get builderReplaceWarning =>
      'Speichern ersetzt diesen Dienstplan. Darauf eingetragene Urlaube / freie Tage werden zurückgesetzt.';

  @override
  String get builderBackToOptions => 'Zurück zur Auswahl';

  @override
  String get builderOrImport => 'ODER BESTEHENDEN DIENSTPLAN IMPORTIEREN';

  @override
  String get builderImportViaAi => 'Mit KI importieren';

  @override
  String get builderScanning => 'Wird gescannt…';

  @override
  String get builderScanInstead => 'Stattdessen Foto vom Dienstplan scannen';

  @override
  String get builderCustomChip => 'Eigene';

  @override
  String get builderCycleLengthLabel => 'Zykluslänge';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'Datum wählen';

  @override
  String get builderNoBlocksYet => 'Noch keine Blöcke';

  @override
  String get builderNoBlocksSub =>
      'Füge Schichtblöcke hinzu, um deinen Rhythmus festzulegen';

  @override
  String builderDaysLine(String ranges) {
    return 'Tage $ranges';
  }

  @override
  String get builderEditBlock => 'Block bearbeiten';

  @override
  String get builderRemoveBlock => 'Block entfernen';

  @override
  String get builderPickRosterStart => 'Startdatum des Dienstplans wählen';

  @override
  String get builderPickScanStart =>
      'Startdatum des gescannten Dienstplans wählen';

  @override
  String get builderScanCamera => 'Mit Kamera scannen';

  @override
  String get builderImportScreenshot => 'Screenshot importieren';

  @override
  String builderScanFailed(String error) {
    return 'Scan fehlgeschlagen: $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'Keine Schichtzeiten erkannt. Schneide das Bild enger um die Tabelle zu.';

  @override
  String get builderCustomRosterFallback => 'Eigener Dienstplan';

  @override
  String get builderScannedRosterFallback => 'Gescannter Dienstplan';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dienstplan aktualisiert – $count Schichten geplant',
      one: 'Dienstplan aktualisiert – 1 Schicht geplant',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Erstellt – $count Schichten geplant',
      one: 'Erstellt – 1 Schicht geplant',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'Dienstplan konnte nicht erstellt werden: $error';
  }

  @override
  String get builderRosterImported =>
      'Dienstplan in deinen Kalender importiert';

  @override
  String builderCouldNotImport(String error) {
    return 'Dienstplan konnte nicht importiert werden: $error';
  }

  @override
  String get blockAddTitle => 'Schichtblock hinzufügen';

  @override
  String get blockEditTitle => 'Schichtblock bearbeiten';

  @override
  String get blockStart => 'Beginn';

  @override
  String get blockEnd => 'Ende';

  @override
  String get blockTapDays => 'Tippe auf die Tage dieser Schicht';

  @override
  String get blockUntappedOff => 'Nicht angetippte Tage sind frei.';

  @override
  String blockOverlap(String ranges) {
    return 'Diese Zeit überschneidet sich mit einer anderen Schicht an Tag $ranges – ändere die Zeit oder diese Tage.';
  }

  @override
  String get blockAdd => 'Block hinzufügen';

  @override
  String get blockSave => 'Block speichern';

  @override
  String get aiPromptCopied =>
      'Prompt kopiert! Füge ihn zusammen mit deinem Dienstplan in deine KI-App ein.';

  @override
  String get aiNothingToPaste => 'Die Zwischenablage ist leer.';

  @override
  String get aiNoValidShifts =>
      'Keine gültigen Schichten erkannt. Hast du den kopierten KI-Prompt verwendet?';

  @override
  String get aiStep1 => 'Prompt kopieren';

  @override
  String get aiCopied => 'Kopiert!';

  @override
  String get aiCopyPrompt => 'KI-Prompt kopieren';

  @override
  String get aiStep1Sub =>
      'Füge ihn in ChatGPT, Gemini oder eine andere KI-App ein, ergänze den Text oder ein Foto/Screenshot deines Dienstplans und sende ihn ab.';

  @override
  String get aiStep2 => 'Antwort der KI einfügen';

  @override
  String get aiPaste => 'Einfügen';

  @override
  String get aiParsePreview => 'Auswerten & Vorschau';

  @override
  String get aiStep3 => 'Erkannte Schichten prüfen';

  @override
  String get aiStep3Sub =>
      'Tippe auf ein Etikett, um zwischen Tag, Spät und Nacht zu wechseln, falls die KI danebenlag.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage importieren',
      one: '1 Tag importieren',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'Mach mit Hilfe einer KI-App aus beliebigem Dienstplan-Text echte Schichten.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0 · $working Arbeit · $off frei';
  }

  @override
  String get draftReviewTitle => 'Gescannten Dienstplan prüfen';

  @override
  String draftRemovedDay(String date) {
    return '$date entfernt';
  }

  @override
  String get draftUndo => 'Rückgängig';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage im Dienstplan gespeichert',
      one: '1 Tag im Dienstplan gespeichert',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'Name des Dienstplans';

  @override
  String get draftScannedImage => 'Gescanntes Bild';

  @override
  String get draftScannedImageSub =>
      'Tippe auf das Bild zum Vergrößern und Vergleichen';

  @override
  String get draftImageError =>
      'Das gescannte Bild konnte nicht angezeigt werden.';

  @override
  String get draftRemove => 'Entfernen';

  @override
  String get draftNoEndTime =>
      'Ohne Endzeit gescannt – lege sie fest, um speichern zu können.';

  @override
  String get draftTime => 'Uhrzeit';

  @override
  String get draftSetEnd => 'Ende festlegen';

  @override
  String get draftConfirmSave => 'Bestätigen & speichern';

  @override
  String notifBeforeYourShift(String type) {
    return 'Vor deiner Schicht ($type)';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind um $time';
  }

  @override
  String get notifWindDownTitle => 'Zeit zum Runterkommen 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'Leg das Handy weg – Schlafenszeit ist $time.';
  }

  @override
  String get notifWindDownBody =>
      'Leg das Handy weg und komm langsam zur Ruhe.';

  @override
  String get notifBedtimeTitle => 'Schlafenszeit 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return 'Ab ins Bett für ~$hours Std. Schlaf vor deiner $shift – Wecker um $time.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return 'Ab ins Bett für dein Schlafziel von $hours Std.';
  }

  @override
  String get notifShiftDay => 'Tagschicht';

  @override
  String get notifShiftAfternoon => 'Spätschicht';

  @override
  String get notifShiftNight => 'Nachtschicht';

  @override
  String get notifShiftGeneric => 'Schicht';

  @override
  String get notifTrialEndsTitle => 'Dein Rostrik-Test endet morgen';

  @override
  String get notifTrialEndsBody =>
      'Schalte den Vollzugriff frei, damit deine Schichtwecker weiter klingeln.';

  @override
  String seedWakeUpLabel(String type) {
    return 'Wecker ($type)';
  }

  @override
  String get seedShiftGeneric => 'Schicht';

  @override
  String commonListAnd(String items, String last) {
    return '$items & $last';
  }

  @override
  String get soundClassic => 'Klassisch';

  @override
  String get soundSiren => 'Sirene';

  @override
  String get soundDigital => 'Digital';

  @override
  String get soundChime => 'Glockenspiel';

  @override
  String get patternFirstResponder => 'Rettungsdienst-Standard';

  @override
  String get ocrCropTitle =>
      'NUR deine Zeile zuschneiden – nicht das ganze Team';

  @override
  String get draftNameHint => 'z. B. Dienstplan Mai';
}
