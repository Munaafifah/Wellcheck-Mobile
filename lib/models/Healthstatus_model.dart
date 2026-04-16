class HealthstatusModel {
  final String additionalnotes;
  final String doctorID;
  final String healthstatusID;
  final DateTime timestamp;
  final List<String> diagnosisList; // ← add this

  HealthstatusModel({
    required this.additionalnotes,
    required this.doctorID,
    required this.healthstatusID,
    required this.timestamp,
    this.diagnosisList = const [], // ← add this
  });

  factory HealthstatusModel.fromJson(Map<String, dynamic> json) {
    return HealthstatusModel(
      additionalnotes: json["additionalNotes"] ?? "",
      doctorID: json["doctorId"] ?? "",
      healthstatusID: json["healthStatusId"] ?? "",
      timestamp: json["timestamp"] is Map
          ? DateTime.parse(json["timestamp"]["\$date"])
          : DateTime.parse(json["timestamp"]),
      diagnosisList: List<String>.from(json["diagnosisList"] ?? []), // ← add this
    );
  }
}