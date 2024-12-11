// HealthstatusService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Healthstatus_model.dart';

class HealthstatusService {
  static const String baseUrl = "http://localhost:5000";

  Future<List<HealthstatusModel>> fetchHealthstatusById(
      String userId, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/healthstatus/$userId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => HealthstatusModel.fromJson(item)).toList();
    } else {
      throw Exception("Failed to fetch healthstatus");
    }
  }

  // HealthstatusService.dart
  Future<void> deleteHealthstatus(
      String userId, String healthStatusId, String token) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/healthstatus/$userId/$healthStatusId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete health status");
    }
  }
}
