# Bundled alarm tones

Drop the 4 beta tones here. **Format (Option 1 — WAV-everywhere):**

> **16-bit PCM WAV · 44.1 kHz · mono · ~8–15 s**

WAV is the one encoding that clears all three subsystems (Android `res/raw`,
iOS `UNNotificationSound`, and the in-app `audioplayers` preview). **Do not use
`.mp3`** — it is not a valid iOS notification-sound format.

Author each clip as a **seamless loop with no leading/trailing silence**:
Android loops it via `FLAG_INSISTENT`; iOS plays it once (≤30 s).

## Files to place (one master per tone → two locations)

| key       | this folder (preview + iOS source) | `android/app/src/main/res/raw/` (Android channel) |
|-----------|-------------------------------------|----------------------------------------------------|
| `classic` | `assets/sounds/classic.wav`         | `res/raw/classic_alarm.wav`                        |
| `siren`   | `assets/sounds/siren.wav`           | `res/raw/siren.wav`                                |
| `digital` | `assets/sounds/digital.wav`         | `res/raw/digital.wav`                              |
| `chime`   | `assets/sounds/chime.wav`           | `res/raw/chime.wav`                                |

The catalog (keys, labels, channel IDs, resource names) lives in
[`lib/alarms/alarm_sound.dart`](../../lib/alarms/alarm_sound.dart) — the single
source of truth. Add a tone by adding a row there and dropping its two files.

`res/raw` names must be lowercase `a–z`/`0–9`/`_`, start with a letter, and
carry no hyphens, spaces, or uppercase. Android resolves them by bare name, so
two files differing only in extension would collide.

## iOS

No Xcode needed: these assets are copied into the app container's
`Library/Sounds/` at startup by `installIosAlarmSounds()`
([`lib/alarms/ios_alarm_sound_installer.dart`](../../lib/alarms/ios_alarm_sound_installer.dart)),
where `UNNotificationSound(named:)` resolves them by filename. Verified ringing
on device.

⚠️ **These four WAVs are duplicated weight in the Android bundle** (~3.9 MB):
Flutter assets are not per-platform, and Android plays its own `res/raw` copies
instead. The sleep sounds avoid this by being iOS bundle resources that
reference `res/raw` directly — see `ios/IOS_SETUP.md` §4.1 for moving the alarm
tones to that pattern, which would also delete the installer above.
