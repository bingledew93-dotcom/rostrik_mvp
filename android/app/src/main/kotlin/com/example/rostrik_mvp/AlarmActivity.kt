package com.example.rostrik_mvp

import android.annotation.SuppressLint
import android.app.Activity
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
    private var snoozeMinutes: Int = AlarmRingControl.DEFAULT_SNOOZE_MINUTES

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

    /** Receives [AlarmAudioService.ACTION_AUTO_DISMISS] — sent by the service's
     *  15-minute battery fail-safe, and by [AlarmActionReceiver] when the ring
     *  is ended from the notification's buttons. By the time this fires the
     *  sender has ALREADY done the ledger writes, released the WakeLock, stopped
     *  the audio and cancelled the notification; the activity's only remaining
     *  job is to drop its own window so the screen can turn off. A broadcast
     *  naming a different alarm's notification id is ignored, so ending a
     *  superseded alarm from the shade cannot close the screen of the one still
     *  ringing. Registered NOT_EXPORTED for the whole onCreate→onDestroy lifetime
     *  so it still lands while the screen is occluded by the shade (when the
     *  activity is merely paused). */
    private val autoDismissReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val endedId = intent?.getIntExtra(AlarmReceiver.EXTRA_NOTIFICATION_ID, -1) ?: -1
            if (endedId >= 0 && notificationId >= 0 && endedId != notificationId) return
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
        // owns the volume keys, and the notification's Snooze/Dismiss buttons
        // ([AlarmActionReceiver]) are the way out.
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
        val mins = if (snoozeMinutes > 0) snoozeMinutes else AlarmRingControl.DEFAULT_SNOOZE_MINUTES
        val hint = TextView(this).apply {
            // Critical-shift alarms (shake mode) deliberately offer NO slide
            // handle — the only way to silence them is a firm, sustained shake.
            text = getString(
                if (shakeToDismiss) R.string.alarm_hint_critical
                else R.string.alarm_hint_slide,
            )
            setTextColor(Color.parseColor("#B0B0B8"))
            textSize = 16f
            gravity = Gravity.CENTER
            setPadding(0, dp(16), 0, dp(40))
        }
        // Snooze stays the big, obvious tap target (a groggy worker wanting a few
        // more minutes shouldn't have to perform a precise gesture). The label
        // reflects the user's configured interval, not a hardcoded value.
        val snoozeButton = Button(this).apply {
            text = getString(R.string.alarm_snooze_button, mins)
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
            text = getString(R.string.alarm_slide_to_dismiss)
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
        // Audio, notification, ledgers and WakeLock — shared with the
        // notification's Dismiss button so both paths end a ring identically.
        AlarmRingControl.dismiss(this, currentRing(), reason)

        // Drop keep-screen-on and finish, removing the task so no zombie
        // alarm screen lingers over the keyguard (the activity is also
        // excludeFromRecents in the manifest).
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        finishAndRemoveTask()
    }

    /** Snooze: re-arm the SAME alarm at the configured offset and stand the
     *  screen down. See [AlarmRingControl.snooze] for why the id is reused. */
    private fun snoozeAlarm() {
        if (dismissed) return
        dismissed = true
        AlarmRingControl.snooze(this, currentRing())
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        finishAndRemoveTask()
    }

    /** The ringing alarm as the shared tear-down sees it. */
    private fun currentRing() = AlarmRingControl.Ring(
        alarmId = alarmId,
        appAlarmId = appAlarmId,
        notificationId = notificationId,
        label = label,
        contextText = contextText,
        requiresShake = requiresShake,
        snoozeMinutes = snoozeMinutes,
        source = source,
        uri = uri,
        vibrate = vibrate,
        bundledResource = bundledResource,
    )

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
