package com.example.rostrik_mvp

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Belt-and-braces lock-screen bypass + warm-launch alarm routing.
 *
 * Two responsibilities:
 *   1. Lock-screen bypass — also declared in AndroidManifest.xml via
 *      `showWhenLocked` / `turnScreenOn`, but the runtime calls below
 *      apply on every onCreate and let us also nudge the keyguard to
 *      dismiss when the device is unlocked-but-screen-off.
 *   2. Warm-launch alarm routing — when the alarm fires while the app is
 *      already alive (foreground or backgrounded), the OS brings this
 *      activity to front via onNewIntent rather than re-running main(),
 *      so the cold-launch `getNotificationAppLaunchDetails()` path in
 *      main.dart can't see the new launch. We extract the notification
 *      payload from the new intent and push it to Flutter via a method
 *      channel, where main.dart navigates to WakeUpScreen.
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "Rostrik"
        private const val CHANNEL = "rostrik/alarm_routing"
        // flutter_local_notifications stores the schedule's `payload`
        // string under this extra key in the PendingIntent it builds.
        private const val EXTRA_PAYLOAD = "payload"
    }

    private var alarmChannel: MethodChannel? = null

    /// Buffered payload captured by onNewIntent BEFORE the Flutter engine
    /// finished attaching its method-channel handler. Drained on
    /// configureFlutterEngine. Rare in practice (onNewIntent on a backgrounded
    /// app means Flutter is already running) but cheap insurance.
    private var pendingPayload: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        alarmChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        )
        // Drain any payload that arrived before Flutter was ready.
        pendingPayload?.let { dispatchToFlutter(it) }
        pendingPayload = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Replace the activity's stored intent so any later getIntent()
        // reads the new launch, not the original one.
        setIntent(intent)

        val payload = intent.getStringExtra(EXTRA_PAYLOAD)
        if (payload == null) {
            // First-test diagnostics: if the plugin starts using a different
            // extra key in a future version, we can read the keys here and
            // adjust EXTRA_PAYLOAD without guessing blindly.
            Log.d(
                TAG,
                "onNewIntent had no '$EXTRA_PAYLOAD' extra. Keys present: " +
                    "${intent.extras?.keySet()?.joinToString()}",
            )
            return
        }
        Log.d(TAG, "onNewIntent received alarm payload: $payload")

        if (alarmChannel != null) {
            dispatchToFlutter(payload)
        } else {
            pendingPayload = payload
        }
    }

    private fun dispatchToFlutter(payload: String) {
        alarmChannel?.invokeMethod("alarmFired", payload)
    }
}
