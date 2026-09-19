import 'package:flutter/foundation.dart';
import 'dart:io';

/// Lightweight OS detector — no extra package needed.
/// Returns a lowercase string that matches what advertisers expect.
class DeviceInfo {
  static String get os {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
