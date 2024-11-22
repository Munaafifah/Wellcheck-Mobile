import 'package:flutter/material.dart';

class BillingPage extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const BillingPage({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final billing = appointment['billing'];
    final consultationFee = billing['consultationFee'];
    final medications = billing['medications'] as List<Map<String, dynamic>>;

    double totalCost = consultationFee;
    for (var medication in medications) {
      totalCost += medication['cost'];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Billing for ${appointment['doctor']}'),
        backgroundColor: const Color(0xFF4CAF93),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consultation Fee: \$${consultationFee.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Medications:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...medications.map((medication) {
              return ListTile(
                title: Text(medication['name']),
                trailing: Text(
                  '\$${medication['cost'].toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }),
            const SizedBox(height: 16),
            Text(
              'Total: \$${totalCost.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
