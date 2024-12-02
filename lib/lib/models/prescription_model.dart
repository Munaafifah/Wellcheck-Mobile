class Prescription {
  final String prescriptionId;
  final String diagnosisAilmentDescription;
  final String doctorId;
  final List<String> medicineList;
  final String prescriptionDescription;
  final DateTime timestamp;

  Prescription({
    required this.prescriptionId,
    required this.diagnosisAilmentDescription,
    required this.doctorId,
    required this.medicineList,
    required this.prescriptionDescription,
    required this.timestamp,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      prescriptionId: json["prescriptionId"],
      diagnosisAilmentDescription: json["diagnosisAilmentDescription"],
      doctorId: json["doctorId"],
      medicineList: List<String>.from(json["medicineList"]),
      prescriptionDescription: json["prescriptionDescription"],
      timestamp: DateTime.parse(json["timestamp"]),
    );
  }
}
