class Billing {
  final String billingId;
  final String userId;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> prescriptions;
  final double totalCost;
  final String statusPayment;
  final DateTime timestamp;

  Billing({
    required this.billingId,
    required this.userId,
    required this.appointments,
    required this.prescriptions,
    required this.totalCost,
    required this.statusPayment,
    required this.timestamp,
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    return Billing(
      billingId: json['billingId'],
      userId: json['userId'],
      appointments: List<Map<String, dynamic>>.from(json['appointments']),
      prescriptions: List<Map<String, dynamic>>.from(json['prescriptions']),
      totalCost: json['totalCost'],
      statusPayment: json['statusPayment'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
