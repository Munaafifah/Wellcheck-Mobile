import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_model.dart';

class LoginService {
  static const String baseUrl = "http://localhost:5000";

  Future<String?> login(LoginRequest request) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      body: jsonEncode(request.toJson()),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["token"];
    } else {
      return null;
    }
  }
}