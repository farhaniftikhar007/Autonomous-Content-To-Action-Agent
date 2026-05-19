import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/command_center_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/summary_card.dart';
import '../widgets/metric_chart.dart';
import '../widgets/resilient_widgets.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedChartKey = "mitigation_impact";

  final Map<String, String> _chartOptions = {
    "mitigation_impact": "Mitigation Impact",
    "inventory_trends": "Inventory Trends",
    "shortage_growth": "Shortage Growth",
    "reorder_forecasts": "Reorder Forecasts",
    "supplier_delays": "Supplier Delays",
    "risk_escalation": "Risk Escalation",
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommandCenterProvider>();

    return Scaffold(
      drawer: const AppDrawer(),
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
              child: const Icon(Icons.rocket_launch, color: Color(0xFF00E5FF), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              "AI OPS COMMAND CENTER",
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
            icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent),
            onPressed: () {
              print("[DEBUG] [Dashboard] Manual instant refresh triggered by developer.");
              provider.forceInstantRefresh();
            },
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
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(CommandCenterProvider provider) {
    if (provider.isLoading && provider.inventory.isEmpty) {
      return const LoadingState(label: "CALIBRATING COMMAND RADAR...");
    }

    if (provider.errorMessage != null && provider.inventory.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: ErrorCard(
            title: "METRIC SYNC BLOCKED",
            error: provider.appError ?? provider.errorMessage,
            onRetry: () => provider.forceInstantRefresh(),
          ),
        ),
      );
    }

    if (provider.inventory.isEmpty && provider.alerts.isEmpty && provider.analytics.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.forceInstantRefresh(),
        color: const Color(0xFF00E5FF),
        backgroundColor: const Color(0xFF14141F),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: EmptyState(
              title: "COMMAND GRID INACTIVE",
              message: "No live operational inventory feeds or threat streams have been processed yet. Upload reports or trigger events on the Ingestion tab to activate.",
              icon: Icons.data_exploration_outlined,
              onAction: () => provider.forceInstantRefresh(),
              actionLabel: "FORCE RESYNC FEED",
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.forceInstantRefresh(),
      color: const Color(0xFF00E5FF),
      backgroundColor: const Color(0xFF14141F),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryGrid(provider),
            const SizedBox(height: 20),
            _buildSystemStatus(provider),
            const SizedBox(height: 20),
            _buildChartSection(provider),
            const SizedBox(height: 20),
            _buildOperationalMetricsRow(provider),
            const SizedBox(height: 20),
            _buildWorkflowActivitySection(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(CommandCenterProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        SummaryCard(
          title: "Active Threats",
          value: provider.activeAlertsCount.toString(),
          icon: Icons.warning_amber_rounded,
          color: Colors.orangeAccent,
        ),
        SummaryCard(
          title: "Reorder Shortages",
          value: provider.inventoryShortagesCount.toString(),
          icon: Icons.inventory_2_outlined,
          color: Colors.redAccent,
        ),
        SummaryCard(
          title: "Inventory Health",
          value: "${provider.inventoryHealth.toStringAsFixed(1)}%",
          icon: Icons.health_and_safety_outlined,
          color: Colors.greenAccent,
        ),
        SummaryCard(
          title: "Supply Risk Index",
          value: provider.supplyRiskIndex.toStringAsFixed(2),
          icon: Icons.bar_chart_outlined,
          color: Colors.purpleAccent,
        ),
      ],
    );
  }

  Widget _buildOperationalMetricsRow(CommandCenterProvider provider) {
    final latency = provider.latencyMs;
    final cost = provider.mitigationBudget.toStringAsFixed(0);
    final risk = provider.riskReductionPercent.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF14141F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem("Avg Latency", "$latency ms", Icons.timer),
          _buildMetricItem("Est. Cost", "PKR $cost", Icons.payments_outlined),
          _buildMetricItem("Risk Reduction", "+$risk%", Icons.shield_outlined),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00E5FF), size: 22),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
      ],
    );
  }

  Widget _buildChartSection(CommandCenterProvider provider) {
    List<double> dataPoints = provider.chartsData[_selectedChartKey] ?? [];

    if (dataPoints.isEmpty) {
      dataPoints = [0.0, 0.0, 0.0, 0.0];
    } else if (dataPoints.length == 1) {
      dataPoints = [dataPoints[0], dataPoints[0]];
    }

    Color lineColor;
    switch (_selectedChartKey) {
      case "inventory_trends":
        lineColor = Colors.greenAccent;
        break;
      case "shortage_growth":
        lineColor = Colors.redAccent;
        break;
      case "reorder_forecasts":
        lineColor = Colors.amberAccent;
        break;
      case "supplier_delays":
        lineColor = Colors.purpleAccent;
        break;
      case "risk_escalation":
        lineColor = Colors.orangeAccent;
        break;
      default:
        lineColor = Colors.cyanAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _chartOptions[_selectedChartKey] ?? "Operational Trend",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF14141F),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: lineColor.withOpacity(0.3)),
              ),
              child: Text(
                "REALTIME MONITORING",
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: lineColor, fontFamily: 'monospace', letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _chartOptions.entries.map((entry) {
              final isSelected = _selectedChartKey == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: lineColor,
                  backgroundColor: const Color(0xFF14141F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? lineColor : Colors.white.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedChartKey = entry.key;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 190,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF11111A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: MetricChart(
            dataPoints: dataPoints,
            lineColor: lineColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowActivitySection(CommandCenterProvider provider) {
    final logs = provider.actionLogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Execution Logs",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        logs.isEmpty
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF11111A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 16),
                    SizedBox(width: 8),
                    Text(
                      "No historical log entries available.",
                      style: TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length > 4 ? 4 : logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Card(
                    color: const Color(0xFF14141F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 18),
                      title: Text(
                        log.actionType.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF), letterSpacing: 1.0),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          log.description,
                          style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                        ),
                      ),
                      trailing: Text(
                        _formatLogTime(log.timestamp),
                        style: const TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                  );
                },
              ),
      ],
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
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: isCritical ? Colors.redAccent : Colors.cyanAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCritical ? "CRITICAL AI RESOLUTION PLAN" : "AI OPTIMIZATION COGNITION",
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                      color: isCritical ? Colors.redAccent : Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
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
                  "CONFIDENCE: ${provider.aiConfidence.toStringAsFixed(0)}%",
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

  String _formatLogTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    return "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}";
  }
}
