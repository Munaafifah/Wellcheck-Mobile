import 'package:flutter/material.dart';
import 'viewListAppointment_service.dart'; // Import the AppointmentService class
import 'appointment_model.dart'; // Import the Appointment model class

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<Appointment> appointments =
      []; // Keeping List<Appointment> type for consistency
  late AppointmentService _appointmentService;

  @override
  void initState() {
    super.initState();
    _appointmentService = AppointmentService(); // Initialize AppointmentService
    _fetchAppointments();
  }

  /// Fetch all appointments from the service.
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

  /// Show a SnackBar with a custom message.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Build the appointments list or an empty state message.
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
              '${appointment.appointmentDate} - ${appointment.typeOfSickness}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Date: ${appointment.appointmentDate}'), // Display date properly
                Text(
                    'Time: ${appointment.appointmentTime}'), // Time part from model
                Text('Duration: ${appointment.duration}'),
                Text('Duration: ${appointment.typeOfSickness}'),
                Text('Additional Notes: ${appointment.additionalNotes}'),
                Text(
                    'Cost: RM ${appointment.appointmentCost.toStringAsFixed(2)}'), // Showing cost
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () =>
                      _showSnackBar('View appointment is disabled.'),
                  icon: const Icon(Icons.remove_red_eye, color: Colors.grey),
                ),
                IconButton(
                  onPressed: () =>
                      _showSnackBar('Edit appointment is disabled.'),
                  icon: const Icon(Icons.edit, color: Colors.grey),
                ),
                IconButton(
                  onPressed: () =>
                      _showSnackBar('Delete appointment is disabled.'),
                  icon: const Icon(Icons.delete, color: Colors.grey),
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
          // Future implementation for creating a new appointment.
          _showSnackBar('Create new appointment functionality coming soon.');
        },
        backgroundColor: const Color(0xFF4CAF93),
        child: const Icon(Icons.add),
      ),
    );
  }
}
