class InventoryItem {
  final int id;
  final String sku;
  final String name;
  final int quantity;
  final int reorderLevel;
  final int salesLast7Days;
  final int complaints;
  final String lastUpdated;

  InventoryItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.quantity,
    required this.reorderLevel,
    required this.salesLast7Days,
    required this.complaints,
    required this.lastUpdated,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      reorderLevel: json['reorder_level'] ?? 0,
      salesLast7Days: json['sales_last_7_days'] ?? 0,
      complaints: json['complaints'] ?? 0,
      lastUpdated: json['last_updated'] ?? '',
    );
  }
}

class Alert {
  final int id;
  final String title;
  final String message;
  final bool isResolved;
  final DateTime createdAt;

  Alert({required this.id, required this.title, required this.message, required this.isResolved, required this.createdAt});

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      isResolved: json['is_resolved'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ActionLog {
  final int id;
  final String actionType;
  final String description;
  final DateTime timestamp;

  ActionLog({required this.id, required this.actionType, required this.description, required this.timestamp});

  factory ActionLog.fromJson(Map<String, dynamic> json) {
    return ActionLog(
      id: json['id'],
      actionType: json['action_type'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class SimulationResult {
  final String proposedAction;
  final String predictedOutcome;
  final String riskLevel;
  final List<String> reasoningLog;
  
  // Advanced System properties
  final double confidenceScore;
  final String recommendations;
  final String decisionExplanations;
  final int estimatedLatencyMs;
  final double estimatedCostPkr;
  final double projectedRiskReduction;
  final String beforeState;
  final String afterState;

  SimulationResult({
    required this.proposedAction,
    required this.predictedOutcome,
    required this.riskLevel,
    required this.reasoningLog,
    required this.confidenceScore,
    required this.recommendations,
    required this.decisionExplanations,
    required this.estimatedLatencyMs,
    required this.estimatedCostPkr,
    required this.projectedRiskReduction,
    required this.beforeState,
    required this.afterState,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    return SimulationResult(
      proposedAction: json['proposed_action'] ?? '',
      predictedOutcome: json['predicted_outcome'] ?? '',
      riskLevel: json['risk_level'] ?? '',
      reasoningLog: json['reasoning_log'] != null ? List<String>.from(json['reasoning_log']) : [],
      confidenceScore: (json['confidence_score'] ?? 0.90).toDouble(),
      recommendations: json['recommendations'] ?? '',
      decisionExplanations: json['decision_explanations'] ?? '',
      estimatedLatencyMs: json['estimated_latency_ms'] ?? 150,
      estimatedCostPkr: (json['estimated_cost_pkr'] ?? 25000.0).toDouble(),
      projectedRiskReduction: (json['projected_risk_reduction'] ?? 85.0).toDouble(),
      beforeState: json['before_state'] ?? 'Vulnerable',
      afterState: json['after_state'] ?? 'Secure',
    );
  }
}

class OperationalAnalytic {
  final int id;
  final int actionChainId;
  final String beforeState;
  final String afterState;
  final int latencyMs;
  final double operationalCost;
  final double riskReductionScore;
  final DateTime timestamp;

  OperationalAnalytic({
    required this.id,
    required this.actionChainId,
    required this.beforeState,
    required this.afterState,
    required this.latencyMs,
    required this.operationalCost,
    required this.riskReductionScore,
    required this.timestamp,
  });

  factory OperationalAnalytic.fromJson(Map<String, dynamic> json) {
    return OperationalAnalytic(
      id: json['id'],
      actionChainId: json['action_chain_id'] ?? 0,
      beforeState: json['before_state'] ?? '',
      afterState: json['after_state'] ?? '',
      latencyMs: json['latency_ms'] ?? 0,
      operationalCost: (json['operational_cost'] ?? 0).toDouble(),
      riskReductionScore: (json['risk_reduction_score'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ProjectedImpact {
  final String status;
  final int estimatedLatencyMs;
  final double estimatedCost;
  final double projectedRiskReduction;
  final String beforeState;
  final String projectedAfterState;

  ProjectedImpact({
    required this.status,
    required this.estimatedLatencyMs,
    required this.estimatedCost,
    required this.projectedRiskReduction,
    required this.beforeState,
    required this.projectedAfterState,
  });

  factory ProjectedImpact.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 'actual') {
      return ProjectedImpact(
        status: json['status'],
        estimatedLatencyMs: json['latency_ms'] ?? 0,
        estimatedCost: (json['operational_cost'] ?? 0).toDouble(),
        projectedRiskReduction: (json['risk_reduction'] ?? 0).toDouble(),
        beforeState: json['before_state'] ?? '',
        projectedAfterState: json['after_state'] ?? '',
      );
    }
    return ProjectedImpact(
      status: json['status'] ?? 'projected',
      estimatedLatencyMs: json['estimated_latency_ms'] ?? 0,
      estimatedCost: (json['estimated_cost'] ?? 0).toDouble(),
      projectedRiskReduction: (json['projected_risk_reduction'] ?? 0).toDouble(),
      beforeState: json['before_state'] ?? '',
      projectedAfterState: json['projected_after_state'] ?? '',
    );
  }
}

enum ActionStatus { pending, executing, retrying, recovered, completed, failed }

class ActionStep {
  final String title;
  final ActionStatus status;
  final String? description;

  ActionStep({required this.title, required this.status, this.description});
}

class ExecutionLog {
  final String timestamp;
  final String type; // info, retry, error, success
  final String message;
  final String? source;

  ExecutionLog({
    required this.timestamp,
    required this.type,
    required this.message,
    this.source,
  });

  factory ExecutionLog.fromJson(Map<String, dynamic> json) {
    final rawType = json['level'] ?? json['type'] ?? 'info';
    final parsedType = rawType == 'warning' ? 'retry' : rawType;
    return ExecutionLog(
      timestamp: json['timestamp'] ?? '',
      type: parsedType,
      message: json['message'] ?? '',
      source: json['source'],
    );
  }
}
