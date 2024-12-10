import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction_model.dart';

class PredictionService {
  static const String baseUrl = "http://localhost:5000";
  Future<List<PredictionModel>> fetchPredictionById(
      String userId, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/predictions/$userId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => PredictionModel.fromJson(item)).toList();
    } else {
      throw Exception("Failed to fetch prediction");
    }
  }
}
