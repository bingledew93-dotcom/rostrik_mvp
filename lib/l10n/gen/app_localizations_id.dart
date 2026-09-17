// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Rostrik';

  @override
  String get legalTitle => 'Sebelum kamu mulai';

  @override
  String get legalBodyOsCaveat =>
      'Rostrik dibuat untuk membangunkanmu di setiap shift. Terus terang saja: di ponsel mana pun, sistem operasi, bukan aplikasi, yang punya keputusan akhir. Dalam kasus yang jarang, sistem bisa menunda atau membisukan aplikasi alarm apa pun (penghemat baterai agresif, paksa berhenti, atau tepat setelah pembaruan sistem).';

  @override
  String get legalBodyBackupAdvice =>
      'Untuk shift yang benar-benar tidak boleh terlewat, pasang alarm kedua sebagai cadangan. Ini kebiasaan baik untuk alarm apa pun, termasuk alarm bawaan ponselmu.';

  @override
  String get legalReviewAndAccept => 'Silakan baca dan setujui:';

  @override
  String get legalPrivacyPolicy => 'Kebijakan Privasi';

  @override
  String get legalTermsOfUse => 'Ketentuan Penggunaan';

  @override
  String get legalConsentCheckbox =>
      'Saya paham sistem operasi dapat memengaruhi aplikasi alarm apa pun, dan saya menyetujui Kebijakan Privasi serta Ketentuan Penggunaan.';

  @override
  String get legalAgreeContinue => 'Setuju & Lanjut';

  @override
  String get legalUpdatedTitle => 'Kami memperbarui ketentuan kami';

  @override
  String get legalUpdatedBody =>
      'Kebijakan Privasi dan Ketentuan Penggunaan kami telah berubah. Luangkan waktu sejenak untuk membacanya sebelum melanjutkan.';

  @override
  String get legalUpdatedAccept => 'Saya sudah membaca dan menyetujui';

  @override
  String get commonSaving => 'Menyimpan…';

  @override
  String get commonCouldNotOpenLink => 'Tautan tidak dapat dibuka.';

  @override
  String get welcomeTagline => 'Jam alarm pintar untuk pekerja shift.';

  @override
  String get welcomeSubTagline =>
      'Alarm yang mengikuti jadwal shift bergilirmu, bukan cuma hari kerja.';

  @override
  String welcomeTrialTitle(int days) {
    return 'Uji coba gratis $days hari';
  }

  @override
  String get welcomeTrialBody =>
      'Akses penuh ke semua fitur, tanpa kartu. Setelah itu cukup sekali beli, tidak pernah langganan.';

  @override
  String get welcomeGetStarted => 'Mulai';

  @override
  String get welcomeSkip => 'Lewati / Atur nanti';

  @override
  String get welcomeTimeFormat => 'Format waktu';

  @override
  String get welcomeWeekStarts => 'Awal minggu';

  @override
  String get common12h => '12 jam';

  @override
  String get common24h => '24 jam';

  @override
  String get commonSundayShort => 'Min';

  @override
  String get commonMondayShort => 'Sen';

  @override
  String get rosterTypeTitle => 'Pilih jenis jadwal';

  @override
  String get rosterTypeQuestion => 'Seperti apa jadwal shiftmu?';

  @override
  String get rosterTypeDay => 'Shift Siang';

  @override
  String get rosterTypeNight => 'Shift Malam';

  @override
  String get rosterTypeRotating => 'Bergilir';

  @override
  String get rosterTypeCustom => 'Kustom';

  @override
  String get commonContinue => 'Lanjut';

  @override
  String get commonComingSoon => 'Segera hadir';

  @override
  String get permsTitle => 'Izin';

  @override
  String get permsIntro =>
      'Rostrik butuh beberapa izin agar alarm berbunyi dengan andal. Kamu bisa mengubahnya nanti di pengaturan sistem.';

  @override
  String get permsNotifications => 'Notifikasi';

  @override
  String get permsNotificationsSub =>
      'Diperlukan untuk menampilkan layar bangun.';

  @override
  String get permsExactAlarms => 'Alarm Tepat Waktu';

  @override
  String get permsExactAlarmsSub =>
      'Membuat alarm berbunyi tepat pada waktu yang dijadwalkan.';

  @override
  String get permsBatteryUnrestricted => 'Baterai Tanpa Batasan';

  @override
  String get permsBatteryGrantedSub =>
      'Alarm terlindung dari optimalisasi baterai.';

  @override
  String get permsBatteryDeniedSub =>
      'Beberapa ponsel menutup aplikasi di latar belakang. Ketuk untuk memperbaiki.';

  @override
  String get permsUnrestrictedBadge => 'Tanpa batasan';

  @override
  String get batteryDialogTitle => 'Jaga alarm tetap aktif';

  @override
  String get batteryDialogIntro =>
      'Beberapa ponsel (Samsung, Xiaomi, Oppo, Huawei) menutup aplikasi latar belakang secara agresif untuk menghemat baterai. Jika itu terjadi pada Rostrik, alarm bisa diam sebelum berbunyi.';

  @override
  String get batteryDialogMarkUnrestricted =>
      'Setel Rostrik ke Tanpa batasan untuk mencegahnya:';

  @override
  String get batteryStep1 => 'Buka pengaturan aplikasi ini (tombol di bawah).';

  @override
  String get batteryStep2 =>
      'Ketuk Baterai (atau \"Penggunaan baterai aplikasi\").';

  @override
  String get batteryStep3 =>
      'Pilih Tanpa batasan (bukan \"Dioptimalkan\" atau \"Dibatasi\").';

  @override
  String get batteryStep4 =>
      'Jika ada \"Izinkan aktivitas latar belakang\", aktifkan juga.';

  @override
  String get batteryStep5 =>
      'MATIKAN \"Jeda aktivitas aplikasi jika tidak digunakan\" (atau \"Hapus izin jika aplikasi tidak digunakan\") agar Android tidak mencabut izin alarm saat kamu tidak membukanya.';

  @override
  String get commonNotNow => 'Nanti saja';

  @override
  String get batteryGoToSettings => 'Buka Pengaturan';

  @override
  String get armEngineTitle => 'Aktifkan alarmmu';

  @override
  String get armEngineRosterReady => 'Jadwalmu sudah siap';

  @override
  String armEngineCycleStarts(String label, String date) {
    return '$label · mulai $date';
  }

  @override
  String armEngineSwitchOn(String summary) {
    return 'Kami akan menyalakan alarm bangun ($summary) sebelum setiap shift yang sesuai.';
  }

  @override
  String get armEngineArming => 'Mengaktifkan…';

  @override
  String get armEngineCta => 'Otomatiskan Alarmku';

  @override
  String get armEngineLeadTimeLabel => 'Jeda alarm sebelum shift';

  @override
  String get armEngineLeadTimeHelper =>
      'Seberapa awal alarm berbunyi sebelum shift dimulai.';

  @override
  String get shiftTypeDay => 'Siang';

  @override
  String get shiftTypeAfternoon => 'Sore';

  @override
  String get shiftTypeNight => 'Malam';

  @override
  String get shiftTypeOff => 'Libur';

  @override
  String get weekdaysNone => 'Tidak ada hari';

  @override
  String get weekdaysEveryDay => 'Setiap hari';

  @override
  String get weekdaysWeekdays => 'Hari kerja';

  @override
  String get weekdaysWeekends => 'Akhir pekan';

  @override
  String durationMin(int m) {
    return '$m mnt';
  }

  @override
  String durationH(int h) {
    return '$h jam';
  }

  @override
  String durationHMin(int h, int m) {
    return '$h jam $m mnt';
  }

  @override
  String durationMinShort(int m) {
    return '$m mnt';
  }

  @override
  String durationHShort(int h) {
    return '$h jam';
  }

  @override
  String durationHMinShort(int h, int m) {
    return '$h jam $m mnt';
  }

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonSkip => 'Lewati';

  @override
  String get commonBack => 'Kembali';

  @override
  String get commonDone => 'Selesai';

  @override
  String get commonNext => 'Berikutnya';

  @override
  String get walkthroughIntroTitle => 'Tur 60 detik';

  @override
  String get walkthroughIntroBodyTwo =>
      'Dua hal yang membuat Rostrik berguna. Kamu bisa melewatinya kapan saja.';

  @override
  String get walkthroughIntroBodyOne =>
      'Hal yang membuat Rostrik berguna. Kamu bisa melewatinya kapan saja.';

  @override
  String get walkthroughPaintLabel => 'Warnai jadwalmu';

  @override
  String get walkthroughPaintDetail => 'Ketuk hari kerjamu, secepat itu.';

  @override
  String get walkthroughShakeLabel => 'Goyangkan untuk mematikan';

  @override
  String get walkthroughShakeDetail => 'Goyangan kuat mematikan alarm kritis.';

  @override
  String get walkthroughTryEach =>
      'Ketuk Berikutnya untuk mencoba masing-masing.';

  @override
  String get walkthroughTryIt => 'Ketuk Berikutnya untuk mencobanya.';

  @override
  String get walkthroughPaintBody =>
      'Ketuk hari kerjamu. Di editor sebenarnya kamu bisa menambah blok lain (sore, malam) dengan cara yang sama.';

  @override
  String get walkthroughPaintPrompt =>
      'Ketuk sebuah hari untuk mewarnainya sebagai shift siang.';

  @override
  String walkthroughPaintFeedback(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Mantap! $count hari itu sekarang blok siang. Hari yang tidak diketuk tetap libur. Semudah itu.',
    );
    return '$_temp0';
  }

  @override
  String get walkthroughShakeBody =>
      'Alarm shift kritis butuh goyangan kuat dan terus-menerus untuk dimatikan, jadi ketukan setengah sadar tidak cukup. Coba: goyangkan ponselmu.';

  @override
  String get walkthroughShakeSuccess => 'Berhasil!';

  @override
  String get walkthroughShakeSuccessDetail =>
      'Persis begitulah cara mematikan alarm kritis.';

  @override
  String get walkthroughDoneTitle => 'Semua siap';

  @override
  String get walkthroughDoneBody =>
      'Buat jadwal kapan saja dari Kelola, dan tonton tur ini lagi di Pengaturan → Bantuan.';

  @override
  String get navDashboard => 'Beranda';

  @override
  String get navTimeline => 'Linimasa';

  @override
  String get navManage => 'Kelola';

  @override
  String get navAlarms => 'Alarm';

  @override
  String get navSleep => 'Tidur';

  @override
  String get onbPatternTitle => 'Pilih pola gilirmu';

  @override
  String get purchaseTrialEnded => 'Uji coba gratismu sudah berakhir';

  @override
  String get purchaseBody =>
      'Buka Rostrik sekali saja agar alarm shift-mu tetap berbunyi. Jadwal, alarm, dan pengaturanmu aman, dan langsung aktif lagi begitu kamu membukanya.';

  @override
  String get purchaseAlarmsWontRing =>
      'Sampai saat itu, alarm tidak akan berbunyi.';

  @override
  String get purchaseUnlock => 'Buka akses penuh';

  @override
  String purchaseUnlockWithPrice(String price) {
    return 'Buka akses penuh · $price';
  }

  @override
  String get purchaseRestore => 'Pulihkan pembelian';

  @override
  String get purchaseOneTime => 'Sekali beli. Tanpa langganan.';

  @override
  String get purchaseUnavailable =>
      'Pembelian sedang tidak tersedia. Periksa koneksimu lalu coba lagi.';

  @override
  String get purchaseCheckingPrevious => 'Mencari pembelian sebelumnya…';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsLegalAbout => 'LEGAL & TENTANG';

  @override
  String get settingsHelp => 'BANTUAN';

  @override
  String get settingsHowItWorks => 'Cara kerjanya';

  @override
  String get settingsReplayTourShake =>
      'Putar ulang tur singkat: warnai jadwal + goyangkan untuk mematikan';

  @override
  String get settingsReplayTour => 'Putar ulang tur singkat: warnai jadwal';

  @override
  String get settingsScreenTips => 'Tampilkan tips layar';

  @override
  String get settingsScreenTipsSub =>
      'Petunjuk sekali tampil di tiap layar. Aktifkan untuk melihatnya lagi.';

  @override
  String get settingsFullAccess => 'AKSES PENUH';

  @override
  String get settingsFullAccessUnlocked => 'Akses penuh terbuka';

  @override
  String get settingsThanks => 'Terima kasih sudah mendukung Rostrik.';

  @override
  String settingsTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Uji coba gratis: sisa $days hari',
    );
    return '$_temp0';
  }

  @override
  String get settingsTrialEnded => 'Uji coba gratis berakhir';

  @override
  String get settingsUnlockPitch =>
      'Buka sekali agar alarm shift tetap berbunyi setelah uji coba berakhir: sekali beli, tidak pernah langganan.';

  @override
  String get settingsRestore => 'Pulihkan';

  @override
  String get settingsBrandTagline => 'Alarm untuk di luar jam kantor';

  @override
  String get settingsLeadTime => 'Jeda sebelum shift';

  @override
  String get settingsLeadTimeSub =>
      'Alarm berbunyi selama ini sebelum setiap shift dimulai.';

  @override
  String get settingsSnoozeDuration => 'Durasi tunda';

  @override
  String get settingsSnoozeDurationSub =>
      'Seberapa jauh tombol Tunda memundurkan alarm yang berbunyi.';

  @override
  String get settingsMinutesLabel => 'Menit';

  @override
  String commonMinutes(int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m menit',
    );
    return '$_temp0';
  }

  @override
  String get settingsShiftCycles => 'SIKLUS SHIFT';

  @override
  String get settingsShiftCyclesSub =>
      'Jadwal yang kamu buat dari pola atau templat.';

  @override
  String get settingsAddShiftCycle => 'Tambah Siklus Shift';

  @override
  String get settingsNoRosters => 'Kamu belum membuat jadwal apa pun.';

  @override
  String commonDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Hapus';

  @override
  String get commonCancel => 'Batal';

  @override
  String get settingsDeleteRosterTitle => 'Hapus jadwal?';

  @override
  String settingsDeleteRosterBody(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shift',
    );
    return 'Hapus \"$label\"? Alarm yang tertunda akan dibatalkan dan $_temp0 akan dihapus.';
  }

  @override
  String settingsDeletedRoster(String label) {
    return '\"$label\" dihapus';
  }

  @override
  String get commonActive => 'Aktif';

  @override
  String get commonUpcoming => 'Mendatang';

  @override
  String get commonPast => 'Lampau';

  @override
  String get settingsWorkHistory => 'RIWAYAT KERJA';

  @override
  String get settingsWorkHistorySub =>
      'Tinjau dan ekspor shift kustom yang sudah selesai untuk mencocokkan slip gaji.';

  @override
  String get settingsViewWorkHistory => 'Lihat & Ekspor Riwayat Kerja';

  @override
  String get settingsPreferences => 'PREFERENSI';

  @override
  String get settingsPreferencesSub => 'Cara jadwalmu ditampilkan di aplikasi.';

  @override
  String get settingsAppearance => 'Tampilan';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeLight => 'Terang';

  @override
  String get settingsThemeDark => 'Gelap';

  @override
  String get settingsThemeSub =>
      'Gelap adalah bawaan Rostrik. Terang memakai palet krem yang hangat.';

  @override
  String get settings24h => 'Gunakan Format 24 Jam';

  @override
  String get settings24hOn => 'Waktu tampil seperti 14:30';

  @override
  String get settings24hOff => 'Waktu tampil seperti 02:30 PM';

  @override
  String get settingsWeekStartTitle => 'Mulai Kalender pada Senin';

  @override
  String get settingsWeekStartMon => 'Minggu dimulai hari Senin';

  @override
  String get settingsWeekStartSun => 'Minggu dimulai hari Minggu';

  @override
  String get settingsTimelineOpensOn => 'Linimasa terbuka di';

  @override
  String get commonList => 'Daftar';

  @override
  String get commonMonth => 'Bulan';

  @override
  String get settingsCalendar => 'KALENDER';

  @override
  String get settingsCalendarSync =>
      'Sinkronkan ke Google / Kalender Perangkat';

  @override
  String get settingsCalendarSyncSub =>
      'Salin shift-mu secara otomatis ke kalender khusus \"Rostrik Roster\" di ponselmu.';

  @override
  String get settingsCalSyncOff =>
      'Sinkronisasi kalender mati. Acara \"Rostrik Roster\" mendatang telah dihapus.';

  @override
  String get settingsCalSyncMirroring =>
      'Menyalin jadwalmu ke kalender \"Rostrik Roster\"…';

  @override
  String get settingsCalPermNeeded =>
      'Izin kalender diperlukan untuk menyinkronkan jadwalmu.';

  @override
  String get settingsCalBlocked =>
      'Akses kalender diblokir. Aktifkan di pengaturan sistem untuk menyinkronkan.';

  @override
  String get settingsCalOpenSettings => 'Pengaturan';

  @override
  String get settingsCalUnsupported =>
      'Sinkronisasi kalender tidak tersedia di perangkat ini.';

  @override
  String get settingsDangerZone => 'ZONA BERBAHAYA';

  @override
  String get settingsDangerZoneSub =>
      'Menghapus jadwal, alarm, dan pengaturanmu, lalu memulai penyiapan dari awal.';

  @override
  String get settingsResetAppData => 'Reset Data Aplikasi';

  @override
  String get settingsResetTitle => 'Reset aplikasi?';

  @override
  String get settingsResetBody =>
      'Yakin? Jadwal, alarm, dan pengaturanmu akan dihapus.';

  @override
  String get settingsResetConfirm => 'Reset';

  @override
  String get dashNoUpcomingShifts => 'Tidak ada shift mendatang';

  @override
  String get dashEnjoyTimeOff => 'Nikmati waktu liburmu.';

  @override
  String get dashInProgress => 'BERLANGSUNG';

  @override
  String get dashRotation => 'Giliran';

  @override
  String get dashAlarmsCantRing => 'Alarm tidak bisa berbunyi dengan andal';

  @override
  String get dashNotifsOffIssue =>
      'Notifikasi mati: alarm yang berbunyi tidak bisa menampilkan layar bangun atau dimatikan.';

  @override
  String get dashOpenSettings => 'Buka pengaturan';

  @override
  String get dashExactBlockedIssue =>
      'Alarm tepat waktu diblokir: tidak ada alarm bangun yang bisa dijadwalkan.';

  @override
  String get dashAlarmsWontTakeOverScreen => 'Alarm tidak akan memenuhi layar';

  @override
  String get dashFullScreenBlockedIssue =>
      'Alarm layar penuh dimatikan — saat ponsel terkunci Anda akan melihat notifikasi, bukan layar alarm.';

  @override
  String get dashAllow => 'Izinkan';

  @override
  String get dashSlideToSkip => 'Geser untuk melewati alarm ini';

  @override
  String dashSlideToSkipAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Geser untuk melewati $count alarm',
    );
    return '$_temp0';
  }

  @override
  String dashDismissUpcoming(String time) {
    return 'Matikan alarm berikutnya · $time';
  }

  @override
  String dashSkipAllForShift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lewati $count alarm untuk shift ini',
    );
    return '$_temp0';
  }

  @override
  String get dashKeepAlarm => 'Pertahankan alarm';

  @override
  String get dashMyRotation => 'Giliranku';

  @override
  String get dashCalendarUpcoming => 'Kalender & shift mendatang';

  @override
  String get dashNextShifts => 'Shift berikutnya';

  @override
  String get dashOpenTimeline => 'Buka Linimasa';

  @override
  String heroStartsIn(String countdown) {
    return 'Mulai dalam $countdown';
  }

  @override
  String heroEndsIn(String countdown) {
    return 'Selesai dalam $countdown';
  }

  @override
  String get heroStartsInPrefix => 'Mulai dalam';

  @override
  String get heroEndsInPrefix => 'Selesai dalam';

  @override
  String heroStartsTodayAt(String time) {
    return 'Mulai hari ini pukul $time';
  }

  @override
  String heroStartedTodayAt(String time) {
    return 'Dimulai hari ini pukul $time';
  }

  @override
  String heroStartsTomorrowAt(String time) {
    return 'Mulai besok pukul $time';
  }

  @override
  String heroStartedYesterdayAt(String time) {
    return 'Dimulai kemarin pukul $time';
  }

  @override
  String heroStartsYesterdayAt(String time) {
    return 'Mulai kemarin pukul $time';
  }

  @override
  String heroStartsOnAt(String date, String time) {
    return 'Mulai $date pukul $time';
  }

  @override
  String heroStartedOnAt(String date, String time) {
    return 'Dimulai $date pukul $time';
  }

  @override
  String get shiftTypeDayShift => 'Shift siang';

  @override
  String get shiftTypeAfternoonShift => 'Shift sore';

  @override
  String get shiftTypeNightShift => 'Shift malam';

  @override
  String heroDayXofY(int x, int y, String label) {
    return 'Hari $x dari $y – $label';
  }

  @override
  String get heroOffTomorrow => 'Besok libur';

  @override
  String heroOffInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Libur dalam $days hari',
    );
    return '$_temp0';
  }

  @override
  String get heroBackOnTomorrow => 'Besok kembali kerja';

  @override
  String heroBackOnInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Kembali kerja dalam $days hari',
    );
    return '$_temp0';
  }

  @override
  String get heroOffRdo => 'Libur';

  @override
  String durationDayShort(int d) {
    return '$d hr';
  }

  @override
  String durationDayHourShort(int d, int h) {
    return '$d hr $h jam';
  }

  @override
  String get alarmsTitle => 'Alarm';

  @override
  String get alarmsAddTooltip => 'Tambah alarm';

  @override
  String get alarmsSortTooltip => 'Urutkan alarm';

  @override
  String get alarmsSortByTime => 'Menurut waktu';

  @override
  String get alarmsSortByShiftType => 'Menurut jenis shift';

  @override
  String get alarmsEmptyTitle => 'Belum ada alarm.';

  @override
  String get alarmsEmptyBody => 'Ketuk + untuk menambahkan.';

  @override
  String get alarmsNextAlarm => 'ALARM BERIKUTNYA';

  @override
  String get alarmsHolidayMode => 'Mode liburan';

  @override
  String get alarmsHolidayModeSub =>
      'Alarm dijeda: tidak ada yang akan berbunyi.';

  @override
  String get alarmsNoUpcoming => 'Tidak ada alarm shift mendatang';

  @override
  String get alarmsNoUpcomingSub =>
      'Tambahkan alarm yang mengikuti giliran, atau buat jadwal.';

  @override
  String alarmsForYourShift(String type, String day) {
    return 'untuk shift $type · $day';
  }

  @override
  String get commonToday => 'Hari ini';

  @override
  String get commonTomorrow => 'Besok';

  @override
  String get alarmsOffWontRing => 'Mati: tidak akan berbunyi';

  @override
  String get alarmsNoUpcomingRing => 'Belum ada bunyi terjadwal';

  @override
  String alarmsNextRing(String day, String time) {
    return 'Bunyi berikutnya: $day pukul $time';
  }

  @override
  String get alarmsSwipeToDelete => 'Geser untuk menghapus';

  @override
  String get alarmsRingsOnceAutoDelete => 'Berbunyi sekali · terhapus otomatis';

  @override
  String get alarmsRingsOnce => 'Hanya berbunyi sekali';

  @override
  String get alarmsYourShift => 'shift-mu';

  @override
  String alarmsShiftsOfType(String type) {
    return 'shift $type';
  }

  @override
  String alarmsExactTime(String shift) {
    return 'Waktu tepat · $shift';
  }

  @override
  String alarmsLeadBeforeDefault(String lead, String shift) {
    return '$lead sebelum $shift · bawaan';
  }

  @override
  String alarmsLeadBefore(String lead, String shift) {
    return '$lead sebelum $shift';
  }

  @override
  String get createEditAlarm => 'Edit alarm';

  @override
  String get createNewAlarm => 'Alarm baru';

  @override
  String get createDefaultLabel => 'Bangun';

  @override
  String get createFallbackLabel => 'Alarm';

  @override
  String get createPickBecomesDefault =>
      'Pilihanmu jadi bawaan untuk alarm baru.';

  @override
  String get createSelectFromFiles => 'Pilih dari File';

  @override
  String get createFilesSub => 'Pilih file audio yang tersimpan di perangkatmu';

  @override
  String get createSelectSystemTone => 'Pilih Nada Sistem';

  @override
  String get createSystemToneSub => 'Pilih dari suara alarm perangkatmu';

  @override
  String get createAlarmTiming => 'Waktu alarm';

  @override
  String get createLeadTimeMode => 'Jeda sebelum shift';

  @override
  String get createExactTimeMode => 'Waktu tepat';

  @override
  String createFiresAt(String time) {
    return 'Berbunyi pukul $time';
  }

  @override
  String createLeadBeforeShiftStart(String lead) {
    return '$lead sebelum shift mulai';
  }

  @override
  String get createLinkedShift => 'Shift terkait';

  @override
  String get createRepeatOn => 'Ulangi pada';

  @override
  String get createLabelField => 'Label';

  @override
  String get createLabelHint => 'mis. Bangun';

  @override
  String get createCriticalShift => 'Shift kritis';

  @override
  String get createCriticalShiftSub =>
      'Goyangkan untuk mematikan · tahan 3 detik sebagai cadangan';

  @override
  String get createRingtone => 'Nada dering';

  @override
  String get commonStop => 'Stop';

  @override
  String get commonPlay => 'Putar';

  @override
  String get createVibrate => 'Getar';

  @override
  String get createRepeat => 'Ulangi';

  @override
  String get createRepeatRotation => 'Giliran';

  @override
  String get createRepeatWeekly => 'Mingguan';

  @override
  String get createRepeatOneTime => 'Sekali';

  @override
  String get createPickOneDay => 'Pilih minimal satu hari';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonSaveChanges => 'Simpan perubahan';

  @override
  String get createTimeBeforeShift => 'Waktu sebelum shift';

  @override
  String get commonOk => 'OK';

  @override
  String get sleepTitle => 'Tidur';

  @override
  String get sleepTargetHeader => 'TARGET TIDUR';

  @override
  String get sleepTargetSub =>
      'Berapa jam kamu ingin tidur. Rostrik menghitung mundur dari alarm bangun berikutnya untuk menentukan jam tidur malam ini.';

  @override
  String get sleepRemindersHeader => 'PENGINGAT';

  @override
  String get sleepWindDownHeader => 'JEDA BERSANTAI';

  @override
  String get sleepWindDownSub =>
      'Seberapa awal sebelum jam tidur pengingat untuk bersantai muncul.';

  @override
  String get sleepSoundsHeader => 'SUARA TIDUR';

  @override
  String get sleepSoundsSub =>
      'White & brown noise untuk membantu tertidur. Pilih timer lalu ketuk sebuah suara.';

  @override
  String get sleepNothingToPlan =>
      'Tidak ada yang perlu direncanakan malam ini';

  @override
  String get sleepNothingToPlanSub =>
      'Tambahkan shift ke jadwalmu dan Rostrik akan menyusun jam tidur pribadi berdasarkan waktu bangun berikutnya.';

  @override
  String get sleepTransitionDay => 'HARI TRANSISI';

  @override
  String get sleepTransitionTitle =>
      'Besok shift malam. Boleh tidur lebih lama.';

  @override
  String get sleepTransitionBody =>
      'Ini hari transisi: kamu libur sebelum shift malam, jadi tidak ada alarm pagi. Tabung istirahat sekarang dan biarkan tubuhmu tidur lebih larut malam ini.';

  @override
  String get sleepRestRecovery => 'ISTIRAHAT & PEMULIHAN';

  @override
  String get sleepNoEarlyAlarm => 'Tidak ada alarm pagi';

  @override
  String get sleepRestBody =>
      'Shift berikutnya masih lebih dari sehari lagi, jadi tidak ada waktu bangun untuk direncanakan malam ini. Tidur sesuai ritmemu dan pulihkan tenaga; Rostrik akan menyusun rencana tidur saat shift makin dekat.';

  @override
  String get sleepTonightsPlan => 'RENCANA MALAM INI';

  @override
  String get sleepTargetBedtime => 'Target jam tidur';

  @override
  String get sleepWindDownStat => 'Bersantai';

  @override
  String get sleepWakeUpStat => 'Bangun';

  @override
  String get sleepDurationStat => 'Durasi';

  @override
  String get sleepBedtimeReminder => 'Pengingat Jam Tidur';

  @override
  String sleepNudgeAtBedtime(String time) {
    return 'Ingatkan aku pukul $time untuk tidur';
  }

  @override
  String get sleepBedtimeSub => 'Pengingat saat waktunya tidur';

  @override
  String get sleepWindDownReminder => 'Pengingat Bersantai';

  @override
  String sleepNudgeAtWindDown(String time) {
    return 'Ingatkan aku pukul $time untuk mulai bersantai';
  }

  @override
  String get sleepWindDownReminderSub =>
      'Pengingat lebih awal untuk mulai bersantai';

  @override
  String get commonOff => 'Mati';

  @override
  String get sleepSoundWhiteNoise => 'White noise';

  @override
  String get sleepSoundPinkNoise => 'Pink noise';

  @override
  String get sleepSoundBrownNoise => 'Brown noise';

  @override
  String get sleepSoundFan => 'Kipas angin';

  @override
  String get sleepSoundOcean => 'Laut';

  @override
  String get sleepSoundRain => 'Hujan';

  @override
  String get manageTitle => 'Kelola';

  @override
  String get manageRosterTools => 'ALAT JADWAL';

  @override
  String get manageRosterToolsSub =>
      'Buat dan sesuaikan shift yang mengatur alarm dan rencana tidurmu.';

  @override
  String get manageGenerateRotation => 'Buat Pola Giliran';

  @override
  String get manageGenerateRotationSub =>
      'Susun pola shift berulang dari templat.';

  @override
  String get manageAddCustomShift => 'Tambah Shift Tambahan';

  @override
  String get manageAddCustomShiftSub =>
      'Tambahkan satu shift lepas ke jadwalmu.';

  @override
  String get manageMarkLeave => 'Tandai Cuti / Libur';

  @override
  String get manageMarkLeaveSub =>
      'Warnai hari liburmu (cuti tahunan, sakit) sekaligus.';

  @override
  String get managePauseSchedule => 'Jeda Jadwal';

  @override
  String get managePausedSub =>
      'Mode liburan AKTIF: alarm dibisukan, jadwalmu aman.';

  @override
  String get manageNotPausedSub =>
      'Mode liburan: bisukan alarm selama kamu tidak bertugas.';

  @override
  String get markLeaveTitle => 'Tandai cuti';

  @override
  String get markLeaveIntro =>
      'Ketuk hari liburmu, pilih alasan, lalu terapkan. Alarm di hari itu tidak akan berbunyi dan jadwalmu tetap utuh.';

  @override
  String get leaveAnnual => 'Cuti tahunan';

  @override
  String get leaveSick => 'Sakit';

  @override
  String get leavePublicHoliday => 'Hari libur nasional';

  @override
  String get markLeaveReason => 'Alasan';

  @override
  String get markLeaveFallbackReason => 'cuti';

  @override
  String markLeaveMarked(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shift ditandai sebagai $reason.',
    );
    return '$_temp0';
  }

  @override
  String get markLeaveSelectDays => 'Pilih hari yang akan ditandai';

  @override
  String get markLeaveNoShifts => 'Tidak ada shift di hari itu';

  @override
  String markLeaveApplyTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Terapkan ke $count shift',
    );
    return '$_temp0';
  }

  @override
  String get workHistoryTitle => 'Riwayat Kerja';

  @override
  String get workHistoryExportTooltip => 'Ekspor Riwayat';

  @override
  String workHistoryExportFailed(String error) {
    return 'Riwayat tidak dapat diekspor: $error';
  }

  @override
  String workHistoryWorked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shift dikerjakan',
    );
    return '$_temp0';
  }

  @override
  String workHistoryHours(String hours) {
    return '$hours jam';
  }

  @override
  String get commonPaused => 'Dijeda';

  @override
  String workHistoryPausedReason(String reason) {
    return 'Dijeda · $reason';
  }

  @override
  String get workHistoryRotationBadge => 'Giliran';

  @override
  String get workHistoryAdHocBadge => 'Tambahan';

  @override
  String get workHistoryEmptyTitle => 'Belum ada shift yang selesai';

  @override
  String get workHistoryEmptyBody =>
      'Shift yang sudah kamu kerjakan, baik giliran maupun kustom, muncul di sini setelah selesai, siap diekspor untuk mencocokkan slip gaji.';

  @override
  String get workHistoryShareSubject => 'Riwayat Kerja Rostrik';

  @override
  String get workHistoryShareText => 'Ekspor riwayat kerja Rostrik-ku.';

  @override
  String get shiftEdAddShift => 'Tambah shift';

  @override
  String get shiftEdEditShift => 'Edit shift';

  @override
  String get shiftEdDate => 'Tanggal';

  @override
  String get shiftEdPickDate => 'Pilih tanggal';

  @override
  String get shiftEdStarts => 'Mulai';

  @override
  String get shiftEdEnds => 'Selesai';

  @override
  String get shiftEdPickTime => 'Pilih waktu';

  @override
  String get shiftEdEndsNextDay => 'Selesai keesokan harinya';

  @override
  String get shiftEdPauseTitle => 'Jeda / batalkan shift ini';

  @override
  String get shiftEdPausedSub =>
      'Alarm tidak akan berbunyi. Tetap tercatat di kalendermu.';

  @override
  String get shiftEdNotPausedSub =>
      'Tandai hari libur (sakit, cuti, libur nasional) tanpa menghapusnya.';

  @override
  String get shiftEdReasonOptional => 'Alasan (opsional)';

  @override
  String get dayShifts => 'Shift';

  @override
  String get dayActivities => 'Kegiatan';

  @override
  String get dayAddAnotherShift => 'Tambah shift lain';

  @override
  String get dayAddActivity => 'Tambah kegiatan';

  @override
  String get dayAddActivitySub => 'Acara, tugas, atau ulang tahun';

  @override
  String get dayReminder => 'Pengingat';

  @override
  String get actEditActivity => 'Edit kegiatan';

  @override
  String get actLeadAtTime => 'Tepat waktu';

  @override
  String get actLead10Min => '10 mnt sebelumnya';

  @override
  String get actLead30Min => '30 mnt sebelumnya';

  @override
  String get actLead1Hour => '1 jam sebelumnya';

  @override
  String get actLead1Day => '1 hari sebelumnya';

  @override
  String get actEvent => 'Acara';

  @override
  String get actTask => 'Tugas';

  @override
  String get actBirthday => 'Ulang tahun';

  @override
  String get actTitleField => 'Judul';

  @override
  String get actAllDay => 'Sepanjang hari';

  @override
  String get actTimeField => 'Waktu';

  @override
  String get actRemindMe => 'Ingatkan aku';

  @override
  String get actRemindMeSub =>
      'Notifikasi ringan, terpisah dari alarm shift-mu.';

  @override
  String get actRemindAt => 'Ingatkan pukul';

  @override
  String get actReminderPassed =>
      'Waktu itu sudah lewat: pengingat ini tidak akan muncul.';

  @override
  String get actNoteOptional => 'Catatan (opsional)';

  @override
  String get actCompleted => 'Selesai';

  @override
  String get tipDashboardTitle => 'Berandamu';

  @override
  String get tipDashboardBody =>
      'Pusat kendalimu. Lihat shift berikutnya dengan hitung mundur langsung dan posisimu dalam giliran. Ketuk sebuah kotak untuk melihat detailnya.';

  @override
  String get tipTimelineTitle => 'Seluruh jadwalmu';

  @override
  String get tipTimelineBody =>
      'Beralih antara Daftar dan kalender Bulan di bagian atas. Ketuk hari mana saja untuk mengedit shift, atau menambah acara, tugas, atau ulang tahun.';

  @override
  String get tipManageTitle => 'Buat & sesuaikan';

  @override
  String get tipManageBody =>
      'Buat jadwal bergilir, tambah shift lepas (lembur), atau jeda seluruh jadwal saat cuti, semuanya di sini.';

  @override
  String get tipAlarmsTitle => 'Alarmmu';

  @override
  String get tipAlarmsBody =>
      'Semua alarm dari shift-mu, plus alarm yang kamu tambahkan sendiri. Ketuk salah satu untuk mengubah waktu atau nadanya, atau jadikan alarm Shift Kritis yang dimatikan dengan digoyangkan.';

  @override
  String get tipSleepTitle => 'Rencana tidur';

  @override
  String get tipSleepBody =>
      'Rencana bersantai yang mengikuti jadwalmu: tetapkan target tidur dan hadapi shift berikutnya dengan segar.';

  @override
  String get tipReplayHint =>
      'Putar ulang kapan saja dari Pengaturan › Cara kerjanya.';

  @override
  String get tipDontShow => 'Jangan tampilkan tips';

  @override
  String get tipGotIt => 'Mengerti';

  @override
  String get timelineListView => 'Daftar';

  @override
  String get timelineMonthView => 'Bulan';

  @override
  String get shiftTypeAftShort => 'Sore';

  @override
  String get timelineNoShifts =>
      'Belum ada shift terjadwal. Ketuk + untuk menambahkan.';

  @override
  String timelineNoMatch(String filter) {
    return 'Tidak ada shift yang cocok dengan filter $filter.';
  }

  @override
  String get timelineRestDay => 'Hari istirahat';

  @override
  String timelineRestDayReason(String reason) {
    return 'Hari istirahat · $reason';
  }

  @override
  String get timelineAllDay => 'Sepanjang hari';

  @override
  String get calLegendPausedLeave => 'Dijeda / Cuti';

  @override
  String get calLegendActivity => 'Kegiatan';

  @override
  String get filterAll => 'Semua';

  @override
  String get filterWork => 'Kerja';

  @override
  String get criticalHoldToDismiss => 'Atau tahan untuk mematikan';

  @override
  String get patternChoosePattern => 'Pilih pola';

  @override
  String get patternRotatingSwings => 'Pola Bergilir';

  @override
  String get patternDaySwings => 'Khusus Shift Siang';

  @override
  String get patternNightSwings => 'Khusus Shift Malam';

  @override
  String get patternShiftTimes => 'Jam shift';

  @override
  String get patternGenerate => 'Tetapkan Hari 1 & Buat';

  @override
  String get patternSelectDay1 => 'Pilih Hari 1 berikutnya';

  @override
  String patternDay1Hint(String label) {
    return 'Hari pertama blok $label';
  }

  @override
  String get patternNextDay1 => 'Hari 1 berikutnya';

  @override
  String get patternUseThisDate => 'Gunakan tanggal ini';

  @override
  String patternGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shift dibuat',
    );
    return '$_temp0';
  }

  @override
  String patternGenerationFailed(String error) {
    return 'Gagal membuat: $error';
  }

  @override
  String get patternFirstBlockFallback => 'pertama';

  @override
  String get patternBuildCustom => 'Buat jadwal kustom';

  @override
  String get patternBuildCustomSub =>
      'Tidak ada templat yang cocok? Susun blokmu sendiri.';

  @override
  String patternBlockDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Siang',
    );
    return '$_temp0';
  }

  @override
  String patternBlockAfternoons(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Sore',
    );
    return '$_temp0';
  }

  @override
  String patternBlockNights(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Malam',
    );
    return '$_temp0';
  }

  @override
  String patternBlockOff(int n) {
    return '$n Libur';
  }

  @override
  String get builderNewRoster => 'Jadwal Shift Baru';

  @override
  String get builderEditRoster => 'Edit Jadwal';

  @override
  String get builderNewSub => 'Atur pola giliran shift-mu';

  @override
  String get builderEditSub => 'Ubah dan ganti jadwal tersimpan ini';

  @override
  String get builderNameHint => 'Nama jadwal (mis. Giliran 14 Hariku)';

  @override
  String get builderCycleLength => 'PANJANG SIKLUS';

  @override
  String get builderStartDate => 'TANGGAL MULAI';

  @override
  String get builderShiftBlocks => 'BLOK SHIFT';

  @override
  String get builderAddShiftBlock => 'Tambah Blok Shift';

  @override
  String get builderCreateRoster => 'Buat Jadwal';

  @override
  String get builderSaveChanges => 'Simpan Perubahan';

  @override
  String get builderReplaceWarning =>
      'Menyimpan akan mengganti jadwal ini. Tanda cuti / libur yang diwarnai di atasnya akan direset.';

  @override
  String get builderBackToOptions => 'Kembali ke pilihan';

  @override
  String get builderOrImport => 'ATAU IMPOR JADWAL YANG ADA';

  @override
  String get builderImportViaAi => 'Impor lewat AI';

  @override
  String get builderScanning => 'Memindai…';

  @override
  String get builderScanInstead => 'Pindai foto jadwal saja';

  @override
  String get builderCustomChip => 'Kustom';

  @override
  String get builderCycleLengthLabel => 'Panjang siklus';

  @override
  String builderDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hari',
    );
    return '$_temp0';
  }

  @override
  String get builderPickADate => 'Pilih tanggal';

  @override
  String get builderNoBlocksYet => 'Belum ada blok';

  @override
  String get builderNoBlocksSub =>
      'Tambahkan blok shift untuk menentukan giliranmu';

  @override
  String builderDaysLine(String ranges) {
    return 'Hari $ranges';
  }

  @override
  String get builderEditBlock => 'Edit blok';

  @override
  String get builderRemoveBlock => 'Hapus blok';

  @override
  String get builderPickRosterStart => 'Pilih tanggal mulai jadwal';

  @override
  String get builderPickScanStart =>
      'Pilih tanggal mulai untuk jadwal yang dipindai';

  @override
  String get builderScanCamera => 'Pindai dengan kamera';

  @override
  String get builderImportScreenshot => 'Impor tangkapan layar';

  @override
  String builderScanFailed(String error) {
    return 'Pemindaian gagal: $error';
  }

  @override
  String get builderNoTimesRecognised =>
      'Jam shift tidak terbaca. Coba potong lebih rapat di sekitar tabel.';

  @override
  String get builderCustomRosterFallback => 'Jadwal kustom';

  @override
  String get builderScannedRosterFallback => 'Jadwal hasil pindai';

  @override
  String builderRosterUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jadwal diperbarui: $count shift terjadwal',
    );
    return '$_temp0';
  }

  @override
  String builderRosterCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dibuat: $count shift terjadwal',
    );
    return '$_temp0';
  }

  @override
  String builderCouldNotCreate(String error) {
    return 'Jadwal tidak dapat dibuat: $error';
  }

  @override
  String get builderRosterImported => 'Jadwal diimpor ke kalendermu';

  @override
  String builderCouldNotImport(String error) {
    return 'Jadwal tidak dapat diimpor: $error';
  }

  @override
  String get blockAddTitle => 'Tambah blok shift';

  @override
  String get blockEditTitle => 'Edit blok shift';

  @override
  String get blockStart => 'Mulai';

  @override
  String get blockEnd => 'Selesai';

  @override
  String get blockTapDays => 'Ketuk hari yang dicakup shift ini';

  @override
  String get blockUntappedOff => 'Hari yang tidak diketuk adalah libur.';

  @override
  String blockOverlap(String ranges) {
    return 'Jam ini bertabrakan dengan shift lain pada hari $ranges. Ubah jamnya atau hari tersebut.';
  }

  @override
  String get blockAdd => 'Tambah blok';

  @override
  String get blockSave => 'Simpan blok';

  @override
  String get aiPromptCopied =>
      'Prompt disalin! Tempel ke aplikasi AI-mu bersama jadwalmu.';

  @override
  String get aiNothingToPaste =>
      'Tidak ada yang bisa ditempel dari papan klip.';

  @override
  String get aiNoValidShifts =>
      'Tidak ada shift valid yang terdeteksi. Pastikan kamu memakai prompt AI yang disalin.';

  @override
  String get aiStep1 => 'Salin prompt';

  @override
  String get aiCopied => 'Disalin!';

  @override
  String get aiCopyPrompt => 'Salin Prompt AI';

  @override
  String get aiStep1Sub =>
      'Tempel ke ChatGPT, Gemini, atau aplikasi AI lain, lalu tambahkan teks jadwal atau foto/tangkapan layar dan kirim.';

  @override
  String get aiStep2 => 'Tempel balasan AI';

  @override
  String get aiPaste => 'Tempel';

  @override
  String get aiParsePreview => 'Urai & Pratinjau';

  @override
  String get aiStep3 => 'Periksa shift yang terdeteksi';

  @override
  String get aiStep3Sub =>
      'Ketuk label untuk mengganti antara Siang, Sore, dan Malam jika AI salah.';

  @override
  String aiImportDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Impor $count hari',
    );
    return '$_temp0';
  }

  @override
  String get aiTitleSub =>
      'Ubah teks jadwal apa pun menjadi shift dengan bantuan aplikasi AI.';

  @override
  String aiSummaryLine(int count, int working, int off) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari',
    );
    return '$_temp0 · $working kerja · $off libur';
  }

  @override
  String get draftReviewTitle => 'Periksa jadwal hasil pindai';

  @override
  String draftRemovedDay(String date) {
    return '$date dihapus';
  }

  @override
  String get draftUndo => 'Urungkan';

  @override
  String draftSavedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari disimpan ke jadwalmu',
    );
    return '$_temp0';
  }

  @override
  String get draftRosterName => 'Nama jadwal';

  @override
  String get draftScannedImage => 'Gambar pindaian';

  @override
  String get draftScannedImageSub =>
      'Ketuk gambar untuk memperbesar dan membandingkan';

  @override
  String get draftImageError => 'Gambar pindaian tidak dapat ditampilkan.';

  @override
  String get draftRemove => 'Hapus';

  @override
  String get draftNoEndTime =>
      'Terpindai tanpa jam selesai: atur dulu agar bisa disimpan.';

  @override
  String get draftTime => 'Waktu';

  @override
  String get draftSetEnd => 'Atur selesai';

  @override
  String get draftConfirmSave => 'Konfirmasi & Simpan';

  @override
  String notifBeforeYourShift(String type) {
    return 'Sebelum shift $type';
  }

  @override
  String notifActivityAt(String kind, String time) {
    return '$kind pukul $time';
  }

  @override
  String get notifWindDownTitle => 'Waktunya bersantai 🌙';

  @override
  String notifWindDownBodyTarget(String time) {
    return 'Jauhkan layar: target jam tidur pukul $time.';
  }

  @override
  String get notifWindDownBody =>
      'Jauhkan layar dan mulai bersantai untuk malam ini.';

  @override
  String get notifBedtimeTitle => 'Waktunya tidur 😴';

  @override
  String notifBedtimeBodyWake(int hours, String shift, String time) {
    return 'Tidurlah agar dapat ~$hours jam sebelum $shift: bangun pukul $time.';
  }

  @override
  String notifBedtimeBody(int hours) {
    return 'Tidurlah untuk mencapai target tidur $hours jam.';
  }

  @override
  String get notifShiftDay => 'shift siang';

  @override
  String get notifShiftAfternoon => 'shift sore';

  @override
  String get notifShiftNight => 'shift malam';

  @override
  String get notifShiftGeneric => 'shift';

  @override
  String get notifTrialEndsTitle => 'Uji coba Rostrik-mu berakhir besok';

  @override
  String get notifTrialEndsBody =>
      'Buka akses penuh agar alarm shift-mu tetap berbunyi.';

  @override
  String seedWakeUpLabel(String type) {
    return 'Bangun shift $type';
  }

  @override
  String get seedShiftGeneric => 'Shift';

  @override
  String commonListAnd(String items, String last) {
    return '$items & $last';
  }

  @override
  String get soundClassic => 'Klasik';

  @override
  String get soundSiren => 'Sirene';

  @override
  String get soundDigital => 'Digital';

  @override
  String get soundChime => 'Lonceng';

  @override
  String get patternFirstResponder => 'Standar Petugas Darurat';

  @override
  String get ocrCropTitle => 'Potong HANYA barismu, bukan seluruh tim';

  @override
  String get draftNameHint => 'mis. Jadwal Mei';
}
