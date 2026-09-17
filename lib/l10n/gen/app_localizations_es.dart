// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'Antes de empezar';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik está hecho para despertarte en cada turno. Un aviso honesto: en cualquier teléfono, el sistema operativo —no la app— tiene la última palabra y, en casos poco frecuentes, puede retrasar o silenciar cualquier app de alarmas (ahorro de batería agresivo, cierres forzados o justo después de actualizar el sistema).';

  @override
  String get legalBodyBackupAdvice =>
      'Para los turnos que no te puedes perder, ten una segunda alarma de respaldo. Es buena práctica con cualquier alarma, incluida la que trae tu teléfono.';

  @override
  String get legalReviewAndAccept => 'Revisa y acepta:';

  @override
  String get legalPrivacyPolicy => 'Política de privacidad';

  @override
  String get legalTermsOfUse => 'Condiciones de uso';

  @override
  String get legalConsentCheckbox =>
      'Entiendo que el sistema operativo puede afectar a cualquier app de alarmas y acepto la Política de privacidad y las Condiciones de uso.';

  @override
  String get legalAgreeContinue => 'Aceptar y continuar';

  @override
  String get legalUpdatedTitle => 'Hemos actualizado nuestras condiciones';

  @override
  String get legalUpdatedBody =>
      'Nuestra Política de Privacidad y Condiciones de Uso han cambiado. Tómate un momento para revisarlas antes de continuar.';

  @override
  String get legalUpdatedAccept => 'Las he revisado y acepto';

  @override
  String get commonSaving => 'Guardando…';

  @override
  String get commonCouldNotOpenLink => 'No se pudo abrir el enlace.';

  @override
  String get welcomeTagline =>
      'El despertador inteligente para quienes trabajan por turnos.';

  @override
  String get welcomeSubTagline =>
      'Alarmas que siguen tu rotación de turnos, no solo los días laborables.';

  @override
  String welcomeTrialTitle(int days) {
    return 'Prueba gratis de $days días';
  }

  @override
  String get welcomeTrialBody =>
      'Acceso completo a todas las funciones, sin tarjeta. Después, un único pago; nunca una suscripción.';

  @override
  String get welcomeGetStarted => 'Empezar';

  @override
  String get welcomeSkip => 'Omitir / Configurar más tarde';

  @override
  String get welcomeTimeFormat => 'Formato de hora';

  @override
  String get welcomeWeekStarts => 'La semana empieza';

  @override
  String get common12h => '12 h';

  @override
  String get common24h => '24 h';

  @override
  String get commonSundayShort => 'Dom';

  @override
  String get commonMondayShort => 'Lun';

  @override
  String get rosterTypeTitle => 'Elige un tipo de turnos';

  @override
  String get rosterTypeQuestion => '¿Cómo son tus turnos?';

  @override
  String get rosterTypeDay => 'Turnos de día';

  @override
  String get rosterTypeNight => 'Turnos de noche';

  @override
  String get rosterTypeRotating => 'Rotativos';

  @override
  String get rosterTypeCustom => 'Personalizado';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonComingSoon => 'Próximamente';

  @override
  String get permsTitle => 'Permisos';

  @override
  String get permsIntro =>
      'Rostrik necesita algunos permisos para que las alarmas suenen de forma fiable. Puedes cambiarlos después en los ajustes del sistema.';

  @override
  String get permsNotifications => 'Notificaciones';

  @override
  String get permsNotificationsSub =>
      'Necesarias para mostrar la pantalla de despertar.';

  @override
  String get permsExactAlarms => 'Alarmas exactas';

  @override
  String get permsExactAlarmsSub =>
      'Permite que las alarmas suenen a la hora exacta.';

  @override
  String get permsBatteryUnrestricted => 'Batería sin restricciones';

  @override
  String get permsBatteryGrantedSub =>
      'Las alarmas están protegidas frente a la optimización de batería.';

  @override
  String get permsBatteryDeniedSub =>
      'Algunos teléfonos cierran apps en segundo plano. Toca para solucionarlo.';

  @override
  String get permsUnrestrictedBadge => 'Sin restricciones';

  @override
  String get batteryDialogTitle => 'Mantén vivas las alarmas';

  @override
  String get batteryDialogIntro =>
      'Algunos teléfonos (Samsung, Xiaomi, Oppo, Huawei) cierran de forma agresiva las apps en segundo plano para ahorrar batería. Si le pasa a Rostrik, una alarma podría silenciarse antes de sonar.';

  @override
  String get batteryDialogMarkUnrestricted =>
      'Marca Rostrik como Sin restricciones para evitarlo:';

  @override
  String get batteryStep1 => 'Abre los ajustes de esta app (botón de abajo).';

  @override
  String get batteryStep2 => 'Toca Batería (o \"Uso de batería de la app\").';

  @override
  String get batteryStep3 =>
      'Elige Sin restricciones (no \"Optimizada\" ni \"Restringida\").';

  @override
  String get batteryStep4 =>
      'Si ves \"Permitir actividad en segundo plano\", actívalo también.';

  @override
  String get batteryStep5 =>
      'Desactiva \"Pausar actividad de la app si no se usa\" (o \"Quitar permisos si la app no se usa\") para que Android no retire los permisos de alarma mientras no la usas.';

  @override
  String get commonNotNow => 'Ahora no';

  @override
  String get batteryGoToSettings => 'Ir a Ajustes';

  @override
  String get armEngineTitle => 'Activa tus alarmas';

  @override
  String get armEngineRosterReady => 'Tus turnos están listos';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · empieza el $date';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'Activaremos alarmas de despertar ($summary) antes de cada turno correspondiente.';
  }

  @override
  String get armEngineArming => 'Activando…';

  @override
  String get armEngineCta => 'Automatizar mis alarmas';

  @override
  String get armEngineLeadTimeLabel => 'Antelación de la alarma';

  @override
  String get armEngineLeadTimeHelper =>
      'Cuánto antes del inicio del turno suena la alarma.';

  @override
  String get shiftTypeDay => 'Día';

  @override
  String get shiftTypeAfternoon => 'Tarde';

  @override
  String get shiftTypeNight => 'Noche';

  @override
  String get shiftTypeOff => 'Libre';

  @override
  String get weekdaysNone => 'Ningún día';

  @override
  String get weekdaysEveryDay => 'Todos los días';

  @override
  String get weekdaysWeekdays => 'Entre semana';

  @override
  String get weekdaysWeekends => 'Fines de semana';

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
  String get commonClose => 'Cerrar';

  @override
  String get commonSkip => 'Omitir';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonDone => 'Hecho';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get walkthroughIntroTitle => 'Un recorrido de 60 segundos';

  @override
  String get walkthroughIntroBodyTwo =>
      'Dos cosas que hacen que Rostrik funcione para ti. Puedes omitirlo cuando quieras.';

  @override
  String get walkthroughIntroBodyOne =>
      'Lo que hace que Rostrik funcione para ti. Puedes omitirlo cuando quieras.';

  @override
  String get walkthroughPaintLabel => 'Pinta tus turnos';

  @override
  String get walkthroughPaintDetail =>
      'Toca los días que trabajas. Así de rápido.';

  @override
  String get walkthroughShakeLabel => 'Agita para apagar';

  @override
  String get walkthroughShakeDetail =>
      'Una sacudida firme apaga una alarma crítica.';

  @override
  String get walkthroughTryEach => 'Toca Siguiente para probar cada una.';

  @override
  String get walkthroughTryIt => 'Toca Siguiente para probarlo.';

  @override
  String get walkthroughPaintBody =>
      'Toca los días que trabajas. En el editor real puedes añadir más bloques (tardes, noches) del mismo modo.';

  @override
  String get walkthroughPaintPrompt =>
      'Toca un día para pintarle un turno de día.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '¡Bien! Esos $count días son un bloque de día. Los días sin tocar quedan libres. Así de fácil.',
      one:
          '¡Bien! Ese día es un bloque de día. Los días sin tocar quedan libres. Así de fácil.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'Las alarmas de turno crítico necesitan una sacudida firme y sostenida para apagarse, así un toque medio dormido no basta. Pruébalo: agita el teléfono.';

  @override
  String get walkthroughShakeSuccess => '¡Lo tienes!';

  @override
  String get walkthroughShakeSuccessDetail =>
      'Así es exactamente como silenciarás una alarma crítica.';

  @override
  String get walkthroughDoneTitle => 'Todo listo';

  @override
  String get walkthroughDoneBody =>
      'Crea tus turnos cuando quieras desde Gestionar y vuelve a ver este recorrido en Ajustes → Ayuda.';

  @override
  String get navDashboard => 'Inicio';

  @override
  String get navTimeline => 'Agenda';

  @override
  String get navManage => 'Gestionar';

  @override
  String get navAlarms => 'Alarmas';

  @override
  String get navSleep => 'Sueño';

  @override
  String get onbPatternTitle => 'Elige tu rotación';

  @override
  String get purchaseTrialEnded => 'Tu prueba gratis ha terminado';

  @override
  String get purchaseBody =>
      'Desbloquea Rostrik una sola vez para que tus alarmas de turno sigan sonando. Tus turnos, alarmas y ajustes están a salvo y se reanudan en cuanto desbloquees.';

  @override
  String get purchaseAlarmsWontRing =>
      'Hasta entonces, las alarmas no sonarán.';

  @override
  String get purchaseUnlock => 'Desbloquear acceso completo';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'Desbloquear acceso completo · $price';
  }

  @override
  String get purchaseRestore => 'Restaurar compra';

  @override
  String get purchaseOneTime => 'Pago único. Sin suscripción.';

  @override
  String get purchaseUnavailable =>
      'Las compras no están disponibles ahora mismo. Revisa tu conexión y vuelve a intentarlo.';

  @override
  String get purchaseCheckingPrevious => 'Buscando una compra anterior…';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLegalAbout => 'LEGAL E INFORMACIÓN';

  @override
  String get settingsHelp => 'AYUDA';

  @override
  String get settingsHowItWorks => 'Cómo funciona';

  @override
  String get settingsReplayTourShake =>
      'Repite el recorrido: pintar turnos + agitar para apagar';

  @override
  String get settingsReplayTour => 'Repite el recorrido: pintar turnos';

  @override
  String get settingsScreenTips => 'Mostrar consejos en pantalla';

  @override
  String get settingsScreenTipsSub =>
      'Consejos de una sola vez en cada pantalla. Actívalo para volver a verlos.';

  @override
  String get settingsFullAccess => 'ACCESO COMPLETO';

  @override
  String get settingsFullAccessUnlocked => 'Acceso completo desbloqueado';

  @override
  String get settingsThanks => 'Gracias por apoyar a Rostrik.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Prueba gratis: quedan $days días',
      one: 'Prueba gratis: queda 1 día',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'Prueba gratis terminada';

  @override
  String get settingsUnlockPitch =>
      'Desbloquea una sola vez para que tus alarmas de turno sigan sonando al terminar la prueba. Pago único, nunca una suscripción.';

  @override
  String get settingsRestore => 'Restaurar';

  @override
  String get settingsBrandTagline =>
      'Alarmas hechas fuera del horario de oficina';

  @override
  String get settingsLeadTime => 'Antelación';

  @override
  String get settingsLeadTimeSub =>
      'La alarma suena con esta antelación antes de cada turno.';

  @override
  String get settingsSnoozeDuration => 'Tiempo al posponer';

  @override
  String get settingsSnoozeDurationSub =>
      'Cuánto retrasa el botón Posponer una alarma que está sonando.';

  @override
  String get settingsMinutesLabel => 'Minutos';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => 'CICLOS DE TURNOS';

  @override
  String get settingsShiftCyclesSub =>
      'Turnos que has generado a partir de un patrón o plantilla.';

  @override
  String get settingsAddShiftCycle => 'Añadir ciclo de turnos';

  @override
  String get settingsNoRosters =>
      'Todavía no has generado ningún calendario de turnos.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get settingsDeleteRosterTitle => '¿Eliminar turnos?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'eliminarán $count turnos',
      one: 'eliminará 1 turno',
    );
    return '¿Eliminar \"$label\"? Se cancelarán las alarmas pendientes y se $_temp0.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return 'Se eliminó \"$label\"';
  }

  @override
  String get commonActive => 'Activo';

  @override
  String get commonUpcoming => 'Próximo';

  @override
  String get commonPast => 'Pasado';

  @override
  String get settingsWorkHistory => 'HISTORIAL DE TRABAJO';

  @override
  String get settingsWorkHistorySub =>
      'Revisa y exporta tus turnos personalizados completados para comprobar tus nóminas.';

  @override
  String get settingsViewWorkHistory => 'Ver y exportar historial';

  @override
  String get settingsPreferences => 'PREFERENCIAS';

  @override
  String get settingsPreferencesSub => 'Cómo se muestra tu horario en la app.';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeSub =>
      'Oscuro es el tema predeterminado de Rostrik. Claro usa una paleta crema cálida.';

  @override
  String get settings24h => 'Usar formato de 24 horas';

  @override
  String get settings24hOn => 'Las horas se muestran como 14:30';

  @override
  String get settings24hOff => 'Las horas se muestran como 02:30 PM';

  @override
  String get settingsWeekStartTitle => 'Empezar el calendario en lunes';

  @override
  String get settingsWeekStartMon => 'Las semanas empiezan en lunes';

  @override
  String get settingsWeekStartSun => 'Las semanas empiezan en domingo';

  @override
  String get settingsTimelineOpensOn => 'La agenda se abre en';

  @override
  String get commonList => 'Lista';

  @override
  String get commonMonth => 'Mes';

  @override
  String get settingsCalendar => 'CALENDARIO';

  @override
  String get settingsCalendarSync =>
      'Sincronizar con Google / calendario del dispositivo';

  @override
  String get settingsCalendarSyncSub =>
      'Copia automáticamente tus turnos en un calendario \"Rostrik Roster\" dedicado en tu teléfono.';

  @override
  String get settingsCalSyncOff =>
      'Sincronización desactivada. Se borraron los próximos eventos de \"Rostrik Roster\".';

  @override
  String get settingsCalSyncMirroring =>
      'Copiando tus turnos en el calendario \"Rostrik Roster\"…';

  @override
  String get settingsCalPermNeeded =>
      'Se necesita permiso de calendario para sincronizar tus turnos.';

  @override
  String get settingsCalBlocked =>
      'El acceso al calendario está bloqueado. Actívalo en los ajustes del sistema para sincronizar.';

  @override
  String get settingsCalOpenSettings => 'Ajustes';

  @override
  String get settingsCalUnsupported =>
      'La sincronización de calendario no está disponible en este dispositivo.';

  @override
  String get settingsDangerZone => 'ZONA DE PELIGRO';

  @override
  String get settingsDangerZoneSub =>
      'Elimina tus turnos, alarmas y ajustes y vuelve a empezar la configuración desde cero.';

  @override
  String get settingsResetAppData => 'Restablecer datos de la app';

  @override
  String get settingsResetTitle => '¿Restablecer la app?';

  @override
  String get settingsResetBody =>
      '¿Seguro? Se eliminarán tus turnos, alarmas y ajustes.';

  @override
  String get settingsResetConfirm => 'Restablecer';

  @override
  String get dashNoUpcomingShifts => 'No hay próximos turnos';

  @override
  String get dashEnjoyTimeOff => 'Disfruta de tu tiempo libre.';

  @override
  String get dashInProgress => 'EN CURSO';

  @override
  String get dashRotation => 'Rotación';

  @override
  String get dashAlarmsCantRing =>
      'Las alarmas no pueden sonar de forma fiable';

  @override
  String get dashNotifsOffIssue =>
      'Las notificaciones están desactivadas: una alarma que suena no puede mostrar su pantalla ni apagarse.';

  @override
  String get dashOpenSettings => 'Abrir ajustes';

  @override
  String get dashExactBlockedIssue =>
      'Las alarmas exactas están bloqueadas: no se puede programar ningún despertar.';

  @override
  String get dashAlarmsWontTakeOverScreen =>
      'Las alarmas no ocuparán la pantalla';

  @override
  String get dashFullScreenBlockedIssue =>
      'Las alarmas a pantalla completa están desactivadas: con el teléfono bloqueado verás una notificación en lugar de la pantalla de alarma.';

  @override
  String get dashAllow => 'Permitir';

  @override
  String get dashSlideToSkip => 'Desliza para omitir esta alarma';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Desliza para omitir las $count alarmas',
      one: 'Desliza para omitir la alarma',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'Descartar próxima alarma · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Omitir las $count alarmas de este turno',
      one: 'Omitir la alarma de este turno',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'Mantener alarma';

  @override
  String get dashMyRotation => 'Mi rotación';

  @override
  String get dashCalendarUpcoming => 'Calendario y próximos turnos';

  @override
  String get dashNextShifts => 'Próximos turnos';

  @override
  String get dashOpenTimeline => 'Abrir agenda';

  @override
  String heroStartsIn(String countdown) {
    return 'Empieza en $countdown';
  }

  @override
  String heroEndsIn(String countdown) {
    return 'Termina en $countdown';
  }

  @override
  String get heroStartsInPrefix => 'Empieza en';

  @override
  String get heroEndsInPrefix => 'Termina en';

  @override
  String heroStartsTodayAt(String time) {
    return 'Empieza hoy a las $time';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'Empezó hoy a las $time';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'Empieza mañana a las $time';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'Empezó ayer a las $time';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'Empieza ayer a las $time';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return 'Empieza el $date a las $time';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return 'Empezó el $date a las $time';
  }

  @override
  String get shiftTypeDayShift => 'Turno de día';

  @override
  String get shiftTypeAfternoonShift => 'Turno de tarde';

  @override
  String get shiftTypeNightShift => 'Turno de noche';

  @override
  String heroDayXofY(int x, int y, String label) {
    return 'Día $x de $y · $label';
  }

  @override
  String get heroOffTomorrow => 'Libre mañana';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Libre en $days días',
      one: 'Libre en 1 día',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'Vuelves mañana';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Vuelves en $days días',
      one: 'Vuelves en 1 día',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'Libre / Descanso';

  @override
  String durationDayShort(int d) {
    return '$d d';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d d $h h';
  }

  @override
  String get alarmsTitle => 'Alarmas';

  @override
  String get alarmsAddTooltip => 'Añadir alarma';

  @override
  String get alarmsSortTooltip => 'Ordenar alarmas';

  @override
  String get alarmsSortByTime => 'Por hora';

  @override
  String get alarmsSortByShiftType => 'Por tipo de turno';

  @override
  String get alarmsEmptyTitle => 'Aún no hay alarmas.';

  @override
  String get alarmsEmptyBody => 'Toca + para añadir una.';

  @override
  String get alarmsNextAlarm => 'PRÓXIMA ALARMA';

  @override
  String get alarmsHolidayMode => 'Modo vacaciones';

  @override
  String get alarmsHolidayModeSub =>
      'Las alarmas están en pausa: no sonará nada.';

  @override
  String get alarmsNoUpcoming => 'No hay próxima alarma de turno';

  @override
  String get alarmsNoUpcomingSub =>
      'Añade una alarma que siga la rotación o genera tus turnos.';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'para tu turno ($type) · $day';
  }

  @override
  String get commonToday => 'Hoy';

  @override
  String get commonTomorrow => 'Mañana';

  @override
  String get alarmsOffWontRing => 'Desactivada: no sonará';

  @override
  String get alarmsNoUpcomingRing => 'No hay ningún aviso programado';

  @override
  String alarmsNextRing(String day, String time) {
    return 'Próximo aviso: $day a las $time';
  }

  @override
  String get alarmsSwipeToDelete => 'Desliza para eliminar';

  @override
  String get alarmsRingsOnceAutoDelete => 'Suena una vez · se elimina sola';

  @override
  String get alarmsRingsOnce => 'Suena una sola vez';

  @override
  String get alarmsYourShift => 'tu turno';

  @override
  String alarmsShiftsOfType(String type) {
    return 'turnos de $type';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'Hora exacta · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$lead antes de $shift · predeterminado';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$lead antes de $shift';
  }

  @override
  String get createEditAlarm => 'Editar alarma';

  @override
  String get createNewAlarm => 'Nueva alarma';

  @override
  String get createDefaultLabel => 'Despertar';

  @override
  String get createFallbackLabel => 'Alarma';

  @override
  String get createPickBecomesDefault =>
      'Tu elección será la predeterminada para las nuevas alarmas.';

  @override
  String get createSelectFromFiles => 'Elegir de Archivos';

  @override
  String get createFilesSub =>
      'Elige un archivo de audio guardado en tu dispositivo';

  @override
  String get createSelectSystemTone => 'Elegir tono del sistema';

  @override
  String get createSystemToneSub =>
      'Elige entre los sonidos de alarma de tu dispositivo';

  @override
  String get createAlarmTiming => 'Momento de la alarma';

  @override
  String get createLeadTimeMode => 'Antelación';

  @override
  String get createExactTimeMode => 'Hora exacta';

  @override
  String createFiresAt(String time) {
    return 'Suena a las $time';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return '$lead antes del inicio del turno';
  }

  @override
  String get createLinkedShift => 'Turno vinculado';

  @override
  String get createRepeatOn => 'Repetir los';

  @override
  String get createLabelField => 'Nombre';

  @override
  String get createLabelHint => 'p. ej. Despertar';

  @override
  String get createCriticalShift => 'Turno crítico';

  @override
  String get createCriticalShiftSub =>
      'Agita para apagar · seguridad de 3 segundos manteniendo pulsado';

  @override
  String get createRingtone => 'Tono';

  @override
  String get commonStop => 'Detener';

  @override
  String get commonPlay => 'Reproducir';

  @override
  String get createVibrate => 'Vibrar';

  @override
  String get createRepeat => 'Repetir';

  @override
  String get createRepeatRotation => 'Rotación';

  @override
  String get createRepeatWeekly => 'Semanal';

  @override
  String get createRepeatOneTime => 'Una vez';

  @override
  String get createPickOneDay => 'Elige al menos un día';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSaveChanges => 'Guardar cambios';

  @override
  String get createTimeBeforeShift => 'Tiempo antes del turno';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get sleepTitle => 'Sueño';

  @override
  String get sleepTargetHeader => 'OBJETIVO DE SUEÑO';

  @override
  String get sleepTargetSub =>
      'Cuántas horas quieres dormir. Rostrik cuenta hacia atrás desde tu próxima alarma para fijar la hora de acostarte esta noche.';

  @override
  String get sleepRemindersHeader => 'RECORDATORIOS';

  @override
  String get sleepWindDownHeader => 'ANTELACIÓN PARA DESCONECTAR';

  @override
  String get sleepWindDownSub =>
      'Cuánto antes de acostarte llega el aviso para desconectar.';

  @override
  String get sleepSoundsHeader => 'SONIDOS PARA DORMIR';

  @override
  String get sleepSoundsSub =>
      'Ruido blanco y marrón para quedarte dormido. Elige un temporizador y toca un sonido.';

  @override
  String get sleepNothingToPlan => 'Nada que planificar esta noche';

  @override
  String get sleepNothingToPlanSub =>
      'Añade un turno y Rostrik preparará una hora de acostarte personalizada según tu próximo despertar.';

  @override
  String get sleepTransitionDay => 'DÍA DE TRANSICIÓN';

  @override
  String get sleepTransitionTitle =>
      'Mañana tienes turno de noche. Puedes dormir hasta tarde.';

  @override
  String get sleepTransitionBody =>
      'Es un día de transición: tienes un día de descanso antes de las noches, así que no hay alarma temprana. Acumula descanso ahora y deja que tu cuerpo se acueste más tarde esta noche.';

  @override
  String get sleepRestRecovery => 'DESCANSO Y RECUPERACIÓN';

  @override
  String get sleepNoEarlyAlarm => 'No hay alarma temprana';

  @override
  String get sleepRestBody =>
      'Tu próximo turno es dentro de más de un día, así que no hay despertar que planificar esta noche. Duerme a tu ritmo y recupérate; Rostrik preparará tu plan cuando se acerque.';

  @override
  String get sleepTonightsPlan => 'PLAN PARA ESTA NOCHE';

  @override
  String get sleepTargetBedtime => 'Hora de acostarte';

  @override
  String get sleepWindDownStat => 'Desconectar';

  @override
  String get sleepWakeUpStat => 'Despertar';

  @override
  String get sleepDurationStat => 'Duración';

  @override
  String get sleepBedtimeReminder => 'Recordatorio para acostarte';

  @override
  String sleepNudgeAtBedtime(String time) {
    return 'Avísame a las $time para irme a la cama';
  }

  @override
  String get sleepBedtimeSub => 'Un aviso cuando sea hora de irte a la cama';

  @override
  String get sleepWindDownReminder => 'Recordatorio para desconectar';

  @override
  String sleepNudgeAtWindDown(String time) {
    return 'Avísame a las $time para empezar a desconectar';
  }

  @override
  String get sleepWindDownReminderSub =>
      'Un aviso previo para empezar a desconectar';

  @override
  String get commonOff => 'No';

  @override
  String get sleepSoundWhiteNoise => 'Ruido blanco';

  @override
  String get sleepSoundPinkNoise => 'Ruido rosa';

  @override
  String get sleepSoundBrownNoise => 'Ruido marrón';

  @override
  String get sleepSoundFan => 'Ventilador';

  @override
  String get sleepSoundOcean => 'Océano';

  @override
  String get sleepSoundRain => 'Lluvia';

  @override
  String get manageTitle => 'Gestionar';

  @override
  String get manageRosterTools => 'HERRAMIENTAS DE TURNOS';

  @override
  String get manageRosterToolsSub =>
      'Crea y ajusta los turnos que controlan tus alarmas y tu plan de sueño.';

  @override
  String get manageGenerateRotation => 'Generar rotación';

  @override
  String get manageGenerateRotationSub =>
      'Crea un patrón de turnos repetitivo a partir de una plantilla.';

  @override
  String get manageAddCustomShift => 'Añadir turno personalizado';

  @override
  String get manageAddCustomShiftSub =>
      'Añade un turno suelto a tu calendario.';

  @override
  String get manageMarkLeave => 'Marcar permiso / días libres';

  @override
  String get manageMarkLeaveSub =>
      'Pinta de una vez los días que no trabajas (vacaciones, baja).';

  @override
  String get managePauseSchedule => 'Pausar horario';

  @override
  String get managePausedSub =>
      'Modo vacaciones ACTIVADO: las alarmas están silenciadas y tus turnos, a salvo.';

  @override
  String get manageNotPausedSub =>
      'Modo vacaciones: silencia las alarmas mientras estás fuera de turno.';

  @override
  String get markLeaveTitle => 'Marcar permiso';

  @override
  String get markLeaveIntro =>
      'Toca los días que no trabajas, elige un motivo y aplica. Las alarmas de esos días no sonarán y tus turnos quedan intactos.';

  @override
  String get leaveAnnual => 'Vacaciones';

  @override
  String get leaveSick => 'Baja por enfermedad';

  @override
  String get leavePublicHoliday => 'Festivo';

  @override
  String get markLeaveReason => 'Motivo';

  @override
  String get markLeaveFallbackReason => 'permiso';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turnos marcados como $reason.',
      one: '1 turno marcado como $reason.',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => 'Elige los días que quieres marcar';

  @override
  String get markLeaveNoShifts => 'No hay turnos esos días';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aplicar a $count turnos',
      one: 'Aplicar a 1 turno',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => 'Historial de trabajo';

  @override
  String get workHistoryExportTooltip => 'Exportar historial';

  @override
  String workHistoryExportFailed(String error) {
    return 'No se pudo exportar el historial: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turnos trabajados',
      one: '1 turno trabajado',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours h';
  }

  @override
  String get commonPaused => 'En pausa';

  @override
  String workHistoryPausedReason(String reason) {
    return 'En pausa · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'Rotación';

  @override
  String get workHistoryAdHocBadge => 'Extra';

  @override
  String get workHistoryEmptyTitle => 'Aún no hay turnos completados';

  @override
  String get workHistoryEmptyBody =>
      'Tus turnos trabajados, tanto de rotación como personalizados, aparecen aquí al terminar, listos para exportar y comprobar tus nóminas.';

  @override
  String get workHistoryShareSubject => 'Historial de trabajo de Rostrik';

  @override
  String get workHistoryShareText =>
      'Mi historial de trabajo exportado desde Rostrik.';

  @override
  String get shiftEdAddShift => 'Añadir turno';

  @override
  String get shiftEdEditShift => 'Editar turno';

  @override
  String get shiftEdDate => 'Fecha';

  @override
  String get shiftEdPickDate => 'Elegir fecha';

  @override
  String get shiftEdStarts => 'Empieza';

  @override
  String get shiftEdEnds => 'Termina';

  @override
  String get shiftEdPickTime => 'Elegir hora';

  @override
  String get shiftEdEndsNextDay => 'Termina al día siguiente';

  @override
  String get shiftEdPauseTitle => 'Pausar / cancelar este turno';

  @override
  String get shiftEdPausedSub =>
      'La alarma no sonará. Queda en tu calendario como registro.';

  @override
  String get shiftEdNotPausedSub =>
      'Marca un día libre (baja, permiso, festivo) sin eliminarlo.';

  @override
  String get shiftEdReasonOptional => 'Motivo (opcional)';

  @override
  String get dayShifts => 'Turnos';

  @override
  String get dayActivities => 'Actividades';

  @override
  String get dayAddAnotherShift => 'Añadir otro turno';

  @override
  String get dayAddActivity => 'Añadir actividad';

  @override
  String get dayAddActivitySub => 'Evento, tarea o cumpleaños';

  @override
  String get dayReminder => 'Recordatorio';

  @override
  String get actEditActivity => 'Editar actividad';

  @override
  String get actLeadAtTime => 'A la hora';

  @override
  String get actLead10Min => '10 min antes';

  @override
  String get actLead30Min => '30 min antes';

  @override
  String get actLead1Hour => '1 hora antes';

  @override
  String get actLead1Day => '1 día antes';

  @override
  String get actEvent => 'Evento';

  @override
  String get actTask => 'Tarea';

  @override
  String get actBirthday => 'Cumpleaños';

  @override
  String get actTitleField => 'Título';

  @override
  String get actAllDay => 'Todo el día';

  @override
  String get actTimeField => 'Hora';

  @override
  String get actRemindMe => 'Recordármelo';

  @override
  String get actRemindMeSub =>
      'Una notificación suave, independiente de tus alarmas de turno.';

  @override
  String get actRemindAt => 'Recordar a las';

  @override
  String get actReminderPassed =>
      'Esa hora ya ha pasado: este recordatorio no saltará.';

  @override
  String get actNoteOptional => 'Nota (opcional)';

  @override
  String get actCompleted => 'Completada';

  @override
  String get tipDashboardTitle => 'Tu inicio';

  @override
  String get tipDashboardBody =>
      'Tu base. Mira tu próximo turno con cuenta atrás en directo y en qué punto de la rotación estás. Toca un bloque para ver los detalles.';

  @override
  String get tipTimelineTitle => 'Todos tus turnos';

  @override
  String get tipTimelineBody =>
      'Cambia entre la vista de lista y el calendario mensual arriba. Toca cualquier día para editar un turno o añadir un evento, tarea o cumpleaños.';

  @override
  String get tipManageTitle => 'Crear y ajustar';

  @override
  String get tipManageBody =>
      'Crea una rotación de turnos, añade un turno suelto (horas extra) o pausa todo tu horario por un permiso, todo desde aquí.';

  @override
  String get tipAlarmsTitle => 'Tus alarmas';

  @override
  String get tipAlarmsBody =>
      'Todas las alarmas que crean tus turnos y las que añadas tú. Toca una para cambiar su hora o tono, o conviértela en una alarma de turno crítico que se apaga agitando.';

  @override
  String get tipSleepTitle => 'Plan de sueño';

  @override
  String get tipSleepBody =>
      'Un plan para desconectar que sigue tus turnos: fija un objetivo de sueño y llega descansado a tu próximo turno.';

  @override
  String get tipReplayHint =>
      'Vuelve a verlos cuando quieras en Ajustes › Cómo funciona.';

  @override
  String get tipDontShow => 'No mostrar consejos';

  @override
  String get tipGotIt => 'Entendido';

  @override
  String get timelineListView => 'Lista';

  @override
  String get timelineMonthView => 'Mes';

  @override
  String get shiftTypeAftShort => 'Tarde';

  @override
  String get timelineNoShifts =>
      'No hay turnos programados. Toca + para añadir uno.';

  @override
  String timelineNoMatch(String filter) {
    return 'Ningún turno coincide con el filtro $filter.';
  }

  @override
  String get timelineRestDay => 'Día de descanso';

  @override
  String timelineRestDayReason(String reason) {
    return 'Día de descanso · $reason';
  }

  @override
  String get timelineAllDay => 'Todo el día';

  @override
  String get calLegendPausedLeave => 'En pausa / Permiso';

  @override
  String get calLegendActivity => 'Actividad';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterWork => 'Trabajo';

  @override
  String get criticalHoldToDismiss => 'O mantén pulsado para apagar';

  @override
  String get patternChoosePattern => 'Elige un patrón';

  @override
  String get patternRotatingSwings => 'Rotaciones mixtas';

  @override
  String get patternDaySwings => 'Solo turnos de día';

  @override
  String get patternNightSwings => 'Solo turnos de noche';

  @override
  String get patternShiftTimes => 'Horarios de turno';

  @override
  String get patternGenerate => 'Fijar el día 1 y generar';

  @override
  String get patternSelectDay1 => 'Elige tu próximo día 1';

  @override
  String patternDay1Hint(String label) {
    return 'Primer día de tu bloque de $label';
  }

  @override
  String get patternNextDay1 => 'Próximo día 1';

  @override
  String get patternUseThisDate => 'Usar esta fecha';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se generaron $count turnos',
      one: 'Se generó 1 turno',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'Error al generar: $error';
  }

  @override
  String get patternFirstBlockFallback => 'inicio';

  @override
  String get patternBuildCustom => 'Crear turnos personalizados';

  @override
  String get patternBuildCustomSub =>
      '¿No encaja ninguna plantilla? Compón tus propios bloques.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tardes',
      one: '1 tarde',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n noches',
      one: '1 noche',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '$n libres';
  }

  @override
  String get builderNewRoster => 'Nuevo calendario de turnos';

  @override
  String get builderEditRoster => 'Editar turnos';

  @override
  String get builderNewSub => 'Configura tu patrón de rotación de turnos';

  @override
  String get builderEditSub => 'Cambia y reemplaza estos turnos guardados';

  @override
  String get builderNameHint => 'Nombre (p. ej. Mi rotación de 14 días)';

  @override
  String get builderCycleLength => 'DURACIÓN DEL CICLO';

  @override
  String get builderStartDate => 'FECHA DE INICIO';

  @override
  String get builderShiftBlocks => 'BLOQUES DE TURNO';

  @override
  String get builderAddShiftBlock => 'Añadir bloque de turno';

  @override
  String get builderCreateRoster => 'Crear turnos';

  @override
  String get builderSaveChanges => 'Guardar cambios';

  @override
  String get builderReplaceWarning =>
      'Al guardar se reemplazan estos turnos. Las marcas de permiso o días libres pintadas en ellos se restablecerán.';

  @override
  String get builderBackToOptions => 'Volver a las opciones';

  @override
  String get builderOrImport => 'O IMPORTA TUS TURNOS ACTUALES';

  @override
  String get builderImportViaAi => 'Importar con IA';

  @override
  String get builderScanning => 'Escaneando…';

  @override
  String get builderScanInstead => 'Escanear una foto de los turnos';

  @override
  String get builderCustomChip => 'Otra';

  @override
  String get builderCycleLengthLabel => 'Duración del ciclo';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'Elige una fecha';

  @override
  String get builderNoBlocksYet => 'Aún no hay bloques';

  @override
  String get builderNoBlocksSub =>
      'Añade bloques de turno para definir tu rotación';

  @override
  String builderDaysLine(String ranges) {
    return 'Días $ranges';
  }

  @override
  String get builderEditBlock => 'Editar bloque';

  @override
  String get builderRemoveBlock => 'Quitar bloque';

  @override
  String get builderPickRosterStart => 'Elige la fecha de inicio';

  @override
  String get builderPickScanStart =>
      'Elige la fecha de inicio de los turnos escaneados';

  @override
  String get builderScanCamera => 'Escanear con la cámara';

  @override
  String get builderImportScreenshot => 'Importar una captura de pantalla';

  @override
  String builderScanFailed(String error) {
    return 'Error al escanear: $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'No se reconocieron horarios. Prueba a recortar más cerca de la tabla.';

  @override
  String get builderCustomRosterFallback => 'Turnos personalizados';

  @override
  String get builderScannedRosterFallback => 'Turnos escaneados';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Turnos actualizados: $count turnos programados',
      one: 'Turnos actualizados: 1 turno programado',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Creado: $count turnos programados',
      one: 'Creado: 1 turno programado',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'No se pudieron crear los turnos: $error';
  }

  @override
  String get builderRosterImported => 'Turnos importados a tu calendario';

  @override
  String builderCouldNotImport(String error) {
    return 'No se pudieron importar los turnos: $error';
  }

  @override
  String get blockAddTitle => 'Añadir bloque de turno';

  @override
  String get blockEditTitle => 'Editar bloque de turno';

  @override
  String get blockStart => 'Inicio';

  @override
  String get blockEnd => 'Fin';

  @override
  String get blockTapDays => 'Toca los días que cubre este turno';

  @override
  String get blockUntappedOff => 'Los días sin tocar son libres.';

  @override
  String blockOverlap(String ranges) {
    return 'Este horario se solapa con otro turno el día $ranges. Cambia la hora o esos días.';
  }

  @override
  String get blockAdd => 'Añadir bloque';

  @override
  String get blockSave => 'Guardar bloque';

  @override
  String get aiPromptCopied =>
      '¡Instrucción copiada! Pégala en tu app de IA junto con tus turnos.';

  @override
  String get aiNothingToPaste => 'No hay nada que pegar en el portapapeles.';

  @override
  String get aiNoValidShifts =>
      'No se detectaron turnos válidos. Asegúrate de haber usado la instrucción copiada.';

  @override
  String get aiStep1 => 'Copia la instrucción';

  @override
  String get aiCopied => '¡Copiada!';

  @override
  String get aiCopyPrompt => 'Copiar instrucción para IA';

  @override
  String get aiStep1Sub =>
      'Pégala en ChatGPT, Gemini o cualquier app de IA, añade el texto de tus turnos o una foto/captura y envíala.';

  @override
  String get aiStep2 => 'Pega la respuesta de la IA';

  @override
  String get aiPaste => 'Pegar';

  @override
  String get aiParsePreview => 'Analizar y previsualizar';

  @override
  String get aiStep3 => 'Revisa los turnos detectados';

  @override
  String get aiStep3Sub =>
      'Toca una etiqueta para cambiarla entre Día, Tarde y Noche si la IA se equivocó.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count días',
      one: 'Importar 1 día',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'Convierte cualquier texto de turnos en turnos con ayuda de una app de IA.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0 · $working de trabajo · $off libres';
  }

  @override
  String get draftReviewTitle => 'Revisar turnos escaneados';

  @override
  String draftRemovedDay(String date) {
    return 'Se quitó $date';
  }

  @override
  String get draftUndo => 'Deshacer';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se guardaron $count días en tus turnos',
      one: 'Se guardó 1 día en tus turnos',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'Nombre de los turnos';

  @override
  String get draftScannedImage => 'Imagen escaneada';

  @override
  String get draftScannedImageSub => 'Toca la imagen para ampliarla y comparar';

  @override
  String get draftImageError => 'No se pudo mostrar la imagen escaneada.';

  @override
  String get draftRemove => 'Quitar';

  @override
  String get draftNoEndTime =>
      'Escaneado sin hora de fin: añádela para poder guardar.';

  @override
  String get draftTime => 'Hora';

  @override
  String get draftSetEnd => 'Fijar fin';

  @override
  String get draftConfirmSave => 'Confirmar y guardar';

  @override
  String notifBeforeYourShift(String type) {
    return 'Antes de tu turno ($type)';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind a las $time';
  }

  @override
  String get notifWindDownTitle => 'Hora de desconectar 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'Deja las pantallas: tu hora de acostarte es a las $time.';
  }

  @override
  String get notifWindDownBody =>
      'Deja las pantallas y empieza a desconectar para la noche.';

  @override
  String get notifBedtimeTitle => 'Hora de dormir 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return 'Vete a la cama para dormir ~$hours h antes de tu $shift; te despiertas a las $time.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return 'Vete a la cama para cumplir tu objetivo de $hours h de sueño.';
  }

  @override
  String get notifShiftDay => 'turno de día';

  @override
  String get notifShiftAfternoon => 'turno de tarde';

  @override
  String get notifShiftNight => 'turno de noche';

  @override
  String get notifShiftGeneric => 'turno';

  @override
  String get notifTrialEndsTitle => 'Tu prueba de Rostrik termina mañana';

  @override
  String get notifTrialEndsBody =>
      'Desbloquea el acceso completo para que tus alarmas de turno sigan sonando.';

  @override
  String seedWakeUpLabel(String type) {
    return 'Despertar ($type)';
  }

  @override
  String get seedShiftGeneric => 'Turno';

  @override
  String commonListAnd(String items, String last) {
    return '$items y $last';
  }

  @override
  String get soundClassic => 'Clásico';

  @override
  String get soundSiren => 'Sirena';

  @override
  String get soundDigital => 'Digital';

  @override
  String get soundChime => 'Campanilla';

  @override
  String get patternFirstResponder => 'Estándar de emergencias';

  @override
  String get ocrCropTitle => 'Recorta SOLO tu fila, no la de todo el equipo';

  @override
  String get draftNameHint => 'p. ej. Turnos de mayo';
}
