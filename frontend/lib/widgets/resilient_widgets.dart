import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/error_handler.dart';

/// Renders a highly visual, cyberpunk-themed Error Card with detailed debug tools and retry actions.
class ErrorCard extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final String? title;

  const ErrorCard({
    Key? key,
    required this.error,
    this.onRetry,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppError appError = AppErrorHandler.handle(error);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E0E0E) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.report_problem_outlined,
                  color: Colors.redAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title ?? "System Operational Alert",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.red[300] : Colors.red[900],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              appError.message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
            if (appError.errorCode != null || appError.traceId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (appError.errorCode != null)
                      Text(
                        "ERROR_CODE: ${appError.errorCode}",
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (appError.traceId != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "TRACE_ID: ${appError.traceId}",
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          color: Colors.blue[300],
                        ),
                      ),
                    ],
                    if (kDebugMode && appError.details != null && appError.details!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const Divider(color: Colors.grey, height: 8),
                      Text(
                        "DETAILS:\n${appError.details}",
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_outlined, size: 18),
                  label: const Text(
                    "RETRY OPERATION",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders a beautiful visual radar/circular scanner indicating asynchronous data stream processes.
class LoadingState extends StatelessWidget {
  final String label;

  const LoadingState({
    Key? key,
    this.label = "Synchronizing live terminal feed...",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF00FF66) : const Color(0xFF00AA55),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isDark ? const Color(0xFF00FF66) : const Color(0xFF00AA55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a stunning cyberpunk placeholder for empty inventory, analysis, or action log scopes.
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C190F) : Colors.green[50],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF00FF66).withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 54,
                color: isDark ? const Color(0xFF00FF66).withOpacity(0.8) : Colors.green[700],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF00FF66) : const Color(0xFF00AA55),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.bolt_outlined, size: 18),
                label: Text(
                  actionLabel!.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
