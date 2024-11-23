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

      final appointment = Appointment(
        appointmentDate: _selectedDate!,
        appointmentTime:
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        duration: _selectedDuration!,
        typeOfSickness: _selectedSicknessType!,
        additionalNotes: _additionalNotes,
        appointmentCost: _calculatedCost,
      );

      try {
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: const Color(0xFF4CAF93),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book Your Appointment',
                      style: theme.textTheme.titleLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20, thickness: 1.5),
                    const SizedBox(height: 16),

                    // Appointment Date Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Appointment Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                    const SizedBox(height: 16),

                    // Appointment Time Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Appointment Time',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                    const SizedBox(height: 16),

                    // Appointment Duration Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Appointment Duration',
                        prefixIcon: const Icon(Icons.timer),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                        _calculateCost(value);
                      },
                      validator: (value) =>
                          value == null ? 'Please select a duration' : null,
                    ),
                    const SizedBox(height: 16),

                    // Type of Sickness Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Type of Sickness',
                        prefixIcon: const Icon(Icons.healing),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                      validator: (value) => value == null
                          ? 'Please select a sickness type'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Additional Notes Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Additional Notes',
                        prefixIcon: const Icon(Icons.note_add),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                      onSaved: (value) {
                        _additionalNotes = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Display Calculated Cost
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Estimated Cost: RM${_calculatedCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF4CAF93),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Book Appointment',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
