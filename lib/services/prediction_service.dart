import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction_model.dart';

class PredictionService {
  final String djangoApiUrl = "http://10.0.2.2:8000/status/"; // For emulator
  //"http://127.0.0.1:8000/status/" // For website
  //"http://10.0.2.2:8000/status/"; // For emulator
  final String nodeApiUrl =
      "http://10.0.2.2:5000/predictions2"; // Node.js MongoDB API
  //"http://localhost:5000/predictions2" //For website
  //"http://10.0.2.2:5000/predictions2"; // Node.js MongoDB API

  Future<PredictionModel?> sendSymptoms(
      String token, List<String> symptoms) async {
    try {
      final Map<String, dynamic> payload = {
        'symptoms': symptoms,
      };

      final response = await http.post(
        Uri.parse(djangoApiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey("top_diseases") &&
            data.containsKey("probabilityList")) {
          final prediction = PredictionModel.fromJson(data);
          prediction.symptomsList = symptoms;

          prediction.probabilityList = (data['probabilityList'] as List)
              .map((prob) => double.tryParse(prob.replaceAll("%", "")) ?? 0.0)
              .toList();

          await savePredictionToDB(token, prediction);

          return prediction;
        } else {
          print("Invalid response format");
          return null;
        }
      } else {
        print("Failed to fetch prediction: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error during API call: $e");
      throw Exception("Failed to connect to API: $e");
    }
  }

  Future<void> savePredictionToDB(
      String token, PredictionModel prediction) async {
    try {
      final Map<String, dynamic> payload = prediction.toJson();
      payload['symptomsList'] = prediction.symptomsList;

      final response = await http.post(
        Uri.parse(nodeApiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        print("Prediction saved to DB successfully.");
      } else {
        print("Failed to save prediction to DB: ${response.statusCode}");
      }
    } catch (e) {
      print("Error during DB save: $e");
      throw Exception("Failed to save to database: $e");
    }
  }
}
