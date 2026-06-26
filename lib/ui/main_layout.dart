import 'package:flutter/material.dart';

import 'alarms_screen.dart';
import 'dashboard_screen.dart';
import 'manage/manage_screen.dart';
import 'sleep/sleep_screen.dart';
import 'timeline/timeline_screen.dart';

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
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
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
