package com.example.rostrik_mvp

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

/**
 * Home-screen widget provider (Phase 2). Renders the glanceable "next shift"
 * card, tinted per shift type, and opens the app on tap.
 *
 * ## The widget renders itself; it is not painted by the app
 *
 * The original version was a pure mapper: Flutter's `WidgetService` computed
 * finished strings — `"Starts in 6d 1h"` — and this class copied them into
 * [RemoteViews]. That froze the widget. A countdown rendered against the app's
 * `now` is stale the moment the app is backgrounded, and the widget process
 * lives for days after; every subsequent redraw dutifully re-painted the same
 * dead value, so the card showed whatever was true the last time the user had
 * Rostrik open.
 *
 * Now Flutter writes a FORECAST instead (`hero_forecast`, see
 * `lib/services/widget_forecast.dart`): the hero's output sampled at every
 * instant it can change, as `[{from, to, badge, sub, type, main, cdTo, cdPre}]`.
 * This class picks the segment covering the current time and finishes the
 * render against its own clock. All roster logic stays in Dart — the only thing
 * duplicated here is duration formatting ([formatCountdown], a direct port of
 * `formatHeroCountdown`), because that is the one piece that must run at draw
 * time.
 *
 * ## Staying live
 *
 * A widget only redraws when something tells it to, so the provider schedules
 * its OWN next redraw ([scheduleTick]) every time it paints, at whichever comes
 * first: the end of the current segment (a shift starting or ending, or
 * midnight) or a cadence matched to how fast the text is moving. The alarm is
 * deliberately **inexact and non-waking** (`AlarmManager.set` with `RTC`, not
 * `RTC_WAKEUP`, and never `setAlarmClock`):
 *
 *   * it needs no permission, so the widget adds nothing to the app's
 *     Play-policy surface — in particular it does NOT lean on the
 *     `USE_EXACT_ALARM` capability, which is granted for the shift-alarm
 *     function and would be abused by spending it on cosmetics;
 *   * nobody is looking at the home screen while the device is dozing, and an
 *     overdue `RTC` alarm fires as soon as the device wakes, so the card is
 *     already correct by the time it is next seen.
 *
 * The `updatePeriodMillis` in `rostrik_widget_info.xml` remains as a coarse
 * backstop, and [BootReceiver] pokes [refresh] after a reboot or clock change
 * (a reboot clears every AlarmManager alarm, including our tick).
 *
 * ## Offline
 *
 * Entirely. The forecast is derived from the local Hive roster and read back
 * from SharedPreferences; no part of this path touches the network.
 */
class RostrikWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        render(context, appWidgetManager, appWidgetIds, widgetData)
    }

    /**
     * `super.onReceive` keeps [AppWidgetProvider][android.appwidget.AppWidgetProvider]'s
     * normal dispatch (APPWIDGET_UPDATE to [onUpdate], deletes, etc.); the extra
     * branch handles our own tick, which is delivered as an explicit broadcast
     * and so never reaches that dispatch.
     */
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TICK) refresh(context)
    }

    /** Last widget removed — stop the tick rather than leave it cycling forever. */
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelTick(context)
    }

    private fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        if (appWidgetIds.isEmpty()) {
            cancelTick(context)
            return
        }

        val now = System.currentTimeMillis()
        val segment = currentSegment(widgetData.getString(KEY_FORECAST, null), now)

        // Fallbacks, in order: the live forecast segment, then the rendered
        // snapshot the app also writes (covers the first paint after an install
        // or an app update, before Dart has pushed a forecast), then a static
        // empty state for a widget added on a fresh install.
        val badge = segment?.badge
            ?: widgetData.getString(KEY_BADGE, null)
            ?: "🛌 Off / RDO"
        val main = segment?.mainTextAt(now)
            ?: widgetData.getString(KEY_MAIN, null)
            ?: "No shifts yet"
        val accent = accentColor(segment?.shiftType ?: widgetData.getString(KEY_SHIFT_TYPE, null))

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.rostrik_widget)

            views.setTextViewText(R.id.widget_badge, badge)
            views.setTextViewText(R.id.widget_main, main)
            // Accent tint: the badge line + the left bar, matching the app's
            // per-shift-type colour coding.
            views.setTextColor(R.id.widget_badge, accent)
            views.setInt(R.id.widget_accent, "setBackgroundColor", accent)

            // Tap anywhere on the card → open Rostrik to the Dashboard.
            views.setOnClickPendingIntent(R.id.widget_root, launchAppIntent(context))

            appWidgetManager.updateAppWidget(widgetId, views)
        }

        scheduleTick(context, nextTickAt(now, segment))
    }

    /**
     * Tap target: open Rostrik exactly the way the home-screen ICON does.
     *
     * We deliberately DON'T use `HomeWidgetLaunchIntent` here. Its custom LAUNCH
     * action doesn't match MainActivity's ACTION_MAIN/CATEGORY_LAUNCHER task
     * root, so — with MainActivity's `taskAffinity=""` — every tap started a
     * SECOND MainActivity in a fresh task, spun up a new FlutterEngine, and
     * re-ran `main()`, which re-showed the legal-consent / onboarding gate: the
     * user had to re-accept the Terms on every single tap.
     *
     * The package launcher intent is the same one the launcher icon fires, so
     * Android brings the RUNNING task forward (no duplicate, no re-gate); on a
     * cold start it just opens normally, landing on the Dashboard (the default
     * tab). NEW_TASK is required to start an Activity from the widget's
     * (non-activity) context; RESET_TASK_IF_NEEDED mirrors launcher behaviour.
     */
    private fun launchAppIntent(context: Context): PendingIntent {
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED,
                )
            }
            ?: Intent(context, MainActivity::class.java)
                .apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }

        return PendingIntent.getActivity(
            context,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** App-palette accent per shift type, brightened for contrast on the near-
     *  black card (Day amber, Afternoon orange, Night indigo, Off/unknown grey). */
    private fun accentColor(shiftType: String?): Int = when (shiftType) {
        "day" -> Color.parseColor("#FFD54F")
        "afternoon" -> Color.parseColor("#FFB74D")
        "night" -> Color.parseColor("#7986CB")
        else -> Color.parseColor("#BDBDBD")
    }

    /** One window of the forecast. Mirrors `WidgetHeroSegment.toJson()` in Dart. */
    private data class Segment(
        val from: Long,
        val to: Long,
        val badge: String,
        val shiftType: String,
        val staticMain: String,
        val countdownTo: Long?,
        val countdownPrefix: String?,
    ) {
        /**
         * The big line, finished against [now]. Countdown segments recompute;
         * static ones (the rotation fallback and the empty state) are already
         * final.
         */
        fun mainTextAt(now: Long): String {
            val target = countdownTo
            val prefix = countdownPrefix
            if (target == null || prefix == null) return staticMain
            return "$prefix ${formatCountdown(target - now)}"
        }
    }

    /** Locates the window covering [now], or null if the forecast is missing,
     *  unparseable, or has run past its horizon. */
    private fun currentSegment(json: String?, now: Long): Segment? {
        if (json.isNullOrEmpty()) return null
        return try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val o = array.optJSONObject(i) ?: continue
                val from = o.optLong("from", -1L)
                val to = o.optLong("to", -1L)
                if (from < 0 || to < 0 || now < from || now >= to) continue
                return Segment(
                    from = from,
                    to = to,
                    badge = o.optString("badge"),
                    shiftType = o.optString("type"),
                    staticMain = o.optString("main"),
                    countdownTo = if (o.has("cdTo")) o.optLong("cdTo") else null,
                    countdownPrefix = if (o.has("cdPre")) o.optString("cdPre") else null,
                )
            }
            null
        } catch (e: Exception) {
            Log.w(TAG, "forecast parse failed", e)
            null
        }
    }

    /**
     * When to paint next: the earlier of this segment's end and a cadence
     * matched to the granularity the countdown is currently changing at.
     *
     * [formatCountdown] moves every minute below 24h and every hour above it,
     * so a fixed one-minute tick would burn wakeups for days to refresh a
     * readout of "6d 1h". The bands below keep the visible error small where it
     * matters — inside the last hour before a shift, the only window where a
     * shift worker is reading minutes off this card — and go quiet otherwise.
     * Segment ends are always honoured exactly, so the transitions that
     * actually matter (a shift starting or ending) are never late.
     */
    private fun nextTickAt(now: Long, segment: Segment?): Long {
        val remaining = segment?.countdownTo?.minus(now)
        val cadence = when {
            remaining == null -> HOUR_MS          // static segment: nothing moves
            remaining < HOUR_MS -> MINUTE_MS      // "23m" — minute by minute
            remaining < DAY_MS -> 15 * MINUTE_MS  // "5h 23m" — near enough
            else -> HOUR_MS                       // "6d 1h" — hour granularity
        }
        val segmentEnd = segment?.to ?: (now + HOUR_MS)
        // The floor stops a segment boundary that lands on (or just before)
        // `now` from scheduling a tick in the past and spinning.
        return maxOf(minOf(segmentEnd, now + cadence), now + MIN_TICK_MS)
    }

    private fun scheduleTick(context: Context, atMillis: Long) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        try {
            // Inexact and non-waking by design — see the class doc.
            alarms.set(AlarmManager.RTC, atMillis, tickIntent(context))
        } catch (e: Exception) {
            // Nothing here is load-bearing for alarms; a failed tick just means
            // the card waits for updatePeriodMillis or the next app resume.
            Log.w(TAG, "widget tick scheduling failed", e)
        }
    }

    private fun cancelTick(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        try {
            alarms.cancel(tickIntent(context))
        } catch (e: Exception) {
            Log.w(TAG, "widget tick cancel failed", e)
        }
    }

    /**
     * Explicit self-targeted broadcast, so no intent-filter is needed and no
     * other app can trigger it. IMMUTABLE|UPDATE_CURRENT matches the pattern
     * used across the alarm engine: we own the intent, and UPDATE_CURRENT
     * refreshes it in place so repeated scheduling reuses one slot.
     */
    private fun tickIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        TICK_REQUEST_CODE,
        Intent(context, RostrikWidgetProvider::class.java).setAction(ACTION_TICK),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    companion object {
        private const val TAG = "RostrikWidget"

        // Wire contract with WidgetService (lib/services/widget_service.dart).
        private const val KEY_BADGE = "hero_badge"
        private const val KEY_MAIN = "hero_main_text"
        private const val KEY_SHIFT_TYPE = "shift_type"
        private const val KEY_FORECAST = "hero_forecast"

        /** Our own redraw broadcast. Explicit — never registered in the manifest. */
        private const val ACTION_TICK = "com.rostrik.app.action.WIDGET_TICK"

        /** Fixed so every reschedule replaces the single outstanding tick. */
        private const val TICK_REQUEST_CODE = 9_100

        private const val MINUTE_MS = 60_000L
        private const val HOUR_MS = 60 * MINUTE_MS
        private const val DAY_MS = 24 * HOUR_MS

        /** Lower bound between ticks; see [nextTickAt]. */
        private const val MIN_TICK_MS = 30_000L

        /**
         * Direct port of `formatHeroCountdown` in `lib/ui/dashboard_hero.dart`
         * — "14h 22m" / "23m" / "3d 14h", always rounding DOWN. Keep the two in
         * lock-step: a divergence here shows up as the widget and the in-app
         * Hero Card disagreeing about the same shift.
         */
        internal fun formatCountdown(remainingMs: Long): String {
            if (remainingMs <= 0L) return "0m"
            val totalMinutes = remainingMs / MINUTE_MS
            if (totalMinutes < 60L) return "${totalMinutes}m"
            if (totalMinutes < 60L * 24L) {
                val h = totalMinutes / 60L
                val m = totalMinutes % 60L
                return if (m == 0L) "${h}h" else "${h}h ${m}m"
            }
            val days = totalMinutes / (60L * 24L)
            val hoursRem = (totalMinutes - days * 60L * 24L) / 60L
            return if (hoursRem == 0L) "${days}d" else "${days}d ${hoursRem}h"
        }

        /**
         * Repaints every placed widget immediately. Called by our own tick and
         * by [BootReceiver] after a reboot or clock change — a reboot wipes
         * every AlarmManager alarm, so without this poke the tick chain would
         * stay dead until `updatePeriodMillis` happened to come round.
         *
         * Safe to call when no widget is placed (it becomes a no-op that also
         * tidies up the tick) and safe to call before first unlock, where
         * reading the credential-encrypted SharedPreferences throws.
         */
        fun refresh(context: Context) {
            try {
                val manager = AppWidgetManager.getInstance(context) ?: return
                val ids = manager.getAppWidgetIds(
                    ComponentName(context, RostrikWidgetProvider::class.java),
                )
                // Route through the normal update path so the provider does its
                // own scheduling; an empty id set is handled inside render().
                RostrikWidgetProvider().render(
                    context,
                    manager,
                    ids,
                    HomeWidgetPlugin.getData(context),
                )
            } catch (e: Exception) {
                Log.w(TAG, "widget refresh failed", e)
            }
        }
    }
}
