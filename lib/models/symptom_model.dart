class Symptom {
  final String symptomId; // New field
  final String userId;
  final String doctorId;
  final String symptomDescription;
  final DateTime timestamp;

  Symptom({
    required this.symptomId,
    required this.userId,
    required this.doctorId,
    required this.symptomDescription,
    required this.timestamp,
  });

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      symptomId: json["symptomId"], // Parse symptomId
      userId: json["userId"],
      doctorId: json["doctorId"],
      symptomDescription: json["symptomDescription"],
      timestamp: DateTime.parse(json["timestamp"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "symptomId": symptomId, // Include symptomId in JSON
        "userId": userId,
        "doctorId": doctorId,
        "symptomDescription": symptomDescription,
        "timestamp": timestamp.toIso8601String(),
      };
}
