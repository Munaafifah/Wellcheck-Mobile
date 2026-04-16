import 'package:flutter/material.dart';
import 'package:session/services/billing_service.dart';
import 'package:session/models/billing_model.dart';
import 'package:session/services/stripe_service.dart';

class Payment extends StatefulWidget {
  final String userId;

  const Payment({super.key, required this.userId});

  @override
  State<Payment> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<Payment> {
  final BillingService _billingService = BillingService();
  List<Billing> _billingList = [];
  bool _isLoading = true;
  Map<String, bool> _isPaying = {};
  Map<String, PaymentMethod> _selectedMethods = {};

  @override
  void initState() {
    super.initState();
    _fetchBillingData();
  }

  Future<void> _fetchBillingData() async {
    setState(() => _isLoading = true);
    try {
      final billings = await _billingService.fetchBilling(widget.userId);
      setState(() {
        _billingList = billings;
        for (var b in billings) {
          _isPaying[b.billingId] = false;
          _selectedMethods[b.billingId] = PaymentMethod.stripe;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error loading billing: $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePay(Billing billing) async {
    setState(() => _isPaying[billing.billingId] = true);
    try {
      await StripeService.instance.makePayment(
        amount: billing.totalCost,
        method: _selectedMethods[billing.billingId]!,
      );
      await _billingService.payBilling(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Payment Successful!"),
              backgroundColor: Colors.green),
        );
        _fetchBillingData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying[billing.billingId] = false);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return "-";
    try {
      final dt = DateTime.parse(raw);
      return "${dt.day} ${_monthName(dt.month)} ${dt.year}";
    } catch (_) {
      return raw;
    }
  }

  String _monthName(int m) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[m];
  }

  Widget _buildInfoGridItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCostRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required double amount,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 14))),
              Text(
                "RM ${amount.toStringAsFixed(2)}",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: iconColor),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, thickness: 0.5),
      ],
    );
  }

  Widget _buildBillingCard(Billing billing) {
    final isPaid = billing.statusPayment == "Paid";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Green header ──
          Container(
            width: double.infinity,
            color: isPaid ? Colors.grey[400] : const Color(0xFF1D9E75),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? "Payment Completed" : "Total Amount Due",
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  "MYR ${billing.totalCost.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ],
            ),
          ),

          // ── Floating info grid ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Transform.translate(
              offset: const Offset(0, -14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfoGridItem(
                                "Date", _formatDate(billing.appointmentDate))),
                        Expanded(
                            child: _buildInfoGridItem(
                                "Time", billing.appointmentTime ?? "-")),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfoGridItem("Duration",
                                "${billing.duration ?? "-"} minutes")),
                        Expanded(
                            child: _buildInfoGridItem(
                                "Hospital", billing.registeredHospital ?? "-")),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfoGridItem("Type of visit",
                                billing.typeOfSickness ?? "-")),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Cost breakdown ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Cost breakdown",
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),

                // Drug cost — from prescription, always shown if present
                if (billing.drugCosts.isNotEmpty)
                  _buildCostRow(
                    icon: Icons.medication,
                    iconColor: const Color(0xFF185FA5),
                    iconBg: const Color(0xFFE6F1FB),
                    label: "Drug cost",
                    amount: billing.drugCosts.fold(0.0, (s, c) => s + c.amount),
                    showDivider: billing.costItems.isNotEmpty,
                  ),

                // Dynamic cost items from clinic assistant
                ...billing.costItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == billing.costItems.length - 1;
                  return _buildCostRow(
                    icon: Icons.receipt_long,
                    iconColor: const Color(0xFF0F6E56),
                    iconBg: const Color(0xFFE1F5EE),
                    label: item.name,
                    amount: item.amount,
                    showDivider: !isLast,
                  );
                }),

                // Fallback if nothing at all
                if (billing.drugCosts.isEmpty && billing.costItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "No charges recorded yet.",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),

          // ── Total row ──
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border:
                  Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total",
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(
                  "MYR ${billing.totalCost.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isPaid ? Colors.grey : const Color(0xFF1D9E75),
                  ),
                ),
              ],
            ),
          ),

          // ── Pay button ──
          if (!isPaid)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  DropdownButtonFormField<PaymentMethod>(
                    value: _selectedMethods[billing.billingId],
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: PaymentMethod.values
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.toString().split('.').last),
                            ))
                        .toList(),
                    onChanged: (val) => setState(
                        () => _selectedMethods[billing.billingId] = val!),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isPaying[billing.billingId] ?? false)
                          ? null
                          : () => _handlePay(billing),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: (_isPaying[billing.billingId] ?? false)
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: Colors.white))
                          : const Text("Pay Now",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),

          if (isPaid)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Center(
                child: Text("Payment completed",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Pending Payment",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _billingList.isEmpty
              ? const Center(child: Text("No billing data available"))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _billingList
                      .map((billing) => _buildBillingCard(billing))
                      .toList(),
                ),
    );
  }
}
