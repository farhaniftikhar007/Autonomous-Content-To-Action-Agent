import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';
import 'api_config.dart';

class SocketService {
  WebSocketChannel? _channel;
  final StreamController<ExecutionLog> _logController = StreamController<ExecutionLog>.broadcast();

  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  bool _isDisposed = false;

  String get _url => ApiConfig.websocketUrl;

  Stream<ExecutionLog> get logStream {
    return _logController.stream;
  }

  SocketService() {
    _connect();
  }

  void _connect() {
    if (_isDisposed) return;

    if (kDebugMode) {
      print("[WS Client] Connecting to $_url (Attempt #${_reconnectAttempts + 1})");
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));

      _channel!.stream.listen(
        (data) {
          // Success: reset reconnect attempts
          _reconnectAttempts = 0;

          if (data == "pong") {
            if (kDebugMode) {
              print("[WS Client] Received heartbeat pong.");
            }
            return;
          }

          try {
            final decoded = jsonDecode(data);
            if (decoded is Map<String, dynamic>) {
              final log = ExecutionLog.fromJson(decoded);
              _logController.add(log);
            }
          } catch (e) {
            if (kDebugMode) {
              print("[WS Client] Received raw packet: $data");
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print("[WS Client] Stream error observed: $error");
          }
          _handleDisconnect();
        },
        onDone: () {
          if (kDebugMode) {
            print("[WS Client] Connection closed by host.");
          }
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      _startHeartbeat();

    } catch (e) {
      if (kDebugMode) {
        print("[WS Client] Socket creation error: $e");
      }
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (_isDisposed) return;

    _pingTimer?.cancel();
    _channel?.sink.close();

    // Exponential backoff: 1s, 2s, 4s, 8s, max 16s
    _reconnectAttempts++;
    final backoffSeconds = (_reconnectAttempts > 4) ? 16 : (1 << (_reconnectAttempts - 1));

    if (kDebugMode) {
      print("[WS Client] Disconnected. Automatically retrying in $backoffSeconds seconds...");
    }

    // Add a local notification log to the stream so the UI terminal displays reconnect warning states!
    _logController.add(ExecutionLog(
      timestamp: DateTime.now().toIsoformat(),
      type: 'error',
      message: "WARNING: WebSocket disconnected. Attempting auto-reconnect in $backoffSeconds seconds...",
      source: "system"
    ));

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      _connect();
    });
  }

  void _startHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_channel != null) {
        try {
          _channel!.sink.add("ping");
          if (kDebugMode) {
            print("[WS Client] Sent keep-alive heartbeat ping.");
          }
        } catch (e) {
          if (kDebugMode) {
            print("[WS Client] Heartbeat ping failed: $e");
          }
          _handleDisconnect();
        }
      }
    });
  }

  void dispose() {
    _isDisposed = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _logController.close();
  }
}

extension DateTimeFormat on DateTime {
  String toIsoformat() {
    return this.toIso8601String().split('T').last.split('.').first;
  }
}
