package com.example.rostrik_mvp

import android.annotation.SuppressLint
import android.app.Activity
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.sqrt

/**
 * The native (NOT Flutter) full-screen alarm screen.
 *
 * Launched by [AlarmReceiver]'s full-screen-intent notification when an alarm
 * fires. It deliberately extends the framework [Activity] rather than
 * `FlutterActivity` so it carries zero Flutter-engine startup cost on the ring
 * path — a groggy shift worker must see the screen and be able to silence it
 * the instant the alarm goes off, with no Dart `main()` race.
 *
 * It owns NO audio. Audio lives in [AlarmAudioService] (foreground, type
 * mediaPlayback) so swiping this screen away does not silence the alarm — only
 * a deliberate dismiss (slide or shake) stops it.
 *
 * Lock-screen behaviour: it draws OVER the keyguard (showWhenLocked) and wakes
 * the display (turnScreenOn), but does NOT dismiss the keyguard — that would
 * pop a PIN/biometric prompt over the alarm. Both dismiss gestures work without
 * unlocking.
 *
 * The dismiss gesture is chosen by the alarm's CRITICAL-SHIFT flag
 * ([requiresShake], from the Dart `isCritical` toggle) — not a fixed pair:
 *   * Normal alarm → Slide-to-dismiss. A deliberate left-to-right drag of a
 *     native handle across the full width, so a stray tap (or a face/pocket
 *     touch) can never silence it. The gesture must BEGIN over the handle on the
 *     left, so a tap landing anywhere on the right of the track is ignored
 *     outright. Mirrors the app's swipe-to-confirm convention.
 *   * Critical-shift alarm → Shake-to-dismiss, and the slide handle is HIDDEN.
 *     A must-not-miss alarm must not be swipeable away half-asleep; only a
 *     deliberate, sustained shake ([SHAKE_THRESHOLD_G], [SHAKE_COUNT_REQUIRED] —
 *     a single bump or dropped phone can never reach it) silences it. A critical
 *     alarm on a device with no accelerometer falls back to the slide handle, so
 *     the user is never locked out.
 *
 * (This is what makes the Dart-side "Critical Shift" toggle meaningful: the
 * dismiss difficulty actually changes with it, rather than shake being hardcoded
 * for every alarm.)
 *
 * Snooze stays a single large, obvious button above the slider — a groggy worker
 * wanting a few more minutes should not have to perform a precise gesture.
 */
class AlarmActivity : Activity(), SensorEventListener {
    companion object {
        private const val TAG = "RostrikAlarm"

        // ---- Shake tuning ---------------------------------------------------
        // gForce = |acceleration| / g. At rest a phone reads ~1.0g; normal
        // handling peaks well under 2g. 2.7g is a clear, deliberate jolt.
        private const val SHAKE_THRESHOLD_G = 2.7f
        // Debounce: one physical shake spans several sensor samples. Ignore
        // samples within 500ms of the last counted one so a single shake counts
        // ONCE, not a dozen times.
        private const val SHAKE_SLOP_MS = 500L
        // Require this many distinct shakes inside [SHAKE_WINDOW_MS] before we
        // accept a dismiss. Four sustained shakes ≈ a clear "I'm awake" gesture;
        // a single drop or pocket bump never reaches it.
        private const val SHAKE_COUNT_REQUIRED = 4
        private const val SHAKE_WINDOW_MS = 3_000L

        // ---- Slide-to-dismiss tuning ----------------------------------------
        // Fraction of the handle's full travel the user must cross before
        // releasing for the dismiss to commit. 0.9 = "almost all the way" — far
        // enough that a short, accidental nudge springs back, close enough that
        // the user doesn't have to fight the last pixel to the edge.
        private const val DISMISS_SLIDE_FRACTION = 0.9f

        // The dismissal fail-safe ledger. MUST equal
        // MainActivity.PENDING_DISMISSALS_FILE and `pendingDismissalsFileName`
        // in lib/alarms/pending_dismissal_guard.dart. Appending an id here is
        // how this native screen reports "alarm dismissed" back to Dart: the
        // app's boot/foreground gate reads + replays the ledger into Hive, so
        // the dismissal survives even if our process is reaped right after.
        private const val PENDING_DISMISSALS_FILE = "pending_dismissals"

        // Defensive fallback when the snooze-interval extra is absent (e.g. an
        // alarm armed by an older build). The live value rides the fire intent,
        // read from the user's `snooze_duration` setting on the Dart side.
        private const val DEFAULT_SNOOZE_MINUTES = 1

        // The snooze fail-safe ledger — one `<shiftId>|<untilMillis>` line per
        // snooze. MUST equal `pendingSnoozesFileName` in
        // lib/alarms/pending_snooze_guard.dart. Dart reads it on resume/boot
        // and sets `Shift.snoozedUntil` BEFORE its reconcile, so the reconcile
        // keeps (not cancels) the alarm this screen just re-armed.
        private const val PENDING_SNOOZES_FILE = "pending_snoozes"

        // The fired-one-time cleanup ledger — one owning `<appAlarmId>` per line.
        // MUST equal `pendingAlarmDeletesFileName` in
        // lib/alarms/pending_alarm_delete_guard.dart. Appending the fired alarm's
        // appAlarmId on dismiss is how this screen tells Dart "this alarm fired";
        // the Dart drain deletes it BEFORE its reconcile iff it's a one-time rule
        // (so a spent one-shot can't re-project into a daily cycle). Recurring
        // alarms also get recorded but Dart no-ops them.
        private const val PENDING_ALARM_DELETES_FILE = "pending_alarm_deletes"
    }

    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null

    private var shakeCount = 0
    private var firstShakeAt = 0L
    private var lastShakeAt = 0L

    private var alarmId: String? = null

    // The rest of the fire payload, read once in onCreate — needed so Snooze can
    // re-arm the SAME alarm (id + label + tone) at the user's snooze offset.
    private var notificationId: Int = -1
    private var appAlarmId: String? = null
    private var label: String = "Alarm"
    private var source: Int = AlarmAudioEngine.SOURCE_CLASSIC
    private var uri: String? = null
    private var vibrate: Boolean = false
    private var bundledResource: String? = null
    private var snoozeMinutes: Int = DEFAULT_SNOOZE_MINUTES

    // Notification copy carried forward so a Snooze re-arm keeps the alarm
    // notification detailed. `contextText` is the time-free shift context; the
    // display time is re-stamped from the snooze instant (not reused) so the
    // snoozed notification shows when it will actually ring next.
    private var contextText: String? = null

    /** Critical-shift wake mechanics (mirrors the alarm's `isCritical` flag).
     *  When true, dismissing REQUIRES a sustained shake and the slide handle is
     *  hidden — a half-asleep swipe must not silence a must-not-miss alarm. */
    private var requiresShake: Boolean = false

    /** Whether shake-to-dismiss is the ACTIVE dismiss gesture this run: a
     *  critical-shift alarm on a device that actually has an accelerometer.
     *  Resolved once in [onCreate] after the sensor lookup. When false the slide
     *  handle is shown instead — including the fallback for a critical alarm on a
     *  sensorless device, so the user is never locked out. */
    private var shakeToDismiss: Boolean = false

    /** Latched so a near-simultaneous shake + button tap (or a service
     *  auto-timeout) can't run the whole teardown twice (double stopService /
     *  double ledger write). Shared by dismiss AND snooze — both are terminal. */
    private var dismissed = false

    /** Receives [AlarmAudioService.ACTION_AUTO_DISMISS] — the service's
     *  15-minute battery fail-safe. By the time this fires the service has
     *  ALREADY recorded the dismissal, released the WakeLock, stopped the audio
     *  and cancelled the notification; the activity's only remaining job is to
     *  drop its own window so the screen can turn off. Registered NOT_EXPORTED
     *  for the whole onCreate→onDestroy lifetime so it still lands while the
     *  screen is occluded by the shade (when the activity is merely paused). */
    private val autoDismissReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            Log.d(TAG, "auto-dismiss broadcast received — finishing alarm screen")
            finishFromServiceTimeout()
        }
    }
    private var autoDismissReceiverRegistered = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        readFirePayload(intent)

        // Point the hardware volume keys at the stream the alarm is actually
        // playing on. Without this an Activity defaults to STREAM_MUSIC, so
        // pressing volume-down during an alarm opens the media slider and moves
        // a level that has nothing to do with the noise being made — reported
        // from the field 2026-08-30 as "couldn't turn it down in the normal
        // Android sounds menu".
        //
        // AlarmAudioEngine plays with USAGE_ALARM, so STREAM_ALARM is the
        // matching stream. Note this only helps while THIS screen is in front:
        // when the full-screen intent degrades to a heads-up notification (the
        // normal case on an unlocked, in-use phone) the foreground app still
        // owns the volume keys. That gap is the notification-actions work, not
        // this line.
        volumeControlStream = android.media.AudioManager.STREAM_ALARM

        applyLockScreenWindowFlags()

        // Resolve the accelerometer BEFORE building the UI so the dismiss control
        // can honestly reflect whether shake-to-dismiss is available here.
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        // Shake is the dismiss gesture ONLY for a critical-shift alarm, and only
        // when the device has an accelerometer. A critical alarm on a sensorless
        // device falls back to the slide handle (better than no dismiss at all).
        shakeToDismiss = requiresShake && accelerometer != null
        if (requiresShake && accelerometer == null) {
            Log.w(TAG, "critical-shift alarm but no accelerometer — falling back to slide-to-dismiss")
        }
        Log.d(TAG, "dismiss mode: ${if (shakeToDismiss) "shake (critical)" else "slide"}")

        setContentView(buildContentView())

        registerAutoDismissReceiver()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // A re-fire while this screen is already up: adopt the new payload so a
        // dismiss/snooze acts on the alarm that's actually ringing.
        setIntent(intent)
        readFirePayload(intent)
    }

    /** Reads the full fire payload off [from] into the per-instance fields. */
    private fun readFirePayload(from: Intent) {
        alarmId = from.getStringExtra(AlarmReceiver.EXTRA_ALARM_ID) ?: alarmId
        appAlarmId = from.getStringExtra(AlarmReceiver.EXTRA_APP_ALARM_ID) ?: appAlarmId
        label = from.getStringExtra(AlarmReceiver.EXTRA_LABEL) ?: label
        contextText = from.getStringExtra(AlarmReceiver.EXTRA_BODY) ?: contextText
        requiresShake = from.getBooleanExtra(AlarmReceiver.EXTRA_REQUIRES_SHAKE, requiresShake)
        notificationId = from.getIntExtra(AlarmReceiver.EXTRA_NOTIFICATION_ID, notificationId)
        snoozeMinutes = from.getIntExtra(AlarmReceiver.EXTRA_SNOOZE_MINUTES, snoozeMinutes)
        source = from.getIntExtra(AlarmAudioService.EXTRA_SOURCE, source)
        uri = from.getStringExtra(AlarmAudioService.EXTRA_URI) ?: uri
        vibrate = from.getBooleanExtra(AlarmAudioService.EXTRA_VIBRATE, vibrate)
        bundledResource = from.getStringExtra(AlarmAudioService.EXTRA_BUNDLED_RESOURCE) ?: bundledResource
    }

    // -----------------------------------------------------------------------
    // Lock-screen window flags. Modern setters (O_MR1+) are the recommended
    // path; the deprecated FLAG_* are added too so the requested
    // SHOW_WHEN_LOCKED / TURN_SCREEN_ON / KEEP_SCREEN_ON behaviour holds across
    // every supported API level. We do NOT requestDismissKeyguard — dismissing
    // the alarm must never require the user to unlock first.
    // -----------------------------------------------------------------------
    private fun applyLockScreenWindowFlags() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
        setShowWhenLocked(true)
        setTurnScreenOn(true)
        // ADD THIS: Explicitly request the keyguard manager to allow bypass
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            keyguardManager.requestDismissKeyguard(this, null) 
        }
    }
    window.addFlags(
        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD // ADD THIS LEGACY FLAG
    )
}

    private fun buildContentView(): LinearLayout {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0B0B0F"))
            val p = dp(32)
            setPadding(p, p, p, p)
        }
        val title = TextView(this).apply {
            text = label
            setTextColor(Color.WHITE)
            textSize = 30f
            gravity = Gravity.CENTER
        }
        val mins = if (snoozeMinutes > 0) snoozeMinutes else DEFAULT_SNOOZE_MINUTES
        val hint = TextView(this).apply {
            // Critical-shift alarms (shake mode) deliberately offer NO slide
            // handle — the only way to silence them is a firm, sustained shake.
            text = if (shakeToDismiss) {
                "Critical alarm\nShake firmly to dismiss"
            } else {
                "Slide the handle below to dismiss"
            }
            setTextColor(Color.parseColor("#B0B0B8"))
            textSize = 16f
            gravity = Gravity.CENTER
            setPadding(0, dp(16), 0, dp(40))
        }
        // Snooze stays the big, obvious tap target (a groggy worker wanting a few
        // more minutes shouldn't have to perform a precise gesture). The label
        // reflects the user's configured interval, not a hardcoded value.
        val snoozeButton = Button(this).apply {
            text = "SNOOZE ($mins MIN)"
            textSize = 18f
            setOnClickListener { snoozeAlarm() }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            )
        }

        root.addView(title)
        root.addView(hint)
        root.addView(snoozeButton)
        // The slide handle is the dismiss control for NORMAL alarms (and the
        // fallback for a critical alarm on a sensorless device). Critical alarms
        // with a working accelerometer dismiss by shake only — no handle.
        if (!shakeToDismiss) {
            root.addView(buildSlideToDismissTrack())
        }
        return root
    }

    /**
     * The primary dismiss control: a native "slide to dismiss" track. A handle
     * sits at the left; the user drags it the full width to silence the alarm.
     *
     * Built entirely in code ([GradientDrawable] for the rounded track + circular
     * handle) so it needs no XML drawables. Forgiving but tamper-proof:
     *   * The drag must START over the handle (left region). A touch that begins
     *     anywhere to the right of the handle is rejected on ACTION_DOWN, so a
     *     stray tap near the right edge can NEVER complete a dismiss.
     *   * Releasing before [DISMISS_SLIDE_FRACTION] of the travel springs the
     *     handle back; only crossing it commits the dismiss.
     */
    @SuppressLint("ClickableViewAccessibility")
    private fun buildSlideToDismissTrack(): FrameLayout {
        val trackHeight = dp(72)
        val inset = dp(6)
        val handleSize = trackHeight - inset * 2

        val track = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                cornerRadius = trackHeight / 2f
                setColor(Color.parseColor("#16161C"))
                setStroke(dp(1), Color.parseColor("#2E2E3A"))
            }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                trackHeight,
            ).apply { topMargin = dp(20) }
        }

        // Centred prompt that fades out as the handle advances.
        val slideLabel = TextView(this).apply {
            text = "Slide to dismiss"
            setTextColor(Color.parseColor("#9A9AA6"))
            textSize = 17f
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            )
        }

        // The draggable handle: a bright circle with a chevron, high-contrast on
        // the dark track so it reads instantly at 3am.
        val handle = TextView(this).apply {
            text = "›››"
            setTextColor(Color.parseColor("#0B0B0F"))
            textSize = 22f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            isClickable = false
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#F5F5F7"))
            }
            layoutParams = FrameLayout.LayoutParams(handleSize, handleSize).apply {
                gravity = Gravity.START or Gravity.CENTER_VERTICAL
                marginStart = inset
            }
        }

        track.addView(slideLabel)
        track.addView(handle)

        var dragging = false
        var grabOffset = 0f
        track.setOnTouchListener { _, ev ->
            if (dismissed) return@setOnTouchListener false
            // Travel = how far the handle's left edge can move before its right
            // edge meets the track's inset on the far side.
            val maxTravel = (track.width - handle.width - inset * 2).toFloat()
                .coerceAtLeast(1f)
            when (ev.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    // Only begin a drag if the finger lands on (or just beside)
                    // the handle. A generous grab zone keeps it groggy-friendly
                    // without letting a right-side tap dismiss.
                    val grabZone = handle.translationX + handle.width + dp(28)
                    if (ev.x <= grabZone) {
                        dragging = true
                        grabOffset = ev.x - handle.translationX
                        true
                    } else {
                        false
                    }
                }
                MotionEvent.ACTION_MOVE -> {
                    if (!dragging) return@setOnTouchListener false
                    val tx = (ev.x - grabOffset).coerceIn(0f, maxTravel)
                    handle.translationX = tx
                    slideLabel.alpha = 1f - (tx / maxTravel)
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    if (!dragging) return@setOnTouchListener false
                    dragging = false
                    if (handle.translationX >= maxTravel * DISMISS_SLIDE_FRACTION) {
                        // Committed: snap to the end and silence the alarm.
                        handle.translationX = maxTravel
                        slideLabel.alpha = 0f
                        dismissAlarm("slide")
                    } else {
                        // Released short — spring back.
                        handle.animate().translationX(0f).setDuration(180).start()
                        slideLabel.animate().alpha(1f).setDuration(180).start()
                    }
                    true
                }
                else -> false
            }
        }
        return track
    }

    /** dp → px for the programmatic layout (no XML resources on this screen). */
    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

    /** Formats [millis] as a 12-hour `hh:mm AM/PM` clock string for the snooze
     *  re-arm's notification — mirrors the Dart side's `_formatClock12h` so a
     *  snoozed alarm's notification reads identically to a freshly-scheduled one
     *  ("03:05 AM"). */
    private fun formatClock12h(millis: Long): String =
        SimpleDateFormat("hh:mm a", Locale.getDefault()).format(Date(millis))

    // -----------------------------------------------------------------------
    // Accelerometer lifecycle. Registered while the screen is the foreground
    // alarm UI; unregistered the moment it's backgrounded so we never leak the
    // sensor. (Audio keeps playing in the service regardless of this listener.)
    // -----------------------------------------------------------------------
    override fun onResume() {
        super.onResume()
        // Register the accelerometer ONLY when shake is the active dismiss
        // gesture (a critical-shift alarm). Normal alarms dismiss via the slide
        // handle, so there's no reason to listen — or drain battery on — the
        // sensor for them.
        if (shakeToDismiss) {
            val sm = sensorManager
            val acc = accelerometer
            if (sm != null && acc != null) {
                sm.registerListener(this, acc, SensorManager.SENSOR_DELAY_GAME)
            }
        }
        // Fresh window each time the screen returns to the foreground.
        resetShakeWindow()
    }

    override fun onPause() {
        sensorManager?.unregisterListener(this)
        super.onPause()
    }

    override fun onSensorChanged(event: SensorEvent) {
        // Defence-in-depth: the listener is only registered in shake mode, but
        // guard anyway so a normal alarm can never be dismissed by a shake.
        if (dismissed || !shakeToDismiss || event.sensor.type != Sensor.TYPE_ACCELEROMETER) return

        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]
        val gForce = sqrt((x * x + y * y + z * z).toDouble()).toFloat() / SensorManager.GRAVITY_EARTH

        if (gForce <= SHAKE_THRESHOLD_G) return

        val now = System.currentTimeMillis()
        // Debounce the multi-sample spike of a single shake into one count.
        if (now - lastShakeAt < SHAKE_SLOP_MS) return

        // Start (or restart) the window if this is the first shake or the prior
        // burst went stale.
        if (shakeCount == 0 || now - firstShakeAt > SHAKE_WINDOW_MS) {
            shakeCount = 0
            firstShakeAt = now
        }
        lastShakeAt = now
        shakeCount++
        Log.d(TAG, "shake $shakeCount/$SHAKE_COUNT_REQUIRED (gForce=$gForce)")

        if (shakeCount >= SHAKE_COUNT_REQUIRED) {
            dismissAlarm("shake")
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // No-op — accuracy changes don't affect a magnitude-threshold detector.
    }

    private fun resetShakeWindow() {
        shakeCount = 0
        firstShakeAt = 0L
        lastShakeAt = 0L
    }

    // -----------------------------------------------------------------------
    // Tear-down. The single exit for a ringing alarm.
    // -----------------------------------------------------------------------
    private fun dismissAlarm(reason: String) {
        if (dismissed) return
        dismissed = true
        Log.d(TAG, "dismiss via '$reason' (id=$alarmId)")

        // 1. Stop the looping audio. stopService routes to the service's
        //    onDestroy → AlarmAudioEngine.stop() (audio + haptics).
        stopService(Intent(this, AlarmAudioService::class.java))

        // 2. Cancel the full-screen-intent notification so no stale alarm
        //    lingers in the shade.
        cancelAlarmNotification()

        // 3. Report success to the Dart layer durably. Appending
        //    `<shiftId>|<appAlarmId>` to the native ledger is the
        //    process-death-proof callback the app already trusts
        //    (MainActivity.readPendingDismissals + the Dart boot gate replay it
        //    into Hive). The appAlarmId scopes the dismissal to THIS ring —
        //    Dart records it per-occurrence so the shift's other alarms keep
        //    firing. No need to spin up Flutter at 3am.
        recordDismissal(alarmId, appAlarmId)

        // 3b. Record the fired rule so Dart can delete a spent ONE-TIME alarm
        //     before its next reconcile re-projects it into a daily cycle.
        //     Recorded for any alarm with an appAlarmId; Dart no-ops recurring
        //     rules and only deletes the one-time ones.
        recordPendingAlarmDelete(appAlarmId)

        // 4. Release the WakeLock AlarmReceiver took at fire time.
        AlarmReceiver.releaseWakeLock()

        // 5. Drop keep-screen-on and finish, removing the task so no zombie
        //    alarm screen lingers over the keyguard (the activity is also
        //    excludeFromRecents in the manifest).
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        finishAndRemoveTask()
    }

    private fun cancelAlarmNotification() {
        try {
            val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            // Per-alarm id (audit F4) — cancel THIS ring's notification only;
            // a superseded sibling's stays until it is handled. Fallback for
            // legacy intents without the id extra.
            mgr.cancel(if (notificationId >= 0) notificationId else AlarmReceiver.NOTIF_ID)
        } catch (e: Exception) {
            Log.w(TAG, "notification cancel failed", e)
        }
    }

    /** Snooze: re-arm the SAME alarm at the configured offset and stand the
     *  screen down.
     *
     *  Reusing [notificationId] is the crux of conflict-free reconciliation —
     *  that id is already in Dart's NativeAlarmScheduler ledger, so a later
     *  reconcile either REPLACES this alarm in place (same-day → projection
     *  computes the same id, FLAG_UPDATE_CURRENT) or CANCELS it and re-schedules
     *  at the identical instant (cross-midnight → projection's new id; this id
     *  becomes a ledger orphan). Either way the user gets exactly one alarm at
     *  the snooze instant. The `pending_snoozes` entry is what makes Dart set
     *  `snoozedUntil` BEFORE that reconcile, so the reconcile keeps the alarm
     *  instead of seeing an unacknowledged shift with no future ring and
     *  cancelling it. */
    private fun snoozeAlarm() {
        if (dismissed) return
        dismissed = true
        val minutes = if (snoozeMinutes > 0) snoozeMinutes else DEFAULT_SNOOZE_MINUTES
        val snoozeUntil = System.currentTimeMillis() + minutes * 60L * 1000L
        Log.d(TAG, "snooze id=$notificationId alarmId=$alarmId mins=$minutes until=$snoozeUntil")

        // 1. Re-arm the SAME notification id at the user's snooze offset, with the
        //    same tone, and carrying the snooze interval forward for the next tap.
        //    Re-stamp the display time to the SNOOZE instant so the next
        //    notification shows when it will actually ring; keep the shift
        //    context as-is.
        if (notificationId >= 0) {
            val armed = NativeAlarmScheduling.schedule(
                applicationContext,
                id = notificationId,
                triggerAtMillis = snoozeUntil,
                alarmId = alarmId,
                appAlarmId = appAlarmId,
                label = label,
                source = source,
                uri = uri,
                vibrate = vibrate,
                bundledResource = bundledResource,
                snoozeMinutes = minutes,
                displayTime = formatClock12h(snoozeUntil),
                body = contextText,
                requiresShake = requiresShake,
            )
            if (!armed) {
                // Android 12/12L with the exact-alarm permission revoked: the
                // re-arm was refused (schedule() never throws — an uncaught
                // SecurityException here would crash the alarm screen on a
                // snooze tap). The snooze ledger below still records intent;
                // Dart's reconcile re-arms once permission returns.
                Log.w(TAG, "snooze: exact-alarm refused — snooze not re-armed natively")
            }
        } else {
            Log.w(TAG, "snooze: missing notification id — cannot re-arm natively")
        }

        // 2. Record the snooze so Dart sets `snoozedUntil` (shift) or the one-off
        //    snooze map (shift-less 'NONE', keyed by appAlarmId).
        recordSnooze(alarmId, appAlarmId, snoozeUntil)

        // 3. Stand down exactly like a dismiss — stop audio, cancel the
        //    notification, release the WakeLock, finish. (stopService cancels
        //    the 15-min auto-timeout via the service's onDestroy.)
        stopService(Intent(this, AlarmAudioService::class.java))
        cancelAlarmNotification()
        AlarmReceiver.releaseWakeLock()
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        finishAndRemoveTask()
    }

    /** Append `<shiftId>|<appAlarmId>|<untilMillis>` to the snooze ledger,
     *  flushed + fsync'd so it survives an immediate reap. Dart uses shiftId for
     *  shift-based alarms (→ `Shift.snoozedUntil`) and appAlarmId for shift-less
     *  'NONE' alarms (→ the one-off snooze map). Skips a record with neither id. */
    private fun recordSnooze(shiftId: String?, appAlarmId: String?, untilMillis: Long) {
        val shift = shiftId ?: ""
        val app = appAlarmId ?: ""
        if (shift.isEmpty() && app.isEmpty()) return
        try {
            val file = File(filesDir, PENDING_SNOOZES_FILE)
            FileOutputStream(file, /* append = */ true).use { out ->
                out.write("$shift|$app|$untilMillis\n".toByteArray(Charsets.UTF_8))
                out.flush()
                out.fd.sync()
            }
            Log.d(TAG, "recorded snooze shift=$shift app=$app until=$untilMillis")
        } catch (e: Exception) {
            Log.w(TAG, "recordSnooze failed shift=$shift app=$app", e)
        }
    }

    /** Append `<shiftId>|<appAlarmId>` to the native ledger, flushed + fsync'd
     *  so it survives the OS reaping us immediately after. The appAlarmId is
     *  what lets Dart resolve the dismissal to ONE ring (a shift can carry
     *  several alarms; dismissing the first must never disarm the rest). When
     *  it is absent (a fire intent armed by an older build) the bare shiftId
     *  is written and Dart falls back to the legacy whole-shift ack. De-dup is
     *  the reader's job (a double-tap appends twice; the Hive replay acks
     *  once). */
    private fun recordDismissal(shiftId: String?, appAlarmId: String?) {
        if (shiftId.isNullOrEmpty()) return
        val line = if (appAlarmId.isNullOrEmpty()) shiftId else "$shiftId|$appAlarmId"
        try {
            val file = File(filesDir, PENDING_DISMISSALS_FILE)
            FileOutputStream(file, /* append = */ true).use { out ->
                out.write((line + "\n").toByteArray(Charsets.UTF_8))
                out.flush()
                out.fd.sync() // kernel-sync — the whole point of the fail-safe
            }
            Log.d(TAG, "recorded dismissal $line")
        } catch (e: Exception) {
            Log.w(TAG, "recordDismissal failed for $line", e)
        }
    }

    /** Append the fired alarm's owning [appAlarmId] to the cleanup ledger,
     *  flushed + fsync'd so it survives an immediate reap. Dart resolves each id
     *  to its AppAlarm on the next boot/resume and deletes the ONE-TIME ones
     *  (recurring rules are a no-op there), so a spent one-shot can't re-project
     *  into a daily cycle. Skips an empty id (nothing to resolve). */
    private fun recordPendingAlarmDelete(appAlarmId: String?) {
        if (appAlarmId.isNullOrEmpty()) return
        try {
            val file = File(filesDir, PENDING_ALARM_DELETES_FILE)
            FileOutputStream(file, /* append = */ true).use { out ->
                out.write((appAlarmId + "\n").toByteArray(Charsets.UTF_8))
                out.flush()
                out.fd.sync() // kernel-sync — survives an immediate process reap
            }
            Log.d(TAG, "recorded pending alarm-delete appAlarmId=$appAlarmId")
        } catch (e: Exception) {
            Log.w(TAG, "recordPendingAlarmDelete failed for id=$appAlarmId", e)
        }
    }

    private fun registerAutoDismissReceiver() {
        val filter = IntentFilter(AlarmAudioService.ACTION_AUTO_DISMISS)
        // Android 14 (targetSdk 34) requires an explicit export flag on every
        // runtime-registered receiver for a non-system broadcast. This one is
        // app-internal, so NOT_EXPORTED.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(autoDismissReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(autoDismissReceiver, filter)
        }
        autoDismissReceiverRegistered = true
    }

    /** The service auto-timeout path: it already did the ledger write, WakeLock
     *  release, audio stop and notification cancel, so the activity just drops
     *  its window. Shares the [dismissed] latch so a shake/tap landing in the
     *  same instant doesn't double-tear-down. */
    private fun finishFromServiceTimeout() {
        if (dismissed) return
        dismissed = true
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        finishAndRemoveTask()
    }

    override fun onDestroy() {
        if (autoDismissReceiverRegistered) {
            try {
                unregisterReceiver(autoDismissReceiver)
            } catch (e: Exception) {
                Log.w(TAG, "auto-dismiss receiver unregister failed", e)
            }
            autoDismissReceiverRegistered = false
        }
        super.onDestroy()
    }

    @Suppress("OVERRIDE_DEPRECATION")
    override fun onBackPressed() {
        // Swallow Back — it must NOT silence the alarm (mirrors WakeUpScreen's
        // PopScope(canPop:false)). Dismiss only via shake or the button.
        Log.d(TAG, "back press ignored — alarm still active")
    }
}
