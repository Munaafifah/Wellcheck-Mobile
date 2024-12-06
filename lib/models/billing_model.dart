import 'appointment_model.dart';
import 'prescription_model.dart';

class Billing {
  String billingId;
  double totalCost;
  String userId;
  Appointment appointment;
  Prescription prescription;
  String statusPayment;
  DateTime timestamp;

  // Constructor
  Billing({
    required this.billingId,
    required this.totalCost,
    required this.userId,
    required this.appointment,
    required this.prescription,
    this.statusPayment = 'Not Paid',
    required this.timestamp,
  });

  // Factory method to create a Billing object from JSON
  factory Billing.fromJson(Map<String, dynamic> json) {
    return Billing(
      billingId: json['billingId'],
      totalCost: json['totalCost'].toDouble(),
      userId: json['userId'],
      appointment: Appointment.fromJson(json['appointment']),
      prescription: Prescription.fromJson(json['prescription']),
      statusPayment: json['statusPayment'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // Method to convert Billing object to JSON
  Map<String, dynamic> toJson() {
    return {
      'billingId': billingId,
      'totalCost': totalCost,
      'userId': userId,
      'appointment': appointment.toJson(),
      'prescription': prescription.toJson(),
      'statusPayment': statusPayment,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
