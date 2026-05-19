import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../models/models.dart';

class LiveLogsScreen extends StatefulWidget {
  const LiveLogsScreen({Key? key}) : super(key: key);

  @override
  State<LiveLogsScreen> createState() => _LiveLogsScreenState();
}

class _LiveLogsScreenState extends State<LiveLogsScreen> {
  final SocketService _socketService = SocketService();
  final List<ExecutionLog> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060608),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F15),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.greenAccent, blurRadius: 6, spreadRadius: 1),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "SYSTEM TRACE CONSOLE",
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Text(
              "STREAM: LIVE",
              style: TextStyle(
                fontFamily: 'Courier',
                color: Colors.cyanAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
      body: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF020203),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.03),
              blurRadius: 12,
              spreadRadius: 1,
            )
          ],
        ),
        child: Column(
          children: [
            // Terminal Header Info
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "SYSTEM: OPERATIONS DASHBOARD",
                    style: TextStyle(color: Colors.white24, fontFamily: 'Courier', fontSize: 10),
                  ),
                  Text(
                    "SECURE PROTOCOL",
                    style: TextStyle(color: Colors.white24, fontFamily: 'Courier', fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // Log Stream Builder
            Expanded(
              child: StreamBuilder<ExecutionLog>(
                stream: _socketService.logStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final newLog = snapshot.data!;
                    // Avoid duplicate logging by comparing last item timestamp + message
                    final isDuplicate = _logs.isNotEmpty &&
                        _logs.first.timestamp == newLog.timestamp &&
                        _logs.first.message == newLog.message;
                    
                    if (!isDuplicate) {
                      print("[VERIFICATION] [WebSocket] Received incoming operational event: [${newLog.source?.toUpperCase()}] ${newLog.message}");
                      _logs.insert(0, newLog);
                    }
                  }

                  if (_logs.isEmpty) {
                    return const Center(
                      child: Text(
                        "--- NO LOG DATA SIGNAL ---",
                        style: TextStyle(color: Colors.white12, fontFamily: 'Courier', fontSize: 13),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final displaySource = log.source ?? "system";
                      final sourceTag = "[${displaySource.toUpperCase()}]";

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timestamp
                            Text(
                              "[${log.timestamp}] ",
                              style: const TextStyle(color: Colors.white30, fontFamily: 'Courier', fontSize: 12),
                            ),
                            // Source tag
                            Text(
                              "${sourceTag.padRight(13)} | ",
                              style: TextStyle(
                                color: _getSourceColor(displaySource),
                                fontFamily: 'Courier',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Message
                            Expanded(
                              child: _buildRichMessage(log),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            
            // Terminal Prompt Line
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: const Row(
                children: [
                  Text(
                    "admin@operations:~# ",
                    style: TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      "awaiting operational triggers...",
                      style: TextStyle(color: Colors.white30, fontFamily: 'Courier', fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichMessage(ExecutionLog log) {
    final message = log.message;
    
    // 1. Identify stage pattern: "[STAGE X/8]"
    final stageRegExp = RegExp(r'^\[STAGE\s+(\d+)/8\]');
    final stageMatch = stageRegExp.firstMatch(message);
    
    String? stageText;
    String remainingMessage = message;
    
    if (stageMatch != null) {
      stageText = "STAGE ${stageMatch.group(1)}";
      remainingMessage = message.replaceFirst(stageRegExp, '').trim();
    }
    
    // 2. Identify status badge: "[SUCCESS]", "[RUNNING]", "[FAILED]", "[WARNING]"
    final statusRegExp = RegExp(r'^\[(SUCCESS|RUNNING|FAILED|WARNING)\]');
    final statusMatch = statusRegExp.firstMatch(remainingMessage);
    
    String? statusText;
    if (statusMatch != null) {
      statusText = statusMatch.group(1);
      remainingMessage = remainingMessage.replaceFirst(statusRegExp, '').trim();
    }
    
    // 3. Identify duration pattern: "Duration: X.Yms"
    final durationRegExp = RegExp(r'\|\s*Duration:\s*([\d\.]+(?:ms)?)');
    final durationMatch = durationRegExp.firstMatch(remainingMessage);
    
    String? durationText;
    if (durationMatch != null) {
      durationText = durationMatch.group(1);
      remainingMessage = remainingMessage.replaceFirst(durationRegExp, '').trim();
      // remove trailing pipe if any
      remainingMessage = remainingMessage.replaceAll(RegExp(r'\|\s*$'), '').trim();
    }
    
    // 4. Build a beautiful list of inline components
    List<Widget> rowItems = [];
    
    // Stage Badge
    if (stageText != null) {
      rowItems.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2F),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            stageText,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontFamily: 'Courier',
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    // Status Badge
    if (statusText != null) {
      Color badgeColor;
      Color badgeBg;
      switch (statusText) {
        case 'SUCCESS':
          badgeColor = Colors.greenAccent;
          badgeBg = Colors.green.withOpacity(0.15);
          break;
        case 'RUNNING':
          badgeColor = Colors.cyanAccent;
          badgeBg = Colors.cyan.withOpacity(0.15);
          break;
        case 'FAILED':
          badgeColor = Colors.redAccent;
          badgeBg = Colors.red.withOpacity(0.15);
          break;
        case 'WARNING':
          badgeColor = Colors.amberAccent;
          badgeBg = Colors.amber.withOpacity(0.15);
          break;
        default:
          badgeColor = Colors.white70;
          badgeBg = Colors.white12;
      }
      
      rowItems.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: badgeBg,
            border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: badgeColor,
              fontFamily: 'Courier',
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    // Core Message Text
    Color textColor = _getLogColor(log.type);
    if (statusText == 'SUCCESS') {
      textColor = Colors.greenAccent.withOpacity(0.85);
    } else if (statusText == 'FAILED') {
      textColor = Colors.redAccent.withOpacity(0.85);
    } else if (statusText == 'WARNING') {
      textColor = Colors.amberAccent.withOpacity(0.85);
    }
    
    rowItems.add(
      Expanded(
        child: Text(
          remainingMessage,
          style: TextStyle(
            color: textColor,
            fontFamily: 'Courier',
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
    
    // Duration suffix
    if (durationText != null) {
      rowItems.add(
        Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            durationText,
            style: const TextStyle(
              color: Colors.purpleAccent,
              fontFamily: 'Courier',
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rowItems,
    );
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'system': return Colors.cyanAccent;
      case 'recovery': return Colors.amberAccent;
      case 'execution': return Colors.lightBlueAccent;
      case 'analysis': return Colors.purpleAccent;
      default: return Colors.white54;
    }
  }

  Color _getLogColor(String type) {
    switch (type.toLowerCase()) {
      case 'retry':
      case 'warning': return Colors.amberAccent;
      case 'error': return const Color(0xFFFF5252);
      case 'success': return Colors.greenAccent;
      case 'system': return Colors.lightBlueAccent;
      default: return Colors.white70;
    }
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}
