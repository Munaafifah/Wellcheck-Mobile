import 'dart:convert';
import 'package:http/http.dart' as http;
import 'prescriptions_model.dart';

class MongoDBService {
  static const String _apiUrl =
      'http://localhost:5000/prescriptions'; // Update to the correct endpoint

  static Future<Prescription?> fetchPrescription() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Prescription.fromJson(
            data); // Deserialize into Prescription model
      } else {
        return null; // Failed to load data
      }
    } catch (e) {
      print('Error fetching data: $e');
      return null; // Handle errors
    }
  }
}
