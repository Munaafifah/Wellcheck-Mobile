class Patient {
  final String id;
  final String name;
  final String address;
  final String contact;
  final String emergencyContact;
  final String assignedDoctor;
  final String sensorDataId;
  final String status;
  final List<Prescription> prescriptions;
  final List<HealthStatus> healthStatus;

  Patient({
    required this.id,
    required this.name,
    required this.address,
    required this.contact,
    required this.emergencyContact,
    required this.assignedDoctor,
    required this.sensorDataId,
    required this.status,
    required this.prescriptions,
    required this.healthStatus,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] ?? 'Unknown',
      name: json['name'] ?? 'Unknown',
      address: json['address'] ?? 'Unknown',
      contact: json['contact'] ?? 'Unknown',
      emergencyContact: json['emergencyContact'] ?? 'Unknown',
      assignedDoctor: json['assigned_doctor'] ?? 'Unknown',
      sensorDataId: json['sensorDataId'] ?? 'Unknown',
      status: json['status'] ?? 'Unknown',
      prescriptions: (json['prescriptions'] as List<dynamic>? ?? [])
          .map((item) => Prescription.fromJson(item))
          .toList(),
      healthStatus: (json['healthStatus'] as List<dynamic>? ?? [])
          .map((item) => HealthStatus.fromJson(item))
          .toList(),
    );
  }
}

class Prescription {
  final String prescriptionId;
  final String diagnosisAilmentDescription;
  final String prescriptionDescription;
  final String doctorId;
  final String timestamp;
  final List<Medication> medicineList;

  Prescription({
    required this.prescriptionId,
    required this.diagnosisAilmentDescription,
    required this.prescriptionDescription,
    required this.doctorId,
    required this.timestamp,
    required this.medicineList,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      prescriptionId: json['prescriptionId'] ?? 'Unknown',
      diagnosisAilmentDescription:
          json['diagnosisAilmentDescription'] ?? 'Not specified',
      prescriptionDescription: json['prescriptionDescription'] ?? 'No description',
      doctorId: json['doctorId'] ?? 'Unknown',
      timestamp: json['timestamp'] ?? 'Unknown',
      medicineList: (json['medicineList'] as List<dynamic>? ?? [])
          .map((item) => Medication.fromJson(item))
          .toList(),
    );
  }
}

class Medication {
  final String name;
  final String dosage;

  Medication({
    required this.name,
    required this.dosage,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'] ?? 'Unknown',
      dosage: json['dosage'] ?? 'Not specified',
    );
  }
}

class HealthStatus {
  final String healthStatusId;
  final String doctorId;
  final String additionalNotes;
  final String timestamp;

  HealthStatus({
    required this.healthStatusId,
    required this.doctorId,
    required this.additionalNotes,
    required this.timestamp,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      healthStatusId: json['healthStatusId'] ?? 'Unknown',
      doctorId: json['doctorId'] ?? 'Unknown',
      additionalNotes: json['additionalNotes'] ?? 'No notes',
      timestamp: json['timestamp'] ?? 'Unknown',
    );
  }
}
