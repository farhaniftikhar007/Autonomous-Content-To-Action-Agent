import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  static const String defaultLocalHost = "127.0.0.1";
  static const String defaultEmulatorHost = "10.0.2.2";
  static const int defaultPort = 8000;

  // Allows manual override at runtime if testing physical devices
  static String? _customHost;
  static int? _customPort;

  /// Configure custom API endpoint parameters at runtime.
  static void configure({required String host, int? port}) {
    _customHost = host;
    if (port != null) {
      _customPort = port;
    }
  }

  /// Reset manual override back to platform defaults
  static void reset() {
    _customHost = null;
    _customPort = null;
  }

  /// Automatically resolves the host IP for local development or APK execution.
  static String get host {
    if (_customHost != null) {
      return _customHost!;
    }
    if (kIsWeb) {
      return defaultLocalHost;
    }
    try {
      if (Platform.isAndroid) {
        // Android emulator accesses the host PC local dev server via 10.0.2.2
        return defaultEmulatorHost;
      }
    } catch (_) {
      // Platform check fallback
    }
    return defaultLocalHost;
  }

  /// The active API port
  static int get port => _customPort ?? defaultPort;

  /// Combined Base HTTP URL
  static String get baseUrl {
    if (_customHost != null) return "http://$_customHost:$_customPort";
    return "https://autonomous-content-to-action-agent.onrender.com";
  }

  /// Combined WebSocket Stream URL
  static String get websocketUrl {
    if (_customHost != null) return "ws://$_customHost:$_customPort/ws/logs";
    return "wss://autonomous-content-to-action-agent.onrender.com/ws/logs";
  }
}
