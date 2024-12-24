import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hospital_model.dart'; // Ensure this path is correct

class HospitalService {
  static const String baseUrl = "http://localhost:5000"; // Replace with your API URL

  /// Fetch the field configuration for a specific hospital by its name.
  Future<List<Field>> fetchFieldConfigurations(String hospitalName) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/hospitals/$hospitalName/fields"), // Update with your actual endpoint
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fieldsJson = data['fields'];
        // Map the JSON response to a list of Field objects
        return fieldsJson.map((field) => Field.fromJson(field)).toList();
      } else {
        throw Exception('Failed to load field configurations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting hospital fields: $e');
    }
  }
}