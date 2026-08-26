# Rostrik — working TODO

Living checklist. iOS-specific mechanics live in
[`ios/IOS_SETUP.md`](ios/IOS_SETUP.md); this is the ordering and the decisions.

---

## 1. Tomorrow: finish the device verification pass

Implemented but never confirmed on hardware. Each is a real risk, not a
formality — today proved how much can look fine and do nothing.

- [ ] **Alarm fires with the app force-quit** — the single most important test.
      Nothing else in the app matters if this fails.
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
| **Shake to dismiss / hold fail-safe** | ✅ | ❌ | ❌ never |
| **Custom tone from a file** | ✅ | ❌ | ❌ never |
| **System ringtone picker** | ✅ | ❌ | ❌ never |
| Home-screen widget | ✅ | ❌ not built | ❌ not built |

Rule: **never available on this platform → hide it.** Don't tease something the
user can never have. **Available on a newer OS → disable + "Requires iOS 26".**

### 2.1 Phase A — platform honesty (do first, no AlarmKit needed)

Independently valuable, testable on the SE today, and fixes live misleading UI.
This is the phase that matters most and it is the smallest.

- [ ] **Capability layer.** One source of truth, resolved **natively** and
      handed to Dart — not inferred in Dart from `Platform.operatingSystemVersion`.
      Only the native side knows the OS version *and* which alarm backend
      actually initialised. A Dart-side guess would drift from reality, which is
      the same "app believes something works" class of bug as today's.
      Suggested shape: `AlarmCapabilities` over the existing
      `rostrik/native_alarms` channel — `shakeToDismiss`, `customToneFromFile`,
      `systemTonePicker`, `soundBeyond30s`, `piercesSilentSwitch`,
      `realAlarmPresentation`, plus `backend` and `iosMajorVersion` for display.
- [ ] **Hide the "Critical shift" toggle on iOS.** Currently shown with the
      subtitle "Shake to dismiss · 3-second hold fail-safe" — neither exists on
      iOS. Decide whether `isCriticalShift` retains *any* iOS meaning; if not,
      hide the control and stop writing the flag there.
- [ ] **Fix the custom-tone lie.** Today: pick "MySong", UI shows "MySong",
      alarm rings `classic.wav`, because `_argIosSound` is always the bundled
      tone. Either hide the Files/System-Tone options on iOS (IOS_SETUP.md §3.5
      recommends this) or show the real fallback tone in the row. Hiding is
      honest; showing a fallback label is honest; today's state is not.
- [ ] **Audit every remaining `Platform.isAndroid`** for a control that renders
      but no-ops. `ringtone_channel.pickSystemRingtone` is the known one.
- [ ] Walkthrough copy in `settings_screen.dart` mentions "shake-to-dismiss" —
      needs the same conditioning.

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
- [ ] **iOS dismissal ledger** (IOS_SETUP.md §4.4). A fired alarm is never
      marked acknowledged on iOS. Follow the file-based pattern that made snooze
      possible, *not* the `rostrik/alarm_routing` channel, which has no iOS
      handler. Until then, no explicit Dismiss action — it would mark nothing.
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
