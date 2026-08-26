#!/bin/bash
# Regenerates the iOS alarm tones in ios/Runner/Sounds/ from the Android masters
# in android/app/src/main/res/raw/.
#
# WHY THIS EXISTS
#
# iOS cannot loop a notification sound. Android plays alarm audio through a
# MediaPlayer with `isLooping = true`, so it rings until dismissed;
# `UNNotificationSound` plays its file exactly ONCE and there is no looping API.
# A 4.7s tone therefore meant a 4.7s alarm. The fix is to bake the repeats into
# the file itself, up to Apple's hard <30s limit for a custom notification sound
# (longer and iOS silently substitutes the default chime).
#
# Output is IMA4/ADPCM in a CAF container — one of the formats Apple documents
# for notification sounds, and ~4:1 smaller than the 16-bit PCM source, which
# very nearly cancels out the cost of the repeats. Mono, for the same reason: an
# alarm does not need a stereo image.
#
# These live in ios/Runner/Sounds/ as iOS BUNDLE RESOURCES, not Flutter assets.
# Flutter assets are not per-platform, so shipping them in assets/ would put
# several MB of never-read duplicates in the ANDROID bundle, which plays its own
# res/raw copies. Being in the main bundle is also what lets
# `UNNotificationSound(named:)` find them with no runtime copy into
# Library/Sounds — which is why ios_alarm_sound_installer.dart no longer exists.
#
# Usage: ./ios/tools/generate_alarm_tones.sh   (run from the repo root)

set -euo pipefail

RAW="android/app/src/main/res/raw"
OUT="ios/Runner/Sounds"
# Keep a margin under 30s: the cap is a hard cliff, not a fade.
MAX_SECONDS=29.0

if [ ! -d "$RAW" ]; then
  echo "error: run this from the repo root (missing $RAW)" >&2
  exit 1
fi
mkdir -p "$OUT"

# key:source — `classic` maps to classic_alarm.wav, matching AlarmSound.androidResource.
for pair in classic:classic_alarm siren:siren digital:digital chime:chime; do
  key="${pair%%:*}"
  src="$RAW/${pair##*:}.wav"
  [ -f "$src" ] || { echo "error: missing $src" >&2; exit 1; }

  tmp="$(mktemp -t "rostrik_${key}").wav"
  python3 - "$src" "$tmp" "$MAX_SECONDS" <<'PY'
import sys, wave
src, dst, cap = sys.argv[1], sys.argv[2], float(sys.argv[3])
with wave.open(src, 'rb') as w:
    params, frames = w.getparams(), w.readframes(w.getnframes())
    duration = params.nframes / params.framerate
# Whole repeats only — the tones are authored as seamless loops with no leading
# or trailing silence, so a partial repeat would be the only audible seam.
reps = max(1, int(cap // duration))
with wave.open(dst, 'wb') as o:
    o.setparams(params)
    o.writeframes(frames * reps)
print(f"  {duration:5.1f}s x{reps} -> {duration*reps:5.1f}s", end='')
PY

  afconvert -f caff -d ima4 -c 1 "$tmp" "$OUT/$key.caf"
  rm -f "$tmp"
  echo "   $(du -h "$OUT/$key.caf" | cut -f1)  $key.caf"
done

echo
echo "Wrote $(ls -1 "$OUT"/*.caf | wc -l | tr -d ' ') tones to $OUT"
echo "Filenames must match AlarmSound.iosSoundName in lib/alarms/alarm_sound.dart."
