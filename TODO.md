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

#### 2.4b App Store purchase readiness — audited 2026-09-11

The Dart purchase layer needs **no iOS-specific code changes**. Verified against
the installed plugin source (`in_app_purchase_storekit 0.4.11`): StoreKit 2 is
the active path (deployment target 15.5 ≥ its iOS 15 floor, no SK1 fallback
needed); `restorePurchases()` reads `Transaction.currentEntitlements` — passive,
never prompts for App Store sign-in — so the automatic restore at launch is
safe; and the plugin surfaces **only cryptographically verified (JWS)
transactions**, so on-device receipt verification comes free on iOS (the
no-verification gap is Android-only). `completePurchase` maps to
`Transaction.finish()`. Ask to Buy arrives as `pending` (correctly not granted);
the later approval is caught because the purchase stream is now subscribed for
the whole app lifetime (2026-09-11 fix).

Console-side, in order, once enrolled — the buy button dead-ends until 1–3 are
done, which is an App Review guideline 2.1 rejection:

- [ ] 1. Sign the **Paid Applications Agreement** (Agreements, Tax, Banking) —
      without it products don't resolve even in sandbox.
- [ ] 2. Create the IAP in App Store Connect: type **Non-Consumable**, product
      id exactly `rostrik_full_access` (same string as Play), price tier,
      localized display name, and the required IAP review screenshot.
- [ ] 3. Attach the IAP to the first app version's submission (a first IAP is
      reviewed with an app version, not alone).
- [ ] 4. App description discloses the 14-day trial + one-time unlock (matches
      the in-app copy; avoids metadata-surprise rejections).
- [ ] 5. App Privacy questionnaire: purchases are processed by Apple and the
      app stores nothing off-device — "Data Not Collected" stays accurate.
- [ ] 6. Sandbox tester account on the SE 3: one end-to-end buy, one restore
      after delete+reinstall. Optional: a `.storekit` configuration file for
      simulator testing before the ASC product exists.

Compliance posture, reviewed: hard paywall after trial is allowed (3.1.1 — the
unlock is IAP, no external purchase links anywhere); Restore is exposed on the
wall AND in Settings; the wall shows the localized StoreKit price; onboarding
discloses the trial up front. Reviewers on a fresh install are inside the trial,
so the whole app is reviewable. Only soft spot: the "trial ends tomorrow" local
notification is promotional-adjacent (guideline 4.5.4) — single-shot and
account-state-ish, so low risk, but it is the first thing to soften if a
reviewer ever objects.

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

**Reproduced 2026-09-15 on the Pixel 9 Pro XL (Android 17).** With the phone
unlocked, `appops` logged the full-screen intent as rejected at fire time and a
heads-up appeared. The user tried to stop it and could not. Findings:

- **The notification can be swiped away, and then nothing stops the ring.**
  Android 14+ lets users dismiss `setOngoing` notifications unless a foreground
  service owns them. `AlarmReceiver` posts its own notification, so a swipe
  removes the only route to `AlarmActivity`. The foreground-service
  notification that remains (`rostrik_alarm_playback`) has no content intent.
  The audio kept ringing until the app was force-stopped; the 15-minute
  auto-timeout was the only other exit.
- Left untouched, the heads-up stays in the shade, and tapping it does open
  `AlarmActivity` — so the one-tap route exists but nobody finds it.
- Fix direction: make the ringing notification the service's foreground
  notification (non-dismissible; `startForeground` with the fire notification's
  id, `setOnlyAlertOnce`), and give it action buttons.
- **Decision needed:** for critical shifts (shake to dismiss), should the
  notification offer Dismiss at all? A one-tap button bypasses the shake. One
  option is Snooze + "Open alarm" for critical shifts, Snooze + Dismiss otherwise.

- [ ] Add Snooze and Dismiss actions to the alarm notification, wired to the
      existing `pending_snoozes` / `pending_dismissals` ledgers exactly as the
      iOS path does.
- [ ] Make the ringing notification non-dismissible (owned by
      `AlarmAudioService`), or give the playback notification a content intent
      to `AlarmActivity`.
- [ ] Check `NotificationManager.canUseFullScreenIntent()` (API 34+). The
      permission is app-op gated from Android 14 and is never verified — if it
      is denied the full-screen alarm silently degrades even on the lock screen,
      which is the one case that must not fail. Offer
      `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` when it is missing.
- [x] Volume keys during an alarm — `AlarmActivity` now sets
      `volumeControlStream = STREAM_ALARM`. Partial: only applies while the
      alarm screen is in front, so the notification actions above are the real
      fix. Compile-verified 2026-08-30.

### Android toolchain — fixed 2026-08-30

This Mac could not build Android at all: the only JDKs present were Java 25
(the system stub, and Android Studio's bundled JBR), which Gradle 8.14 refuses.
Resolved with `brew install openjdk@21` + `flutter config --jdk-dir`. The
Homebrew *formula* is deliberate over the cask — it installs under
`/opt/homebrew` and needs no `sudo`, where the cask writes to `/Library` and
prompts for a password.

Do NOT record the path in `android/gradle.properties` as `org.gradle.java.home`:
that file is committed and the path is machine-specific, so it would break every
other machine and CI. `flutter config` keeps it machine-local.

Note `./gradlew` directly does not inherit Flutter's setting — it needs
`JAVA_HOME` exported. Only `flutter build` picks up `--jdk-dir`.

- [ ] **Kotlin 2.2.20 support is being dropped** — Flutter now warns it wants
      ≥2.3.20 (`android/settings.gradle.kts`). Not urgent, but it will become a
      hard failure. Worth doing while there is a device to verify alarms on,
      since a KGP bump touches every native alarm path.

---

## 2.6 Internationalisation — shipped 2026-09-15

15 languages: en, es, pt (Brazilian), de, fr, it, nl, pl, tr, id, vi, ja, ko,
hi, ar. Locale follows the device; Android 13+ and iOS also offer a per-app
language picker in system settings.

Where strings live (all three must stay in step):
- Flutter UI + notification copy: `lib/l10n/app_<lang>.arb` (template
  `app_en.arb`), generated into `lib/l10n/gen` by `flutter gen-l10n`.
- Native Android (alarm screen, notification channels, widget):
  `android/app/src/main/res/values-<lang>/strings.xml` (Indonesian is
  `values-in`).
- Native iOS (permission prompts, AlarmKit Stop/Snooze):
  `ios/Runner/<lang>.lproj/{InfoPlist,Localizable}.strings`.

Guards: `test/l10n/catalogue_completeness_test.dart` fails if any language is
missing a key or mangles a placeholder; `test/l10n/locale_layout_smoke_test.dart`
renders 11 key screens in every language at 360dp and fails on overflow.

Follow-ups:
- [ ] Native-speaker review. Translations are machine-authored with care for
      tone and terminology but unreviewed — prioritise the markets with real
      installs (Play Console → Statistics → by country). Cheapest high-value
      check: the legal consent screen and the purchase wall.
- [ ] Privacy Policy and Terms of Use pages are English-only; the consent
      screen is translated but links to English documents.
- [ ] Store listings per language (Play custom store listings, App Store
      localizations) — separate from the app; screenshots too.
- [ ] Arabic on device: Flutter mirrors the UI automatically, but the native
      Android alarm screen stays left-to-right (`supportsRtl` is off on
      purpose until the slide-to-dismiss track is tested mirrored).
- [ ] Already-armed alarms keep the old language's notification text after a
      device-language change until the next reconcile (next app open, or boot).
- [ ] Adding a string: add it to `app_en.arb` AND all 14 other ARBs, or the
      completeness test fails. Same idea for native strings.
- [ ] Notification channel names never update for existing installs: every
      `ensureChannel` (AlarmReceiver, AlarmAudioService, SleepSoundService,
      ReminderReceiver) returns early when the channel exists, so the Pixel
      still shows "Alarm playback" / "Reminders" in English. Update
      name/description on the existing channel instead of returning.
- [ ] Ringtone row reads "Default (Fresh Start)" in English on every language
      (create-alarm sheet).
- [ ] Dashboard settings gear stays top-right in Arabic; other screens mirror it.

Verified on the Pixel 9 Pro XL 2026-09-15 (de, ar, hi, ja; es for alarm text):
all tabs, Settings, the Schedule month and list views, the native alarm screen
(de), and alarm text re-arming on a language switch. Fixed there: live language
switch leaving the calendar in the old language, Arabic dates in Arabic-Indic
digits beside Western-digit times, and letter spacing splitting Hindi words.

Not i18n, seen during that pass: in the Schedule list view the pinned month
headers stack (JULI / AUGUST / SEPTEMBER 2026) and cover the first card.

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
