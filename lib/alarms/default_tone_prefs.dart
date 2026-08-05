import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/models/ringtone_source.dart';
import 'alarm_sound.dart';

/// The tone a NEW alarm starts on — the user's remembered preference. Picking a
/// bundled or system tone in the create/edit sheet updates this, so the next
/// alarm the user makes is already set to the sound they like.
class DefaultTone {
  const DefaultTone({
    required this.soundKey,
    required this.source,
    this.uri,
    this.name,
  });

  final String soundKey;
  final RingtoneSource source;
  final String? uri;
  final String? name;

  /// Whether this default is a custom (system) tone rather than a bundled one.
  bool get isCustom => source != RingtoneSource.classic && name != null;
}

/// Reads/writes the default alarm tone on the always-open `settings` box.
/// Hive-guarded (returns the classic bundled tone when the box isn't open) so a
/// widget test that never opened the box degrades sensibly rather than throwing.
///
/// Only bundled (`classic`) and `system` tones are ever stored here. A `vault`
/// (file) tone is per-alarm — its file is deleted when the owning alarm re-picks
/// (see `_maybeDeletePreviousVaultFile`), so making it a shared default would
/// leave new alarms pointing at a file that can vanish. File tones therefore
/// stay alarm-local and never change the default.
class DefaultTonePrefs {
  DefaultTonePrefs._();

  static const String _soundKeyKey = 'default_tone_sound_key';
  static const String _sourceKey = 'default_tone_source';
  static const String _uriKey = 'default_tone_uri';
  static const String _nameKey = 'default_tone_name';

  static DefaultTone read(Box box) {
    final soundKey =
        box.get(_soundKeyKey, defaultValue: kDefaultAlarmSoundKey) as String;
    final sourceIdx =
        box.get(_sourceKey, defaultValue: RingtoneSource.classic.index) as int;
    final source = (sourceIdx >= 0 && sourceIdx < RingtoneSource.values.length)
        ? RingtoneSource.values[sourceIdx]
        : RingtoneSource.classic;
    return DefaultTone(
      soundKey: soundKey,
      source: source,
      uri: box.get(_uriKey) as String?,
      name: box.get(_nameKey) as String?,
    );
  }

  /// Persists [tone] as the default. Never call this with a vault tone (see the
  /// class doc); callers gate on the source.
  static Future<void> write(Box box, DefaultTone tone) async {
    await box.put(_soundKeyKey, tone.soundKey);
    await box.put(_sourceKey, tone.source.index);
    if (tone.uri == null) {
      await box.delete(_uriKey);
    } else {
      await box.put(_uriKey, tone.uri);
    }
    if (tone.name == null) {
      await box.delete(_nameKey);
    } else {
      await box.put(_nameKey, tone.name);
    }
    await box.flush();
  }
}
