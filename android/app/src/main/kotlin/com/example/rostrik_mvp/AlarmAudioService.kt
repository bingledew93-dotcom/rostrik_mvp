package com.example.rostrik_mvp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log

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
 * NOTHING but the ring-window audio — scheduling, the notification, FSI
 * routing, dismiss/snooze, and the Hive reconcile all stay with
 * flutter_local_notifications exactly as before.
 *
 * Lifecycle: started by [MainActivity] when WakeUpScreen begins fire-time
 * playback (`previewRingtone(asAlarm:true)` over the ringtone channel), while
 * the FSI activity is foreground (so the background-FGS-launch restriction is
 * satisfied). Stopped when Dart issues `stopPreview` on Dismiss / Snooze /
 * self-destruct — [MainActivity] calls `stopService`, which routes to
 * [onDestroy]. The editor's short preview stays in-activity (never reaches the
 * lock screen) and does not use this service.
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

        // Dedicated low-importance channel for the FGS keep-alive notification.
        // Silent + non-vibrating: the alarm's own FullScreenIntent notification
        // owns all UX; this one exists only because a foreground service must
        // post a notification.
        private const val CHANNEL_ID = "rostrik_alarm_playback"
        private const val NOTIF_ID = 0x41554449 // "AUDI"
    }

    private var engine: AlarmAudioEngine? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY -> {
                // Go foreground IMMEDIATELY (well within the 5s startForeground
                // deadline) so the process is pinned before anything else.
                startForegroundCompat()
                val source = intent.getIntExtra(EXTRA_SOURCE, AlarmAudioEngine.SOURCE_CLASSIC)
                val uri = intent.getStringExtra(EXTRA_URI)
                val vibrate = intent.getBooleanExtra(EXTRA_VIBRATE, false)
                val bundledResource = intent.getStringExtra(EXTRA_BUNDLED_RESOURCE)
                val e = engine ?: AlarmAudioEngine(applicationContext).also { engine = it }
                e.play(source, uri, vibrate, bundledResource)
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
        engine?.stop()
        engine = null
        stopForegroundCompat()
        stopSelf()
    }

    override fun onDestroy() {
        // `stopService` from MainActivity routes here — stop the audio. The FGS
        // notification is removed automatically when the service is destroyed.
        engine?.stop()
        engine = null
        Log.d(TAG, "AlarmAudioService destroyed — alarm audio stopped")
        super.onDestroy()
    }

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
            .setContentTitle("Alarm")
            .setContentText("Your alarm is ringing")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .build()
    }
}
