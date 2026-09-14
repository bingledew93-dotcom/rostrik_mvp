package com.example.rostrik_mvp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
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

        // FALLBACK notification id (audit F4): the fire notification is keyed
        // by the alarm's own EXTRA_NOTIFICATION_ID so near-simultaneous alarms
        // get SEPARATE, separately-dismissable notifications instead of the
        // second silently replacing the first (the audio + wake screen still
        // coalesce onto the newest — one service, one singleInstance activity —
        // but a superseded alarm's notification stays in the shade; tapping it
        // reopens AlarmActivity with THAT alarm's payload so its dismissal is
        // still recorded). This constant is only used when the extra is absent
        // (legacy intents / the preview path).
        const val NOTIF_ID = 0x414C524D // "ALRM"

        // Partial WakeLock held from fire → dismiss. Static so [AlarmActivity]
        // (a different object, possibly a different process incarnation) can
        // release the exact same lock. Reference-counting OFF: a single
        // acquire/release pair, idempotent.
        private const val WAKELOCK_TAG = "rostrik:alarm-fire"
        // Hard ceiling so a never-dismissed alarm (FSI ignored, device in a
        // drawer) can't pin the CPU forever. MUST outlast AlarmAudioService's
        // 15-minute AUTO_TIMEOUT (audit F5 — it was 11 min, silently lapsing
        // mid-ring; the MediaPlayer's own wake mode masked it): the service's
        // timeout is the intended end of an unattended ring, and it releases
        // this lock itself, so the ceiling only ever fires as a fail-safe.
        private const val WAKELOCK_TIMEOUT_MS = 16L * 60L * 1000L

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
        fun notificationDetail(
            ctx: Context,
            displayTime: String?,
            body: String?,
        ): String {
            val time = displayTime?.takeIf { it.isNotBlank() }
            val context = body?.takeIf { it.isNotBlank() }
            return when {
                time != null && context != null -> "$time · $context"
                time != null -> time
                context != null -> context
                else -> ctx.getString(R.string.alarm_fallback_title)
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

        // Built once and used twice: posted below, and held in the foreground
        // by the audio service (which makes it impossible to swipe away).
        val notifId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1).let { if (it >= 0) it else NOTIF_ID }
        val notification = buildRingNotification(context, intent)

        // 2. Start the looping audio in the foreground service. Forward the
        //    sound routing extras verbatim using AlarmAudioService's own keys.
        startAudioService(context, intent, notification)

        // 3. Post the full-screen-intent notification that launches the native
        //    alarm screen over the keyguard. Posted here as well as by the
        //    service so the full-screen launch never waits on the service start.
        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        // Per-alarm id (audit F4) — a second alarm firing mid-ring posts its
        // OWN notification instead of replacing the first one's.
        mgr.notify(notifId, notification)
    }

    private fun startAudioService(context: Context, fireIntent: Intent, notification: Notification) {
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
            // The per-alarm notification id, so the auto-timeout cancels THIS
            // alarm's fire notification (audit F4 keys them per alarm).
            putExtra(
                EXTRA_NOTIFICATION_ID,
                fireIntent.getIntExtra(EXTRA_NOTIFICATION_ID, -1),
            )
            // The ring notification itself, which the service holds as its
            // foreground notification under the same id.
            putExtra(AlarmAudioService.EXTRA_RING_NOTIFICATION, notification)
            // Forward the notification detail for the legacy keep-alive
            // notification, used only when no ring notification is passed.
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

    /** The ringing alarm's notification: full-screen intent to [AlarmActivity],
     *  plus Snooze and — for a normal alarm — Dismiss buttons.
     *
     *  The buttons matter because Android launches the full-screen intent only
     *  when the phone is locked or the screen is off. On an unlocked phone in use
     *  it shows this notification as a heads-up instead, and before the buttons
     *  existed that heads-up offered no way to stop the ring. A critical-shift
     *  alarm gets "Open alarm" in place of Dismiss, so ending it still takes the
     *  shake on the alarm screen. */
    private fun buildRingNotification(context: Context, fireIntent: Intent): Notification {
        ensureChannel(context)

        val ring = AlarmRingControl.Ring.from(fireIntent)
        val displayTime = fireIntent.getStringExtra(EXTRA_DISPLAY_TIME)

        // NEW_TASK is required to launch an Activity from this non-activity
        // context. `singleInstance` in the manifest keeps it the sole activity in
        // its own task, so a warm re-fire routes through onNewIntent (not a
        // destroy/recreate) and a dismiss can finishAndRemoveTask() without
        // disturbing the main app task. The ring payload drives the dismissal
        // ledger, Snooze's re-arm (same notification id + tone at the user's
        // snooze offset) and the dismiss gesture (shake vs slide); the display
        // time is carried so a Snooze re-arm keeps the notification detail.
        val activityIntent = ring.writeTo(Intent(context, AlarmActivity::class.java)).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra(EXTRA_DISPLAY_TIME, displayTime)
        }

        var piFlags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            piFlags = piFlags or PendingIntent.FLAG_IMMUTABLE
        }
        // requestCode keyed on the PER-ALARM notification id so distinct
        // alarms get distinct PendingIntents even on the SAME shift (a
        // shiftId-hash key would let UPDATE_CURRENT silently rewrite an
        // earlier notification's tap payload with the newer alarm's extras).
        // Falls back to the shift-id hash for legacy intents without the id.
        val requestCode = if (ring.notificationId >= 0) ring.notificationId else (ring.alarmId?.hashCode() ?: 0)
        val fullScreenPi = PendingIntent.getActivity(
            context,
            requestCode,
            activityIntent,
            piFlags,
        )

        // Button PendingIntents share the request code; their distinct actions
        // keep them from matching each other or the activity intent.
        fun buttonIntent(action: String): PendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            ring.writeTo(Intent(context, AlarmActionReceiver::class.java).setAction(action)),
            piFlags,
        )
        val icon = Icon.createWithResource(context, R.drawable.ic_stat_alarm)
        val snooze = Notification.Action.Builder(
            icon,
            context.getString(R.string.alarm_action_snooze),
            buttonIntent(AlarmActionReceiver.ACTION_SNOOZE),
        ).build()
        val end = if (ring.requiresShake) {
            Notification.Action.Builder(icon, context.getString(R.string.alarm_action_open), fullScreenPi).build()
        } else {
            Notification.Action.Builder(
                icon,
                context.getString(R.string.alarm_action_dismiss),
                buttonIntent(AlarmActionReceiver.ACTION_DISMISS),
            ).build()
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        return builder
            .setContentTitle(ring.label)
            .setContentText(notificationDetail(context, displayTime, ring.contextText))
            .setSmallIcon(R.drawable.ic_stat_alarm)
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            // Shown in full on the lock screen, buttons included: an alarm must be
            // stoppable without unlocking, exactly like the alarm screen.
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            // The service re-posts this same notification when it goes
            // foreground; without this the heads-up would pop a second time.
            .setOnlyAlertOnce(true)
            // Tapping the heads-up AND the OS-launched full-screen both route to
            // the alarm screen. `true` = launch the FSI even in heads-up-capable
            // foreground states.
            .setContentIntent(fullScreenPi)
            .setFullScreenIntent(fullScreenPi, true)
            .addAction(snooze)
            .addAction(end)
            .build()
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (mgr.relabelChannel(
            CHANNEL_ID,
            context.getString(R.string.channel_alarm_name),
            context.getString(R.string.channel_alarm_description),
        )) return
        // IMPORTANCE_HIGH is the floor for a full-screen intent to be honoured.
        // Sound/vibration are silenced on the CHANNEL because AlarmAudioService
        // owns the audio + haptics — we must not double up.
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.channel_alarm_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = context.getString(R.string.channel_alarm_description)
            setSound(null, null)
            enableVibration(false)
            setBypassDnd(true)
        }
        mgr.createNotificationChannel(channel)
    }
}
