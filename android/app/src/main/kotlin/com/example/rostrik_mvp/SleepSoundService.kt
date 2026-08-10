package com.example.rostrik_mvp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.view.KeyEvent

/**
 * Foreground service that plays a looping SLEEP SOUND (white/brown noise etc.)
 * with a wind-down auto-stop timer. Completely separate from the shift-alarm
 * audio path ([AlarmAudioService]): this is calm MEDIA playback, not an alarm.
 *
 * WHY A FOREGROUND SERVICE: the user starts a sound and locks the phone to fall
 * asleep. A plain in-activity MediaPlayer would be torn down when the activity
 * stops. A `mediaPlayback` foreground service keeps the process (and the audio)
 * alive with the screen off until the timer elapses or the user stops it.
 *
 * AUDIO FOCUS: it requests `AUDIOFOCUS_GAIN`, so other media (Spotify, YouTube
 * Music…) pauses while the sleep sound plays — one clean source. It respects
 * focus changes: a permanent loss stops it, a transient loss pauses, a duck
 * lowers the volume.
 *
 * UNIVERSAL AUTO-STOP (the bonus): when the timer elapses it stops its own audio
 * AND dispatches a MEDIA_PAUSE key event, best-effort, so any other app that
 * grabbed playback back is paused too — the timer acts as a "silence everything"
 * wind-down. On a manual stop only our own audio stops.
 */
class SleepSoundService : Service() {
    companion object {
        private const val TAG = "RostrikSleep"

        const val ACTION_PLAY = "com.example.rostrik_mvp.action.SLEEP_PLAY"
        const val ACTION_STOP = "com.example.rostrik_mvp.action.SLEEP_STOP"

        // res/raw resource name of the looping sound (e.g. "sleep_brown_noise").
        const val EXTRA_RESOURCE = "resource"
        // Human label shown in the notification (e.g. "Brown noise").
        const val EXTRA_LABEL = "label"
        // Auto-stop after this many minutes; 0 = play until stopped.
        const val EXTRA_TIMER_MINUTES = "timerMinutes"

        // Broadcast sent (package-local) whenever playback stops for ANY reason —
        // timer, manual, or focus loss — so the Flutter UI can un-highlight the
        // playing tile. MainActivity relays it to the `rostrik/sleep_sounds`
        // channel as `onSleepStopped`.
        const val ACTION_SLEEP_STOPPED = "com.example.rostrik_mvp.action.SLEEP_STOPPED"

        // Low-key channel for the FGS keep-alive notification (silent, no badge).
        private const val CHANNEL_ID = "rostrik_sleep_sounds"
        private const val NOTIF_ID = 0x534C4550 // "SLEP"

        /** True while the service is alive and playing — queried by the Flutter
         *  side (`isSleepPlaying`) so the UI can re-sync after a background stop. */
        @Volatile
        var isRunning: Boolean = false
            private set
    }

    private var player: MediaPlayer? = null
    private var audioManager: AudioManager? = null
    private var focusRequest: AudioFocusRequest? = null
    private var label: String = "Sleep sound"

    private val timeoutHandler = Handler(Looper.getMainLooper())
    private val autoStopRunnable = Runnable { stopEverything(fromTimer = true) }

    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            AudioManager.AUDIOFOCUS_LOSS -> stopEverything(fromTimer = false)
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> player?.let { if (it.isPlaying) it.pause() }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK ->
                player?.setVolume(0.2f, 0.2f)
            AudioManager.AUDIOFOCUS_GAIN -> player?.let {
                it.setVolume(1.0f, 1.0f)
                if (!it.isPlaying) it.start()
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY -> {
                val resource = intent.getStringExtra(EXTRA_RESOURCE)
                label = intent.getStringExtra(EXTRA_LABEL) ?: "Sleep sound"
                val timerMinutes = intent.getIntExtra(EXTRA_TIMER_MINUTES, 0)
                // Go foreground first (well within the 5s deadline) so the process
                // is pinned before we prepare audio.
                startForegroundCompat(timerMinutes)
                val started = startPlayback(resource)
                if (!started) {
                    stopEverything(fromTimer = false)
                    return START_NOT_STICKY
                }
                armAutoStop(timerMinutes)
            }
            else -> stopEverything(fromTimer = false) // ACTION_STOP / unexpected
        }
        // NOT_STICKY: a sleep sound is a convenience — never auto-restart it after
        // an OS kill (the user isn't awake to expect it back).
        return START_NOT_STICKY
    }

    /** Prepares + starts the looping sound and grabs audio focus. Returns false
     *  if the resource can't be resolved/opened (caller then tears down). */
    private fun startPlayback(resourceName: String?): Boolean {
        if (resourceName.isNullOrEmpty()) {
            Log.w(TAG, "no resource name supplied")
            return false
        }
        val resId = resources.getIdentifier(resourceName, "raw", packageName)
        if (resId == 0) {
            Log.w(TAG, "sleep sound resource not found: $resourceName")
            return false
        }

        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()

        // Pause other media while our sound plays (clean single source).
        if (!requestFocus(attrs)) {
            Log.w(TAG, "audio focus denied — playing anyway")
        }

        return try {
            // Release any previous player (a re-tap swaps the sound seamlessly).
            player?.release()
            val afd = resources.openRawResourceFd(resId) ?: return false
            player = MediaPlayer().apply {
                setAudioAttributes(attrs)
                afd.use { setDataSource(it.fileDescriptor, it.startOffset, it.length) }
                isLooping = true
                setOnErrorListener { _, what, extra ->
                    Log.w(TAG, "MediaPlayer error what=$what extra=$extra")
                    stopEverything(fromTimer = false)
                    true
                }
                prepare()
                setVolume(1.0f, 1.0f)
                start()
            }
            isRunning = true
            true
        } catch (e: Exception) {
            Log.w(TAG, "sleep playback failed for $resourceName", e)
            false
        }
    }

    private fun requestFocus(attrs: AudioAttributes): Boolean {
        val am = (getSystemService(Context.AUDIO_SERVICE) as AudioManager).also {
            audioManager = it
        }
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attrs)
                .setOnAudioFocusChangeListener(focusListener)
                .build()
            focusRequest = req
            am.requestAudioFocus(req) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            @Suppress("DEPRECATION")
            am.requestAudioFocus(
                focusListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN,
            ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    private fun abandonFocus() {
        val am = audioManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { am.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(focusListener)
        }
        focusRequest = null
    }

    private fun armAutoStop(timerMinutes: Int) {
        timeoutHandler.removeCallbacks(autoStopRunnable)
        if (timerMinutes > 0) {
            timeoutHandler.postDelayed(autoStopRunnable, timerMinutes * 60_000L)
        }
    }

    /** Tears everything down. [fromTimer] true means the wind-down timer elapsed,
     *  in which case we ALSO best-effort pause any OTHER app's media (the bonus:
     *  a "silence everything" wind-down). A manual/focus stop leaves other apps
     *  alone. */
    private fun stopEverything(fromTimer: Boolean) {
        timeoutHandler.removeCallbacks(autoStopRunnable)
        try {
            player?.let { if (it.isPlaying) it.stop() }
        } catch (_: Exception) {
        }
        player?.release()
        player = null

        if (fromTimer) pauseOtherMedia()
        abandonFocus()

        isRunning = false
        broadcastStopped()
        stopForegroundCompat()
        stopSelf()
    }

    /** Best-effort "pause everything else": dispatch a MEDIA_PAUSE key so any app
     *  holding an active media session (Spotify, YouTube Music, a podcast app…)
     *  pauses when the wind-down timer ends. Harmless no-op if the OS ignores it. */
    private fun pauseOtherMedia() {
        try {
            val am = audioManager ?: getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.dispatchMediaKeyEvent(
                KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PAUSE),
            )
            am.dispatchMediaKeyEvent(
                KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PAUSE),
            )
        } catch (e: Exception) {
            Log.d(TAG, "dispatch media pause failed (ignored)", e)
        }
    }

    private fun broadcastStopped() {
        sendBroadcast(Intent(ACTION_SLEEP_STOPPED).setPackage(packageName))
    }

    override fun onDestroy() {
        timeoutHandler.removeCallbacks(autoStopRunnable)
        try {
            player?.release()
        } catch (_: Exception) {
        }
        player = null
        abandonFocus()
        isRunning = false
        super.onDestroy()
    }

    // -----------------------------------------------------------------------
    // Foreground-service plumbing
    // -----------------------------------------------------------------------

    private fun startForegroundCompat(timerMinutes: Int) {
        ensureChannel()
        val notif = buildNotification(timerMinutes)
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
            "Sleep sounds",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps a sleep sound playing with the screen off."
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        mgr.createNotificationChannel(channel)
    }

    private fun buildNotification(timerMinutes: Int): Notification {
        val stopPi = PendingIntent.getService(
            this,
            0,
            Intent(this, SleepSoundService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        // Tapping the body opens the app.
        val openPi = PendingIntent.getActivity(
            this,
            1,
            packageManager.getLaunchIntentForPackage(packageName)
                ?: Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val subtitle = if (timerMinutes > 0) {
            "Playing · stops in ${timerMinutes}m"
        } else {
            "Playing"
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle(label)
            .setContentText(subtitle)
            .setSmallIcon(R.drawable.ic_stat_alarm)
            .setOngoing(true)
            .setContentIntent(openPi)
            .addAction(
                Notification.Action.Builder(null, "Stop", stopPi).build(),
            )
            .build()
    }
}
