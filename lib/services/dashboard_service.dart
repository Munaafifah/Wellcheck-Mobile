import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_model.dart';

class DashboardService {
  static const String baseUrl = "http://localhost:5000";

  Future<Patient?> fetchPatient(String userId, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/patient/$userId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Patient.fromJson(data);
    } else {
      return null;
    }
  }
}
