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
