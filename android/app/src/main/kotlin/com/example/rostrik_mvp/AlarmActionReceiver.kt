package com.example.rostrik_mvp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Handles the Snooze and Dismiss buttons on the ringing alarm's notification.
 *
 * Those buttons are the way out when the full-screen [AlarmActivity] never
 * appears — the normal case when the phone is unlocked and in use, where Android
 * shows the alarm as a heads-up notification instead. Before them, that
 * notification offered nothing and the alarm rang until its 15-minute timeout
 * (field report 2026-08-30 on a Samsung; reproduced 2026-09-15 on a Pixel).
 *
 * Both buttons run the same [AlarmRingControl] tear-down as the alarm screen.
 * A critical-shift alarm is never offered Dismiss — its notification links to
 * the alarm screen instead, so ending it still takes the shake — and this
 * receiver refuses a Dismiss for one anyway.
 */
class AlarmActionReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "RostrikAlarm"

        const val ACTION_DISMISS = "com.example.rostrik_mvp.action.ALARM_NOTIFICATION_DISMISS"
        const val ACTION_SNOOZE = "com.example.rostrik_mvp.action.ALARM_NOTIFICATION_SNOOZE"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val ring = AlarmRingControl.Ring.from(intent)
        when (intent.action) {
            ACTION_DISMISS -> {
                if (ring.requiresShake) {
                    Log.w(TAG, "notification dismiss refused for a critical-shift alarm (id=${ring.alarmId})")
                    return
                }
                AlarmRingControl.dismiss(context, ring, "notification")
            }
            ACTION_SNOOZE -> AlarmRingControl.snooze(context, ring)
            else -> {
                Log.w(TAG, "ignoring unexpected action: ${intent.action}")
                return
            }
        }

        // Close the alarm screen if it is open behind the shade. It ignores a
        // broadcast carrying another alarm's notification id.
        context.sendBroadcast(
            Intent(AlarmAudioService.ACTION_AUTO_DISMISS)
                .setPackage(context.packageName)
                .putExtra(AlarmReceiver.EXTRA_NOTIFICATION_ID, ring.notificationId),
        )

        // No app resume follows a notification button, so a running app would
        // not drain the ledgers just written until the user next switched back
        // to it — leaving a spent one-time alarm to be re-projected meanwhile.
        NativeAlarmScheduling.notifyLedgersChanged()
    }
}
