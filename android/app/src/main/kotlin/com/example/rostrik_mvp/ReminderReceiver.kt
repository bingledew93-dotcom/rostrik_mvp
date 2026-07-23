package com.example.rostrik_mvp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * The component `AlarmManager` dispatches to when an ACTIVITY REMINDER fires.
 *
 * This is the entire delivery surface for the Phase-3 "optional reminders"
 * feature, and it is deliberately kept as far as possible from the shift-alarm
 * fire chain ([AlarmReceiver] → [AlarmAudioService] → [AlarmActivity]):
 *   * a PLAIN notification on its own low-key channel ([CHANNEL_ID]) — no
 *     full-screen intent, no wake activity, no foreground audio service, no
 *     WakeLock;
 *   * `IMPORTANCE_DEFAULT`, `autoCancel`, `CATEGORY_REMINDER` — it behaves like
 *     any calendar-app nudge and can be swiped away;
 *   * tapping it just opens the app ([MainActivity]).
 *
 * A bug here can post a stray notification at worst; it can never touch the
 * shift-alarm reliability path. `exported="false"` + an explicit PendingIntent
 * means no other app can spoof a reminder.
 */
class ReminderReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "RostrikReminder"

        const val ACTION_REMINDER_FIRE =
            "com.example.rostrik_mvp.action.REMINDER_FIRE"

        // Intent extras (set by ActivityReminderScheduling).
        const val EXTRA_ID = "id"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"

        // Dedicated LOW-KEY notification channel — completely separate from the
        // shift-alarm channel. Default importance makes a normal notification
        // sound/peek without hijacking the screen.
        private const val CHANNEL_ID = "rostrik_activity_reminders"
        private const val CHANNEL_NAME = "Reminders"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != null && intent.action != ACTION_REMINDER_FIRE) {
            Log.w(TAG, "ignoring unexpected action: ${intent.action}")
            return
        }
        val id = intent.getIntExtra(EXTRA_ID, -1)
        val title = intent.getStringExtra(EXTRA_TITLE)?.takeIf { it.isNotBlank() }
            ?: "Reminder"
        val body = intent.getStringExtra(EXTRA_BODY)?.takeIf { it.isNotBlank() }
            ?: ""
        Log.d(TAG, "reminder fired id=$id title=$title")

        ensureChannel(context)

        // Tapping the reminder just opens the app.
        val openIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        var piFlags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            piFlags = piFlags or PendingIntent.FLAG_IMMUTABLE
        }
        val contentPi = PendingIntent.getActivity(
            context,
            if (id >= 0) id else 0,
            openIntent,
            piFlags,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val notification = builder
            .setContentTitle(title)
            .apply { if (body.isNotEmpty()) setContentText(body) }
            .setSmallIcon(R.drawable.ic_stat_alarm)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(contentPi)
            .build()

        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        mgr.notify(if (id >= 0) id else 0, notification)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        if (mgr.getNotificationChannel(CHANNEL_ID) != null) return
        // IMPORTANCE_DEFAULT: a normal, dismissible reminder — makes a sound and
        // may peek, but never takes over the screen the way the alarm channel
        // (IMPORTANCE_HIGH + full-screen intent) does. No DND bypass: a reminder
        // must respect Do-Not-Disturb, unlike a shift alarm.
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Optional nudges for calendar events, tasks and birthdays."
        }
        mgr.createNotificationChannel(channel)
    }
}
