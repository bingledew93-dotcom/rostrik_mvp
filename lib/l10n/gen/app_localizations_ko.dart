// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => '시작하기 전에';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik은 매 근무마다 제때 깨워 드리도록 만들어졌어요. 솔직히 말씀드리면, 어떤 휴대폰이든 최종 결정권은 앱이 아니라 운영체제에 있어요. 드물게 운영체제가 어떤 알람 앱이든 지연시키거나 소리를 끌 수 있어요(강력한 배터리 절약, 강제 종료, 시스템 업데이트 직후 등).';

  @override
  String get legalBodyBackupAdvice =>
      '절대 놓치면 안 되는 근무에는 예비 알람을 하나 더 맞춰 두세요. 휴대폰 기본 알람을 포함해 어떤 알람에도 좋은 습관이에요.';

  @override
  String get legalReviewAndAccept => '확인 후 동의해 주세요:';

  @override
  String get legalPrivacyPolicy => '개인정보 처리방침';

  @override
  String get legalTermsOfUse => '이용약관';

  @override
  String get legalConsentCheckbox =>
      '운영체제가 모든 알람 앱에 영향을 줄 수 있음을 이해했으며, 개인정보 처리방침과 이용약관에 동의합니다.';

  @override
  String get legalAgreeContinue => '동의하고 계속';

  @override
  String get commonSaving => '저장 중…';

  @override
  String get commonCouldNotOpenLink => '링크를 열 수 없어요.';

  @override
  String get welcomeTagline => '교대 근무자를 위한 스마트 알람.';

  @override
  String get welcomeSubTagline => '평일만이 아니라 교대 근무표를 따라 울리는 알람.';

  @override
  String welcomeTrialTitle(int days) {
    return '$days일 무료 체험';
  }

  @override
  String get welcomeTrialBody =>
      '카드 없이 모든 기능을 사용해 보세요. 이후엔 한 번만 구매하면 되고, 구독은 없어요.';

  @override
  String get welcomeGetStarted => '시작하기';

  @override
  String get welcomeSkip => '건너뛰기 / 나중에 설정';

  @override
  String get welcomeTimeFormat => '시간 형식';

  @override
  String get welcomeWeekStarts => '주 시작일';

  @override
  String get common12h => '12시간';

  @override
  String get common24h => '24시간';

  @override
  String get commonSundayShort => '일';

  @override
  String get commonMondayShort => '월';

  @override
  String get rosterTypeTitle => '근무표 유형 선택';

  @override
  String get rosterTypeQuestion => '근무 형태가 어떻게 되나요?';

  @override
  String get rosterTypeDay => '주간 근무';

  @override
  String get rosterTypeNight => '야간 근무';

  @override
  String get rosterTypeRotating => '교대 근무';

  @override
  String get rosterTypeCustom => '직접 설정';

  @override
  String get commonContinue => '계속';

  @override
  String get commonComingSoon => '곧 출시';

  @override
  String get permsTitle => '권한';

  @override
  String get permsIntro =>
      '알람이 확실히 울리려면 Rostrik에 몇 가지 권한이 필요해요. 나중에 시스템 설정에서 바꿀 수 있어요.';

  @override
  String get permsNotifications => '알림';

  @override
  String get permsNotificationsSub => '기상 화면을 표시하는 데 필요해요.';

  @override
  String get permsExactAlarms => '정확한 알람';

  @override
  String get permsExactAlarmsSub => '정해진 시각에 정확히 알람이 울리게 해요.';

  @override
  String get permsBatteryUnrestricted => '배터리 제한 없음';

  @override
  String get permsBatteryGrantedSub => '알람이 배터리 최적화의 영향을 받지 않아요.';

  @override
  String get permsBatteryDeniedSub => '일부 휴대폰은 백그라운드 앱을 종료해요. 탭해서 해결하세요.';

  @override
  String get permsUnrestrictedBadge => '제한 없음';

  @override
  String get batteryDialogTitle => '알람이 꺼지지 않게 하기';

  @override
  String get batteryDialogIntro =>
      '일부 휴대폰(Samsung, Xiaomi, Oppo, Huawei)은 배터리를 아끼려고 백그라운드 앱을 적극적으로 종료해요. Rostrik이 종료되면 알람이 울리지 않을 수 있어요.';

  @override
  String get batteryDialogMarkUnrestricted =>
      '이를 막으려면 Rostrik을 \'제한 없음\'으로 설정하세요:';

  @override
  String get batteryStep1 => '이 앱의 설정을 여세요(아래 버튼).';

  @override
  String get batteryStep2 => '배터리(또는 \"앱 배터리 사용량\")를 탭하세요.';

  @override
  String get batteryStep3 => '\"최적화됨\"이나 \"제한됨\"이 아닌 \"제한 없음\"을 선택하세요.';

  @override
  String get batteryStep4 => '\"백그라운드 활동 허용\"이 보이면 그것도 켜세요.';

  @override
  String get batteryStep5 =>
      '\"사용하지 않는 앱 활동 일시중지\"(또는 \"앱을 사용하지 않으면 권한 삭제\")를 꺼서, 앱을 쓰지 않는 동안 Android가 알람 권한을 회수하지 않게 하세요.';

  @override
  String get commonNotNow => '나중에';

  @override
  String get batteryGoToSettings => '설정으로 이동';

  @override
  String get armEngineTitle => '알람 켜기';

  @override
  String get armEngineRosterReady => '근무표가 준비됐어요';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · $date 시작';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return '해당하는 근무 전마다 기상 알람($summary)을 켜 드릴게요.';
  }

  @override
  String get armEngineArming => '켜는 중…';

  @override
  String get armEngineCta => '알람 자동화하기';

  @override
  String get armEngineLeadTimeLabel => '알람 미리 울림';

  @override
  String get armEngineLeadTimeHelper => '근무 시작 얼마 전에 알람이 울릴지 정해요.';

  @override
  String get shiftTypeDay => '주간';

  @override
  String get shiftTypeAfternoon => '오후';

  @override
  String get shiftTypeNight => '야간';

  @override
  String get shiftTypeOff => '휴무';

  @override
  String get weekdaysNone => '요일 없음';

  @override
  String get weekdaysEveryDay => '매일';

  @override
  String get weekdaysWeekdays => '평일';

  @override
  String get weekdaysWeekends => '주말';

  @override
  String durationMin(int m) {
    return '$m분';
  }

  @override
  String durationH(int h) {
    return '$h시간';
  }

  @override
  String durationHMin(int h, int m) {
    return '$h시간 $m분';
  }

  @override
  String durationMinShort(int m) {
    return '$m분';
  }

  @override
  String durationHShort(int h) {
    return '$h시간';
  }

  @override
  String durationHMinShort(int h, int m) {
    return '$h시간 $m분';
  }

  @override
  String get commonClose => '닫기';

  @override
  String get commonSkip => '건너뛰기';

  @override
  String get commonBack => '뒤로';

  @override
  String get commonDone => '완료';

  @override
  String get commonNext => '다음';

  @override
  String get walkthroughIntroTitle => '60초 둘러보기';

  @override
  String get walkthroughIntroBodyTwo => 'Rostrik의 핵심 두 가지예요. 언제든 건너뛸 수 있어요.';

  @override
  String get walkthroughIntroBodyOne => 'Rostrik의 핵심 기능이에요. 언제든 건너뛸 수 있어요.';

  @override
  String get walkthroughPaintLabel => '근무표 칠하기';

  @override
  String get walkthroughPaintDetail => '근무하는 날만 탭하면 끝.';

  @override
  String get walkthroughShakeLabel => '흔들어서 끄기';

  @override
  String get walkthroughShakeDetail => '세게 흔들면 중요 알람이 꺼져요.';

  @override
  String get walkthroughTryEach => '다음을 탭해 하나씩 해 보세요.';

  @override
  String get walkthroughTryIt => '다음을 탭해 해 보세요.';

  @override
  String get walkthroughPaintBody =>
      '근무하는 날을 탭하세요. 실제 편집기에서도 오후·야간 블록을 같은 방식으로 추가할 수 있어요.';

  @override
  String get walkthroughPaintPrompt => '날짜를 탭해 주간 근무를 칠해 보세요.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '좋아요! $count일이 주간 블록이 됐어요. 탭하지 않은 날은 휴무로 남아요. 정말 쉽죠.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      '중요 근무 알람은 세게, 계속 흔들어야 꺼져요. 잠결에 톡 건드려서는 안 꺼지죠. 휴대폰을 흔들어 보세요.';

  @override
  String get walkthroughShakeSuccess => '성공했어요!';

  @override
  String get walkthroughShakeSuccessDetail => '중요 알람은 바로 이렇게 끄면 돼요.';

  @override
  String get walkthroughDoneTitle => '준비 완료';

  @override
  String get walkthroughDoneBody =>
      '근무표는 언제든 관리 탭에서 만들 수 있고, 이 안내는 설정 → 도움말에서 다시 볼 수 있어요.';

  @override
  String get navDashboard => '홈';

  @override
  String get navTimeline => '일정';

  @override
  String get navManage => '관리';

  @override
  String get navAlarms => '알람';

  @override
  String get navSleep => '수면';

  @override
  String get onbPatternTitle => '교대 패턴 선택';

  @override
  String get purchaseTrialEnded => '무료 체험이 끝났어요';

  @override
  String get purchaseBody =>
      'Rostrik을 한 번만 구매하면 근무 알람이 계속 울려요. 근무표, 알람, 설정은 모두 안전하게 보관돼 있고 구매하는 즉시 다시 작동해요.';

  @override
  String get purchaseAlarmsWontRing => '그전까지는 알람이 울리지 않아요.';

  @override
  String get purchaseUnlock => '전체 기능 잠금 해제';

  @override
  String purchaseUnlockWithPrice(String price) {
    return '전체 기능 잠금 해제 · $price';
  }

  @override
  String get purchaseRestore => '구매 복원';

  @override
  String get purchaseOneTime => '1회 구매. 구독 없음.';

  @override
  String get purchaseUnavailable => '지금은 구매할 수 없어요. 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get purchaseCheckingPrevious => '이전 구매를 확인하는 중…';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLegalAbout => '법적 고지 및 정보';

  @override
  String get settingsHelp => '도움말';

  @override
  String get settingsHowItWorks => '사용 방법';

  @override
  String get settingsReplayTourShake => '둘러보기 다시 보기: 근무표 칠하기 + 흔들어서 끄기';

  @override
  String get settingsReplayTour => '둘러보기 다시 보기: 근무표 칠하기';

  @override
  String get settingsScreenTips => '화면 도움말 표시';

  @override
  String get settingsScreenTipsSub => '화면마다 한 번씩 보이는 도움말이에요. 켜면 다시 볼 수 있어요.';

  @override
  String get settingsFullAccess => '전체 기능';

  @override
  String get settingsFullAccessUnlocked => '전체 기능 잠금 해제됨';

  @override
  String get settingsThanks => 'Rostrik을 응원해 주셔서 감사해요.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '무료 체험 $days일 남음',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => '무료 체험 종료';

  @override
  String get settingsUnlockPitch =>
      '한 번만 구매하면 체험이 끝나도 근무 알람이 계속 울려요. 1회 구매이며 구독이 아니에요.';

  @override
  String get settingsRestore => '복원';

  @override
  String get settingsBrandTagline => '9 to 5 밖에서 일하는 사람을 위한 알람';

  @override
  String get settingsLeadTime => '미리 울림';

  @override
  String get settingsLeadTimeSub => '각 근무 시작 이만큼 전에 알람이 울려요.';

  @override
  String get settingsSnoozeDuration => '다시 알림 간격';

  @override
  String get settingsSnoozeDurationSub => '다시 알림 버튼이 울리는 알람을 얼마나 미룰지 정해요.';

  @override
  String get settingsMinutesLabel => '분';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(m, locale: localeName, other: '$m분');
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => '근무 주기';

  @override
  String get settingsShiftCyclesSub => '패턴이나 템플릿으로 만든 근무표예요.';

  @override
  String get settingsAddShiftCycle => '근무 주기 추가';

  @override
  String get settingsNoRosters => '아직 만든 근무표가 없어요.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => '편집';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonCancel => '취소';

  @override
  String get settingsDeleteRosterTitle => '근무표를 삭제할까요?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count건',
    );
    return '\"$label\"을(를) 삭제할까요? 예정된 알람이 취소되고 근무 $_temp0이 삭제돼요.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return '\"$label\" 삭제됨';
  }

  @override
  String get commonActive => '사용 중';

  @override
  String get commonUpcoming => '예정';

  @override
  String get commonPast => '지난';

  @override
  String get settingsWorkHistory => '근무 기록';

  @override
  String get settingsWorkHistorySub => '완료한 추가 근무를 확인하고 내보내 급여명세서와 대조해 보세요.';

  @override
  String get settingsViewWorkHistory => '근무 기록 보기 및 내보내기';

  @override
  String get settingsPreferences => '환경설정';

  @override
  String get settingsPreferencesSub => '앱에서 일정이 표시되는 방식이에요.';

  @override
  String get settingsAppearance => '화면 모드';

  @override
  String get settingsThemeSystem => '시스템';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsThemeSub => 'Rostrik의 기본은 다크 모드예요. 라이트 모드는 따뜻한 크림색이에요.';

  @override
  String get settings24h => '24시간 형식 사용';

  @override
  String get settings24hOn => '시간이 14:30처럼 표시돼요';

  @override
  String get settings24hOff => '시간이 02:30 PM처럼 표시돼요';

  @override
  String get settingsWeekStartTitle => '달력을 월요일부터 시작';

  @override
  String get settingsWeekStartMon => '한 주가 월요일에 시작돼요';

  @override
  String get settingsWeekStartSun => '한 주가 일요일에 시작돼요';

  @override
  String get settingsTimelineOpensOn => '일정 기본 보기';

  @override
  String get commonList => '목록';

  @override
  String get commonMonth => '월';

  @override
  String get settingsCalendar => '캘린더';

  @override
  String get settingsCalendarSync => 'Google / 기기 캘린더와 동기화';

  @override
  String get settingsCalendarSyncSub =>
      '근무를 휴대폰의 전용 캘린더 \"Rostrik Roster\"에 자동으로 옮겨요.';

  @override
  String get settingsCalSyncOff =>
      '캘린더 동기화를 껐어요. 예정된 \"Rostrik Roster\" 일정이 삭제됐어요.';

  @override
  String get settingsCalSyncMirroring => '근무표를 \"Rostrik Roster\" 캘린더에 옮기는 중…';

  @override
  String get settingsCalPermNeeded => '근무표를 동기화하려면 캘린더 권한이 필요해요.';

  @override
  String get settingsCalBlocked => '캘린더 접근이 차단돼 있어요. 시스템 설정에서 허용해 주세요.';

  @override
  String get settingsCalOpenSettings => '설정';

  @override
  String get settingsCalUnsupported => '이 기기에서는 캘린더 동기화를 사용할 수 없어요.';

  @override
  String get settingsDangerZone => '위험 구역';

  @override
  String get settingsDangerZoneSub => '근무표, 알람, 설정을 삭제하고 처음부터 다시 설정해요.';

  @override
  String get settingsResetAppData => '앱 데이터 초기화';

  @override
  String get settingsResetTitle => '앱을 초기화할까요?';

  @override
  String get settingsResetBody => '정말 초기화할까요? 근무표, 알람, 설정이 삭제돼요.';

  @override
  String get settingsResetConfirm => '초기화';

  @override
  String get dashNoUpcomingShifts => '예정된 근무가 없어요';

  @override
  String get dashEnjoyTimeOff => '편히 쉬세요.';

  @override
  String get dashInProgress => '근무 중';

  @override
  String get dashRotation => '교대 순서';

  @override
  String get dashAlarmsCantRing => '알람이 제대로 울릴 수 없어요';

  @override
  String get dashNotifsOffIssue =>
      '알림이 꺼져 있어요. 알람이 울려도 기상 화면이 표시되지 않고 끌 수도 없어요.';

  @override
  String get dashOpenSettings => '설정 열기';

  @override
  String get dashExactBlockedIssue => '정확한 알람이 차단돼 있어요. 기상 알람을 예약할 수 없어요.';

  @override
  String get dashAllow => '허용';

  @override
  String get dashSlideToSkip => '밀어서 이 알람 건너뛰기';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '밀어서 알람 $count개 모두 건너뛰기',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return '다음 알람 끄기 · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이 근무의 알람 $count개 모두 건너뛰기',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => '알람 유지';

  @override
  String get dashMyRotation => '내 교대 순서';

  @override
  String get dashCalendarUpcoming => '달력 및 예정 근무';

  @override
  String get dashNextShifts => '다음 근무';

  @override
  String get dashOpenTimeline => '일정 열기';

  @override
  String heroStartsIn(String countdown) {
    return '$countdown 후 시작';
  }

  @override
  String heroEndsIn(String countdown) {
    return '$countdown 후 종료';
  }

  @override
  String get heroStartsInPrefix => '시작까지';

  @override
  String get heroEndsInPrefix => '종료까지';

  @override
  String heroStartsTodayAt(String time) {
    return '오늘 $time 시작';
  }

  @override
  String heroStartedTodayAt(String time) {
    return '오늘 $time에 시작함';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return '내일 $time 시작';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return '어제 $time에 시작함';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return '어제 $time 시작';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return '$date $time 시작';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return '$date $time에 시작함';
  }

  @override
  String get shiftTypeDayShift => '주간 근무';

  @override
  String get shiftTypeAfternoonShift => '오후 근무';

  @override
  String get shiftTypeNightShift => '야간 근무';

  @override
  String heroDayXofY(int x, int y, String label) {
    return '$y일 중 $x일째 – $label';
  }

  @override
  String get heroOffTomorrow => '내일 휴무';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일 후 휴무',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => '내일 복귀';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일 후 복귀',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => '휴무';

  @override
  String durationDayShort(int d) {
    return '$d일';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d일 $h시간';
  }

  @override
  String get alarmsTitle => '알람';

  @override
  String get alarmsAddTooltip => '알람 추가';

  @override
  String get alarmsSortTooltip => '알람 정렬';

  @override
  String get alarmsSortByTime => '시간순';

  @override
  String get alarmsSortByShiftType => '근무 유형순';

  @override
  String get alarmsEmptyTitle => '아직 알람이 없어요.';

  @override
  String get alarmsEmptyBody => '+를 탭해 추가하세요.';

  @override
  String get alarmsNextAlarm => '다음 알람';

  @override
  String get alarmsHolidayMode => '휴가 모드';

  @override
  String get alarmsHolidayModeSub => '알람이 일시중지됐어요. 아무것도 울리지 않아요.';

  @override
  String get alarmsNoUpcoming => '예정된 근무 알람이 없어요';

  @override
  String get alarmsNoUpcomingSub => '교대 순서를 따르는 알람을 추가하거나 근무표를 만드세요.';

  @override
  String alarmsForYourShift(String type, String day) {
    return '$type 근무용 · $day';
  }

  @override
  String get commonToday => '오늘';

  @override
  String get commonTomorrow => '내일';

  @override
  String get alarmsOffWontRing => '꺼짐: 울리지 않아요';

  @override
  String get alarmsNoUpcomingRing => '예약된 알람 없음';

  @override
  String alarmsNextRing(String day, String time) {
    return '다음 울림: $day $time';
  }

  @override
  String get alarmsSwipeToDelete => '밀어서 삭제';

  @override
  String get alarmsRingsOnceAutoDelete => '한 번 울림 · 자동 삭제';

  @override
  String get alarmsRingsOnce => '한 번만 울림';

  @override
  String get alarmsYourShift => '내 근무';

  @override
  String alarmsShiftsOfType(String type) {
    return '$type 근무';
  }

  @override
  String alarmsExactTime(String shift) {
    return '정해진 시각 · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$shift $lead 전 · 기본값';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$shift $lead 전';
  }

  @override
  String get createEditAlarm => '알람 편집';

  @override
  String get createNewAlarm => '새 알람';

  @override
  String get createDefaultLabel => '기상';

  @override
  String get createFallbackLabel => '알람';

  @override
  String get createPickBecomesDefault => '선택한 소리가 새 알람의 기본값이 돼요.';

  @override
  String get createSelectFromFiles => '파일에서 선택';

  @override
  String get createFilesSub => '기기에 저장된 오디오 파일을 골라요';

  @override
  String get createSelectSystemTone => '시스템 소리 선택';

  @override
  String get createSystemToneSub => '기기의 알람 소리 중에서 골라요';

  @override
  String get createAlarmTiming => '알람 시점';

  @override
  String get createLeadTimeMode => '미리 울림';

  @override
  String get createExactTimeMode => '정해진 시각';

  @override
  String createFiresAt(String time) {
    return '$time에 울림';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return '근무 시작 $lead 전';
  }

  @override
  String get createLinkedShift => '연결된 근무';

  @override
  String get createRepeatOn => '반복 요일';

  @override
  String get createLabelField => '이름';

  @override
  String get createLabelHint => '예: 기상';

  @override
  String get createCriticalShift => '중요 근무';

  @override
  String get createCriticalShiftSub => '흔들어서 끄기 · 3초 길게 눌러 비상 해제';

  @override
  String get createRingtone => '알람음';

  @override
  String get commonStop => '정지';

  @override
  String get commonPlay => '재생';

  @override
  String get createVibrate => '진동';

  @override
  String get createRepeat => '반복';

  @override
  String get createRepeatRotation => '교대';

  @override
  String get createRepeatWeekly => '매주';

  @override
  String get createRepeatOneTime => '한 번';

  @override
  String get createPickOneDay => '요일을 하나 이상 선택하세요';

  @override
  String get commonSave => '저장';

  @override
  String get commonSaveChanges => '변경사항 저장';

  @override
  String get createTimeBeforeShift => '근무 전 시간';

  @override
  String get commonOk => '확인';

  @override
  String get sleepTitle => '수면';

  @override
  String get sleepTargetHeader => '수면 목표';

  @override
  String get sleepTargetSub =>
      '몇 시간 자고 싶은지 정하세요. Rostrik이 다음 알람에서 거꾸로 계산해 오늘 밤 취침 시각을 정해요.';

  @override
  String get sleepRemindersHeader => '리마인더';

  @override
  String get sleepWindDownHeader => '휴식 준비 시간';

  @override
  String get sleepWindDownSub => '취침 시각 얼마 전에 휴식 준비 알림을 보낼지 정해요.';

  @override
  String get sleepSoundsHeader => '수면 사운드';

  @override
  String get sleepSoundsSub =>
      '잠들기 좋은 화이트 노이즈와 브라운 노이즈. 자동 종료 시간을 고르고 소리를 탭하세요.';

  @override
  String get sleepNothingToPlan => '오늘 밤은 계획할 게 없어요';

  @override
  String get sleepNothingToPlanSub =>
      '근무표에 근무를 추가하면 Rostrik이 다음 기상 시각에 맞춰 취침 시각을 짜 드려요.';

  @override
  String get sleepTransitionDay => '전환일';

  @override
  String get sleepTransitionTitle => '내일은 야간 근무예요. 늦잠을 자도 괜찮아요.';

  @override
  String get sleepTransitionBody =>
      '오늘은 전환일이에요. 야간 근무 전에 휴무가 있어서 이른 알람이 없어요. 지금 충분히 쉬고 오늘 밤은 늦게 자도 돼요.';

  @override
  String get sleepRestRecovery => '휴식과 회복';

  @override
  String get sleepNoEarlyAlarm => '이른 알람 없음';

  @override
  String get sleepRestBody =>
      '다음 근무까지 하루 넘게 남아서 오늘 밤 계획할 기상 시각이 없어요. 원하는 리듬으로 자며 회복하세요. 근무가 가까워지면 Rostrik이 취침 계획을 세워 드려요.';

  @override
  String get sleepTonightsPlan => '오늘 밤 계획';

  @override
  String get sleepTargetBedtime => '목표 취침 시각';

  @override
  String get sleepWindDownStat => '휴식 준비';

  @override
  String get sleepWakeUpStat => '기상';

  @override
  String get sleepDurationStat => '수면 시간';

  @override
  String get sleepBedtimeReminder => '취침 리마인더';

  @override
  String sleepNudgeAtBedtime(String time) {
    return '$time에 잘 시간이라고 알려 주기';
  }

  @override
  String get sleepBedtimeSub => '잘 시간이 되면 알려 드려요';

  @override
  String get sleepWindDownReminder => '휴식 준비 리마인더';

  @override
  String sleepNudgeAtWindDown(String time) {
    return '$time에 휴식 준비를 알려 주기';
  }

  @override
  String get sleepWindDownReminderSub => '조금 일찍 휴식 준비를 알려 드려요';

  @override
  String get commonOff => '끄기';

  @override
  String get sleepSoundWhiteNoise => '화이트 노이즈';

  @override
  String get sleepSoundPinkNoise => '핑크 노이즈';

  @override
  String get sleepSoundBrownNoise => '브라운 노이즈';

  @override
  String get sleepSoundFan => '선풍기';

  @override
  String get sleepSoundOcean => '바다';

  @override
  String get sleepSoundRain => '빗소리';

  @override
  String get manageTitle => '관리';

  @override
  String get manageRosterTools => '근무표 도구';

  @override
  String get manageRosterToolsSub => '알람과 수면 계획의 기준이 되는 근무를 만들고 조정하세요.';

  @override
  String get manageGenerateRotation => '교대 패턴 만들기';

  @override
  String get manageGenerateRotationSub => '템플릿으로 반복되는 근무 패턴을 만들어요.';

  @override
  String get manageAddCustomShift => '단발 근무 추가';

  @override
  String get manageAddCustomShiftSub => '근무표에 한 번만 있는 근무를 추가해요.';

  @override
  String get manageMarkLeave => '휴가 / 휴무 표시';

  @override
  String get manageMarkLeaveSub => '쉬는 날(연차, 병가)을 한 번에 칠해요.';

  @override
  String get managePauseSchedule => '일정 일시중지';

  @override
  String get managePausedSub => '휴가 모드 켜짐: 알람은 꺼지고 근무표는 그대로 보관돼요.';

  @override
  String get manageNotPausedSub => '휴가 모드: 근무가 없는 동안 알람을 꺼요.';

  @override
  String get markLeaveTitle => '휴가 표시';

  @override
  String get markLeaveIntro =>
      '쉬는 날을 탭하고 사유를 고른 뒤 적용하세요. 해당 날짜의 알람은 울리지 않고 근무표는 그대로 남아요.';

  @override
  String get leaveAnnual => '연차';

  @override
  String get leaveSick => '병가';

  @override
  String get leavePublicHoliday => '공휴일';

  @override
  String get markLeaveReason => '사유';

  @override
  String get markLeaveFallbackReason => '휴가';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '근무 $count건을 $reason(으)로 표시했어요.',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => '표시할 날짜를 선택하세요';

  @override
  String get markLeaveNoShifts => '해당 날짜에 근무가 없어요';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '근무 $count건에 적용',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => '근무 기록';

  @override
  String get workHistoryExportTooltip => '기록 내보내기';

  @override
  String workHistoryExportFailed(String error) {
    return '기록을 내보낼 수 없어요: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '근무 $count건 완료',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours시간';
  }

  @override
  String get commonPaused => '일시중지됨';

  @override
  String workHistoryPausedReason(String reason) {
    return '일시중지됨 · $reason';
  }

  @override
  String get workHistoryRotationBadge => '교대';

  @override
  String get workHistoryAdHocBadge => '추가';

  @override
  String get workHistoryEmptyTitle => '아직 완료한 근무가 없어요';

  @override
  String get workHistoryEmptyBody =>
      '교대 근무든 직접 추가한 근무든, 끝난 근무는 여기에 표시되고 급여명세서 확인용으로 내보낼 수 있어요.';

  @override
  String get workHistoryShareSubject => 'Rostrik 근무 기록';

  @override
  String get workHistoryShareText => 'Rostrik에서 내보낸 내 근무 기록이에요.';

  @override
  String get shiftEdAddShift => '근무 추가';

  @override
  String get shiftEdEditShift => '근무 편집';

  @override
  String get shiftEdDate => '날짜';

  @override
  String get shiftEdPickDate => '날짜 선택';

  @override
  String get shiftEdStarts => '시작';

  @override
  String get shiftEdEnds => '종료';

  @override
  String get shiftEdPickTime => '시간 선택';

  @override
  String get shiftEdEndsNextDay => '다음 날 종료';

  @override
  String get shiftEdPauseTitle => '이 근무 일시중지 / 취소';

  @override
  String get shiftEdPausedSub => '알람이 울리지 않아요. 기록으로 달력에 남아요.';

  @override
  String get shiftEdNotPausedSub => '삭제하지 않고 쉬는 날(병가, 휴가, 공휴일)로 표시해요.';

  @override
  String get shiftEdReasonOptional => '사유(선택)';

  @override
  String get dayShifts => '근무';

  @override
  String get dayActivities => '일정';

  @override
  String get dayAddAnotherShift => '근무 하나 더 추가';

  @override
  String get dayAddActivity => '일정 추가';

  @override
  String get dayAddActivitySub => '이벤트, 할 일, 생일';

  @override
  String get dayReminder => '리마인더';

  @override
  String get actEditActivity => '일정 편집';

  @override
  String get actLeadAtTime => '정각';

  @override
  String get actLead10Min => '10분 전';

  @override
  String get actLead30Min => '30분 전';

  @override
  String get actLead1Hour => '1시간 전';

  @override
  String get actLead1Day => '1일 전';

  @override
  String get actEvent => '이벤트';

  @override
  String get actTask => '할 일';

  @override
  String get actBirthday => '생일';

  @override
  String get actTitleField => '제목';

  @override
  String get actAllDay => '종일';

  @override
  String get actTimeField => '시간';

  @override
  String get actRemindMe => '알림 받기';

  @override
  String get actRemindMeSub => '근무 알람과는 별개인 부드러운 알림이에요.';

  @override
  String get actRemindAt => '알림 시각';

  @override
  String get actReminderPassed => '이미 지난 시각이라 이 리마인더는 울리지 않아요.';

  @override
  String get actNoteOptional => '메모(선택)';

  @override
  String get actCompleted => '완료';

  @override
  String get tipDashboardTitle => '홈 화면';

  @override
  String get tipDashboardBody =>
      '여기가 기본 화면이에요. 다음 근무까지 남은 시간과 교대 순서에서 지금 위치를 확인하세요. 타일을 탭하면 자세히 볼 수 있어요.';

  @override
  String get tipTimelineTitle => '전체 근무표';

  @override
  String get tipTimelineBody =>
      '위에서 목록과 월 달력을 전환하세요. 날짜를 탭하면 근무를 편집하거나 이벤트, 할 일, 생일을 추가할 수 있어요.';

  @override
  String get tipManageTitle => '만들고 조정하기';

  @override
  String get tipManageBody =>
      '교대 근무표를 만들고, 단발(초과) 근무를 추가하고, 휴가 동안 일정 전체를 멈추는 것까지 모두 여기서 해요.';

  @override
  String get tipAlarmsTitle => '내 알람';

  @override
  String get tipAlarmsBody =>
      '근무로 만들어진 알람과 직접 추가한 알람이 모두 여기 있어요. 탭해서 시간이나 소리를 바꾸거나, 흔들어서 끄는 중요 근무 알람으로 바꿔 보세요.';

  @override
  String get tipSleepTitle => '수면 계획';

  @override
  String get tipSleepBody => '근무표에 맞춘 휴식 계획이에요. 수면 목표를 정하고 개운하게 다음 근무를 맞이하세요.';

  @override
  String get tipReplayHint => '설정 › 사용 방법에서 언제든 다시 볼 수 있어요.';

  @override
  String get tipDontShow => '도움말 그만 보기';

  @override
  String get tipGotIt => '확인';

  @override
  String get timelineListView => '목록';

  @override
  String get timelineMonthView => '월';

  @override
  String get shiftTypeAftShort => '오후';

  @override
  String get timelineNoShifts => '예정된 근무가 없어요. +를 탭해 추가하세요.';

  @override
  String timelineNoMatch(String filter) {
    return '\'$filter\' 필터에 맞는 근무가 없어요.';
  }

  @override
  String get timelineRestDay => '쉬는 날';

  @override
  String timelineRestDayReason(String reason) {
    return '쉬는 날 · $reason';
  }

  @override
  String get timelineAllDay => '종일';

  @override
  String get calLegendPausedLeave => '일시중지 / 휴가';

  @override
  String get calLegendActivity => '일정';

  @override
  String get filterAll => '전체';

  @override
  String get filterWork => '근무';

  @override
  String get criticalHoldToDismiss => '또는 길게 눌러 끄기';

  @override
  String get patternChoosePattern => '패턴 선택';

  @override
  String get patternRotatingSwings => '주야 교대 패턴';

  @override
  String get patternDaySwings => '주간 근무만';

  @override
  String get patternNightSwings => '야간 근무만';

  @override
  String get patternShiftTimes => '근무 시간';

  @override
  String get patternGenerate => '1일째 정하고 만들기';

  @override
  String get patternSelectDay1 => '다음 1일째 선택';

  @override
  String patternDay1Hint(String label) {
    return '$label 블록의 첫날';
  }

  @override
  String get patternNextDay1 => '다음 1일째';

  @override
  String get patternUseThisDate => '이 날짜 사용';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '근무 $count건을 만들었어요',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return '만들지 못했어요: $error';
  }

  @override
  String get patternFirstBlockFallback => '첫';

  @override
  String get patternBuildCustom => '직접 근무표 만들기';

  @override
  String get patternBuildCustomSub => '맞는 템플릿이 없나요? 블록을 직접 구성하세요.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '주간 $n일',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '오후 $n일',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '야간 $n일',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '휴무 $n일';
  }

  @override
  String get builderNewRoster => '새 근무표';

  @override
  String get builderEditRoster => '근무표 편집';

  @override
  String get builderNewSub => '교대 근무 패턴을 설정하세요';

  @override
  String get builderEditSub => '저장된 근무표를 수정해 교체해요';

  @override
  String get builderNameHint => '근무표 이름(예: 14일 교대)';

  @override
  String get builderCycleLength => '주기 길이';

  @override
  String get builderStartDate => '시작 날짜';

  @override
  String get builderShiftBlocks => '근무 블록';

  @override
  String get builderAddShiftBlock => '근무 블록 추가';

  @override
  String get builderCreateRoster => '근무표 만들기';

  @override
  String get builderSaveChanges => '변경사항 저장';

  @override
  String get builderReplaceWarning => '저장하면 이 근무표가 교체돼요. 칠해 둔 휴가·휴무 표시는 초기화돼요.';

  @override
  String get builderBackToOptions => '옵션으로 돌아가기';

  @override
  String get builderOrImport => '또는 기존 근무표 가져오기';

  @override
  String get builderImportViaAi => 'AI로 가져오기';

  @override
  String get builderScanning => '스캔 중…';

  @override
  String get builderScanInstead => '근무표 사진 스캔하기';

  @override
  String get builderCustomChip => '직접 입력';

  @override
  String get builderCycleLengthLabel => '주기 길이';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n일');
    return '$_temp0';
  }

  @override
  String get builderPickADate => '날짜 선택';

  @override
  String get builderNoBlocksYet => '아직 블록이 없어요';

  @override
  String get builderNoBlocksSub => '근무 블록을 추가해 교대 패턴을 정하세요';

  @override
  String builderDaysLine(String ranges) {
    return '$ranges일째';
  }

  @override
  String get builderEditBlock => '블록 편집';

  @override
  String get builderRemoveBlock => '블록 삭제';

  @override
  String get builderPickRosterStart => '근무표 시작 날짜 선택';

  @override
  String get builderPickScanStart => '스캔한 근무표의 시작 날짜 선택';

  @override
  String get builderScanCamera => '카메라로 스캔';

  @override
  String get builderImportScreenshot => '스크린샷 가져오기';

  @override
  String builderScanFailed(String error) {
    return '스캔 실패: $error';
  }

  @override
  String get builderNoTimesRecognised => '근무 시간을 인식하지 못했어요. 표 주변만 더 좁게 잘라 보세요.';

  @override
  String get builderCustomRosterFallback => '직접 만든 근무표';

  @override
  String get builderScannedRosterFallback => '스캔한 근무표';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '근무표 업데이트: 근무 $count건 예약됨',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '생성됨: 근무 $count건 예약됨',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return '근무표를 만들 수 없어요: $error';
  }

  @override
  String get builderRosterImported => '근무표를 달력으로 가져왔어요';

  @override
  String builderCouldNotImport(String error) {
    return '근무표를 가져올 수 없어요: $error';
  }

  @override
  String get blockAddTitle => '근무 블록 추가';

  @override
  String get blockEditTitle => '근무 블록 편집';

  @override
  String get blockStart => '시작';

  @override
  String get blockEnd => '종료';

  @override
  String get blockTapDays => '이 근무가 있는 날을 탭하세요';

  @override
  String get blockUntappedOff => '탭하지 않은 날은 휴무예요.';

  @override
  String blockOverlap(String ranges) {
    return '$ranges일째에 다른 근무와 시간이 겹쳐요. 시간이나 날짜를 바꿔 주세요.';
  }

  @override
  String get blockAdd => '블록 추가';

  @override
  String get blockSave => '블록 저장';

  @override
  String get aiPromptCopied => '프롬프트를 복사했어요! 근무표와 함께 AI 앱에 붙여넣으세요.';

  @override
  String get aiNothingToPaste => '클립보드에 붙여넣을 내용이 없어요.';

  @override
  String get aiNoValidShifts => '유효한 근무를 찾지 못했어요. 복사한 AI 프롬프트를 사용했는지 확인하세요.';

  @override
  String get aiStep1 => '프롬프트 복사';

  @override
  String get aiCopied => '복사됨!';

  @override
  String get aiCopyPrompt => 'AI 프롬프트 복사';

  @override
  String get aiStep1Sub =>
      'ChatGPT, Gemini 등 AI 앱에 붙여넣고, 근무표 텍스트나 사진·스크린샷을 추가해 보내세요.';

  @override
  String get aiStep2 => 'AI 답변 붙여넣기';

  @override
  String get aiPaste => '붙여넣기';

  @override
  String get aiParsePreview => '분석 후 미리보기';

  @override
  String get aiStep3 => '찾은 근무 확인';

  @override
  String get aiStep3Sub => 'AI가 잘못 인식했다면 라벨을 탭해 주간, 오후, 야간으로 바꾸세요.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 가져오기',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub => 'AI 앱의 도움으로 어떤 근무표 텍스트든 근무로 바꿔요.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
    );
    return '$_temp0 · 근무 $working · 휴무 $off';
  }

  @override
  String get draftReviewTitle => '스캔한 근무표 확인';

  @override
  String draftRemovedDay(String date) {
    return '$date 삭제됨';
  }

  @override
  String get draftUndo => '실행 취소';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '근무표에 $count일을 저장했어요',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => '근무표 이름';

  @override
  String get draftScannedImage => '스캔 이미지';

  @override
  String get draftScannedImageSub => '이미지를 탭해 확대하고 비교하세요';

  @override
  String get draftImageError => '스캔 이미지를 표시할 수 없어요.';

  @override
  String get draftRemove => '삭제';

  @override
  String get draftNoEndTime => '종료 시간 없이 스캔됐어요. 저장하려면 설정하세요.';

  @override
  String get draftTime => '시간';

  @override
  String get draftSetEnd => '종료 설정';

  @override
  String get draftConfirmSave => '확인 후 저장';

  @override
  String notifBeforeYourShift(String type) {
    return '$type 근무 전';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind · $time';
  }

  @override
  String get notifWindDownTitle => '휴식할 시간이에요 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return '화면을 내려놓으세요. 목표 취침 시각은 $time이에요.';
  }

  @override
  String get notifWindDownBody => '화면을 내려놓고 잠들 준비를 시작하세요.';

  @override
  String get notifBedtimeTitle => '잘 시간이에요 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return '$shift 전에 약 $hours시간 자려면 지금 잠자리에 드세요. 기상은 $time이에요.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return '수면 목표 $hours시간을 채우려면 지금 잠자리에 드세요.';
  }

  @override
  String get notifShiftDay => '주간 근무';

  @override
  String get notifShiftAfternoon => '오후 근무';

  @override
  String get notifShiftNight => '야간 근무';

  @override
  String get notifShiftGeneric => '근무';

  @override
  String get notifTrialEndsTitle => 'Rostrik 무료 체험이 내일 끝나요';

  @override
  String get notifTrialEndsBody => '전체 기능을 잠금 해제하면 근무 알람이 계속 울려요.';

  @override
  String seedWakeUpLabel(String type) {
    return '$type 기상';
  }

  @override
  String get seedShiftGeneric => '근무';

  @override
  String commonListAnd(String items, String last) {
    return '$items 및 $last';
  }

  @override
  String get soundClassic => '클래식';

  @override
  String get soundSiren => '사이렌';

  @override
  String get soundDigital => '디지털';

  @override
  String get soundChime => '차임';

  @override
  String get patternFirstResponder => '구급대원 표준';

  @override
  String get ocrCropTitle => '팀 전체 말고 내 줄만 잘라 주세요';

  @override
  String get draftNameHint => '예: 5월 근무표';
}
