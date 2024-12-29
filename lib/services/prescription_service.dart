import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prescription_model.dart';
import '../config.dart';

class PrescriptionService {
  static const String baseUrl = Config.baseUrl;

  Future<List<Prescription>> fetchPrescriptions(String userId, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/prescriptions/$userId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Prescription.fromJson(item)).toList();
    } else {
      throw Exception("Failed to fetch prescriptions");
    }
  }
}
