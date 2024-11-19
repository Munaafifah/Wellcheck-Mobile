import 'dart:convert';
import 'package:http/http.dart' as http;
import 'appointment_model.dart';

class AppointmentService {
  final String baseUrl = "https://your-api-url.com"; // Replace with your API URL

  // Create a new appointment
  Future<void> createAppointment(Appointment appointment) async {
    final url = Uri.parse('$baseUrl/appointments');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(appointment.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create appointment');
    }
  }

  // Fetch all appointments for a specific user
  Future<List<Appointment>> fetchAppointments(String userId) async {
    final url = Uri.parse('$baseUrl/appointments?userId=$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Appointment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load appointments');
    }
  }
}
