import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'appointment_page.dart';
import 'viewListAppointment_service.dart'; // Import the AppointmentService class

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<Map<String, dynamic>> appointments = [];
  late AppointmentService
      _appointmentService; // Declare AppointmentService instance

  @override
  void initState() {
    super.initState();
    _appointmentService = AppointmentService(); // Initialize AppointmentService
    _connectToDatabase();
  }

  // Connect to database and fetch appointments
  Future<void> _connectToDatabase() async {
    await _appointmentService.connect();
    _fetchAppointments();
  }

  // Fetch all appointments
  Future<void> _fetchAppointments() async {
    try {
      final fetchedAppointments = await _appointmentService.fetchAppointments();
      setState(() {
        appointments = fetchedAppointments;
      });
    } catch (e) {
      print("Failed to fetch appointments: $e");
    }
  }

  // Delete an appointment by ID
  void _deleteAppointment(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Appointment'),
          content:
              const Text('Are you sure you want to delete this appointment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _appointmentService.deleteAppointment(id);
                  setState(() {
                    appointments
                        .removeWhere((appointment) => appointment['id'] == id);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Appointment deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Failed to delete appointment')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Edit an appointment
  void _editAppointment(Map<String, dynamic> appointment) {
    final dateController =
        TextEditingController(text: appointment['appointmentDate']);
    final timeController =
        TextEditingController(text: appointment['appointmentTime']);
    final durationController =
        TextEditingController(text: appointment['duration']);
    final sicknessController =
        TextEditingController(text: appointment['typeOfSickness']);
    final notesController =
        TextEditingController(text: appointment['additionalNotes']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: dateController,
                    decoration:
                        const InputDecoration(labelText: 'Appointment Date')),
                TextField(
                    controller: timeController,
                    decoration:
                        const InputDecoration(labelText: 'Appointment Time')),
                TextField(
                    controller: durationController,
                    decoration: const InputDecoration(labelText: 'Duration')),
                TextField(
                    controller: sicknessController,
                    decoration:
                        const InputDecoration(labelText: 'Type of Sickness')),
                TextField(
                    controller: notesController,
                    decoration:
                        const InputDecoration(labelText: 'Additional Notes')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final updatedAppointment = {
                  'appointmentDate': dateController.text,
                  'appointmentTime': timeController.text,
                  'duration': durationController.text,
                  'typeOfSickness': sicknessController.text,
                  'additionalNotes': notesController.text,
                  'appointmentDateTime':
                      '${dateController.text} ${timeController.text}',
                };

                try {
                  await _appointmentService.editAppointment(
                      appointment['id'], updatedAppointment);
                  _fetchAppointments(); // Refresh the appointments list
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Appointment updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Failed to update appointment')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // View appointment details
  void _viewAppointmentDetails(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Appointment Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${appointment['appointmentDate']}'),
              Text('Time: ${appointment['appointmentTime']}'),
              Text('Duration: ${appointment['duration']}'),
              Text('Type of Sickness: ${appointment['typeOfSickness']}'),
              Text('Additional Notes: ${appointment['additionalNotes']}'),
              Text(
                  'Appointment DateTime: ${appointment['appointmentDateTime']}'),
              Text('Created At: ${appointment['createdAt']}'),
            ],
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

  // Create a new appointment
  void _createNewAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppointmentPage()),
    );
  }

  @override
  void dispose() {
    _appointmentService.disconnect();
    super.dispose();
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
        child: ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  '${appointment['appointmentDate']} - ${appointment['typeOfSickness']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time: ${appointment['appointmentTime']}'),
                    Text('Duration: ${appointment['duration']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _viewAppointmentDetails(appointment),
                      icon: const Icon(Icons.remove_red_eye),
                    ),
                    IconButton(
                      onPressed: () => _editAppointment(appointment),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () => _deleteAppointment(appointment['id']),
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewAppointment,
        backgroundColor: const Color(0xFF4CAF93),
        child: const Icon(Icons.add),
      ),
    );
  }
}
