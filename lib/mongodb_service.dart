import 'dart:convert';
import 'package:http/http.dart' as http;
import 'prescriptions_model.dart'; // Combined model file

class MongoDBService {
  static const String _apiUrl =
      'http://localhost:5000/patients/:id/prescriptions'; // Update to the correct endpoint

  static Future<Patient?> fetchPatientData(String patientId) async {
    try {
      // Assuming the endpoint takes a patientId as a query parameter
      final response = await http.get(Uri.parse('$_apiUrl/$patientId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Patient.fromJson(data); // Deserialize into Patient model
      } else {
        print(
            'Failed to load patient data. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching patient data: $e');
      return null; // Handle errors
    }
  }
}
