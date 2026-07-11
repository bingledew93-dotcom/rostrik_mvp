package com.example.rostrik_mvp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import java.io.File
import java.io.FileOutputStream

/**
 * Foreground service that owns FIRING-ALARM audio.
 *
 * WHY THIS EXISTS (Android 14 keyguard Silence Bug): a process-scoped (static)
 * MediaPlayer survives the Activity instance being destroyed, but it CANNOT
 * survive the process. When a `showWhenLocked` FullScreenIntent activity is
 * occluded by the notification shade ON THE LOCK SCREEN, Android 14 stops then
 * destroys it — and with no visible activity and no foreground service left,
 * the process drops to an empty/cached oom bucket and the Pixel reaps it within
 * moments, taking the static player (and the alarm audio) with it. Unlocked,
 * the activity stays visible behind the translucent shade, the process keeps
 * foreground priority, and the audio survives — hence the locked-only bug.
 *
 * A foreground service of type `mediaPlayback` raises the PROCESS to foreground
 * oom-priority, which is the only OS-blessed way to keep playback (and the
 * process) alive across that keyguard/activity transition. This service owns
 * the ring-window audio AND a strict battery fail-safe.
 *
 * BATTERY FAIL-SAFE (15-minute auto-timeout): because the audio is deliberately
 * decoupled from the UI, a phone left unattended — FSI ignored, screen dark, no
 * one to shake or tap Dismiss — would otherwise ring (and hold a WakeLock) until
 * the battery hit zero. So the service arms a [AUTO_TIMEOUT_MS] timer on every
 * `play`. If it elapses with no user dismiss, [onAutoTimeout] records the
 * dismissal in the native ledger (so Dart still acknowledges the shift in Hive),
 * releases the fire-time WakeLock, stops the audio, cancels the full-screen
 * notification, and broadcasts [ACTION_AUTO_DISMISS] so [AlarmActivity] tears
 * its window down and the screen can turn off. A deliberate dismiss
 * (shake/button → stopService) cancels the timer first via [onDestroy].
 *
 * Lifecycle: started by [AlarmReceiver] (fire-time) or [MainActivity] (the
 * legacy preview/fire path) while a foreground component is up, so the
 * background-FGS-launch restriction is satisfied. Stopped on Dismiss/Snooze/
 * self-destruct (stopService → [onDestroy]) or by the auto-timeout above.
 */
class AlarmAudioService : Service() {
    companion object {
        private const val TAG = "Rostrik"

        const val ACTION_PLAY = "com.example.rostrik_mvp.action.ALARM_PLAY"
        const val ACTION_STOP = "com.example.rostrik_mvp.action.ALARM_STOP"
        const val EXTRA_SOURCE = "source"
        const val EXTRA_URI = "uri"
        const val EXTRA_VIBRATE = "vibrate"

        // PRESET internal tone: a `res/raw` name (mirrors
        // AlarmSound.androidResource). Non-null routes a bundled preset through
        // this service — the whole point of regression 1: EVERY fire-time
        // alarm, preset or custom, plays here, never via FLAG_INSISTENT.
        const val EXTRA_BUNDLED_RESOURCE = "bundledResource"

        // The shift/alarm id, forwarded by AlarmReceiver so the auto-timeout can
        // record the right shift in the dismissal ledger. Same key the fire
        // intent carries (AlarmReceiver.EXTRA_ALARM_ID == "alarm_id").
        const val EXTRA_ALARM_ID = "alarm_id"

        // Broadcast the service sends on auto-timeout to finish AlarmActivity.
        // AlarmActivity registers a NOT_EXPORTED receiver for it.
        const val ACTION_AUTO_DISMISS = "com.example.rostrik_mvp.action.ALARM_AUTO_DISMISS"

        // Strict battery ceiling: stop a never-dismissed alarm after 15 minutes.
        private const val AUTO_TIMEOUT_MS = 15L * 60L * 1000L

        // Mirrors `noShiftPayloadSentinel` in lib/alarms/alarm_sync_service.dart.
        // Shift-less alarms (one-time/weekly) carry this id and have no shift row
        // to acknowledge — never written to the ledger. Keep in lock-step.
        private const val NO_SHIFT_SENTINEL = "NONE"

        // Dismissal fail-safe ledger — MUST equal MainActivity.PENDING_DISMISSALS_FILE,
        // AlarmActivity.PENDING_DISMISSALS_FILE, and pendingDismissalsFileName in
        // lib/alarms/pending_dismissal_guard.dart.
        private const val PENDING_DISMISSALS_FILE = "pending_dismissals"

        // Fired-one-time cleanup ledger — MUST equal
        // AlarmActivity.PENDING_ALARM_DELETES_FILE and pendingAlarmDeletesFileName
        // in lib/alarms/pending_alarm_delete_guard.dart. The auto-timeout records
        // the fired rule's appAlarmId here so Dart deletes a spent one-time alarm
        // (same cleanup a manual dismiss does) before it re-projects.
        private const val PENDING_ALARM_DELETES_FILE = "pending_alarm_deletes"

        // Dedicated low-importance channel for the FGS keep-alive notification.
        // Silent + non-vibrating: the alarm's own FullScreenIntent notification
        // owns all UX; this one exists only because a foreground service must
        // post a notification.
        private const val CHANNEL_ID = "rostrik_alarm_playback"
        private const val NOTIF_ID = 0x41554449 // "AUDI"
    }

    private var engine: AlarmAudioEngine? = null

    /** The ringing shift's id, captured on [ACTION_PLAY]. Null on the legacy
     *  MainActivity preview path (no id) — the auto-timeout then records
     *  nothing but still tears everything down. */
    private var alarmId: String? = null

    /** The owning AppAlarm id, captured on [ACTION_PLAY]. Recorded by the
     *  auto-timeout so Dart can delete a fired ONE-TIME rule (same cleanup a
     *  manual dismiss does). Null on the legacy preview path. */
    private var appAlarmId: String? = null

    /** The ringing alarm's PER-ALARM fire-notification id (audit F4), captured
     *  on [ACTION_PLAY] so the auto-timeout cancels the right notification.
     *  -1 on legacy/preview intents → falls back to [AlarmReceiver.NOTIF_ID]. */
    private var fsiNotificationId: Int = -1

    /** Notification copy, captured on [ACTION_PLAY] and used by
     *  [buildNotification] so the keep-alive notification matches the
     *  full-screen one. Defaults keep the legacy preview path readable. */
    private var label: String = "Alarm"
    private var displayTime: String? = null
    private var contextText: String? = null

    private val timeoutHandler = Handler(Looper.getMainLooper())
    private val autoTimeoutRunnable = Runnable { onAutoTimeout() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY -> {
                alarmId = intent.getStringExtra(EXTRA_ALARM_ID)
                appAlarmId = intent.getStringExtra(AlarmReceiver.EXTRA_APP_ALARM_ID)
                fsiNotificationId =
                    intent.getIntExtra(AlarmReceiver.EXTRA_NOTIFICATION_ID, -1)
                // Capture the notification copy BEFORE going foreground so the
                // keep-alive notification is built with it (reading three extras
                // is microseconds — still well within the 5s startForeground
                // deadline). Falls back to defaults on the legacy preview path.
                intent.getStringExtra(AlarmReceiver.EXTRA_LABEL)?.let { label = it }
                displayTime = intent.getStringExtra(AlarmReceiver.EXTRA_DISPLAY_TIME)
                contextText = intent.getStringExtra(AlarmReceiver.EXTRA_BODY)
                // Go foreground (well within the 5s startForeground deadline) so
                // the process is pinned before anything else.
                startForegroundCompat()
                val source = intent.getIntExtra(EXTRA_SOURCE, AlarmAudioEngine.SOURCE_CLASSIC)
                val uri = intent.getStringExtra(EXTRA_URI)
                val vibrate = intent.getBooleanExtra(EXTRA_VIBRATE, false)
                val bundledResource = intent.getStringExtra(EXTRA_BUNDLED_RESOURCE)
                val e = engine ?: AlarmAudioEngine(applicationContext).also { engine = it }
                e.play(source, uri, vibrate, bundledResource)
                // Arm (or re-arm) the 15-minute battery fail-safe from the moment
                // the alarm starts ringing.
                scheduleAutoTimeout()
            }
            else -> stopEverything() // ACTION_STOP or anything unexpected
        }
        // NOT_STICKY: if the process is somehow killed despite the FGS, do NOT
        // auto-restart and re-ring a possibly already-dismissed alarm — the
        // authoritative dismissal state lives in Hive / the native ledger, not
        // here. The FGS itself is what prevents the kill.
        return START_NOT_STICKY
    }

    private fun stopEverything() {
        cancelAutoTimeout()
        engine?.stop()
        engine = null
        stopForegroundCompat()
        stopSelf()
    }

    override fun onDestroy() {
        // `stopService` from a deliberate Dismiss/Snooze routes here — cancel the
        // fail-safe timer (so it can't fire after the user already handled it)
        // and stop the audio. The FGS notification is removed automatically when
        // the service is destroyed.
        cancelAutoTimeout()
        engine?.stop()
        engine = null
        Log.d(TAG, "AlarmAudioService destroyed — alarm audio stopped")
        super.onDestroy()
    }

    // -----------------------------------------------------------------------
    // 15-minute battery fail-safe
    // -----------------------------------------------------------------------

    private fun scheduleAutoTimeout() {
        timeoutHandler.removeCallbacks(autoTimeoutRunnable)
        timeoutHandler.postDelayed(autoTimeoutRunnable, AUTO_TIMEOUT_MS)
    }

    private fun cancelAutoTimeout() {
        timeoutHandler.removeCallbacks(autoTimeoutRunnable)
    }

    /** Fired when 15 minutes elapse with no user dismiss. Performs the full
     *  unattended teardown so a phone left in a drawer can't drain to zero. */
    private fun onAutoTimeout() {
        Log.w(TAG, "alarm hit the 15-min auto-timeout — stopping to save battery")
        // 1. Record the dismissal so Dart still resolves this ring in Hive
        //    (same `<shiftId>|<appAlarmId>` contract as a manual dismiss — the
        //    appAlarmId keeps it scoped to THIS ring, not the whole shift).
        recordAutoDismissal(alarmId, appAlarmId)
        // 1b. Record the fired rule so Dart deletes a spent ONE-TIME alarm —
        //     same cleanup the manual dismiss does, so an unattended one-shot
        //     can't re-project into a daily cycle.
        recordPendingAlarmDelete(appAlarmId)
        // 2. Release the fire-time WakeLock AlarmReceiver took.
        AlarmReceiver.releaseWakeLock()
        // 3. Stop the audio + haptics.
        engine?.stop()
        engine = null
        // 4. Clear the full-screen-intent notification (the service's own
        //    keep-alive notif goes away with stopForeground below).
        cancelFullScreenNotification()
        // 5. Tell AlarmActivity to finish so the screen can turn off.
        broadcastKillActivity()
        // 6. Drop foreground state and stop the service.
        stopForegroundCompat()
        stopSelf()
    }

    /** Append `<shiftId>|<appAlarmId>` to the native ledger, flushed + fsync'd
     *  so it survives an immediate reap. Mirrors [AlarmActivity.recordDismissal]:
     *  the appAlarmId scopes the auto-timeout dismissal to the ring that was
     *  actually sounding, so the shift's other alarms stay armed. Skips empty /
     *  shift-less (`NONE`) shift ids — there is no shift row to update for
     *  those. */
    private fun recordAutoDismissal(shiftId: String?, appAlarmId: String?) {
        if (shiftId.isNullOrEmpty() || shiftId == NO_SHIFT_SENTINEL) {
            Log.d(TAG, "auto-timeout: no shift id to record (id='$shiftId')")
            return
        }
        val line = if (appAlarmId.isNullOrEmpty()) shiftId else "$shiftId|$appAlarmId"
        try {
            val file = File(filesDir, PENDING_DISMISSALS_FILE)
            FileOutputStream(file, /* append = */ true).use { out ->
                out.write((line + "\n").toByteArray(Charsets.UTF_8))
                out.flush()
                out.fd.sync()
            }
            Log.d(TAG, "auto-timeout recorded dismissal $line")
        } catch (e: Exception) {
            Log.w(TAG, "auto-timeout recordDismissal failed $line", e)
        }
    }

    /** Append the fired alarm's owning [appAlarmId] to the cleanup ledger,
     *  flushed + fsync'd. Mirrors [AlarmActivity.recordPendingAlarmDelete] so the
     *  auto-timeout path deletes a spent one-time alarm exactly as a manual
     *  dismiss would. Skips an empty id (the legacy preview path). */
    private fun recordPendingAlarmDelete(appAlarmId: String?) {
        if (appAlarmId.isNullOrEmpty()) {
            Log.d(TAG, "auto-timeout: no appAlarmId to record for cleanup")
            return
        }
        try {
            val file = File(filesDir, PENDING_ALARM_DELETES_FILE)
            FileOutputStream(file, /* append = */ true).use { out ->
                out.write((appAlarmId + "\n").toByteArray(Charsets.UTF_8))
                out.flush()
                out.fd.sync()
            }
            Log.d(TAG, "auto-timeout recorded pending alarm-delete id=$appAlarmId")
        } catch (e: Exception) {
            Log.w(TAG, "auto-timeout recordPendingAlarmDelete failed id=$appAlarmId", e)
        }
    }

    private fun cancelFullScreenNotification() {
        try {
            val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            // Per-alarm id (audit F4) — cancel the ringing alarm's own fire
            // notification; legacy intents fall back to the fixed id.
            mgr.cancel(
                if (fsiNotificationId >= 0) fsiNotificationId else AlarmReceiver.NOTIF_ID,
            )
        } catch (e: Exception) {
            Log.w(TAG, "FSI notification cancel failed", e)
        }
    }

    private fun broadcastKillActivity() {
        // Targeted to our own package; AlarmActivity's receiver is NOT_EXPORTED
        // so nothing outside the app can see or spoof this.
        val killIntent = Intent(ACTION_AUTO_DISMISS).setPackage(packageName)
        sendBroadcast(killIntent)
    }

    // -----------------------------------------------------------------------
    // Foreground-service plumbing (unchanged from the Silence-Bug fix)
    // -----------------------------------------------------------------------

    private fun startForegroundCompat() {
        ensureChannel()
        val notif = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ID,
                notif,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(NOTIF_ID, notif)
        }
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (mgr.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Alarm playback",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps a ringing custom alarm playing reliably."
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        mgr.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle(label)
            .setContentText(AlarmReceiver.notificationDetail(displayTime, contextText))
            .setSmallIcon(R.drawable.ic_stat_alarm)
            .setOngoing(true)
            .build()
    }
}
