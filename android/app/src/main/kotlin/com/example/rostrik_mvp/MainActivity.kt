package com.example.rostrik_mvp

import android.content.Intent
import android.os.Build
import android.os.Bundle
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

        // Dart-side methods exchanged on this channel. Keep these strings
        // in sync with `main.dart`; the names are part of the wire
        // contract between Kotlin and Dart.
        private const val METHOD_GET_INITIAL_PAYLOAD = "getInitialAlarmPayload"
        private const val METHOD_ALARM_FIRED = "alarmFired"

        // flutter_local_notifications stores the schedule's `payload`
        // string under this extra key in the PendingIntent it builds.
        private const val EXTRA_PAYLOAD = "payload"
    }

    private var alarmChannel: MethodChannel? = null

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
}
