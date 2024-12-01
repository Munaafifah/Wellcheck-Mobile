import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class Appointment {
  final String appointmentId;
  final String userId;
  final String doctorId;
  final DateTime appointmentDate;
  final TimeOfDay appointmentTime;
  final String duration;
  final String typeOfSickness;
  final String additionalNotes;
  final String email;
  final double appointmentCost;

  Appointment({
    required this.appointmentId,
    required this.userId,
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.duration,
    required this.typeOfSickness,
    required this.additionalNotes,
    required this.email,
    required this.appointmentCost,
  });

  // Convert Appointment object to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      "appointmentId": appointmentId,
      "userId": userId,
      "doctorId": doctorId,
      "appointmentDate": DateFormat('yyyy-MM-dd').format(appointmentDate), // Convert date to string
      "appointmentTime":
          '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}', // Convert TimeOfDay to HH:mm string
      'duration': duration,
      'typeOfSickness': typeOfSickness,
      'additionalNotes': additionalNotes,
      'email': email,
      'appointmentCost': appointmentCost,
    };
  }

  // Create Appointment object from JSON response
  factory Appointment.fromJson(Map<String, dynamic> json) {
    // Parse TimeOfDay from string (e.g., "14:30")
    late TimeOfDay parsedTime;
    try {
      final timeParts = (json['appointmentTime'] as String).split(':');
      parsedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    } catch (e) {
      parsedTime = const TimeOfDay(hour: 0, minute: 0); // Default to midnight on error
      debugPrint('Error parsing appointmentTime: $e');
    }

    return Appointment(
      appointmentId: json["appointmentId"] ?? '',
      userId: json["userId"] ?? '',
      doctorId: json["doctorId"] ?? '',
      appointmentDate: json['appointmentDate'] != null
          ? DateTime.tryParse(json['appointmentDate']) ?? DateTime.now()
          : DateTime.now(),
      appointmentTime: parsedTime,
      duration: json['duration'] ?? '0',
      typeOfSickness: json['typeOfSickness'] ?? 'Unknown',
      additionalNotes: json['additionalNotes'] ?? 'No additional notes provided',
      email: json['email'] ?? 'No email provided',
      appointmentCost: (json['appointmentCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Method to calculate the cost of the appointment
  static double calculateCost(String duration) {
    final durationMinutes = int.tryParse(duration) ?? 0;
    return durationMinutes * 1.0; // RM1 per minute
  }

  // Method to format the appointment date for display purposes
  String getFormattedDate() {
    return DateFormat('dd MMM yyyy').format(appointmentDate); // e.g., 26 Nov 2024
  }

  // Method to format the appointment time for display
  String getFormattedTime() {
    return '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}'; // e.g., "14:30"
  }
}
