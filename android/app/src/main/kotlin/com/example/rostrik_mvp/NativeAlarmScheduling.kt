package com.example.rostrik_mvp

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Shared registration + implementation for the `rostrik/native_alarms`
 * MethodChannel — the flutter_local_notifications replacement that arms exact
 * AlarmManager alarms.
 *
 * Extracted out of [MainActivity] so the IDENTICAL handler can be wired into
 * BOTH Flutter engines the Dart `NativeAlarmScheduler` can run in:
 *   * the foreground UI engine ([MainActivity.configureFlutterEngine]), and
 *   * the HEADLESS background engine [AlarmSyncWorker] spins up on boot.
 *
 * Without the second registration the boot re-sync's `scheduleAt` calls would
 * hit `MissingPluginException` — the channel handler would only exist in the UI
 * engine — and alarms would silently fail to re-arm after a reboot. (FLN got
 * this for free because its plugin self-registers via GeneratedPluginRegistrant;
 * our hand-written bridge must be registered explicitly in each engine.)
 *
 * Context-based (never holds an Activity) so the Worker — which has only an
 * application Context — can register it too. Every Intent is explicit, so the
 * application context is sufficient.
 */
object NativeAlarmScheduling {
    private const val TAG = "Rostrik"

    const val CHANNEL = "rostrik/native_alarms"
    private const val METHOD_SET_EXACT_ALARM = "setExactAlarm"
    private const val METHOD_CANCEL_ALARM = "cancelAlarm"

    /** Wires the channel onto [messenger], servicing calls with [context]'s
     *  application context. Returns the channel so the caller can retain it for
     *  the engine's lifetime. */
    fun register(messenger: BinaryMessenger, context: Context): MethodChannel {
        val appContext = context.applicationContext
        val channel = MethodChannel(messenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_SET_EXACT_ALARM -> {
                    val id = (call.argument<Number>("id"))?.toInt()
                    val triggerAtMillis = (call.argument<Number>("triggerAtMillis"))?.toLong()
                    if (id == null || triggerAtMillis == null) {
                        result.error("BAD_ARGS", "id and triggerAtMillis are required", null)
                    } else {
                        scheduleExactAlarm(
                            appContext,
                            id = id,
                            triggerAtMillis = triggerAtMillis,
                            alarmId = call.argument<String>("alarm_id"),
                            appAlarmId = call.argument<String>("appAlarmId"),
                            label = call.argument<String>("label"),
                            source = (call.argument<Number>("source"))?.toInt()
                                ?: AlarmAudioEngine.SOURCE_CLASSIC,
                            uri = call.argument<String>("uri"),
                            vibrate = call.argument<Boolean>("vibrate") ?: false,
                            bundledResource = call.argument<String>("bundledResource"),
                            snoozeMinutes = (call.argument<Number>("snoozeMinutes"))?.toInt() ?: 1,
                            displayTime = call.argument<String>("displayTime"),
                            body = call.argument<String>("body"),
                            requiresShake = call.argument<Boolean>("requiresShake") ?: false,
                        )
                        result.success(null)
                    }
                }
                METHOD_CANCEL_ALARM -> {
                    val id = (call.argument<Number>("id"))?.toInt()
                    if (id == null) {
                        result.error("BAD_ARGS", "id is required", null)
                    } else {
                        cancelExactAlarm(appContext, id)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        return channel
    }

    /** Public so [AlarmActivity]'s Snooze can re-arm an alarm in-process (it has
     *  a Context, not a MethodChannel). The channel handler routes here too. */
    fun schedule(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        alarmId: String?,
        appAlarmId: String?,
        label: String?,
        source: Int,
        uri: String?,
        vibrate: Boolean,
        bundledResource: String?,
        snoozeMinutes: Int,
        displayTime: String? = null,
        body: String? = null,
        requiresShake: Boolean = false,
    ) = scheduleExactAlarm(
        context, id, triggerAtMillis, alarmId, appAlarmId, label, source, uri, vibrate,
        bundledResource, snoozeMinutes, displayTime, body, requiresShake,
    )

    /** Schedules (or replaces) one exact alarm. `setAlarmClock` is the
     *  highest-priority AlarmManager tier: exact, Doze-exempt, surfaced on the
     *  lock-screen alarm icon — and it needs NO SCHEDULE_EXACT_ALARM grant. The
     *  fire PendingIntent targets [AlarmReceiver] explicitly; FLAG_UPDATE_CURRENT
     *  keyed on [id] means re-scheduling the same id replaces it (and refreshes
     *  its sound/label extras), satisfying the AlarmScheduler replace-by-id
     *  contract. */
    private fun scheduleExactAlarm(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        alarmId: String?,
        appAlarmId: String?,
        label: String?,
        source: Int,
        uri: String?,
        vibrate: Boolean,
        bundledResource: String?,
        snoozeMinutes: Int,
        displayTime: String?,
        body: String?,
        requiresShake: Boolean,
    ) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val fireIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_FIRE
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_APP_ALARM_ID, appAlarmId)
            putExtra(AlarmReceiver.EXTRA_LABEL, label)
            // Critical-shift wake mechanics — AlarmActivity requires a shake to
            // dismiss (and hides the slide handle) when true; normal slide when
            // false. Sourced from the alarm's `isCritical` flag on the Dart side.
            putExtra(AlarmReceiver.EXTRA_REQUIRES_SHAKE, requiresShake)
            // Notification detail: the 12-hour ring time + the short shift
            // context. AlarmReceiver composes these into the alarm notification's
            // title/text and forwards them to AlarmAudioService.
            putExtra(AlarmReceiver.EXTRA_DISPLAY_TIME, displayTime)
            putExtra(AlarmReceiver.EXTRA_BODY, body)
            // The notification id, also carried as an extra (the requestCode
            // alone isn't readable at fire time) so AlarmActivity's Snooze can
            // re-arm this exact id.
            putExtra(AlarmReceiver.EXTRA_NOTIFICATION_ID, id)
            // The user's snooze interval, so AlarmActivity re-arms at the right
            // offset (read from Hive at schedule time, on the Dart side).
            putExtra(AlarmReceiver.EXTRA_SNOOZE_MINUTES, snoozeMinutes)
            // Sound routing — same keys AlarmAudioService/AlarmAudioEngine read.
            putExtra(AlarmAudioService.EXTRA_SOURCE, source)
            putExtra(AlarmAudioService.EXTRA_URI, uri)
            putExtra(AlarmAudioService.EXTRA_VIBRATE, vibrate)
            putExtra(AlarmAudioService.EXTRA_BUNDLED_RESOURCE, bundledResource)
        }
        val firePi = PendingIntent.getBroadcast(
            context,
            id,
            fireIntent,
            pendingIntentFlags(PendingIntent.FLAG_UPDATE_CURRENT),
        )
        // Tapping the lock-screen alarm icon opens the app.
        val showPi = PendingIntent.getActivity(
            context,
            id,
            Intent(context, MainActivity::class.java),
            pendingIntentFlags(PendingIntent.FLAG_UPDATE_CURRENT),
        )
        am.setAlarmClock(AlarmManager.AlarmClockInfo(triggerAtMillis, showPi), firePi)
        Log.d(TAG, "setExactAlarm id=$id at=$triggerAtMillis alarmId=$alarmId")
    }

    /** Cancels a previously-scheduled exact alarm. Rebuilds a PendingIntent that
     *  filter-matches the scheduled one (same id + component + action; extras are
     *  ignored by PendingIntent equality) with FLAG_NO_CREATE — a null result
     *  means nothing is pending, so the cancel is a clean no-op. */
    private fun cancelExactAlarm(context: Context, id: Int) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val fireIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_FIRE
        }
        val firePi = PendingIntent.getBroadcast(
            context,
            id,
            fireIntent,
            pendingIntentFlags(PendingIntent.FLAG_NO_CREATE),
        )
        if (firePi != null) {
            am.cancel(firePi)
            firePi.cancel()
            Log.d(TAG, "cancelAlarm id=$id")
        } else {
            Log.d(TAG, "cancelAlarm id=$id — no pending alarm to cancel")
        }
    }

    /** Adds the FLAG_IMMUTABLE bit (required on S+) to [base] PendingIntent flags. */
    private fun pendingIntentFlags(base: Int): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            base or PendingIntent.FLAG_IMMUTABLE
        } else {
            base
        }
}
