import 'package:flutter_test/flutter_test.dart';
import 'package:rostrik_mvp/alarms/alarm_sound.dart';
import 'package:rostrik_mvp/ui/alarm_sound_previewer.dart';

/// Records the exact ordered sequence of player calls so the previewer's
/// stop-before-play discipline can be asserted without a real audio device.
class _FakePreviewAudioPlayer implements PreviewAudioPlayer {
  final List<String> calls = [];

  @override
  Future<void> play(String assetKey) async => calls.add('play:$assetKey');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

void main() {
  AlarmSound sound(String key) => resolveAlarmSound(key);

  group('previewAssetKey', () {
    test('strips the leading assets/ for audioplayers AssetSource', () {
      expect(previewAssetKey('assets/sounds/classic.wav'), 'sounds/classic.wav');
    });

    test('leaves an already-relative path untouched', () {
      expect(previewAssetKey('sounds/x.wav'), 'sounds/x.wav');
    });
  });

  group('AlarmSoundPreviewer overlap guard', () {
    test('a single preview stops before it plays', () async {
      final fake = _FakePreviewAudioPlayer();
      await AlarmSoundPreviewer(player: fake).preview(sound('classic'));
      expect(fake.calls, ['stop', 'play:sounds/classic.wav']);
    });

    test('rapid previews never overlap — each play is preceded by a stop',
        () async {
      final fake = _FakePreviewAudioPlayer();
      final previewer = AlarmSoundPreviewer(player: fake);

      await previewer.preview(sound('classic'));
      await previewer.preview(sound('siren'));
      await previewer.preview(sound('digital'));

      expect(fake.calls, [
        'stop', 'play:sounds/classic.wav',
        'stop', 'play:sounds/siren.wav',
        'stop', 'play:sounds/digital.wav',
      ]);
    });
  });

  group('AlarmSoundPreviewer lifecycle', () {
    test('stop() forwards to the player', () async {
      final fake = _FakePreviewAudioPlayer();
      await AlarmSoundPreviewer(player: fake).stop();
      expect(fake.calls, ['stop']);
    });

    test('dispose() disposes the player', () async {
      final fake = _FakePreviewAudioPlayer();
      await AlarmSoundPreviewer(player: fake).dispose();
      expect(fake.calls, ['dispose']);
    });

    test('preview after dispose is a no-op (no resurrected audio)', () async {
      final fake = _FakePreviewAudioPlayer();
      final previewer = AlarmSoundPreviewer(player: fake);
      await previewer.dispose();
      await previewer.preview(sound('siren'));
      await previewer.stop();
      expect(fake.calls, ['dispose'],
          reason: 'no stop/play may run after dispose');
    });

    test('dispose is idempotent', () async {
      final fake = _FakePreviewAudioPlayer();
      final previewer = AlarmSoundPreviewer(player: fake);
      await previewer.dispose();
      await previewer.dispose();
      expect(fake.calls, ['dispose']);
    });
  });
}
