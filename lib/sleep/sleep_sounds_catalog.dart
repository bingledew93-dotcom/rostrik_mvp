import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Locale-aware display name for a sleep sound, keyed by its stable
/// [SleepSound.resource]. The catalogue's [SleepSound.label] stays as the
/// English fallback so an unknown resource still renders something.
String sleepSoundLabel(SleepSound s) {
  final l10n = currentL10n;
  switch (s.resource) {
    case 'sleep_white_noise':
      return l10n.sleepSoundWhiteNoise;
    case 'sleep_pink_noise':
      return l10n.sleepSoundPinkNoise;
    case 'sleep_brown_noise':
      return l10n.sleepSoundBrownNoise;
    case 'sleep_fan':
      return l10n.sleepSoundFan;
    case 'sleep_ocean':
      return l10n.sleepSoundOcean;
    case 'sleep_rain':
      return l10n.sleepSoundRain;
    default:
      return s.label;
  }
}

/// One selectable sleep sound. [resource] is the Android `res/raw` file name
/// (without extension) the native [SleepSoundService] loads; [label] and [icon]
/// are presentation.
class SleepSound {
  const SleepSound({
    required this.resource,
    required this.label,
    required this.icon,
  });

  final String resource;
  final String label;
  final IconData icon;
}

/// The 6 bundled white/brown-noise sleep sounds, in display order. Each
/// [SleepSound.resource] maps to a looping WAV in
/// `android/app/src/main/res/raw/` (generated, seamless-looping).
const List<SleepSound> kSleepSounds = <SleepSound>[
  SleepSound(
    resource: 'sleep_white_noise',
    label: 'White Noise',
    icon: Icons.graphic_eq,
  ),
  SleepSound(
    resource: 'sleep_pink_noise',
    label: 'Pink Noise',
    icon: Icons.blur_on,
  ),
  SleepSound(
    resource: 'sleep_brown_noise',
    label: 'Brown Noise',
    icon: Icons.surround_sound,
  ),
  SleepSound(
    resource: 'sleep_fan',
    label: 'Fan',
    icon: Icons.air,
  ),
  SleepSound(
    resource: 'sleep_ocean',
    label: 'Ocean',
    icon: Icons.waves,
  ),
  SleepSound(
    resource: 'sleep_rain',
    label: 'Rain',
    icon: Icons.grain,
  ),
];
