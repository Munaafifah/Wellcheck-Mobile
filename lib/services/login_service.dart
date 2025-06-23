import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_model.dart';
import '../config.dart';

class LoginService {
  Future<String?> login(LoginRequest request) async {
    try {
      final url = Uri.parse('${Config.baseUrl}/login');
      
      print('🌐 Making request to: $url');
      print('📤 Request body: ${jsonEncode(request.toJson())}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(Duration(seconds: 15));
      
      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      print('📋 Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else if (response.statusCode == 401) {
        throw Exception('Invalid credentials');
      } else if (response.statusCode == 403) {
        throw Exception('Access restricted to patients');
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Login failed');
      }
    } catch (e) {
      print('🚨 LoginService Error: $e');
      rethrow;
    }
  }
}

class LoginRequest {
  final String userId;
  final String password;
  
  LoginRequest({required this.userId, required this.password});
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'password': password,
    };
  }
}