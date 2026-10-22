import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Lock-screen helpers. Need the small addition in MainActivity.kt
/// (see setup/MainActivity.kt). Without it, calls are silently ignored.
class LockScreen {
  static const _channel = MethodChannel('dawnbox/screen');

  /// Keeps Dawnbox visible over the lock screen (true) or not (false).
  static Future<void> showOver(bool on) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('showOverLockScreen', on);
    } catch (_) {}
  }

  /// Android 14+ asks users to allow full-screen alarms per app. Without it
  /// the locked phone only shows a small notification.
  static Future<bool> canUseFullScreen() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('canUseFullScreen') ?? true;
    } catch (_) {
      return true; // unknown: don't nag
    }
  }

  /// How the alarm notification opened the app: "tap" (notification
  /// tapped), "button" (Surprise me / Play some songs), else null. Each launch is reported only once.
  static Future<String?> takeLaunchAction() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('takeLaunchAction');
    } catch (_) {
      return null;
    }
  }

  /// Called when "Surprise me" is tapped while the app is already running.
  static void onLaunchAction(void Function() handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'launchAction') handler();
    });
  }

  /// Keeps the screen on (true) while a surprise runs, so the phone doesn't
  /// turn the screen off and lock again in the middle of it.
  static Future<void> keepScreenOn(bool on) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('keepScreenOn', on);
    } catch (_) {}
  }

  /// Is the phone locked right now?
  static Future<bool> isLocked() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isLocked') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Asks Android to unlock (fingerprint, face or PIN). True when unlocked
  /// or not locked at all, false if the user cancelled.
  static Future<bool> requestUnlock() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('requestUnlock') ?? true;
    } catch (_) {
      return true; // unknown: just try
    }
  }

  static Future<void> openFullScreenSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openFullScreenSettings');
    } catch (_) {}
  }
}
