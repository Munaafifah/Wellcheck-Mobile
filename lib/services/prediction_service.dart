import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction_model.dart';

class PredictionService {
  final String djangoApiUrl =
      "https://ai-disease-prediction-jqf3d.ondigitalocean.app/status/";
  final String nodeApiUrl =
      "https://wellcheck-mobile-iu264.ondigitalocean.app/predictions2";
  final String healthStatusUrl =
      "https://wellcheck-mobile-iu264.ondigitalocean.app/add-healthstatus";

  Future<PredictionModel?> sendSymptoms(
      String token, List<String> symptoms) async {
    try {
      print("📥 Symptoms sent to Django: $symptoms");

      final response = await http.post(
        Uri.parse(djangoApiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'symptoms': symptoms}), // ← send strings
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
          await saveHealthStatusToDB(token, symptoms, prediction.diagnosisList);

          return prediction;
        } else {
          print("Invalid response format: $data");
          return null;
        }
      } else {
        print("Failed to fetch prediction: ${response.statusCode}");
        print("Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Errors during API call: $e");
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

  Future<void> saveHealthStatusToDB(
      String token, List<String> symptoms, List<String> diagnosisList) async {
    try {
      final response = await http.post(
        Uri.parse(healthStatusUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'additionalNotes': symptoms.join(', '),
          'diagnosisList': diagnosisList,
        }),
      );

      if (response.statusCode == 200) {
        print("Health status saved successfully.");
      } else {
        print("Failed to save health status: ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      print("Error saving health status: $e");
    }
  }
}
