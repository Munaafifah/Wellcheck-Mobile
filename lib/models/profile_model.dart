class PatientProfile {
  final String name;
  final String address;
  final String contact;
  final String emergencyContact;

  PatientProfile({
    required this.name,
    required this.address,
    required this.contact,
    required this.emergencyContact,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      name: json["name"],
      address: json["address"],
      contact: json["contact"],
      emergencyContact: json["emergencyContact"],
    );
  }
}
