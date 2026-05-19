import '../models/models.dart';
import 'api_service.dart';

abstract class ICommandCenterRepository {
  Future<List<InventoryItem>> getInventory();
  Future<List<Alert>> getAlerts();
  Future<List<OperationalAnalytic>> getAnalytics();
  Future<ProjectedImpact> getProjectedImpact(int actionChainId);
  Future<List<ActionLog>> getActionLogs();
  Future<SimulationResult> analyzeInventory(String query);
  Future<Map<String, List<double>>> getChartsData();
}

class CommandCenterRepository implements ICommandCenterRepository {
  final ApiService _apiService;

  CommandCenterRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  @override
  Future<List<InventoryItem>> getInventory() async {
    print("[DEBUG] [Repository] Fetching live inventory items...");
    final result = await _apiService.getInventory();
    print("[DEBUG] [Repository] Loaded ${result.length} inventory items successfully.");
    return result;
  }

  @override
  Future<List<Alert>> getAlerts() async {
    print("[DEBUG] [Repository] Fetching live alerts...");
    final result = await _apiService.getAlerts();
    print("[DEBUG] [Repository] Loaded ${result.length} alerts successfully.");
    return result;
  }

  @override
  Future<List<OperationalAnalytic>> getAnalytics() async {
    print("[DEBUG] [Repository] Fetching live operational analytics...");
    final result = await _apiService.getAnalyticsMetrics();
    print("[DEBUG] [Repository] Loaded ${result.length} analytics records successfully.");
    return result;
  }

  @override
  Future<ProjectedImpact> getProjectedImpact(int actionChainId) async {
    print("[DEBUG] [Repository] Fetching live projected impact for action chain: #$actionChainId...");
    final result = await _apiService.getProjectedImpact(actionChainId);
    print("[DEBUG] [Repository] Loaded impact. Cost: \$${result.estimatedCost}, Risk Reduction: ${result.projectedRiskReduction}.");
    return result;
  }

  @override
  Future<List<ActionLog>> getActionLogs() async {
    print("[DEBUG] [Repository] Fetching live action logs...");
    final result = await _apiService.getActionLogs();
    print("[DEBUG] [Repository] Loaded ${result.length} action logs successfully.");
    return result;
  }

  @override
  Future<SimulationResult> analyzeInventory(String query) async {
    print("[DEBUG] [Repository] Simulating AI analysis for query: '$query'...");
    final result = await _apiService.analyzeInventory(query);
    print("[DEBUG] [Repository] AI Analysis finished. Risk Level: ${result.riskLevel}");
    return result;
  }

  @override
  Future<Map<String, List<double>>> getChartsData() async {
    print("[DEBUG] [Repository] Fetching live dynamic chart data series...");
    final result = await _apiService.getChartsData();
    print("[DEBUG] [Repository] Loaded ${result.keys.length} dynamic chart metrics.");
    return result;
  }
}
