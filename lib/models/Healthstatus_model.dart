// HealthstatusModel.dart
class HealthstatusModel {
  final String additionalnotes;
  final String doctorID;
  final String healthstatusID;
  final DateTime timestamp;

  HealthstatusModel({
    required this.additionalnotes,
    required this.doctorID,
    required this.healthstatusID,
    required this.timestamp,
  });

  factory HealthstatusModel.fromJson(Map<String, dynamic> json) {
    return HealthstatusModel(
      additionalnotes: json["additionalNotes"],
      doctorID: json["doctorId"],
      healthstatusID: json["healthStatusId"],
      timestamp: json["timestamp"] is Map
          ? DateTime.parse(json["timestamp"]["\$date"])
          : DateTime.parse(json["timestamp"]),
    );
  }
}
