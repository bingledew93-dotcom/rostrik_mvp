// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'ご利用の前に';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik は、すべてのシフトに確実に起きられるよう作られています。ただし正直にお伝えすると、どのスマートフォンでも最終的な判断はアプリではなく OS が行います。まれに、どのアラームアプリでも遅延したり鳴らなかったりすることがあります（強力な省電力機能、強制停止、システムアップデート直後など）。';

  @override
  String get legalBodyBackupAdvice =>
      '絶対に遅れられないシフトには、予備としてもう 1 つアラームを設定してください。スマートフォン標準のアラームを含め、どのアラームにも有効な習慣です。';

  @override
  String get legalReviewAndAccept => '内容を確認して同意してください：';

  @override
  String get legalPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get legalTermsOfUse => '利用規約';

  @override
  String get legalConsentCheckbox =>
      'OS がどのアラームアプリにも影響しうることを理解し、プライバシーポリシーと利用規約に同意します。';

  @override
  String get legalAgreeContinue => '同意して続ける';

  @override
  String get legalUpdatedTitle => '規約を更新しました';

  @override
  String get legalUpdatedBody => 'プライバシーポリシーと利用規約が変更されました。続ける前にご確認ください。';

  @override
  String get legalUpdatedAccept => '確認して同意します';

  @override
  String get commonSaving => '保存中…';

  @override
  String get commonCouldNotOpenLink => 'リンクを開けませんでした。';

  @override
  String get welcomeTagline => 'シフト勤務のためのスマート目覚まし。';

  @override
  String get welcomeSubTagline => '平日だけでなく、交代制の勤務表に合わせて鳴るアラーム。';

  @override
  String welcomeTrialTitle(int days) {
    return '$days 日間の無料体験';
  }

  @override
  String get welcomeTrialBody =>
      'カード登録不要ですべての機能を利用できます。その後は買い切りで、サブスクリプションはありません。';

  @override
  String get welcomeGetStarted => 'はじめる';

  @override
  String get welcomeSkip => 'スキップ / 後で設定';

  @override
  String get welcomeTimeFormat => '時刻の表示';

  @override
  String get welcomeWeekStarts => '週の始まり';

  @override
  String get common12h => '12 時間';

  @override
  String get common24h => '24 時間';

  @override
  String get commonSundayShort => '日';

  @override
  String get commonMondayShort => '月';

  @override
  String get rosterTypeTitle => '勤務表の種類を選択';

  @override
  String get rosterTypeQuestion => 'どんな勤務形態ですか？';

  @override
  String get rosterTypeDay => '日勤';

  @override
  String get rosterTypeNight => '夜勤';

  @override
  String get rosterTypeRotating => '交代制';

  @override
  String get rosterTypeCustom => 'カスタム';

  @override
  String get commonContinue => '続ける';

  @override
  String get commonComingSoon => '近日公開';

  @override
  String get permsTitle => '権限';

  @override
  String get permsIntro =>
      'アラームを確実に鳴らすため、Rostrik にはいくつかの権限が必要です。後からシステム設定で変更できます。';

  @override
  String get permsNotifications => '通知';

  @override
  String get permsNotificationsSub => '起床画面を表示するために必要です。';

  @override
  String get permsExactAlarms => '正確なアラーム';

  @override
  String get permsExactAlarmsSub => '設定した時刻ぴったりにアラームを鳴らします。';

  @override
  String get permsBatteryUnrestricted => 'バッテリー：制限なし';

  @override
  String get permsBatteryGrantedSub => 'アラームはバッテリー最適化の影響を受けません。';

  @override
  String get permsBatteryDeniedSub => '一部の端末はバックグラウンドのアプリを終了します。タップして対処。';

  @override
  String get permsUnrestrictedBadge => '制限なし';

  @override
  String get batteryDialogTitle => 'アラームを確実に動かす';

  @override
  String get batteryDialogIntro =>
      '一部の端末（Samsung、Xiaomi、Oppo、Huawei）は、バッテリー節約のためにバックグラウンドのアプリを強制終了します。Rostrik が終了されると、アラームが鳴らないことがあります。';

  @override
  String get batteryDialogMarkUnrestricted =>
      'これを防ぐには、Rostrik を「制限なし」に設定してください：';

  @override
  String get batteryStep1 => 'このアプリの設定を開きます（下のボタン）。';

  @override
  String get batteryStep2 => '「バッテリー」（または「アプリのバッテリー使用量」）をタップします。';

  @override
  String get batteryStep3 => '「制限なし」を選びます（「最適化」や「制限」ではありません）。';

  @override
  String get batteryStep4 => '「バックグラウンドでの動作を許可」があれば、それもオンにします。';

  @override
  String get batteryStep5 =>
      '「使用されていないアプリの動作を停止」（または「アプリが使用されていない場合に権限を削除」）をオフにし、使っていない間に Android がアラームの権限を取り消さないようにします。';

  @override
  String get commonNotNow => '後で';

  @override
  String get batteryGoToSettings => '設定を開く';

  @override
  String get armEngineTitle => 'アラームをセット';

  @override
  String get armEngineRosterReady => '勤務表の準備ができました';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · $date 開始';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return '該当する各シフトの前に、起床アラーム（$summary）をオンにします。';
  }

  @override
  String get armEngineArming => 'セット中…';

  @override
  String get armEngineCta => 'アラームを自動化';

  @override
  String get armEngineLeadTimeLabel => 'アラームの時間';

  @override
  String get armEngineLeadTimeHelper => 'シフト開始の何分前に鳴らすか。';

  @override
  String get shiftTypeDay => '日勤';

  @override
  String get shiftTypeAfternoon => '遅番';

  @override
  String get shiftTypeNight => '夜勤';

  @override
  String get shiftTypeOff => '休み';

  @override
  String get weekdaysNone => '曜日なし';

  @override
  String get weekdaysEveryDay => '毎日';

  @override
  String get weekdaysWeekdays => '平日';

  @override
  String get weekdaysWeekends => '週末';

  @override
  String durationMin(int m) {
    return '$m 分';
  }

  @override
  String durationH(int h) {
    return '$h 時間';
  }

  @override
  String durationHMin(int h, int m) {
    return '$h 時間 $m 分';
  }

  @override
  String durationMinShort(int m) {
    return '$m分';
  }

  @override
  String durationHShort(int h) {
    return '$h時間';
  }

  @override
  String durationHMinShort(int h, int m) {
    return '$h時間$m分';
  }

  @override
  String get commonClose => '閉じる';

  @override
  String get commonSkip => 'スキップ';

  @override
  String get commonBack => '戻る';

  @override
  String get commonDone => '完了';

  @override
  String get commonNext => '次へ';

  @override
  String get walkthroughIntroTitle => '60 秒ツアー';

  @override
  String get walkthroughIntroBodyTwo => 'Rostrik の要となる 2 つの操作です。いつでもスキップできます。';

  @override
  String get walkthroughIntroBodyOne => 'Rostrik の要となる操作です。いつでもスキップできます。';

  @override
  String get walkthroughPaintLabel => '勤務表を塗る';

  @override
  String get walkthroughPaintDetail => '勤務日をタップするだけ。';

  @override
  String get walkthroughShakeLabel => '振って止める';

  @override
  String get walkthroughShakeDetail => 'しっかり振ると重要アラームが止まります。';

  @override
  String get walkthroughTryEach => '「次へ」をタップしてそれぞれ試しましょう。';

  @override
  String get walkthroughTryIt => '「次へ」をタップして試しましょう。';

  @override
  String get walkthroughPaintBody =>
      '勤務日をタップしてください。実際のエディタでは、遅番や夜勤のブロックも同じように追加できます。';

  @override
  String get walkthroughPaintPrompt => '日をタップして日勤を塗りましょう。';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'いいですね！その $count 日が日勤ブロックになりました。タップしていない日は休みのままです。',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      '重要シフトのアラームは、しっかり振り続けないと止まりません。寝ぼけたタップでは止まらない仕組みです。スマートフォンを振ってみましょう。';

  @override
  String get walkthroughShakeSuccess => 'できました！';

  @override
  String get walkthroughShakeSuccessDetail => 'これが重要アラームを止める方法です。';

  @override
  String get walkthroughDoneTitle => '準備完了';

  @override
  String get walkthroughDoneBody =>
      '勤務表は「管理」からいつでも作成できます。このツアーは「設定 → ヘルプ」から再生できます。';

  @override
  String get navDashboard => 'ホーム';

  @override
  String get navTimeline => '予定';

  @override
  String get navManage => '管理';

  @override
  String get navAlarms => 'アラーム';

  @override
  String get navSleep => '睡眠';

  @override
  String get onbPatternTitle => 'ローテーションを選択';

  @override
  String get purchaseTrialEnded => '無料体験期間が終了しました';

  @override
  String get purchaseBody =>
      '一度だけ購入すると、シフトのアラームを引き続き使えます。勤務表・アラーム・設定はすべて保存されており、購入するとすぐに再開します。';

  @override
  String get purchaseAlarmsWontRing => '購入するまでアラームは鳴りません。';

  @override
  String get purchaseUnlock => 'フルアクセスを解除';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'フルアクセスを解除 · $price';
  }

  @override
  String get purchaseRestore => '購入を復元';

  @override
  String get purchaseOneTime => '買い切り。サブスクリプションなし。';

  @override
  String get purchaseUnavailable => '現在購入できません。接続を確認してもう一度お試しください。';

  @override
  String get purchaseCheckingPrevious => '以前の購入を確認しています…';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLegalAbout => '法的情報とアプリについて';

  @override
  String get settingsHelp => 'ヘルプ';

  @override
  String get settingsHowItWorks => '使い方';

  @override
  String get settingsReplayTourShake => 'ツアーを再生（勤務表を塗る + 振って止める）';

  @override
  String get settingsReplayTour => 'ツアーを再生（勤務表を塗る）';

  @override
  String get settingsScreenTips => '画面のヒントを表示';

  @override
  String get settingsScreenTipsSub => '各画面で一度だけ表示されるヒント。オンにすると再表示されます。';

  @override
  String get settingsFullAccess => 'フルアクセス';

  @override
  String get settingsFullAccessUnlocked => 'フルアクセス解除済み';

  @override
  String get settingsThanks => 'Rostrik をご支援いただきありがとうございます。';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '無料体験：残り $days 日',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => '無料体験は終了しました';

  @override
  String get settingsUnlockPitch =>
      '一度購入すれば、体験期間後もシフトのアラームが鳴り続けます。買い切りで、サブスクリプションではありません。';

  @override
  String get settingsRestore => '復元';

  @override
  String get settingsBrandTagline => '9 時〜 5 時の外で働く人のアラーム';

  @override
  String get settingsLeadTime => 'アラームの時間';

  @override
  String get settingsLeadTimeSub => '各シフト開始のこの時間前にアラームが鳴ります。';

  @override
  String get settingsSnoozeDuration => 'スヌーズ時間';

  @override
  String get settingsSnoozeDurationSub => 'スヌーズボタンで鳴っているアラームを延ばす時間。';

  @override
  String get settingsMinutesLabel => '分';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(m, locale: localeName, other: '$m 分');
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => 'シフトサイクル';

  @override
  String get settingsShiftCyclesSub => 'パターンやテンプレートから作成した勤務表。';

  @override
  String get settingsAddShiftCycle => 'シフトサイクルを追加';

  @override
  String get settingsNoRosters => 'まだ勤務表を作成していません。';

  @override
  String commonDateRange(String start, String end) {
    return '$start〜$end';
  }

  @override
  String get commonEdit => '編集';

  @override
  String get commonDelete => '削除';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get settingsDeleteRosterTitle => '勤務表を削除しますか？';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のシフト',
    );
    return '「$label」を削除しますか？予定中のアラームは取り消され、$_temp0が削除されます。';
  }

  @override
  String settingsDeletedRoster(String label) {
    return '「$label」を削除しました';
  }

  @override
  String get commonActive => '有効';

  @override
  String get commonUpcoming => '予定';

  @override
  String get commonPast => '過去';

  @override
  String get settingsWorkHistory => '勤務履歴';

  @override
  String get settingsWorkHistorySub => '完了したカスタムシフトを確認・書き出しして、給与明細の照合に使えます。';

  @override
  String get settingsViewWorkHistory => '勤務履歴を表示・書き出し';

  @override
  String get settingsPreferences => '表示設定';

  @override
  String get settingsPreferencesSub => 'アプリ内でのスケジュールの表示方法。';

  @override
  String get settingsAppearance => '外観';

  @override
  String get settingsThemeSystem => 'システム';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsThemeSub => 'Rostrik の標準はダークです。ライトは温かみのあるクリーム色です。';

  @override
  String get settings24h => '24 時間表示';

  @override
  String get settings24hOn => '時刻は 14:30 のように表示';

  @override
  String get settings24hOff => '時刻は 02:30 PM のように表示';

  @override
  String get settingsWeekStartTitle => 'カレンダーを月曜始まりにする';

  @override
  String get settingsWeekStartMon => '週は月曜日から始まります';

  @override
  String get settingsWeekStartSun => '週は日曜日から始まります';

  @override
  String get settingsTimelineOpensOn => '予定の初期表示';

  @override
  String get commonList => 'リスト';

  @override
  String get commonMonth => '月';

  @override
  String get settingsCalendar => 'カレンダー';

  @override
  String get settingsCalendarSync => 'Google / 端末のカレンダーと同期';

  @override
  String get settingsCalendarSyncSub =>
      'シフトを端末内の専用カレンダー「Rostrik Roster」に自動で反映します。';

  @override
  String get settingsCalSyncOff =>
      'カレンダー同期をオフにしました。今後の「Rostrik Roster」の予定は削除されました。';

  @override
  String get settingsCalSyncMirroring => '勤務表を「Rostrik Roster」カレンダーに反映しています…';

  @override
  String get settingsCalPermNeeded => '勤務表を同期するにはカレンダーへのアクセス権限が必要です。';

  @override
  String get settingsCalBlocked => 'カレンダーへのアクセスがブロックされています。システム設定で許可してください。';

  @override
  String get settingsCalOpenSettings => '設定';

  @override
  String get settingsCalUnsupported => 'この端末ではカレンダー同期を利用できません。';

  @override
  String get settingsDangerZone => '危険な操作';

  @override
  String get settingsDangerZoneSub => '勤務表・アラーム・設定を削除し、初期設定からやり直します。';

  @override
  String get settingsResetAppData => 'アプリのデータをリセット';

  @override
  String get settingsResetTitle => 'アプリをリセットしますか？';

  @override
  String get settingsResetBody => 'よろしいですか？勤務表・アラーム・設定が削除されます。';

  @override
  String get settingsResetConfirm => 'リセット';

  @override
  String get dashNoUpcomingShifts => '予定のシフトはありません';

  @override
  String get dashEnjoyTimeOff => 'ゆっくり休んでください。';

  @override
  String get dashInProgress => '勤務中';

  @override
  String get dashRotation => 'ローテーション';

  @override
  String get dashAlarmsCantRing => 'アラームが正しく鳴らない状態です';

  @override
  String get dashNotifsOffIssue => '通知がオフです。アラームが鳴っても起床画面が表示されず、止められません。';

  @override
  String get dashOpenSettings => '設定を開く';

  @override
  String get dashExactBlockedIssue => '正確なアラームがブロックされています。アラームを設定できません。';

  @override
  String get dashAlarmsWontTakeOverScreen => 'アラームが画面全体に表示されません';

  @override
  String get dashFullScreenBlockedIssue =>
      '全画面アラームがオフです。画面がロックされているときは、アラーム画面ではなく通知が表示されます。';

  @override
  String get dashAllow => '許可';

  @override
  String get dashSlideToSkip => 'スライドしてこのアラームをスキップ';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'スライドして $count 件のアラームをスキップ',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return '次のアラームを解除 · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'このシフトの $count 件のアラームをすべてスキップ',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'アラームを残す';

  @override
  String get dashMyRotation => 'マイローテーション';

  @override
  String get dashCalendarUpcoming => 'カレンダーと今後のシフト';

  @override
  String get dashNextShifts => '今後のシフト';

  @override
  String get dashOpenTimeline => '予定を開く';

  @override
  String heroStartsIn(String countdown) {
    return '開始まで $countdown';
  }

  @override
  String heroEndsIn(String countdown) {
    return '終了まで $countdown';
  }

  @override
  String get heroStartsInPrefix => '開始まで';

  @override
  String get heroEndsInPrefix => '終了まで';

  @override
  String heroStartsTodayAt(String time) {
    return '今日 $time 開始';
  }

  @override
  String heroStartedTodayAt(String time) {
    return '今日 $time に開始';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return '明日 $time 開始';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return '昨日 $time に開始';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return '昨日 $time 開始';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return '$date $time 開始';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return '$date $time に開始';
  }

  @override
  String get shiftTypeDayShift => '日勤';

  @override
  String get shiftTypeAfternoonShift => '遅番';

  @override
  String get shiftTypeNightShift => '夜勤';

  @override
  String heroDayXofY(int x, int y, String label) {
    return '$y 日中 $x 日目 · $label';
  }

  @override
  String get heroOffTomorrow => '明日は休み';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 日後に休み',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => '明日から勤務';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 日後に勤務再開',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => '休み';

  @override
  String durationDayShort(int d) {
    return '$d日';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d日$h時間';
  }

  @override
  String get alarmsTitle => 'アラーム';

  @override
  String get alarmsAddTooltip => 'アラームを追加';

  @override
  String get alarmsSortTooltip => 'アラームを並べ替え';

  @override
  String get alarmsSortByTime => '時刻順';

  @override
  String get alarmsSortByShiftType => 'シフトの種類順';

  @override
  String get alarmsEmptyTitle => 'アラームはまだありません。';

  @override
  String get alarmsEmptyBody => '+ をタップして追加します。';

  @override
  String get alarmsNextAlarm => '次のアラーム';

  @override
  String get alarmsHolidayMode => '休暇モード';

  @override
  String get alarmsHolidayModeSub => 'アラームは一時停止中です。何も鳴りません。';

  @override
  String get alarmsNoUpcoming => '予定のシフトアラームはありません';

  @override
  String get alarmsNoUpcomingSub => 'ローテーション連動のアラームを追加するか、勤務表を作成してください。';

  @override
  String alarmsForYourShift(String type, String day) {
    return '$typeのシフト用 · $day';
  }

  @override
  String get commonToday => '今日';

  @override
  String get commonTomorrow => '明日';

  @override
  String get alarmsOffWontRing => 'オフ（鳴りません）';

  @override
  String get alarmsNoUpcomingRing => '予定のアラームはありません';

  @override
  String alarmsNextRing(String day, String time) {
    return '次回：$day $time';
  }

  @override
  String get alarmsSwipeToDelete => 'スワイプして削除';

  @override
  String get alarmsRingsOnceAutoDelete => '1 回だけ鳴る · 自動削除';

  @override
  String get alarmsRingsOnce => '1 回だけ鳴る';

  @override
  String get alarmsYourShift => 'シフト';

  @override
  String alarmsShiftsOfType(String type) {
    return '$typeのシフト';
  }

  @override
  String alarmsExactTime(String shift) {
    return '時刻指定 · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$shiftの $lead 前 · 標準';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$shiftの $lead 前';
  }

  @override
  String get createEditAlarm => 'アラームを編集';

  @override
  String get createNewAlarm => '新しいアラーム';

  @override
  String get createDefaultLabel => '起床';

  @override
  String get createFallbackLabel => 'アラーム';

  @override
  String get createPickBecomesDefault => '選んだ音が新しいアラームの標準になります。';

  @override
  String get createSelectFromFiles => 'ファイルから選択';

  @override
  String get createFilesSub => '端末に保存されている音声ファイルを選びます';

  @override
  String get createSelectSystemTone => 'システムの音を選択';

  @override
  String get createSystemToneSub => '端末のアラーム音から選びます';

  @override
  String get createAlarmTiming => '鳴らすタイミング';

  @override
  String get createLeadTimeMode => '開始前';

  @override
  String get createExactTimeMode => '時刻指定';

  @override
  String createFiresAt(String time) {
    return '$time に鳴る';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return 'シフト開始の $lead 前';
  }

  @override
  String get createLinkedShift => '連動するシフト';

  @override
  String get createRepeatOn => '繰り返す曜日';

  @override
  String get createLabelField => 'ラベル';

  @override
  String get createLabelHint => '例：起床';

  @override
  String get createCriticalShift => '重要シフト';

  @override
  String get createCriticalShiftSub => '振って止める · 3 秒長押しで予備解除';

  @override
  String get createRingtone => 'アラーム音';

  @override
  String get commonStop => '停止';

  @override
  String get commonPlay => '再生';

  @override
  String get createVibrate => 'バイブレーション';

  @override
  String get createRepeat => '繰り返し';

  @override
  String get createRepeatRotation => 'ローテ';

  @override
  String get createRepeatWeekly => '毎週';

  @override
  String get createRepeatOneTime => '1 回';

  @override
  String get createPickOneDay => '曜日を 1 つ以上選んでください';

  @override
  String get commonSave => '保存';

  @override
  String get commonSaveChanges => '変更を保存';

  @override
  String get createTimeBeforeShift => 'シフト前の時間';

  @override
  String get commonOk => 'OK';

  @override
  String get sleepTitle => '睡眠';

  @override
  String get sleepTargetHeader => '睡眠目標';

  @override
  String get sleepTargetSub => '眠りたい時間数。Rostrik が次のアラームから逆算して今夜の就寝時刻を決めます。';

  @override
  String get sleepRemindersHeader => 'リマインダー';

  @override
  String get sleepWindDownHeader => 'リラックスの時間';

  @override
  String get sleepWindDownSub => '就寝時刻の何分前にリラックスの通知を届けるか。';

  @override
  String get sleepSoundsHeader => '睡眠サウンド';

  @override
  String get sleepSoundsSub => '眠りにつくためのホワイトノイズとブラウンノイズ。タイマーを選んでサウンドをタップします。';

  @override
  String get sleepNothingToPlan => '今夜の予定はありません';

  @override
  String get sleepNothingToPlanSub =>
      '勤務表にシフトを追加すると、次の起床に合わせて Rostrik が就寝時刻を提案します。';

  @override
  String get sleepTransitionDay => '移行日';

  @override
  String get sleepTransitionTitle => '明日は夜勤です。朝はゆっくり眠りましょう。';

  @override
  String get sleepTransitionBody =>
      '今日は移行日です。夜勤の前に休みがあるので、早朝のアラームはありません。今のうちにしっかり休み、今夜は遅めに寝ましょう。';

  @override
  String get sleepRestRecovery => '休息と回復';

  @override
  String get sleepNoEarlyAlarm => '早朝のアラームはありません';

  @override
  String get sleepRestBody =>
      '次のシフトまで 1 日以上あるため、今夜は起床時刻を計画する必要がありません。自分のリズムで眠って回復しましょう。シフトが近づいたら Rostrik が就寝プランを作ります。';

  @override
  String get sleepTonightsPlan => '今夜のプラン';

  @override
  String get sleepTargetBedtime => '目標就寝時刻';

  @override
  String get sleepWindDownStat => 'リラックス';

  @override
  String get sleepWakeUpStat => '起床';

  @override
  String get sleepDurationStat => '睡眠時間';

  @override
  String get sleepBedtimeReminder => '就寝リマインダー';

  @override
  String sleepNudgeAtBedtime(String time) {
    return '$time に就寝を知らせる';
  }

  @override
  String get sleepBedtimeSub => '寝る時間になったらお知らせ';

  @override
  String get sleepWindDownReminder => 'リラックスリマインダー';

  @override
  String sleepNudgeAtWindDown(String time) {
    return '$time にリラックス開始を知らせる';
  }

  @override
  String get sleepWindDownReminderSub => '少し早めにリラックスを促すお知らせ';

  @override
  String get commonOff => 'オフ';

  @override
  String get sleepSoundWhiteNoise => 'ホワイトノイズ';

  @override
  String get sleepSoundPinkNoise => 'ピンクノイズ';

  @override
  String get sleepSoundBrownNoise => 'ブラウンノイズ';

  @override
  String get sleepSoundFan => '扇風機';

  @override
  String get sleepSoundOcean => '海';

  @override
  String get sleepSoundRain => '雨';

  @override
  String get manageTitle => '管理';

  @override
  String get manageRosterTools => '勤務表ツール';

  @override
  String get manageRosterToolsSub => 'アラームと睡眠プランの元になるシフトを作成・調整します。';

  @override
  String get manageGenerateRotation => 'ローテーションを作成';

  @override
  String get manageGenerateRotationSub => 'テンプレートから繰り返しのシフトパターンを作ります。';

  @override
  String get manageAddCustomShift => '単発シフトを追加';

  @override
  String get manageAddCustomShiftSub => '勤務表に単発のシフトを 1 件追加します。';

  @override
  String get manageMarkLeave => '休暇・休みを登録';

  @override
  String get manageMarkLeaveSub => '休みの日（年休、病欠）をまとめて塗ります。';

  @override
  String get managePauseSchedule => 'スケジュールを一時停止';

  @override
  String get managePausedSub => '休暇モードオン：アラームは鳴らず、勤務表はそのまま残ります。';

  @override
  String get manageNotPausedSub => '休暇モード：勤務がない間はアラームを止めます。';

  @override
  String get markLeaveTitle => '休暇を登録';

  @override
  String get markLeaveIntro =>
      '休みの日をタップし、理由を選んで適用します。その日のアラームは鳴らず、勤務表はそのまま残ります。';

  @override
  String get leaveAnnual => '年次休暇';

  @override
  String get leaveSick => '病欠';

  @override
  String get leavePublicHoliday => '祝日';

  @override
  String get markLeaveReason => '理由';

  @override
  String get markLeaveFallbackReason => '休暇';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のシフトを「$reason」に設定しました。',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => '登録する日を選択';

  @override
  String get markLeaveNoShifts => 'その日にシフトはありません';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のシフトに適用',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => '勤務履歴';

  @override
  String get workHistoryExportTooltip => '履歴を書き出し';

  @override
  String workHistoryExportFailed(String error) {
    return '履歴を書き出せませんでした：$error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '勤務 $count 件',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours 時間';
  }

  @override
  String get commonPaused => '一時停止';

  @override
  String workHistoryPausedReason(String reason) {
    return '一時停止 · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'ローテ';

  @override
  String get workHistoryAdHocBadge => '単発';

  @override
  String get workHistoryEmptyTitle => '完了したシフトはまだありません';

  @override
  String get workHistoryEmptyBody =>
      '勤務したシフト（ローテーション・カスタムとも）は終了後ここに表示され、給与明細の照合用に書き出せます。';

  @override
  String get workHistoryShareSubject => 'Rostrik 勤務履歴';

  @override
  String get workHistoryShareText => 'Rostrik から書き出した勤務履歴です。';

  @override
  String get shiftEdAddShift => 'シフトを追加';

  @override
  String get shiftEdEditShift => 'シフトを編集';

  @override
  String get shiftEdDate => '日付';

  @override
  String get shiftEdPickDate => '日付を選択';

  @override
  String get shiftEdStarts => '開始';

  @override
  String get shiftEdEnds => '終了';

  @override
  String get shiftEdPickTime => '時刻を選択';

  @override
  String get shiftEdEndsNextDay => '翌日終了';

  @override
  String get shiftEdPauseTitle => 'このシフトを一時停止 / 取り消し';

  @override
  String get shiftEdPausedSub => 'アラームは鳴りません。記録としてカレンダーに残ります。';

  @override
  String get shiftEdNotPausedSub => '削除せずに休み（病欠、休暇、祝日）として登録します。';

  @override
  String get shiftEdReasonOptional => '理由（任意）';

  @override
  String get dayShifts => 'シフト';

  @override
  String get dayActivities => '予定';

  @override
  String get dayAddAnotherShift => 'シフトをもう 1 つ追加';

  @override
  String get dayAddActivity => '予定を追加';

  @override
  String get dayAddActivitySub => 'イベント、タスク、誕生日';

  @override
  String get dayReminder => 'リマインダー';

  @override
  String get actEditActivity => '予定を編集';

  @override
  String get actLeadAtTime => '開始時';

  @override
  String get actLead10Min => '10 分前';

  @override
  String get actLead30Min => '30 分前';

  @override
  String get actLead1Hour => '1 時間前';

  @override
  String get actLead1Day => '1 日前';

  @override
  String get actEvent => 'イベント';

  @override
  String get actTask => 'タスク';

  @override
  String get actBirthday => '誕生日';

  @override
  String get actTitleField => 'タイトル';

  @override
  String get actAllDay => '終日';

  @override
  String get actTimeField => '時刻';

  @override
  String get actRemindMe => 'リマインドする';

  @override
  String get actRemindMeSub => 'シフトのアラームとは別の、控えめな通知です。';

  @override
  String get actRemindAt => '通知時刻';

  @override
  String get actReminderPassed => 'この時刻はすでに過ぎているため、通知されません。';

  @override
  String get actNoteOptional => 'メモ（任意）';

  @override
  String get actCompleted => '完了';

  @override
  String get tipDashboardTitle => 'ホーム';

  @override
  String get tipDashboardBody =>
      'ここが拠点です。次のシフトまでのカウントダウンと、ローテーションの現在地を確認できます。タイルをタップすると詳細を表示します。';

  @override
  String get tipTimelineTitle => '勤務表全体';

  @override
  String get tipTimelineBody =>
      '上部でリストと月表示を切り替えます。日をタップするとシフトの編集や、イベント・タスク・誕生日の追加ができます。';

  @override
  String get tipManageTitle => '作成と調整';

  @override
  String get tipManageBody =>
      '交代制の勤務表を作る、単発（残業）シフトを追加する、休暇中にスケジュール全体を止める、すべてここで行えます。';

  @override
  String get tipAlarmsTitle => 'アラーム';

  @override
  String get tipAlarmsBody =>
      'シフトから作られたアラームと、自分で追加したアラームの一覧です。タップして時刻や音を変更したり、振って止める重要シフトアラームにしたりできます。';

  @override
  String get tipSleepTitle => '睡眠プラン';

  @override
  String get tipSleepBody => '勤務表に合わせたリラックスプラン。睡眠目標を決めて、しっかり休んで次のシフトに備えましょう。';

  @override
  String get tipReplayHint => '「設定 › 使い方」からいつでも再表示できます。';

  @override
  String get tipDontShow => 'ヒントを表示しない';

  @override
  String get tipGotIt => 'OK';

  @override
  String get timelineListView => 'リスト';

  @override
  String get timelineMonthView => '月表示';

  @override
  String get shiftTypeAftShort => '遅番';

  @override
  String get timelineNoShifts => '予定のシフトはありません。+ をタップして追加します。';

  @override
  String timelineNoMatch(String filter) {
    return '「$filter」に一致するシフトはありません。';
  }

  @override
  String get timelineRestDay => '休日';

  @override
  String timelineRestDayReason(String reason) {
    return '休日 · $reason';
  }

  @override
  String get timelineAllDay => '終日';

  @override
  String get calLegendPausedLeave => '一時停止 / 休暇';

  @override
  String get calLegendActivity => '予定';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterWork => '勤務';

  @override
  String get criticalHoldToDismiss => 'または長押しで止める';

  @override
  String get patternChoosePattern => 'パターンを選択';

  @override
  String get patternRotatingSwings => '日勤・夜勤ローテーション';

  @override
  String get patternDaySwings => '日勤のみ';

  @override
  String get patternNightSwings => '夜勤のみ';

  @override
  String get patternShiftTimes => 'シフトの時間';

  @override
  String get patternGenerate => '1 日目を設定して作成';

  @override
  String get patternSelectDay1 => '次の 1 日目を選択';

  @override
  String patternDay1Hint(String label) {
    return '$labelブロックの初日';
  }

  @override
  String get patternNextDay1 => '次の 1 日目';

  @override
  String get patternUseThisDate => 'この日付を使う';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のシフトを作成しました',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return '作成に失敗しました：$error';
  }

  @override
  String get patternFirstBlockFallback => '最初の';

  @override
  String get patternBuildCustom => 'カスタム勤務表を作成';

  @override
  String get patternBuildCustomSub => '合うテンプレートがない場合は、自分でブロックを組み立てます。';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '日勤 $n 日',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '遅番 $n 日',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '夜勤 $n 日',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '休み $n 日';
  }

  @override
  String get builderNewRoster => '新しい勤務表';

  @override
  String get builderEditRoster => '勤務表を編集';

  @override
  String get builderNewSub => 'シフトのローテーションを設定します';

  @override
  String get builderEditSub => '保存済みの勤務表を変更して置き換えます';

  @override
  String get builderNameHint => '勤務表の名前（例：14 日ローテーション）';

  @override
  String get builderCycleLength => 'サイクルの長さ';

  @override
  String get builderStartDate => '開始日';

  @override
  String get builderShiftBlocks => 'シフトブロック';

  @override
  String get builderAddShiftBlock => 'シフトブロックを追加';

  @override
  String get builderCreateRoster => '勤務表を作成';

  @override
  String get builderSaveChanges => '変更を保存';

  @override
  String get builderReplaceWarning =>
      '保存するとこの勤務表が置き換わります。塗った休暇・休みの登録はリセットされます。';

  @override
  String get builderBackToOptions => '選択肢に戻る';

  @override
  String get builderOrImport => '既存の勤務表を取り込む';

  @override
  String get builderImportViaAi => 'AI で取り込む';

  @override
  String get builderScanning => 'スキャン中…';

  @override
  String get builderScanInstead => '勤務表の写真をスキャンする';

  @override
  String get builderCustomChip => 'カスタム';

  @override
  String get builderCycleLengthLabel => 'サイクルの長さ';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n 日');
    return '$_temp0';
  }

  @override
  String get builderPickADate => '日付を選択';

  @override
  String get builderNoBlocksYet => 'ブロックはまだありません';

  @override
  String get builderNoBlocksSub => 'シフトブロックを追加してローテーションを決めましょう';

  @override
  String builderDaysLine(String ranges) {
    return '$ranges 日目';
  }

  @override
  String get builderEditBlock => 'ブロックを編集';

  @override
  String get builderRemoveBlock => 'ブロックを削除';

  @override
  String get builderPickRosterStart => '勤務表の開始日を選択';

  @override
  String get builderPickScanStart => 'スキャンした勤務表の開始日を選択';

  @override
  String get builderScanCamera => 'カメラでスキャン';

  @override
  String get builderImportScreenshot => 'スクリーンショットを取り込む';

  @override
  String builderScanFailed(String error) {
    return 'スキャンに失敗しました：$error';
  }

  @override
  String get builderNoTimesRecognised =>
      'シフトの時刻を読み取れませんでした。表の周りをもっと狭くトリミングしてください。';

  @override
  String get builderCustomRosterFallback => 'カスタム勤務表';

  @override
  String get builderScannedRosterFallback => 'スキャンした勤務表';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '勤務表を更新しました（$count 件のシフト）',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '作成しました（$count 件のシフト）',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return '勤務表を作成できませんでした：$error';
  }

  @override
  String get builderRosterImported => '勤務表をカレンダーに取り込みました';

  @override
  String builderCouldNotImport(String error) {
    return '勤務表を取り込めませんでした：$error';
  }

  @override
  String get blockAddTitle => 'シフトブロックを追加';

  @override
  String get blockEditTitle => 'シフトブロックを編集';

  @override
  String get blockStart => '開始';

  @override
  String get blockEnd => '終了';

  @override
  String get blockTapDays => 'このシフトの日をタップ';

  @override
  String get blockUntappedOff => 'タップしていない日は休みです。';

  @override
  String blockOverlap(String ranges) {
    return '$ranges 日目で別のシフトと時間が重なっています。時刻か日を変更してください。';
  }

  @override
  String get blockAdd => 'ブロックを追加';

  @override
  String get blockSave => 'ブロックを保存';

  @override
  String get aiPromptCopied => 'プロンプトをコピーしました！勤務表と一緒に AI アプリに貼り付けてください。';

  @override
  String get aiNothingToPaste => 'クリップボードに貼り付ける内容がありません。';

  @override
  String get aiNoValidShifts => '有効なシフトが見つかりません。コピーした AI プロンプトを使ったか確認してください。';

  @override
  String get aiStep1 => 'プロンプトをコピー';

  @override
  String get aiCopied => 'コピーしました！';

  @override
  String get aiCopyPrompt => 'AI プロンプトをコピー';

  @override
  String get aiStep1Sub =>
      'ChatGPT、Gemini などの AI アプリに貼り付け、勤務表のテキストや写真・スクリーンショットを添えて送信します。';

  @override
  String get aiStep2 => 'AI の返答を貼り付け';

  @override
  String get aiPaste => '貼り付け';

  @override
  String get aiParsePreview => '解析してプレビュー';

  @override
  String get aiStep3 => '検出されたシフトを確認';

  @override
  String get aiStep3Sub => 'AI が間違えた場合は、ラベルをタップして日勤・遅番・夜勤を切り替えます。';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 日分を取り込む',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub => 'AI アプリを使って、どんな勤務表のテキストもシフトに変換します。';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 日',
    );
    return '$_temp0 · 勤務 $working · 休み $off';
  }

  @override
  String get draftReviewTitle => 'スキャンした勤務表を確認';

  @override
  String draftRemovedDay(String date) {
    return '$date を削除しました';
  }

  @override
  String get draftUndo => '元に戻す';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 日分を勤務表に保存しました',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => '勤務表の名前';

  @override
  String get draftScannedImage => 'スキャン画像';

  @override
  String get draftScannedImageSub => '画像をタップして拡大・比較';

  @override
  String get draftImageError => 'スキャン画像を表示できませんでした。';

  @override
  String get draftRemove => '削除';

  @override
  String get draftNoEndTime => '終了時刻が読み取れませんでした。保存するには設定してください。';

  @override
  String get draftTime => '時刻';

  @override
  String get draftSetEnd => '終了を設定';

  @override
  String get draftConfirmSave => '確認して保存';

  @override
  String notifBeforeYourShift(String type) {
    return '$typeシフトの前に';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind · $time';
  }

  @override
  String get notifWindDownTitle => 'リラックスの時間です 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return '画面から離れましょう。就寝目標は $time です。';
  }

  @override
  String get notifWindDownBody => '画面から離れて、眠る準備を始めましょう。';

  @override
  String get notifBedtimeTitle => 'おやすみの時間 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return '$shiftの前に約 $hours 時間眠るため、そろそろ寝ましょう。起床は $time です。';
  }

  @override
  String notifBedtimeBody(int hours) {
    return '睡眠目標 $hours 時間のため、そろそろ寝ましょう。';
  }

  @override
  String get notifShiftDay => '日勤';

  @override
  String get notifShiftAfternoon => '遅番';

  @override
  String get notifShiftNight => '夜勤';

  @override
  String get notifShiftGeneric => 'シフト';

  @override
  String get notifTrialEndsTitle => 'Rostrik の無料体験は明日終了します';

  @override
  String get notifTrialEndsBody => 'フルアクセスを解除すると、シフトのアラームが引き続き鳴ります。';

  @override
  String seedWakeUpLabel(String type) {
    return '$typeの起床';
  }

  @override
  String get seedShiftGeneric => 'シフト';

  @override
  String commonListAnd(String items, String last) {
    return '$items・$last';
  }

  @override
  String get soundClassic => 'クラシック';

  @override
  String get soundSiren => 'サイレン';

  @override
  String get soundDigital => 'デジタル';

  @override
  String get soundChime => 'チャイム';

  @override
  String get patternFirstResponder => '救急隊標準';

  @override
  String get ocrCropTitle => 'チーム全体ではなく自分の行だけをトリミング';

  @override
  String get draftNameHint => '例：5 月の勤務表';
}
