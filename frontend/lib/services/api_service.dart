import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_config.dart';

class ApiService {
  String get baseUrl => ApiConfig.baseUrl;

  Future<List<InventoryItem>> getInventory() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/inventory'))
          .timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        return List<InventoryItem>.from(l.map((model) => InventoryItem.fromJson(model)));
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load inventory: Check connection to $baseUrl. Details: $e');
    }
  }

  Future<List<Alert>> getAlerts() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/alerts'))
          .timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        return List<Alert>.from(l.map((model) => Alert.fromJson(model)));
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load alerts: Check connection to $baseUrl. Details: $e');
    }
  }

  Future<SimulationResult> analyzeInventory(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agent/analyze'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'query': query,
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        return SimulationResult.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to analyze inventory: Check connection to $baseUrl. Details: $e');
    }
  }

  Future<List<OperationalAnalytic>> getAnalyticsMetrics() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/analytics/metrics'))
          .timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        return List<OperationalAnalytic>.from(l.map((model) => OperationalAnalytic.fromJson(model)));
      }
    } catch (e) {
      print("Analytics API error: $e");
    }
    return [];
  }

  Future<ProjectedImpact> getProjectedImpact(int actionChainId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/analytics/projected-impact?action_chain_id=$actionChainId'))
          .timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200) {
        return ProjectedImpact.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print("Projected Impact API error: $e");
    }
    return ProjectedImpact(
        status: "mock",
        estimatedLatencyMs: 0,
        estimatedCost: 0,
        projectedRiskReduction: 0,
        beforeState: "Unknown",
        projectedAfterState: "Unknown"
    );
  }

  Future<Map<String, List<double>>> getChartsData() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/analytics/charts'))
          .timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        Map<String, List<double>> parsed = {};
        data.forEach((key, value) {
          if (value is List) {
            parsed[key] = value.map<double>((e) => (e as num).toDouble()).toList();
          }
        });
        return parsed;
      }
    } catch (e) {
      print("Charts API error: $e");
    }
    return {};
  }

  Future<List<ActionLog>> getActionLogs() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/action_logs'))
          .timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200) {
        Iterable l = json.decode(response.body);
        return List<ActionLog>.from(l.map((model) => ActionLog.fromJson(model)));
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load action logs: Check connection to $baseUrl. Details: $e');
    }
  }
}

