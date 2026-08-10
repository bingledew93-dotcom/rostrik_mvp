package com.example.rostrik_mvp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget provider (Phase 2). Renders the glanceable "next shift"
 * card, tinted per shift type, and opens the app on tap.
 *
 * Data is written by the Flutter side (`WidgetService`) via
 * `HomeWidget.saveWidgetData`; [onUpdate] receives it as [widgetData] and only
 * maps it onto [RemoteViews] — it holds no roster logic of its own (the strings
 * are already fully formatted by the shared Dashboard hero builder).
 */
class RostrikWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        // Fallbacks cover the first paint before Flutter has ever run (a
        // freshly-added widget on a fresh install).
        val badge = widgetData.getString(KEY_BADGE, null) ?: "🛌 Off / RDO"
        val main = widgetData.getString(KEY_MAIN, null) ?: "No shifts yet"
        val accent = accentColor(widgetData.getString(KEY_SHIFT_TYPE, null))

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

    companion object {
        // Wire contract with WidgetService (lib/services/widget_service.dart).
        private const val KEY_BADGE = "hero_badge"
        private const val KEY_MAIN = "hero_main_text"
        private const val KEY_SHIFT_TYPE = "shift_type"
    }
}
