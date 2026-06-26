package com.example.rostrik_mvp

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Host activity for the Flutter app.
 *
 * After the move to a fully native alarm path (AlarmManager → [AlarmReceiver] →
 * [AlarmAudioService] + the native [AlarmActivity]), MainActivity is NO LONGER
 * an alarm surface — a firing alarm never routes through it. It now owns only
 * three small platform bridges:
 *   * `rostrik/alarm_routing` — drains the native `pending_dismissals` ledger
 *     into Hive on boot (`getPendingDismissals` / `clearPendingDismissals`).
 *   * `rostrik/ringtone_picker` — the alarm create/edit sheet's system-tone
 *     picker + in-activity tone preview (NOT fire-time audio).
 *   * `rostrik/native_alarms` — exact-alarm scheduling, via the shared
 *     [NativeAlarmScheduling] helper (also registered in the bg engine).
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "Rostrik"
        private const val CHANNEL = "rostrik/alarm_routing"

        // Phase 2a custom-audio channel. Wire name must match
        // `lib/alarms/ringtone_channel.dart`'s `RingtoneChannel.channelName`.
        private const val RINGTONE_CHANNEL = "rostrik/ringtone_picker"

        // Native dismiss fail-safe ledger methods (Dart's boot gate reads, then
        // clears). Strings are part of the wire contract with `main.dart`.
        private const val METHOD_GET_PENDING_DISMISSALS = "getPendingDismissals"
        private const val METHOD_CLEAR_PENDING_DISMISSALS = "clearPendingDismissals"

        // The native dismiss fail-safe ledger — one shift id per line, written by
        // [AlarmActivity] on dismiss (synchronous flushed write, survives the OS
        // reaping the process). Lives in `filesDir`, where path_provider maps
        // Dart's `getApplicationSupportDirectory()` on Android. Name must stay in
        // lock-step with `pendingDismissalsFileName` in pending_dismissal_guard.dart.
        private const val PENDING_DISMISSALS_FILE = "pending_dismissals"

        // startActivityForResult request code for the system ringtone picker.
        // FlutterActivity extends the FRAMEWORK android.app.Activity (NOT an
        // androidx ComponentActivity), so the modern ActivityResult API is
        // unavailable here — we use the classic request-code path.
        private const val RINGTONE_PICKER_REQUEST = 0x52494E47 // "RING"

        // RingtoneSource.index default — matches the Dart enum order
        // (classic, vault, system).
        private const val SOURCE_CLASSIC = AlarmAudioEngine.SOURCE_CLASSIC
    }

    private var alarmChannel: MethodChannel? = null
    private var ringtoneChannel: MethodChannel? = null
    private var nativeAlarmsChannel: MethodChannel? = null

    /// EDITOR PREVIEW ("Play Now") engine — in-activity tone preview for the
    /// create/edit sheet. Dies with the activity (it never reaches a lock
    /// screen). Fire-time alarm audio is owned by [AlarmAudioService], not this.
    private val previewEngine: AlarmAudioEngine by lazy {
        AlarmAudioEngine(applicationContext)
    }

    /// In-flight `pickSystemRingtone` reply, held while the system picker is up
    /// and completed from [onActivityResult]. One pick can be in flight at a time.
    private var pendingRingtoneResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Native dismiss fail-safe drain: hand Dart the killed-app dismissals
        // AlarmActivity recorded, then clear once Dart confirms the Hive replay.
        alarmChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        )
        alarmChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_GET_PENDING_DISMISSALS -> {
                    result.success(readPendingDismissals())
                }
                METHOD_CLEAR_PENDING_DISMISSALS -> {
                    clearPendingDismissals()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Phase 2a custom-audio channel: system-tone picker + in-activity preview.
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
                    // `asAlarm` true routes a FIRING ALARM preview to the
                    // foreground service; the editor's "Play Now" plays in-activity.
                    val asAlarm = call.argument<Boolean>("asAlarm") ?: false
                    if (asAlarm) {
                        startAlarmAudioService(source, uri, vibrate, bundledResource)
                    } else {
                        previewEngine.play(source, uri, vibrate, bundledResource)
                    }
                    result.success(null)
                }
                "stopPreview" -> {
                    // Stop BOTH possible sources: the in-activity preview AND the
                    // alarm service. stopService is safe from any state.
                    previewEngine.stop()
                    stopService(Intent(this, AlarmAudioService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Native exact-alarm scheduling — the flutter_local_notifications
        // replacement. Registered via the SHARED [NativeAlarmScheduling] helper
        // so the SAME handler is also available in the headless background
        // engine ([AlarmSyncWorker]) the boot re-sync spins up.
        nativeAlarmsChannel = NativeAlarmScheduling.register(
            flutterEngine.dartExecutor.binaryMessenger,
            applicationContext,
        )
    }

    override fun onDestroy() {
        // Stop the EDITOR PREVIEW — it must die with the activity. A FIRING ALARM
        // is owned by [AlarmAudioService] (a foreground service), never touched here.
        previewEngine.stop()
        super.onDestroy()
    }

    // ---------------------------------------------------------------------
    // Native dismiss fail-safe ledger. [AlarmActivity] writes
    // `filesDir/pending_dismissals` on dismiss; Dart's boot gate reads and
    // clears it through the alarm-routing channel before trusting Hive.
    // ---------------------------------------------------------------------

    /** Reads the ledger: trimmed, blanks dropped, de-duplicated. Any failure
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

    /** Deletes the ledger. Best-effort: a failed delete just means the next boot
     *  replays the same ids into Hive again, which is idempotent. */
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
     *  Used by the create/edit sheet's `asAlarm` preview path. */
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
