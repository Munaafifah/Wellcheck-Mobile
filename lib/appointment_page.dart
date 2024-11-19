import 'package:flutter/material.dart';
import 'appointment_model.dart';
import 'appointment_service.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentService _service = AppointmentService();

  String? _selectedDoctor;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;
  String? _selectedSicknessType;
  String _additionalNotes = '';

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final appointment = Appointment(
        doctorId: _selectedDoctor!,
        appointmentDateTime: DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        ),
        duration: _selectedDuration!,
        typeOfSickness: _selectedSicknessType!,
        additionalNotes: _additionalNotes,
        userId: "003",
      );

      try {
        await _service.createAppointment(appointment);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
        Navigator.pop(context); // Return to previous screen
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
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: const Color(0xFF4CAF93),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4CAF93).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                
                
                _buildDatePicker(),
                const SizedBox(height: 16),
                _buildTimePicker(),
                const SizedBox(height: 16),
                _buildDurationDropdown(),
                const SizedBox(height: 16),
                _buildSicknessTypeDropdown(),
                const SizedBox(height: 16),
                _buildAdditionalNotesField(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  

  Widget _buildDatePicker() {
    return TextFormField(
      decoration: _inputDecoration('Appointment Date', Icons.calendar_today),
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
    );
  }

  Widget _buildTimePicker() {
    return TextFormField(
      decoration: _inputDecoration('Appointment Time', Icons.access_time),
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
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Appointment Duration', Icons.timer_outlined),
      items: [
        '15 minutes',
        '30 minutes',
        '45 minutes',
        '1 hour',
        '1 hour 30 minutes',
        '2 hours'
      ]
          .map((duration) => DropdownMenuItem(
                value: duration,
                child: Text(duration),
              ))
          .toList(),
      onChanged: (value) {
        _selectedDuration = value;
      },
      validator: (value) =>
          value == null ? 'Please select a duration' : null,
    );
  }

  Widget _buildSicknessTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Type of Sickness', Icons.health_and_safety_outlined),
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
    );
  }

  Widget _buildAdditionalNotesField() {
    return TextFormField(
      decoration: _inputDecoration('Additional Notes', Icons.note_add_outlined),
      maxLines: 3,
      onSaved: (value) {
        _additionalNotes = value ?? '';
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF93),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        'Book Appointment',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF4CAF93)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4CAF93), width: 2),
      ),
    );
  }
}