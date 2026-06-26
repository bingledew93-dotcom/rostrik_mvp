package com.example.rostrik_mvp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log

/**
 * The component AlarmManager dispatches to when an exact alarm fires.
 *
 * This is the entry point of the custom native alarm path that REPLACES
 * flutter_local_notifications for core ring delivery. The Dart scheduler builds
 * an EXPLICIT PendingIntent targeting this receiver (action [ACTION_ALARM_FIRE])
 * and hands it to `AlarmManager.setAlarmClock(...)`. Because it's explicit and
 * the receiver is `exported="false"`, no other app can spoof a fire.
 *
 * onReceive runs on the main thread with a ~10s ANR budget, so it does the
 * minimum and returns:
 *   1. Acquire a partial WakeLock so the CPU can't doze back off between here
 *      and the service/activity actually coming up. Held statically (AOSP
 *      AlarmKlaxon pattern) and released by [AlarmActivity] on dismiss; a
 *      [WAKELOCK_TIMEOUT_MS] safety means it can never leak past one ring.
 *   2. Start [AlarmAudioService] in the foreground — the looping audio. Firing
 *      an exact alarm grants a short Android-14 exemption from the
 *      background-FGS-start restriction, which is the ONLY reason a `start
 *      ForegroundService` from a receiver is legal here.
 *   3. Post a high-importance notification whose `setFullScreenIntent` launches
 *      the native [AlarmActivity] over the lock screen. The FSI is the
 *      OS-blessed way to bring an Activity up from the background; the same
 *      notification is the heads-up fallback if the OS suppresses the FSI.
 *
 * The audio (step 2) is intentionally decoupled from the UI (step 3): if the
 * user swipes the alarm screen away, the foreground service keeps screaming.
 */
class AlarmReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "RostrikAlarm"

        // The action the Dart scheduler stamps on the AlarmManager PendingIntent.
        // Validated below before any work runs (defence-in-depth even though the
        // receiver is not exported).
        const val ACTION_ALARM_FIRE = "com.example.rostrik_mvp.action.ALARM_FIRE"

        // ---- Intent extras contract (set by the Dart scheduler) -------------
        // The shift/alarm id. Recorded to the dismissal ledger on dismiss so the
        // Dart layer reconciles Hive — see [AlarmActivity.recordDismissal].
        const val EXTRA_ALARM_ID = "alarm_id"
        // Human label shown on the alarm screen and used as the notification's
        // content TITLE (e.g. "Night shift", or the user's custom alarm name).
        const val EXTRA_LABEL = "label"
        // The ring time, pre-formatted 12-hour on the Dart side ("03:00 AM").
        const val EXTRA_DISPLAY_TIME = "displayTime"
        // Short, time-free shift context ("Before your Night shift"); empty for a
        // plain alarm. Combined with EXTRA_DISPLAY_TIME into the notification's
        // content TEXT — see [notificationDetail].
        const val EXTRA_BODY = "body"
        // OS notification id (the AlarmManager PendingIntent requestCode),
        // forwarded so AlarmActivity's Snooze can re-arm the SAME id — which is
        // what lets a later Dart reconcile converge to one alarm.
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        // Owning AppAlarm UUID — the discriminator the native snooze records for
        // shift-less ("one-off") alarms (all of which share the 'NONE' shiftId).
        const val EXTRA_APP_ALARM_ID = "appAlarmId"
        // The user's configured snooze interval (minutes); AlarmActivity's Snooze
        // re-arms at this offset instead of a hardcoded default.
        const val EXTRA_SNOOZE_MINUTES = "snoozeMinutes"
        // Critical-shift wake mechanics. true ⇒ AlarmActivity requires a
        // sustained shake to dismiss and hides the slide handle (so a half-asleep
        // swipe can't silence it); false ⇒ normal slide-to-dismiss. Mirrors the
        // alarm's `isCritical` flag.
        const val EXTRA_REQUIRES_SHAKE = "requiresShake"
        // Sound routing — SAME keys AlarmAudioService already reads, so the
        // receiver just forwards them through untouched. One source of truth.
        //   EXTRA_SOURCE / EXTRA_URI / EXTRA_VIBRATE / EXTRA_BUNDLED_RESOURCE

        // Foreground-Service-Intent (FSI) keep-up notification.
        private const val CHANNEL_ID = "rostrik_alarm_fire"
        const val NOTIF_ID = 0x414C524D // "ALRM" — shared so AlarmActivity can cancel it.

        // Partial WakeLock held from fire → dismiss. Static so [AlarmActivity]
        // (a different object, possibly a different process incarnation) can
        // release the exact same lock. Reference-counting OFF: a single
        // acquire/release pair, idempotent.
        private const val WAKELOCK_TAG = "rostrik:alarm-fire"
        // Hard ceiling so a never-dismissed alarm (FSI ignored, device in a
        // drawer) can't pin the CPU forever. Comfortably longer than any sane
        // ring window; the service's own playback timeout should end things
        // first.
        private const val WAKELOCK_TIMEOUT_MS = 11L * 60L * 1000L

        @Volatile
        private var wakeLock: PowerManager.WakeLock? = null

        /** Take the ring-window WakeLock if not already held. */
        @Synchronized
        fun acquireWakeLock(context: Context) {
            if (wakeLock?.isHeld == true) return
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG).apply {
                setReferenceCounted(false)
            }
            wl.acquire(WAKELOCK_TIMEOUT_MS)
            wakeLock = wl
            Log.d(TAG, "wakelock acquired")
        }

        /** Release the ring-window WakeLock. Safe to call from any state /
         *  more than once — [AlarmActivity] calls this on dismiss. */
        @Synchronized
        fun releaseWakeLock() {
            val wl = wakeLock ?: return
            wakeLock = null
            try {
                if (wl.isHeld) wl.release()
                Log.d(TAG, "wakelock released")
            } catch (e: Exception) {
                Log.w(TAG, "wakelock release failed", e)
            }
        }

        /** The notification CONTENT-TEXT line shared by the full-screen-intent
         *  notification ([AlarmReceiver]) and the keep-alive notification
         *  ([AlarmAudioService]) so they never drift. Combines the 12-hour ring
         *  time with the optional shift context:
         *    * both → "03:00 AM · Before your Night shift"
         *    * time only → "03:00 AM"
         *    * neither (legacy/preview) → "Alarm". */
        fun notificationDetail(displayTime: String?, body: String?): String {
            val time = displayTime?.takeIf { it.isNotBlank() }
            val context = body?.takeIf { it.isNotBlank() }
            return when {
                time != null && context != null -> "$time · $context"
                time != null -> time
                context != null -> context
                else -> "Alarm"
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        // Defensive: only act on our own fire action. AlarmManager delivers the
        // explicit PendingIntent we built, but re-checking costs nothing.
        if (intent.action != null && intent.action != ACTION_ALARM_FIRE) {
            Log.w(TAG, "ignoring unexpected action: ${intent.action}")
            return
        }
        Log.d(TAG, "alarm fired: id=${intent.getStringExtra(EXTRA_ALARM_ID)}")

        // 1. Pin the CPU before anything can doze us back to sleep.
        acquireWakeLock(context)

        // 2. Start the looping audio in the foreground service. Forward the
        //    sound routing extras verbatim using AlarmAudioService's own keys.
        startAudioService(context, intent)

        // 3. Post the full-screen-intent notification that launches the native
        //    alarm screen over the keyguard.
        postFullScreenNotification(context, intent)
    }

    private fun startAudioService(context: Context, fireIntent: Intent) {
        val serviceIntent = Intent(context, AlarmAudioService::class.java).apply {
            action = AlarmAudioService.ACTION_PLAY
            // The shift/alarm id rides through to the service so its 15-minute
            // AUTO-TIMEOUT can record the dismissal against the right shift in
            // the ledger (Dart acks it in Hive). Same key the fire intent uses.
            putExtra(
                AlarmAudioService.EXTRA_ALARM_ID,
                fireIntent.getStringExtra(EXTRA_ALARM_ID),
            )
            // The owning AppAlarm id, so the service's 15-min auto-timeout can
            // record a fired ONE-TIME rule for deletion (same cleanup the manual
            // dismiss does) even when the user never touched the phone.
            putExtra(EXTRA_APP_ALARM_ID, fireIntent.getStringExtra(EXTRA_APP_ALARM_ID))
            // Forward the notification detail so the service's keep-alive
            // notification reads the same as the full-screen one (label title +
            // "time · context" text) instead of a generic "Alarm".
            putExtra(EXTRA_LABEL, fireIntent.getStringExtra(EXTRA_LABEL))
            putExtra(EXTRA_DISPLAY_TIME, fireIntent.getStringExtra(EXTRA_DISPLAY_TIME))
            putExtra(EXTRA_BODY, fireIntent.getStringExtra(EXTRA_BODY))
            // Forward the sound selection straight through. The receiver doesn't
            // need to understand it — it's the same wire AlarmAudioService /
            // AlarmAudioEngine already speak.
            putExtra(
                AlarmAudioService.EXTRA_SOURCE,
                fireIntent.getIntExtra(AlarmAudioService.EXTRA_SOURCE, AlarmAudioEngine.SOURCE_CLASSIC),
            )
            putExtra(AlarmAudioService.EXTRA_URI, fireIntent.getStringExtra(AlarmAudioService.EXTRA_URI))
            putExtra(
                AlarmAudioService.EXTRA_VIBRATE,
                fireIntent.getBooleanExtra(AlarmAudioService.EXTRA_VIBRATE, false),
            )
            putExtra(
                AlarmAudioService.EXTRA_BUNDLED_RESOURCE,
                fireIntent.getStringExtra(AlarmAudioService.EXTRA_BUNDLED_RESOURCE),
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

    private fun postFullScreenNotification(context: Context, fireIntent: Intent) {
        ensureChannel(context)

        val alarmId = fireIntent.getStringExtra(EXTRA_ALARM_ID)
        val label = fireIntent.getStringExtra(EXTRA_LABEL) ?: "Alarm"
        val displayTime = fireIntent.getStringExtra(EXTRA_DISPLAY_TIME)
        val body = fireIntent.getStringExtra(EXTRA_BODY)

        val activityIntent = Intent(context, AlarmActivity::class.java).apply {
            // NEW_TASK is required to launch an Activity from this non-activity
            // context. `singleInstance` in the manifest keeps it the sole
            // activity in its own task, so a warm re-fire routes through
            // onNewIntent (not a destroy/recreate) and a dismiss can
            // finishAndRemoveTask() without disturbing the main app task. Carry
            // the id/label forward for the dismissal ledger + UI.
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra(EXTRA_ALARM_ID, alarmId)
            putExtra(EXTRA_LABEL, label)
            // Carried so a Snooze re-arm keeps the same notification detail (and
            // re-stamps the time for the new ring) — see AlarmActivity.snoozeAlarm.
            putExtra(EXTRA_DISPLAY_TIME, displayTime)
            putExtra(EXTRA_BODY, body)
            // Forwarded so AlarmActivity's Snooze can re-arm the SAME alarm
            // (same notification id + tone) at the user's snooze offset.
            putExtra(EXTRA_NOTIFICATION_ID, fireIntent.getIntExtra(EXTRA_NOTIFICATION_ID, -1))
            putExtra(EXTRA_APP_ALARM_ID, fireIntent.getStringExtra(EXTRA_APP_ALARM_ID))
            putExtra(EXTRA_SNOOZE_MINUTES, fireIntent.getIntExtra(EXTRA_SNOOZE_MINUTES, 1))
            // Drives the dismiss gesture (shake vs slide) on the alarm screen.
            putExtra(
                EXTRA_REQUIRES_SHAKE,
                fireIntent.getBooleanExtra(EXTRA_REQUIRES_SHAKE, false),
            )
            putExtra(
                AlarmAudioService.EXTRA_SOURCE,
                fireIntent.getIntExtra(AlarmAudioService.EXTRA_SOURCE, AlarmAudioEngine.SOURCE_CLASSIC),
            )
            putExtra(AlarmAudioService.EXTRA_URI, fireIntent.getStringExtra(AlarmAudioService.EXTRA_URI))
            putExtra(
                AlarmAudioService.EXTRA_VIBRATE,
                fireIntent.getBooleanExtra(AlarmAudioService.EXTRA_VIBRATE, false),
            )
            putExtra(
                AlarmAudioService.EXTRA_BUNDLED_RESOURCE,
                fireIntent.getStringExtra(AlarmAudioService.EXTRA_BUNDLED_RESOURCE),
            )
        }

        var piFlags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            piFlags = piFlags or PendingIntent.FLAG_IMMUTABLE
        }
        // requestCode keyed on the alarm id so distinct alarms get distinct
        // PendingIntents (UPDATE_CURRENT refreshes a re-fire's extras).
        val requestCode = alarmId?.hashCode() ?: 0
        val fullScreenPi = PendingIntent.getActivity(
            context,
            requestCode,
            activityIntent,
            piFlags,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val notification = builder
            .setContentTitle(label)
            .setContentText(notificationDetail(displayTime, body))
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            // Tapping the heads-up AND the OS-launched full-screen both route to
            // the alarm screen. `true` = launch the FSI even in heads-up-capable
            // foreground states.
            .setContentIntent(fullScreenPi)
            .setFullScreenIntent(fullScreenPi, true)
            .build()

        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        mgr.notify(NOTIF_ID, notification)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (mgr.getNotificationChannel(CHANNEL_ID) != null) return
        // IMPORTANCE_HIGH is the floor for a full-screen intent to be honoured.
        // Sound/vibration are silenced on the CHANNEL because AlarmAudioService
        // owns the audio + haptics — we must not double up.
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Alarm",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Fires the full-screen alarm when a shift alarm is due."
            setSound(null, null)
            enableVibration(false)
            setBypassDnd(true)
        }
        mgr.createNotificationChannel(channel)
    }
}
