class Patient {
  final String name;
  final String address;
  final String contact;
  final String emergencyContact;
  final String assignedDoctor;

  Patient({
    required this.name,
    required this.address,
    required this.contact,
    required this.emergencyContact,
    required this.assignedDoctor,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      name: json["name"],
      address: json["address"],
      contact: json["contact"],
      emergencyContact: json["emergencyContact"],
      assignedDoctor: json["assigned_doctor"],
    );
  }
}
