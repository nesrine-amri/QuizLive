import 'package:flutter/foundation.dart';

class AppConfig {
  /// Android (émulateur) → 10.0.2.2. Windows / macOS / Linux / iOS simu → localhost.
  /// Téléphone réel: `--dart-define=API_BASE_URL=http://<IP_DU_PC>:3000`
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static String get socketBaseUrl {
    const fromEnv = String.fromEnvironment('SOCKET_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}

