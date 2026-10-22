package com.example.surpise_wake_up

import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // When the alarm rings, the alarm plugin opens this activity with this
    // action (full-screen alarm, or a tap on the alarm notification).
    private val actionRing = "com.gdelataillade.alarm.action.RING"

    private var channel: MethodChannel? = null

    /** "tap" (alarm notification tapped) or "button" (Surprise me / Play some songs). */
    private var pendingAction: String? = null

    /**
     * Keeps the CPU awake from the alarm until "I am awake" (at most 30 min),
     * so timers, the voice, the waiting music and the Spotify call keep
     * running even if the screen is switched off with the power button.
     */
    private var cpuLock: PowerManager.WakeLock? = null

    private fun keepAwake(on: Boolean) {
        if (on) {
            val lock = cpuLock ?: getSystemService(PowerManager::class.java)
                ?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "RiseAndSurprise:surprise")
                ?.also { it.setReferenceCounted(false); cpuLock = it }
            lock?.acquire(30 * 60 * 1000L)
        } else {
            cpuLock?.let { if (it.isHeld) it.release() }
        }
    }

    override fun onDestroy() {
        keepAwake(false)
        super.onDestroy()
    }

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
            // Keep the screen (and the CPU) on until Dart says the user is awake.
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            keepAwake(true)
        } else if (!fromNewIntent) {
            showOverLockScreen(false)
        }
        val action = if (isAlarm) intent?.getStringExtra("dawnboxAction") else null
        if (action != null) {
            pendingAction = action
            // The helper notification that opened us is no longer needed.
            getSystemService(NotificationManager::class.java)?.cancel(4711)
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
                    // Dart asks once how the app was opened ("tap", "button" or null).
                    "takeLaunchAction" -> {
                        result.success(pendingAction)
                        pendingAction = null
                    }
                    // Asks Android to unlock (fingerprint, face, PIN...). true once
                    // unlocked or if the phone wasn't locked, false if cancelled.
                    "requestUnlock" -> {
                        val km = getSystemService(KeyguardManager::class.java)
                        if (km == null || !km.isKeyguardLocked || Build.VERSION.SDK_INT < 26) {
                            result.success(true)
                        } else {
                            var answered = false
                            fun answer(ok: Boolean) {
                                if (!answered) {
                                    answered = true
                                    result.success(ok)
                                }
                            }
                            km.requestDismissKeyguard(this, object : KeyguardManager.KeyguardDismissCallback() {
                                override fun onDismissSucceeded() = answer(true)
                                override fun onDismissCancelled() = answer(false)
                                override fun onDismissError() = answer(false)
                            })
                        }
                    }
                    // Keeps the screen from turning off (and the phone from locking
                    // again) while the surprise is running.
                    "keepScreenOn" -> {
                        if (call.arguments as? Boolean == true) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            keepAwake(true)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            keepAwake(false)
                        }
                        result.success(null)
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
