import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appointment_model.dart';
import 'package:flutter/material.dart';
import '../config.dart';

class AppointmentService {
  static const String baseUrl = Config.baseUrl; // Replace with your API URL

  // Helper method to handle API requests
  Future<http.Response> makeRequest(
      String method,
      String endpoint, {
        Map<String, String>? headers,
        dynamic body,
      }) async {
    Uri uri = Uri.parse("$baseUrl$endpoint");
    if (method == 'POST') {
      return await http.post(uri, headers: headers, body: jsonEncode(body));
    } else if (method == 'PUT') {
      return await http.put(uri, headers: headers, body: jsonEncode(body));
    } else if (method == 'GET') {
      return await http.get(uri, headers: headers);
    } else if (method == 'DELETE') {
      return await http.delete(uri, headers: headers);
    }
    throw Exception('Unsupported HTTP method: $method');
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
    required String hospitalId,
    required String registeredHospital,
    String statusPayment = "Not Paid", // Optional parameter
    String statusAppointment = "Not Approved", // Optional parameter
    String? insuranceProvider, // Optional parameter for insurance provider
    String? insurancePolicyNumber, // Optional parameter for insurance policy number
    String? preferredLanguage, // Optional parameter for preferred language
  }) async {
    final String formattedTime =
        '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}';

    // Validate input fields
    if (typeOfSickness.isEmpty) {
      throw Exception("Type of sickness cannot be empty.");
    }

    final response = await makeRequest('POST', '/appointments', headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    }, body: {
      "appointmentDate": appointmentDate.toIso8601String(),
      "appointmentTime": formattedTime,
      "duration": duration,
      "typeOfSickness": typeOfSickness,
      "additionalNotes": additionalNotes,
      "email": email,
      "appointmentCost": appointmentCost,
      "statusPayment": statusPayment,
      "statusAppointment": statusAppointment,
      "hospitalId": hospitalId,
      "registeredHospital": registeredHospital,
      "insuranceProvider": insuranceProvider,
      "insurancePolicyNumber": insurancePolicyNumber,
      "preferredLanguage": preferredLanguage,
    });

    // Handle response
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

  // Update appointment's date, time, duration, and type of sickness
  Future<void> updateAppointment(
    String token,
    String appointmentId,
    String appointmentDate,  // Expecting ISO formatted string
    String appointmentTime,   // Expecting "HH:mm" formatted string
    String duration,          // Duration in string format
    String typeOfSickness     // Type of sickness
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/appointments/$appointmentId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "appointmentDate": appointmentDate,   // Send appointment date
        "appointmentTime": appointmentTime,    // Send appointment time
        "duration": duration,                   // Send duration
        "typeOfSickness": typeOfSickness,      // Send type of sickness
      }),
    );

    // Check for successful response
    if (response.statusCode != 200) {
      throw Exception("Failed to update appointment: ${response.body}");
    }
  }

  // Delete an appointment
  Future<void> deleteAppointment(String token, String appointmentId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/appointments/$appointmentId"), // Endpoint for deleting appointment
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete appointment: ${response.body}");
    }
  }
}