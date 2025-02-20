import 'package:flutter/material.dart';
import 'package:session/services/stripe_service.dart';
import 'package:session/models/appointment_model.dart';
import 'package:session/services/appointment_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Payment extends StatefulWidget {
  final String userId;

  const Payment({
    super.key,
    required this.userId,
  });

  @override
  State<Payment> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<Payment> {
  bool _isLoading = false;
  final _appointmentService = AppointmentService();
  final _storage = const FlutterSecureStorage();
  List<Appointment> _appointments = [];
  bool _isLoadingAppointments = true;
  double _totalAmount = 0.0;
  double _displayedTotalAmount = 0.0;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.stripe;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final token = await _storage.read(key: "auth_token");
      if (token == null) {
        throw Exception("Authentication token not found");
      }

      final appointments = await _appointmentService.fetchAppointments(
        token,
        widget.userId,
      );

      // Filter appointments that are "Approved"
      final unpaidAppointments = appointments
          .where((appointment) =>
              appointment.statusPayment == "Not Paid" &&
              appointment.statusAppointment == "Approved")
          .toList();

      // Calculate total amount, including RM1 appointments for display only
      final totalDisplayed = unpaidAppointments.fold<double>(
        0,
        (sum, appointment) => sum + appointment.appointmentCost,
      );

      // Calculate payable amount, excluding RM1 appointments from payable total
      final totalPayable = unpaidAppointments.fold<double>(
        0,
        (sum, appointment) => appointment.appointmentCost > 1
            ? sum + appointment.appointmentCost
            : sum,
      );

      setState(() {
        _appointments = unpaidAppointments;
        _totalAmount = totalPayable;
        _displayedTotalAmount = totalDisplayed;
        _isLoadingAppointments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAppointments = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePaymentForAll() async {
    setState(() => _isLoading = true);
    try {
      await StripeService.instance.makePayment(
        amount: _totalAmount,
        method: _selectedPaymentMethod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePaymentForSingle(Appointment appointment) async {
    setState(() => _isLoading = true);
    try {
      await StripeService.instance.makePayment(
        amount: appointment.appointmentCost,
        method: _selectedPaymentMethod,
      );

      final token = await _storage.read(key: "auth_token");
      if (token == null) {
        throw Exception("Authentication token not found");
      }

      await _appointmentService.updateAppointmentStatus(
        token: token,
        appointmentId: appointment.appointmentId,
        statusPayment: "Paid",
        statusAppointment: "Paid",
      );

      setState(() {
        _appointments
            .removeWhere((a) => a.appointmentId == appointment.appointmentId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful and status updated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Pending Payments",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (!_isLoadingAppointments && _appointments.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(20),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Total Amount Due (Including RM1)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'MYR ${_displayedTotalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButton<PaymentMethod>(
                      value: _selectedPaymentMethod,
                      items: PaymentMethod.values.map((PaymentMethod method) {
                        return DropdownMenuItem<PaymentMethod>(
                          value: method,
                          child: Text(method.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (PaymentMethod? newValue) {
                        setState(() {
                          _selectedPaymentMethod = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handlePaymentForAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Pay All Now',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Appointment List
          Expanded(
            child: _isLoadingAppointments
                ? const Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                    ? const Center(
                        child: Text(
                          'No pending payments',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = _appointments[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Appointment Details',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  _buildDetailRow(
                                      'Date', appointment.getFormattedDate()),
                                  _buildDetailRow(
                                      'Time', appointment.getFormattedTime()),
                                  _buildDetailRow('Duration',
                                      '${appointment.duration} minutes'),
                                  _buildDetailRow('Hospital',
                                      appointment.registeredHospital),
                                  _buildMultiLineDetailRow('Type of Visit',
                                      appointment.typeOfSickness),
                                  const Divider(height: 30),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Amount',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      Text(
                                        'MYR ${appointment.appointmentCost.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ||
                                              appointment.appointmentCost == 1
                                          ? null
                                          : () => _handlePaymentForSingle(
                                              appointment),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: Text(
                                        appointment.appointmentCost == 1
                                            ? 'Cannot Pay (RM1)'
                                            : 'Pay Now',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiLineDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
