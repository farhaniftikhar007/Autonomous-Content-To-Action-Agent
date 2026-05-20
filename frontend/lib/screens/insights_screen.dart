import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/action_timeline.dart';
import '../models/models.dart';
import '../services/command_center_provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommandCenterProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F15),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
              ),
              child: const Icon(Icons.psychology, color: Color(0xFF00E5FF), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              "OPERATIONAL ANALYSIS",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.cyanAccent),
            onPressed: () => provider.forceInstantRefresh(),
            tooltip: "Force Synchronization",
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
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, CommandCenterProvider provider) {
    if (provider.isLoading && provider.actionLogs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    final analytics = provider.analytics;
    final logs = provider.actionLogs;

    // Dynamically build the Action Chain timeline steps from recent logs
    List<ActionStep> activeSteps = [];
    if (logs.isEmpty) {
      activeSteps = [
        ActionStep(
          title: "System Standby",
          status: ActionStatus.pending,
          description: "Awaiting database events or documents ingestion",
        ),
      ];
    } else {
      // Map up to 4 recent logs dynamically into a chronological timeline representation
      final limit = logs.length > 4 ? 4 : logs.length;
      for (int i = 0; i < limit; i++) {
        final log = logs[i];
        
        // Define clean status: latest log is "executing" or "completed" based on type
        ActionStatus status = ActionStatus.completed;
        if (i == 0) {
          status = log.actionType.contains("ANALYSIS") ? ActionStatus.executing : ActionStatus.completed;
        }

        activeSteps.add(ActionStep(
          title: log.actionType.toUpperCase().replaceAll("_", " "),
          status: status,
          description: log.description,
        ));
      }
      
      // If we only have 1 or 2 steps, pad it with pending system states for completeness
      if (activeSteps.length < 4) {
        activeSteps.add(ActionStep(
          title: "Continuous Ingest Sweep",
          status: ActionStatus.pending,
          description: "Continuous polling thread awaiting next operational conflict",
        ));
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemStatus(provider),
          const SizedBox(height: 24),
          const Text(
            "Live Reasoning Patterns",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF), letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          
          // Live Reasoning Patterns
          () {
            final sim = provider.latestSimulation;
            if (sim != null && sim.reasoningLog.isNotEmpty) {
              print("[VERIFICATION] [InsightsScreen] Rendering ${sim.reasoningLog.length} dynamic AI reasoning pattern steps.");
              return Column(
                children: sim.reasoningLog.map((log) {
                  String tag = "ANALYSIS";
                  String msg = log;
                  if (log.contains("]")) {
                    final parts = log.split("]");
                    tag = parts[0].replaceAll("[", "").trim();
                    msg = parts.sublist(1).join("]").trim();
                  }

                  Color cardColor = Colors.cyanAccent;
                  IconData icon = Icons.psychology_outlined;
                  if (tag.contains("UNDERSTAND")) {
                    cardColor = Colors.cyanAccent;
                    icon = Icons.search;
                  } else if (tag.contains("CONTEXT")) {
                    cardColor = Colors.purpleAccent;
                    icon = Icons.info_outline;
                  } else if (tag.contains("CONFLICT") || tag.contains("INSIGHT")) {
                    cardColor = Colors.redAccent;
                    icon = Icons.warning_amber_outlined;
                  } else if (tag.contains("REASONING") || tag.contains("IMPACT")) {
                    cardColor = Colors.amberAccent;
                    icon = Icons.lightbulb_outline;
                  } else if (tag.contains("DECISION") || tag.contains("PLAN")) {
                    cardColor = Colors.blueAccent;
                    icon = Icons.playlist_add_check;
                  } else if (tag.contains("OUTCOME")) {
                    cardColor = Colors.greenAccent;
                    icon = Icons.done_all;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _buildInsightCard(
                      title: "Analysis Step: $tag",
                      description: msg,
                      details: "Operational Event | Source: Analysis Engine",
                      icon: icon,
                      color: cardColor,
                    ),
                  );
                }).toList(),
              );
            }

            if (analytics.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF14141F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.psychology_outlined, color: Colors.white24, size: 40),
                    SizedBox(height: 12),
                    Text(
                      "No operational events processed yet.",
                      style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Run an inventory analysis in the 'Agent' tab to update operational metrics.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: analytics.length > 3 ? 3 : analytics.length,
              itemBuilder: (context, index) {
                final analytic = analytics[index];
                
                Color cardColor = Colors.cyanAccent;
                if (index == 1) cardColor = Colors.purpleAccent;
                if (index == 2) cardColor = Colors.orangeAccent;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildInsightCard(
                    title: "AI State Resolution Chain #${analytic.actionChainId}",
                    description: "State Shift: '${analytic.beforeState}' \u2192 '${analytic.afterState}'",
                    details: "Execution Time: ${analytic.latencyMs}ms | Projected Cost: \$${analytic.operationalCost.toStringAsFixed(2)}",
                    icon: Icons.psychology_outlined,
                    color: cardColor,
                  ),
                );
              },
            );
          }(),
                
          const SizedBox(height: 24),
          const Text(
            "Active Action Chain Timeline",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF), letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14141F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ActionTimeline(steps: activeSteps),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String description,
    required String details,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14141F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.02),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  details,
                  style: const TextStyle(fontSize: 11, color: Colors.white30, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(CommandCenterProvider provider) {
    final sim = provider.latestSimulation;
    if (sim == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF14141F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: const Row(
          children: [
            Icon(Icons.psychology_outlined, color: Colors.cyanAccent, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Operations Assistant",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "No active decision analysis triggered yet. Start analysis in the 'Agent' tab.",
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isCritical = sim.riskLevel.toUpperCase() == "CRITICAL";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101018),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical ? Colors.redAccent.withOpacity(0.3) : Colors.cyanAccent.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCritical ? Colors.redAccent : Colors.cyanAccent).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: isCritical ? Colors.redAccent : Colors.cyanAccent,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isCritical ? "CRITICAL RESOLUTION PLAN" : "OPERATIONAL ANALYSIS",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.0,
                          color: isCritical ? Colors.redAccent : Colors.cyanAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isCritical ? Colors.redAccent : Colors.purpleAccent).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: (isCritical ? Colors.redAccent : Colors.purpleAccent).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  "CONFIDENCE: ${(sim.confidenceScore * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? Colors.redAccent : Colors.purpleAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sim.proposedAction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sim.decisionExplanations,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAiImpactItem("Latency Estimate", "${sim.estimatedLatencyMs}ms", Colors.cyanAccent),
              _buildAiImpactItem("Mitigation Budget", "PKR ${sim.estimatedCostPkr.toStringAsFixed(0)}", Colors.amberAccent),
              _buildAiImpactItem("Risk Mitigated", "${sim.projectedRiskReduction}%", Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiImpactItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.white38),
        ),
      ],
    );
  }
}
