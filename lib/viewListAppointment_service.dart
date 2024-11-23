import 'dart:convert';
import 'package:http/http.dart' as http;
import 'appointment_model.dart';

class AppointmentService {
  static const String _apiUrl =
      "http://localhost:5000/appointments"; // Replace with your actual API URL

  /// Fetch all appointments from the database.
  Future<List<Appointment>> fetchAppointments() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        // Parse the JSON response into a list of Appointment objects.
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Appointment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetchs appointments: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching appointments: $e');
    }
  }
}
