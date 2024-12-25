import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction_model.dart';

class PredictionService {
  final String djangoApiUrl =
      "http://127.0.0.1:8000/status/"; // Django Prediction API
  final String nodeApiUrl =
      "http://localhost:5000/predictions2"; // Node.js MongoDB API

  Future<PredictionModel?> sendSymptoms(
      String token, List<String> symptoms) async {
    try {
      final Map<String, dynamic> payload = {
        'symptoms': symptoms,  // Send symptoms list to Django
      };

      final response = await http.post(
        Uri.parse(djangoApiUrl),
        headers: {
          'Authorization': 'Bearer $token',  // Pass the token here
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      final Map<String, dynamic> data = json.decode(response.body);

      if (data.containsKey("top_diseases")) {
        // Attach symptoms to the prediction model
        final prediction = PredictionModel.fromJson(data);
        prediction.symptomsList = symptoms;  // Store the symptoms list

        // Save prediction to MongoDB after receiving response from Django
        await savePredictionToDB(token, prediction);  // Pass the token here

        return prediction;
      } else {
        print("Key 'top_diseases' not found in response");
        return null;
      }
    } catch (e) {
      print("Error during API call: $e");
      return null;
    }
  }

  // Save predictions to MongoDB via Node.js
  Future<void> savePredictionToDB(
      String token, PredictionModel prediction) async {
    try {
      // Include symptoms list in the payload to MongoDB
      final Map<String, dynamic> payload = prediction.toJson();
      payload['symptomsList'] = prediction.symptomsList;

      final response = await http.post(
        Uri.parse(nodeApiUrl),
        headers: {
          'Authorization':
              'Bearer $token',  // Pass the token to Node.js endpoint
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
    }
  }
}
