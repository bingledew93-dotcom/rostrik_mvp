package com.example.rostrik_mvp

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

/**
 * Self-contained alarm/preview playback engine.
 *
 * Resolves the chosen audio source and, on ANY failure, falls through to the
 * bundled `classic_alarm` and finally the device's default alarm tone — the
 * user is never left in silence. Extracted from MainActivity so the EXACT same
 * fallback ladder backs both:
 *   * the editor's "Play Now" preview (in [MainActivity], dies with the
 *     activity — a preview is inherently foreground), and
 *   * fire-time alarm playback (in [AlarmAudioService], which wraps an instance
 *     of this engine in a foreground service so the OS keeps the PROCESS alive
 *     across the keyguard/activity transition that was silencing the alarm).
 *
 * Context-based (no Activity dependency) so the service can own one. Holds a
 * partial wake-lock on the player ([PowerManager.PARTIAL_WAKE_LOCK]) so the CPU
 * keeps feeding the audio buffer while the screen is off — belt-and-braces
 * alongside the foreground-service process pin.
 */
class AlarmAudioEngine(private val context: Context) {
    companion object {
        private const val TAG = "Rostrik"

        // RingtoneSource.index values — MUST match the Dart enum order in
        // `lib/data/models/ringtone_source.dart` (classic, vault, system).
        const val SOURCE_CLASSIC = 0
        const val SOURCE_VAULT = 1
        const val SOURCE_SYSTEM = 2
    }

    private var player: MediaPlayer? = null

    /** Active haptic vibrator while a tone plays WITH vibration. Held so it
     *  survives an audio fallback (releasing the player must NOT stop the
     *  buzz); cancelled by [stop]. */
    private var vibrator: Vibrator? = null

    /** Resolve the audio source and start looping playback, with the fallback
     *  ladder on any failure. Stops whatever is currently playing first, so
     *  re-calling is a clean restart.
     *
     *  [bundledResource] (a `res/raw` name like `siren`) takes precedence — it
     *  is how a PRESET internal tone reaches the foreground service (every
     *  fire-time alarm now plays here, not via FLAG_INSISTENT). When null, the
     *  [sourceIndex]/[uri] path handles custom vault/system tones. */
    fun play(
        sourceIndex: Int,
        uri: String?,
        vibrate: Boolean,
        bundledResource: String? = null,
    ) {
        stop()
        // Start the haptic loop BEFORE audio so it accompanies whatever rings —
        // including the classic/RingtoneManager fallbacks below (which release
        // the player but deliberately do NOT cancel vibration).
        if (vibrate) startVibration()
        val p = MediaPlayer()
        player = p
        try {
            configureAlarmPlayer(p)
            // Mid-stream failures (media-server death, codec stall) surface
            // here, not at prepare() — fall back rather than dying silently.
            p.setOnErrorListener { _, what, extra ->
                Log.w(TAG, "alarm MediaPlayer error what=$what extra=$extra → classic")
                fallbackToClassic()
                true
            }
            when {
                bundledResource != null -> setBundledDataSource(p, bundledResource)
                sourceIndex == SOURCE_VAULT ->
                    p.setDataSource(
                        requireNotNull(uri) { "vault source needs a path" },
                    )
                sourceIndex == SOURCE_SYSTEM ->
                    p.setDataSource(
                        context.applicationContext,
                        Uri.parse(requireNotNull(uri) { "system source needs a uri" }),
                    )
                else -> setClassicDataSource(p) // SOURCE_CLASSIC
            }
            // SYNCHRONOUS prepare: a bad path / revoked content:// throws HERE,
            // before start(), so the catch can fall back with no audible gap.
            p.prepare()
            p.start()
        } catch (e: Exception) {
            Log.w(TAG, "alarm resolve failed (${e.message}) → classic fallback", e)
            fallbackToClassic()
        }
    }

    /** Full stop: release the player AND cancel the haptic loop. The ONLY way
     *  a firing alarm ends (driven from Dart's Dismiss/Snooze via the service)
     *  — never a lifecycle event. */
    fun stop() {
        releasePlayer()
        stopVibration()
    }

    /** Last-resort audio: bundled `classic_alarm`, then the device default
     *  alarm tone. Releases the failed player but NOT the vibrator — an audio
     *  source swap must keep any active haptic loop running. */
    private fun fallbackToClassic() {
        releasePlayer()
        val p = MediaPlayer()
        player = p
        try {
            configureAlarmPlayer(p)
            setClassicDataSource(p)
            p.prepare()
            p.start()
        } catch (e: Exception) {
            Log.e(TAG, "classic fallback failed → system default alarm tone", e)
            player = null
            try {
                RingtoneManager.getRingtone(
                    context.applicationContext,
                    RingtoneManager.getActualDefaultRingtoneUri(
                        context.applicationContext,
                        RingtoneManager.TYPE_ALARM,
                    ),
                )?.play()
            } catch (e2: Exception) {
                Log.e(TAG, "even the default alarm ringtone failed", e2)
            }
        }
    }

    private fun configureAlarmPlayer(p: MediaPlayer) {
        p.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build(),
        )
        p.isLooping = true
        // Keep the CPU feeding the audio buffer while the screen is off.
        // WAKE_LOCK is declared in the manifest; released on player.release().
        p.setWakeMode(context.applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
    }

    /** Points [p] at `res/raw/classic_alarm`. The AssetFileDescriptor is
     *  closed right after setDataSource (MediaPlayer dups the fd). */
    private fun setClassicDataSource(p: MediaPlayer) {
        val afd = context.resources.openRawResourceFd(R.raw.classic_alarm)
        try {
            p.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
        } finally {
            afd.close()
        }
    }

    /** Points [p] at `res/raw/<resourceName>` — the preset tone's bundled WAV
     *  (resolved by name so the native side needs no hard-coded tone catalog,
     *  it just mirrors `AlarmSound.androidResource`). An unknown name resolves
     *  to id 0 and degrades to the classic tone rather than throwing. */
    private fun setBundledDataSource(p: MediaPlayer, resourceName: String) {
        val resId = context.resources.getIdentifier(
            resourceName,
            "raw",
            context.packageName,
        )
        if (resId == 0) {
            Log.w(TAG, "unknown bundled resource '$resourceName' → classic")
            setClassicDataSource(p)
            return
        }
        val afd = context.resources.openRawResourceFd(resId)
        try {
            p.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
        } finally {
            afd.close()
        }
    }

    private fun releasePlayer() {
        val p = player ?: return
        player = null
        try {
            if (p.isPlaying) p.stop()
        } catch (e: IllegalStateException) {
            // already stopped/uninitialised — fine.
        }
        try {
            p.release()
        } catch (e: Exception) {
            Log.w(TAG, "player release failed", e)
        }
    }

    /** Continuous, aggressive looping vibration (buzz 1s / pause 1s).
     *  Best-effort — a device without a vibrator must never break the alarm. */
    private fun startVibration() {
        stopVibration()
        val v = resolveVibrator() ?: return
        if (!v.hasVibrator()) return
        vibrator = v
        val pattern = longArrayOf(0, 1000, 1000) // delay, on, off — index 0 loops
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                v.vibrate(pattern, 0)
            }
        } catch (e: Exception) {
            Log.w(TAG, "startVibration failed", e)
        }
    }

    private fun stopVibration() {
        val v = vibrator ?: return
        vibrator = null
        try {
            v.cancel()
        } catch (e: Exception) {
            Log.w(TAG, "vibrator cancel failed", e)
        }
    }

    private fun resolveVibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                as? VibratorManager
            vm?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }
}
