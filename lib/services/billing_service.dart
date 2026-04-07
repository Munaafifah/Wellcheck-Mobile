import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/billing_model.dart';
import '../config.dart';

class BillingService {
  static const String baseUrl = Config.baseUrl;
  final _storage = const FlutterSecureStorage();

  // Fetch billing data
  Future<List<Billing>> fetchBilling(String userId) async {
    final token = await _storage.read(key: "auth_token");
    if (token == null) throw Exception("Authentication token not found");

    final response = await http.get(
      Uri.parse("$baseUrl/api/billing/$userId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("DEBUG BILLING STATUS: ${response.statusCode}");
    print("DEBUG BILLING BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((e) => Billing.fromJson(e)).toList();
      } else {
        return [Billing.fromJson(decoded)];
      }
    } else if (response.statusCode == 404) {
      return []; // ✅ No appointments found — return empty list, not an error
    } else {
      throw Exception("Failed to fetch billing data: ${response.body}");
    }
  }

  // Mark billing as paid
  Future<void> payBilling(String userId) async {
    final token = await _storage.read(key: "auth_token");
    if (token == null) throw Exception("Authentication token not found");

    final response = await http.post(
      Uri.parse("$baseUrl/api/billing/pay"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"userId": userId}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to process payment: ${response.body}");
    }
  }
}
