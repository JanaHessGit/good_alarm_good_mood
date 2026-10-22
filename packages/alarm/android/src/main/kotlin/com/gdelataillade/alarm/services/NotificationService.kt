package com.gdelataillade.alarm.services

import android.annotation.SuppressLint
import com.gdelataillade.alarm.models.NotificationSettings
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import com.gdelataillade.alarm.alarm.R
import androidx.core.app.NotificationCompat
import com.gdelataillade.alarm.alarm.AlarmReceiver
import com.gdelataillade.alarm.alarm.DawnboxActionReceiver

class NotificationHandler(private val context: Context) {
    companion object {
        private const val CHANNEL_ID = "alarm_plugin_channel"
        private const val CHANNEL_NAME = "Alarm Notification"
        // DAWNBOX CHANGE
        private const val DAWNBOX_CHANNEL_ID = "dawnbox_surprise_channel"
        const val DAWNBOX_LAUNCH_NOTIFICATION_ID = 4711
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setSound(null, null)
            }

            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    // Dismisses the alarm notification when no foreground service owns it
    // (a live service removes it via stopForeground(STOP_FOREGROUND_REMOVE)).
    fun cancelNotification(id: Int) {
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(id)
    }

    /**
     * Delete intent that puts the notification for [alarmId] back.
     *
     * Shares the alarm id as request code with the stop and snooze intents, which
     * is safe because `PendingIntent` identity includes the action: only the
     * extras are ignored.
     */
    private fun restorePendingIntent(alarmId: Int): PendingIntent {
        val restoreIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_RESTORE
            putExtra("id", alarmId)
        }
        return PendingIntent.getBroadcast(
            context,
            alarmId,
            restoreIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /**
     * DAWNBOX CHANGE: an intent that opens Dawnbox (over the lock screen)
     * with the extra "dawnboxAction": "tap" (notification tapped) or
     * "button" (second button). Dawnbox then starts the surprise, or for
     * the check-in alarm plays songs.
     */
    fun dawnboxActivityIntent(alarmId: Int, dawnboxAction: String): Intent? {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return null
        launch.action = "com.gdelataillade.alarm.action.RING"
        launch.removeCategory(Intent.CATEGORY_LAUNCHER)
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        launch.putExtra("alarmId", alarmId)
        launch.putExtra("dawnboxAction", dawnboxAction)
        return launch
    }

    fun dawnboxLaunchIntent(alarmId: Int, dawnboxAction: String, requestCode: Int): PendingIntent? {
        val launch = dawnboxActivityIntent(alarmId, dawnboxAction) ?: return null
        return PendingIntent.getActivity(
            context,
            requestCode, // own request code, so it never replaces the ring intent
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /**
     * DAWNBOX CHANGE: called by DawnboxActionReceiver when the second button
     * is pressed. A button that opens an app directly makes Android ask to
     * unlock first; a full-screen notification opens Dawnbox over the lock
     * screen right away (needs "Full screen notifications" on Android 14+).
     */
    fun postDawnboxLaunch(alarmId: Int, title: String?) {
        val launch = dawnboxLaunchIntent(alarmId, "button", alarmId + 30000) ?: return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                DAWNBOX_CHANNEL_ID, "Surprise", NotificationManager.IMPORTANCE_HIGH
            ).apply { setSound(null, null) }
            nm.createNotificationChannel(channel)
        }
        val n = NotificationCompat.Builder(context, DAWNBOX_CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title ?: context.applicationInfo.loadLabel(context.packageManager).toString())
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(launch)
            .setFullScreenIntent(launch, true)
            .setAutoCancel(true)
            .setTimeoutAfter(60_000)
            .build()
        nm.notify(DAWNBOX_LAUNCH_NOTIFICATION_ID, n)
    }

    fun buildNotification(
        notificationSettings: NotificationSettings,
        fullScreen: Boolean,
        pendingIntent: PendingIntent,
        alarmId: Int,
        canSnooze: Boolean = false
    ): Notification {
        val iconResId = iconResId(notificationSettings)

        val stopIntent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_STOP
            putExtra("id", alarmId)
        }
        // Use the alarm id as request code so each alarm gets its own pending
        // intent; with a shared request code the stop button of one alarm
        // would stop whichever alarm was scheduled last.
        val stopPendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // DAWNBOX CHANGE: tapping the notification opens Dawnbox with the
        // surprise. The full-screen intent below still opens the ringing screen.
        val tapIntent = dawnboxLaunchIntent(alarmId, "tap", alarmId + 10000)

        val notificationBuilder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(iconResId)
            .setContentTitle(notificationSettings.title)
            .setContentText(notificationSettings.body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setOngoing(true)
            .setContentIntent(tapIntent ?: pendingIntent)
            .setSound(null)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        // setOngoing(true) above no longer pins the notification: since Android 13 a
        // foreground service notification can be swiped away while the device is
        // unlocked. The delete intent is the only signal Android gives for that
        // swipe, so it is what decides what the swipe means.
        //
        // Opting out has to *restore* rather than ignore. Ignoring it leaves the
        // alarm sounding with its only on-screen control gone, which is worse than
        // the stray swipe the opt-out exists to prevent; re-posting extends to an
        // unlocked device what the platform already guarantees on a locked one.
        notificationBuilder.setDeleteIntent(
            if (notificationSettings.androidStopAlarmOnDismiss) {
                stopPendingIntent
            } else {
                restorePendingIntent(alarmId)
            }
        )

        if (fullScreen) {
            notificationBuilder.setFullScreenIntent(pendingIntent, true)
        }

        // DAWNBOX CHANGE: bigger title and text, also on the lock screen. The
        // buttons (Stop / Surprise me) stay below it as usual.
        val bigViews = RemoteViews(context.packageName, R.layout.dawnbox_alarm_notification).apply {
            setTextViewText(R.id.dawnbox_title, notificationSettings.title)
            setTextViewText(R.id.dawnbox_body, notificationSettings.body)
        }
        notificationBuilder
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(bigViews)
            .setCustomBigContentView(bigViews)
            .setCustomHeadsUpContentView(bigViews)

        notificationSettings.let {
            if (it.stopButton != null) {
                notificationBuilder.addAction(0, it.stopButton, stopPendingIntent)
            }

            // DAWNBOX CHANGE: the second button ("Surprise me", or "Play some
            // songs" on the check-in) replaces snooze. It uses the
            // androidSnoozeButton label. A broadcast works on the lock screen
            // without unlocking; DawnboxActionReceiver then opens Dawnbox.
            if (it.androidSnoozeButton != null) {
                val buttonIntent = Intent(context, DawnboxActionReceiver::class.java).apply {
                    putExtra("id", alarmId)
                    putExtra("title", notificationSettings.title)
                }
                val buttonPendingIntent = PendingIntent.getBroadcast(
                    context,
                    alarmId + 20000,
                    buttonIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                notificationBuilder.addAction(0, it.androidSnoozeButton, buttonPendingIntent)
            }

            if (it.iconColor != null) {
                notificationBuilder.setColor(it.iconColor)
            }
        }

        return notificationBuilder.build()
    }

    /**
     * What a non-looping alarm leaves behind with `keepNotificationAfterAlarmEnds`: the
     * alarm is over, so no actions, nothing ongoing, and silent so it does not alert again.
     */
    fun postEndedNotification(notificationSettings: NotificationSettings, alarmId: Int) {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(iconResId(notificationSettings))
            .setContentTitle(notificationSettings.title)
            .setContentText(notificationSettings.body)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setSilent(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
        if (launch != null) {
            builder.setContentIntent(
                PendingIntent.getActivity(
                    context,
                    alarmId,
                    launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
        }
        notificationSettings.iconColor?.let { builder.setColor(it) }

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(alarmId, builder.build())
    }

    // We need to use [Resources.getIdentifier] because resources are registered by Flutter.
    @SuppressLint("DiscouragedApi")
    private fun iconResId(notificationSettings: NotificationSettings): Int {
        val defaultIconResId =
            context.packageManager.getApplicationInfo(context.packageName, 0).icon
        val icon = notificationSettings.icon ?: return defaultIconResId
        val resId = context.resources.getIdentifier(icon, "drawable", context.packageName)
        return if (resId != 0) resId else defaultIconResId
    }
}
