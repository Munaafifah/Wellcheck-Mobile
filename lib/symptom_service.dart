import 'dart:convert';
import 'package:http/http.dart' as http;

class SymptomService {
  static const String _apiUrl =
      'http://localhost:5000/symptoms'; // Replace with actual endpoint

  static Future<bool> sendSymptom(String symptom) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'symptom': symptom}),
      );

      if (response.statusCode == 200) {
        // Successfully sent
        return true;
      } else {
        // Handle server errors
        print('Failed to send symptom: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Handle network errors
      print('Error sending symptom: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getSymptoms() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        print('Failed to fetch symptoms: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching symptoms: $e');
      return [];
    }
  }

  static Future<bool> deleteSymptom(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting symptom: $e');
      return false;
    }
  }

  static Future<bool> editSymptom(String id, String newDescription) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'description': newDescription}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error editing symptom: $e');
      return false;
    }
  }
}
