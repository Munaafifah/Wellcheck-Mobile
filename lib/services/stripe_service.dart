import 'package:dio/dio.dart';
import 'package:session/constsPayment.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';

enum PaymentMethod { stripe, paypal, googlePay, applePay, bankTransfer }

class BankAccountDetails {
  final String accountNumber;
  final String bankName;
  final String accountHolderName;
  final String swiftCode;

  BankAccountDetails({
    required this.accountNumber,
    required this.bankName,
    required this.accountHolderName,
    required this.swiftCode,
  });

  Map<String, String> toMap() => {
        'accountNumber': accountNumber,
        'bankName': bankName,
        'accountHolderName': accountHolderName,
        'swiftCode': swiftCode,
      };
}

class PaymentConfig {
  final double amount;
  final String currency;
  final String description;
  final String merchantName;
  final BankAccountDetails? bankDetails;

  PaymentConfig({
    required this.amount,
    this.currency = 'MYR',
    this.description = 'Payment for appointments',
    this.merchantName = 'Danial Hakim',
    this.bankDetails,
  });
}

abstract class PaymentBuilder {
  Future<void> buildPaymentIntent();
  Future<void> buildPaymentSheet();
  Future<void> presentPayment();
  void setConfig(PaymentConfig config);
}

class StripePaymentBuilder implements PaymentBuilder {
  PaymentConfig? _config;
  Map<String, dynamic>? _paymentIntent;

  @override
  void setConfig(PaymentConfig config) => _config = config;

  @override
  Future<void> buildPaymentIntent() async {
    if (_config == null) throw Exception('Configuration must be set');
    final intAmount = (_config!.amount * 100).round();

    try {
      final dio = Dio();
      final response = await dio.post(
        'https://api.stripe.com/v1/payment_intents',
        data: {
          'amount': intAmount.toString(),
          'currency': _config!.currency.toLowerCase(),
          'automatic_payment_methods[enabled]': 'true',
          'description': _config!.description,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $stripeSecretKey',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Stripe-Version': '2023-10-16',
          },
        ),
      );
      _paymentIntent = response.data;
    } catch (e) {
      throw Exception('Failed to create payment intent: ${e.toString()}');
    }
  }

  @override
  Future<void> buildPaymentSheet() async {
    if (_paymentIntent == null)
      throw Exception('Payment intent must be built first');

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: _paymentIntent!['client_secret'],
          merchantDisplayName: _config!.merchantName,
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Colors.blue,
            ),
          ),
        ),
      );
    } catch (e) {
      throw Exception('Failed to initialize payment sheet: ${e.toString()}');
    }
  }

  @override
  Future<void> presentPayment() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception('Payment failed: ${e.toString()}');
    }
  }
}

class PayPalPaymentBuilder implements PaymentBuilder {
  PaymentConfig? _config;

  @override
  void setConfig(PaymentConfig config) => _config = config;

  @override
  Future<void> buildPaymentIntent() async {
    if (_config == null) throw Exception('Configuration must be set');
    // Implement PayPal API integration here
    throw UnimplementedError('PayPal integration not implemented');
  }

  @override
  Future<void> buildPaymentSheet() async {
    if (_config == null) throw Exception('Configuration must be set');
    // Implement PayPal UI here
    throw UnimplementedError('PayPal UI not implemented');
  }

  @override
  Future<void> presentPayment() async {
    // Present PayPal payment flow
    throw UnimplementedError('PayPal payment flow not implemented');
  }
}

class GooglePayPaymentBuilder implements PaymentBuilder {
  PaymentConfig? _config;

  @override
  void setConfig(PaymentConfig config) => _config = config;

  @override
  Future<void> buildPaymentIntent() async {
    if (_config == null) throw Exception('Configuration must be set');
    // Implement Google Pay integration here
    throw UnimplementedError('Google Pay integration not implemented');
  }

  @override
  Future<void> buildPaymentSheet() async {
    // Implement Google Pay UI here
    throw UnimplementedError('Google Pay UI not implemented');
  }

  @override
  Future<void> presentPayment() async {
    // Present Google Pay payment flow
    throw UnimplementedError('Google Pay payment flow not implemented');
  }
}

class ApplePayBuilder implements PaymentBuilder {
  PaymentConfig? _config;

  @override
  void setConfig(PaymentConfig config) => _config = config;

  @override
  Future<void> buildPaymentIntent() async {
    if (_config == null) throw Exception('Configuration must be set');
    // Implement Apple Pay integration here
    throw UnimplementedError('Apple Pay integration not implemented');
  }

  @override
  Future<void> buildPaymentSheet() async {
    // Implement Apple Pay UI here
    throw UnimplementedError('Apple Pay UI not implemented');
  }

  @override
  Future<void> presentPayment() async {
    // Present Apple Pay payment flow
    throw UnimplementedError('Apple Pay payment flow not implemented');
  }
}

class BankTransferBuilder implements PaymentBuilder {
  PaymentConfig? _config;

  @override
  void setConfig(PaymentConfig config) {
    if (config.bankDetails == null) {
      throw Exception('Bank details are required for bank transfer');
    }
    _config = config;
  }

  @override
  Future<void> buildPaymentIntent() async {
    if (_config == null) throw Exception('Configuration must be set');
    // No external API call needed for bank transfer
  }

  @override
  Future<void> buildPaymentSheet() async {
    if (_config == null || _config!.bankDetails == null) {
      throw Exception('Bank details must be set');
    }
  }

  @override
  Future<void> presentPayment() async {
    if (_config == null || _config!.bankDetails == null) {
      throw Exception('Bank details must be set');
    }

    // In a real implementation, you would show a dialog with bank transfer instructions
    // and possibly integrate with a bank API to verify the transfer
    throw UnimplementedError('Bank transfer UI not implemented');
  }
}

class PaymentDirector {
  final Map<PaymentMethod, PaymentBuilder> _builders = {
    PaymentMethod.stripe: StripePaymentBuilder(),
    PaymentMethod.paypal: PayPalPaymentBuilder(),
    PaymentMethod.googlePay: GooglePayPaymentBuilder(),
    PaymentMethod.applePay: ApplePayBuilder(),
    PaymentMethod.bankTransfer: BankTransferBuilder(),
  };

  Future<void> constructPayment(
      PaymentMethod method, PaymentConfig config) async {
    final builder = _builders[method];
    if (builder == null) throw Exception('Payment method not supported');

    try {
      builder.setConfig(config);
      await builder.buildPaymentIntent();
      await builder.buildPaymentSheet();
      await builder.presentPayment();
    } catch (e) {
      throw Exception('Payment construction failed: ${e.toString()}');
    }
  }
}

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  final _director = PaymentDirector();

  Future<void> makePayment({
    required double amount,
    PaymentMethod method = PaymentMethod.stripe,
    String? currency,
    String? description,
    String? merchantName,
    BankAccountDetails? bankDetails,
  }) async {
    try {
      final config = PaymentConfig(
        amount: amount,
        currency: currency ?? 'MYR',
        description: description ?? 'Payment for appointments',
        merchantName: merchantName ?? 'Danial Hakim',
        bankDetails: bankDetails,
      );

      await _director.constructPayment(method, config);
    } catch (e) {
      print('Error: $e');
      if (e is StripeException) {
        print('Error code: ${e.error.code}');
        print('Error message: ${e.error.message}');
      }
      rethrow;
    }
  }
}
