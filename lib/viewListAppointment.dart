import 'package:flutter/material.dart';
import 'viewListAppointment_service.dart'; // Import the AppointmentService class
import 'appointment_model.dart'; // Import the Appointment model class
import 'appointment_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<Appointment> appointments = [];
  late AppointmentService _appointmentService;

  @override
  void initState() {
    super.initState();
    _appointmentService = AppointmentService();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final fetchedAppointments = await _appointmentService.fetchAppointments();
      setState(() {
        appointments = fetchedAppointments;
      });
    } catch (e) {
      print("Failed to fetch appointments: $e");
      _showSnackBar("Failed to fetch appointments.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show a detailed view of the appointment in a dialog.
  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Appointment Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title: Appointment - ${appointment.typeOfSickness}'),
                Text('Date: ${appointment.appointmentDate}'),
                Text('Time: ${appointment.appointmentTime}'),
                Text('Duration: ${appointment.duration}'),
                Text('Additional Notes: ${appointment.additionalNotes}'),
                Text(
                    'Cost: RM ${appointment.appointmentCost.toStringAsFixed(2)}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentsList() {
    if (appointments.isEmpty) {
      return const Center(
        child: Text(
          'No appointments found.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(
              'Appointment - ${appointment.typeOfSickness}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${appointment.appointmentDate}'),
                Text('Time: ${appointment.appointmentTime}'),
                Text('Duration: ${appointment.duration}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showAppointmentDetails(appointment),
                  icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                ),
                IconButton(
                  onPressed: () =>
                      _showSnackBar('Edit appointment is disabled.'),
                  icon: const Icon(Icons.edit, color: Colors.orange),
                ),
                IconButton(
                  onPressed: () =>
                      _showSnackBar('Delete appointment is disabled.'),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: const Color(0xFF4CAF93),
      ),
      body: Container(
        color: Colors.grey[200],
        child: _buildAppointmentsList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentPage()),
          );
        },
        backgroundColor: const Color(0xFF4CAF93),
        child: const Icon(Icons.add),
      ),
    );
  }
}
