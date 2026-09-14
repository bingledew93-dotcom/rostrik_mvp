// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'Trước khi bắt đầu';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik được tạo ra để đánh thức bạn cho mọi ca làm. Xin nói thật: trên mọi điện thoại, hệ điều hành chứ không phải ứng dụng mới là bên quyết định cuối cùng. Trong một số ít trường hợp, hệ điều hành có thể làm trễ hoặc tắt tiếng bất kỳ ứng dụng báo thức nào (tiết kiệm pin quá mức, buộc dừng ứng dụng, hoặc ngay sau khi cập nhật hệ thống).';

  @override
  String get legalBodyBackupAdvice =>
      'Với những ca không thể bỏ lỡ, hãy đặt thêm một báo thức dự phòng. Đây là thói quen tốt với mọi báo thức, kể cả báo thức có sẵn trên điện thoại.';

  @override
  String get legalReviewAndAccept => 'Vui lòng xem và đồng ý:';

  @override
  String get legalPrivacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get legalTermsOfUse => 'Điều khoản sử dụng';

  @override
  String get legalConsentCheckbox =>
      'Tôi hiểu rằng hệ điều hành có thể ảnh hưởng đến mọi ứng dụng báo thức, và tôi đồng ý với Chính sách quyền riêng tư và Điều khoản sử dụng.';

  @override
  String get legalAgreeContinue => 'Đồng ý và tiếp tục';

  @override
  String get commonSaving => 'Đang lưu…';

  @override
  String get commonCouldNotOpenLink => 'Không mở được liên kết.';

  @override
  String get welcomeTagline =>
      'Đồng hồ báo thức thông minh dành cho người làm theo ca.';

  @override
  String get welcomeSubTagline =>
      'Báo thức theo lịch ca xoay vòng của bạn, không chỉ theo ngày trong tuần.';

  @override
  String welcomeTrialTitle(int days) {
    return 'Dùng thử miễn phí $days ngày';
  }

  @override
  String get welcomeTrialBody =>
      'Dùng đầy đủ mọi tính năng, không cần thẻ. Sau đó chỉ mua một lần, không bao giờ là gói đăng ký.';

  @override
  String get welcomeGetStarted => 'Bắt đầu';

  @override
  String get welcomeSkip => 'Bỏ qua / Thiết lập sau';

  @override
  String get welcomeTimeFormat => 'Định dạng giờ';

  @override
  String get welcomeWeekStarts => 'Tuần bắt đầu';

  @override
  String get common12h => '12 giờ';

  @override
  String get common24h => '24 giờ';

  @override
  String get commonSundayShort => 'CN';

  @override
  String get commonMondayShort => 'T2';

  @override
  String get rosterTypeTitle => 'Chọn loại lịch ca';

  @override
  String get rosterTypeQuestion => 'Lịch ca của bạn như thế nào?';

  @override
  String get rosterTypeDay => 'Ca ngày';

  @override
  String get rosterTypeNight => 'Ca đêm';

  @override
  String get rosterTypeRotating => 'Xoay ca';

  @override
  String get rosterTypeCustom => 'Tùy chỉnh';

  @override
  String get commonContinue => 'Tiếp tục';

  @override
  String get commonComingSoon => 'Sắp ra mắt';

  @override
  String get permsTitle => 'Quyền';

  @override
  String get permsIntro =>
      'Rostrik cần một vài quyền để báo thức reo đáng tin cậy. Bạn có thể thay đổi sau trong cài đặt hệ thống.';

  @override
  String get permsNotifications => 'Thông báo';

  @override
  String get permsNotificationsSub => 'Cần để hiển thị màn hình báo thức.';

  @override
  String get permsExactAlarms => 'Báo thức chính xác';

  @override
  String get permsExactAlarmsSub => 'Cho phép báo thức reo đúng giờ đã hẹn.';

  @override
  String get permsBatteryUnrestricted => 'Pin không hạn chế';

  @override
  String get permsBatteryGrantedSub =>
      'Báo thức được bảo vệ khỏi tính năng tối ưu hóa pin.';

  @override
  String get permsBatteryDeniedSub =>
      'Một số điện thoại tắt ứng dụng chạy nền. Chạm để khắc phục.';

  @override
  String get permsUnrestrictedBadge => 'Không hạn chế';

  @override
  String get batteryDialogTitle => 'Giữ báo thức luôn hoạt động';

  @override
  String get batteryDialogIntro =>
      'Một số điện thoại (Samsung, Xiaomi, Oppo, Huawei) tắt mạnh tay các ứng dụng chạy nền để tiết kiệm pin. Nếu Rostrik bị tắt, báo thức có thể không reo.';

  @override
  String get batteryDialogMarkUnrestricted =>
      'Đặt Rostrik ở chế độ Không hạn chế để tránh điều này:';

  @override
  String get batteryStep1 => 'Mở cài đặt của ứng dụng này (nút bên dưới).';

  @override
  String get batteryStep2 =>
      'Chạm vào Pin (hoặc \"Mức sử dụng pin của ứng dụng\").';

  @override
  String get batteryStep3 =>
      'Chọn Không hạn chế (không phải \"Được tối ưu hóa\" hay \"Bị hạn chế\").';

  @override
  String get batteryStep4 =>
      'Nếu thấy \"Cho phép hoạt động nền\", hãy bật cả mục đó.';

  @override
  String get batteryStep5 =>
      'TẮT \"Tạm dừng hoạt động của ứng dụng nếu không dùng\" (hoặc \"Xóa quyền nếu không dùng ứng dụng\") để Android không thu hồi quyền báo thức khi bạn vắng mặt.';

  @override
  String get commonNotNow => 'Để sau';

  @override
  String get batteryGoToSettings => 'Đi tới Cài đặt';

  @override
  String get armEngineTitle => 'Bật báo thức';

  @override
  String get armEngineRosterReady => 'Lịch ca của bạn đã sẵn sàng';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · bắt đầu $date';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'Chúng tôi sẽ bật báo thức ($summary) trước mỗi ca phù hợp.';
  }

  @override
  String get armEngineArming => 'Đang bật…';

  @override
  String get armEngineCta => 'Tự động hóa báo thức';

  @override
  String get armEngineLeadTimeLabel => 'Thời gian báo trước';

  @override
  String get armEngineLeadTimeHelper =>
      'Báo thức reo trước giờ vào ca bao lâu.';

  @override
  String get shiftTypeDay => 'Ngày';

  @override
  String get shiftTypeAfternoon => 'Chiều';

  @override
  String get shiftTypeNight => 'Đêm';

  @override
  String get shiftTypeOff => 'Nghỉ';

  @override
  String get weekdaysNone => 'Không có ngày nào';

  @override
  String get weekdaysEveryDay => 'Hằng ngày';

  @override
  String get weekdaysWeekdays => 'Ngày trong tuần';

  @override
  String get weekdaysWeekends => 'Cuối tuần';

  @override
  String durationMin(int m) {
    return '$m phút';
  }

  @override
  String durationH(int h) {
    return '$h giờ';
  }

  @override
  String durationHMin(int h, int m) {
    return '$h giờ $m phút';
  }

  @override
  String durationMinShort(int m) {
    return '${m}ph';
  }

  @override
  String durationHShort(int h) {
    return '${h}g';
  }

  @override
  String durationHMinShort(int h, int m) {
    return '${h}g ${m}ph';
  }

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonSkip => 'Bỏ qua';

  @override
  String get commonBack => 'Quay lại';

  @override
  String get commonDone => 'Xong';

  @override
  String get commonNext => 'Tiếp';

  @override
  String get walkthroughIntroTitle => 'Hướng dẫn 60 giây';

  @override
  String get walkthroughIntroBodyTwo =>
      'Hai điều làm nên Rostrik. Bạn có thể bỏ qua bất cứ lúc nào.';

  @override
  String get walkthroughIntroBodyOne =>
      'Điều làm nên Rostrik. Bạn có thể bỏ qua bất cứ lúc nào.';

  @override
  String get walkthroughPaintLabel => 'Tô lịch ca';

  @override
  String get walkthroughPaintDetail =>
      'Chạm vào những ngày bạn đi làm, nhanh vậy thôi.';

  @override
  String get walkthroughShakeLabel => 'Lắc để tắt';

  @override
  String get walkthroughShakeDetail => 'Lắc mạnh để tắt báo thức quan trọng.';

  @override
  String get walkthroughTryEach => 'Chạm Tiếp để thử từng cái.';

  @override
  String get walkthroughTryIt => 'Chạm Tiếp để thử.';

  @override
  String get walkthroughPaintBody =>
      'Chạm vào những ngày bạn đi làm. Trong trình tạo lịch thật, bạn thêm các khối khác (ca chiều, ca đêm) theo cách tương tự.';

  @override
  String get walkthroughPaintPrompt => 'Chạm vào một ngày để tô ca ngày.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tuyệt! $count ngày đó giờ là khối ca ngày. Những ngày chưa chạm vẫn là ngày nghỉ. Dễ vậy thôi.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'Báo thức ca quan trọng chỉ tắt khi lắc mạnh và liên tục, để một cái chạm lúc ngái ngủ không tắt được. Thử ngay: lắc điện thoại.';

  @override
  String get walkthroughShakeSuccess => 'Làm được rồi!';

  @override
  String get walkthroughShakeSuccessDetail =>
      'Đó chính là cách bạn sẽ tắt báo thức quan trọng.';

  @override
  String get walkthroughDoneTitle => 'Đã sẵn sàng';

  @override
  String get walkthroughDoneBody =>
      'Tạo lịch ca bất cứ lúc nào trong mục Quản lý, và xem lại hướng dẫn này tại Cài đặt → Trợ giúp.';

  @override
  String get navDashboard => 'Tổng quan';

  @override
  String get navTimeline => 'Lịch trình';

  @override
  String get navManage => 'Quản lý';

  @override
  String get navAlarms => 'Báo thức';

  @override
  String get navSleep => 'Giấc ngủ';

  @override
  String get onbPatternTitle => 'Chọn kiểu xoay ca';

  @override
  String get purchaseTrialEnded => 'Thời gian dùng thử miễn phí đã kết thúc';

  @override
  String get purchaseBody =>
      'Mở khóa Rostrik một lần để báo thức theo ca tiếp tục reo. Lịch ca, báo thức và cài đặt của bạn vẫn an toàn và hoạt động lại ngay khi mở khóa.';

  @override
  String get purchaseAlarmsWontRing => 'Cho đến lúc đó, báo thức sẽ không reo.';

  @override
  String get purchaseUnlock => 'Mở khóa toàn bộ';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'Mở khóa toàn bộ · $price';
  }

  @override
  String get purchaseRestore => 'Khôi phục giao dịch mua';

  @override
  String get purchaseOneTime => 'Mua một lần. Không đăng ký định kỳ.';

  @override
  String get purchaseUnavailable =>
      'Hiện không thể mua. Hãy kiểm tra kết nối và thử lại.';

  @override
  String get purchaseCheckingPrevious => 'Đang tìm giao dịch mua trước đây…';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsLegalAbout => 'PHÁP LÝ & GIỚI THIỆU';

  @override
  String get settingsHelp => 'TRỢ GIÚP';

  @override
  String get settingsHowItWorks => 'Cách hoạt động';

  @override
  String get settingsReplayTourShake =>
      'Xem lại hướng dẫn: tô lịch ca + lắc để tắt';

  @override
  String get settingsReplayTour => 'Xem lại hướng dẫn: tô lịch ca';

  @override
  String get settingsScreenTips => 'Hiện mẹo trên màn hình';

  @override
  String get settingsScreenTipsSub =>
      'Mẹo hiện một lần trên mỗi màn hình. Bật để xem lại.';

  @override
  String get settingsFullAccess => 'TOÀN QUYỀN SỬ DỤNG';

  @override
  String get settingsFullAccessUnlocked => 'Đã mở khóa toàn bộ';

  @override
  String get settingsThanks => 'Cảm ơn bạn đã ủng hộ Rostrik.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Dùng thử miễn phí: còn $days ngày',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'Đã hết thời gian dùng thử';

  @override
  String get settingsUnlockPitch =>
      'Mở khóa một lần để báo thức theo ca vẫn reo khi hết dùng thử: mua một lần, không bao giờ là gói đăng ký.';

  @override
  String get settingsRestore => 'Khôi phục';

  @override
  String get settingsBrandTagline =>
      'Báo thức cho người làm ngoài giờ hành chính';

  @override
  String get settingsLeadTime => 'Thời gian báo trước';

  @override
  String get settingsLeadTimeSub =>
      'Báo thức reo trước mỗi ca một khoảng thời gian này.';

  @override
  String get settingsSnoozeDuration => 'Thời gian báo lại';

  @override
  String get settingsSnoozeDurationSub =>
      'Nút Báo lại dời báo thức đang reo bao lâu.';

  @override
  String get settingsMinutesLabel => 'Phút';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m phút',
    );
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => 'CHU KỲ CA';

  @override
  String get settingsShiftCyclesSub => 'Lịch ca bạn đã tạo từ mẫu có sẵn.';

  @override
  String get settingsAddShiftCycle => 'Thêm chu kỳ ca';

  @override
  String get settingsNoRosters => 'Bạn chưa tạo lịch ca nào.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'Sửa';

  @override
  String get commonDelete => 'Xóa';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get settingsDeleteRosterTitle => 'Xóa lịch ca?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ca',
    );
    return 'Xóa \"$label\"? Các báo thức đang chờ sẽ bị hủy và $_temp0 sẽ bị xóa.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return 'Đã xóa \"$label\"';
  }

  @override
  String get commonActive => 'Đang dùng';

  @override
  String get commonUpcoming => 'Sắp tới';

  @override
  String get commonPast => 'Đã qua';

  @override
  String get settingsWorkHistory => 'LỊCH SỬ LÀM VIỆC';

  @override
  String get settingsWorkHistorySub =>
      'Xem và xuất các ca tùy chỉnh đã làm xong để đối chiếu bảng lương.';

  @override
  String get settingsViewWorkHistory => 'Xem & xuất lịch sử làm việc';

  @override
  String get settingsPreferences => 'TÙY CHỌN';

  @override
  String get settingsPreferencesSub =>
      'Cách lịch làm việc hiển thị trong ứng dụng.';

  @override
  String get settingsAppearance => 'Giao diện';

  @override
  String get settingsThemeSystem => 'Hệ thống';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsThemeSub =>
      'Tối là giao diện mặc định của Rostrik. Sáng dùng tông màu kem ấm.';

  @override
  String get settings24h => 'Dùng định dạng 24 giờ';

  @override
  String get settings24hOn => 'Giờ hiển thị như 14:30';

  @override
  String get settings24hOff => 'Giờ hiển thị như 02:30 PM';

  @override
  String get settingsWeekStartTitle => 'Lịch bắt đầu từ thứ Hai';

  @override
  String get settingsWeekStartMon => 'Tuần bắt đầu từ thứ Hai';

  @override
  String get settingsWeekStartSun => 'Tuần bắt đầu từ Chủ nhật';

  @override
  String get settingsTimelineOpensOn => 'Lịch trình mở ở chế độ';

  @override
  String get commonList => 'Danh sách';

  @override
  String get commonMonth => 'Tháng';

  @override
  String get settingsCalendar => 'LỊCH';

  @override
  String get settingsCalendarSync => 'Đồng bộ với Google / Lịch trên thiết bị';

  @override
  String get settingsCalendarSyncSub =>
      'Tự động sao chép các ca vào lịch riêng \"Rostrik Roster\" trên điện thoại.';

  @override
  String get settingsCalSyncOff =>
      'Đã tắt đồng bộ lịch. Các sự kiện sắp tới của \"Rostrik Roster\" đã được xóa.';

  @override
  String get settingsCalSyncMirroring =>
      'Đang sao chép lịch ca vào lịch \"Rostrik Roster\"…';

  @override
  String get settingsCalPermNeeded =>
      'Cần quyền truy cập lịch để đồng bộ lịch ca.';

  @override
  String get settingsCalBlocked =>
      'Quyền truy cập lịch bị chặn. Hãy bật trong cài đặt hệ thống để đồng bộ.';

  @override
  String get settingsCalOpenSettings => 'Cài đặt';

  @override
  String get settingsCalUnsupported =>
      'Thiết bị này không hỗ trợ đồng bộ lịch.';

  @override
  String get settingsDangerZone => 'VÙNG NGUY HIỂM';

  @override
  String get settingsDangerZoneSub =>
      'Xóa lịch ca, báo thức và cài đặt, rồi bắt đầu thiết lập lại từ đầu.';

  @override
  String get settingsResetAppData => 'Đặt lại dữ liệu ứng dụng';

  @override
  String get settingsResetTitle => 'Đặt lại ứng dụng?';

  @override
  String get settingsResetBody =>
      'Bạn chắc chứ? Lịch ca, báo thức và cài đặt sẽ bị xóa.';

  @override
  String get settingsResetConfirm => 'Đặt lại';

  @override
  String get dashNoUpcomingShifts => 'Không có ca sắp tới';

  @override
  String get dashEnjoyTimeOff => 'Tận hưởng thời gian nghỉ nhé.';

  @override
  String get dashInProgress => 'ĐANG DIỄN RA';

  @override
  String get dashRotation => 'Xoay ca';

  @override
  String get dashAlarmsCantRing => 'Báo thức không thể reo ổn định';

  @override
  String get dashNotifsOffIssue =>
      'Thông báo đang tắt: báo thức đang reo không thể hiện màn hình báo thức hay tắt được.';

  @override
  String get dashOpenSettings => 'Mở cài đặt';

  @override
  String get dashExactBlockedIssue =>
      'Báo thức chính xác bị chặn: không thể hẹn giờ báo thức nào.';

  @override
  String get dashAllow => 'Cho phép';

  @override
  String get dashSlideToSkip => 'Trượt để bỏ qua báo thức này';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Trượt để bỏ qua $count báo thức',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'Tắt báo thức sắp tới · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bỏ qua $count báo thức của ca này',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'Giữ báo thức';

  @override
  String get dashMyRotation => 'Xoay ca của tôi';

  @override
  String get dashCalendarUpcoming => 'Lịch & ca sắp tới';

  @override
  String get dashNextShifts => 'Ca tiếp theo';

  @override
  String get dashOpenTimeline => 'Mở Lịch trình';

  @override
  String heroStartsIn(String countdown) {
    return 'Bắt đầu sau $countdown';
  }

  @override
  String heroEndsIn(String countdown) {
    return 'Kết thúc sau $countdown';
  }

  @override
  String get heroStartsInPrefix => 'Bắt đầu sau';

  @override
  String get heroEndsInPrefix => 'Kết thúc sau';

  @override
  String heroStartsTodayAt(String time) {
    return 'Bắt đầu hôm nay lúc $time';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'Đã bắt đầu hôm nay lúc $time';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'Bắt đầu ngày mai lúc $time';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'Đã bắt đầu hôm qua lúc $time';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'Bắt đầu hôm qua lúc $time';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return 'Bắt đầu $date lúc $time';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return 'Đã bắt đầu $date lúc $time';
  }

  @override
  String get shiftTypeDayShift => 'Ca ngày';

  @override
  String get shiftTypeAfternoonShift => 'Ca chiều';

  @override
  String get shiftTypeNightShift => 'Ca đêm';

  @override
  String heroDayXofY(int x, int y, String label) {
    return 'Ngày $x/$y – $label';
  }

  @override
  String get heroOffTomorrow => 'Mai được nghỉ';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Nghỉ sau $days ngày',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'Mai đi làm lại';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Đi làm lại sau $days ngày',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'Ngày nghỉ';

  @override
  String durationDayShort(int d) {
    return '${d}ng';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '${d}ng ${h}g';
  }

  @override
  String get alarmsTitle => 'Báo thức';

  @override
  String get alarmsAddTooltip => 'Thêm báo thức';

  @override
  String get alarmsSortTooltip => 'Sắp xếp báo thức';

  @override
  String get alarmsSortByTime => 'Theo giờ';

  @override
  String get alarmsSortByShiftType => 'Theo loại ca';

  @override
  String get alarmsEmptyTitle => 'Chưa có báo thức.';

  @override
  String get alarmsEmptyBody => 'Chạm + để thêm.';

  @override
  String get alarmsNextAlarm => 'BÁO THỨC TIẾP THEO';

  @override
  String get alarmsHolidayMode => 'Chế độ nghỉ phép';

  @override
  String get alarmsHolidayModeSub =>
      'Báo thức đang tạm dừng: sẽ không có gì reo.';

  @override
  String get alarmsNoUpcoming => 'Không có báo thức ca sắp tới';

  @override
  String get alarmsNoUpcomingSub =>
      'Thêm báo thức theo xoay ca, hoặc tạo lịch ca.';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'cho ca $type · $day';
  }

  @override
  String get commonToday => 'Hôm nay';

  @override
  String get commonTomorrow => 'Ngày mai';

  @override
  String get alarmsOffWontRing => 'Tắt: sẽ không reo';

  @override
  String get alarmsNoUpcomingRing => 'Chưa hẹn lần reo nào';

  @override
  String alarmsNextRing(String day, String time) {
    return 'Lần reo tới: $day lúc $time';
  }

  @override
  String get alarmsSwipeToDelete => 'Vuốt để xóa';

  @override
  String get alarmsRingsOnceAutoDelete => 'Reo một lần · tự xóa';

  @override
  String get alarmsRingsOnce => 'Chỉ reo một lần';

  @override
  String get alarmsYourShift => 'ca của bạn';

  @override
  String alarmsShiftsOfType(String type) {
    return 'ca $type';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'Giờ cố định · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$lead trước $shift · mặc định';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$lead trước $shift';
  }

  @override
  String get createEditAlarm => 'Sửa báo thức';

  @override
  String get createNewAlarm => 'Báo thức mới';

  @override
  String get createDefaultLabel => 'Thức dậy';

  @override
  String get createFallbackLabel => 'Báo thức';

  @override
  String get createPickBecomesDefault =>
      'Lựa chọn của bạn sẽ là mặc định cho báo thức mới.';

  @override
  String get createSelectFromFiles => 'Chọn từ Tệp';

  @override
  String get createFilesSub => 'Chọn tệp âm thanh đã lưu trên thiết bị';

  @override
  String get createSelectSystemTone => 'Chọn nhạc chuông hệ thống';

  @override
  String get createSystemToneSub => 'Chọn từ âm báo thức của thiết bị';

  @override
  String get createAlarmTiming => 'Thời điểm báo thức';

  @override
  String get createLeadTimeMode => 'Báo trước';

  @override
  String get createExactTimeMode => 'Giờ cố định';

  @override
  String createFiresAt(String time) {
    return 'Reo lúc $time';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return '$lead trước giờ vào ca';
  }

  @override
  String get createLinkedShift => 'Ca liên kết';

  @override
  String get createRepeatOn => 'Lặp lại vào';

  @override
  String get createLabelField => 'Nhãn';

  @override
  String get createLabelHint => 'vd. Thức dậy';

  @override
  String get createCriticalShift => 'Ca quan trọng';

  @override
  String get createCriticalShiftSub => 'Lắc để tắt · giữ 3 giây để dự phòng';

  @override
  String get createRingtone => 'Nhạc chuông';

  @override
  String get commonStop => 'Dừng';

  @override
  String get commonPlay => 'Phát';

  @override
  String get createVibrate => 'Rung';

  @override
  String get createRepeat => 'Lặp lại';

  @override
  String get createRepeatRotation => 'Xoay ca';

  @override
  String get createRepeatWeekly => 'Hằng tuần';

  @override
  String get createRepeatOneTime => 'Một lần';

  @override
  String get createPickOneDay => 'Chọn ít nhất một ngày';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonSaveChanges => 'Lưu thay đổi';

  @override
  String get createTimeBeforeShift => 'Thời gian trước ca';

  @override
  String get commonOk => 'OK';

  @override
  String get sleepTitle => 'Giấc ngủ';

  @override
  String get sleepTargetHeader => 'MỤC TIÊU NGỦ';

  @override
  String get sleepTargetSub =>
      'Bạn muốn ngủ bao nhiêu giờ. Rostrik đếm ngược từ báo thức tiếp theo để đặt giờ đi ngủ tối nay.';

  @override
  String get sleepRemindersHeader => 'NHẮC NHỞ';

  @override
  String get sleepWindDownHeader => 'THƯ GIÃN TRƯỚC KHI NGỦ';

  @override
  String get sleepWindDownSub =>
      'Lời nhắc thư giãn đến trước giờ đi ngủ bao lâu.';

  @override
  String get sleepSoundsHeader => 'ÂM THANH GIẤC NGỦ';

  @override
  String get sleepSoundsSub =>
      'Tiếng ồn trắng & nâu giúp dễ ngủ. Chọn hẹn giờ tắt rồi chạm vào một âm thanh.';

  @override
  String get sleepNothingToPlan => 'Tối nay không có gì cần lên kế hoạch';

  @override
  String get sleepNothingToPlanSub =>
      'Thêm một ca vào lịch và Rostrik sẽ xếp giờ đi ngủ phù hợp với lần thức dậy tiếp theo.';

  @override
  String get sleepTransitionDay => 'NGÀY CHUYỂN CA';

  @override
  String get sleepTransitionTitle => 'Mai là ca đêm. Bạn có thể ngủ muộn hơn.';

  @override
  String get sleepTransitionBody =>
      'Hôm nay là ngày chuyển ca: bạn được nghỉ trước chuỗi ca đêm nên không có báo thức sớm. Hãy nghỉ ngơi thêm và để cơ thể đi ngủ muộn hơn tối nay.';

  @override
  String get sleepRestRecovery => 'NGHỈ NGƠI & HỒI PHỤC';

  @override
  String get sleepNoEarlyAlarm => 'Không có báo thức sớm';

  @override
  String get sleepRestBody =>
      'Ca tiếp theo còn hơn một ngày nữa nên tối nay không có giờ thức cần tính. Cứ ngủ theo nhịp của bạn và hồi phục; Rostrik sẽ lên kế hoạch khi ca đến gần.';

  @override
  String get sleepTonightsPlan => 'KẾ HOẠCH TỐI NAY';

  @override
  String get sleepTargetBedtime => 'Giờ đi ngủ';

  @override
  String get sleepWindDownStat => 'Thư giãn';

  @override
  String get sleepWakeUpStat => 'Thức dậy';

  @override
  String get sleepDurationStat => 'Thời lượng';

  @override
  String get sleepBedtimeReminder => 'Nhắc đi ngủ';

  @override
  String sleepNudgeAtBedtime(String time) {
    return 'Nhắc tôi lúc $time để đi ngủ';
  }

  @override
  String get sleepBedtimeSub => 'Một lời nhắc khi đến giờ đi ngủ';

  @override
  String get sleepWindDownReminder => 'Nhắc thư giãn';

  @override
  String sleepNudgeAtWindDown(String time) {
    return 'Nhắc tôi lúc $time để bắt đầu thư giãn';
  }

  @override
  String get sleepWindDownReminderSub => 'Nhắc sớm hơn để bắt đầu thư giãn';

  @override
  String get commonOff => 'Tắt';

  @override
  String get sleepSoundWhiteNoise => 'Tiếng ồn trắng';

  @override
  String get sleepSoundPinkNoise => 'Tiếng ồn hồng';

  @override
  String get sleepSoundBrownNoise => 'Tiếng ồn nâu';

  @override
  String get sleepSoundFan => 'Quạt';

  @override
  String get sleepSoundOcean => 'Biển';

  @override
  String get sleepSoundRain => 'Mưa';

  @override
  String get manageTitle => 'Quản lý';

  @override
  String get manageRosterTools => 'CÔNG CỤ LỊCH CA';

  @override
  String get manageRosterToolsSub =>
      'Tạo và điều chỉnh các ca quyết định báo thức và kế hoạch ngủ.';

  @override
  String get manageGenerateRotation => 'Tạo xoay ca';

  @override
  String get manageGenerateRotationSub => 'Tạo mẫu ca lặp lại từ mẫu có sẵn.';

  @override
  String get manageAddCustomShift => 'Thêm ca lẻ';

  @override
  String get manageAddCustomShiftSub => 'Thêm một ca riêng lẻ vào lịch.';

  @override
  String get manageMarkLeave => 'Đánh dấu nghỉ phép';

  @override
  String get manageMarkLeaveSub =>
      'Tô một lượt những ngày bạn nghỉ (phép năm, ốm).';

  @override
  String get managePauseSchedule => 'Tạm dừng lịch';

  @override
  String get managePausedSub =>
      'Chế độ nghỉ phép BẬT: báo thức đã tắt tiếng, lịch ca vẫn an toàn.';

  @override
  String get manageNotPausedSub =>
      'Chế độ nghỉ phép: tắt tiếng báo thức khi bạn không có ca.';

  @override
  String get markLeaveTitle => 'Đánh dấu nghỉ';

  @override
  String get markLeaveIntro =>
      'Chạm vào những ngày nghỉ, chọn lý do rồi áp dụng. Báo thức những ngày đó sẽ không reo và lịch ca vẫn giữ nguyên.';

  @override
  String get leaveAnnual => 'Nghỉ phép năm';

  @override
  String get leaveSick => 'Nghỉ ốm';

  @override
  String get leavePublicHoliday => 'Ngày lễ';

  @override
  String get markLeaveReason => 'Lý do';

  @override
  String get markLeaveFallbackReason => 'nghỉ phép';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã đánh dấu $count ca là $reason.',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => 'Chọn ngày để đánh dấu';

  @override
  String get markLeaveNoShifts => 'Không có ca vào những ngày đó';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Áp dụng cho $count ca',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => 'Lịch sử làm việc';

  @override
  String get workHistoryExportTooltip => 'Xuất lịch sử';

  @override
  String workHistoryExportFailed(String error) {
    return 'Không xuất được lịch sử: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã làm $count ca',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours giờ';
  }

  @override
  String get commonPaused => 'Tạm dừng';

  @override
  String workHistoryPausedReason(String reason) {
    return 'Tạm dừng · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'Xoay ca';

  @override
  String get workHistoryAdHocBadge => 'Ca lẻ';

  @override
  String get workHistoryEmptyTitle => 'Chưa có ca nào hoàn thành';

  @override
  String get workHistoryEmptyBody =>
      'Các ca bạn đã làm, cả xoay ca lẫn ca tùy chỉnh, sẽ hiện ở đây khi kết thúc, sẵn sàng xuất ra để đối chiếu bảng lương.';

  @override
  String get workHistoryShareSubject => 'Lịch sử làm việc Rostrik';

  @override
  String get workHistoryShareText => 'Lịch sử làm việc tôi xuất từ Rostrik.';

  @override
  String get shiftEdAddShift => 'Thêm ca';

  @override
  String get shiftEdEditShift => 'Sửa ca';

  @override
  String get shiftEdDate => 'Ngày';

  @override
  String get shiftEdPickDate => 'Chọn ngày';

  @override
  String get shiftEdStarts => 'Bắt đầu';

  @override
  String get shiftEdEnds => 'Kết thúc';

  @override
  String get shiftEdPickTime => 'Chọn giờ';

  @override
  String get shiftEdEndsNextDay => 'Kết thúc vào ngày hôm sau';

  @override
  String get shiftEdPauseTitle => 'Tạm dừng / hủy ca này';

  @override
  String get shiftEdPausedSub =>
      'Báo thức sẽ không reo. Ca vẫn nằm trên lịch để lưu lại.';

  @override
  String get shiftEdNotPausedSub =>
      'Đánh dấu ngày nghỉ (ốm, phép, lễ) mà không cần xóa.';

  @override
  String get shiftEdReasonOptional => 'Lý do (không bắt buộc)';

  @override
  String get dayShifts => 'Ca làm';

  @override
  String get dayActivities => 'Hoạt động';

  @override
  String get dayAddAnotherShift => 'Thêm ca khác';

  @override
  String get dayAddActivity => 'Thêm hoạt động';

  @override
  String get dayAddActivitySub => 'Sự kiện, việc cần làm hoặc sinh nhật';

  @override
  String get dayReminder => 'Lời nhắc';

  @override
  String get actEditActivity => 'Sửa hoạt động';

  @override
  String get actLeadAtTime => 'Đúng giờ';

  @override
  String get actLead10Min => 'Trước 10 phút';

  @override
  String get actLead30Min => 'Trước 30 phút';

  @override
  String get actLead1Hour => 'Trước 1 giờ';

  @override
  String get actLead1Day => 'Trước 1 ngày';

  @override
  String get actEvent => 'Sự kiện';

  @override
  String get actTask => 'Việc cần làm';

  @override
  String get actBirthday => 'Sinh nhật';

  @override
  String get actTitleField => 'Tiêu đề';

  @override
  String get actAllDay => 'Cả ngày';

  @override
  String get actTimeField => 'Giờ';

  @override
  String get actRemindMe => 'Nhắc tôi';

  @override
  String get actRemindMeSub =>
      'Một thông báo nhẹ nhàng, tách biệt với báo thức ca.';

  @override
  String get actRemindAt => 'Nhắc lúc';

  @override
  String get actReminderPassed =>
      'Thời điểm đó đã qua: lời nhắc này sẽ không hiện.';

  @override
  String get actNoteOptional => 'Ghi chú (không bắt buộc)';

  @override
  String get actCompleted => 'Đã xong';

  @override
  String get tipDashboardTitle => 'Tổng quan của bạn';

  @override
  String get tipDashboardBody =>
      'Trung tâm của bạn. Xem ca tiếp theo với đồng hồ đếm ngược và vị trí của bạn trong vòng xoay ca. Chạm một ô để xem chi tiết.';

  @override
  String get tipTimelineTitle => 'Toàn bộ lịch ca';

  @override
  String get tipTimelineBody =>
      'Chuyển giữa Danh sách và lịch Tháng ở phía trên. Chạm vào bất kỳ ngày nào để sửa ca hoặc thêm sự kiện, việc cần làm, sinh nhật.';

  @override
  String get tipManageTitle => 'Tạo & điều chỉnh';

  @override
  String get tipManageBody =>
      'Tạo lịch xoay ca, thêm ca lẻ (tăng ca) hoặc tạm dừng toàn bộ lịch khi nghỉ phép, tất cả ở đây.';

  @override
  String get tipAlarmsTitle => 'Báo thức của bạn';

  @override
  String get tipAlarmsBody =>
      'Mọi báo thức do các ca tạo ra, cùng báo thức bạn tự thêm. Chạm vào một báo thức để đổi giờ hoặc nhạc chuông, hoặc biến nó thành báo thức Ca quan trọng tắt bằng cách lắc.';

  @override
  String get tipSleepTitle => 'Kế hoạch ngủ';

  @override
  String get tipSleepBody =>
      'Kế hoạch thư giãn theo lịch ca: đặt mục tiêu ngủ và bước vào ca tiếp theo thật tỉnh táo.';

  @override
  String get tipReplayHint =>
      'Xem lại bất cứ lúc nào tại Cài đặt › Cách hoạt động.';

  @override
  String get tipDontShow => 'Không hiện mẹo';

  @override
  String get tipGotIt => 'Đã hiểu';

  @override
  String get timelineListView => 'Danh sách';

  @override
  String get timelineMonthView => 'Tháng';

  @override
  String get shiftTypeAftShort => 'Chiều';

  @override
  String get timelineNoShifts => 'Chưa có ca nào. Chạm + để thêm.';

  @override
  String timelineNoMatch(String filter) {
    return 'Không có ca nào khớp bộ lọc $filter.';
  }

  @override
  String get timelineRestDay => 'Ngày nghỉ';

  @override
  String timelineRestDayReason(String reason) {
    return 'Ngày nghỉ · $reason';
  }

  @override
  String get timelineAllDay => 'Cả ngày';

  @override
  String get calLegendPausedLeave => 'Tạm dừng / Nghỉ phép';

  @override
  String get calLegendActivity => 'Hoạt động';

  @override
  String get filterAll => 'Tất cả';

  @override
  String get filterWork => 'Làm việc';

  @override
  String get criticalHoldToDismiss => 'Hoặc nhấn giữ để tắt';

  @override
  String get patternChoosePattern => 'Chọn mẫu';

  @override
  String get patternRotatingSwings => 'Xoay ca ngày – đêm';

  @override
  String get patternDaySwings => 'Chỉ ca ngày';

  @override
  String get patternNightSwings => 'Chỉ ca đêm';

  @override
  String get patternShiftTimes => 'Giờ làm các ca';

  @override
  String get patternGenerate => 'Đặt Ngày 1 & tạo lịch';

  @override
  String get patternSelectDay1 => 'Chọn Ngày 1 tiếp theo';

  @override
  String patternDay1Hint(String label) {
    return 'Ngày đầu tiên của khối ca $label';
  }

  @override
  String get patternNextDay1 => 'Ngày 1 tiếp theo';

  @override
  String get patternUseThisDate => 'Dùng ngày này';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã tạo $count ca',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'Tạo lịch thất bại: $error';
  }

  @override
  String get patternFirstBlockFallback => 'đầu tiên';

  @override
  String get patternBuildCustom => 'Tạo lịch ca tùy chỉnh';

  @override
  String get patternBuildCustomSub =>
      'Không có mẫu phù hợp? Tự ghép các khối ca.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ngày',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n chiều',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n đêm',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '$n nghỉ';
  }

  @override
  String get builderNewRoster => 'Lịch ca mới';

  @override
  String get builderEditRoster => 'Sửa lịch ca';

  @override
  String get builderNewSub => 'Thiết lập kiểu xoay ca của bạn';

  @override
  String get builderEditSub => 'Thay đổi và thay thế lịch ca đã lưu này';

  @override
  String get builderNameHint => 'Tên lịch (vd. Xoay ca 14 ngày)';

  @override
  String get builderCycleLength => 'ĐỘ DÀI CHU KỲ';

  @override
  String get builderStartDate => 'NGÀY BẮT ĐẦU';

  @override
  String get builderShiftBlocks => 'CÁC KHỐI CA';

  @override
  String get builderAddShiftBlock => 'Thêm khối ca';

  @override
  String get builderCreateRoster => 'Tạo lịch ca';

  @override
  String get builderSaveChanges => 'Lưu thay đổi';

  @override
  String get builderReplaceWarning =>
      'Lưu sẽ thay thế lịch ca này. Các đánh dấu nghỉ phép / ngày nghỉ đã tô trên đó sẽ bị đặt lại.';

  @override
  String get builderBackToOptions => 'Quay lại các lựa chọn';

  @override
  String get builderOrImport => 'HOẶC NHẬP LỊCH CA SẴN CÓ';

  @override
  String get builderImportViaAi => 'Nhập bằng AI';

  @override
  String get builderScanning => 'Đang quét…';

  @override
  String get builderScanInstead => 'Quét ảnh lịch ca thay thế';

  @override
  String get builderCustomChip => 'Khác';

  @override
  String get builderCycleLengthLabel => 'Độ dài chu kỳ';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ngày',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'Chọn ngày';

  @override
  String get builderNoBlocksYet => 'Chưa có khối nào';

  @override
  String get builderNoBlocksSub => 'Thêm khối ca để xác định vòng xoay ca';

  @override
  String builderDaysLine(String ranges) {
    return 'Ngày $ranges';
  }

  @override
  String get builderEditBlock => 'Sửa khối';

  @override
  String get builderRemoveBlock => 'Xóa khối';

  @override
  String get builderPickRosterStart => 'Chọn ngày bắt đầu lịch ca';

  @override
  String get builderPickScanStart => 'Chọn ngày bắt đầu cho lịch ca đã quét';

  @override
  String get builderScanCamera => 'Quét bằng máy ảnh';

  @override
  String get builderImportScreenshot => 'Nhập ảnh chụp màn hình';

  @override
  String builderScanFailed(String error) {
    return 'Quét thất bại: $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'Không nhận diện được giờ làm. Hãy cắt ảnh sát bảng hơn.';

  @override
  String get builderCustomRosterFallback => 'Lịch ca tùy chỉnh';

  @override
  String get builderScannedRosterFallback => 'Lịch ca đã quét';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã cập nhật lịch: đã lên $count ca',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã tạo: đã lên $count ca',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'Không tạo được lịch ca: $error';
  }

  @override
  String get builderRosterImported => 'Đã nhập lịch ca vào lịch của bạn';

  @override
  String builderCouldNotImport(String error) {
    return 'Không nhập được lịch ca: $error';
  }

  @override
  String get blockAddTitle => 'Thêm khối ca';

  @override
  String get blockEditTitle => 'Sửa khối ca';

  @override
  String get blockStart => 'Bắt đầu';

  @override
  String get blockEnd => 'Kết thúc';

  @override
  String get blockTapDays => 'Chạm vào những ngày có ca này';

  @override
  String get blockUntappedOff => 'Ngày không chạm là ngày nghỉ.';

  @override
  String blockOverlap(String ranges) {
    return 'Giờ này trùng với một ca khác vào ngày $ranges. Hãy đổi giờ hoặc những ngày đó.';
  }

  @override
  String get blockAdd => 'Thêm khối';

  @override
  String get blockSave => 'Lưu khối';

  @override
  String get aiPromptCopied =>
      'Đã sao chép câu lệnh! Dán vào ứng dụng AI cùng với lịch ca của bạn.';

  @override
  String get aiNothingToPaste => 'Bộ nhớ tạm không có gì để dán.';

  @override
  String get aiNoValidShifts =>
      'Không phát hiện ca hợp lệ. Hãy chắc rằng bạn đã dùng câu lệnh AI đã sao chép.';

  @override
  String get aiStep1 => 'Sao chép câu lệnh';

  @override
  String get aiCopied => 'Đã sao chép!';

  @override
  String get aiCopyPrompt => 'Sao chép câu lệnh AI';

  @override
  String get aiStep1Sub =>
      'Dán vào ChatGPT, Gemini hoặc bất kỳ ứng dụng AI nào, thêm nội dung lịch ca hoặc ảnh/ảnh chụp màn hình rồi gửi.';

  @override
  String get aiStep2 => 'Dán câu trả lời của AI';

  @override
  String get aiPaste => 'Dán';

  @override
  String get aiParsePreview => 'Phân tích & xem trước';

  @override
  String get aiStep3 => 'Kiểm tra các ca phát hiện được';

  @override
  String get aiStep3Sub =>
      'Chạm vào nhãn để đổi giữa Ngày, Chiều và Đêm nếu AI nhận sai.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nhập $count ngày',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'Biến bất kỳ nội dung lịch ca nào thành ca làm với sự trợ giúp của ứng dụng AI.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
    );
    return '$_temp0 · $working ngày làm · $off ngày nghỉ';
  }

  @override
  String get draftReviewTitle => 'Kiểm tra lịch ca đã quét';

  @override
  String draftRemovedDay(String date) {
    return 'Đã xóa $date';
  }

  @override
  String get draftUndo => 'Hoàn tác';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã lưu $count ngày vào lịch ca',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'Tên lịch ca';

  @override
  String get draftScannedImage => 'Ảnh đã quét';

  @override
  String get draftScannedImageSub => 'Chạm vào ảnh để phóng to và so sánh';

  @override
  String get draftImageError => 'Không hiển thị được ảnh đã quét.';

  @override
  String get draftRemove => 'Xóa';

  @override
  String get draftNoEndTime =>
      'Quét được nhưng thiếu giờ kết thúc: hãy đặt để có thể lưu.';

  @override
  String get draftTime => 'Giờ';

  @override
  String get draftSetEnd => 'Đặt giờ kết thúc';

  @override
  String get draftConfirmSave => 'Xác nhận & lưu';

  @override
  String notifBeforeYourShift(String type) {
    return 'Trước ca $type của bạn';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind lúc $time';
  }

  @override
  String get notifWindDownTitle => 'Đến giờ thư giãn 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'Rời xa màn hình: giờ đi ngủ là $time.';
  }

  @override
  String get notifWindDownBody =>
      'Rời xa màn hình và bắt đầu thư giãn cho buổi tối.';

  @override
  String get notifBedtimeTitle => 'Đến giờ ngủ 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return 'Đi ngủ để có ~$hours giờ trước $shift: thức dậy lúc $time.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return 'Đi ngủ để đạt mục tiêu ngủ $hours giờ.';
  }

  @override
  String get notifShiftDay => 'ca ngày';

  @override
  String get notifShiftAfternoon => 'ca chiều';

  @override
  String get notifShiftNight => 'ca đêm';

  @override
  String get notifShiftGeneric => 'ca làm';

  @override
  String get notifTrialEndsTitle =>
      'Bản dùng thử Rostrik kết thúc vào ngày mai';

  @override
  String get notifTrialEndsBody =>
      'Mở khóa toàn bộ để báo thức theo ca tiếp tục reo.';

  @override
  String seedWakeUpLabel(String type) {
    return 'Thức dậy ca $type';
  }

  @override
  String get seedShiftGeneric => 'Ca';

  @override
  String commonListAnd(String items, String last) {
    return '$items và $last';
  }

  @override
  String get soundClassic => 'Cổ điển';

  @override
  String get soundSiren => 'Còi hú';

  @override
  String get soundDigital => 'Điện tử';

  @override
  String get soundChime => 'Chuông gió';

  @override
  String get patternFirstResponder => 'Chuẩn lực lượng cứu hộ';

  @override
  String get ocrCropTitle => 'CHỈ cắt hàng của bạn, đừng lấy cả nhóm';

  @override
  String get draftNameHint => 'vd. Lịch ca tháng 5';
}
