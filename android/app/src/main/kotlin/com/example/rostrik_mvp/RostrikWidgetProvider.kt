package com.example.rostrik_mvp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget provider (Phase 2). Renders the glanceable "next shift"
 * card, tinted per shift type, and deep-links into the app on tap.
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
        val subtitle = widgetData.getString(KEY_SUBTITLE, null)
            ?: "Open Rostrik to set up your roster"
        val accent = accentColor(widgetData.getString(KEY_SHIFT_TYPE, null))

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.rostrik_widget)

            views.setTextViewText(R.id.widget_badge, badge)
            views.setTextViewText(R.id.widget_main, main)
            views.setTextViewText(R.id.widget_subtitle, subtitle)
            // Accent tint: the badge line + the left bar, matching the app's
            // per-shift-type colour coding.
            views.setTextColor(R.id.widget_badge, accent)
            views.setInt(R.id.widget_accent, "setBackgroundColor", accent)

            // Tap anywhere on the card → open Rostrik to the Dashboard. Routed
            // at MainActivity (singleTop + taskAffinity=""), so no duplicate task
            // or back-stack entry is created; the Flutter side reads the URI and
            // selects the Dashboard tab.
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse(DEEP_LINK_URI),
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
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
        private const val KEY_SUBTITLE = "hero_subtitle"
        private const val KEY_SHIFT_TYPE = "shift_type"

        private const val DEEP_LINK_URI = "rostrikwidget://dashboard"
    }
}
