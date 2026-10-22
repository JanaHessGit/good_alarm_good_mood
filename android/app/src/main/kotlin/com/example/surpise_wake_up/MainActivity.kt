package com.example.surpise_wake_up

import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // When the alarm rings, the alarm plugin opens this activity with this
    // action (full-screen alarm, or a tap on the alarm notification).
    private val actionRing = "com.gdelataillade.alarm.action.RING"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Before Flutter starts, so the ringing screen with
        // "Start surprise / Snooze / Stop" appears over the lock screen at once.
        showOverLockScreenIfAlarm(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        showOverLockScreenIfAlarm(intent)
    }

    private fun showOverLockScreenIfAlarm(intent: Intent?) {
        if (intent?.action == actionRing) showOverLockScreen(true)
    }

    private fun showOverLockScreen(on: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(on)
            setTurnScreenOn(on)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dawnbox/screen")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Keep Dawnbox on top of the lock screen while the surprise plays.
                    "showOverLockScreen" -> {
                        showOverLockScreen(call.arguments as? Boolean ?: false)
                        result.success(null)
                    }
                    // Android 14+: may the alarm open full screen over the lock screen?
                    "canUseFullScreen" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            val nm = getSystemService(NotificationManager::class.java)
                            result.success(nm.canUseFullScreenIntent())
                        } else {
                            result.success(true)
                        }
                    }
                    "openFullScreenSettings" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            startActivity(
                                Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
                                    .setData(Uri.parse("package:$packageName"))
                            )
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
