import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:rostrik_mvp/alarms/alarm_health.dart';
import 'package:rostrik_mvp/data/models/alarm_settings.dart';
import 'package:rostrik_mvp/data/models/app_alarm.dart';
import 'package:rostrik_mvp/data/models/shift.dart';
import 'package:rostrik_mvp/data/models/shift_cycle.dart';
import 'package:rostrik_mvp/data/models/shift_type.dart';
import 'package:rostrik_mvp/data/repositories/app_alarm_repository.dart';
import 'package:rostrik_mvp/data/repositories/shift_repository.dart';
import 'package:rostrik_mvp/l10n/l10n.dart';
import 'package:rostrik_mvp/purchase/entitlement_service.dart';
import 'package:rostrik_mvp/purchase/purchase_gate.dart';
import 'package:rostrik_mvp/state/app_preferences.dart';
import 'package:rostrik_mvp/ui/app_theme.dart';
import 'package:rostrik_mvp/ui/alarms_screen.dart';
import 'package:rostrik_mvp/ui/create_alarm_sheet.dart';
import 'package:rostrik_mvp/ui/dashboard_screen.dart';
import 'package:rostrik_mvp/ui/legal_consent_screen.dart';
import 'package:rostrik_mvp/ui/manage/manage_screen.dart';
import 'package:rostrik_mvp/ui/onboarding/roster_type_screen.dart';
import 'package:rostrik_mvp/ui/onboarding/walkthrough_flow.dart';
import 'package:rostrik_mvp/ui/onboarding/welcome_screen.dart';
import 'package:rostrik_mvp/ui/settings_screen.dart';
import 'package:rostrik_mvp/ui/sleep/sleep_screen.dart';

import '../alarms/fakes.dart';
import '../reminders/fakes.dart';

class _NoIap extends Fake implements InAppPurchase {}

/// Renders every high-traffic screen at the viewports the app does NOT
/// currently support, so the work needed before targetSdk 37 is an enumerated
/// list rather than a guess.
///
/// Why this exists: the app pins portrait, and a `<property>` in the manifest
/// restores that lock on large screens where Android 16 would otherwise ignore
/// it. The framework stops honouring that property at **API 37** — verified on
/// a Galaxy Tab A9+ (sw800dp, Android 16): forcing landscape today does
/// nothing while Rostrik is open, and will simply work once the opt-out dies.
/// On that day every screen here has to cope, or tablet users get broken
/// layouts on upgrade.
///
/// Deliberately English-only. Landscape breakage is STRUCTURAL — a Column that
/// assumes a tall viewport fails identically in all 15 languages — so adding
/// the locale axis would multiply the run time without finding anything new.
/// `locale_layout_smoke_test.dart` keeps the language axis at phone portrait,
/// where long translations are the actual risk. Re-add languages here only
/// once these pass.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Box settingsBox;
  late AppPreferences prefs;

  setUpAll(() async {
    // Real Roboto: the default test font draws every glyph as a 1em square,
    // roughly double real text width, and would flag overflows no device shows.
    final fonts = '${Platform.environment['FLUTTER_ROOT']}'
        '/bin/cache/artifacts/material_fonts';
    final roboto = FontLoader('Roboto');
    for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
      roboto.addFont(
        File('$fonts/Roboto-$w.ttf')
            .readAsBytes()
            .then((b) => ByteData.sublistView(b)),
      );
    }
    await roboto.load();
    tempDir = await Directory.systemTemp.createTemp('rostrik_large_screen_');
    Hive.init(tempDir.path);
    settingsBox = await Hive.openBox('settings');
    prefs = AppPreferences(settingsBox);
  });

  tearDownAll(() async {
    prefs.dispose();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final soon = now.add(const Duration(hours: 3));
  final shifts = <Shift>[
    Shift(
      id: 's1',
      date: DateTime(soon.year, soon.month, soon.day),
      type: ShiftType.day,
      startMinutes: soon.hour * 60 + soon.minute,
      endMinutes: (soon.hour * 60 + soon.minute + 8 * 60) % 1440,
    ),
    Shift(
      id: 's2',
      date: today.add(const Duration(days: 2)),
      type: ShiftType.night,
      startMinutes: 19 * 60,
      endMinutes: 7 * 60,
      isPaused: true,
      pauseReason: 'Annual Leave',
    ),
  ];
  final alarms = <AppAlarm>[
    AppAlarm(
      id: 'a1',
      minutesOfDay: 360,
      label: 'Day wake-up',
      repeatType: AppAlarmRepeatType.followsRotation,
      linkedShiftType: ShiftType.day,
      relativeOffsetMinutes: 60,
    ),
    AppAlarm(
      id: 'a3',
      minutesOfDay: 450,
      label: 'Gym',
      repeatType: AppAlarmRepeatType.weekly,
      weekdaysBitmask: 0x15,
    ),
  ];

  final screens = <String, Widget Function()>{
    'legal consent': () => LegalConsentScreen(onAccepted: () {}),
    'welcome': () => WelcomeScreen(onContinue: () {}, onSkip: () {}),
    'roster type': () => RosterTypeScreen(
          selected: null,
          onSelect: (_) {},
          onCustomTap: () {},
          onBack: () {},
          onContinue: () {},
        ),
    'walkthrough': () => WalkthroughFlow(onFinish: () {}),
    'dashboard': () => DashboardScreen(
          healthProbe: () async => AlarmHealth.healthy,
        ),
    'alarms': () => const AlarmsScreen(),
    'create alarm': () => const Scaffold(body: CreateAlarmSheet()),
    'sleep': () => const SleepScreen(),
    'manage': () => const ManageScreen(),
    'settings': () => const SettingsScreen(),
    'purchase gate': () => PurchaseGate(
          service: EntitlementService(
            settingsBox: settingsBox,
            reminderScheduler: FakeActivityReminderScheduler(),
            iap: _NoIap(),
          ),
        ),
  };

  /// Logical sizes, with the device pixel ratio each one is measured at.
  /// The tablet figures are the Galaxy Tab A9+ exactly: 1200×1920 physical at
  /// density 240 (dpr 1.5) = 800×1280 logical.
  const viewports = <String, (Size, double)>{
    // The case that arrives the day the opt-out dies.
    'tablet landscape 1280x800': (Size(1920, 1200), 1.5),
    // Already reachable today on a tablet, and already wasteful.
    'tablet portrait 800x1280': (Size(1200, 1920), 1.5),
    // The cruellest viewport: a phone on its side has barely 360dp of HEIGHT,
    // so anything assuming a tall column fails here first.
    'phone landscape 760x360': (Size(2280, 1080), 3.0),
  };

  for (final vp in viewports.entries) {
    group('[${vp.key}]', () {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} lays out', (tester) async {
          tester.view.physicalSize = vp.value.$1;
          tester.view.devicePixelRatio = vp.value.$2;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final shiftRepo = FakeShiftRepository();
          final alarmRepo = FakeAppAlarmRepository();
          addTearDown(shiftRepo.dispose);
          addTearDown(alarmRepo.dispose);

          await tester.pumpWidget(
            MultiProvider(
              providers: [
                Provider<List<Shift>>.value(value: shifts),
                Provider<List<ShiftCycle>>.value(value: const []),
                Provider<List<AppAlarm>>.value(value: alarms),
                Provider<AlarmSettings>.value(value: AlarmSettings.defaults),
                Provider<ShiftRepository>.value(value: shiftRepo),
                Provider<AppAlarmRepository>.value(value: alarmRepo),
                ChangeNotifierProvider<AppPreferences>.value(value: prefs),
              ],
              child: MaterialApp(
                locale: const Locale('en'),
                theme: _withRoboto(rostrikDarkTheme()),
                localizationsDelegates:
                    AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: syncL10nFromContext,
                home: entry.value(),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
        });
      }
    });
  }
}

ThemeData _withRoboto(ThemeData t) => t.copyWith(
      textTheme: t.textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: t.primaryTextTheme.apply(fontFamily: 'Roboto'),
    );
