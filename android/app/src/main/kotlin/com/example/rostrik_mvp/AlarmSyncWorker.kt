package com.example.rostrik_mvp

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Spins up a headless `FlutterEngine`, runs the
 * `syncAlarmsBackgroundEntrypoint` Dart function, and returns once the
 * entrypoint reports completion via MethodChannel.
 *
 * This is what makes [BootReceiver] effectful — the receiver itself
 * runs on the main thread with a ~10s ANR budget which is nowhere
 * near enough to start a Flutter engine, open Hive, walk the shifts
 * box, and re-issue scheduleAt calls. WorkManager gives us a real
 * background thread with no time budget, plus crash-resume semantics:
 * if the device reboots mid-sync, the worker is re-enqueued.
 *
 * Why not the `workmanager` Flutter plugin: per Phase-5 architectural
 * stance we don't run a long-lived Dart isolate in a periodic worker.
 * This Worker is one-shot per boot / package-replace — it starts an
 * engine, runs one sync, tears down. The engine does not persist
 * across `doWork()` calls.
 *
 * Hand-off contract with Dart (identical to the iOS path):
 *   1. Native creates the engine, registers plugins, starts the
 *      `syncAlarmsBackgroundEntrypoint` Dart entry.
 *   2. Native attaches a method-call handler that listens for
 *      `handlerReady`.
 *   3. Dart's entrypoint sets up its `run` handler and then invokes
 *      `handlerReady` on native to confirm it's wired.
 *   4. Native, on receiving `handlerReady`, invokes `run` on Dart.
 *   5. Dart performs the sync, returns success (or PlatformException).
 *   6. Native tears down the engine and reports `Result.success()` or
 *      `Result.retry()`.
 *
 * Without the handshake, native's `invokeMethod("run", ...)` can fire
 * before Dart's `setMethodCallHandler` is registered and the call is
 * lost as `notImplemented`.
 */
class AlarmSyncWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {

    companion object {
        private const val TAG = "RostrikSyncWorker"

        /// Unique-work name. Using a constant means a second enqueue
        /// while one is already pending becomes a no-op (with
        /// ExistingWorkPolicy.KEEP). Without this, a reboot loop
        /// could pile workers up faster than WorkManager could drain
        /// them.
        private const val UNIQUE_WORK_NAME = "rostrik_alarm_sync_boot"

        /// Channel name matched by `lib/alarms/background_sync_entrypoint.dart`
        /// and `ios/Runner/AppDelegate.swift`. All three must agree.
        private const val CHANNEL = "rostrik/alarm_sync_background"

        /// Dart entrypoint function name. Must match the function
        /// annotated `@pragma('vm:entry-point')` in
        /// `lib/alarms/background_sync_entrypoint.dart`. AOT drops
        /// any function not so annotated, so a mismatch surfaces as
        /// "entrypoint not found" rather than a silent skip.
        private const val DART_ENTRYPOINT = "syncAlarmsBackgroundEntrypoint"

        /// Hard cap on how long we wait for the Dart sync to finish.
        /// 30s gives the engine plenty of time to start, open Hive,
        /// walk a 14-day window, and re-schedule up to 50 alarms —
        /// our measured worst-case on a budget device. WorkManager
        /// can pre-empt us with a stop signal earlier if Doze is
        /// aggressive; the timeout is the upper bound, not the
        /// expected runtime.
        private const val SYNC_TIMEOUT_MS = 30_000L

        fun enqueueOneShot(context: Context) {
            val request = OneTimeWorkRequestBuilder<AlarmSyncWorker>()
                // No constraints — boot recovery must run regardless
                // of charging / network / idle state. The work is
                // light and the user expects alarms to be ready
                // immediately after unlock.
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork(
                UNIQUE_WORK_NAME,
                ExistingWorkPolicy.KEEP,
                request,
            )
        }
    }

    /**
     * Worker entry point. Coroutines on `Dispatchers.Main` because
     * `FlutterEngine` and `MethodChannel` must be touched on the main
     * thread (Flutter's `BinaryMessenger` asserts main-thread use).
     * The heavy work (Hive + scheduler calls) happens in the Dart
     * isolate which is OFF the main thread, so we're not blocking
     * the UI thread for the sync itself — just the engine lifecycle
     * calls.
     */
    override suspend fun doWork(): Result = withContext(Dispatchers.Main) {
        Log.d(TAG, "AlarmSyncWorker.doWork start")

        val engine = FlutterEngine(applicationContext)

        try {
            // Resolve the bundled Dart code's location. FlutterInjector
            // is the supported singleton entrypoint for this in v2
            // embedding. Calling `findAppBundlePath` outside a
            // FlutterActivity context still works because it reads
            // from the installed APK's assets, not from any per-
            // activity state.
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)

            val entrypoint = DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                DART_ENTRYPOINT,
            )

            engine.dartExecutor.executeDartEntrypoint(entrypoint)

            // GeneratedPluginRegistrant is the auto-generated file in
            // io.flutter.plugins. It registers every plugin in the
            // app — including flutter_local_notifications, which the
            // Dart entrypoint needs to talk to AlarmManager. Without
            // this call, the entrypoint's plugin method calls return
            // MissingPluginException.
            GeneratedPluginRegistrant.registerWith(engine)

            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            val syncCompleted = CompletableDeferred<Boolean>()

            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "handlerReady" -> {
                        Log.d(TAG, "Dart handler ready — invoking run")
                        result.success(null)
                        // Now that Dart has confirmed its handler is
                        // wired, invoke the actual sync. Result
                        // callback completes the deferred so the
                        // outer coroutine unblocks.
                        channel.invokeMethod("run", null, object : MethodChannel.Result {
                            override fun success(runResult: Any?) {
                                Log.d(TAG, "Dart sync completed: $runResult")
                                syncCompleted.complete(true)
                            }
                            override fun error(code: String, message: String?, details: Any?) {
                                Log.e(TAG, "Dart sync error: $code / $message")
                                syncCompleted.complete(false)
                            }
                            override fun notImplemented() {
                                Log.e(TAG, "Dart sync handler missing — entrypoint did not register?")
                                syncCompleted.complete(false)
                            }
                        })
                    }
                    else -> result.notImplemented()
                }
            }

            // Wait for the sync (or hit the timeout). null from
            // withTimeoutOrNull means timeout — treat as retryable
            // so WorkManager will try again with backoff.
            val success = withTimeoutOrNull(SYNC_TIMEOUT_MS) {
                syncCompleted.await()
            }

            when (success) {
                true -> Result.success()
                false -> {
                    Log.w(TAG, "Dart sync reported failure — retrying")
                    Result.retry()
                }
                null -> {
                    Log.w(TAG, "Dart sync timed out after ${SYNC_TIMEOUT_MS}ms")
                    Result.retry()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "AlarmSyncWorker exception", e)
            // Retry on any exception. WorkManager's default backoff
            // policy (exponential, 30s base) will space out retries
            // so a persistent failure doesn't hammer the device.
            Result.retry()
        } finally {
            // Always tear down. A leaked FlutterEngine holds an
            // isolate alive and consumes ~10MB of RAM — innocuous
            // once, catastrophic over an extended retry chain.
            try {
                engine.destroy()
            } catch (e: Exception) {
                Log.e(TAG, "engine.destroy() threw", e)
            }
            Log.d(TAG, "AlarmSyncWorker.doWork end")
        }
    }
}
