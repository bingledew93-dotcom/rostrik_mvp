package com.example.rostrik_mvp

import android.app.NotificationChannel
import android.app.NotificationManager

/**
 * Brings an existing notification channel's name and description into the
 * current app language and returns true, or returns false when the channel does
 * not exist yet (the caller then creates it).
 *
 * Android keeps whatever labels a channel was first created with, so without
 * this a user who changes language — or who installed before the app was
 * translated — sees the channel names in Settings in the old language forever
 * (seen on a Pixel 2026-09-15: "Alarm playback" in a German app). Only the
 * labels change: for an existing channel Android ignores sound, vibration and
 * DND settings, and passing its current importance leaves that untouched.
 */
fun NotificationManager.relabelChannel(id: String, name: String, description: String): Boolean {
    val existing = getNotificationChannel(id) ?: return false
    if (existing.name == name && existing.description == description) return true
    createNotificationChannel(
        NotificationChannel(id, name, existing.importance).apply {
            this.description = description
        },
    )
    return true
}
