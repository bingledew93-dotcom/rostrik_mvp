package com.example.rostrik_mvp

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

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
    private const val METHOD_CAN_SCHEDULE_EXACT = "canScheduleExactAlarms"
    private const val METHOD_GET_ALIVE_ALARM_IDS = "getAliveAlarmIds"

    // ---- Native boot re-arm store (Pixel 9 XL field bug #2) ----------------
    // Every armed alarm's full fire payload, persisted in DEVICE-PROTECTED
    // storage so [BootReceiver] can re-arm DIRECTLY in Kotlin — before first
    // unlock, with no WorkManager and no Flutter engine on the critical path.
    // Reboots erase every AlarmManager alarm; the previous recovery (boot →
    // WorkManager → headless Dart reconcile) died silently on FBE devices:
    // LOCKED_BOOT_COMPLETED starts the process in direct-boot mode where
    // WorkManager's initializer can't run (its DB is credential-encrypted),
    // and the post-unlock BOOT_COMPLETED lands in that same broken process.
    // A real alarm clock re-arms natively in milliseconds; the Dart reconcile
    // then converges Hive truth whenever it next runs.
    private const val STORE_PREFS = "rostrik_alarm_store"

    /** Grace for alarms whose instant passed while the device was off /
     *  rebooting: anything this recent still fires (a few seconds out) rather
     *  than being dropped — for a shift worker, a late wake-up beats a
     *  no-show. Older entries are pruned. */
    private const val BOOT_REARM_GRACE_MS = 30L * 60L * 1000L

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
                        val armed = scheduleExactAlarm(
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
                        if (armed) {
                            result.success(null)
                        } else {
                            // Surface the refusal instead of pretending success:
                            // the Dart scheduler must NOT record this id in its
                            // ledger, or the reconciler would believe the alarm
                            // is armed and never retry once the permission is
                            // restored. Error code is part of the wire contract
                            // with NativeAlarmScheduler.scheduleAt.
                            result.error(
                                "EXACT_ALARM_DENIED",
                                "exact-alarm permission revoked — alarm $id not armed",
                                null,
                            )
                        }
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
                // The AUTHORITATIVE exact-alarm capability check for the
                // Dashboard's reliability banner. Asks AlarmManager directly —
                // NOT permission_handler, whose status lookup resolves the
                // SCHEDULE_EXACT_ALARM group via the MANIFEST declaration and
                // reports a false "denied" on 13+ now that the manifest caps
                // that permission at maxSdkVersion=32 (USE_EXACT_ALARM, which
                // actually grants exactness there, never enters its lookup).
                METHOD_CAN_SCHEDULE_EXACT -> {
                    result.success(canScheduleExactAlarms(appContext))
                }
                // Ledger VALIDATION (Pixel 9 XL field bug): AlarmManager can't
                // be enumerated, but the fire PendingIntents CAN be probed with
                // FLAG_NO_CREATE — and the events that silently wipe an app's
                // alarms (force-stop, reboot, OEM cleaners) wipe its
                // PendingIntents too. Filtering the Dart ledger's ids down to
                // the ones whose PI still exists gives the reconciler REAL OS
                // truth, so wiped alarms read as "not pending" and get
                // re-armed instead of being trusted as phantoms forever.
                METHOD_GET_ALIVE_ALARM_IDS -> {
                    val ids = call.argument<List<Number>>("ids")
                    if (ids == null) {
                        result.error("BAD_ARGS", "ids is required", null)
                    } else {
                        result.success(
                            ids.map { it.toInt() }.filter { isAlarmAlive(appContext, it) },
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
        return channel
    }

    /** Public so [AlarmActivity]'s Snooze can re-arm an alarm in-process (it has
     *  a Context, not a MethodChannel). The channel handler routes here too.
     *  Returns whether the alarm was actually armed — false when the exact-alarm
     *  permission has been revoked (see [scheduleExactAlarm]); never throws. */
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
     *  lock-screen alarm icon. The fire PendingIntent targets [AlarmReceiver]
     *  explicitly; FLAG_UPDATE_CURRENT keyed on [id] means re-scheduling the
     *  same id replaces it (and refreshes its sound/label extras), satisfying
     *  the AlarmScheduler replace-by-id contract.
     *
     *  PERMISSIONS: on Android 13+ the manifest's USE_EXACT_ALARM (install-time,
     *  non-revocable for alarm-clock apps) covers `setAlarmClock`. On Android
     *  12/12L only SCHEDULE_EXACT_ALARM exists, is pre-granted, and the user CAN
     *  revoke it via Settings → "Alarms & reminders" — after which
     *  `setAlarmClock` throws SecurityException. That throw must never escape:
     *  uncaught it aborts the Dart boot sync mid-`main()` (app stuck on splash)
     *  or crashes [AlarmActivity]'s in-process snooze re-arm. Returns false on
     *  refusal so callers can report an honest failure instead of recording a
     *  phantom alarm. */
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
    ): Boolean {
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
        return try {
            am.setAlarmClock(AlarmManager.AlarmClockInfo(triggerAtMillis, showPi), firePi)
            Log.d(TAG, "setExactAlarm id=$id at=$triggerAtMillis alarmId=$alarmId")
            // Persist the full fire payload for the boot re-arm (only on a
            // SUCCESSFUL arm — a refused alarm must not resurrect at boot).
            storeAlarm(
                context, id, triggerAtMillis, alarmId, appAlarmId, label, source,
                uri, vibrate, bundledResource, snoozeMinutes, displayTime, body,
                requiresShake,
            )
            true
        } catch (e: SecurityException) {
            // Android 12/12L with "Alarms & reminders" revoked. Loud but
            // non-fatal — the caller reports the refusal to Dart, whose ledger
            // then stays honest and re-issues on the reconcile after re-grant.
            Log.e(TAG, "setAlarmClock refused (exact-alarm permission revoked) id=$id", e)
            false
        }
    }

    /** Re-arms every stored alarm straight from the device-protected store —
     *  the boot-recovery path that needs NO WorkManager and NO Flutter engine,
     *  and runs even BEFORE first unlock (LOCKED_BOOT_COMPLETED). Future
     *  entries re-arm at their original instant; entries missed within
     *  [BOOT_REARM_GRACE_MS] (the reboot happened across their fire time)
     *  re-arm a few seconds out so the user still gets woken, late beats
     *  never; older entries are pruned. Returns how many alarms were armed.
     *  The Dart reconcile converges Hive truth whenever it next runs — its
     *  ledger validation sees these re-armed PendingIntents as alive. */
    fun rearmFromStore(context: Context): Int {
        val prefs = storePrefs(context)
        val now = System.currentTimeMillis()
        var armed = 0
        val doomed = mutableListOf<String>()
        for ((key, value) in prefs.all) {
            val id = key.toIntOrNull()
            val raw = value as? String
            if (id == null || raw == null) {
                doomed.add(key)
                continue
            }
            try {
                val json = JSONObject(raw)
                var at = json.getLong("at")
                if (at <= now) {
                    if (now - at > BOOT_REARM_GRACE_MS) {
                        doomed.add(key) // long past — spent; prune
                        continue
                    }
                    at = now + 5_000L // missed across the reboot — ring now-ish
                }
                val ok = scheduleExactAlarm(
                    context,
                    id = id,
                    triggerAtMillis = at,
                    alarmId = json.optString("alarmId").ifEmpty { null },
                    appAlarmId = json.optString("appAlarmId").ifEmpty { null },
                    label = json.optString("label").ifEmpty { null },
                    source = json.optInt("source", AlarmAudioEngine.SOURCE_CLASSIC),
                    uri = json.optString("uri").ifEmpty { null },
                    vibrate = json.optBoolean("vibrate", false),
                    bundledResource = json.optString("bundledResource").ifEmpty { null },
                    snoozeMinutes = json.optInt("snoozeMinutes", 1),
                    displayTime = json.optString("displayTime").ifEmpty { null },
                    body = json.optString("body").ifEmpty { null },
                    requiresShake = json.optBoolean("requiresShake", false),
                )
                if (ok) armed++
            } catch (e: Exception) {
                Log.w(TAG, "boot re-arm: corrupt store entry $key — pruning", e)
                doomed.add(key)
            }
        }
        if (doomed.isNotEmpty()) {
            val editor = prefs.edit()
            doomed.forEach { editor.remove(it) }
            editor.apply()
        }
        Log.i(TAG, "boot re-arm: $armed alarm(s) re-armed, ${doomed.size} pruned")
        return armed
    }

    /** The boot re-arm store: DEVICE-PROTECTED (direct-boot) storage, so it is
     *  readable before first unlock — exactly when a rebooted phone needs its
     *  alarms back. Contents are alarm metadata only (times, labels, tone
     *  routing); nothing credential-grade lives here. */
    private fun storePrefs(context: Context): SharedPreferences =
        context.createDeviceProtectedStorageContext()
            .getSharedPreferences(STORE_PREFS, Context.MODE_PRIVATE)

    /** Persists one armed alarm's full fire payload, synchronously (`commit`) —
     *  the write must be durable the moment the alarm is armed, or a reboot in
     *  the gap loses it. */
    private fun storeAlarm(
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
        try {
            val json = JSONObject()
                .put("at", triggerAtMillis)
                .put("alarmId", alarmId ?: "")
                .put("appAlarmId", appAlarmId ?: "")
                .put("label", label ?: "")
                .put("source", source)
                .put("uri", uri ?: "")
                .put("vibrate", vibrate)
                .put("bundledResource", bundledResource ?: "")
                .put("snoozeMinutes", snoozeMinutes)
                .put("displayTime", displayTime ?: "")
                .put("body", body ?: "")
                .put("requiresShake", requiresShake)
            storePrefs(context).edit().putString(id.toString(), json.toString()).commit()
        } catch (e: Exception) {
            Log.w(TAG, "alarm store write failed id=$id (boot re-arm won't cover it)", e)
        }
    }

    private fun removeStoredAlarm(context: Context, id: Int) {
        try {
            storePrefs(context).edit().remove(id.toString()).commit()
        } catch (e: Exception) {
            Log.w(TAG, "alarm store remove failed id=$id", e)
        }
    }

    /** Whether the OS will accept `setAlarmClock` from this app right now.
     *  True below S (no exact-alarm permission concept); on S+ defers to
     *  [AlarmManager.canScheduleExactAlarms], which honours BOTH grant paths —
     *  the revocable SCHEDULE_EXACT_ALARM (12/12L) and the install-time
     *  USE_EXACT_ALARM (13+). */
    private fun canScheduleExactAlarms(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return am.canScheduleExactAlarms()
    }

    /** Whether the fire PendingIntent for [id] still exists in the system —
     *  the live-OS proxy for "is this alarm still armed". Same FLAG_NO_CREATE
     *  filter-match [cancelExactAlarm] uses. True for an alarm that already
     *  FIRED (the PI outlives delivery) — fine: the reconciler drops fired
     *  occurrences as past/not-desired anyway; this check only needs to catch
     *  wholesale wipes (force-stop / reboot / OEM cleaner), which destroy the
     *  PIs along with the alarms. */
    private fun isAlarmAlive(context: Context, id: Int): Boolean {
        val fireIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_FIRE
        }
        return PendingIntent.getBroadcast(
            context,
            id,
            fireIntent,
            pendingIntentFlags(PendingIntent.FLAG_NO_CREATE),
        ) != null
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
        // Either way the boot re-arm must forget it — a cancelled alarm
        // resurrecting after a reboot would be a phantom ring.
        removeStoredAlarm(context, id)
    }

    /** Adds the FLAG_IMMUTABLE bit (required on S+) to [base] PendingIntent flags.
     *
     *  IMMUTABLE + FLAG_UPDATE_CURRENT is deliberate and correct — do not "fix"
     *  it to FLAG_MUTABLE. Immutability only blocks the RECIPIENT from merging a
     *  fill-in Intent at send() time; it does NOT stop this app from refreshing
     *  the extras by re-creating the PendingIntent with UPDATE_CURRENT (the
     *  documented owner-side update path, and how every reschedule here refreshes
     *  sound/label/shake extras — verified live by the snooze re-arm, which
     *  re-stamps the display time on the SAME id). FLAG_MUTABLE would be a
     *  security downgrade with no functional gain. */
    private fun pendingIntentFlags(base: Int): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            base or PendingIntent.FLAG_IMMUTABLE
        } else {
            base
        }
}
