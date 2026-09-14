import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
// Referencing the symbol through `main.dart` is the point: if the entrypoint
// moves out of the root library again, this file stops compiling.
import 'package:rostrik_mvp/main.dart' as app show syncAlarmsBackgroundEntrypoint;

/// The headless alarm re-sync is started BY NAME from native code, which no
/// Dart analyzer or compiler checks. From May to September 2026 the function
/// lived in a library nothing imported, so it was never compiled into the app:
/// every Android WorkManager run and iOS background refresh timed out looking
/// for it, silently. These tests pin the three things that must line up.
void main() {
  const entrypoint = 'syncAlarmsBackgroundEntrypoint';
  const channel = 'rostrik/alarm_sync_background';

  String read(String path) => File(path).readAsStringSync();

  test('main.dart declares the entrypoint with vm:entry-point', () {
    expect(app.syncAlarmsBackgroundEntrypoint, isA<void Function()>());
    // Without the pragma, AOT tree-shaking drops a function main() never
    // calls, so release builds would lose it even though it is declared.
    expect(
      RegExp(
        r"@pragma\('vm:entry-point'\)\s*void\s+" + entrypoint + r'\(\)',
      ).hasMatch(read('lib/main.dart')),
      isTrue,
    );
  });

  test('Android worker starts the entrypoint by the same bare name', () {
    final worker = read(
      'android/app/src/main/kotlin/com/example/rostrik_mvp/AlarmSyncWorker.kt',
    );
    // A bare name resolves against the root library (main.dart) only.
    expect(worker, contains('DART_ENTRYPOINT = "$entrypoint"'));
    expect(worker, contains('CHANNEL = "$channel"'));
  });

  test('iOS background task starts the entrypoint by the same bare name', () {
    final delegate = read('ios/Runner/AppDelegate.swift');
    expect(delegate, contains('run(withEntrypoint: "$entrypoint")'));
    expect(delegate, contains('"$channel"'));
  });

  test('the Dart side answers on the channel both platforms use', () {
    expect(
      read('lib/alarms/background_sync_entrypoint.dart'),
      contains("'$channel'"),
    );
  });
}
