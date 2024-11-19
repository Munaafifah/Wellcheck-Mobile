class Prescription {
  final String doctorName;
  final String doctorSpecialty;
  final String patientName;
  final List<Medication>
      medicationsList; // Changed from String to a list of Medication objects
  final String diagnosis;
  final String notes;
  final String time;
  final String iddoc;

  Prescription({
    required this.doctorName,
    required this.doctorSpecialty,
    required this.patientName,
    required this.medicationsList, // Updated field
    required this.diagnosis,
    required this.notes,
    required this.time,
    required this.iddoc,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      doctorName: json['doctorName'] ?? 'Unknown',
      doctorSpecialty: json['doctorSpecialty'] ?? 'Unknown',
      patientName: json['patientName'] ?? 'Unknown',
      medicationsList: (json['medicationsList'] as List<dynamic>?)
              ?.map((item) => Medication.fromJson(item))
              .toList() ??
          [], // Parsing the list of medications
      diagnosis: json['diagnosis'] ?? 'Not specified',
      notes: json['notes'] ?? 'No notes',
      time: json['time'] ?? 'Unknown',
      iddoc: json['iddoc'] ?? 'Unknown',
    );
  }
}

class Medication {
  final String name;
  final String dosage;
  final String frequency;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'] ?? 'Unknown',
      dosage: json['dosage'] ?? 'Not specified',
      frequency: json['frequency'] ?? 'Not specified',
    );
  }
}
