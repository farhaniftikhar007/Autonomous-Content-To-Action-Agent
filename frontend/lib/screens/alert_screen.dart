import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/api_config.dart';
import '../widgets/resilient_widgets.dart';

class AlertScreen extends StatefulWidget {
  @override
  _AlertScreenState createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Alert> _alerts = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fetchAlerts();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _rotationController.repeat();

    try {
      final alerts = await _apiService.getAlerts();
      // Sort alerts: active/unresolved first, then by date descending
      final sortedAlerts = List<Alert>.from(alerts)
        ..sort((a, b) {
          if (a.isResolved != b.isResolved) {
            return a.isResolved ? 1 : -1;
          }
          return b.createdAt.compareTo(a.createdAt);
        });

      setState(() {
        _alerts = sortedAlerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      _rotationController.stop();
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime.toLocal());

    if (difference.inSeconds < 5) {
      return 'just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final dateStr = dateTime.toLocal().toString();
      return dateStr.substring(0, 16);
    }
  }

  int get _activeCount => _alerts.where((a) => !a.isResolved).length;
  int get _resolvedCount => _alerts.where((a) => a.isResolved).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E), // Ultra-dark cyber background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F15),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.security,
                color: Color(0xFF00E5FF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "THREAT MONITOR",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Operational Threat Monitor",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A24),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.settings_ethernet, size: 16, color: Colors.white70),
            ),
            onPressed: () {
              // Show quick debug connection config dialog
              _showConnectionSettingsDialog();
            },
            tooltip: "Server Node Configuration",
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF00E5FF).withOpacity(0.15),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar dashboard summary cards
            if (!_isLoading && _errorMessage == null) _buildSummaryHeader(),
            Expanded(
              child: _buildBodyContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _fetchAlerts,
        backgroundColor: const Color(0xFF00E5FF),
        foregroundColor: Colors.black,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
        child: RotationTransition(
          turns: _rotationController,
          child: const Icon(Icons.refresh_rounded, size: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const LoadingState(label: "Calibrating operational threat monitor...");
    } else if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          child: ErrorCard(
            title: "THREAT MONITOR SYNC BLOCKED",
            error: _errorMessage,
            onRetry: _fetchAlerts,
          ),
        ),
      );
    } else if (_alerts.isEmpty) {
      return EmptyState(
        title: "THREAT MONITOR INACTIVE",
        message: "No operational anomalies or threats have been detected in the system.",
        icon: Icons.shield_outlined,
        onAction: _fetchAlerts,
        actionLabel: "REFRESH MONITOR",
      );
    } else {
      return _buildAlertsList();
    }
  }

  Widget _buildSummaryHeader() {
    final hasThreats = _activeCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F15),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildHeaderCard(
              title: "ACTIVE THREATS",
              value: _activeCount.toString(),
              valueColor: hasThreats ? const Color(0xFFFF5252) : const Color(0xFF00E5FF),
              icon: Icons.warning_amber_rounded,
              iconColor: hasThreats ? const Color(0xFFFF5252) : Colors.white24,
              borderColor: hasThreats ? const Color(0xFFFF5252).withOpacity(0.3) : Colors.white10,
              glowColor: hasThreats ? const Color(0xFFFF5252).withOpacity(0.15) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildHeaderCard(
              title: "RESOLVED NODES",
              value: _resolvedCount.toString(),
              valueColor: const Color(0xFF00E676),
              icon: Icons.verified_user_outlined,
              iconColor: const Color(0xFF00E676).withOpacity(0.7),
              borderColor: const Color(0xFF00E676).withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    Color? glowColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF14141F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Icon(icon, color: iconColor, size: 24),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cyber spinner
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00E5FF).withOpacity(0.8)),
                ),
              ),
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFF9100).withOpacity(0.5)),
                ),
              ),
              const Icon(
                Icons.radar,
                color: Color(0xFF00E5FF),
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "SCANNING DATABASE...",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Establishing sync with network threat grid",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: ListView(
        shrinkWrap: true,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: const Color(0xFFFF5252).withOpacity(0.8),
            size: 64,
          ),
          const SizedBox(height: 20),
          const Text(
            "CONNECTION DISRUPTED",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Color(0xFFFF5252),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0B0B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.terminal, color: Color(0xFFFF5252), size: 16),
                    SizedBox(width: 8),
                    Text(
                      "Diagnostic Terminal",
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFFFF5252),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 16),
                Text(
                  "Target Base Node: ${ApiConfig.baseUrl}",
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _errorMessage ?? "Unknown connection handshake failure",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: ElevatedButton.icon(
              onPressed: _fetchAlerts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252).withOpacity(0.15),
                foregroundColor: const Color(0xFFFF5252),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
                ),
              ),
              icon: const Icon(Icons.sync_problem_rounded, size: 18),
              label: const Text(
                "RECONNECT TO CORE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _showConnectionSettingsDialog,
            child: const Text(
              "Configure Server Endpoint",
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E676).withOpacity(0.05),
                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.2), width: 2),
              ),
              child: const Icon(
                Icons.gpp_good_rounded,
                color: Color(0xFF00E676),
                size: 54,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "ALL SYSTEMS NOMINAL",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: Color(0xFF00E676),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Threat monitor cleared. No active conflicts or stock discrepancies detected.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAlerts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14141F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.white10),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("FORCE RESCAN"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        final isUnresolved = !alert.isResolved;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF11111A), // Dark cyber card
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnresolved
                  ? const Color(0xFFFF9100).withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
              width: 1.2,
            ),
            boxShadow: isUnresolved
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF9100).withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Severity color bar left edge
                  Container(
                    width: 6,
                    color: isUnresolved
                        ? const Color(0xFFFF9100) // Glowing amber for unresolved
                        : const Color(0xFF00E676).withOpacity(0.6), // Green for resolved
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Alert title & icon
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      isUnresolved
                                          ? Icons.warning_amber_rounded
                                          : Icons.check_circle_outline_rounded,
                                      color: isUnresolved
                                          ? const Color(0xFFFF9100)
                                          : const Color(0xFF00E676),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        alert.title.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          letterSpacing: 1.0,
                                          color: isUnresolved ? Colors.white : Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Real-time Relative Timestamp tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.access_time, size: 10, color: Colors.white38),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getRelativeTime(alert.createdAt),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Alert description message
                          Text(
                            alert.message,
                            style: TextStyle(
                              color: isUnresolved ? Colors.white70 : Colors.white38,
                              fontSize: 13,
                              height: 1.4,
                              decoration: alert.isResolved ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 8),
                          // Node details footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "NODE ID: #${alert.id.toString().padLeft(3, '0')}",
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: Colors.white24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isUnresolved
                                      ? const Color(0xFFFF9100).withOpacity(0.08)
                                      : const Color(0xFF00E676).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isUnresolved ? "UNRESOLVED" : "RESOLVED",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: isUnresolved
                                        ? const Color(0xFFFF9100)
                                        : const Color(0xFF00E676),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConnectionSettingsDialog() {
    final TextEditingController hostController = TextEditingController(text: ApiConfig.host);
    final TextEditingController portController = TextEditingController(text: ApiConfig.port.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF12121A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.2)),
          ),
          title: Row(
            children: [
              const Icon(Icons.settings_ethernet, color: Color(0xFF00E5FF)),
              const SizedBox(width: 10),
              const Text(
                "SERVER CONFIG",
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 1.5,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Change server endpoint to connect physical APK or local emulator web client.",
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hostController,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: "Host IP/Domain",
                  labelStyle: const TextStyle(color: Colors.white38),
                  hintText: "e.g., 10.0.2.2 or 192.168.1.100",
                  hintStyle: const TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF181824),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: "Port",
                  labelStyle: const TextStyle(color: Colors.white38),
                  hintText: "e.g., 8000",
                  hintStyle: const TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF181824),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  hostController.text = ApiConfig.defaultLocalHost;
                  portController.text = ApiConfig.defaultPort.toString();
                },
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Reset to Local Defaults",
                    style: TextStyle(
                      color: Color(0xFFFF9100),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("CANCEL", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("APPLY & REBOOT", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                final String host = hostController.text.trim();
                final int port = int.tryParse(portController.text.trim()) ?? ApiConfig.defaultPort;

                if (host.isNotEmpty) {
                  ApiConfig.configure(host: host, port: port);
                } else {
                  ApiConfig.reset();
                }

                Navigator.of(context).pop();
                _fetchAlerts(); // Force a fresh rescan with the new settings
              },
            ),
          ],
        );
      },
    );
  }
}
