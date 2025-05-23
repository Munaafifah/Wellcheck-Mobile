import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class Appointment {
  final String appointmentId;
  final String userId;
  final String doctorId;
  final String hospitalId;
  final String registeredHospital;
  final DateTime appointmentDate;
  final TimeOfDay appointmentTime;
  final String duration;
  final String typeOfSickness;
  final String additionalNotes;
  final String email;
  final double appointmentCost;
  final String statusPayment;
  final String statusAppointment;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final String? preferredLanguage;
  
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
    required this.registeredHospital,
    this.statusPayment = "Not Paid",
    this.statusAppointment = "Not Approved",
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
      "hospitalId": hospitalId,
      "registeredHospital": registeredHospital,
      "appointmentDate": DateFormat('yyyy-MM-dd').format(appointmentDate), // Send as formatted string
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
      registeredHospital: json["registeredHospital"] ?? '',
      appointmentDate: json['appointmentDate'] != null
          ? DateFormat('yyyy-MM-dd').parse(json['appointmentDate']) // Parse correctly
          : DateTime.now(),
      appointmentTime: parsedTime,
      duration: json['duration'] ?? '0',
      typeOfSickness: json['typeOfSickness'] ?? '',
      additionalNotes: json['additionalNotes'] ?? 'No additional notes provided',
      email: json['email'] ?? 'No email provided',
      appointmentCost: (json['appointmentCost'] as num?)?.toDouble() ?? 0.0,
      statusPayment: json['statusPayment'] ?? 'Not paid',
      statusAppointment: json['statusAppointment'] ?? 'Not Approved',
      insuranceProvider: json['insuranceProvider'],
      insurancePolicyNumber: json['insurancePolicyNumber'],
      preferredLanguage: json['preferredLanguage'],
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