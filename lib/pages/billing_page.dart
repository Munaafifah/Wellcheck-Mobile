import 'package:flutter/material.dart';
import '../services/billing_service.dart';
import '../models/billing_model.dart';

class BillingPage extends StatefulWidget {
  final String userId;

  const BillingPage({super.key, required this.userId});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final BillingService _billingService = BillingService();
  Billing? _billingData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBillingData();
  }

  Future<void> _fetchBillingData() async {
    setState(() => _isLoading = true);

    try {
      final billing = await _billingService.fetchBilling(widget.userId);
      setState(() => _billingData = billing);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processPayment() async {
    try {
      await _billingService.payBilling(widget.userId);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Payment Successful!")));
      _fetchBillingData(); // Refresh billing data
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Billing Details")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _billingData == null
              ? const Center(child: Text("No billing data available"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Total Cost: RM${_billingData!.totalCost.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            const Text("Appointments:"),
                            ..._billingData!.appointments.map((app) => ListTile(
                                  title: Text(
                                      "Appointment - ${app['typeOfSickness']}"),
                                  subtitle:
                                      Text("Cost: RM${app['appointmentCost']}"),
                                )),
                            const SizedBox(height: 16),
                            const Text("Prescriptions:"),
                            ..._billingData!.prescriptions
                                .map((pres) => ListTile(
                                      title: Text(
                                          "Prescription - ${pres['diagnosisAilmentDescription']}"),
                                      subtitle: Text(
                                          "Cost: RM${pres['totalPrescriptionCost']}"),
                                    )),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _processPayment,
                        child: const Text("Pay Now"),
                      ),
                    ],
                  ),
                ),
    );
  }
}
