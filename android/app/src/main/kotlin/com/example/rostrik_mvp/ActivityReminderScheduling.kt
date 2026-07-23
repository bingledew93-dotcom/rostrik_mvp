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
 * Registration + implementation for the `rostrik/activity_reminders`
 * MethodChannel — the schedule/cancel bridge behind the Phase-3 "optional
 * reminders" feature.
 *
 * Kept intentionally minimal and SEPARATE from [NativeAlarmScheduling]:
 *   * arms an `AlarmManager` *AllowWhileIdle* alarm (NOT `setAlarmClock`) — a
 *     reminder is best-effort and must never consume the alarm-clock tier or
 *     the exact-alarm reliability budget the shift alarms depend on;
 *   * the fire `PendingIntent` targets [ReminderReceiver] with its own action,
 *     so it can't collide with a shift-alarm PendingIntent even at an equal
 *     request code;
 *   * no boot re-arm store — reminders re-arm from Hive on the next app launch
 *     (see `ActivityReminderService`); losing a birthday nudge across a reboot
 *     until the app is next opened is an acceptable trade for total isolation.
 *
 * Only registered on the foreground UI engine ([MainActivity]); the headless
 * boot engine schedules shift alarms only, never reminders.
 */
object ActivityReminderScheduling {
    private const val TAG = "RostrikReminder"

    const val CHANNEL = "rostrik/activity_reminders"
    private const val METHOD_SCHEDULE = "scheduleReminder"
    private const val METHOD_CANCEL = "cancelReminder"

    fun register(messenger: BinaryMessenger, context: Context): MethodChannel {
        val appContext = context.applicationContext
        val channel = MethodChannel(messenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_SCHEDULE -> {
                    val id = (call.argument<Number>("id"))?.toInt()
                    val triggerAtMillis =
                        (call.argument<Number>("triggerAtMillis"))?.toLong()
                    if (id == null || triggerAtMillis == null) {
                        result.error(
                            "BAD_ARGS",
                            "id and triggerAtMillis are required",
                            null,
                        )
                    } else {
                        scheduleReminder(
                            appContext,
                            id = id,
                            triggerAtMillis = triggerAtMillis,
                            title = call.argument<String>("title"),
                            body = call.argument<String>("body"),
                        )
                        result.success(null)
                    }
                }
                METHOD_CANCEL -> {
                    val id = (call.argument<Number>("id"))?.toInt()
                    if (id == null) {
                        result.error("BAD_ARGS", "id is required", null)
                    } else {
                        cancelReminder(appContext, id)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        return channel
    }

    private fun scheduleReminder(
        context: Context,
        id: Int,
        triggerAtMillis: Long,
        title: String?,
        body: String?,
    ) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // FLAG_UPDATE_CURRENT always creates → non-null; guard anyway so the
        // AllowWhileIdle calls below see a non-null PendingIntent.
        val pi = firePendingIntent(context, id, title, body, PendingIntent.FLAG_UPDATE_CURRENT)
            ?: run {
                Log.w(TAG, "scheduleReminder id=$id — null PendingIntent, skipping")
                return
            }
        try {
            // AllowWhileIdle punches through Doze so a reminder still arrives when
            // the phone has been idle overnight. EXACT when the exact-alarm
            // capability is available (punctual, e.g. a 9:00 meeting nudge); the
            // inexact fallback may drift a few minutes in deep Doze — fine for a
            // reminder, and it NEVER throws or needs a runtime permission.
            if (canScheduleExact(am)) {
                am.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pi,
                )
            } else {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
            }
            Log.d(TAG, "scheduleReminder id=$id at=$triggerAtMillis")
        } catch (e: SecurityException) {
            // Belt-and-braces: if an OEM revokes even the exact path unexpectedly,
            // fall back to inexact rather than crash. Reminders are best-effort.
            Log.w(TAG, "exact reminder refused id=$id — using inexact", e)
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
        }
    }

    private fun cancelReminder(context: Context, id: Int) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // Match-and-cancel: rebuild a filter-equal PendingIntent (extras are
        // ignored by PendingIntent equality) with NO_CREATE — null means nothing
        // is armed, so cancel is a clean no-op.
        val pi = firePendingIntent(context, id, null, null, PendingIntent.FLAG_NO_CREATE)
        if (pi != null) {
            am.cancel(pi)
            pi.cancel()
            Log.d(TAG, "cancelReminder id=$id")
        } else {
            Log.d(TAG, "cancelReminder id=$id — nothing armed")
        }
        // Also clear any already-posted notification for this reminder.
        try {
            (context.getSystemService(Context.NOTIFICATION_SERVICE)
                as android.app.NotificationManager).cancel(id)
        } catch (e: Exception) {
            Log.w(TAG, "reminder notification cancel failed id=$id", e)
        }
    }

    private fun firePendingIntent(
        context: Context,
        id: Int,
        title: String?,
        body: String?,
        baseFlags: Int,
    ): PendingIntent? {
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            action = ReminderReceiver.ACTION_REMINDER_FIRE
            putExtra(ReminderReceiver.EXTRA_ID, id)
            putExtra(ReminderReceiver.EXTRA_TITLE, title)
            putExtra(ReminderReceiver.EXTRA_BODY, body)
        }
        return PendingIntent.getBroadcast(context, id, intent, pendingIntentFlags(baseFlags))
    }

    /** True when the OS will honour an exact AllowWhileIdle alarm. Below S there
     *  is no exact-alarm gate; on S+ defer to [AlarmManager.canScheduleExactAlarms]. */
    private fun canScheduleExact(am: AlarmManager): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()

    private fun pendingIntentFlags(base: Int): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            base or PendingIntent.FLAG_IMMUTABLE
        } else {
            base
        }
}
