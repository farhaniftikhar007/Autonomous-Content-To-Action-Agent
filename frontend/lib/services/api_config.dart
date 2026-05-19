import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
static const String defaultLocalHost = "autonomous-content-to-action-agent.onrender.com";
static const String defaultEmulatorHost = "autonomous-content-to-action-agent.onrender.com";
static const int defaultPort = 443;

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
    final isSecure = host.endsWith("onrender.com") || port == 443;
    final scheme = isSecure ? "https" : "http";
    final portSuffix = (port == 443 || port == 80) ? "" : ":$port";
    return "$scheme://$host$portSuffix";
  }

  /// Combined WebSocket Stream URL
  static String get websocketUrl {
    if (_customHost != null) return "ws://$_customHost:$_customPort/ws/logs";
    final isSecure = host.endsWith("onrender.com") || port == 443;
    final scheme = isSecure ? "wss" : "ws";
    final portSuffix = (port == 443 || port == 80) ? "" : ":$port";
    return "$scheme://$host$portSuffix/ws/logs";
  }
}
