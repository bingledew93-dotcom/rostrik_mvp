import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';

import 'alarms_screen.dart';
import 'dashboard_screen.dart';
import 'manage/manage_screen.dart';
import 'sleep/sleep_screen.dart';
import 'timeline/timeline_screen.dart';
import 'tips/screen_tip.dart';
import 'tips/screen_tip_overlay.dart';

/// Root navigation chassis.
///
/// Five tabs swapped via an [IndexedStack] so each tab's `State`
/// (scroll position, filter, modal stack, calendar focused month) is
/// preserved across switches — the tab widget stays mounted under the
/// stack while its sibling is foregrounded, instead of being rebuilt
/// from scratch the way a PageView or conditional `body:` would force.
///
/// Layout (post the "Great Migration" — viewing vs manipulation split):
///   0. Dashboard — landing surface; "next shift" + cycle position.
///   1. Timeline  — viewing: chronological shift list + resolver-driven
///                  month grid behind an in-screen [List | Month] toggle.
///   2. Manage    — manipulation hub: generate rotation / add custom
///                  shift / pause schedule.
///   3. Alarms    — alarm-rule CRUD.
///   4. Sleep     — roster-aware bedtime plan + wind-down / sounds (UI).
///
/// Settings is intentionally NOT a bottom-nav destination — it's an
/// AppBar gear action on Calendar / Roster / Alarms and a top-right
/// overlay on Dashboard (which has no AppBar). That choice keeps the
/// nav bar in M3's recommended 3-5 destination range while preserving
/// one-tap reach from every screen.
///
/// The bottom bar uses Material 3 [NavigationBar] / [NavigationDestination],
/// which respects the app's `ThemeData` (dark M3 enabled in `RostrikApp`)
/// for surface, ripple, and selected-state styling.
///
/// A firing alarm is no longer a Flutter route: the native AlarmActivity draws
/// over this layout (in its own task) and tears itself down on dismiss, so
/// MainLayout neither pushes nor reacts to any wake screen.
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  /// Default landing tab: Dashboard (index 0). Post-alarm dismiss also
  /// lands here — the Dashboard's "next shift" countdown is the most
  /// useful surface to see at 04:00 after acknowledging an alarm.
  int _currentIndex = 0;

  static const int _dashboardTab = 0;

  /// Home-screen-widget click subscription (Phase 2); null off Android/iOS.
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    _wireWidgetDeepLink();
  }

  @override
  void dispose() {
    _widgetClickSub?.cancel();
    super.dispose();
  }

  /// Tapping the home-screen widget deep-links here. We land on the Dashboard
  /// tab — the widget mirrors the Dashboard hero, so that's the "same" surface.
  /// Guarded so the plugin channels are never touched off Android/iOS (desktop /
  /// the test VM would throw `MissingPluginException`).
  void _wireWidgetDeepLink() {
    bool mobile;
    try {
      mobile = Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      mobile = false;
    }
    if (!mobile) return;

    // Cold launch straight from the widget.
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null && mounted) _goToDashboard();
    }).catchError((Object _) {});

    // Warm launch — app already running, brought forward by the widget tap.
    _widgetClickSub = HomeWidget.widgetClicked.listen(
      (uri) {
        if (uri != null && mounted) _goToDashboard();
      },
      onError: (Object _) {},
    );
  }

  /// Dismisses any pushed routes (Settings, an open editor) so the Dashboard is
  /// actually visible, then selects its tab. `singleTop` MainActivity already
  /// prevents a duplicate task / back-stack entry from the launch itself.
  void _goToDashboard() {
    Navigator.of(context).popUntil((r) => r.isFirst);
    if (_currentIndex != _dashboardTab) {
      setState(() => _currentIndex = _dashboardTab);
    }
  }

  /// Switches the foreground tab. Passed down to [DashboardScreen] so its
  /// "My Rotation" tile can jump to the Calendar / Roster tabs without each
  /// child needing a handle on this State.
  void _openTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    // Tabs are stable by position + runtimeType across rebuilds, which is the
    // invariant `IndexedStack` relies on to preserve each tab's internal State.
    // Only Dashboard is non-const (it carries the `_openTab` callback); the
    // others stay const. Rebuilding the Dashboard widget each frame is cheap
    // and does NOT reset its State (same runtimeType at index 0).
    final tabs = <Widget>[
      DashboardScreen(onOpenTab: _openTab),
      const TimelineScreen(),
      const ManageScreen(),
      const AlarmsScreen(),
      const SleepScreen(),
    ];
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: tabs,
          ),
          // First-run coaching tip for the CURRENT tab. Overlaid at the layout
          // level (not inside each screen) so it works uniformly whether or not
          // a screen has its own AppBar, and so only the foregrounded tab's tip
          // ever shows despite every tab staying mounted in the IndexedStack.
          _CurrentTabTip(tabIndex: _currentIndex),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          // Timeline merges the chronological list + the month grid behind an
          // in-screen [ List View | Month View ] toggle.
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Timeline',
          ),
          // Manage is the roster-manipulation hub (generate / add / pause).
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Manage',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_alarm),
            label: 'Alarms',
          ),
          NavigationDestination(
            icon: Icon(Icons.bedtime_outlined),
            selectedIcon: Icon(Icons.bedtime),
            label: 'Sleep',
          ),
        ],
      ),
    );
  }
}

/// Renders the one-time coaching tip for [tabIndex], or nothing when tips are
/// off / already seen / the settings box isn't available. Subscribes to the
/// settings box so a dismissal or a "Show screen tips" re-enable from Settings
/// updates the overlay live.
class _CurrentTabTip extends StatelessWidget {
  const _CurrentTabTip({required this.tabIndex});

  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    // The box is opened in main() before runApp; guard anyway so a stray
    // MainLayout pump (e.g. a future test) degrades to no overlay, not a throw.
    if (!Hive.isBoxOpen('settings')) return const SizedBox.shrink();
    if (tabIndex < 0 || tabIndex >= kScreenTips.length) {
      return const SizedBox.shrink();
    }
    final box = Hive.box('settings');
    final tip = kScreenTips[tabIndex];
    return ValueListenableBuilder<Box>(
      valueListenable: box.listenable(keys: ScreenTipsPrefs.watchedKeys),
      builder: (context, box, _) {
        if (!ScreenTipsPrefs.shouldShow(box, tip)) {
          return const SizedBox.shrink();
        }
        return ScreenTipOverlay(
          tip: tip,
          onDismiss: () => ScreenTipsPrefs.markSeen(box, tip.tipKey),
          onDisable: () => ScreenTipsPrefs.setEnabled(box, false),
        );
      },
    );
  }
}
