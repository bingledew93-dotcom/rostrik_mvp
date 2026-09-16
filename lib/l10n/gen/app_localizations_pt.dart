// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'Antes de começar';

  @override
  String get legalBodyOsCaveat =>
      'O Rostrik foi feito para te acordar para cada turno. Um aviso sincero: em qualquer celular, quem dá a palavra final é o sistema operacional, não o app. Em casos raros, ele pode atrasar ou silenciar qualquer app de alarme (economia de bateria agressiva, fechamento forçado ou logo após atualizações do sistema).';

  @override
  String get legalBodyBackupAdvice =>
      'Para turnos que você não pode perder de jeito nenhum, mantenha um segundo alarme de reserva. É uma boa prática com qualquer alarme, inclusive o que já vem no seu celular.';

  @override
  String get legalReviewAndAccept => 'Leia e aceite:';

  @override
  String get legalPrivacyPolicy => 'Política de Privacidade';

  @override
  String get legalTermsOfUse => 'Termos de Uso';

  @override
  String get legalConsentCheckbox =>
      'Entendo que o sistema operacional pode afetar qualquer app de alarme e aceito a Política de Privacidade e os Termos de Uso.';

  @override
  String get legalAgreeContinue => 'Aceitar e continuar';

  @override
  String get commonSaving => 'Salvando…';

  @override
  String get commonCouldNotOpenLink => 'Não foi possível abrir o link.';

  @override
  String get welcomeTagline =>
      'O despertador inteligente feito para quem trabalha em turnos.';

  @override
  String get welcomeSubTagline =>
      'Alarmes que seguem a sua escala de revezamento, não só os dias úteis.';

  @override
  String welcomeTrialTitle(int days) {
    return '$days dias grátis';
  }

  @override
  String get welcomeTrialBody =>
      'Acesso total a todos os recursos, sem cartão. Depois, um pagamento único, nunca uma assinatura.';

  @override
  String get welcomeGetStarted => 'Começar';

  @override
  String get welcomeSkip => 'Pular / Configurar depois';

  @override
  String get welcomeTimeFormat => 'Formato de hora';

  @override
  String get welcomeWeekStarts => 'Semana começa';

  @override
  String get common12h => '12 h';

  @override
  String get common24h => '24 h';

  @override
  String get commonSundayShort => 'Dom';

  @override
  String get commonMondayShort => 'Seg';

  @override
  String get rosterTypeTitle => 'Escolha o tipo de escala';

  @override
  String get rosterTypeQuestion => 'Como é a sua escala?';

  @override
  String get rosterTypeDay => 'Turnos diurnos';

  @override
  String get rosterTypeNight => 'Turnos noturnos';

  @override
  String get rosterTypeRotating => 'Revezamento';

  @override
  String get rosterTypeCustom => 'Personalizada';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonComingSoon => 'Em breve';

  @override
  String get permsTitle => 'Permissões';

  @override
  String get permsIntro =>
      'O Rostrik precisa de algumas permissões para tocar os alarmes com confiança. Você pode alterá-las depois nas configurações do sistema.';

  @override
  String get permsNotifications => 'Notificações';

  @override
  String get permsNotificationsSub =>
      'Necessárias para mostrar a tela de despertar.';

  @override
  String get permsExactAlarms => 'Alarmes exatos';

  @override
  String get permsExactAlarmsSub =>
      'Permite que os alarmes toquem no horário exato.';

  @override
  String get permsBatteryUnrestricted => 'Bateria sem restrições';

  @override
  String get permsBatteryGrantedSub =>
      'Os alarmes estão protegidos da otimização de bateria.';

  @override
  String get permsBatteryDeniedSub =>
      'Alguns celulares encerram apps em segundo plano. Toque para corrigir.';

  @override
  String get permsUnrestrictedBadge => 'Sem restrições';

  @override
  String get batteryDialogTitle => 'Mantenha os alarmes ativos';

  @override
  String get batteryDialogIntro =>
      'Alguns celulares (Samsung, Xiaomi, Oppo, Huawei) encerram apps em segundo plano de forma agressiva para economizar bateria. Se isso acontecer com o Rostrik, um alarme pode ser silenciado antes de tocar.';

  @override
  String get batteryDialogMarkUnrestricted =>
      'Marque o Rostrik como Sem restrições para evitar isso:';

  @override
  String get batteryStep1 => 'Abra as configurações deste app (botão abaixo).';

  @override
  String get batteryStep2 =>
      'Toque em Bateria (ou \"Uso da bateria pelo app\").';

  @override
  String get batteryStep3 =>
      'Escolha Sem restrições (não \"Otimizado\" nem \"Restrito\").';

  @override
  String get batteryStep4 =>
      'Se aparecer \"Permitir atividade em segundo plano\", ative também.';

  @override
  String get batteryStep5 =>
      'Desative \"Pausar atividade no app se não for usado\" (ou \"Remover permissões se o app não for usado\") para que o Android não revogue as permissões de alarme enquanto você estiver fora.';

  @override
  String get commonNotNow => 'Agora não';

  @override
  String get batteryGoToSettings => 'Abrir configurações';

  @override
  String get armEngineTitle => 'Ative seus alarmes';

  @override
  String get armEngineRosterReady => 'Sua escala está pronta';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · começa $date';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'Vamos ativar alarmes de despertar ($summary) antes de cada turno correspondente.';
  }

  @override
  String get armEngineArming => 'Ativando…';

  @override
  String get armEngineCta => 'Automatizar meus alarmes';

  @override
  String get armEngineLeadTimeLabel => 'Antecedência do alarme';

  @override
  String get armEngineLeadTimeHelper =>
      'Quanto tempo antes do início do turno o alarme toca.';

  @override
  String get shiftTypeDay => 'Dia';

  @override
  String get shiftTypeAfternoon => 'Tarde';

  @override
  String get shiftTypeNight => 'Noite';

  @override
  String get shiftTypeOff => 'Folga';

  @override
  String get weekdaysNone => 'Nenhum dia';

  @override
  String get weekdaysEveryDay => 'Todos os dias';

  @override
  String get weekdaysWeekdays => 'Dias úteis';

  @override
  String get weekdaysWeekends => 'Fins de semana';

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
  String get commonClose => 'Fechar';

  @override
  String get commonSkip => 'Pular';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonDone => 'Concluir';

  @override
  String get commonNext => 'Próximo';

  @override
  String get walkthroughIntroTitle => 'Um tour de 60 segundos';

  @override
  String get walkthroughIntroBodyTwo =>
      'Duas coisas que fazem o Rostrik funcionar para você. Pule quando quiser.';

  @override
  String get walkthroughIntroBodyOne =>
      'O que faz o Rostrik funcionar para você. Pule quando quiser.';

  @override
  String get walkthroughPaintLabel => 'Pinte sua escala';

  @override
  String get walkthroughPaintDetail =>
      'Toque nos dias em que você trabalha. Rápido assim.';

  @override
  String get walkthroughShakeLabel => 'Chacoalhe para desligar';

  @override
  String get walkthroughShakeDetail =>
      'Uma chacoalhada firme desliga um alarme crítico.';

  @override
  String get walkthroughTryEach => 'Toque em Próximo para testar cada um.';

  @override
  String get walkthroughTryIt => 'Toque em Próximo para testar.';

  @override
  String get walkthroughPaintBody =>
      'Toque nos dias em que você trabalha. No editor de verdade, você adiciona mais blocos (tardes, noites) do mesmo jeito.';

  @override
  String get walkthroughPaintPrompt =>
      'Toque em um dia para pintar um turno diurno nele.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Boa! Esses $count dias viraram um bloco diurno. Os dias sem toque ficam de folga. Fácil assim.',
      one:
          'Boa! Esse dia virou um bloco diurno. Os dias sem toque ficam de folga. Fácil assim.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'Alarmes de turno crítico precisam de uma chacoalhada firme e contínua para desligar, assim um toque sonolento não basta. Experimente: chacoalhe o celular.';

  @override
  String get walkthroughShakeSuccess => 'Isso aí!';

  @override
  String get walkthroughShakeSuccessDetail =>
      'É exatamente assim que você vai silenciar um alarme crítico.';

  @override
  String get walkthroughDoneTitle => 'Tudo pronto';

  @override
  String get walkthroughDoneBody =>
      'Monte uma escala quando quiser em Gerenciar e reveja este tour em Configurações → Ajuda.';

  @override
  String get navDashboard => 'Início';

  @override
  String get navTimeline => 'Agenda';

  @override
  String get navManage => 'Gerenciar';

  @override
  String get navAlarms => 'Alarmes';

  @override
  String get navSleep => 'Sono';

  @override
  String get onbPatternTitle => 'Escolha seu revezamento';

  @override
  String get purchaseTrialEnded => 'Seu período grátis terminou';

  @override
  String get purchaseBody =>
      'Desbloqueie o Rostrik uma única vez para manter seus alarmes de turno tocando. Sua escala, alarmes e configurações estão seguros e voltam assim que você desbloquear.';

  @override
  String get purchaseAlarmsWontRing => 'Até lá, os alarmes não vão tocar.';

  @override
  String get purchaseUnlock => 'Desbloquear acesso total';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'Desbloquear acesso total · $price';
  }

  @override
  String get purchaseRestore => 'Restaurar compra';

  @override
  String get purchaseOneTime => 'Pagamento único. Sem assinatura.';

  @override
  String get purchaseUnavailable =>
      'As compras não estão disponíveis agora. Verifique sua conexão e tente de novo.';

  @override
  String get purchaseCheckingPrevious => 'Procurando uma compra anterior…';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsLegalAbout => 'JURÍDICO E SOBRE';

  @override
  String get settingsHelp => 'AJUDA';

  @override
  String get settingsHowItWorks => 'Como funciona';

  @override
  String get settingsReplayTourShake =>
      'Rever o tour rápido: pintar escala + chacoalhar para desligar';

  @override
  String get settingsReplayTour => 'Rever o tour rápido: pintar escala';

  @override
  String get settingsScreenTips => 'Mostrar dicas de tela';

  @override
  String get settingsScreenTipsSub =>
      'Dicas únicas em cada tela. Ative para vê-las de novo.';

  @override
  String get settingsFullAccess => 'ACESSO TOTAL';

  @override
  String get settingsFullAccessUnlocked => 'Acesso total desbloqueado';

  @override
  String get settingsThanks => 'Obrigado por apoiar o Rostrik.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Período grátis: faltam $days dias',
      one: 'Período grátis: falta 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'Período grátis encerrado';

  @override
  String get settingsUnlockPitch =>
      'Desbloqueie uma vez para manter seus alarmes de turno tocando quando o período grátis acabar. Pagamento único, nunca uma assinatura.';

  @override
  String get settingsRestore => 'Restaurar';

  @override
  String get settingsBrandTagline =>
      'Alarmes feitos para além do horário comercial';

  @override
  String get settingsLeadTime => 'Antecedência';

  @override
  String get settingsLeadTimeSub =>
      'O alarme toca com esta antecedência antes de cada turno.';

  @override
  String get settingsSnoozeDuration => 'Duração da soneca';

  @override
  String get settingsSnoozeDurationSub =>
      'Quanto o botão Soneca adia um alarme tocando.';

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
  String get settingsShiftCycles => 'CICLOS DE ESCALA';

  @override
  String get settingsShiftCyclesSub =>
      'Escalas que você gerou a partir de um padrão ou modelo.';

  @override
  String get settingsAddShiftCycle => 'Adicionar ciclo de escala';

  @override
  String get settingsNoRosters => 'Você ainda não gerou nenhuma escala.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get settingsDeleteRosterTitle => 'Excluir escala?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turnos',
      one: '1 turno',
    );
    return 'Excluir \"$label\"? Isso cancela os alarmes pendentes e remove $_temp0.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return '\"$label\" excluída';
  }

  @override
  String get commonActive => 'Ativa';

  @override
  String get commonUpcoming => 'Próxima';

  @override
  String get commonPast => 'Anterior';

  @override
  String get settingsWorkHistory => 'HISTÓRICO DE TRABALHO';

  @override
  String get settingsWorkHistorySub =>
      'Revise e exporte seus turnos personalizados concluídos para conferir o holerite.';

  @override
  String get settingsViewWorkHistory => 'Ver e exportar histórico';

  @override
  String get settingsPreferences => 'PREFERÊNCIAS';

  @override
  String get settingsPreferencesSub => 'Como sua agenda aparece no app.';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsThemeSub =>
      'O escuro é o padrão do Rostrik. O claro usa uma paleta creme e acolhedora.';

  @override
  String get settings24h => 'Usar formato 24 horas';

  @override
  String get settings24hOn => 'Horários aparecem como 14:30';

  @override
  String get settings24hOff => 'Horários aparecem como 02:30 PM';

  @override
  String get settingsWeekStartTitle => 'Começar o calendário na segunda';

  @override
  String get settingsWeekStartMon => 'Semanas começam na segunda';

  @override
  String get settingsWeekStartSun => 'Semanas começam no domingo';

  @override
  String get settingsTimelineOpensOn => 'A agenda abre em';

  @override
  String get commonList => 'Lista';

  @override
  String get commonMonth => 'Mês';

  @override
  String get settingsCalendar => 'CALENDÁRIO';

  @override
  String get settingsCalendarSync =>
      'Sincronizar com o Google / calendário do aparelho';

  @override
  String get settingsCalendarSyncSub =>
      'Copia automaticamente seus turnos para um calendário \"Rostrik Roster\" dedicado no seu celular.';

  @override
  String get settingsCalSyncOff =>
      'Sincronização desligada. Os próximos eventos do \"Rostrik Roster\" foram apagados.';

  @override
  String get settingsCalSyncMirroring =>
      'Copiando sua escala para o calendário \"Rostrik Roster\"…';

  @override
  String get settingsCalPermNeeded =>
      'É preciso permitir o acesso ao calendário para sincronizar sua escala.';

  @override
  String get settingsCalBlocked =>
      'O acesso ao calendário está bloqueado. Ative nas configurações do sistema para sincronizar.';

  @override
  String get settingsCalOpenSettings => 'Configurações';

  @override
  String get settingsCalUnsupported =>
      'A sincronização de calendário não está disponível neste aparelho.';

  @override
  String get settingsDangerZone => 'ZONA DE PERIGO';

  @override
  String get settingsDangerZoneSub =>
      'Apaga sua escala, alarmes e configurações e recomeça a configuração do zero.';

  @override
  String get settingsResetAppData => 'Redefinir dados do app';

  @override
  String get settingsResetTitle => 'Redefinir o app?';

  @override
  String get settingsResetBody =>
      'Tem certeza? Isso vai apagar sua escala, alarmes e configurações.';

  @override
  String get settingsResetConfirm => 'Redefinir';

  @override
  String get dashNoUpcomingShifts => 'Nenhum turno próximo';

  @override
  String get dashEnjoyTimeOff => 'Aproveite a folga.';

  @override
  String get dashInProgress => 'EM ANDAMENTO';

  @override
  String get dashRotation => 'Revezamento';

  @override
  String get dashAlarmsCantRing => 'Os alarmes não podem tocar com confiança';

  @override
  String get dashNotifsOffIssue =>
      'As notificações estão desligadas: um alarme tocando não consegue mostrar a tela de despertar nem ser desligado.';

  @override
  String get dashOpenSettings => 'Abrir configurações';

  @override
  String get dashExactBlockedIssue =>
      'Os alarmes exatos estão bloqueados: nenhum despertar pode ser agendado.';

  @override
  String get dashAlarmsWontTakeOverScreen => 'Os alarmes não vão ocupar a tela';

  @override
  String get dashFullScreenBlockedIssue =>
      'Os alarmes em tela cheia estão desativados: com o celular bloqueado você verá uma notificação em vez da tela do alarme.';

  @override
  String get dashAllow => 'Permitir';

  @override
  String get dashSlideToSkip => 'Deslize para pular este alarme';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deslize para pular os $count alarmes',
      one: 'Deslize para pular o alarme',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'Dispensar próximo alarme · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pular os $count alarmes deste turno',
      one: 'Pular o alarme deste turno',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'Manter alarme';

  @override
  String get dashMyRotation => 'Meu revezamento';

  @override
  String get dashCalendarUpcoming => 'Calendário e próximos turnos';

  @override
  String get dashNextShifts => 'Próximos turnos';

  @override
  String get dashOpenTimeline => 'Abrir agenda';

  @override
  String heroStartsIn(String countdown) {
    return 'Começa em $countdown';
  }

  @override
  String heroEndsIn(String countdown) {
    return 'Termina em $countdown';
  }

  @override
  String get heroStartsInPrefix => 'Começa em';

  @override
  String get heroEndsInPrefix => 'Termina em';

  @override
  String heroStartsTodayAt(String time) {
    return 'Começa hoje às $time';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'Começou hoje às $time';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'Começa amanhã às $time';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'Começou ontem às $time';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'Começa ontem às $time';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return 'Começa $date às $time';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return 'Começou $date às $time';
  }

  @override
  String get shiftTypeDayShift => 'Turno diurno';

  @override
  String get shiftTypeAfternoonShift => 'Turno da tarde';

  @override
  String get shiftTypeNightShift => 'Turno noturno';

  @override
  String heroDayXofY(int x, int y, String label) {
    return 'Dia $x de $y · $label';
  }

  @override
  String get heroOffTomorrow => 'Folga amanhã';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Folga em $days dias',
      one: 'Folga em 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'Volta amanhã';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Volta em $days dias',
      one: 'Volta em 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'Folga';

  @override
  String durationDayShort(int d) {
    return '$d d';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d d $h h';
  }

  @override
  String get alarmsTitle => 'Alarmes';

  @override
  String get alarmsAddTooltip => 'Adicionar alarme';

  @override
  String get alarmsSortTooltip => 'Ordenar alarmes';

  @override
  String get alarmsSortByTime => 'Por horário';

  @override
  String get alarmsSortByShiftType => 'Por tipo de turno';

  @override
  String get alarmsEmptyTitle => 'Nenhum alarme ainda.';

  @override
  String get alarmsEmptyBody => 'Toque em + para adicionar.';

  @override
  String get alarmsNextAlarm => 'PRÓXIMO ALARME';

  @override
  String get alarmsHolidayMode => 'Modo férias';

  @override
  String get alarmsHolidayModeSub => 'Alarmes pausados: nada vai tocar.';

  @override
  String get alarmsNoUpcoming => 'Nenhum alarme de turno próximo';

  @override
  String get alarmsNoUpcomingSub =>
      'Adicione um alarme que siga o revezamento ou gere uma escala.';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'para seu turno ($type) · $day';
  }

  @override
  String get commonToday => 'Hoje';

  @override
  String get commonTomorrow => 'Amanhã';

  @override
  String get alarmsOffWontRing => 'Desligado: não vai tocar';

  @override
  String get alarmsNoUpcomingRing => 'Nenhum toque agendado';

  @override
  String alarmsNextRing(String day, String time) {
    return 'Próximo toque: $day às $time';
  }

  @override
  String get alarmsSwipeToDelete => 'Deslize para excluir';

  @override
  String get alarmsRingsOnceAutoDelete => 'Toca uma vez · exclui sozinho';

  @override
  String get alarmsRingsOnce => 'Toca uma única vez';

  @override
  String get alarmsYourShift => 'seu turno';

  @override
  String alarmsShiftsOfType(String type) {
    return 'turnos ($type)';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'Horário exato · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$lead antes de $shift · padrão';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$lead antes de $shift';
  }

  @override
  String get createEditAlarm => 'Editar alarme';

  @override
  String get createNewAlarm => 'Novo alarme';

  @override
  String get createDefaultLabel => 'Despertar';

  @override
  String get createFallbackLabel => 'Alarme';

  @override
  String get createPickBecomesDefault =>
      'Sua escolha vira o padrão para novos alarmes.';

  @override
  String get createSelectFromFiles => 'Escolher dos Arquivos';

  @override
  String get createFilesSub => 'Escolha um arquivo de áudio salvo no aparelho';

  @override
  String get createSelectSystemTone => 'Escolher toque do sistema';

  @override
  String get createSystemToneSub =>
      'Escolha entre os sons de alarme do aparelho';

  @override
  String get createAlarmTiming => 'Momento do alarme';

  @override
  String get createLeadTimeMode => 'Antecedência';

  @override
  String get createExactTimeMode => 'Horário exato';

  @override
  String createFiresAt(String time) {
    return 'Toca às $time';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return '$lead antes do início do turno';
  }

  @override
  String get createLinkedShift => 'Turno vinculado';

  @override
  String get createRepeatOn => 'Repetir em';

  @override
  String get createLabelField => 'Nome';

  @override
  String get createLabelHint => 'ex.: Despertar';

  @override
  String get createCriticalShift => 'Turno crítico';

  @override
  String get createCriticalShiftSub =>
      'Chacoalhe para desligar · segurança de 3 segundos segurando';

  @override
  String get createRingtone => 'Toque';

  @override
  String get commonStop => 'Parar';

  @override
  String get commonPlay => 'Tocar';

  @override
  String get createVibrate => 'Vibrar';

  @override
  String get createRepeat => 'Repetir';

  @override
  String get createRepeatRotation => 'Revezamento';

  @override
  String get createRepeatWeekly => 'Semanal';

  @override
  String get createRepeatOneTime => 'Uma vez';

  @override
  String get createPickOneDay => 'Escolha pelo menos um dia';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonSaveChanges => 'Salvar alterações';

  @override
  String get createTimeBeforeShift => 'Tempo antes do turno';

  @override
  String get commonOk => 'OK';

  @override
  String get sleepTitle => 'Sono';

  @override
  String get sleepTargetHeader => 'META DE SONO';

  @override
  String get sleepTargetSub =>
      'Quantas horas você quer dormir. O Rostrik conta para trás a partir do seu próximo alarme para definir a hora de dormir hoje.';

  @override
  String get sleepRemindersHeader => 'LEMBRETES';

  @override
  String get sleepWindDownHeader => 'ANTECEDÊNCIA PARA DESACELERAR';

  @override
  String get sleepWindDownSub =>
      'Quanto tempo antes de dormir chega o aviso para desacelerar.';

  @override
  String get sleepSoundsHeader => 'SONS PARA DORMIR';

  @override
  String get sleepSoundsSub =>
      'Ruído branco e marrom para pegar no sono. Escolha um timer e toque em um som.';

  @override
  String get sleepNothingToPlan => 'Nada para planejar hoje';

  @override
  String get sleepNothingToPlanSub =>
      'Adicione um turno à sua escala e o Rostrik monta uma hora de dormir personalizada para o seu próximo despertar.';

  @override
  String get sleepTransitionDay => 'DIA DE TRANSIÇÃO';

  @override
  String get sleepTransitionTitle =>
      'Amanhã é turno noturno. Vale dormir até mais tarde.';

  @override
  String get sleepTransitionBody =>
      'É um dia de transição: você tem uma folga antes das noites, então não há alarme cedo. Descanse mais agora e deixe o corpo dormir mais tarde esta noite.';

  @override
  String get sleepRestRecovery => 'DESCANSO E RECUPERAÇÃO';

  @override
  String get sleepNoEarlyAlarm => 'Nenhum alarme cedo';

  @override
  String get sleepRestBody =>
      'Seu próximo turno é daqui a mais de um dia, então não há despertar para planejar hoje. Durma no seu ritmo e recupere as energias: o Rostrik monta seu plano quando chegar mais perto.';

  @override
  String get sleepTonightsPlan => 'PLANO DE HOJE';

  @override
  String get sleepTargetBedtime => 'Hora de dormir';

  @override
  String get sleepWindDownStat => 'Desacelerar';

  @override
  String get sleepWakeUpStat => 'Despertar';

  @override
  String get sleepDurationStat => 'Duração';

  @override
  String get sleepBedtimeReminder => 'Lembrete de dormir';

  @override
  String sleepNudgeAtBedtime(String time) {
    return 'Avise-me às $time para ir para a cama';
  }

  @override
  String get sleepBedtimeSub => 'Um aviso quando for hora de ir para a cama';

  @override
  String get sleepWindDownReminder => 'Lembrete para desacelerar';

  @override
  String sleepNudgeAtWindDown(String time) {
    return 'Avise-me às $time para começar a desacelerar';
  }

  @override
  String get sleepWindDownReminderSub =>
      'Um aviso antecipado para começar a desacelerar';

  @override
  String get commonOff => 'Desl.';

  @override
  String get sleepSoundWhiteNoise => 'Ruído branco';

  @override
  String get sleepSoundPinkNoise => 'Ruído rosa';

  @override
  String get sleepSoundBrownNoise => 'Ruído marrom';

  @override
  String get sleepSoundFan => 'Ventilador';

  @override
  String get sleepSoundOcean => 'Mar';

  @override
  String get sleepSoundRain => 'Chuva';

  @override
  String get manageTitle => 'Gerenciar';

  @override
  String get manageRosterTools => 'FERRAMENTAS DE ESCALA';

  @override
  String get manageRosterToolsSub =>
      'Monte e ajuste os turnos que controlam seus alarmes e seu plano de sono.';

  @override
  String get manageGenerateRotation => 'Gerar revezamento';

  @override
  String get manageGenerateRotationSub =>
      'Monte um padrão de turnos repetido a partir de um modelo.';

  @override
  String get manageAddCustomShift => 'Adicionar turno avulso';

  @override
  String get manageAddCustomShiftSub =>
      'Coloque um único turno avulso na sua escala.';

  @override
  String get manageMarkLeave => 'Marcar folga / afastamento';

  @override
  String get manageMarkLeaveSub =>
      'Pinte de uma vez os dias em que você não trabalha (férias, atestado).';

  @override
  String get managePauseSchedule => 'Pausar escala';

  @override
  String get managePausedSub =>
      'Modo férias LIGADO: alarmes silenciados, sua escala está segura.';

  @override
  String get manageNotPausedSub =>
      'Modo férias: silencie os alarmes enquanto estiver fora da escala.';

  @override
  String get markLeaveTitle => 'Marcar folga';

  @override
  String get markLeaveIntro =>
      'Toque nos dias em que você não trabalha, escolha um motivo e aplique. Os alarmes desses dias não vão tocar e sua escala continua intacta.';

  @override
  String get leaveAnnual => 'Férias';

  @override
  String get leaveSick => 'Atestado';

  @override
  String get leavePublicHoliday => 'Feriado';

  @override
  String get markLeaveReason => 'Motivo';

  @override
  String get markLeaveFallbackReason => 'folga';

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
  String get markLeaveSelectDays => 'Escolha os dias para marcar';

  @override
  String get markLeaveNoShifts => 'Nenhum turno nesses dias';

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
  String get workHistoryTitle => 'Histórico de trabalho';

  @override
  String get workHistoryExportTooltip => 'Exportar histórico';

  @override
  String workHistoryExportFailed(String error) {
    return 'Não foi possível exportar o histórico: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turnos trabalhados',
      one: '1 turno trabalhado',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours h';
  }

  @override
  String get commonPaused => 'Pausado';

  @override
  String workHistoryPausedReason(String reason) {
    return 'Pausado · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'Revezamento';

  @override
  String get workHistoryAdHocBadge => 'Avulso';

  @override
  String get workHistoryEmptyTitle => 'Nenhum turno concluído ainda';

  @override
  String get workHistoryEmptyBody =>
      'Seus turnos trabalhados, de revezamento ou avulsos, aparecem aqui quando terminam, prontos para exportar e conferir o holerite.';

  @override
  String get workHistoryShareSubject => 'Histórico de trabalho do Rostrik';

  @override
  String get workHistoryShareText =>
      'Meu histórico de trabalho exportado do Rostrik.';

  @override
  String get shiftEdAddShift => 'Adicionar turno';

  @override
  String get shiftEdEditShift => 'Editar turno';

  @override
  String get shiftEdDate => 'Data';

  @override
  String get shiftEdPickDate => 'Escolher data';

  @override
  String get shiftEdStarts => 'Começa';

  @override
  String get shiftEdEnds => 'Termina';

  @override
  String get shiftEdPickTime => 'Escolher horário';

  @override
  String get shiftEdEndsNextDay => 'Termina no dia seguinte';

  @override
  String get shiftEdPauseTitle => 'Pausar / cancelar este turno';

  @override
  String get shiftEdPausedSub =>
      'O alarme não vai tocar. Fica no seu calendário como registro.';

  @override
  String get shiftEdNotPausedSub =>
      'Marque uma folga (atestado, férias, feriado) sem excluir o turno.';

  @override
  String get shiftEdReasonOptional => 'Motivo (opcional)';

  @override
  String get dayShifts => 'Turnos';

  @override
  String get dayActivities => 'Atividades';

  @override
  String get dayAddAnotherShift => 'Adicionar outro turno';

  @override
  String get dayAddActivity => 'Adicionar atividade';

  @override
  String get dayAddActivitySub => 'Evento, tarefa ou aniversário';

  @override
  String get dayReminder => 'Lembrete';

  @override
  String get actEditActivity => 'Editar atividade';

  @override
  String get actLeadAtTime => 'Na hora';

  @override
  String get actLead10Min => '10 min antes';

  @override
  String get actLead30Min => '30 min antes';

  @override
  String get actLead1Hour => '1 hora antes';

  @override
  String get actLead1Day => '1 dia antes';

  @override
  String get actEvent => 'Evento';

  @override
  String get actTask => 'Tarefa';

  @override
  String get actBirthday => 'Aniversário';

  @override
  String get actTitleField => 'Título';

  @override
  String get actAllDay => 'Dia inteiro';

  @override
  String get actTimeField => 'Horário';

  @override
  String get actRemindMe => 'Lembrar-me';

  @override
  String get actRemindMeSub =>
      'Uma notificação leve, separada dos seus alarmes de turno.';

  @override
  String get actRemindAt => 'Lembrar às';

  @override
  String get actReminderPassed =>
      'Esse horário já passou: este lembrete não vai disparar.';

  @override
  String get actNoteOptional => 'Observação (opcional)';

  @override
  String get actCompleted => 'Concluída';

  @override
  String get tipDashboardTitle => 'Seu painel';

  @override
  String get tipDashboardBody =>
      'Sua base. Veja seu próximo turno com contagem regressiva ao vivo e em que ponto do revezamento você está. Toque em um bloco para ver os detalhes.';

  @override
  String get tipTimelineTitle => 'Sua escala completa';

  @override
  String get tipTimelineBody =>
      'Alterne entre Lista e calendário Mensal no topo. Toque em qualquer dia para editar um turno ou adicionar um evento, tarefa ou aniversário.';

  @override
  String get tipManageTitle => 'Montar e ajustar';

  @override
  String get tipManageBody =>
      'Crie uma escala de revezamento, adicione um turno avulso (hora extra) ou pause toda a escala nas férias, tudo por aqui.';

  @override
  String get tipAlarmsTitle => 'Seus alarmes';

  @override
  String get tipAlarmsBody =>
      'Todos os alarmes criados pelos seus turnos e os que você mesmo adicionar. Toque em um para mudar o horário ou o toque, ou transforme-o em um alarme de turno crítico que desliga chacoalhando.';

  @override
  String get tipSleepTitle => 'Plano de sono';

  @override
  String get tipSleepBody =>
      'Um plano para desacelerar que segue sua escala: defina uma meta de sono e chegue descansado ao próximo turno.';

  @override
  String get tipReplayHint =>
      'Reveja quando quiser em Configurações › Como funciona.';

  @override
  String get tipDontShow => 'Não mostrar dicas';

  @override
  String get tipGotIt => 'Entendi';

  @override
  String get timelineListView => 'Lista';

  @override
  String get timelineMonthView => 'Mês';

  @override
  String get shiftTypeAftShort => 'Tarde';

  @override
  String get timelineNoShifts =>
      'Nenhum turno agendado. Toque em + para adicionar.';

  @override
  String timelineNoMatch(String filter) {
    return 'Nenhum turno corresponde ao filtro $filter.';
  }

  @override
  String get timelineRestDay => 'Folga';

  @override
  String timelineRestDayReason(String reason) {
    return 'Folga · $reason';
  }

  @override
  String get timelineAllDay => 'Dia inteiro';

  @override
  String get calLegendPausedLeave => 'Pausado / Folga';

  @override
  String get calLegendActivity => 'Atividade';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterWork => 'Trabalho';

  @override
  String get criticalHoldToDismiss => 'Ou segure para desligar';

  @override
  String get patternChoosePattern => 'Escolha um padrão';

  @override
  String get patternRotatingSwings => 'Revezamentos mistos';

  @override
  String get patternDaySwings => 'Só turnos diurnos';

  @override
  String get patternNightSwings => 'Só turnos noturnos';

  @override
  String get patternShiftTimes => 'Horários dos turnos';

  @override
  String get patternGenerate => 'Definir Dia 1 e gerar';

  @override
  String get patternSelectDay1 => 'Escolha seu próximo Dia 1';

  @override
  String patternDay1Hint(String label) {
    return 'Primeiro dia do seu bloco ($label)';
  }

  @override
  String get patternNextDay1 => 'Próximo Dia 1';

  @override
  String get patternUseThisDate => 'Usar esta data';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turnos gerados',
      one: '1 turno gerado',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'Falha ao gerar: $error';
  }

  @override
  String get patternFirstBlockFallback => 'primeiro';

  @override
  String get patternBuildCustom => 'Montar escala personalizada';

  @override
  String get patternBuildCustomSub =>
      'Nenhum modelo serve? Monte seus próprios blocos.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dias',
      one: '1 dia',
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
      other: '$n noites',
      one: '1 noite',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '$n de folga';
  }

  @override
  String get builderNewRoster => 'Nova escala de turnos';

  @override
  String get builderEditRoster => 'Editar escala';

  @override
  String get builderNewSub => 'Configure seu padrão de revezamento';

  @override
  String get builderEditSub => 'Altere e substitua esta escala salva';

  @override
  String get builderNameHint =>
      'Nome da escala (ex.: Meu revezamento de 14 dias)';

  @override
  String get builderCycleLength => 'DURAÇÃO DO CICLO';

  @override
  String get builderStartDate => 'DATA DE INÍCIO';

  @override
  String get builderShiftBlocks => 'BLOCOS DE TURNO';

  @override
  String get builderAddShiftBlock => 'Adicionar bloco de turno';

  @override
  String get builderCreateRoster => 'Criar escala';

  @override
  String get builderSaveChanges => 'Salvar alterações';

  @override
  String get builderReplaceWarning =>
      'Salvar substitui esta escala. As marcações de folga pintadas nela serão redefinidas.';

  @override
  String get builderBackToOptions => 'Voltar às opções';

  @override
  String get builderOrImport => 'OU IMPORTE UMA ESCALA EXISTENTE';

  @override
  String get builderImportViaAi => 'Importar com IA';

  @override
  String get builderScanning => 'Digitalizando…';

  @override
  String get builderScanInstead => 'Digitalizar uma foto da escala';

  @override
  String get builderCustomChip => 'Outra';

  @override
  String get builderCycleLengthLabel => 'Duração do ciclo';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'Escolha uma data';

  @override
  String get builderNoBlocksYet => 'Nenhum bloco ainda';

  @override
  String get builderNoBlocksSub =>
      'Adicione blocos de turno para definir seu revezamento';

  @override
  String builderDaysLine(String ranges) {
    return 'Dias $ranges';
  }

  @override
  String get builderEditBlock => 'Editar bloco';

  @override
  String get builderRemoveBlock => 'Remover bloco';

  @override
  String get builderPickRosterStart => 'Escolha a data de início da escala';

  @override
  String get builderPickScanStart =>
      'Escolha a data de início da escala digitalizada';

  @override
  String get builderScanCamera => 'Digitalizar com a câmera';

  @override
  String get builderImportScreenshot => 'Importar uma captura de tela';

  @override
  String builderScanFailed(String error) {
    return 'Falha na digitalização: $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'Nenhum horário reconhecido. Tente recortar mais perto da tabela.';

  @override
  String get builderCustomRosterFallback => 'Escala personalizada';

  @override
  String get builderScannedRosterFallback => 'Escala digitalizada';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Escala atualizada: $count turnos agendados',
      one: 'Escala atualizada: 1 turno agendado',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Criada: $count turnos agendados',
      one: 'Criada: 1 turno agendado',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'Não foi possível criar a escala: $error';
  }

  @override
  String get builderRosterImported => 'Escala importada para o seu calendário';

  @override
  String builderCouldNotImport(String error) {
    return 'Não foi possível importar a escala: $error';
  }

  @override
  String get blockAddTitle => 'Adicionar bloco de turno';

  @override
  String get blockEditTitle => 'Editar bloco de turno';

  @override
  String get blockStart => 'Início';

  @override
  String get blockEnd => 'Fim';

  @override
  String get blockTapDays => 'Toque nos dias que este turno cobre';

  @override
  String get blockUntappedOff => 'Dias sem toque são folga.';

  @override
  String blockOverlap(String ranges) {
    return 'Este horário se sobrepõe a outro turno no dia $ranges. Altere o horário ou esses dias.';
  }

  @override
  String get blockAdd => 'Adicionar bloco';

  @override
  String get blockSave => 'Salvar bloco';

  @override
  String get aiPromptCopied =>
      'Prompt copiado! Cole no seu app de IA junto com a sua escala.';

  @override
  String get aiNothingToPaste =>
      'Não há nada para colar na área de transferência.';

  @override
  String get aiNoValidShifts =>
      'Nenhum turno válido detectado. Confira se usou o prompt de IA copiado.';

  @override
  String get aiStep1 => 'Copie o prompt';

  @override
  String get aiCopied => 'Copiado!';

  @override
  String get aiCopyPrompt => 'Copiar prompt de IA';

  @override
  String get aiStep1Sub =>
      'Cole no ChatGPT, Gemini ou qualquer app de IA, adicione o texto da sua escala ou uma foto/captura e envie.';

  @override
  String get aiStep2 => 'Cole a resposta da IA';

  @override
  String get aiPaste => 'Colar';

  @override
  String get aiParsePreview => 'Analisar e pré-visualizar';

  @override
  String get aiStep3 => 'Revise os turnos detectados';

  @override
  String get aiStep3Sub =>
      'Toque em uma etiqueta para alternar entre Dia, Tarde e Noite se a IA errou.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count dias',
      one: 'Importar 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'Transforme qualquer texto de escala em turnos com a ajuda de um app de IA.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0 · $working de trabalho · $off de folga';
  }

  @override
  String get draftReviewTitle => 'Revisar escala digitalizada';

  @override
  String draftRemovedDay(String date) {
    return '$date removido';
  }

  @override
  String get draftUndo => 'Desfazer';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias salvos na sua escala',
      one: '1 dia salvo na sua escala',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'Nome da escala';

  @override
  String get draftScannedImage => 'Imagem digitalizada';

  @override
  String get draftScannedImageSub => 'Toque na imagem para ampliar e comparar';

  @override
  String get draftImageError =>
      'Não foi possível exibir a imagem digitalizada.';

  @override
  String get draftRemove => 'Remover';

  @override
  String get draftNoEndTime =>
      'Digitalizado sem horário de término: defina-o para poder salvar.';

  @override
  String get draftTime => 'Horário';

  @override
  String get draftSetEnd => 'Definir fim';

  @override
  String get draftConfirmSave => 'Confirmar e salvar';

  @override
  String notifBeforeYourShift(String type) {
    return 'Antes do seu turno ($type)';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind às $time';
  }

  @override
  String get notifWindDownTitle => 'Hora de desacelerar 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'Largue as telas: sua hora de dormir é $time.';
  }

  @override
  String get notifWindDownBody =>
      'Largue as telas e comece a desacelerar para a noite.';

  @override
  String get notifBedtimeTitle => 'Hora de dormir 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return 'Vá para a cama para dormir ~$hours h antes do seu $shift. Despertar às $time.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return 'Vá para a cama para bater sua meta de $hours h de sono.';
  }

  @override
  String get notifShiftDay => 'turno diurno';

  @override
  String get notifShiftAfternoon => 'turno da tarde';

  @override
  String get notifShiftNight => 'turno noturno';

  @override
  String get notifShiftGeneric => 'turno';

  @override
  String get notifTrialEndsTitle =>
      'Seu período grátis do Rostrik termina amanhã';

  @override
  String get notifTrialEndsBody =>
      'Desbloqueie o acesso total para manter seus alarmes de turno tocando.';

  @override
  String seedWakeUpLabel(String type) {
    return 'Despertar ($type)';
  }

  @override
  String get seedShiftGeneric => 'Turno';

  @override
  String commonListAnd(String items, String last) {
    return '$items e $last';
  }

  @override
  String get soundClassic => 'Clássico';

  @override
  String get soundSiren => 'Sirene';

  @override
  String get soundDigital => 'Digital';

  @override
  String get soundChime => 'Sininho';

  @override
  String get patternFirstResponder => 'Padrão de emergência';

  @override
  String get ocrCropTitle => 'Recorte SÓ a sua linha, não a equipe toda';

  @override
  String get draftNameHint => 'ex.: Escala de maio';
}
