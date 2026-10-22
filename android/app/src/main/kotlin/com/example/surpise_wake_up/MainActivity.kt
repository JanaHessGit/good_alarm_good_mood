package com.example.surpise_wake_up

import android.app.KeyguardManager
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

    private var channel: MethodChannel? = null

    /** "surprise" after "Surprise me" or a tap on the alarm notification. */
    private var pendingAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Before Flutter starts, so the alarm appears over the lock screen at
        // once. Opened normally (app icon): never over the lock screen.
        handleLaunch(intent, fromNewIntent = false)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleLaunch(intent, fromNewIntent = true)
    }

    private fun handleLaunch(intent: Intent?, fromNewIntent: Boolean) {
        val isAlarm = intent?.action == actionRing
        if (isAlarm) {
            showOverLockScreen(true)
        } else if (!fromNewIntent) {
            showOverLockScreen(false)
        }
        if (isAlarm && intent?.getBooleanExtra("dawnboxSurprise", false) == true) {
            pendingAction = "surprise"
            // App already running: tell Dart, which then asks for the action.
            channel?.invokeMethod("launchAction", null)
        }
    }

    private fun showOverLockScreen(on: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(on)
            setTurnScreenOn(on)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dawnbox/screen")
        channel = ch
        ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    // Dart asks once how the app was opened ("surprise" or null).
                    "takeLaunchAction" -> {
                        result.success(pendingAction)
                        pendingAction = null
                    }
                    // Is the phone locked right now?
                    "isLocked" -> {
                        val km = getSystemService(KeyguardManager::class.java)
                        result.success(km?.isKeyguardLocked ?: false)
                    }
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
