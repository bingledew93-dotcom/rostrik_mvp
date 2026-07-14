package com.example.rostrik_mvp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Rostrik's own boot recovery receiver. INTENTIONALLY independent of
 * `flutter_local_notifications`' `ScheduledNotificationBootReceiver`.
 *
 * Why a second receiver: FLN's boot receiver restores from its own
 * internal SharedPreferences store of scheduled notifications. If that
 * store diverges from our Hive `shifts` / `alarms` boxes — manual app
 * data clear, OEM-aggressive "deep sleep" cleanup, partial-write race
 * during a previous crash, or a future plugin upgrade that changes the
 * persistence format — alarms vanish until the user opens the app.
 *
 * This receiver is the safety net. On every boot (and every package
 * replace), it enqueues a one-shot [AlarmSyncWorker] that re-derives
 * the desired OS-alarm set from the Hive source of truth via the same
 * `AlarmSyncService.syncAlarms()` the foreground app uses. Whatever FLN
 * restored is then reconciled — duplicates are caught by the in-flight
 * `_scheduledFireAt` check, missing entries are scheduled fresh.
 *
 * onReceive runs on the main thread with a ~10s ANR budget. We do NOT
 * open Hive or run Dart code here — that's the Worker's job. This
 * receiver is purely an enqueue point.
 *
 * Listened actions:
 *   - ACTION_BOOT_COMPLETED: standard device-on signal. Fires after
 *     keyguard unlock on most OEMs, so user-unlock IS the trigger
 *     point on devices with locked-boot encryption (FBE).
 *   - ACTION_LOCKED_BOOT_COMPLETED: fires earlier on FBE devices,
 *     before user-unlock. We register for both so the receiver runs
 *     as early as possible — important for alarms that need to fire
 *     before the user has unlocked their phone for the first time
 *     after reboot.
 *   - ACTION_MY_PACKAGE_REPLACED: fires on app upgrade. Same
 *     reconciliation logic — the new APK may have changed how alarms
 *     are computed, so re-deriving from Hive is correct.
 *   - QUICKBOOT_POWERON: HTC/legacy quick-boot signal. Cheap to
 *     handle, costs nothing on devices that don't emit it.
 *   - ACTION_TIMEZONE_CHANGED / ACTION_TIME_CHANGED (audit F2): every
 *     armed alarm is an EPOCH instant computed from LOCAL wall time at
 *     schedule time. When the user crosses timezones (fly-in/fly-out
 *     shift workers) or manually adjusts the clock, those instants no
 *     longer land on the intended local wall time — a 06:00 wake-up can
 *     drift hours. The re-sync recomputes every fireAt from local
 *     calendar math and re-arms. Both actions are on Android's
 *     implicit-broadcast exceptions list ("clock applications may need
 *     to receive these broadcasts to update alarms when the time
 *     changes"), so a manifest-registered receiver still gets them on
 *     API 26+.
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "RostrikBoot"

        // QUICKBOOT_POWERON is not a constant on Intent (it's an OEM
        // string), so we duplicate the string used in
        // AndroidManifest.xml here. Keep them in sync.
        private const val ACTION_QUICKBOOT_POWERON = "android.intent.action.QUICKBOOT_POWERON"
        private const val ACTION_HTC_QUICKBOOT_POWERON = "com.htc.intent.action.QUICKBOOT_POWERON"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "onReceive action=$action")

        // Defensive: this receiver is exported in the manifest only
        // for the actions we declared in the intent-filter, but a
        // malicious app on a rooted device could try to fake one of
        // them. We re-check action whitelist before doing any work.
        val handled = when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            // Clock moved under our armed epoch instants — re-derive them
            // from local wall time (ACTION_TIME_CHANGED == "TIME_SET").
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            ACTION_QUICKBOOT_POWERON,
            ACTION_HTC_QUICKBOOT_POWERON -> true
            else -> false
        }
        if (!handled) {
            Log.w(TAG, "Ignoring unexpected action: $action")
            return
        }

        // NATIVE RE-ARM FIRST — no WorkManager, no Flutter engine (Pixel 9 XL
        // field bug: the WorkManager hand-off below silently died on FBE
        // devices, see AlarmSyncWorker.workManager, and alarms stayed dead
        // until the app was opened). A reboot erases every AlarmManager alarm;
        // re-arming straight from the device-protected store takes
        // milliseconds inside this receiver and works BEFORE first unlock
        // (LOCKED_BOOT_COMPLETED) — so an alarm due before the user unlocks
        // still rings. Runs again on BOOT_COMPLETED — idempotent
        // (UPDATE_CURRENT on the same ids).
        //
        // Clock changes are deliberately EXCLUDED: the stored epoch instants
        // are exactly what a timezone/time change invalidates — only the Dart
        // reconcile can recompute them from local wall time.
        val isClockChange = action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_TIME_CHANGED
        if (!isClockChange) {
            try {
                NativeAlarmScheduling.rearmFromStore(context)
            } catch (e: Exception) {
                Log.e(TAG, "native boot re-arm failed", e)
            }
        }

        // Then hand off to WorkManager for the authoritative Hive reconcile.
        // The Worker runs off the main thread, has no ANR budget, and is the
        // canonical place to spin up a Flutter engine for headless Dart
        // execution. ExistingWorkPolicy.KEEP — if a previous boot's worker is
        // somehow still queued (reboot loop), don't pile on a second.
        try {
            AlarmSyncWorker.enqueueOneShot(context)
            Log.d(TAG, "AlarmSyncWorker enqueued for $action")
        } catch (e: Exception) {
            // Pre-unlock (LOCKED_BOOT_COMPLETED) this always lands here:
            // WorkManager's Room DB lives in credential-encrypted storage.
            // Harmless — the native re-arm above already restored the alarms,
            // and the post-unlock BOOT_COMPLETED retries the enqueue (with
            // AlarmSyncWorker.workManager's on-demand init fixing the
            // direct-boot-born-process trap).
            Log.e(TAG, "Failed to enqueue AlarmSyncWorker", e)
        }
    }
}
