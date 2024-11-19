class Appointment {
  final String? id;
  final String doctorId;
  final DateTime appointmentDateTime;
  final String duration;
  final String typeOfSickness;
  final String additionalNotes;
  final String userId;

  Appointment({
    this.id,
    required this.doctorId,
    required this.appointmentDateTime,
    required this.duration,
    required this.typeOfSickness,
    required this.additionalNotes,
    required this.userId,
  });

  // Convert Appointment object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'appointmentDateTime': appointmentDateTime.toIso8601String(),
      'duration': duration,
      'typeOfSickness': typeOfSickness,
      'additionalNotes': additionalNotes,
      'userId': userId,
    };
  }

  // Create Appointment object from JSON
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      doctorId: json['doctorId'],
      appointmentDateTime: DateTime.parse(json['appointmentDateTime']),
      duration: json['duration'],
      typeOfSickness: json['typeOfSickness'],
      additionalNotes: json['additionalNotes'],
      userId: json['userId'],
    );
  }
}
