package com.gdelataillade.alarm.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import com.gdelataillade.alarm.services.NotificationHandler

/**
 * DAWNBOX CHANGE: receives the alarm notification's second button
 * ("Surprise me" / "Play some songs"). Android doesn't let a notification
 * button open an app on the lock screen without unlocking, and doesn't let
 * a receiver open an activity directly, so this posts a full-screen
 * notification that opens Dawnbox over the lock screen at once. The alarm
 * keeps ringing until Dawnbox takes over (it stops it right away).
 */
class DawnboxActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", 0)
        val handler = NotificationHandler(context)
        // With "Display over other apps" allowed, open Dawnbox directly.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)) {
            try {
                handler.dawnboxActivityIntent(id, "button")?.let { context.startActivity(it) }
            } catch (_: Exception) {
            }
        }
        // Always also the full-screen notification, in case Android blocked that.
        handler.postDawnboxLaunch(id, intent.getStringExtra("title"))
    }
}
