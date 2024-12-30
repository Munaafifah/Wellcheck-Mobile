import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profile2_model.dart';
import '../config.dart';
import 'package:dio/dio.dart';

class Profile2Service {
  final Dio _dio = Dio();
  static const String baseUrl = Config.baseUrl;

  Future<UserProfile?> fetchUser(String userId, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/user/$userId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      print(
          "API Response: ${response.body}"); // Print the API response for debugging
      final data = jsonDecode(response.body);
      return UserProfile.fromJson(data);
    } else {
      print(
          "Error: ${response.statusCode}"); // Print error if status is not 200
      return null;
    }
  }
Future<bool> updateUser(String userId, UserProfile updatedProfile, String token) async {
  try {
    // Create a map with only the fields that have values
    Map<String, dynamic> updateData = {};
    
    // Only include fields that are not null and have changed
    if (updatedProfile.password != null) updateData['password'] = updatedProfile.password;
    if (updatedProfile.userId != null) updateData['userId'] = updatedProfile.userId;
    
    final response = await http.put(
      Uri.parse("$baseUrl/user/$userId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Error: Status code ${response.statusCode}, Body: ${response.body}");
      return false;
    }
  } catch (e) {
    print("Error updating user: $e");
    return false;
  }
}

/// Update user password
  Future<bool> updatePassword(String userId, String newPassword, String token) async {
  final url = Uri.parse('$baseUrl/user/$userId/password');

  try {
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'newPassword': newPassword}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Error: ${response.statusCode}, Body: ${response.body}");
      return false;
    }
  } catch (e) {
    print("Error updating password: $e");
    return false;
  }
}


  // Update user profile image (with image as Base64 string)
Future<bool> uploadProfileImage(String userId, String base64Image, String token) async {
  final url = Uri.parse('$baseUrl/user/uploadImage/$userId');

  try {
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'profilepic': base64Image}),  // Send Base64 image
    );

    if (response.statusCode == 200) {
      print('Profile image uploaded successfully');
      return true;
    } else {
      print('Failed to upload image: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print("Error uploading image: $e");
    return false;
  }
}

Future<String?> fetchProfileImage(String userId, String token) async {
  final response = await http.get(
    Uri.parse("$baseUrl/user/profileImage/$userId"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['profilepic'];
  } else {
    print("Failed to fetch profile image: ${response.statusCode}");
    return null;
  }
}

  Future<bool> verifyPassword(String userId, String currentPassword, String token) async {
    try {
      final response = await _dio.post(
        '$baseUrl/verify-password',
        data: {
          'userId': userId,
          'password': currentPassword,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }


}

