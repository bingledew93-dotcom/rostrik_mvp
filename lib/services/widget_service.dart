import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';

import '../data/models/shift.dart';
import '../data/models/shift_cycle.dart';
import '../data/repositories/shift_cycle_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../state/app_preferences.dart' show use24HourTimeKey;
import '../ui/dashboard_hero.dart';
import '../util/clock.dart';
import 'widget_forecast.dart';

/// Bridges the app's live roster/dashboard state onto the Android home-screen
/// widget (Phase 2). It recomputes the SAME hero payload the Dashboard shows
/// (via [buildDashboardHero], the shared source of truth) and writes it to the
/// native widget's data store, then asks Android to redraw the widget.
///
/// Refresh triggers (see [start] + the Dashboard hooks):
///   * app startup + every app resume;
///   * any roster mutation — save / edit / import / leave / delete — via the
///     shift + cycle streams (one debounced write per burst);
///   * the Dashboard Hero Card init + its minute ticker (keeps the countdown
///     fresh while the app is foreground, so the widget is current the moment
///     the user swipes home).
///
/// Every call is a safe no-op on platforms `home_widget` doesn't implement
/// (desktop / web / the test VM) and swallows its own errors — a widget update
/// must never disturb the app or its state management.
class WidgetService with WidgetsBindingObserver {
  WidgetService({
    required ShiftRepository shifts,
    required ShiftCycleRepository cycles,
    required Box settingsBox,
    Clock clock = const SystemClock(),
  })  : _shifts = shifts,
        _cycles = cycles,
        _settings = settingsBox,
        _clock = clock;

  /// Fully-qualified Android provider class. It lives in the Gradle *namespace*
  /// (`com.example.rostrik_mvp`), which is NOT the runtime applicationId
  /// (`com.rostrik.app`) — so `home_widget`'s `androidName` (it prefixes the
  /// applicationId) would resolve the wrong class and silently update nothing.
  /// We pass the qualified name explicitly.
  static const String androidProvider =
      'com.example.rostrik_mvp.RostrikWidgetProvider';

  // Wire contract with RostrikWidgetProvider.kt — keep in lock-step.
  static const String keyBadge = 'hero_badge';
  static const String keyMain = 'hero_main_text';
  static const String keySubtitle = 'hero_subtitle';
  static const String keyShiftType = 'shift_type';

  /// The piecewise `[{from,to,badge,sub,type,main,cdTo,cdPre}, ...]` timeline
  /// the native provider renders itself from. See `widget_forecast.dart` for
  /// why the widget cannot be handed a finished countdown string.
  static const String keyForecast = 'hero_forecast';

  final ShiftRepository _shifts;
  final ShiftCycleRepository _cycles;
  final Box _settings;
  final Clock _clock;

  StreamSubscription<List<Shift>>? _shiftSub;
  StreamSubscription<List<ShiftCycle>>? _cycleSub;
  Timer? _debounce;
  bool _started = false;

  /// `home_widget` only implements Android + iOS; anywhere else a call would
  /// throw `MissingPluginException`. `Platform` itself throws on web — hence the
  /// guard-inside-try.
  bool get _supported {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Pushes an initial snapshot and wires the reactive refreshes (roster streams
  /// + app-resume). Safe to call once at startup; idempotent.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (!_supported) return;

    await updateHomeScreenWidget();
    WidgetsBinding.instance.addObserver(this);

    final now = _clock.now();
    // Wide window so any realistic roster mutation re-emits and refreshes the
    // widget. Centered on start; the resume push covers a process left running
    // past the window edge.
    _shiftSub = _shifts
        .watchInRange(
          DateTime(now.year, now.month, now.day - 400),
          DateTime(now.year, now.month, now.day + 400),
        )
        .listen((_) => _scheduleUpdate());
    _cycleSub = _cycles.watch().listen((_) => _scheduleUpdate());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) updateHomeScreenWidget();
  }

  /// Coalesces the burst of emissions a single roster generate produces (many
  /// shift upserts + a cycle create) into ONE widget write.
  void _scheduleUpdate() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 400), updateHomeScreenWidget);
  }

  /// Recomputes the hero payload from current state and writes it to the widget.
  /// Never throws.
  Future<void> updateHomeScreenWidget() async {
    if (!_supported) return;
    try {
      final shifts = await _shifts.getAll();
      final cycles = await _cycles.getAll();
      final use24Hour =
          _settings.get(use24HourTimeKey, defaultValue: false) as bool;
      final hero = buildDashboardHero(
        shifts: shifts,
        cycles: cycles,
        now: _clock.now(),
        use24Hour: use24Hour,
      );
      await HomeWidget.saveWidgetData<String>(keyBadge, hero.badge);
      await HomeWidget.saveWidgetData<String>(keyMain, hero.mainText);
      await HomeWidget.saveWidgetData<String>(keySubtitle, hero.subtitle);
      await HomeWidget.saveWidgetData<String>(
        keyShiftType,
        hero.shiftType.name,
      );
      // The TIME-INDEPENDENT payload — this is what actually keeps the widget
      // live. The four keys above are a rendered snapshot and are retained only
      // so a widget whose forecast is missing or unparseable (first paint after
      // an update, a truncated write) still shows something sensible.
      await HomeWidget.saveWidgetData<String>(
        keyForecast,
        encodeWidgetForecast(
          buildWidgetForecast(
            shifts: shifts,
            cycles: cycles,
            now: _clock.now(),
            use24Hour: use24Hour,
          ),
        ),
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: androidProvider);
    } catch (e) {
      debugPrint('[WidgetService] update failed: $e');
    }
  }

  void dispose() {
    _shiftSub?.cancel();
    _cycleSub?.cancel();
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
