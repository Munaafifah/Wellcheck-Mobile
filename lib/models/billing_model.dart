class BillingCharge {
  final String name;
  final double amount;

  BillingCharge({required this.name, required this.amount});

  factory BillingCharge.fromJson(Map<String, dynamic> json) {
    return BillingCharge(
      name: json['name'] ?? '',
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class Billing {
  final String billingId;
  final String userId;
  final List<BillingCharge> drugCosts;
  final List<BillingCharge> consultationCosts;
  final List<BillingCharge> equipmentCosts;
  final double totalCost;
  final String statusPayment;
  final DateTime timestamp;

  // ✅ New appointment info fields
  final String? appointmentDate;
  final String? appointmentTime;
  final String? duration;
  final String? registeredHospital;
  final String? typeOfSickness;

  Billing({
    required this.billingId,
    required this.userId,
    required this.drugCosts,
    required this.consultationCosts,
    required this.equipmentCosts,
    required this.totalCost,
    required this.statusPayment,
    required this.timestamp,
    this.appointmentDate,
    this.appointmentTime,
    this.duration,
    this.registeredHospital,
    this.typeOfSickness,
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    return Billing(
      billingId: json['billingId'],
      userId: json['userId'],
      drugCosts: (json['drugCosts'] as List<dynamic>? ?? [])
          .map((e) => BillingCharge.fromJson(e))
          .toList(),
      consultationCosts: (json['consultationCosts'] as List<dynamic>? ?? [])
          .map((e) => BillingCharge.fromJson(e))
          .toList(),
      equipmentCosts: (json['equipmentCosts'] as List<dynamic>? ?? [])
          .map((e) => BillingCharge.fromJson(e))
          .toList(),
      totalCost: (json['totalCost'] as num).toDouble(),
      statusPayment: json['statusPayment'],
      timestamp: DateTime.parse(json['timestamp']),
      // ✅ New fields
      appointmentDate: json['appointmentDate']?.toString(),
      appointmentTime: json['appointmentTime']?.toString(),
      duration: json['duration']?.toString(),
      registeredHospital: json['registeredHospital']?.toString(),
      typeOfSickness: json['typeOfSickness']?.toString(),
    );
  }
}
