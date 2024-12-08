import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class Sickness {
  final String appointmentId; // Unique identifier for the sickness
  final String name; // Name of the sickness
  final double appointmentPrice; // Price associated with the appointment

  Sickness({
    required this.appointmentId,
    required this.name,
    required this.appointmentPrice,
  });

  // Convert Sickness object to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      "appointmentId": appointmentId,
      "name": name,
      "appointmentPrice": appointmentPrice,
    };
  }

  // Create Sickness object from JSON response
  factory Sickness.fromJson(Map<String, dynamic> json) {
    return Sickness(
      appointmentId: json["_id"] ?? '', // Use the MongoDB _id or equivalent
      name: json["name"] ?? 'Unknown', // Assuming appointmentType as name
      appointmentPrice: (json['appointmentPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}