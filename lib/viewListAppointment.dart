import 'package:flutter/material.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<Map<String, dynamic>> appointments = [
    {
      'id': '1',
      'date': '2024-02-15',
      'time': '10:00 AM',
      'doctor': 'Dr. Smith',
      'specialty': 'Cardiology',
      'status': 'Confirmed'
    },
    {
      'id': '2',
      'date': '2024-03-20',
      'time': '2:30 PM',
      'doctor': 'Johnson',
      'specialty': 'Orthopedics',
      'status': 'Pending'
    },
    {
      'id': '3',
      'date': '2024-04-05',
      'time': '11:15 AM',
      'doctor': 'Dr. Williams',
      'specialty': 'Neurology',
      'status': 'Scheduled'
    },
  ];

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
              onPressed: () {
                setState(() {
                  appointments
                      .removeWhere((appointment) => appointment['id'] == id);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Appointment deleted successfully')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _editAppointment(Map<String, dynamic> appointment) {
    // Create controllers for each field
    final dateController = TextEditingController(text: appointment['date']);
    final timeController = TextEditingController(text: appointment['time']);
    final doctorController = TextEditingController(text: appointment['doctor']);
    final specialtyController =
        TextEditingController(text: appointment['specialty']);

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
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: 'Time'),
                ),
                TextField(
                  controller: doctorController,
                  decoration: const InputDecoration(labelText: 'Doctor'),
                ),
                TextField(
                  controller: specialtyController,
                  decoration: const InputDecoration(labelText: 'Specialty'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  final index = appointments
                      .indexWhere((a) => a['id'] == appointment['id']);
                  if (index != -1) {
                    appointments[index] = {
                      ...appointment,
                      'date': dateController.text,
                      'time': timeController.text,
                      'doctor': doctorController.text,
                      'specialty': specialtyController.text,
                    };
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Appointment updated successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
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
                  '${appointment['doctor']} - ${appointment['specialty']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${appointment['date']}'),
                    Text('Time: ${appointment['time']}'),
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

  void _viewAppointmentDetails(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Appointment Details: ${appointment['doctor']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doctor: ${appointment['doctor']}'),
              Text('Specialty: ${appointment['specialty']}'),
              Text('Date: ${appointment['date']}'),
              Text('Time: ${appointment['time']}'),
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

  void _createNewAppointment() {
    // Placeholder for creating a new appointment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Appointment feature coming soon!')),
    );
  }
}
