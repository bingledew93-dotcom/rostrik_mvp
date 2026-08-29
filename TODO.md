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
- [x] **Alarms keep alerting for ~4 minutes** via the repeat chain, and stop the
      instant they are dismissed — verified 2026-08-27 backgrounded and
      force-quit, including dismissal mid-chain.
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
| Sound past ~30s (single tone) | ✅ | ❌ | ✅ |
| Keeps alerting until dismissed | ✅ | ✅ repeat chain (~4 min) | ✅ |
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

### 2.2 Phase B — implement AlarmKit (in progress, 2026-08-27)

`alarmKitEnabled = false` still gates everything. That gate stays until an alarm
has actually rung on hardware — flipping it early would give the *newest*
iPhones no alarms while older ones worked.

**The API is no longer guesswork.** Xcode 26.6 ships the iOS 26.5 SDK, so the
authoritative surface is on disk at
`…/iPhoneOS26.5.sdk/System/Library/Frameworks/AlarmKit.framework/Modules/AlarmKit.swiftmodule/arm64e-apple-ios.swiftinterface`.
`AlarmKitBackend` is now written against it and **compiles**.

> ⚠️ The AlarmKit guide bundled with Xcode's assistant
> (`IDEIntelligenceChat.framework/…/SwiftUI-AlarmKit-Integration.md`) is wrong in
> specifics: it dates the framework to iOS 18, invents `AlarmButton(label:)` and
> `.stopButton` / `.snoozeButton` statics, and makes `cancel` async. Prefer the
> `.swiftinterface`, and let the compiler settle disputes.

Done:

- [x] Real API surface, verified by compiling — `AlarmManager.shared`,
      `.fixed(Date)`, `AlarmButton(text:textColor:systemImageName:)`,
      `AlertSound.named()` (so the bundled `.caf` tones carry over).
- [x] `schedule` / `cancel` / `aliveIds` implemented; `RostrikAlarmMetadata`
      carries `shiftId` + `appAlarmId`, the pair the Stop intent will need.
- [x] Authorisation flow, post-frame, chained after the notification prompt so
      the two system alerts queue rather than race (IOS_SETUP.md §1.1).

Also done, verified on device 2026-08-27 (iPhone SE 3, iOS 26.6.1):

- [x] **Alarm cap measured: ≥400.** 400 armed, none refused, all 400 confirmed
      live *before* cleanup. No hybrid split needed — AlarmKit carries the whole
      14-day horizon.
- [x] **The alert needs no widget extension.** Full-screen with slide-to-dismiss,
      banner when unlocked. Rings on silent, and for over five minutes.
- [x] **Nor does the countdown.** Native snooze via `postAlert` re-alerts with no
      widget target.
- [x] **`RostrikStopAlarmIntent`** — verified end to end on real alarms: stop →
      deletes ledger → Dart drain → rule retired, and the reconciler does not
      re-arm it. The daily-alarm bug does not reproduce.
- [x] **`RostrikSnoozeAlarmIntent`** — verified with a real rule UUID: snooze →
      ledger → drain → re-armed at the snooze instant, and the Dashboard
      dismiss control appears.
- [x] **Runtime backend switch** so real alarms can run on either backend.

⚠️ **Two snooze mechanisms now coexist**: AlarmKit's native `postAlert` countdown
AND Dart re-arming from the snooze ledger. They do not double-alert, but only
because both target the same instant *and* the same alarm UUID, so
cancel-then-schedule collapses them. If either ever computed a different instant,
the user would get two alarms. Worth a test pinning that invariant.

Open, in the order that de-risks fastest:

- [x] **Alarm cap raised under AlarmKit** — 50, matching Android, with no repeat
      chains. `AlarmBackendInfo` carries which backend is live; the budgets are
      now read per reconcile rather than captured at construction, so the
      runtime switch takes effect without a relaunch.
- [x] **Two-snooze invariant pinned** — a re-armed snooze must reuse the SAME id
      and instant, which is the only reason AlarmKit's countdown and Dart's
      re-arm collapse into one alarm instead of two.
- [x] **Default flipped on** for iOS 26. `object(forKey:)` rather than
      `bool(forKey:)` distinguishes "never set" from "explicitly false", so a
      deliberate kill-switch is not overridden by the default next launch.
- [x] **AlarmKit authorisation now requested in RELEASE builds.** It was only
      asked from the debug-gated bring-up, so a shipped build would never have
      prompted — and with the default on, `schedule` fails unauthorised, which
      would have meant **no alarms at all**. `makeBackend` now also requires
      authorisation before selecting AlarmKit, so a denied prompt costs the user
      the weaker alarm rather than silence.
- [ ] Phase C messaging (§2.3) — `soundBeyondThirtySeconds`,
      `piercesSilentSwitch` and `fullScreenAlarm` are all *true* under AlarmKit
      but are consumed nowhere yet.

**DEBUG · ALARMKIT stays in Settings** — an earlier note here said to strip it
before merge; that was wrong. It is gated on `kReleaseMode`, not `kDebugMode`,
so it cannot reach a shipped build, and it is the only way to exercise either
backend on a device now that the one test phone runs iOS 26. Deleting a tool
that cannot ship, to guard against a risk it does not carry, would only cost the
next person the ability to test.

⚠️ **The notification path now has no hardware to test it on** (§4). It is still
the majority path and the permanent one for pre-26 devices. Treat any change to
`NotificationBackend` as unverified.

### 2.2b Custom tones on iOS — reopened 2026-08-27

Phase A hid `customTonePicker` on iOS on the grounds that "iOS plays notification
sounds only from its bundle or `Library/Sounds`, so a picked file is silently
replaced". The constraint is right; **the conclusion was wrong** —
`Library/Sounds` is inside our own container and we can write to it. Copy the
picked file in, reference it by name, and it plays. Same mistake in kind as
treating the ~30s cap as a wall.

This is **not** AlarmKit-specific: `AlertSound.named()` and
`UNNotificationSound(named:)` resolve the same way, so it would restore custom
tones on the notification path too.

- [ ] Verify the `Library/Sounds` route on device before promising it. Not yet
      proven, only reasoned.
- [ ] `UIDocumentPickerViewController(asCopy: true)` — handles iCloud Drive by
      downloading and handing over a local copy, so the file need not already be
      on device.
- [ ] Convert on device to a valid notification-sound format (Linear PCM, IMA4,
      µLaw or aLaw in `.caf`/`.aif`/`.wav`). mp3/m4a are rejected outright.
- [ ] Trim to ≤30s. Irrelevant under AlarmKit, which loops the file — a ~29s
      tone rang for over 5 minutes on device — but the notification path needs
      the same pre-looping the bundled tones get.
- [ ] Manage the files: replace on change, delete with the alarm.

⚠️ **Copy the file in — never store a reference to it.** A security-scoped
bookmark into iCloud Drive is the tidier-looking design and fails at exactly the
wrong moment: an evicted file needs a network fetch at fire time, so no internet
means no alarm, and a file the user has since moved or deleted is simply gone.
Either way the failure is a silent no-sound alarm at 4am. A converted copy in our
own `Library/Sounds` is app-owned data — not evictable by Optimize Storage, not
movable by the user, and needing nothing but the device itself. Same principle as
the bundled tones: **an alarm must depend on nothing that is not already on the
phone.** (Ben's point, 2026-08-27.)
- [ ] Then flip `customTonePicker` back on for iOS and unhide the UI.

Still genuinely impossible, and the picker must not imply otherwise:
**system ringtones** (Marimba, Radar — no public API on any iOS version) and
**DRM-protected Apple Music tracks**, which cannot be exported. Only files the
user actually owns.

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

## 2.5 Android: the alarm notification is a dead end

Field report 2026-08-30 (Samsung S25 FE): an alarm fired while the user was in
Instagram. No full-screen alarm appeared — just a notification that offered no
way to stop it. He had to open the app manually and tap the notification from
there.

Most of that is **working as Android intends**. `setFullScreenIntent` launches
the activity only when the device is locked or the screen is off; on an unlocked,
in-use phone it is posted as a heads-up notification instead. That is documented
behaviour and not a bug.

The bug is what the heads-up notification offers: **nothing.**
`AlarmReceiver` calls no `addAction`, so the notification has no Snooze and no
Dismiss. The design assumed the full-screen activity would always be there, and
when it is not the user is stranded with a ringing phone.

Ironically iOS is now ahead here — its lack of any wake surface forced us to
build notification actions, and Android never needed them until this.

- [ ] Add Snooze and Dismiss actions to the alarm notification, wired to the
      existing `pending_snoozes` / `pending_dismissals` ledgers exactly as the
      iOS path does.
- [ ] Check `NotificationManager.canUseFullScreenIntent()` (API 34+). The
      permission is app-op gated from Android 14 and is never verified — if it
      is denied the full-screen alarm silently degrades even on the lock screen,
      which is the one case that must not fail. Offer
      `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` when it is missing.
- [x] Volume keys during an alarm — `AlarmActivity` now sets
      `volumeControlStream = STREAM_ALARM`. Partial: only applies while the
      alarm screen is in front, so the notification actions above are the real
      fix. **Uncompiled** — see below.

⚠️ **This Mac cannot build Android.** The only JDKs present (system, and Android
Studio's bundled JBR) are Java 25; Gradle 8.14 refuses it. So no Android change
made here is compile-verified, and no Android release can be cut from this
machine. Fix by installing a JDK 21 and pointing Flutter at it
(`flutter config --jdk-dir=...`), or by moving to Gradle 9.1+.

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

## 4. Which device runs iOS 26 — decided 2026-08-27

The SE 3 is being updated to iOS 26 to start Phase B. That was held off until
the repeat chain (§2.2's predecessor) was finished and verified, because the
notification fallback is what *every* non-26 user runs, and the SE was the only
hardware proving it worked.

**Consequence to keep in view:** once it is on 26 there is no longer a device
that can regression-test the iOS 15.5–18 path. That path is not legacy — it is
the majority path today and the permanent one for devices that cannot take 26.
Changes to `NotificationBackend` after this point are effectively unverified
until there is a second device or a downgrade. Weigh that before touching it.
