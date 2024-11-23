import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_model.dart';

class LoginService {
  static const String _apiUrl = 'http://localhost:5000/login';

  static Future<Map<String, dynamic>> login({
    required String userId,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromJson(responseData['user']);
        
        // Check user role from database
        if (user.role.trim().toLowerCase() == 'patient') {
          return {
            'success': true,
            'message': 'Login successful',
            'user': user,
          };
        } else {
          return {
            'success': false,
            'message': 'Access denied: Only patients can login through this portal',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Invalid userId or password',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'An error occurred',
        };
      }
    } catch (e) {
      print('Error during login: $e');
      return {
        'success': false,
        'message': 'Network error: Unable to connect to server',
      };
    }
  }
}
