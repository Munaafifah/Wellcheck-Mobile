import 'package:flutter/material.dart';
import '../models/appointment_model.dart'; // Adjust the import based on your file structure
import '../services/appointment_service.dart';
import 'package:intl/intl.dart'; 

class EditAppointmentPage extends StatefulWidget {
  final Appointment appointment;

  const EditAppointmentPage({Key? key, required this.appointment}) : super(key: key);

  @override
  _EditAppointmentPageState createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {
  final AppointmentService _appointmentService = AppointmentService();
  // Define controllers for handling input
  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController durationController;
  late TextEditingController typeOfSicknessController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current appointment data
    dateController = TextEditingController(text: widget.appointment.getFormattedDate());
    timeController = TextEditingController(text: widget.appointment.getFormattedTime());
    durationController = TextEditingController(text: widget.appointment.duration);
    typeOfSicknessController = TextEditingController(text: widget.appointment.typeOfSickness);
  }

  @override
  void dispose() {
    // Clean up controllers
    dateController.dispose();
    timeController.dispose();
    durationController.dispose();
    typeOfSicknessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Appointment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Date"),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: widget.appointment.appointmentDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                }
              },
            ),
            // Add more fields similarly
            ElevatedButton(
              onPressed: () {
                // Save logic
                Navigator.pop(context); // Go back after saving
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}