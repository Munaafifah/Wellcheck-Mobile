import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class Appointment {
  final String appointmentId;
  final String userId;
  final String doctorId;
  final String hospitalId; // Added hospital association
  final DateTime appointmentDate;
  final TimeOfDay appointmentTime;
  final String duration;
  final String typeOfSickness; // Made optional for non-medical visits
  final String additionalNotes;
  final String email;
  final double appointmentCost;
  final String statusPayment; // New property for payment status
  final String statusAppointment; // New property for appointment status
  final String? insuranceProvider; // New: Insurance provider info
  final String? insurancePolicyNumber; // New: Insurance policy number
  final String? preferredLanguage; // New: Preferred language for consultation
  final String registeredHospital; // New attribute for registered hospital

  Appointment({
    required this.appointmentId,
    required this.userId,
    required this.doctorId,
    required this.hospitalId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.duration,
    required this.typeOfSickness,
    required this.additionalNotes,
    required this.email,
    required this.appointmentCost,
    required this.registeredHospital, // Initialize the registeredHospital
    this.statusPayment = "Not Paid", // Initialized to "not paid"
    this.statusAppointment = "Not Approved", // Initialized to "scheduled"
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.preferredLanguage,
  });

  // Convert Appointment object to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      "appointmentId": appointmentId,
      "userId": userId,
      "doctorId": doctorId,
      "hospitalId": hospitalId, // Include hospitalId in JSON
      "appointmentDate": DateFormat('yyyy-MM-dd').format(appointmentDate),
      "appointmentTime":
          '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}',
      'duration': duration,
      'typeOfSickness': typeOfSickness,
      'additionalNotes': additionalNotes,
      'email': email,
      'appointmentCost': appointmentCost,
      'statusPayment': statusPayment,
      'statusAppointment': statusAppointment,
      'insuranceProvider': insuranceProvider,
      'insurancePolicyNumber': insurancePolicyNumber,
      'preferredLanguage': preferredLanguage,
      'registeredHospital':
          registeredHospital, // Include registeredHospital in JSON
    };
  }

  // Create Appointment object from JSON response
  factory Appointment.fromJson(Map<String, dynamic> json) {
    late TimeOfDay parsedTime;
    try {
      final timeParts = (json['appointmentTime'] as String).split(':');
      parsedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    } catch (e) {
      parsedTime = const TimeOfDay(hour: 0, minute: 0);
      debugPrint('Error parsing appointmentTime: $e');
    }

    return Appointment(
      appointmentId: json["appointmentId"] ?? '',
      userId: json["userId"] ?? '',
      doctorId: json["doctorId"] ?? '',
      hospitalId: json["hospitalId"] ?? '',
      appointmentDate: json['appointmentDate'] != null
          ? DateTime.tryParse(json['appointmentDate']) ?? DateTime.now()
          : DateTime.now(),
      appointmentTime: parsedTime,
      duration: json['duration'] ?? '0',
      typeOfSickness: json['typeOfSickness'],
      additionalNotes:
          json['additionalNotes'] ?? 'No additional notes provided',
      email: json['email'] ?? 'No email provided',
      appointmentCost: (json['appointmentCost'] as num?)?.toDouble() ?? 0.0,
      statusPayment: json['statusPayment'] ?? 'Not paid',
      statusAppointment: json['statusAppointment'] ?? 'Not Approved',
      insuranceProvider: json['insuranceProvider'],
      insurancePolicyNumber: json['insurancePolicyNumber'],
      preferredLanguage: json['preferredLanguage'],
      registeredHospital:
          json['registeredHospital'] ?? '', // Parse registeredHospital
    );
  }

  // Method to format the appointment date for display purposes
  String getFormattedDate() {
    return DateFormat('dd MMM yyyy').format(appointmentDate);
  }

  // Method to format the appointment time for display
  String getFormattedTime() {
    return '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}';
  }
}
