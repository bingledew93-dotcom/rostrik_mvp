package com.example.rostrik_mvp

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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
        private const val METHOD_GET_PENDING_DISMISSALS = "getPendingDismissals"
        private const val METHOD_CLEAR_PENDING_DISMISSALS = "clearPendingDismissals"
        private const val METHOD_RELINQUISH_LOCK_SCREEN = "relinquishLockScreen"
        private const val METHOD_FINISH_WAKE_ACTIVITY = "finishWakeActivity"

        // Native dismiss fail-safe ledger — one shift id per line, written by
        // the background Dart engine's FIRST instruction on a killed-app
        // Dismiss (synchronous flushed write, survives the OS reaping the
        // engine before its Hive boot completes). Lives in `filesDir`, which
        // is exactly where path_provider maps Dart's
        // `getApplicationSupportDirectory()` on Android — the one directory
        // both sides reach with zero extra plumbing. Read + cleared HERE,
        // natively and synchronously, when Dart's boot gate asks. Name must
        // stay in lock-step with `pendingDismissalsFileName` in
        // `lib/alarms/pending_dismissal_guard.dart`.
        private const val PENDING_DISMISSALS_FILE = "pending_dismissals"

        // flutter_local_notifications stores the schedule's `payload`
        // string under this extra key in the PendingIntent it builds.
        private const val EXTRA_PAYLOAD = "payload"

        // startActivityForResult request code for the system ringtone picker.
        // FlutterActivity extends the FRAMEWORK android.app.Activity (NOT an
        // androidx ComponentActivity), so the modern ActivityResult API is
        // unavailable here — we use the classic request-code path, routed
        // through [onActivityResult].
        private const val RINGTONE_PICKER_REQUEST = 0x52494E47 // "RING"

        // RingtoneSource.index values — MUST match the Dart enum order in
        // `lib/data/models/ringtone_source.dart` (classic, vault, system).
        // Re-exported from the engine so the channel handler can default it.
        private const val SOURCE_CLASSIC = AlarmAudioEngine.SOURCE_CLASSIC
    }

    private var alarmChannel: MethodChannel? = null
    private var ringtoneChannel: MethodChannel? = null

    // -----------------------------------------------------------------------
    // ALARM AUDIO OWNERSHIP (Android-14 keyguard Silence-Bug fix):
    //   * FIRING ALARM playback lives in [AlarmAudioService], a foreground
    //     service. A process-scoped static player was NOT enough — it dies
    //     with the process, and the process is reaped when a show-when-locked
    //     activity is occluded by the shade on the lock screen. Only a
    //     foreground service pins the process. Alarm audio therefore stops
    //     ONLY via an explicit Dismiss/Snooze (`stopPreview` → stopService) or
    //     process death — NEVER a window/activity lifecycle event. DO NOT add
    //     onPause/onStop/onWindowFocusChanged audio handling.
    //   * EDITOR PREVIEW ("Play Now") stays in-activity via [previewEngine] —
    //     it is inherently foreground (the user is in the editor) and never
    //     reaches the lock screen, so it doesn't need the service and SHOULD
    //     die with the activity. Same [AlarmAudioEngine], same fallback ladder.
    // -----------------------------------------------------------------------
    private val previewEngine: AlarmAudioEngine by lazy {
        AlarmAudioEngine(applicationContext)
    }

    /** True while THIS activity holds the lock-screen lease for a live alarm
     *  (applied on an alarm launch, relinquished when the WakeUpScreen is
     *  gone). Used to scope [finishWakeActivityIfAlarmActive] to "an alarm
     *  wake screen is actually showing" — so a stray notification dismiss
     *  during normal app use can never finish the app. */
    private var lockScreenBypassActive = false

    /// In-flight `pickSystemRingtone` reply, held while the system picker
    /// Activity is up and completed from [onActivityResult]. Only one pick can
    /// be in flight at a time (re-entrant calls are rejected).
    private var pendingRingtoneResult: MethodChannel.Result? = null

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
                // Native dismiss fail-safe: hand Dart the killed-app
                // dismissals the background engine recorded before the OS
                // reaped it. Plain synchronous file reads — the ledger is a
                // handful of UUID lines at most.
                METHOD_GET_PENDING_DISMISSALS -> {
                    result.success(readPendingDismissals())
                }
                // Cleared only AFTER Dart confirms the Hive replay landed —
                // crash in between re-replays (idempotently) next boot.
                METHOD_CLEAR_PENDING_DISMISSALS -> {
                    clearPendingDismissals()
                    result.success(null)
                }
                // WakeUpScreen's dispose: the alarm is over, fully relinquish
                // the lock screen (showWhenLocked / turnScreenOn /
                // KEEP_SCREEN_ON). Without this a stranded instance in the
                // Recents task kept drawing over the keyguard after an
                // external dismissal. Re-armed by [applyLockScreenBypass] on
                // the next alarm launch.
                METHOD_RELINQUISH_LOCK_SCREEN -> {
                    relinquishLockScreenBypass()
                    result.success(null)
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
                    val uri = call.argument<String>("uri")
                    val vibrate = call.argument<Boolean>("vibrate") ?: false
                    // A PRESET internal tone arrives as a res/raw name; null for
                    // a custom vault/system tone.
                    val bundledResource = call.argument<String>("bundledResource")
                    // `asAlarm` routes the playback: a FIRING ALARM (preset OR
                    // custom) goes to the foreground service (survives the
                    // keyguard/activity teardown); an editor preview plays
                    // in-activity.
                    val asAlarm = call.argument<Boolean>("asAlarm") ?: false
                    if (asAlarm) {
                        startAlarmAudioService(source, uri, vibrate, bundledResource)
                    } else {
                        previewEngine.play(source, uri, vibrate, bundledResource)
                    }
                    result.success(null)
                }
                "stopPreview" -> {
                    // Dismiss/Snooze (or any teardown) stops BOTH possible
                    // sources: the in-activity preview AND the alarm service.
                    // stopService is safe from any state and a no-op if the
                    // service isn't running — no background-start restriction.
                    previewEngine.stop()
                    stopService(Intent(this, AlarmAudioService::class.java))
                    result.success(null)
                }
                // Regression 2 — the foreground dispatcher's EXTERNAL dismiss
                // (a Dismiss tapped in the notification shade) calls this so the
                // stranded WakeUpScreen, occluded by the shade and never hitting
                // resumed, is torn down NATIVELY — no dependence on the Dart
                // ticker or a manual shade swipe. No-op unless an alarm wake
                // screen is actually showing (guarded by the lock-screen lease).
                METHOD_FINISH_WAKE_ACTIVITY -> {
                    finishWakeActivityIfAlarmActive()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // COLD-LAUNCH: buffer only. We deliberately do NOT call
        // invokeMethod here — Dart `main()` hasn't run yet, so the
        // channel handler isn't attached on the Dart side and the call
        // would be silently dropped. Dart will pull via
        // [METHOD_GET_INITIAL_PAYLOAD] once it's ready.
        //
        // ZOMBIE-UI GUARD: when the task is relaunched from recents, Android
        // REDELIVERS the original FullScreenIntent — payload extra and all —
        // hours after the alarm fired and was dismissed from the shade. A
        // history-redelivered payload must never be buffered as a live alarm
        // (Dart additionally verifies against Hive, but the stale extra is
        // best refused at the source).
        val payload = intent.getStringExtra(EXTRA_PAYLOAD)
        val fromHistory =
            (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
        if (payload != null && fromHistory) {
            Log.d(
                TAG,
                "onCreate: '$EXTRA_PAYLOAD' present but the intent was " +
                    "redelivered from recents history — ignoring stale alarm payload",
            )
        } else if (payload != null) {
            // Live alarm cold-launch: take the lock-screen lease (render over
            // the keyguard + wake the screen) — ONLY here, not for an ordinary
            // launcher start, so `lockScreenBypassActive` precisely tracks "an
            // alarm wake screen is up." We deliberately do NOT
            // `requestDismissKeyguard` — that would pop a biometric/PIN prompt
            // over the FSI. The public-visibility notification's action buttons
            // cover the no-auth dismiss/snooze paths.
            applyLockScreenBypass()
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
        //
        // Same recents-history guard as onCreate: a warm relaunch from the
        // task switcher can also redeliver the original alarm intent.
        if ((intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0) {
            Log.d(TAG, "onNewIntent: intent from recents history — ignoring payload")
            return
        }
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
        // RE-ARM the lock-screen bypass for this fresh alarm. A previous
        // WakeUpScreen teardown relinquished the flags on this same Activity
        // instance — without re-applying, the SECOND alarm's wake screen
        // would render behind the keyguard instead of over it.
        applyLockScreenBypass()
        val channel = alarmChannel
        if (channel != null) {
            channel.invokeMethod(METHOD_ALARM_FIRED, payload)
        } else {
            pendingPayload = payload
        }
    }

    // ---------------------------------------------------------------------
    // Lock-screen bypass lifecycle (Zombie-UI, final piece). The bypass is a
    // PER-ALARM lease, not a permanent Activity property: applied on every
    // alarm launch (onCreate + the onNewIntent warm path above), and fully
    // relinquished when Dart reports the WakeUpScreen is gone — so a
    // stranded task in Recents can never keep drawing over the keyguard.
    // ---------------------------------------------------------------------

    /** Grants the wake screen its lock-screen lease: render over the
     *  keyguard and wake the display. Runtime calls mirror the manifest's
     *  `showWhenLocked` / `turnScreenOn` for pre-O_MR1 API paths. */
    private fun applyLockScreenBypass() {
        lockScreenBypassActive = true
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
    }

    /** Revokes the lease: clears showWhenLocked / turnScreenOn (modern API
     *  setters AND the legacy window flags) plus FLAG_KEEP_SCREEN_ON, so the
     *  app completely relinquishes the lock screen the moment the wake
     *  screen is disposed. */
    private fun relinquishLockScreenBypass() {
        lockScreenBypassActive = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(false)
            setTurnScreenOn(false)
        } else {
            @Suppress("DEPRECATION")
            window.clearFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        Log.d(TAG, "lock-screen bypass relinquished")
    }

    /** Regression 2 — native teardown of a WakeUpScreen stranded over the lock
     *  screen after an EXTERNAL (notification-shade) dismiss. While occluded by
     *  the shade the activity never hits Dart's `resumed` hook, so the ledger
     *  poll/self-destruct can lag until a manual swipe. The foreground
     *  dispatcher's dismiss calls this the instant it handles the action: stop
     *  the alarm service, drop the lock-screen lease, and finish the task so
     *  the keyguard is revealed immediately. Guarded by [lockScreenBypassActive]
     *  so it can ONLY fire while an alarm wake screen is up — a stray dismiss
     *  during normal app use is a no-op. */
    private fun finishWakeActivityIfAlarmActive() {
        if (!lockScreenBypassActive) {
            Log.d(TAG, "finishWakeActivity: no alarm wake screen active — ignoring")
            return
        }
        Log.d(TAG, "finishWakeActivity: tearing down stranded wake screen")
        stopService(Intent(this, AlarmAudioService::class.java))
        relinquishLockScreenBypass()
        finishAndRemoveTask()
    }

    override fun onDestroy() {
        // Stop the EDITOR PREVIEW — it must die with the activity. A FIRING
        // ALARM is NOT touched here: it lives in [AlarmAudioService] (a
        // foreground service), so the keyguard occluding/destroying this
        // activity can no longer silence it. The alarm ends only on an
        // explicit Dismiss/Snooze (`stopPreview` → stopService) or process
        // death. (THIS is the Silence-Bug fix — do not reintroduce any alarm
        // audio teardown on a lifecycle callback.)
        previewEngine.stop()
        super.onDestroy()
    }

    // ---------------------------------------------------------------------
    // Native dismiss fail-safe ledger (Zombie-UI hardening, round 2).
    // The killed-app Dismiss writes `filesDir/pending_dismissals` from the
    // background Dart engine's first instruction; these synchronous helpers
    // are the OTHER half of the contract — Dart's boot gate reads and clears
    // through the alarm-routing channel before trusting Hive.
    // ---------------------------------------------------------------------

    /** Reads the ledger: trimmed, blanks dropped, de-duplicated (a rapid
     *  double-tap appends twice; the Hive replay must ack once). Any failure
     *  reads as "nothing pending" — a corrupt ledger must never block boot. */
    private fun readPendingDismissals(): List<String> {
        return try {
            val file = File(filesDir, PENDING_DISMISSALS_FILE)
            if (!file.exists()) {
                emptyList()
            } else {
                file.readLines()
                    .map { it.trim() }
                    .filter { it.isNotEmpty() }
                    .distinct()
            }
        } catch (e: Exception) {
            Log.w(TAG, "pending-dismissals read failed", e)
            emptyList()
        }
    }

    /** Deletes the ledger. Best-effort: a failed delete just means the next
     *  boot replays the same ids into Hive again, which is idempotent. */
    private fun clearPendingDismissals() {
        try {
            File(filesDir, PENDING_DISMISSALS_FILE).delete()
        } catch (e: Exception) {
            Log.w(TAG, "pending-dismissals clear failed", e)
        }
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
    // Fire-time alarm audio — delegated to the foreground [AlarmAudioService]
    // so it survives the lock-screen activity teardown (the Silence Bug). The
    // resolve-and-fallback engine itself lives in [AlarmAudioEngine], shared
    // verbatim with the in-activity editor preview.
    // ---------------------------------------------------------------------

    /** Starts (or restarts) fire-time alarm playback in the foreground service.
     *  Launched while THIS activity is foreground (the FSI just brought it up),
     *  so the Android-12+ background-foreground-service-launch restriction is
     *  satisfied. `startForegroundService` on O+; the service calls
     *  `startForeground` immediately in `onStartCommand`. */
    private fun startAlarmAudioService(
        source: Int,
        uri: String?,
        vibrate: Boolean,
        bundledResource: String?,
    ) {
        val intent = Intent(this, AlarmAudioService::class.java).apply {
            action = AlarmAudioService.ACTION_PLAY
            putExtra(AlarmAudioService.EXTRA_SOURCE, source)
            putExtra(AlarmAudioService.EXTRA_URI, uri)
            putExtra(AlarmAudioService.EXTRA_VIBRATE, vibrate)
            putExtra(AlarmAudioService.EXTRA_BUNDLED_RESOURCE, bundledResource)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
