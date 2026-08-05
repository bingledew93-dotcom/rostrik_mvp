import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:rostrik_mvp/alarms/default_tone_prefs.dart';
import 'package:rostrik_mvp/data/models/ringtone_source.dart';

void main() {
  late Directory tempDir;
  late Box box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rostrik_tone_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('defaults to the classic bundled tone', () {
    final d = DefaultTonePrefs.read(box);
    expect(d.soundKey, 'classic');
    expect(d.source, RingtoneSource.classic);
    expect(d.uri, isNull);
    expect(d.isCustom, isFalse);
  });

  test('round-trips a bundled tone', () async {
    await DefaultTonePrefs.write(
      box,
      const DefaultTone(soundKey: 'siren', source: RingtoneSource.classic),
    );
    final d = DefaultTonePrefs.read(box);
    expect(d.soundKey, 'siren');
    expect(d.source, RingtoneSource.classic);
    expect(d.isCustom, isFalse);
  });

  test('round-trips a system tone', () async {
    await DefaultTonePrefs.write(
      box,
      const DefaultTone(
        soundKey: 'classic',
        source: RingtoneSource.system,
        uri: 'content://media/1',
        name: 'My Tone',
      ),
    );
    final d = DefaultTonePrefs.read(box);
    expect(d.source, RingtoneSource.system);
    expect(d.uri, 'content://media/1');
    expect(d.name, 'My Tone');
    expect(d.isCustom, isTrue);
  });

  test('writing a bundled tone over a system one clears the uri/name', () async {
    await DefaultTonePrefs.write(
      box,
      const DefaultTone(
        soundKey: 'classic',
        source: RingtoneSource.system,
        uri: 'content://media/1',
        name: 'My Tone',
      ),
    );
    await DefaultTonePrefs.write(
      box,
      const DefaultTone(soundKey: 'digital', source: RingtoneSource.classic),
    );
    final d = DefaultTonePrefs.read(box);
    expect(d.soundKey, 'digital');
    expect(d.uri, isNull);
    expect(d.name, isNull);
    expect(d.isCustom, isFalse);
  });
}
