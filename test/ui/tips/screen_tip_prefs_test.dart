import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:rostrik_mvp/ui/tips/screen_tip.dart';

void main() {
  late Directory tempDir;
  late Box box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rostrik_tips_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  final tip = kScreenTips.first;

  test('defaults: enabled, unseen → shouldShow', () {
    expect(ScreenTipsPrefs.isEnabled(box), isTrue);
    expect(ScreenTipsPrefs.isSeen(box, tip.tipKey), isFalse);
    expect(ScreenTipsPrefs.shouldShow(box, tip), isTrue);
  });

  test('markSeen hides that one tip', () async {
    await ScreenTipsPrefs.markSeen(box, tip.tipKey);
    expect(ScreenTipsPrefs.isSeen(box, tip.tipKey), isTrue);
    expect(ScreenTipsPrefs.shouldShow(box, tip), isFalse);
    // Other tips are unaffected.
    expect(ScreenTipsPrefs.shouldShow(box, kScreenTips[1]), isTrue);
  });

  test('disabling hides every tip', () async {
    await ScreenTipsPrefs.setEnabled(box, false);
    expect(ScreenTipsPrefs.isEnabled(box), isFalse);
    for (final t in kScreenTips) {
      expect(ScreenTipsPrefs.shouldShow(box, t), isFalse);
    }
  });

  test('re-enabling replays every tip (clears seen flags)', () async {
    // Dismiss all, then turn the master switch back on.
    for (final t in kScreenTips) {
      await ScreenTipsPrefs.markSeen(box, t.tipKey);
    }
    await ScreenTipsPrefs.setEnabled(box, false);
    await ScreenTipsPrefs.setEnabled(box, true);

    expect(ScreenTipsPrefs.isEnabled(box), isTrue);
    for (final t in kScreenTips) {
      expect(ScreenTipsPrefs.isSeen(box, t.tipKey), isFalse);
      expect(ScreenTipsPrefs.shouldShow(box, t), isTrue);
    }
  });

  test('watchedKeys covers the enabled flag and every tip seen flag', () {
    expect(ScreenTipsPrefs.watchedKeys, contains(ScreenTipsPrefs.enabledKey));
    for (final t in kScreenTips) {
      expect(
        ScreenTipsPrefs.watchedKeys,
        contains(ScreenTipsPrefs.seenKey(t.tipKey)),
      );
    }
  });
}
