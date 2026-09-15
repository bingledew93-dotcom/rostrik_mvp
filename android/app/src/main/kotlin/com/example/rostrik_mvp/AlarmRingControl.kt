package com.example.rostrik_mvp

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * The two ways a user ends a ringing alarm — dismiss and snooze — shared by the
 * full-screen [AlarmActivity] and the notification's action buttons
 * ([AlarmActionReceiver]), so both leave the audio, the notification, the OS
 * alarm set and the Dart ledgers in exactly the same state.
 *
 * Neither path touches Hive. The ledgers below are the process-death-proof
 * hand-off the Flutter side already trusts: it drains them on resume, on boot,
 * and when nudged via [NativeAlarmScheduling.notifyLedgersChanged].
 */
object AlarmRingControl {
    private const val TAG = "RostrikAlarm"

    // The dismissal fail-safe ledger. MUST equal
    // MainActivity.PENDING_DISMISSALS_FILE and `pendingDismissalsFileName`
    // in lib/alarms/pending_dismissal_guard.dart. Appending an id here is
    // how native code reports "alarm dismissed" back to Dart: the app's
    // boot/foreground gate reads + replays the ledger into Hive, so the
    // dismissal survives even if our process is reaped right after.
    private const val PENDING_DISMISSALS_FILE = "pending_dismissals"

    // The snooze fail-safe ledger — one `<shiftId>|<appAlarmId>|<untilMillis>`
    // line per snooze. MUST equal `pendingSnoozesFileName` in
    // lib/alarms/pending_snooze_guard.dart. Dart reads it on resume/boot and
    // sets `Shift.snoozedUntil` BEFORE its reconcile, so the reconcile keeps
    // (not cancels) the alarm a snooze just re-armed.
    private const val PENDING_SNOOZES_FILE = "pending_snoozes"

    // The fired-one-time cleanup ledger — one owning `<appAlarmId>` per line.
    // MUST equal `pendingAlarmDeletesFileName` in
    // lib/alarms/pending_alarm_delete_guard.dart. Dart deletes the id BEFORE
    // its reconcile iff it's a one-time rule (so a spent one-shot can't
    // re-project into a daily cycle). Recurring alarms are recorded too but
    // Dart no-ops them.
    private const val PENDING_ALARM_DELETES_FILE = "pending_alarm_deletes"

    // Mirrors `noShiftPayloadSentinel` in lib/alarms/alarm_sync_service.dart:
    // the shift id carried by shift-less (one-time/weekly) alarms.
    private const val NO_SHIFT_SENTINEL = "NONE"

    // Defensive fallback when the snooze-interval extra is absent (e.g. an
    // alarm armed by an older build). The live value rides the fire intent,
    // read from the user's `snooze_duration` setting on the Dart side.
    const val DEFAULT_SNOOZE_MINUTES = 1

    /** Everything needed to end, or re-arm, one ringing alarm. Travels as the
     *  same intent extras the Dart scheduler stamps on the fire intent. */
    data class Ring(
        val alarmId: String?,
        val appAlarmId: String?,
        val notificationId: Int,
        val label: String,
        val contextText: String?,
        val requiresShake: Boolean,
        val snoozeMinutes: Int,
        val source: Int,
        val uri: String?,
        val vibrate: Boolean,
        val bundledResource: String?,
    ) {
        /** Copies this ring onto [intent] under the fire-intent extra keys. */
        fun writeTo(intent: Intent): Intent = intent.apply {
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_APP_ALARM_ID, appAlarmId)
            putExtra(AlarmReceiver.EXTRA_NOTIFICATION_ID, notificationId)
            putExtra(AlarmReceiver.EXTRA_LABEL, label)
            putExtra(AlarmReceiver.EXTRA_BODY, contextText)
            putExtra(AlarmReceiver.EXTRA_REQUIRES_SHAKE, requiresShake)
            putExtra(AlarmReceiver.EXTRA_SNOOZE_MINUTES, snoozeMinutes)
            putExtra(AlarmAudioService.EXTRA_SOURCE, source)
            putExtra(AlarmAudioService.EXTRA_URI, uri)
            putExtra(AlarmAudioService.EXTRA_VIBRATE, vibrate)
            putExtra(AlarmAudioService.EXTRA_BUNDLED_RESOURCE, bundledResource)
        }

        companion object {
            /** Reads a ring off [intent]. A missing extra keeps [previous]'s
             *  value — how [AlarmActivity.onNewIntent] adopts a re-fire — or
             *  falls back to the fire intent's defaults. */
            fun from(intent: Intent, previous: Ring? = null): Ring = Ring(
                alarmId = intent.getStringExtra(AlarmReceiver.EXTRA_ALARM_ID)
                    ?: previous?.alarmId,
                appAlarmId = intent.getStringExtra(AlarmReceiver.EXTRA_APP_ALARM_ID)
                    ?: previous?.appAlarmId,
                notificationId = intent.getIntExtra(
                    AlarmReceiver.EXTRA_NOTIFICATION_ID,
                    previous?.notificationId ?: -1,
                ),
                label = intent.getStringExtra(AlarmReceiver.EXTRA_LABEL)
                    ?: previous?.label ?: "Alarm",
                contextText = intent.getStringExtra(AlarmReceiver.EXTRA_BODY)
                    ?: previous?.contextText,
                requiresShake = intent.getBooleanExtra(
                    AlarmReceiver.EXTRA_REQUIRES_SHAKE,
                    previous?.requiresShake ?: false,
                ),
                snoozeMinutes = intent.getIntExtra(
                    AlarmReceiver.EXTRA_SNOOZE_MINUTES,
                    previous?.snoozeMinutes ?: DEFAULT_SNOOZE_MINUTES,
                ),
                source = intent.getIntExtra(
                    AlarmAudioService.EXTRA_SOURCE,
                    previous?.source ?: AlarmAudioEngine.SOURCE_CLASSIC,
                ),
                uri = intent.getStringExtra(AlarmAudioService.EXTRA_URI) ?: previous?.uri,
                vibrate = intent.getBooleanExtra(
                    AlarmAudioService.EXTRA_VIBRATE,
                    previous?.vibrate ?: false,
                ),
                bundledResource = intent.getStringExtra(AlarmAudioService.EXTRA_BUNDLED_RESOURCE)
                    ?: previous?.bundledResource,
            )
        }
    }

    /** Ends [ring] for good: silence it, clear its notification, and record the
     *  dismissal and the fired rule for Dart. */
    fun dismiss(context: Context, ring: Ring, reason: String) {
        Log.d(TAG, "dismiss via '$reason' (id=${ring.alarmId})")

        // 1. Stop the looping audio — only if it is THIS alarm's. stopService
        //    routes to the service's onDestroy → AlarmAudioEngine.stop() (audio
        //    + haptics), and removes the ring notification the service holds in
        //    the foreground.
        val sounding = isSounding(ring)
        if (sounding) context.stopService(Intent(context, AlarmAudioService::class.java))

        // 2. Cancel the ring notification too — it is not service-owned when
        //    another alarm superseded this one mid-ring.
        cancelNotification(context, ring)

        // 3. Report success to the Dart layer durably. Appending
        //    `<shiftId>|<appAlarmId>` to the native ledger is the
        //    process-death-proof callback the app already trusts
        //    (MainActivity.readPendingDismissals + the Dart boot gate replay it
        //    into Hive). The appAlarmId scopes the dismissal to THIS ring —
        //    Dart records it per-occurrence so the shift's other alarms keep
        //    firing. No need to spin up Flutter at 3am.
        recordDismissal(context, ring.alarmId, ring.appAlarmId)

        // 3b. Record the fired rule so Dart can delete a spent ONE-TIME alarm
        //     before its next reconcile re-projects it into a daily cycle.
        recordPendingAlarmDelete(context, ring.appAlarmId)

        // 3c. Take it out of the boot re-arm store, so a reboot or app update in
        //     the next half hour does not ring it again as "missed".
        NativeAlarmScheduling.forgetEndedRing(context, ring.notificationId)

        // 4. Release the WakeLock AlarmReceiver took at fire time — it belongs
        //    to the alarm that is ringing.
        if (sounding) AlarmReceiver.releaseWakeLock()
    }

    /** Whether [ring] is the alarm whose audio is playing. Also true when that
     *  cannot be told apart — nothing playing, or a ring without an id — so
     *  those cases keep stopping everything, as before.
     *
     *  False for an alarm a newer one superseded mid-ring: its notification
     *  stays in the shade (audit F4), and ending it from there must leave the
     *  newer ring going. Found on a Pixel 2026-09-15 with two alarms 7 minutes
     *  apart: dismissing the older one silenced the newer and dropped its
     *  notification unrecorded — and had the newer been a critical shift, one
     *  tap would have ended it without the shake. */
    private fun isSounding(ring: Ring): Boolean {
        val playing = AlarmAudioService.ringingNotificationId ?: return true
        return playing < 0 || ring.notificationId < 0 || playing == ring.notificationId
    }

    /** Snooze: re-arm the SAME alarm at the configured offset, record it for
     *  Dart, and stand the ring down.
     *
     *  Reusing [Ring.notificationId] is the crux of conflict-free reconciliation
     *  — that id is already in Dart's NativeAlarmScheduler ledger, so a later
     *  reconcile either REPLACES this alarm in place (same-day → projection
     *  computes the same id, FLAG_UPDATE_CURRENT) or CANCELS it and re-schedules
     *  at the identical instant (cross-midnight → projection's new id; this id
     *  becomes a ledger orphan). Either way the user gets exactly one alarm at
     *  the snooze instant. The `pending_snoozes` entry is what makes Dart set
     *  `snoozedUntil` BEFORE that reconcile, so the reconcile keeps the alarm
     *  instead of seeing an unacknowledged shift with no future ring and
     *  cancelling it. */
    fun snooze(context: Context, ring: Ring) {
        val minutes = if (ring.snoozeMinutes > 0) ring.snoozeMinutes else DEFAULT_SNOOZE_MINUTES
        val snoozeUntil = System.currentTimeMillis() + minutes * 60L * 1000L
        Log.d(TAG, "snooze id=${ring.notificationId} alarmId=${ring.alarmId} mins=$minutes until=$snoozeUntil")

        // 1. Re-arm the SAME notification id at the user's snooze offset, with the
        //    same tone, and carrying the snooze interval forward for the next tap.
        //    Re-stamp the display time to the SNOOZE instant so the next
        //    notification shows when it will actually ring; keep the shift
        //    context as-is.
        if (ring.notificationId >= 0) {
            val armed = NativeAlarmScheduling.schedule(
                context.applicationContext,
                id = ring.notificationId,
                triggerAtMillis = snoozeUntil,
                alarmId = ring.alarmId,
                appAlarmId = ring.appAlarmId,
                label = ring.label,
                source = ring.source,
                uri = ring.uri,
                vibrate = ring.vibrate,
                bundledResource = ring.bundledResource,
                snoozeMinutes = minutes,
                displayTime = formatClock12h(snoozeUntil),
                body = ring.contextText,
                requiresShake = ring.requiresShake,
            )
            if (!armed) {
                // Android 12/12L with the exact-alarm permission revoked: the
                // re-arm was refused (schedule() never throws — an uncaught
                // SecurityException here would crash on a snooze tap). The
                // snooze ledger below still records intent; Dart's reconcile
                // re-arms once permission returns.
                Log.w(TAG, "snooze: exact-alarm refused — snooze not re-armed natively")
            }
        } else {
            Log.w(TAG, "snooze: missing notification id — cannot re-arm natively")
        }

        // 2. Record the snooze so Dart sets `snoozedUntil` (shift) or the one-off
        //    snooze map (shift-less 'NONE', keyed by appAlarmId).
        recordSnooze(context, ring.alarmId, ring.appAlarmId, snoozeUntil)

        // 3. Stand down exactly like a dismiss — stop audio, cancel the
        //    notification, release the WakeLock. (stopService cancels the
        //    15-min auto-timeout via the service's onDestroy.) Snoozing an
        //    alarm that a newer one superseded leaves the newer ring going.
        val sounding = isSounding(ring)
        if (sounding) context.stopService(Intent(context, AlarmAudioService::class.java))
        cancelNotification(context, ring)
        if (sounding) AlarmReceiver.releaseWakeLock()
    }

    /** Formats [millis] as a 12-hour `hh:mm AM/PM` clock string for the snooze
     *  re-arm's notification — mirrors the Dart side's `_formatClock12h` so a
     *  snoozed alarm's notification reads identically to a freshly-scheduled one
     *  ("03:05 AM"). */
    private fun formatClock12h(millis: Long): String =
        SimpleDateFormat("hh:mm a", Locale.getDefault()).format(Date(millis))

    private fun cancelNotification(context: Context, ring: Ring) {
        try {
            val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            // Per-alarm id (audit F4) — cancel THIS ring's notification only;
            // a superseded sibling's stays until it is handled. Fallback for
            // legacy intents without the id extra.
            mgr.cancel(if (ring.notificationId >= 0) ring.notificationId else AlarmReceiver.NOTIF_ID)
        } catch (e: Exception) {
            Log.w(TAG, "notification cancel failed", e)
        }
    }

    /** Append `<shiftId>|<appAlarmId>|<untilMillis>` to the snooze ledger,
     *  flushed + fsync'd so it survives an immediate reap. Dart uses shiftId for
     *  shift-based alarms (→ `Shift.snoozedUntil`) and appAlarmId for shift-less
     *  'NONE' alarms (→ the one-off snooze map). Skips a record with neither id. */
    private fun recordSnooze(context: Context, shiftId: String?, appAlarmId: String?, untilMillis: Long) {
        val shift = shiftId ?: ""
        val app = appAlarmId ?: ""
        if (shift.isEmpty() && app.isEmpty()) return
        appendLine(context, PENDING_SNOOZES_FILE, "$shift|$app|$untilMillis", "snooze")
    }

    /** Append `<shiftId>|<appAlarmId>` to the dismissal ledger. The appAlarmId
     *  is what lets Dart resolve the dismissal to ONE ring (a shift can carry
     *  several alarms; dismissing the first must never disarm the rest). When
     *  it is absent (a fire intent armed by an older build) the bare shiftId
     *  is written and Dart falls back to the legacy whole-shift ack. De-dup is
     *  the reader's job (a double-tap appends twice; the Hive replay acks
     *  once).
     *
     *  Shift-less alarms (`NONE`) are skipped, as the Dart writer and the
     *  service's auto-timeout already do: there is no shift row to acknowledge,
     *  the Dart reader drops such lines, and a ledger holding only those is
     *  never cleared — so they used to pile up. The spent one-time rule is
     *  still retired through the alarm-deletes ledger. */
    private fun recordDismissal(context: Context, shiftId: String?, appAlarmId: String?) {
        if (shiftId.isNullOrEmpty() || shiftId == NO_SHIFT_SENTINEL) return
        val line = if (appAlarmId.isNullOrEmpty()) shiftId else "$shiftId|$appAlarmId"
        appendLine(context, PENDING_DISMISSALS_FILE, line, "dismissal")
    }

    /** Append the fired alarm's owning [appAlarmId] to the cleanup ledger. Dart
     *  resolves each id to its AppAlarm on the next drain and deletes the
     *  ONE-TIME ones (recurring rules are a no-op there). Skips an empty id. */
    private fun recordPendingAlarmDelete(context: Context, appAlarmId: String?) {
        if (appAlarmId.isNullOrEmpty()) return
        appendLine(context, PENDING_ALARM_DELETES_FILE, appAlarmId, "pending alarm-delete")
    }

    /** Appends [line] to the ledger [fileName], flushed + fsync'd — the whole
     *  point of the fail-safe is surviving the OS reaping us immediately after. */
    private fun appendLine(context: Context, fileName: String, line: String, what: String) {
        try {
            val file = File(context.filesDir, fileName)
            FileOutputStream(file, /* append = */ true).use { out ->
                out.write((line + "\n").toByteArray(Charsets.UTF_8))
                out.flush()
                out.fd.sync()
            }
            Log.d(TAG, "recorded $what $line")
        } catch (e: Exception) {
            Log.w(TAG, "record $what failed for $line", e)
        }
    }
}
