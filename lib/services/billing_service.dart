import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/billing_model.dart';

class BillingService {
  static const String baseUrl = "http://localhost:5000";

  // Fetch billing data
  Future<Billing> fetchBilling(String userId) async {
    final response = await http.get(Uri.parse("$baseUrl/api/billing/$userId"));

    if (response.statusCode == 200) {
      return Billing.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to fetch billing data");
    }
  }

  // Mark billing as paid
  Future<void> payBilling(String userId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/billing/pay"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to process payment");
    }
  }
}
