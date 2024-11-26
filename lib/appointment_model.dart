import 'package:intl/intl.dart'; // For date formatting

class Appointment {
  final DateTime appointmentDate; // Changed to DateTime
  final String appointmentTime; // String to represent time in a readable format
  final String duration;
  final String typeOfSickness;
  final String additionalNotes;
  final double appointmentCost; // Cost of the appointment

  Appointment({
    required this.appointmentDate,
    required this.appointmentTime,
    required this.duration,
    required this.typeOfSickness,
    required this.additionalNotes,
    required this.appointmentCost, // Added appointment cost as a required field
  });

  // Convert Appointment object to JSON
  Map<String, dynamic> toJson() {
    return {
      'appointmentDate': DateFormat('yyyy-MM-dd')
          .format(appointmentDate), // Format date as string
      'appointmentTime': appointmentTime, // Time as a string (e.g., "14:30")
      'duration': duration,
      'typeOfSickness': typeOfSickness,
      'additionalNotes': additionalNotes,
      'appointmentCost': appointmentCost, // Include appointment cost
    };
  }

  // Create Appointment object from JSON
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      appointmentDate: json['appointmentDate'] != null
          ? DateTime.tryParse(json['appointmentDate']) ?? DateTime.now()
          : DateTime.now(),
      appointmentTime: json['appointmentTime'] ?? 'No time provided',
      typeOfSickness: json['typeOfSickness'] ?? 'Unknown',
      duration: json['duration'] ?? '0 min',
      additionalNotes: json['additionalNotes'] ?? 'No additional notes',
      appointmentCost: (json['appointmentCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Method to calculate the cost of the appointment based on duration
  static double calculateCost(String duration) {
    final durationMinutes =
        int.tryParse(duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return durationMinutes * 1.0; // RM1 per minute
  }

  // Factory to create an Appointment and calculate cost dynamically
  factory Appointment.withCalculatedCost({
    required DateTime appointmentDate,
    required String appointmentTime,
    required String duration,
    required String typeOfSickness,
    required String additionalNotes,
  }) {
    final cost = calculateCost(duration);
    return Appointment(
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      duration: duration,
      typeOfSickness: typeOfSickness,
      additionalNotes: additionalNotes,
      appointmentCost: cost,
    );
  }

  // Method to format the appointment date for display purposes
  String getFormattedDate() {
    return DateFormat('yyyy-MM-dd').format(appointmentDate);
  }
}
