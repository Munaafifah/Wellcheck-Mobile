import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EditAppointmentPage extends StatefulWidget {
  final Appointment appointment;

  const EditAppointmentPage({Key? key, required this.appointment}) : super(key: key);

  @override
  _EditAppointmentPageState createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {
  final AppointmentService _appointmentService = AppointmentService();
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController durationController;
  late TextEditingController typeOfSicknessController;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.appointment.appointmentDate;
    selectedTime = widget.appointment.appointmentTime;
    dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(selectedDate));
    timeController = TextEditingController(text: widget.appointment.getFormattedTime());
    durationController = TextEditingController(text: widget.appointment.duration);
    typeOfSicknessController = TextEditingController(text: widget.appointment.typeOfSickness);
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    durationController.dispose();
    typeOfSicknessController.dispose();
    super.dispose();
  }

  Future<void> _updateAppointment() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final token = await _storage.read(key: "auth_token");
      if (token == null) {
        throw Exception("User not authenticated.");
      }

      final typeOfSickness = typeOfSicknessController.text.trim();
      if (typeOfSickness.isEmpty) {
        throw Exception("Type of sickness cannot be empty.");
      }

      if (durationController.text.trim().isEmpty) {
        throw Exception("Duration cannot be empty.");
      }

      await _appointmentService.updateAppointment(
        token,
        widget.appointment.appointmentId,
        selectedDate,
        selectedTime,
        durationController.text.trim(),
        typeOfSickness,
      );

      if (!mounted) return;

      Navigator.pop(context, true); // Pass true to indicate successful update
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment updated successfully!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update appointment: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Appointment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: "Date",
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                      dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: "Time",
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (pickedTime != null) {
                    setState(() {
                      selectedTime = pickedTime;
                      timeController.text = 
                        '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: "Duration (minutes)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: typeOfSicknessController,
                decoration: const InputDecoration(
                  labelText: "Type of Sickness",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _updateAppointment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}