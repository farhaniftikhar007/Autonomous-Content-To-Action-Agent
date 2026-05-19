import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

enum AppErrorType { network, timeout, server, parsing, websocket, unknown }

class AppError implements Exception {
  final String message;
  final AppErrorType type;
  final String? errorCode;
  final String? details;
  final String? traceId;

  AppError({
    required this.message,
    required this.type,
    this.errorCode,
    this.details,
    this.traceId,
  });

  @override
  String toString() {
    if (kDebugMode) {
      return 'AppError[$type] ($errorCode): $message (TraceID: $traceId)\nDetails: $details';
    }
    return message;
  }
}

class AppErrorHandler {
  static AppError handle(dynamic error) {
    // 1. Check for standard custom AppError already formatted
    if (error is AppError) {
      return error;
    }

    // 2. Check for DioException
    if (error is DioException) {
      return _handleDioException(error);
    }

    // 3. Check for http Response failures
    if (error is http.Response) {
      return _handleHttpResponse(error);
    }

    // 4. Check for SocketException (Offline / network warning)
    if (error is SocketException) {
      return AppError(
        message: "No internet connection detected. Please verify your network and retry.",
        type: AppErrorType.network,
        errorCode: "OFFLINE_WARNING",
        details: error.message,
      );
    }

    // 5. Check for Timeouts
    if (error.toString().contains("TimeoutException") || error.toString().contains("timeout")) {
      return AppError(
        message: "Request timed out. The server took too long to respond.",
        type: AppErrorType.timeout,
        errorCode: "TIMEOUT_EXCEPTION",
        details: error.toString(),
      );
    }

    // 6. Check for JSON Parsing Issues
    if (error is FormatException) {
      return AppError(
        message: "Unable to parse server payload correctly.",
        type: AppErrorType.parsing,
        errorCode: "PARSING_ERROR",
        details: error.message,
      );
    }

    // Default Unknown Error
    return AppError(
      message: "An unexpected client-side error occurred.",
      type: AppErrorType.unknown,
      errorCode: "UNKNOWN_CLIENT_FAILURE",
      details: error.toString(),
    );
  }

  static AppError _handleDioException(DioException error) {
    String message = "An unexpected network error occurred.";
    AppErrorType type = AppErrorType.network;
    String errorCode = "NETWORK_FAILURE";
    String? details = error.toString();

    final response = error.response;
    if (response != null) {
      final int statusCode = response.statusCode ?? 500;
      type = AppErrorType.server;
      errorCode = "HTTP_STATUS_$statusCode";

      if (statusCode == 400) {
        message = "Invalid ingestion payload";
      } else if (statusCode == 404) {
        message = "Backend endpoint unavailable";
      } else if (statusCode == 500) {
        message = "Internal intelligence engine failure";
      } else {
        message = "Server returned an unsuccessful status code: $statusCode.";
      }

      try {
        if (response.data != null) {
          final data = response.data;
          if (data is Map && data.containsKey('detail')) {
            details = data['detail'].toString();
            message = details;
          } else if (data is String) {
            final parsed = jsonDecode(data);
            if (parsed is Map && parsed.containsKey('detail')) {
              details = parsed['detail'].toString();
              message = details;
            }
          }
        }
      } catch (_) {}
    } else {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        message = "Request timed out. The server took too long to respond.";
        type = AppErrorType.timeout;
        errorCode = "TIMEOUT_EXCEPTION";
      } else if (error.error is SocketException) {
        message = "No internet connection detected. Please verify your network and retry.";
        type = AppErrorType.network;
        errorCode = "OFFLINE_WARNING";
      }
    }

    return AppError(
      message: message,
      type: type,
      errorCode: errorCode,
      details: details,
    );
  }

  static AppError _handleHttpResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['success'] == false) {
        // Parse our unified backend error schema!
        return AppError(
          message: body['message'] ?? 'Server operational failure.',
          type: AppErrorType.server,
          errorCode: body['error_code'] ?? 'SERVER_ERROR',
          details: body['details'],
          traceId: body['trace_id'],
        );
      }
    } catch (_) {
      // Body is not our unified JSON or parsing failed
    }

    // Generic HTTP non-200 responses fallback
    return AppError(
      message: "Server returned an unsuccessful status code: ${response.statusCode}.",
      type: AppErrorType.server,
      errorCode: "HTTP_STATUS_${response.statusCode}",
      details: "Raw Body: ${response.body}",
    );
  }
}
