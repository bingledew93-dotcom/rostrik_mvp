import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// A one-time coaching tip for a single main screen: what it's for and how to
/// use it, shown the first time a new user lands on that tab.
class ScreenTip {
  const ScreenTip({
    required this.tipKey,
    required this.icon,
    required this.title,
    required this.body,
  });

  /// Stable id used to persist the "seen" flag (`tip_seen_<tipKey>`). Never
  /// reuse or renumber — a changed key re-shows a tip the user already dismissed.
  final String tipKey;

  final IconData icon;
  final String title;
  final String body;
}

/// One tip per bottom-nav tab, in tab order (Dashboard, Timeline, Manage,
/// Alarms, Sleep). Index matches `MainLayout`'s tab index so the layout can look
/// the current tab's tip up directly.
const List<ScreenTip> kScreenTips = [
  ScreenTip(
    tipKey: 'dashboard',
    icon: Icons.home,
    title: 'Your dashboard',
    body: 'Home base. See your next shift with a live countdown and where you '
        'are in your rotation. Tap a tile to jump straight to the details.',
  ),
  ScreenTip(
    tipKey: 'timeline',
    icon: Icons.calendar_month,
    title: 'Your whole roster',
    body: 'Switch between a List and a Month calendar up top. Tap any day to '
        'edit a shift — or add an event, task or birthday.',
  ),
  ScreenTip(
    tipKey: 'manage',
    icon: Icons.tune,
    title: 'Build & adjust',
    body: 'Create a rotating roster, add a one-off (overtime) shift, or pause '
        'your whole schedule for leave — all from here.',
  ),
  ScreenTip(
    tipKey: 'alarms',
    icon: Icons.access_alarm,
    title: 'Your alarms',
    body: 'Every alarm your shifts create, plus any you add yourself. Tap one '
        'to change its time or tone, or make it a shake-to-dismiss Critical '
        'Shift alarm.',
  ),
  ScreenTip(
    tipKey: 'sleep',
    icon: Icons.bedtime,
    title: 'Sleep plan',
    body: 'A wind-down plan that follows your roster: set a sleep goal and get '
        'ready for your next shift feeling rested.',
  ),
];

/// Reads/writes the one-time screen-tip flags on the always-open `settings`
/// box. Static + Hive-guarded (mirrors the project's other box helpers) so it
/// degrades to sensible defaults when the box isn't open (e.g. a widget test
/// that never opened it) rather than throwing.
class ScreenTipsPrefs {
  ScreenTipsPrefs._();

  /// Master switch. Default true — a fresh install shows tips; the user can
  /// turn them off from the card or Settings.
  static const String enabledKey = 'screen_tips_enabled';

  static String seenKey(String tipKey) => 'tip_seen_$tipKey';

  /// Every settings key the tip system touches — what `MainLayout` listens on
  /// so the overlay reacts the instant a tip is dismissed or re-enabled.
  static List<String> get watchedKeys => [
        enabledKey,
        for (final t in kScreenTips) seenKey(t.tipKey),
      ];

  static bool isEnabled(Box box) =>
      box.get(enabledKey, defaultValue: true) as bool;

  static bool isSeen(Box box, String tipKey) =>
      box.get(seenKey(tipKey), defaultValue: false) as bool;

  /// Whether [tip] should be shown right now: tips on, and this one not yet
  /// dismissed.
  static bool shouldShow(Box box, ScreenTip tip) =>
      isEnabled(box) && !isSeen(box, tip.tipKey);

  static Future<void> markSeen(Box box, String tipKey) async {
    await box.put(seenKey(tipKey), true);
    await box.flush();
  }

  /// Turns the whole system on/off. Re-enabling REPLAYS every tip — it clears
  /// each per-screen seen flag — so "Show screen tips" in Settings brings them
  /// all back, which is the behaviour the user expects from that control.
  static Future<void> setEnabled(Box box, bool value) async {
    await box.put(enabledKey, value);
    if (value) {
      for (final t in kScreenTips) {
        await box.delete(seenKey(t.tipKey));
      }
    }
    await box.flush();
  }
}
