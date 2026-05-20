import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/command_center_provider.dart';
import '../services/error_handler.dart';
import '../services/socket_service.dart';

class AgentScreen extends StatefulWidget {
  @override
  _AgentScreenState createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ApiService _apiService = ApiService();
  SimulationResult? _result;
  bool _isLoading = false;

  final ScrollController _scrollController = ScrollController();
  final List<ExecutionLog> _liveLogs = [];
  StreamSubscription<ExecutionLog>? _logSubscription;

  void _analyze() async {
    final query = _queryController.text;
    if (query.isEmpty) return;
    
    final SocketService socketService = SocketService();
    
    setState(() {
      _isLoading = true;
      _result = null;
      _liveLogs.clear();
    });

    _logSubscription = socketService.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _liveLogs.add(log);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    try {
      print("[VERIFICATION] [AgentScreen] Sending POST query to backend Operations Engine with sequence: '$query'");
      final result = await _apiService.analyzeInventory(query);
      
      setState(() {
        _isLoading = false;
        _result = result;
      });

      // Synchronize latest simulation state globally
      final provider = Provider.of<CommandCenterProvider>(context, listen: false);
      provider.updateLatestSimulation(result);
      provider.forceInstantRefresh();

      print("[VERIFICATION] [AgentScreen] Successfully synced dynamic analysis state to CommandCenterProvider.");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Operational analysis successfully executed!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("[VERIFICATION] [AgentScreen] Backend call failed: $e.");
      final appErr = AppErrorHandler.handle(e);
      
      setState(() {
        _isLoading = false;
        _result = null;
      });

      final provider = Provider.of<CommandCenterProvider>(context, listen: false);
      provider.clearSimulationAndImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("System operational alert: ${appErr.message}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      _logSubscription?.cancel();
      socketService.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "OPERATIONS ASSISTANT",
          style: TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 15,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.greenAccent),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24.0),
          child: Container(
            color: const Color(0xFF0F0F15),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "OPERATIONS FEED: ONLINE",
                  style: TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  "SYSTEM STATUS: ONLINE",
                  style: TextStyle(color: Colors.cyanAccent, fontFamily: 'Courier', fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Terminal Input
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.greenAccent, width: 1.5),
                borderRadius: BorderRadius.circular(4.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: TextField(
                controller: _queryController,
                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier'),
                cursorColor: Colors.greenAccent,
                decoration: InputDecoration(
                  hintText: "Enter operational command...",
                  hintStyle: TextStyle(color: Colors.greenAccent.withOpacity(0.5), fontFamily: 'Courier'),
                  prefixIcon: const Icon(Icons.chevron_right, color: Colors.greenAccent),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.keyboard_return, color: Colors.greenAccent),
                    onPressed: _analyze,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                onSubmitted: (_) => _analyze(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Loading State
            if (_isLoading)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                      )
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.cyanAccent,
                              strokeWidth: 2.0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "SYSTEM EXECUTION LOGS ACTIVE",
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${_liveLogs.length} LOGS BUFFERED",
                            style: const TextStyle(
                              color: Colors.white30,
                              fontFamily: 'Courier',
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(color: Colors.cyanAccent.withOpacity(0.4), thickness: 1.0),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _liveLogs.isEmpty
                            ? const Center(
                                child: Text(
                                  "Initializing telemetry link...",
                                  style: TextStyle(color: Colors.cyanAccent, fontFamily: 'Courier', fontSize: 12),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _liveLogs.length,
                                itemBuilder: (context, index) {
                                  final log = _liveLogs[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "[${log.timestamp}] ",
                                          style: const TextStyle(color: Colors.white24, fontFamily: 'Courier', fontSize: 11),
                                        ),
                                        Expanded(
                                          child: _buildRichMessage(log),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              
            // Neutral state safety guard when no analysis is active
            if (_result == null && !_isLoading)
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F15),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.05),
                          blurRadius: 15,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.terminal, color: Colors.greenAccent.withOpacity(0.5), size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          "Awaiting operational intelligence input.",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'Courier',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter a dynamic command query above to orchestrate real-time supply chain analysis.",
                          style: TextStyle(
                            color: Colors.greenAccent.withOpacity(0.5),
                            fontFamily: 'Courier',
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
               
            // Results Output
            if (_result != null)
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Execution Trace Terminal Log
                    Container(
                      margin: const EdgeInsets.only(bottom: 24.0),
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: Colors.greenAccent, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.memory, color: Colors.greenAccent, size: 20),
                              const SizedBox(width: 12),
                              const Text(
                                "EXECUTION LOGS",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(color: Colors.greenAccent.withOpacity(0.8), thickness: 1.5),
                          const SizedBox(height: 12),
                          ..._result!.reasoningLog.map((log) => _buildReasoningLogItem(log)),
                        ],
                      ),
                    ),
                    
                    // Stats Cards (Professional Dark UI)
                    _buildDarkCard(Icons.psychology, "Proposed Action", _result!.proposedAction, Colors.cyanAccent),
                    _buildDarkCard(Icons.timeline, "Predicted Outcome", _result!.predictedOutcome, Colors.greenAccent),
                    _buildDarkCard(Icons.warning_amber_rounded, "Risk Level", _result!.riskLevel, Colors.redAccent),
                    
                    // Linear Progress Bar Confidence State
                    Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(6.0),
                        border: const Border(left: BorderSide(color: Colors.purpleAccent, width: 4.0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "REAL-TIME CONFIDENCE STATE",
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Courier',
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _result!.confidenceScore,
                                    color: Colors.purpleAccent,
                                    backgroundColor: Colors.white10,
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "${(_result!.confidenceScore * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(
                                  color: Colors.purpleAccent,
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    _buildDarkCard(Icons.assistant, "AI Recommendations", _result!.recommendations, Colors.amberAccent),
                    _buildDarkCard(Icons.lightbulb_outline, "Decision Explanations", _result!.decisionExplanations, Colors.orangeAccent),
                    
                    // Dynamic Mitigation Impact Profile Grid
                    Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(6.0),
                        border: const Border(left: BorderSide(color: Colors.cyanAccent, width: 4.0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "DYNAMIC MITIGATION IMPACT PROFILE",
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Courier',
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMitigationGridItem("Latency Target", "${_result!.estimatedLatencyMs}ms", Colors.cyanAccent),
                              _buildMitigationGridItem("Mitigation Budget", "PKR ${_result!.estimatedCostPkr.toStringAsFixed(0)}", Colors.amberAccent),
                              _buildMitigationGridItem("Risk Reduction", "${_result!.projectedRiskReduction}%", Colors.greenAccent),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 24),
                          Text(
                            "State Transition: ${_result!.beforeState} ➔ ${_result!.afterState}",
                            style: const TextStyle(color: Colors.white54, fontFamily: 'Courier', fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildMitigationGridItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontFamily: 'Courier', fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.white38)),
      ],
    );
  }

  Widget _buildDarkCard(IconData icon, String title, String subtitle, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(6.0),
        border: Border(left: BorderSide(color: accentColor, width: 4.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(icon, color: accentColor, size: 32),
        title: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontFamily: 'Courier',
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Courier',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReasoningLogItem(String logLine) {
    final badgeRegExp = RegExp(r'^\[([A-Z0-9\s_\-\/]+)\]');
    final match = badgeRegExp.firstMatch(logLine);
    
    if (match != null) {
      final badgeName = match.group(1)!;
      final remainingText = logLine.replaceFirst(badgeRegExp, '').trim();
      
      Color badgeColor;
      Color badgeBg;
      switch (badgeName.toUpperCase()) {
        case 'UNDERSTAND':
          badgeColor = Colors.blueAccent;
          badgeBg = Colors.blue.withOpacity(0.15);
          break;
        case 'CONTEXT':
          badgeColor = Colors.tealAccent;
          badgeBg = Colors.teal.withOpacity(0.15);
          break;
        case 'CONFLICT':
          badgeColor = Colors.orangeAccent;
          badgeBg = Colors.orange.withOpacity(0.15);
          break;
        case 'REASONING':
          badgeColor = Colors.purpleAccent;
          badgeBg = Colors.purple.withOpacity(0.15);
          break;
        case 'DECISION':
          badgeColor = Colors.cyanAccent;
          badgeBg = Colors.cyan.withOpacity(0.15);
          break;
        case 'OUTCOME':
          badgeColor = Colors.greenAccent;
          badgeBg = Colors.green.withOpacity(0.15);
          break;
        case 'RECOVERY':
          badgeColor = Colors.amberAccent;
          badgeBg = Colors.amber.withOpacity(0.15);
          break;
        case 'ROLLBACK':
          badgeColor = Colors.redAccent;
          badgeBg = Colors.red.withOpacity(0.15);
          break;
        case 'EXECUTION':
          badgeColor = Colors.lightBlueAccent;
          badgeBg = Colors.blue.withOpacity(0.12);
          break;
        case 'ERROR':
          badgeColor = Colors.redAccent;
          badgeBg = Colors.red.withOpacity(0.2);
          break;
        default:
          badgeColor = Colors.greenAccent;
          badgeBg = Colors.greenAccent.withOpacity(0.1);
      }
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: badgeBg,
                border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeName,
                style: TextStyle(
                  color: badgeColor,
                  fontFamily: 'Courier',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Text(
                remainingText,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'Courier',
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("> ", style: TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              logLine,
              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
    _scrollController.dispose();
    _queryController.dispose();
    _logSubscription?.cancel();
    super.dispose();
  }
}
