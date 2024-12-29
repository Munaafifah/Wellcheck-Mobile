import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profile_model.dart';

class ProfileService {
  static const String baseUrl = "http://10.0.2.2:5000";

  Future<PatientProfile?> fetchPatient(String userId, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/patient/$userId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PatientProfile.fromJson(data);
    } else {
      return null;
    }
  }

  Future<bool> updatePatient(String userId, PatientProfile updatedProfile, String token) async {
  try {
    // Build the update data only with the fields that are not null or empty
    final updateData = <String, dynamic>{};

    if (updatedProfile.name.isNotEmpty) updateData["name"] = updatedProfile.name;
    if (updatedProfile.address.isNotEmpty) updateData["address"] = updatedProfile.address;
    if (updatedProfile.contact.isNotEmpty) updateData["contact"] = updatedProfile.contact;
    if (updatedProfile.emergencyContact.isNotEmpty) updateData["emergencyContact"] = updatedProfile.emergencyContact;

    final response = await http.put(
      Uri.parse("$baseUrl/patient/$userId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(updateData),  // Send only the fields that need to be updated
    );

    return response.statusCode == 200;
  } catch (e) {
    print("Error updating patient: $e");
    return false;
  }
}

}
