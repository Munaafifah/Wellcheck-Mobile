import 'package:flutter/material.dart';
import 'package:session/services/stripe_service.dart';

class Payment extends StatefulWidget {
  const Payment({super.key});

  @override
  State<Payment> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<Payment> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Stripe Payment Demo"),
      ),
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MaterialButton(
              onPressed: () async {
                try {
                  await StripeService.instance.makePayment();
                  // Handle successful payment
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment successful!')),
                  );
                } catch (e) {
                  // Handle payment error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              color: Colors.green,
              child: const Text("Purchase"),
            ),
          ],
        ),
      ),
    );
  }
}
