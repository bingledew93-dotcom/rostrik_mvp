# Rostrik — working TODO

Living checklist. iOS-specific mechanics live in
[`ios/IOS_SETUP.md`](ios/IOS_SETUP.md); this is the ordering and the decisions.

---

## 1. Tomorrow: finish the device verification pass

Implemented but never confirmed on hardware. Each is a real risk, not a
formality — today proved how much can look fine and do nothing.

- [x] **Alarm fires with the app force-quit** — verified 2026-08-27.
- [x] **One-time alarms retire after firing** — backgrounded, force-quit, and
      cleared from Notification Center. Verified 2026-08-27; see §1.1.
- [x] **Alarm tones ring for ~28s** rather than the tone's raw 4.7s length.
- [ ] **Snooze from a force-quit app.** Snooze writes `pending_snoozes` and
      re-arms; the drain only runs on next launch. This is the path where the
      ledger design earns its keep, and the one most likely to be subtly wrong.
- [ ] **Sleep sound with the screen locked** — the `audio` background mode is
      declared but unproven. If it stops on lock, the mode isn't taking effect.
- [ ] **Custom-tone preview** — needs any audio file on the device. Do *not*
      buy anything (§2.1 explains why the whole feature is a lie on iOS).
- [ ] Background refresh rolls the 14-day horizon (Xcode `_simulateLaunch…`,
      command in IOS_SETUP.md §5).
- [ ] OCR scanner: camera → crop → parse.
- [ ] Calendar sync creates the "Rostrik Roster" calendar.
- [ ] Light and dark theme.

### 1.1 One-time alarm retirement — closed

A fired one-time alarm is now retired by three layers, deepest first:

1. **The anchor** (`AppAlarm.oneTimeFireAt`) — the absolute instant the alarm
   was set for. Needs no OS cooperation at all: a spent alarm is recognisable
   offline, from a cold start, days later. This is what makes the guarantee
   unconditional rather than best-effort.
2. **The notification response** — a tap or an explicit dismiss, plus a nudge
   into Dart so cleanup is immediate rather than waiting for a later resume.
   `.customDismissAction` on the category is what makes a *cleared* notification
   deliver a response at all.
3. **A sweep of still-delivered notifications**, as a backstop for ignored ones.

Verified on device 2026-08-27: backgrounded, force-quit, and — the case that
defeated the previous build — cleared from Notification Center without opening
the app.

Legacy one-time alarms (written before the anchor existed) read a null anchor
and deliberately keep the old rolling behaviour: their intended date cannot be
reconstructed, and deleting an alarm the user may still rely on is the worse
failure. They self-correct on the next edit.

---

## 2. iOS capability & conditional availability

The goal: **never show a control that silently does nothing.** That is exactly
the failure mode that cost a full day — a channel that answered and did nothing,
a toggle that could never be granted. The UI should be as honest as the engine.

Two different kinds of unavailability, and conflating them produces nonsense
labels like "Requires iOS 26" on something iOS 26 also cannot do:

| Capability | Android | iOS 15.5–18 | iOS 26+ (AlarmKit) |
|---|---|---|---|
| Alarm fires, bundled tone | ✅ | ✅ | ✅ |
| Reminders / wind-down nudges | ✅ | ✅ | ✅ |
| Sleep sounds | ✅ | ✅ | ✅ |
| Snooze | ✅ full-screen | ✅ notification action | ✅ system UI |
| Sound past ~30s | ✅ | ❌ | ✅ |
| Pierces silent switch / Focus | ✅ | ❌ | ✅ |
| Real alarm presentation | ✅ own activity | ❌ notification only | ✅ system UI |
| **Sustained vibration** | ✅ | ❌ one buzz | ❌ never |
| **Shake to dismiss / hold fail-safe** | ✅ | ❌ | ❌ never |
| **Custom tone from a file** | ✅ | ❌ | ❌ never |
| **System ringtone picker** | ✅ | ❌ | ❌ never |
| Home-screen widget | ✅ | ❌ not built | ❌ not built |

Rule: **never available on this platform → hide it.** Don't tease something the
user can never have. **Available on a newer OS → disable + "Requires iOS 26".**

### 2.1 Phase A — platform honesty ✅ done 2026-08-27

`AlarmCapabilities` (`lib/alarms/alarm_capabilities.dart`) is now the single
source of truth; the UI asks it instead of checking `Platform` ad-hoc. Hidden on
iOS: the Critical-shift toggle, both custom tone sources, the Vibrate toggle,
the walkthrough's shake lesson **and its preview on the intro page**, and the
shake mention in Settings. `RingtonePreviewPlugin.swift` was removed with the pickers — a preview
for a tone that cannot be selected is theatre.

Built Dart-side rather than native-resolved, deviating from the original plan
here: every distinction is currently platform-level and iOS always runs the
notification backend, so `Platform` answers correctly and a native round-trip
would be speculative plumbing. **When AlarmKit lands, `AlarmCapabilities.current`
should be fed from the `rostrik/native_alarms` channel** — which backend actually
initialised is then a runtime fact only native knows. Call sites do not change;
they already ask the object, not the platform.

The default profile is `android`, so existing widget tests keep asserting the
full-featured UI; iOS behaviour is proven by explicit `debugOverride` tests.

### 2.2 Phase B — implement AlarmKit (needs an iOS 26 device)

`AlarmKitBackend` is a stub failing loudly behind `alarmKitEnabled = false`.
That gate stays until an alarm has actually rung on hardware — flipping it early
would give the *newest* iPhones no alarms while older ones worked.

- [ ] Research the real AlarmKit API surface. The existing stub was written
      blind with no compiler and its type/method names are guesses — treat them
      as a sketch, not a starting point to trust.
- [ ] Widget extension for AlarmKit's alert presentation (see §2.4 — verify
      whether this needs the paid account).
- [ ] Authorisation flow, using `NSAlarmKitUsageDescription` (already in
      Info.plist). Must follow the Phase A rule: request only when the app is
      interactive, never during `main()` (IOS_SETUP.md §1.1).
- [ ] Keep failing loudly until proven. A silent success is the worst outcome:
      an alarm the app believes is set that never rings.
- [ ] Only then flip `alarmKitEnabled = true`.

### 2.3 Phase C — version-conditional UI (only after B works)

- [ ] "Requires iOS 26" treatment for `soundBeyond30s`,
      `piercesSilentSwitch`, `realAlarmPresentation`.
- [ ] Honest disclosure on iOS < 26 that the alarm is weaker: ~30s of sound and
      the ring switch silences it. Better a user who knows than one who
      oversleeps. Worth surfacing in onboarding, not buried in Settings.
- [ ] Decide the App Store positioning — the store copy currently describes
      Android-strength alarms.

### 2.4 Blocked on the paid Developer Programme

- [ ] In-App Purchase capability (Xcode refuses to register the App ID on a free
      personal team).
- [ ] App Groups → the iOS home-screen widget (IOS_SETUP.md §4.3).
- [ ] TestFlight.
- [ ] When enrolled: `DEVELOPMENT_TEAM` changes from `LM6TRKQX8F` to the real
      team id — a one-line `project.pbxproj` commit. (Unrelated to git identity.)

---

## 3. Tech debt worth clearing

- [ ] **Reclaim ~3.9 MB from the Android bundle** (IOS_SETUP.md §4.1). Move the
      alarm tones to the iOS bundle-resource pattern the sleep sounds already
      use; this also deletes `ios_alarm_sound_installer.dart` outright, since
      `UNNotificationSound(named:)` searches the main bundle.
- [ ] Trim/downsample the WAVs — 16-bit PCM, several >1 MB for a ~10 s loop.
      Cuts cost on both platforms.
- [x] ~~iOS dismissal ledger~~ — assessed 2026-08-27 and **deliberately not
      built**. Nothing user-facing depends on `isAcknowledged` enough to justify
      it: suppression uses per-ring `dismissedAlarmIds`, and its only readers
      skip a future shift the user has dealt with, which on iOS just means the
      Dashboard keeps showing a shift that genuinely is still ahead. See
      IOS_SETUP.md §4.4. Still the reason there is no explicit Dismiss action.
- [ ] Google ML Kit blocks Apple-Silicon simulators entirely (no arm64 sim
      slice + Xcode 26 dropped Rosetta). Device-only testing for now; revisit if
      a maintained OCR alternative appears.
- [ ] `macos/` scaffold picked up a `Podfile` from a stray `pod install`. Harmless,
      but the macOS target is undeveloped — decide whether to support or remove it.

---

## 4. Decision needed: which device runs iOS 26

The **iPhone SE 3 is almost certainly iOS 26-capable** (A15; iOS 26 supports
roughly A13/iPhone 11 and later) — so a second phone may not be needed. But
updating it has a real cost: it is currently the *only* hardware proof that the
iOS 15.5–18 notification fallback works, and that fallback is what every
non-26 user will run.

Recommendation: **don't update the SE yet.** Phase A needs no iOS 26, and the
fallback is the path most users will be on. Decide when Phase B actually starts —
by then either update it and accept re-verifying the fallback elsewhere, or pick
up a cheap second device.
