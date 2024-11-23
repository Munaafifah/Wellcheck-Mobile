import 'package:intl/intl.dart'; // For date formatting

class Appointment {
  final DateTime appointmentDate; // Store only the date part
  final String appointmentTime; // Time as a string (e.g., "14:30")
  final String duration; // e.g., "30 min"
  final String typeOfSickness;
  final String additionalNotes;
  final double appointmentCost; // Cost of the appointment

  Appointment({
    required this.appointmentDate,
    required this.appointmentTime,
    required this.duration,
    required this.typeOfSickness,
    required this.additionalNotes,
    required this.appointmentCost, // Cost is calculated or fetched
  });

  /// Convert Appointment object to JSON
  Map<String, dynamic> toJson() {
    return {
      'appointmentDate': DateFormat('yyyy-MM-dd').format(appointmentDate),
      'appointmentTime': appointmentTime,
      'duration': duration,
      'typeOfSickness': typeOfSickness,
      'additionalNotes': additionalNotes,
      'appointmentCost': appointmentCost,
    };
  }

  /// Create Appointment object from JSON
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      appointmentDate: json['appointmentDate'] != null
          ? DateTime.tryParse(json['appointmentDate']) ?? DateTime.now()
          : DateTime.now(),
      appointmentTime: json['appointmentTime']?.toString() ?? '00:00',
      duration: json['duration']?.toString() ?? '0 min',
      typeOfSickness: json['typeOfSickness']?.toString() ?? 'Unknown',
      additionalNotes:
          json['additionalNotes']?.toString() ?? 'No additional notes',
      appointmentCost: (json['appointmentCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Calculate the cost of the appointment based on duration
  static double calculateCost(String duration) {
    // Extract numeric values from the duration string
    final durationMinutes =
        int.tryParse(RegExp(r'\d+').stringMatch(duration) ?? '0') ?? 0;
    return durationMinutes * 1.0; // RM1 per minute
  }

  /// Factory to create an Appointment and calculate cost dynamically
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

  /// Method to format the appointment date for display purposes
  String getFormattedDate() {
    return DateFormat('yyyy-MM-dd').format(appointmentDate);
  }

  /// Method to format the appointment time for display purposes
  String getFormattedTime() {
    // Additional parsing can be done here if required
    return appointmentTime; // Returns time as a string
  }

  /// Get duration in minutes
  int getDurationInMinutes() {
    return int.tryParse(RegExp(r'\d+').stringMatch(duration) ?? '0') ?? 0;
  }

  /// Get formatted appointment details for UI display
  String getFormattedDetails() {
    return '''
    Date: ${getFormattedDate()}
    Time: ${getFormattedTime()}
    Duration: $duration
    Cost: RM ${appointmentCost.toStringAsFixed(2)}
    ''';
  }
}
