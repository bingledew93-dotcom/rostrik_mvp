package com.example.rostrik_mvp

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Lock-screen bypass + alarm routing for FullScreenIntent.
 *
 * Two responsibilities:
 *   1. Lock-screen bypass — also declared in AndroidManifest.xml via
 *      `showWhenLocked` / `turnScreenOn`, with matching runtime calls
 *      in `onCreate` for older API paths. The Activity renders on top
 *      of the lock screen but does NOT force the keyguard to dismiss
 *      itself — that would pop a biometric/PIN prompt over the FSI
 *      UI. Users can authenticate themselves if they want to interact
 *      with WakeUpScreen; the public-visibility notification's action
 *      buttons cover the no-auth dismiss/snooze paths.
 *   2. Cross-isolate alarm routing — two paths:
 *      a) COLD LAUNCH via FullScreenIntent. Android constructs the
 *         activity from a stopped state. By the time `onCreate` runs,
 *         the Dart engine is not yet ready to receive MethodChannel
 *         calls (Dart `main()` hasn't even begun). Pushing into the
 *         channel here is lost. Instead we buffer the payload and
 *         expose a `getInitialAlarmPayload` method that Dart calls
 *         when it is ready — the canonical "pull on attach" pattern.
 *      b) WARM LAUNCH while the app is already alive. The OS routes
 *         the new alarm intent through `onNewIntent`. Dart's
 *         `alarmFired` handler is already attached, so we push
 *         directly.
 *
 * Earlier attempts at native-side FSI/body-tap discrimination via
 * `KeyguardManager.isKeyguardLocked` failed on fast-unlock devices
 * (Pixel 9 reports unlocked DURING the FSI launch). Earlier attempts
 * at push-on-attach via `configureFlutterEngine.invokeMethod` raced
 * Dart `main()` and lost the payload. The pull pattern below avoids
 * both failure modes by making Dart the initiator.
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "Rostrik"
        private const val CHANNEL = "rostrik/alarm_routing"

        // Phase 2a custom-audio channel. Wire name must match
        // `lib/alarms/ringtone_channel.dart`'s `RingtoneChannel.channelName`.
        private const val RINGTONE_CHANNEL = "rostrik/ringtone_picker"

        // Dart-side methods exchanged on this channel. Keep these strings
        // in sync with `main.dart`; the names are part of the wire
        // contract between Kotlin and Dart.
        private const val METHOD_GET_INITIAL_PAYLOAD = "getInitialAlarmPayload"
        private const val METHOD_ALARM_FIRED = "alarmFired"

        // flutter_local_notifications stores the schedule's `payload`
        // string under this extra key in the PendingIntent it builds.
        private const val EXTRA_PAYLOAD = "payload"

        // RingtoneSource.index values — MUST match the Dart enum order in
        // `lib/data/models/alarm_settings.dart` (classic, vault, system).
        private const val SOURCE_CLASSIC = 0
        private const val SOURCE_VAULT = 1
        private const val SOURCE_SYSTEM = 2

        // startActivityForResult request code for the system ringtone picker.
        // FlutterActivity extends the FRAMEWORK android.app.Activity (NOT an
        // androidx ComponentActivity), so the modern ActivityResult API is
        // unavailable here — we use the classic request-code path, routed
        // through [onActivityResult].
        private const val RINGTONE_PICKER_REQUEST = 0x52494E47 // "RING"
    }

    private var alarmChannel: MethodChannel? = null
    private var ringtoneChannel: MethodChannel? = null

    /// In-flight `pickSystemRingtone` reply, held while the system picker
    /// Activity is up and completed from [onActivityResult]. Only one pick can
    /// be in flight at a time (re-entrant calls are rejected).
    private var pendingRingtoneResult: MethodChannel.Result? = null

    /// Preview player for the Phase-2a "Play Now" harness. A plain looping
    /// [MediaPlayer] (no foreground service — preview is foreground, on-demand)
    /// that runs the same resolve-and-fallback logic the fire-time engine will.
    private var previewPlayer: MediaPlayer? = null

    /// Active haptic vibrator while a custom tone is playing WITH vibration on.
    /// Held so it survives an audio fallback (releasing the player must NOT stop
    /// the buzz) and is cancelled by [stopPreviewPlayer] / onDestroy.
    private var vibrator: Vibrator? = null

    /// Payload captured by [onCreate] before the Dart side could ask
    /// for it. Cleared atomically the first time
    /// `getInitialAlarmPayload` is invoked from Dart — Dart pulls
    /// exactly once on boot, and any subsequent firings come through
    /// [onNewIntent] while the channel is live.
    private var pendingPayload: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        alarmChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        )
        // Dart pulls the initial payload here. Returning the buffered
        // value AND clearing it in the same call ensures the buffer is
        // never double-consumed, even if Dart somehow asks twice.
        alarmChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_GET_INITIAL_PAYLOAD -> {
                    val payload = pendingPayload
                    pendingPayload = null
                    Log.d(TAG, "$METHOD_GET_INITIAL_PAYLOAD → ${payload ?: "<null>"}")
                    result.success(payload)
                }
                else -> result.notImplemented()
            }
        }

        // Phase 2a custom-audio channel: system-tone picker + native preview
        // harness (the engine that Phase 2b promotes into the foreground
        // service). Separate channel so the alarm-routing contract above is
        // untouched.
        ringtoneChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RINGTONE_CHANNEL,
        )
        ringtoneChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickSystemRingtone" -> {
                    launchRingtonePicker(call.argument<String>("currentUri"), result)
                }
                "previewRingtone" -> {
                    val source = call.argument<Int>("source") ?: SOURCE_CLASSIC
                    val vibrate = call.argument<Boolean>("vibrate") ?: false
                    previewRingtone(source, call.argument<String>("uri"), vibrate)
                    result.success(null)
                }
                "stopPreview" -> {
                    stopPreviewPlayer()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Lock-screen bypass for the Activity ONLY — we want the
        // WakeUpScreen to render on top of the keyguard, but we
        // deliberately do NOT call `requestDismissKeyguard` here.
        // Forcing the keyguard to dismiss would pop a biometric/PIN
        // prompt over the FSI Activity, which is the exact UX
        // regression we are fixing. The user can authenticate
        // themselves if they want to interact with WakeUpScreen
        // (slide-to-dismiss); otherwise the action buttons on the
        // public-visibility notification still work from the lock
        // screen, no auth required.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        // COLD-LAUNCH: buffer only. We deliberately do NOT call
        // invokeMethod here — Dart `main()` hasn't run yet, so the
        // channel handler isn't attached on the Dart side and the call
        // would be silently dropped. Dart will pull via
        // [METHOD_GET_INITIAL_PAYLOAD] once it's ready.
        val payload = intent.getStringExtra(EXTRA_PAYLOAD)
        if (payload != null) {
            Log.d(TAG, "onCreate buffering alarm payload for pull: $payload")
            pendingPayload = payload
        } else {
            Log.d(
                TAG,
                "onCreate had no '$EXTRA_PAYLOAD' extra. Keys present: " +
                    "${intent.extras?.keySet()?.joinToString()}",
            )
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Replace the activity's stored intent so any later getIntent()
        // reads the new launch, not the original one.
        setIntent(intent)

        // WARM-LAUNCH: Dart is already alive with its `alarmFired`
        // handler attached, so push directly. The buffering fallback is
        // a defensive belt for the unlikely path where onNewIntent fires
        // before configureFlutterEngine has set up the channel (e.g. a
        // re-entrant launch during engine teardown).
        val payload = intent.getStringExtra(EXTRA_PAYLOAD)
        if (payload == null) {
            Log.d(
                TAG,
                "onNewIntent had no '$EXTRA_PAYLOAD' extra. Keys present: " +
                    "${intent.extras?.keySet()?.joinToString()}",
            )
            return
        }
        Log.d(TAG, "onNewIntent pushing alarm payload: $payload")
        val channel = alarmChannel
        if (channel != null) {
            channel.invokeMethod(METHOD_ALARM_FIRED, payload)
        } else {
            pendingPayload = payload
        }
    }

    override fun onDestroy() {
        // Never let a preview tone outlive the editor screen.
        stopPreviewPlayer()
        super.onDestroy()
    }

    // ---------------------------------------------------------------------
    // Phase 2a — system ringtone picker
    // ---------------------------------------------------------------------

    /** Launches the system alarm-tone picker; the reply is delivered async via
     *  [onActivityResult]. Rejects re-entrant calls so a second pick can't
     *  strand the first [MethodChannel.Result]. */
    private fun launchRingtonePicker(currentUri: String?, result: MethodChannel.Result) {
        if (pendingRingtoneResult != null) {
            result.error("ALREADY_ACTIVE", "Ringtone picker already open", null)
            return
        }
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Select alarm tone")
            if (!currentUri.isNullOrEmpty()) {
                putExtra(
                    RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                    Uri.parse(currentUri),
                )
            }
        }
        pendingRingtoneResult = result
        try {
            @Suppress("DEPRECATION")
            startActivityForResult(intent, RINGTONE_PICKER_REQUEST)
        } catch (e: Exception) {
            // No picker activity on this device/ROM — fail the call cleanly.
            pendingRingtoneResult = null
            Log.w(TAG, "ringtone picker launch failed", e)
            result.error("LAUNCH_FAILED", e.message, null)
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        // Let FlutterActivity forward to any plugins first (none use our code).
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != RINGTONE_PICKER_REQUEST) return

        val pending = pendingRingtoneResult
        pendingRingtoneResult = null
        if (pending == null) return

        if (resultCode != Activity.RESULT_OK) {
            pending.success(null) // user cancelled
            return
        }
        val uri = extractPickedRingtoneUri(data)
        if (uri == null) {
            pending.success(null) // "Silent" / no selection
            return
        }
        val title = try {
            RingtoneManager.getRingtone(applicationContext, uri)
                ?.getTitle(applicationContext)
        } catch (e: Exception) {
            Log.w(TAG, "ringtone title lookup failed", e)
            null
        } ?: "System tone"
        pending.success(mapOf("uri" to uri.toString(), "title" to title))
    }

    /** Reads the picked tone URI out of the picker result, across API levels. */
    private fun extractPickedRingtoneUri(data: Intent?): Uri? {
        if (data == null) return null
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            data.getParcelableExtra(
                RingtoneManager.EXTRA_RINGTONE_PICKED_URI,
                Uri::class.java,
            )
        } else {
            @Suppress("DEPRECATION")
            data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        }
    }

    // ---------------------------------------------------------------------
    // Phase 2a — native preview engine (the Phase-2b fire-time player, run
    // on-demand). Resolve the chosen source, and on ANY failure fall through
    // to the bundled classic tone so a preview is never silent.
    // ---------------------------------------------------------------------

    private fun previewRingtone(sourceIndex: Int, uri: String?, vibrate: Boolean) {
        stopPreviewPlayer()
        // Start the haptic loop BEFORE audio so it accompanies whatever rings —
        // including the classic/RingtoneManager fallbacks below (which release
        // the player but deliberately do NOT cancel vibration).
        if (vibrate) startVibration()
        val player = MediaPlayer()
        previewPlayer = player
        try {
            configureAlarmPlayer(player)
            // Mid-stream failures (media-server death, codec stall) surface here,
            // not at prepare() — fall back rather than dying silently.
            player.setOnErrorListener { _, what, extra ->
                Log.w(TAG, "preview MediaPlayer error what=$what extra=$extra → classic")
                fallbackToClassic()
                true
            }
            when (sourceIndex) {
                SOURCE_VAULT ->
                    player.setDataSource(
                        requireNotNull(uri) { "vault source needs a path" },
                    )
                SOURCE_SYSTEM ->
                    player.setDataSource(
                        applicationContext,
                        Uri.parse(requireNotNull(uri) { "system source needs a uri" }),
                    )
                else -> setClassicDataSource(player) // SOURCE_CLASSIC
            }
            // SYNCHRONOUS prepare: a bad path / revoked content:// throws HERE,
            // before start(), so the catch can fall back with no audible gap.
            player.prepare()
            player.start()
        } catch (e: Exception) {
            Log.w(TAG, "preview resolve failed (${e.message}) → classic fallback", e)
            fallbackToClassic()
        }
    }

    /** Last-resort audio: the bundled `classic_alarm`, then the device's default
     *  alarm ringtone. The user is never left in silence. Releases the failed
     *  player but NOT the vibrator — a swap of audio source must keep any active
     *  haptic loop running. */
    private fun fallbackToClassic() {
        releasePlayer()
        val player = MediaPlayer()
        previewPlayer = player
        try {
            configureAlarmPlayer(player)
            setClassicDataSource(player)
            player.prepare()
            player.start()
        } catch (e: Exception) {
            Log.e(TAG, "classic fallback failed → system default alarm tone", e)
            previewPlayer = null
            try {
                RingtoneManager.getRingtone(
                    applicationContext,
                    RingtoneManager.getActualDefaultRingtoneUri(
                        applicationContext,
                        RingtoneManager.TYPE_ALARM,
                    ),
                )?.play()
            } catch (e2: Exception) {
                Log.e(TAG, "even the default alarm ringtone failed", e2)
            }
        }
    }

    private fun configureAlarmPlayer(player: MediaPlayer) {
        player.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build(),
        )
        player.isLooping = true
    }

    /** Points [player] at `res/raw/classic_alarm`. The AssetFileDescriptor is
     *  closed right after setDataSource (MediaPlayer dups the fd), before the
     *  caller's prepare(). */
    private fun setClassicDataSource(player: MediaPlayer) {
        val afd = resources.openRawResourceFd(R.raw.classic_alarm)
        try {
            player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
        } finally {
            afd.close()
        }
    }

    /** Full stop: release the audio player AND cancel any haptic loop. Used by
     *  the channel `stopPreview`, onDestroy, and the start of a new play. */
    private fun stopPreviewPlayer() {
        releasePlayer()
        stopVibration()
    }

    /** Stops + releases the [MediaPlayer] only, leaving the vibrator untouched
     *  (so an audio fallback can swap players without dropping the buzz). */
    private fun releasePlayer() {
        val player = previewPlayer ?: return
        previewPlayer = null
        try {
            if (player.isPlaying) player.stop()
        } catch (e: IllegalStateException) {
            // already stopped/uninitialised — fine.
        }
        try {
            player.release()
        } catch (e: Exception) {
            Log.w(TAG, "preview player release failed", e)
        }
    }

    /** Starts a continuous, aggressive looping vibration (buzz 1s / pause 1s,
     *  repeating). Resolves the [Vibrator] across API levels. Best-effort — a
     *  device without a vibrator, or a failure, must never break the alarm. */
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
            val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                as? VibratorManager
            vm?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }
}
