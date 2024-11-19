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
}
