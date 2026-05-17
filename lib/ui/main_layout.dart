import 'package:flutter/material.dart';

import 'alarms_screen.dart';
import 'calendar/calendar_screen.dart';
import 'dashboard_screen.dart';
import 'roster_screen.dart';

/// Root navigation chassis.
///
/// Four tabs swapped via an [IndexedStack] so each tab's `State`
/// (scroll position, filter, modal stack, calendar focused month) is
/// preserved across switches — the tab widget stays mounted under the
/// stack while its sibling is foregrounded, instead of being rebuilt
/// from scratch the way a PageView or conditional `body:` would force.
///
/// Layout (post the Calendar-promotion restructure):
///   0. Dashboard — landing surface; "next shift" + cycle position.
///   1. Calendar  — resolver-driven month grid (works for any past or
///                  future date via pure-Dart projection math, no need
///                  to read materialised shifts).
///   2. Roster    — chronological list of materialised shifts +
///                  filter chips + add-shift FAB.
///   3. Alarms    — alarm-rule CRUD.
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
/// Alarm routing: this widget is `pushAndRemoveUntil`'d as the only
/// route below WakeUpScreen when an alarm fires (see `_routeToWakeUp`
/// in main.dart). After WakeUpScreen dismisses it `pushReplacement`s
/// back to a fresh `MainLayout`, so the post-alarm landing is on the
/// chassis (Dashboard tab — see `_currentIndex` below).
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

  /// Tabs are const-constructed so their identity is stable across
  /// rebuilds of this State — that's the invariant `IndexedStack`
  /// relies on to preserve each tab's internal State.
  static const List<Widget> _tabs = <Widget>[
    DashboardScreen(),
    CalendarScreen(),
    RosterScreen(),
    AlarmsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          // Roster used to own `Icons.calendar_month`; with Calendar
          // promoted to its own tab, Roster relinquishes that metaphor
          // and becomes the chronological-list view.
          NavigationDestination(
            icon: Icon(Icons.view_list),
            label: 'Roster',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_alarm),
            label: 'Alarms',
          ),
        ],
      ),
    );
  }
}
