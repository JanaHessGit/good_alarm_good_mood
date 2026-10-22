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

  static Future<void> openFullScreenSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openFullScreenSettings');
    } catch (_) {}
  }
}
