import 'dart:convert';
import 'package:http/http.dart' as http;
import 'appointment_model.dart';

class AppointmentService {
  static const String _apiUrl = "http://localhost:5000/appointments"; // Replace with your API URL

  // Create a new appointment
  Future<void> createAppointment(Appointment appointment) async {
  final response = await http.post(
    Uri.parse(_apiUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(appointment.toJson()),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Failed to create appointment: ${response.body}');
  }
}



}
