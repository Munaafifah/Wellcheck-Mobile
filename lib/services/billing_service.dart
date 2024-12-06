import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:session/models/billing_model.dart';
import 'package:session/models/appointment_model.dart';
import 'package:session/models/prescription_model.dart';
import 'package:flutter/material.dart';

class BillingService {
  static const String baseUrl =
      "http://localhost:5000"; // Replace with your API URL

  // Helper method to handle API requests
  Future<http.Response> makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    Uri uri = Uri.parse("$baseUrl$endpoint");
    final response = method == 'POST'
        ? await http.post(uri, headers: headers, body: jsonEncode(body))
        : method == 'GET'
            ? await http.get(uri, headers: headers)
            : method == 'PUT'
                ? await http.put(uri, headers: headers, body: jsonEncode(body))
                : await http.delete(uri, headers: headers);
    return response;
  }

  // Create a new billing record
  Future<void> createBilling({
    required String token,
    required String billingId,
    required double totalCost,
    required String userId,
    required Appointment appointment,
    required Prescription prescription,
  }) async {
    final response = await makeRequest(
      'POST',
      '/billings',
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: {
        "billingId": billingId,
        "totalCost": totalCost,
        "userId": userId,
        "appointment": appointment.toJson(),
        "prescription": prescription.toJson(),
        "statusPayment": "Not Paid", // Set initial status to "Not Paid"
        "timestamp": DateTime.now().toIso8601String(),
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create billing: ${response.body}");
    }
  }

  // Fetch billings for a specific user
  Future<List<Billing>> fetchBillings(String token, String userId) async {
    try {
      final response = await http.get(
        Uri.parse(
            "$baseUrl/billings/$userId"), // Endpoint for fetching billings
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Billing.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch billings: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching billings: $e');
    }
  }

  // Update billing status to "Paid"
  Future<void> updateBillingStatusToPaid(
    String token,
    String billingId,
  ) async {
    final response = await http.put(
      Uri.parse(
          "$baseUrl/billings/$billingId"), // Endpoint for updating billing status
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"statusPayment": "Paid"}), // Update status to "Paid"
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update billing status: ${response.body}");
    }
  }

  // Delete a billing record
  Future<void> deleteBilling(String token, String billingId) async {
    final response = await http.delete(
      Uri.parse(
          "$baseUrl/billings/$billingId"), // Endpoint for deleting billings
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete billing: ${response.body}");
    }
  }
}
