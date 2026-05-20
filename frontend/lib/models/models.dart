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
      id: (json['id'] as num?)?.toInt() ?? 0,
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      reorderLevel: (json['reorder_level'] as num?)?.toInt() ?? 0,
      salesLast7Days: (json['sales_last_7_days'] as num?)?.toInt() ?? 0,
      complaints: (json['complaints'] as num?)?.toInt() ?? 0,
      lastUpdated: json['last_updated']?.toString() ?? '',
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
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isResolved: json['is_resolved'] == true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
      id: (json['id'] as num?)?.toInt() ?? 0,
      actionType: json['action_type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
      proposedAction: json['proposed_action']?.toString() ?? '',
      predictedOutcome: json['predicted_outcome']?.toString() ?? '',
      riskLevel: json['risk_level']?.toString() ?? '',
      reasoningLog: json['reasoning_log'] != null 
          ? (json['reasoning_log'] as List).map((e) => e?.toString() ?? '').toList()
          : [],
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.90,
      recommendations: json['recommendations']?.toString() ?? '',
      decisionExplanations: json['decision_explanations']?.toString() ?? '',
      estimatedLatencyMs: (json['estimated_latency_ms'] as num?)?.toInt() ?? 150,
      estimatedCostPkr: (json['estimated_cost_pkr'] as num?)?.toDouble() ?? 25000.0,
      projectedRiskReduction: (json['projected_risk_reduction'] as num?)?.toDouble() ?? 85.0,
      beforeState: json['before_state']?.toString() ?? 'Vulnerable',
      afterState: json['after_state']?.toString() ?? 'Secure',
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
      id: (json['id'] as num?)?.toInt() ?? 0,
      actionChainId: (json['action_chain_id'] as num?)?.toInt() ?? 0,
      beforeState: json['before_state']?.toString() ?? '',
      afterState: json['after_state']?.toString() ?? '',
      latencyMs: (json['latency_ms'] as num?)?.toInt() ?? 0,
      operationalCost: (json['operational_cost'] as num?)?.toDouble() ?? 0.0,
      riskReductionScore: (json['risk_reduction_score'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
        status: json['status']?.toString() ?? 'actual',
        estimatedLatencyMs: (json['latency_ms'] as num?)?.toInt() ?? 0,
        estimatedCost: (json['operational_cost'] as num?)?.toDouble() ?? 0.0,
        projectedRiskReduction: (json['risk_reduction'] as num?)?.toDouble() ?? 0.0,
        beforeState: json['before_state']?.toString() ?? '',
        projectedAfterState: json['after_state']?.toString() ?? '',
      );
    }
    return ProjectedImpact(
      status: json['status']?.toString() ?? 'projected',
      estimatedLatencyMs: (json['estimated_latency_ms'] as num?)?.toInt() ?? 0,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0.0,
      projectedRiskReduction: (json['projected_risk_reduction'] as num?)?.toDouble() ?? 0.0,
      beforeState: json['before_state']?.toString() ?? '',
      projectedAfterState: json['projected_after_state'] ?? '',
    );
  }
}

enum ActionStatus { pending, executing, retrying, recovered, completed, failed, rollback }

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
    final rawType = (json['level'] ?? json['type'] ?? 'info').toString();
    final parsedType = rawType == 'warning' ? 'retry' : rawType;
    return ExecutionLog(
      timestamp: (json['timestamp'] ?? '').toString(),
      type: parsedType,
      message: (json['message'] ?? '').toString(),
      source: json['source']?.toString(),
    );
  }
}
