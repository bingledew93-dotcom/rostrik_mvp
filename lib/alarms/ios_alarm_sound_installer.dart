import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'alarm_sound.dart';

/// Copies the bundled alarm tones into the iOS app container's
/// `Library/Sounds/`, where `UNNotificationSound(named:)` resolves them.
///
/// ## Why this had to be rebuilt
///
/// `alarm_sound.dart` has always documented this copy as the job of
/// `LocalNotificationsAlarmScheduler.init`. That class went away with
/// `flutter_local_notifications` when the alarm path became fully native, and
/// the copy went with it — leaving `AlarmSound.iosSoundName` with no callers
/// anywhere in the app. Android never noticed, because it plays tones from
/// `res/raw` and never touches this path. iOS would have: a notification naming
/// a sound file that does not exist falls back to the default chime, so every
/// Rostrik alarm would have rung with the wrong tone and nothing would have
/// looked broken enough to investigate.
///
/// ## Why `Library/Sounds` specifically
///
/// `UNNotificationSound(named:)` searches the main bundle and the app
/// container's `Library/Sounds/`. Flutter assets land in the bundle under
/// `Frameworks/App.framework/flutter_assets/`, which that lookup does NOT
/// search — so the file has to be physically copied out at runtime. The upside
/// is that no Xcode bundle-membership step is needed for the tones: adding a
/// tone to [kAlarmSounds] and dropping its WAV in `assets/sounds/` is enough.
///
/// No-ops on every non-iOS platform and never throws: a tone that fails to
/// install degrades to the system default sound, which is far better than an
/// exception in `main()` stranding the app on the splash screen.
Future<void> installIosAlarmSounds() async {
  if (!_isIOS) return;
  try {
    final library = await getLibraryDirectory();
    final soundsDir = Directory('${library.path}/Sounds');
    if (!await soundsDir.exists()) {
      await soundsDir.create(recursive: true);
    }

    for (final sound in kAlarmSounds) {
      final destination = File('${soundsDir.path}/${sound.iosSoundName}');
      // Skip work already done. The tones are immutable for the life of a
      // build, so re-copying several MB on every cold start would be pure
      // startup cost — but a length mismatch means a partial write from an
      // interrupted previous run, which must be redone.
      final expected = await _tryLoadAsset(sound.assetPath);
      if (expected == null) {
        // The asset is not bundled. `assets/sounds/` currently holds only its
        // README; see ios/IOS_SETUP.md. Nothing to install, and deliberately
        // not an error — the alarm still rings, just with the default tone.
        continue;
      }
      if (await destination.exists() &&
          await destination.length() == expected.lengthInBytes) {
        continue;
      }
      await destination.writeAsBytes(
        expected.buffer.asUint8List(
          expected.offsetInBytes,
          expected.lengthInBytes,
        ),
        flush: true,
      );
    }
  } catch (e) {
    debugPrint('[installIosAlarmSounds] failed: $e');
  }
}

Future<ByteData?> _tryLoadAsset(String path) async {
  try {
    return await rootBundle.load(path);
  } catch (_) {
    return null;
  }
}

/// `Platform` throws on web, so the check is guarded rather than read directly.
bool get _isIOS {
  try {
    return Platform.isIOS;
  } catch (_) {
    return false;
  }
}
