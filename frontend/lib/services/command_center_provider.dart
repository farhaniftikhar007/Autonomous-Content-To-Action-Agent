import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'command_center_repository.dart';
import 'error_handler.dart';

class CommandCenterProvider extends ChangeNotifier {
  final ICommandCenterRepository _repository;
  Timer? _pollingTimer;

  // Cached states
  List<InventoryItem> _inventory = [];
  List<Alert> _alerts = [];
  List<OperationalAnalytic> _analytics = [];
  ProjectedImpact? _projectedImpact;
  List<ActionLog> _actionLogs = [];
  SimulationResult? _latestSimulation;
  Map<String, List<double>> _chartsData = {};

  bool _isLoading = true;
  String? _errorMessage;
  AppError? _appError;

  // Getters
  List<InventoryItem> get inventory => _inventory;
  List<Alert> get alerts => _alerts;
  List<OperationalAnalytic> get analytics => _analytics;
  ProjectedImpact? get projectedImpact => _projectedImpact;
  List<ActionLog> get actionLogs => _actionLogs;
  SimulationResult? get latestSimulation => _latestSimulation;
  Map<String, List<double>> get chartsData => _chartsData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppError? get appError => _appError;

  void updateLatestSimulation(SimulationResult result) {
    _latestSimulation = result;
    print("[DEBUG] [Provider] Appended new System SimulationResult state cache.");
    notifyListeners();
  }

  void clearSimulationAndImpact() {
    _latestSimulation = null;
    _projectedImpact = null;
    print("[VERIFICATION] [Provider] Cleared cache and triggered dynamic hot-refresh.");
    notifyListeners();
  }

  // Derived metrics
  int get activeAlertsCount => _alerts.where((a) => !a.isResolved).length;
  int get inventoryShortagesCount => _inventory.where((item) => item.quantity <= item.reorderLevel).length;
  
  double get recoverySuccessRate {
    if (_alerts.isEmpty) return 100.0;
    final resolvedCount = _alerts.where((a) => a.isResolved).length;
    return (resolvedCount / _alerts.length) * 100.0;
  }

  double get complaintSpikePercentage {
    if (_inventory.isEmpty) return 0.0;
    final totalComplaints = _inventory.fold<int>(0, (sum, item) => sum + item.complaints);
    return totalComplaints.toDouble();
  }

  double get inventoryHealth {
    if (_inventory.isEmpty) return 100.0;
    final total = _inventory.length;
    final shortages = inventoryShortagesCount;
    return ((total - shortages) / total) * 100.0;
  }

  double get supplyRiskIndex {
    final threatWeight = activeAlertsCount * 1.5;
    final shortageWeight = inventoryShortagesCount * 0.8;
    final calculated = threatWeight + shortageWeight;
    return calculated > 10.0 ? 10.0 : calculated;
  }

  double get aiConfidence {
    if (_latestSimulation != null) {
      return _latestSimulation!.confidenceScore * 100.0;
    }
    double base = 85.0;
    if (_inventory.isNotEmpty) base += 10.0;
    base -= (activeAlertsCount * 2.0);
    if (base > 98.0) base = 98.0;
    if (base < 60.0) base = 60.0;
    return base;
  }

  int get latencyMs {
    if (_latestSimulation != null) {
      return _latestSimulation!.estimatedLatencyMs;
    }
    if (_projectedImpact != null) {
      return _projectedImpact!.estimatedLatencyMs;
    }
    int base = 120;
    base += (inventoryShortagesCount * 25);
    base += (activeAlertsCount * 80);
    return base;
  }

  double get mitigationBudget {
    if (_latestSimulation != null) {
      return _latestSimulation!.estimatedCostPkr;
    }
    if (_projectedImpact != null) {
      final cost = _projectedImpact!.estimatedCost;
      if (cost < 1000.0) {
        return cost * 280.0; 
      }
      return cost;
    }
    double base = 15000.0;
    base += (inventoryShortagesCount * 15000.0);
    base += (activeAlertsCount * 50000.0);
    return base;
  }

  double get riskReductionPercent {
    if (_latestSimulation != null) {
      return _latestSimulation!.projectedRiskReduction;
    }
    if (_projectedImpact != null) {
      return _projectedImpact!.projectedRiskReduction * 100.0;
    }
    double base = 98.0;
    base -= (activeAlertsCount * 5.0 + inventoryShortagesCount * 2.0);
    if (base < 10.0) base = 10.0;
    if (base > 98.0) base = 98.0;
    return base;
  }

  CommandCenterProvider({ICommandCenterRepository? repository})
      : _repository = repository ?? CommandCenterRepository() {
    print("[DEBUG] [Provider] Initializing CommandCenterProvider...");
    fetchData(silent: false);
    startPolling(seconds: 8);
  }

  /// Fetches all required resources in parallel with timeout safeguards.
  Future<void> fetchData({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      _appError = null;
      notifyListeners();
    }

    try {
      print("[DEBUG] [Provider] Launching concurrent API updates...");
      
      // Parallel execution of key endpoints
      final results = await Future.wait([
        _repository.getInventory().timeout(const Duration(seconds: 8)),
        _repository.getAlerts().timeout(const Duration(seconds: 8)),
        _repository.getAnalytics().timeout(const Duration(seconds: 8)),
        _repository.getActionLogs().timeout(const Duration(seconds: 8)),
        _repository.getChartsData().timeout(const Duration(seconds: 8)),
      ]);

      _inventory = results[0] as List<InventoryItem>;
      _alerts = results[1] as List<Alert>;
      _analytics = results[2] as List<OperationalAnalytic>;
      _actionLogs = results[3] as List<ActionLog>;
      _chartsData = results[4] as Map<String, List<double>>;

      // If database is empty, seed realistic mock demo states to keep the grid alive and functional
      if (_inventory.isEmpty) {
        _inventory = [
          InventoryItem(
            id: 1,
            sku: "MED-GLOVE-981",
            name: "Surgical Sterile Gloves",
            quantity: 4,
            reorderLevel: 25,
            salesLast7Days: 45,
            complaints: 4,
            lastUpdated: DateTime.now().toIso8601String(),
          ),
          InventoryItem(
            id: 2,
            sku: "ELE-CHIP-702",
            name: "Microcontroller STM32",
            quantity: 18,
            reorderLevel: 50,
            salesLast7Days: 120,
            complaints: 1,
            lastUpdated: DateTime.now().toIso8601String(),
          ),
          InventoryItem(
            id: 3,
            sku: "TEX-FIB-404",
            name: "Premium Nylon Fiber",
            quantity: 410,
            reorderLevel: 300,
            salesLast7Days: 95,
            complaints: 0,
            lastUpdated: DateTime.now().toIso8601String(),
          ),
          InventoryItem(
            id: 4,
            sku: "MED-SYR-102",
            name: "Disposable Syringes 5ml",
            quantity: 2,
            reorderLevel: 100,
            salesLast7Days: 180,
            complaints: 6,
            lastUpdated: DateTime.now().toIso8601String(),
          ),
        ];
      }

      if (_alerts.isEmpty) {
        _alerts = [
          Alert(
            id: 1,
            title: "[CRITICAL] Inventory Depleted: MED-SYR-102",
            message: "Stock level is at 2 units (Reorder limit: 100).",
            isResolved: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
          ),
          Alert(
            id: 2,
            title: "[WARNING] Supply Risk: Supplier 4 Delay",
            message: "Supplier 4 reliability score dropped to 72%. Estimated delay is 3.5 days.",
            isResolved: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          Alert(
            id: 3,
            title: "[ALERT] Ingestion Contradiction on ELE-CHIP-702",
            message: "Conflict: Physical CSV indicates 18 units, while news feed indicates cargo loss.",
            isResolved: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ];
      }

      if (_actionLogs.isEmpty) {
        _actionLogs = [
          ActionLog(
            id: 1,
            actionType: "understand",
            description: "Parsed query: 'Analyze medical stock shortage & draft purchase order.'",
            timestamp: DateTime.now().subtract(const Duration(seconds: 40)),
          ),
          ActionLog(
            id: 2,
            actionType: "conflict",
            description: "Cross-referenced sources: Found 1 core conflict on SKU ELE-CHIP-702.",
            timestamp: DateTime.now().subtract(const Duration(seconds: 35)),
          ),
          ActionLog(
            id: 3,
            actionType: "reasoning",
            description: "Gemini swarm resolved reorder plan: Split PO for MED-SYR-102 to alternative supplier.",
            timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
          ),
          ActionLog(
            id: 4,
            actionType: "decision",
            description: "Drafted split purchase orders: PO-901A (PKR 48,000) & PO-901B (PKR 22,000) generated.",
            timestamp: DateTime.now().subtract(const Duration(seconds: 25)),
          ),
          ActionLog(
            id: 5,
            actionType: "outcome",
            description: "Dispatched operational sequence. Monitored task execution running...",
            timestamp: DateTime.now().subtract(const Duration(seconds: 20)),
          ),
        ];
      }

      if (_chartsData.isEmpty) {
        _chartsData = {
          "mitigation_impact": [20.0, 45.0, 75.0, 92.0],
          "inventory_trends": [88.0, 82.0, 71.0, 68.0],
          "shortage_growth": [1.0, 2.0, 3.0, 3.0],
          "reorder_forecasts": [12.0, 24.0, 35.0, 48.0],
          "supplier_delays": [1.2, 1.8, 2.7, 3.5],
          "risk_escalation": [2.1, 3.5, 5.8, 6.8],
        };
      }

      if (_analytics.isEmpty) {
        _analytics = [
          OperationalAnalytic(
            id: 1,
            actionChainId: 1,
            beforeState: "Active shortages and delays present",
            afterState: "Actions dispatched: Stock replenishment ordered",
            latencyMs: 820,
            operationalCost: 70000.0,
            riskReductionScore: 84.5,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ];
      }

      // Dynamically load the projected impact of the latest action chain
      final latestChainId = _analytics.isNotEmpty ? _analytics.first.actionChainId : 1;
      _projectedImpact = await _repository.getProjectedImpact(latestChainId).timeout(const Duration(seconds: 5));

      _errorMessage = null;
      _appError = null;
      print("[DEBUG] [Provider] API synchronization complete.");
    } catch (e) {
      print("[DEBUG] [Provider] Synchronization error: $e");
      final resolved = AppErrorHandler.handle(e);
      _appError = resolved;
      if (!silent) {
        _errorMessage = resolved.message;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Periodically polls the server in the background without showing loading spinners.
  void startPolling({int seconds = 8}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: seconds), (timer) {
      print("[DEBUG] [Provider] Polling trigger: Silently pulling update feed...");
      fetchData(silent: true);
    });
  }

  /// Manually stops background polling.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Forces an instant refresh of all backend data.
  Future<void> forceInstantRefresh() async {
    print("[DEBUG] [Provider] Forcing immediate system-wide synchronization...");
    await fetchData(silent: false);
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
