import 'package:dio/dio.dart';
import 'package:session/constsPayment.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  Future<void> makePayment({required double amount}) async {
    try {
      // Convert the double amount to integer (cents)
      final intAmount = (amount).round();

      // Create payment intent with the dynamic amount
      Map<String, dynamic>? paymentIntentData =
          await _createPaymentIntent(intAmount, "MYR");

      if (paymentIntentData == null) {
        print('Failed to create payment intent');
        return;
      }

      // Initialize payment sheet with the client secret
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: "Danial Hakim",
          style: ThemeMode.system,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Colors.blue,
            ),
          ),
        ),
      );

      // Present the payment sheet
      await Stripe.instance.presentPaymentSheet();
      print('Payment completed successfully');
    } catch (e) {
      print('Error: $e');
      if (e is StripeException) {
        print('Error code: ${e.error.code}');
        print('Error message: ${e.error.message}');
      }
      throw e; // Rethrow the error to handle it in the UI
    }
  }

  Future<Map<String, dynamic>?> _createPaymentIntent(
      int amount, String currency) async {
    try {
      final Dio dio = Dio();
      final data = {
        'amount': _calculateAmount(amount),
        'currency': currency,
        'automatic_payment_methods[enabled]': 'true',
        'description': 'Payment for appointments',
      };

      print('Creating payment intent with data: $data');

      final response = await dio.post(
        'https://api.stripe.com/v1/payment_intents',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $stripeSecretKey',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Stripe-Version': '2023-10-16',
          },
        ),
      );

      print('Payment intent response: ${response.data}');
      return response.data;
    } catch (e) {
      if (e is DioError) {
        print('Error creating payment intent: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      } else {
        print('Error: $e');
      }
      return null;
    }
  }

  String _calculateAmount(int amount) {
    // Amount should be in smallest currency unit (cents)
    final calculatedAmount = amount * 100;
    return calculatedAmount.toString();
  }
}
