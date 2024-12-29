import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hospital_model.dart'; // Ensure this path is correct
import '../config.dart';

class HospitalService {
  static const String baseUrl = Config.baseUrl;

  final http.Client
      client; // Use an instance of http.Client for better management

  HospitalService({http.Client? client}) : client = client ?? http.Client();

  Future<List<Hospital>> fetchHospitals() async {
    try {
      final response = await client
          .get(Uri.parse('$baseUrl/hospitals'))
          .timeout(const Duration(seconds: 10)); // Timeout after 10 seconds

      if (response.statusCode == 200) {
        // Parse the JSON successfully
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Hospital.fromJson(item)).toList();
      } else {
        // Log the error for better debugging
        print(
            'Failed response: ${response.statusCode}, Body: ${response.body}');
        switch (response.statusCode) {
          case 404:
            throw Exception('No hospitals found');
          case 500:
            throw Exception('Server error while fetching hospitals');
          default:
            throw Exception('Failed to fetch hospitals: ${response.body}');
        }
      }
    } on http.ClientException {
      throw Exception("Client error occurred");
    }
  }
}
