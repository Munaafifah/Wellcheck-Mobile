import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:session/models/appointment_model.dart';
import 'package:flutter/material.dart';


class AppointmentService {
  static const String baseUrl = "http://localhost:5000"; // Replace with your API URL

  // Helper method to handle API requests
  Future<http.Response> makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    Uri uri = Uri.parse("$baseUrl$endpoint");
    final response = method == 'POST'
        ? await http.post(uri, headers: headers, body: jsonEncode(body))
        : await http.get(uri, headers: headers);
    return response;
  }

  // Create a new appointment
  Future<void> createAppointment({
    required String token,
    required DateTime appointmentDate,
    required TimeOfDay appointmentTime,
    required String duration,
    required String typeOfSickness,
    required String additionalNotes,
    required String email,
    required double appointmentCost,
  }) async {
    final String formattedTime =
        '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}';

    final response = await http.post(
      Uri.parse("$baseUrl/appointments"), // Endpoint for creating appointments
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "appointmentDate": appointmentDate.toIso8601String(),
        "appointmentTime": formattedTime,
        "duration": duration,
        "typeOfSickness": typeOfSickness,
        "additionalNotes": additionalNotes,
        "email": email,
        "appointmentCost": appointmentCost,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create appointment: ${response.body}");
    }
  }

  // Fetch appointments for a specific user
  Future<List<Appointment>> fetchAppointments(String token, String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/appointments/$userId"), // Endpoint for fetching appointments
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Appointment.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch appointments: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching appointments: $e');
    }
  }

  // Update appointment's additional notes
  Future<void> updateAppointment(
      String token, String appointmentId, String newNotes) async {
    final response = await http.put(
      Uri.parse("$baseUrl/appointments/$appointmentId"), // Endpoint for updating appointments
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"additionalNotes": newNotes}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update appointment: ${response.body}");
    }
  }

  // Delete an appointment
  Future<void> deleteAppointment(String token, String appointmentId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/appointments/$appointmentId"), // Endpoint for deleting appointments
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete appointment: ${response.body}");
    }
  }
}
