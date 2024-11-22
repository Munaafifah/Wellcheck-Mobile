import 'package:flutter/material.dart';
import 'appointment_model.dart'; // Import the adjusted model
import 'appointment_service.dart'; // Import the service for booking appointments

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentService _service = AppointmentService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;
  String? _selectedSicknessType;
  String _additionalNotes = '';
  double _calculatedCost = 0.0;

  // Function to calculate cost based on duration
  void _calculateCost(String? duration) {
    if (duration != null) {
      final durationMinutes =
          int.tryParse(duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      setState(() {
        _calculatedCost = durationMinutes * 1.0; // RM1 per minute
      });
    } else {
      setState(() {
        _calculatedCost = 0.0;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // Prepare the `Appointment` object
      final appointment = Appointment(
        appointmentDate: _selectedDate!, // Date only
        appointmentTime:
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}', // Time formatted as HH:mm
        duration: _selectedDuration!,
        typeOfSickness: _selectedSicknessType!,
        additionalNotes: _additionalNotes,
        appointmentCost: _calculatedCost,
      );

      try {
        // Call service to create an appointment
        await _service.createAppointment(appointment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book appointment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Appointment Date Field
              TextFormField(
                decoration: const InputDecoration(labelText: 'Appointment Date'),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  setState(() {
                    _selectedDate = date;
                  });
                },
                validator: (value) =>
                    _selectedDate == null ? 'Please select a date' : null,
                controller: TextEditingController(
                  text: _selectedDate != null
                      ? '${_selectedDate!.toLocal()}'.split(' ')[0]
                      : '',
                ),
              ),

              // Appointment Time Field
              TextFormField(
                decoration: const InputDecoration(labelText: 'Appointment Time'),
                readOnly: true,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  setState(() {
                    _selectedTime = time;
                  });
                },
                validator: (value) =>
                    _selectedTime == null ? 'Please select a time' : null,
                controller: TextEditingController(
                  text: _selectedTime != null
                      ? _selectedTime!.format(context)
                      : '',
                ),
              ),

              // Appointment Duration Dropdown
              DropdownButtonFormField<String>(
                decoration:
                    const InputDecoration(labelText: 'Appointment Duration'),
                items: [
                  '15 minutes',
                  '30 minutes',
                  '45 minutes',
                  '60 minutes',
                  '90 minutes',
                ]
                    .map((duration) => DropdownMenuItem(
                          value: duration,
                          child: Text(duration),
                        ))
                    .toList(),
                onChanged: (value) {
                  _selectedDuration = value;
                  _calculateCost(value); // Calculate cost when duration changes
                },
                validator: (value) =>
                    value == null ? 'Please select a duration' : null,
              ),

              // Type of Sickness Dropdown
              DropdownButtonFormField<String>(
                decoration:
                    const InputDecoration(labelText: 'Type of Sickness'),
                items: [
                  'General Checkup',
                  'Cold/Flu',
                  'Allergy',
                  'Injury',
                  'Skin Issue',
                  'Mental Health',
                  'Chronic Pain',
                  'Other'
                ]
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  _selectedSicknessType = value;
                },
                validator: (value) =>
                    value == null ? 'Please select a sickness type' : null,
              ),

              // Additional Notes Field
              TextFormField(
                decoration: const InputDecoration(labelText: 'Additional Notes'),
                maxLines: 3,
                onSaved: (value) {
                  _additionalNotes = value ?? '';
                },
              ),

              // Display Calculated Cost
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Estimated Cost: RM${_calculatedCost.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Book Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
