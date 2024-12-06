import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/billing_service.dart';
import '../models/billing_model.dart';
import 'package:intl/intl.dart';

class BillingPage extends StatefulWidget {
  final String userId;

  const BillingPage({Key? key, required this.userId}) : super(key: key);

  @override
  _BillingPageState createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final BillingService _billingService = BillingService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Billing>? _billings;

  @override
  void initState() {
    super.initState();
    _fetchBillings();
  }

  void _fetchBillings() async {
    final token = await _storage.read(key: "auth_token");
    if (token != null) {
      try {
        final billings =
            await _billingService.fetchBillings(widget.userId, token);
        setState(() {
          _billings = billings;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load billings")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4CAF93),
              Color(0xFF379B7E),
              Color(0xFF1E7F68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            _buildHeader(),
            Expanded(
              child: _billings == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : _buildBillingList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Billings",
            style: TextStyle(color: Colors.white, fontSize: 40),
          ),
          SizedBox(height: 10),
          Text(
            "View your billing details here",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingList() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(60),
          topRight: Radius.circular(60),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _billings!.length,
        itemBuilder: (context, index) {
          final billing = _billings![index];
          return _buildBillingCard(billing);
        },
      ),
    );
  }

  Widget _buildBillingCard(Billing billing) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Billing ID: ${billing.billingId}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF4CAF93),
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow("Total Cost", "\$${billing.totalCost}"),
            _buildDetailRow("Payment Status", billing.statusPayment),
            _buildDetailRow("Timestamp",
                DateFormat('yyyy-MM-dd HH:mm').format(billing.timestamp)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              "Appointment Details",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            // Additional appointment details go here...
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
