# Rostrik — iOS runbook

This file was originally written on Windows with no Xcode, as a day-one plan.
**That day has happened.** Rostrik now builds, installs, and runs on a physical
device (iPhone SE 3, iOS 18.6), with alarms, reminders, and sleep sounds all
firing. What follows is the current state, the device workflow, and the gaps
that are still open.

Read `## 1` before touching anything — two of the entries there are silent
failure modes that cost hours to rediscover.

---

## 0. State

| Item | State |
|---|---|
| Bundle id | `com.rostrik.app` (matches Android `applicationId`) |
| Display name | "Rostrik" |
| Signing | Personal team `LM6TRKQX8F`, free Apple ID, automatic |
| Deployment target | 15.5, pinned in `Podfile` + `project.pbxproj` (ML Kit floor) |
| Dependency manager | CocoaPods. Swift Package Manager **disabled** in `pubspec.yaml` |
| Alarm delivery | ✅ works — `UNUserNotificationCenter`, bundled tones |
| Foreground alarms | ✅ works — `ForegroundAlarmPresenter` |
| Snooze | ✅ implemented — notification action + `pending_snoozes` ledger |
| One-time alarm cleanup | ✅ works — notification response + Dart nudge (§4.4) |
| Reminders / sleep nudges | ✅ works — `ActivityReminderPlugin.swift` |
| Sleep sounds | ✅ works — `SleepSoundPlugin.swift` (`AVAudioPlayer`) |
| Custom-tone preview | implemented (`RingtonePreviewPlugin.swift`), **not yet verified on device** |
| Background refresh | `BGTaskScheduler` wired end-to-end |
| Alarm tones | ✅ `ios/Runner/Sounds/*.caf`, pre-looped to ~28s (§4.1) |
| AlarmKit | stub, gated off (§4.2) |
| Home-screen widget | not started (§4.3) |
| In-App Purchase | **blocked** — capability needs the paid Developer Program |

Verified on device: alarms firing with the correct preset tone (~28s),
**delivery with the app force-quit**, foreground delivery, wind-down/bedtime
nudges, sleep-sound playback, and one-time alarms retiring after firing both
backgrounded and force-quit. Snooze was reported working; its **force-quit**
path (ledger written while the app is dead, drained on next launch) deserves one
more explicit test.

---

## 1. Things that fail silently

### 1.1 ⚠️ Never call `permission_handler` before `runApp()` on iOS

`permission_handler_apple` answers a status check by blocking its thread on a
semaphore until `UNUserNotificationCenter` calls back — and that callback does
not arrive until the app has finished launching. Asking during `main()`
therefore blocks the very launch the callback is waiting on. **The app sits on
the native splash screen forever**, with no crash, no log, and no error.

Because the splash is the same pitch black as the app theme, this is
indistinguishable from a hang anywhere else, and it makes every other iOS
feature look broken at once.

`requestIosNotificationPermission()` in `lib/main.dart` is the safe form: it
posts the request with `addPostFrameCallback` **after** `runApp`, so the app is
provably live first. `PermissionsScreen` also asks on an explicit tap.

### 1.2 ⚠️ `permission_handler` compiles every permission out by default

Each strategy in `permission_handler_apple` is wrapped in
`#if PERMISSION_X … #else <empty @implementation> #endif`. Without the macro the
class exists and the channel answers — it just does nothing, so
`Permission.notification.request()` never reaches `UNUserNotificationCenter` and
no dialog can ever appear.

`ios/Podfile`'s `post_install` sets `PERMISSION_NOTIFICATIONS=1`. Verify it
actually landed:

```bash
grep PERMISSION_NOTIFICATIONS ios/Pods/Pods.xcodeproj/project.pbxproj  # one hit per config
```

### 1.3 ⚠️ Hand-written plugins must be retained

Rostrik's iOS plugins are not pub plugins, so nothing registers or retains them
automatically. The original pattern captured the instance **weakly** while every
caller discarded the returned value — ARC freed it the moment `register`
returned, and from then on every call fell through to
`FlutterMethodNotImplemented`. The channel answered and did nothing, while Dart
believed its alarms were armed. **This is why alarms never fired at all.**

Every plugin in `ios/Runner/` now holds itself **strongly** in its method-call
closure. Doubly required for the audio plugins: `AVAudioPlayer` stops the
instant its owner is deallocated.

Related: never make a per-engine plugin the `UNUserNotificationCenter` delegate.
That property is **weak**, and the BGTask engine is destroyed after every
refresh, so the delegate would silently become nil. `ForegroundAlarmPresenter`
is a statically-owned singleton for exactly this reason.

### 1.4 ⚠️ Foreground notifications are opt-in

iOS shows **nothing** for a frontmost app unless a delegate implements
`willPresent`. `ForegroundAlarmPresenter` must cover **both** identifier
prefixes (`rostrik.alarm.` and `rostrik.reminder.`) — scoping it to one silently
suppresses the other on screen while it still works on the lock screen, which
reads exactly like an iOS restriction and isn't one.

---

## 2. Device workflow

```bash
flutter build ios --profile
codesign --verify --deep --strict build/ios/iphoneos/Runner.app   # catch a bad signature early
flutter install -d <device-id>
xcrun devicectl device process launch --device <device-id> --terminate-existing --console com.rostrik.app
```

- **Never `flutter run` for this device.** It needs macOS Automation permission
  to drive Xcode; if that prompt goes unanswered it hangs, and killing it leaves
  a **corrupted code signature** that fails install with `0xe8008001
  ApplicationVerificationFailed`. Recovery: `rm -rf build/ios`, rebuild.
- **Never build `--debug` for the device.** A debug Flutter app cannot start
  without live tooling — tapping the icon fails with *"Cannot create a
  FlutterEngine instance in debug mode"*. Use `--profile` or `--release`.
- `flutter install` uninstalls the old copy, which **revokes developer trust
  every time**. The user must redo Settings → General → VPN & Device Management
  → Trust before the next launch. **Batch changes** to spare them the loop.
- **Dart `print`/`debugPrint` does not reach the device console** in
  profile/release — only native `NSLog` does. To trace Dart, relay through a
  MethodChannel to `NSLog`. macOS `log stream` no longer supports remote
  devices.

---

## 3. What iOS genuinely cannot do

Explain these rather than attempting them:

- **No full-screen wake surface.** Android's `AlarmActivity` draws over the
  keyguard; iOS has no third-party equivalent. The notification is the entire
  control affordance, which is why Snooze is a notification action.
- **No shake-to-dismiss** — it depends on that surface.
- **No system-ringtone picker.** No public API;
  `RingtoneChannel.pickSystemRingtone` no-ops on iOS by design.
- **No arbitrary file as a notification sound.** Only `Library/Sounds`, so a
  custom tone degrades to its bundled fallback. Buying a song proves nothing.
- **~30s sound cap**, and the ring/silent switch silences it. `.critical` would
  pierce both but needs an Apple-approved entitlement.
- iOS caps pending notifications at **64**, shared between alarms and reminders.
  The 14-day / 50-alarm horizon fits, but it is worth watching.

---

## 4. Open gaps

### 4.1 Alarm tones: why iOS holds different files

**Done — recorded here because the divergence is deliberate and looks wrong at
a glance.**

iOS cannot loop a notification sound. Android plays alarm audio through a
`MediaPlayer` with `isLooping = true`, so it rings until dismissed;
`UNNotificationSound` plays its file exactly ONCE and offers no looping API. A
4.7 s `classic` tone therefore meant a 4.7 s alarm.

So the iOS copies bake the repeats into the file, filling Apple's hard **<30 s**
ceiling (longer and iOS silently substitutes the default chime):

| tone | master | iOS |
|---|---|---|
| classic | 4.7 s | 28.1 s (×6) |
| siren | 9.0 s | 27.0 s (×3) |
| digital | 7.2 s | 28.8 s (×4) |
| chime | 16.1 s | 16.1 s — ×2 would breach the cap |

They live in `ios/Runner/Sounds/*.caf` as Runner target resources, in IMA4 (an
Apple-documented notification-sound format, ~4:1 smaller, so 6× the length costs
almost nothing). Regenerate from the Android masters with
`ios/tools/generate_alarm_tones.sh`.

They are **not** Flutter assets, deliberately: assets are not per-platform, so
`assets/sounds/*.wav` put ~3.9 MB of never-read duplicates in the ANDROID
bundle, which plays its own `res/raw` copies. Those are now deleted. Being in
the main bundle is also what lets `UNNotificationSound(named:)` find them with
no runtime copy — which is why `ios_alarm_sound_installer.dart` no longer
exists.

A unit test guards both silent failure modes (a missing tone, and one that has
grown past the cap); both otherwise present identically on device as "it rang
with the wrong sound".

Still worth doing: the masters are 16-bit PCM, several >1 MB for a ~10 s loop.
Trimming or downsampling would cut cost on both platforms.

### 4.2 AlarmKit is still a stub

`AlarmKitBackend` in `NativeAlarmPlugin.swift` is unimplemented and gated off by
`alarmKitEnabled = false`, so every iOS version uses `NotificationBackend`.

That gate is deliberate: selecting AlarmKit on `#available(iOS 26.0, *)` alone
would hand the newest iPhones a backend that cannot schedule, so the newest
devices would get *no* alarms while older ones worked. Its `schedule` fails
loudly on purpose — the error keeps the id out of the Dart ledger, so the
reconciler re-arms instead of trusting a phantom. A silent success would be the
worst outcome: an alarm the app believes is set that never rings.

AlarmKit is the only route to a real alarm UI, a sound past 30s, and piercing
the silent switch. It needs a widget extension for its alert presentation, so do
§4.3 first. Do not flip the flag until an alarm has actually rung on hardware.
The test device is on iOS 18.6, so this cannot be validated there at all.

### 4.3 No home-screen widget on iOS

The Android widget has no iOS counterpart. `home_widget` supports iOS but needs
Xcode work:

1. **File → New → Target → Widget Extension**
2. Add an **App Group** to *both* the Runner and widget targets (note
   `Runner.entitlements` currently declares none — an empty
   `application-groups` array grants nothing)
3. `HomeWidget.setAppGroupId(...)` in `WidgetService`, `Platform.isIOS`-guarded
4. SwiftUI view reading the `hero_forecast` JSON

The hard part is already cross-platform: `widget_forecast.dart` writes plain
JSON with absolute timestamps. WidgetKit's `TimelineProvider` is a *better* fit
than Android's — the forecast's segment boundaries map almost one-to-one onto
`TimelineEntry` dates, so iOS can schedule the whole timeline in one pass
instead of self-ticking.

### 4.4 Retiring a fired alarm on iOS

**Mostly solved — the remaining hole is narrow but real.**

Android writes `pending_alarm_deletes` from native code at fire time. iOS runs
NO app code when a notification fires, so that ledger was always empty and
`drainPendingAlarmDeletesIntoHive` never retired anything. The consequence was
severe and silent: a spent one-time alarm was re-projected to "the next future
occurrence of its time-of-day", so **a one-time alarm quietly became a daily
one** and kept waking the user every morning. Confirmed on device before the
fix.

Three signals now feed the same ledger, so the existing Dart drain is unchanged:

1. **The notification response** (`didReceive`) — a tap or an explicit dismiss.
   The dependable one: iOS launches the app just to deliver it, so it works
   from a force-quit state. The category needs `.customDismissAction` or iOS
   silently drops swipe-away responses.
2. **A nudge back into Dart** (`onSpentAlarmRecorded`). Without it, retirement
   is merely eventual: tapping a notification foregrounds the app, so the
   resume-time drain has usually already run by the time the response arrives,
   leaving the ledger unread until some later resume.
3. **A sweep of still-delivered notifications** on launch/resume, as a backstop
   for alarms the user ignores. On its own this is NOT sufficient — it only
   sees notifications still in Notification Center, i.e. it misses the most
   common case of all, the user dismissing one. (A first attempt built solely
   on this failed on device for exactly that reason.)

**The hole:** clearing the notification via "Clear All" without ever opening the
app reports nothing, so the rule survives. Fully closing it needs a time-based
sweep — retire a one-time alarm once its intended instant has passed, with no OS
cooperation. `AppAlarm` has no `createdAt`/target date (its fire time is a
time-of-day, which is precisely why it rolls), so that means a model field and a
Hive migration. See TODO.md §1.1.

Separately, `pending_dismissals` still has no iOS writer, so a fired alarm is
never marked *acknowledged* in Hive. That matters less than on Android — a
notification fires once, with no re-ring loop to suppress — but it is why there
is no explicit "Dismiss" button beyond the system one.

### 4.5 In-App Purchase needs the paid programme

The capability cannot be added under a free Personal Team — Xcode refuses to
register the App ID. Nothing else is blocked by it; the purchase/entitlement
flow simply cannot be tested until enrolment.

### 4.6 Google ML Kit blocks Apple-Silicon simulators

ML Kit's pods ship no `arm64` simulator slice, and Xcode 26's simulator dropped
Rosetta by default, so the app **cannot install on an Apple-Silicon iOS 26
simulator** (`Failed to find matching arch`). Physical devices are unaffected —
they use the proper `arm64` device slice. Test on hardware; alarms could never
be meaningfully tested in a simulator anyway.

---

## 5. Test checklist (device only)

- [x] Cold launch clears the splash and reaches onboarding
- [x] Notification permission prompt appears
- [x] Build a roster → alarms schedule (`NSLog` shows `scheduled id=…`)
- [x] An alarm fires with the correct preset tone, for ~28s
- [x] An alarm fires while the app is **foregrounded**
- [x] **An alarm fires with the app force-quit**
- [x] A fired one-time alarm is retired, backgrounded **and** force-quit
- [x] Wind-down / bedtime nudges fire
- [x] Sleep sounds play and loop
- [ ] Sleep sound keeps playing with the **screen locked** (needs the `audio`
      background mode — declared, unverified)
- [ ] Snooze from a **force-quit** app, then relaunch: the ledger drain should
      set `snoozedUntil` and the alarm should still ring
- [ ] Custom-tone preview (`AVAudioPlayer`) — needs an audio file on the device
- [ ] Background refresh rolls the horizon. Force it in Xcode with
      `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.rostrik.app.alarmSyncRefresh"]`
- [ ] OCR scanner: camera → crop → parse
- [ ] Calendar sync creates the "Rostrik Roster" calendar
- [ ] Light and dark theme
- [ ] IAP sandbox purchase (blocked, §4.5)

---

## 6. App Store Connect

1. Create the app record with bundle id **`com.rostrik.app`**
2. **In-App Purchase** → Non-Consumable → product id **`rostrik_full_access`**
   — must match `kFullAccessProductId` in `lib/purchase/entitlement.dart`
   exactly, or the paywall shows nothing
3. Privacy nutrition labels: Rostrik is local-first — no data collected, no
   tracking, no third-party analytics. Camera (OCR) and calendar (sync) are both
   on-device and opt-in
4. Reuse the store copy in `store_listing/` — already written in 13 languages
5. Attach the Privacy Policy and Terms URLs already used on Android

**Review note worth pre-empting:** an alarm app that keeps working when closed
invites questions about background execution. Rostrik uses `BGTaskScheduler`
only to roll a 14-day scheduling horizon forward — no network, no location, no
silent push. Saying so up front is cheaper than a rejection round-trip.
