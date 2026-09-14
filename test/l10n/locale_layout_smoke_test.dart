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

/// Renders the highest-traffic screens in EVERY supported locale on a narrow
/// phone viewport. Translations routinely run 30–40% longer than English
/// (German, Polish, Vietnamese), and a label that fits in English can overflow
/// a Row or SegmentedButton — which Flutter reports as an exception, failing
/// the test. This is the guard that keeps a new or edited translation from
/// shipping a visibly broken layout, since nobody on the team reads all 15
/// languages.
///
/// Real Roboto is loaded for the measurement. The default test font draws
/// every glyph as a full 1em square — roughly double real Latin text width —
/// which flags "overflows" no phone would ever show.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Box settingsBox;
  late AppPreferences prefs;

  setUpAll(() async {
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
    tempDir = await Directory.systemTemp.createTemp('rostrik_l10n_smoke_');
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
  // A day shift starting within the next few hours puts the dashboard's
  // countdown hero AND the early-skip control (the longest button copy in the
  // app) on screen.
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
      id: 'a2',
      minutesOfDay: 360,
      label: 'Backup',
      repeatType: AppAlarmRepeatType.followsRotation,
      linkedShiftType: ShiftType.day,
      relativeOffsetMinutes: 30,
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
    'dashboard': () =>
        DashboardScreen(healthProbe: () async => const AlarmHealth(
              notificationsEnabled: false,
              exactAlarmsAllowed: false,
            )),
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

  for (final locale in AppLocalizations.supportedLocales) {
    group('[$locale]', () {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} lays out without overflow', (tester) async {
          // 360×760 logical — a small modern Android phone, the tightest
          // common target.
          tester.view.physicalSize = const Size(1080, 2280);
          tester.view.devicePixelRatio = 3.0;
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
                locale: locale,
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
          // Sanity: the screen really rendered in the target language rather
          // than silently falling back to English.
          expect(
            Localizations.localeOf(tester.element(find.byType(Scaffold).first))
                .languageCode,
            locale.languageCode,
          );
        });
      }
    });
  }
}

ThemeData _withRoboto(ThemeData t) => t.copyWith(
      textTheme: t.textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: t.primaryTextTheme.apply(fontFamily: 'Roboto'),
    );
