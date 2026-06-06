# Rostrik - Master Architecture Document

## Core Objective
A highly reliable, offline-first lifestyle OS and alarm ecosystem specifically designed for shift workers.

## Tech Stack & Constraints
- **Framework:** Native Flutter.
- **State Management:** (Wait for Claude's MVP recommendation, but keep it simple, e.g., Provider).
- **Data Storage:** STRICTLY LOCAL. No cloud databases (Firebase, Supabase, etc.), no external login systems. All user rosters and alarm data must live on the device.

## Architectural Rules (Non-Negotiable)
1. **Separation of Concerns:** Business logic (saving data, calculating shift rotations, triggering alarms) must be 100% separated from UI code.
2. **No UI Bloat:** Build the underlying logic and data models first. UI is only implemented after the logic is proven to work.
3. **Hardware Constraints:** Background alarm triggering must work reliably without relying on complex, battery-draining hardware sensors (e.g., no accelerometer/shake-to-wake logic for V1).

## V1 MVP Scope
- **Storage:** Reliable local database setup.
- **Roster:** A calendar/timeline view to add, edit, and delete basic shift blocks (Day, Night, Afternoon, Off).
- **Alarms:** Core engine that reads the local calendar and fires an alarm at a user-defined time before a scheduled shift. Basic device ringtones only.

## Phase 5 — Alarm Engine Architecture

### Two distinct horizons (do not conflate)
The "365" and "14" figures describe two unrelated windows. Confusing them is a recurring trap:

| Horizon | Value | Owner | Purpose |
| --- | --- | --- | --- |
| **OS alarm scheduling** | **14 days, max 50 alarms** | `AlarmSyncService` ([lib/alarms/alarm_sync_service.dart:69-70](lib/alarms/alarm_sync_service.dart#L69-L70)) | The rolling slice of alarms actually registered with the OS. Kept small so the iOS 64-pending-notification ceiling is unreachable; longer-term coverage is the background re-sync's job. |
| **Roster materialisation** | **365 days** | `ShiftGenerator` / pattern picker | Shifts are pre-computed far in advance for the calendar/roster UI. Only the next 14 days of that roster are ever scheduled as OS alarms. |

### Engine model
`AlarmSyncService` is **alarm-rule-centric** (not shift-centric): it reconciles the desired set of OS
alarms from `AppAlarm` rules + `Shift` state.
- Per-shift suppression: a shift that is `isMuted`, `isAcknowledged`, or within an active
  `snoozedUntil` window is skipped / cancelled ([alarm_sync_service.dart:214-264](lib/alarms/alarm_sync_service.dart#L214-L264)).
- Idempotent reconcile: cancel-orphans + replace-by-id; running twice with no input change issues
  zero scheduler mutations. A persisted `_scheduledFireAt` map suppresses redundant `scheduleAt`
  bursts on cold start.
- While the app is alive it watches the `AppAlarm`, `ShiftCycle`, and in-horizon `Shift` streams
  (debounced) and re-syncs reactively.

### Delivery
`flutter_local_notifications` with `AndroidScheduleMode.alarmClock` (`AlarmManager.setAlarmClock` —
Doze-bypassing without `USE_EXACT_ALARM`), `FLAG_INSISTENT` looping audio, and a FullScreenIntent
that wakes the lock screen. This is the only file allowed to import the plugin
([lib/alarms/local_notifications_alarm_scheduler.dart](lib/alarms/local_notifications_alarm_scheduler.dart)).

### Native background re-sync
Keeps the 14-day window hydrated while the app is closed. **No long-lived Dart isolate / no
`workmanager` Flutter plugin** — each trigger spins up a one-shot headless `FlutterEngine`, runs a
single `syncAlarms()`, and tears down.
- **iOS:** `BGTaskScheduler` ([ios/Runner/AppDelegate.swift](ios/Runner/AppDelegate.swift), declared
  in [ios/Runner/Info.plist](ios/Runner/Info.plist)) — re-arms each background transition; rolls the
  window forward (iOS local notifications already survive reboot, so there is no iOS boot receiver).
- **Android:** `BootReceiver` → `AlarmSyncWorker` (native `androidx.work`,
  [android/app/build.gradle.kts](android/app/build.gradle.kts)) — `AlarmManager` is wiped on reboot,
  so the worker re-derives the alarm set from Hive on `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED`.
- **Dart bridge:** [lib/alarms/background_sync_entrypoint.dart](lib/alarms/background_sync_entrypoint.dart)
  exposes `@pragma('vm:entry-point') syncAlarmsBackgroundEntrypoint`, invoked over the
  `rostrik/alarm_sync_background` MethodChannel with a `handlerReady → run` handshake.
- **Three identifiers must stay in lock-step** across iOS, Android, and Dart: channel name
  `rostrik/alarm_sync_background`, entrypoint `syncAlarmsBackgroundEntrypoint`, and the iOS task id
  `com.example.rostrikMvp.alarmSyncRefresh`.

### Cross-isolate notification actions
Snooze/Dismiss taps that arrive while the app is killed are handled in a background isolate
([lib/alarms/notification_response_handler.dart](lib/alarms/notification_response_handler.dart)). To
avoid Hive cache staleness it forwards the action to the live main isolate via `IsolateNameServer`
port-forwarding when one exists, and only does the Hive write itself when the main isolate is dead.
*Caveat:* the background **sync** entrypoint above does not share that guard — see the audit note on
iOS background refresh running alongside a suspended UI isolate.