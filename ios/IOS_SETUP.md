# Rostrik — iOS day-one runbook

Everything in this file was prepared on Windows, with **no Xcode and no Swift
compiler available**. The Dart changes are analyzer-verified and the Android
build is green; the Swift is not compiled. Plan the first Mac day around
*fixing build errors*, not around it working first try.

Read `## 1` and `## 2` before touching Xcode — step 2.1 in particular is the
kind of thing that fails silently rather than loudly.

---

## 0. What is already done

| Item | State |
|---|---|
| Bundle id | `com.example.rostrikMvp` → **`com.rostrik.app`** (matches Android `applicationId`) |
| Tests bundle id | `com.rostrik.app.RunnerTests` |
| Display name / bundle name | "Rostrik Mvp" / "rostrik_mvp" → **"Rostrik"** |
| BGTask identifier | `com.rostrik.app.alarmSyncRefresh` (Info.plist **and** AppDelegate agree) |
| Deployment target | 15.5, pinned in both `Podfile` and `project.pbxproj` (ML Kit floor) |
| Background refresh | `BGTaskScheduler` wired end-to-end in `AppDelegate.swift` |
| Alarm channel | `ios/Runner/NativeAlarmPlugin.swift` — **new**, registered on both engines |
| AlarmKit usage string | `NSAlarmKitUsageDescription` added to Info.plist |
| iOS tone installer | `lib/alarms/ios_alarm_sound_installer.dart` — **new**, called from `main()` |
| App icons | 22 files present in `AppIcon.appiconset` |
| Orientation | Portrait-locked in Info.plist |
| Camera / photos / calendar strings | Present |

---

## 1. Prerequisites

```bash
xcode-select --install
sudo gem install cocoapods          # or: brew install cocoapods
flutter doctor                      # must show no iOS-toolchain issues
```

An Apple Developer Program membership ($99/yr) is required to ship. You can
build to your own device without one, but not to TestFlight.

---

## 2. First build

```bash
cd rostrik_mvp
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace        # .xcworkspace, NEVER .xcodeproj
```

### 2.1 ⚠️ Add `NativeAlarmPlugin.swift` to the Runner target — FIRST

`ios/Runner/NativeAlarmPlugin.swift` exists on disk but is **not** referenced by
`project.pbxproj`. Xcode compiles the target's file list, not the folder, so
until you add it the file is simply ignored.

This one fails quietly and expensively. There is no compile error — the app
builds, launches, looks fine, and then every alarm schedule throws
`MissingPluginException` at runtime because nothing answers
`rostrik/native_alarms`. If alarms "just don't work" on day one, check this
first.

> Xcode → right-click the `Runner` group → **Add Files to "Runner"…** → select
> `NativeAlarmPlugin.swift` → ensure **Runner** is ticked under *Add to targets*.

### 2.2 Signing

Xcode → Runner target → **Signing & Capabilities**:

- Team: your Apple Developer team (`DEVELOPMENT_TEAM` is currently unset)
- Signing: Automatic
- Verify the bundle identifier reads `com.rostrik.app`

Add these capabilities:

- **Background Modes** → Background fetch + Background processing
  (`UIBackgroundModes` is already in Info.plist; the capability makes Xcode
  agree)
- **Push Notifications** — not needed, Rostrik is fully local
- **In-App Purchase**

### 2.3 Build

```bash
flutter build ios --debug --no-codesign     # fastest way to surface Swift errors
```

Expect errors in `NativeAlarmPlugin.swift`. The `NotificationBackend` half uses
long-stable API and should be close; the `AlarmKitBackend` half is a stub by
design (see §3.1).

---

## 3. Known gaps, in priority order

### 3.1 AlarmKit is not implemented — alarms fall back to notifications

`NativeAlarmPlugin.swift` ships two backends behind an `AlarmBackend` protocol.
`AlarmKitBackend` is a **stub whose `schedule` always fails**, and it is gated
off by `alarmKitEnabled = false`, so the app currently uses
`NotificationBackend` on every iOS version.

That gate is deliberate. Selecting AlarmKit on `#available(iOS 26.0, *)` alone
would give the newest iPhones a backend that cannot schedule — the newest
devices would get *no* alarms while older ones worked. Failing loudly also
matters: the error keeps the id out of the Dart ledger, so the reconciler
re-arms instead of trusting a phantom. A silent success would be the worst
outcome — an alarm the app believes is set that never rings.

**What the fallback actually gives you.** A time-sensitive notification with a
bundled sound. Honestly: this is a weaker alarm than Rostrik promises.

- sound stops after ~30 seconds
- the ring/silent switch and Focus modes silence it
- no full-screen wake surface, no shake-to-dismiss
- iOS caps pending notifications at 64 (the 14-day / 50-alarm horizon fits, but
  activity reminders share that budget)

**To finish AlarmKit:** implement the three `TODO(mac)` bodies against the real
SDK, verify on a device, then flip `alarmKitEnabled` to `true`. AlarmKit also
needs a widget extension for its alert presentation — do §3.3 first. Do not
ship the flag on until an alarm has actually rung on hardware.

### 3.2 The alarm tones are not bundled for iOS

`assets/sounds/` contains **only `README.md`**. The four WAVs live at
`android/app/src/main/res/raw/`, which iOS cannot read. `installIosAlarmSounds()`
is wired into `main()` and will copy them into `Library/Sounds/` the moment they
exist — until then it skips silently and alarms ring with the iOS default chime.

The fix is a copy, but it costs the **Android** bundle ~3.9 MB, because Flutter
assets are not per-platform. Your call, so it is left undone:

```bash
cp android/app/src/main/res/raw/classic_alarm.wav assets/sounds/classic.wav
cp android/app/src/main/res/raw/siren.wav         assets/sounds/siren.wav
cp android/app/src/main/res/raw/digital.wav       assets/sounds/digital.wav
cp android/app/src/main/res/raw/chime.wav         assets/sounds/chime.wav
```

Worth considering first: these are 16-bit PCM WAVs and several are >1 MB for a
~10 s loop. Trimming or downsampling them before copying would cut most of that
cost on both platforms.

### 3.3 No home-screen widget on iOS

The Android widget (forecast-driven, self-refreshing) has no iOS counterpart.
`home_widget` supports iOS but needs work only doable in Xcode:

1. **File → New → Target → Widget Extension**, named e.g. `RostrikWidget`
2. Add an **App Group** (e.g. `group.com.rostrik.app`) to *both* the Runner
   target and the widget target — this is how the two processes share data
3. Call `HomeWidget.setAppGroupId('group.com.rostrik.app')` in `WidgetService`
   before the first write (Android needs no equivalent, so this must be
   `Platform.isIOS`-guarded)
4. Write the SwiftUI view to read the `hero_forecast` JSON and render it

Good news for step 4: the hard part is already solved cross-platform. The
forecast written by `lib/services/widget_forecast.dart` is plain JSON with
absolute timestamps, so the SwiftUI view does the same job as
`RostrikWidgetProvider.kt` — pick the segment covering `now`, subtract, format.
WidgetKit's `TimelineProvider` is actually a *better* fit than Android's:
`hero_forecast`'s segment boundaries map almost one-to-one onto
`TimelineEntry` dates, so iOS can schedule the whole timeline in one pass
instead of self-ticking.

### 3.4 Android-only features that degrade on iOS

These are already `Platform.isAndroid`-guarded, so they fail soft rather than
crash — but they will be visibly missing:

| Feature | File | iOS state |
|---|---|---|
| Sleep sound player | `lib/sleep/sleep_sound_channel.dart` | Returns unsupported; **the Sleep tab loses its player** |
| Custom ringtone picker / preview | `lib/alarms/ringtone_channel.dart` | Returns null; vault + system tones unavailable |
| Exact-alarm / overlay permission rows | `lib/ui/onboarding/permissions_screen.dart` | Hidden on iOS (correct) |
| Full-screen wake activity | native Kotlin | No equivalent; see §3.1 |

The Sleep player is the one a user would actually notice. An `AVAudioPlayer`
loop in a background-audio-capable target is the iOS equivalent — a contained
piece of work, but not started.

### 3.5 Custom ringtones cannot work on iOS

Even with §3.2 done, only the four **bundled** tones will play. iOS cannot use
an arbitrary user-picked file as a notification sound unless it is copied into
`Library/Sounds` first, and the vault/system URI model does not map. The Dart
side already sends `iosSound` populated from the bundled catalogue for *every*
alarm, so a custom-tone alarm degrades to its bundled fallback rather than
going silent. Fine for v1; hide the picker on iOS to avoid promising it.

---

## 4. App Store Connect

1. Create the app record with bundle id **`com.rostrik.app`**
2. **In-App Purchase** → Non-Consumable → product id **`rostrik_full_access`**
   — must match `kFullAccessProductId` in `lib/purchase/entitlement.dart`
   exactly, or the paywall shows nothing
3. Fill in the privacy nutrition labels. Rostrik is local-first: no data
   collected, no tracking, no third-party analytics. The camera (OCR) and
   calendar (sync) permissions are both on-device and opt-in
4. Reuse the store copy in `store_listing/` — already written in 13 languages
5. Attach the Privacy Policy and Terms URLs already used on Android

**Review note worth pre-empting:** an alarm app that keeps working when the app
is closed invites questions about background execution. Rostrik uses
`BGTaskScheduler` only to roll a 14-day scheduling horizon forward — no
network, no location, no silent push. Saying so in the review notes is cheaper
than a rejection round-trip.

---

## 5. Test checklist (device, not simulator)

Alarms cannot be meaningfully tested in the simulator.

- [ ] Cold launch → legal gate → onboarding
- [ ] Notification permission prompt appears (`Permission.notification` in `main()`)
- [ ] Build a roster → alarms schedule without `MissingPluginException` (§2.1)
- [ ] An alarm fires with the app **backgrounded**
- [ ] An alarm fires with the app **force-quit** — the real test
- [ ] Correct tone plays (default chime until §3.2 is done)
- [ ] Background refresh rolls the horizon: schedule, wait, confirm alarms
      beyond day 14 appear. Force it in Xcode with
      `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.rostrik.app.alarmSyncRefresh"]`
- [ ] IAP sandbox purchase unlocks full access
- [ ] Trial expiry disarms alarms (entitlement lock path)
- [ ] OCR scanner: camera → crop → parse
- [ ] Calendar sync creates the "Rostrik Roster" calendar
- [ ] Light and dark theme
- [ ] Portrait lock holds on iPad

---

## 6. Storage note

This whole preparation is source text — a few hundred KB. The Mac is where the
weight lands: Xcode ~40 GB, iOS SDKs and simulators another ~10–20 GB, plus
CocoaPods and DerivedData. Nothing here constrains the Windows box, which is
currently at ~16 GB free with a 3.9 GB `build/` directory that
`flutter clean` reclaims whenever you need the room.
