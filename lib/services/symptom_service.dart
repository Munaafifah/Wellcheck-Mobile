import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/symptom_model.dart';
import '../config.dart';

class SymptomService {
  static const String baseUrl = Config.baseUrl;

  Future<void> addSymptom(String token, String symptomDescription) async {
    final response = await http.post(
      Uri.parse("$baseUrl/add-symptom"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"symptomDescription": symptomDescription}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to add symptom");
    }
  }
// Fetch all symptoms for the logged-in user
  Future<List<Symptom>> fetchSymptoms(String token, String userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/symptoms/$userId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Symptom.fromJson(item)).toList();
    } else {
      throw Exception("Failed to fetch symptoms");
    }
  }

  // Delete a symptom by its symptomId
  Future<void> deleteSymptom(String token, String symptomId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/delete-symptom/$symptomId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete symptom");
    }
  }

  // Update a symptom by its symptomId
  Future<void> updateSymptom(String token, String symptomId, String newDescription) async {
    final response = await http.put(
      Uri.parse("$baseUrl/update-symptom"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "symptomId": symptomId,
        "symptomDescription": newDescription,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update symptom");
    }
  }
}


