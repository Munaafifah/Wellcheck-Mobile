import 'dart:convert';
import 'package:http/http.dart' as http;

class AvailabilityService {
  final String baseUrl = "http://10.0.2.2:5001";

  // Fetch all active doctors that have a schedule
  Future<List<Map<String, dynamic>>> fetchDoctors(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/doctors"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to fetch doctors: ${response.body}");
    }
  }

  // Fetch available slots for a doctor on a specific date
  // date format: "2026-04-21"
  Future<Map<String, dynamic>> fetchAvailability(
      String token, String doctorId, String date) async {
    final response = await http.get(
      Uri.parse("$baseUrl/doctors/$doctorId/availability?date=$date"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch availability: ${response.body}");
    }
  }
}