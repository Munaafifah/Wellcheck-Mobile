import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/appointment_service.dart';
import '../models/appointment_model.dart';
// For date formatting

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();
  final TextEditingController _customSicknessController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AppointmentService _appointmentService = AppointmentService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;
  // String? _selectedSicknessType;
  double _appointmentCost = 0.0;
  final List<String> _selectedSicknessTypes = [];

  final List<String> _sicknessTypes = [
    'Flu',
    'Headache',
    'Stomachache',
    'Cold',
    'Follow-up Appointment',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _additionalNotesController.dispose();
    _customSicknessController.dispose();
    super.dispose();
  }

  void _calculateCost() {
    setState(() {
      if (_selectedSicknessTypes.contains('Follow-up Appointment')) {
        _appointmentCost = 5.0; // RM5 for Follow-up Appointment
      } else {
        _appointmentCost = 1.0; // Reset to 0
      }
    });
  }

  void _addCustomSicknessType() {
    final customType = _customSicknessController.text.trim();
    if (customType.isNotEmpty) {
      setState(() {
        if (!_sicknessTypes.contains(customType)) {
          _sicknessTypes.add(customType);
        }
        _selectedSicknessTypes.add(customType);
        _customSicknessController.clear();
        _calculateCost(); // Recalculate cost
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        String sicknessTypesString = _selectedSicknessTypes.join(', ');
        await _appointmentService.createAppointment(
          token: token,
          appointmentDate: _selectedDate!,
          appointmentTime: _selectedTime!,
          duration: _selectedDuration!,
          typeOfSickness: sicknessTypesString,
          additionalNotes: _additionalNotesController.text,
          email: _emailController.text,
          appointmentCost: _appointmentCost,
          statusPayment: "Not Paid",
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );

        // Reset form fields after successful submission
        setState(() {
          _emailController.clear();
          _selectedDate = null;
          _selectedTime = null;
          _selectedDuration = null;
          _selectedSicknessTypes.clear();
          _additionalNotesController.clear();
          _dateController.clear();
          _timeController.clear();
          _appointmentCost = 0.0;
        });
        _formKey.currentState?.reset();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book appointment: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Appointment Date Field
                    TextFormField(
                      controller: _dateController,
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
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                            _dateController.text = _selectedDate!
                                .toLocal()
                                .toString()
                                .split(' ')[0];
                          });
                        }
                      },
                      validator: (value) =>
                          _selectedDate == null ? 'Please select a date' : null,
                    ),
                    const SizedBox(height: 16),

                    // Appointment Time Field
                    TextFormField(
                      controller: _timeController,
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
                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                            _timeController.text =
                                '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      validator: (value) =>
                          _selectedTime == null ? 'Please select a time' : null,
                    ),
                    const SizedBox(height: 16),

                    // Duration Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedDuration,
                      decoration: InputDecoration(
                        labelText: 'Duration (minutes)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['15', '30', '45', '60']
                          .map((duration) => DropdownMenuItem(
                                value: duration,
                                child: Text('$duration minutes'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDuration = value;
                          //_calculateCost(value); // Update cost
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a duration' : null,
                    ),
                    const SizedBox(height: 16),

                    // Type of Sickness Multi-Select
                    FormField<List<String>>(
                      validator: (value) => _selectedSicknessTypes.isEmpty
                          ? 'Please select at least one symptom'
                          : null,
                      builder: (state) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Multi-Select Chips
                          Wrap(
                            spacing: 8.0,
                            children: _sicknessTypes.map((type) {
                              return ChoiceChip(
                                label: Text(type),
                                selected: _selectedSicknessTypes.contains(type),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedSicknessTypes.add(type);
                                    } else {
                                      _selectedSicknessTypes.remove(type);
                                    }
                                    _calculateCost(); // Recalculate cost whenever selection changes
                                  });
                                  state.didChange(_selectedSicknessTypes);
                                },
                              );
                            }).toList(),
                          ),
                          if (state.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 10, left: 12),
                              child: Text(
                                state.errorText!,
                                style: TextStyle(
                                    color: Colors.red[700], fontSize: 12),
                              ),
                            ),

                          // Custom Sickness Type Input
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customSicknessController,
                                  decoration: InputDecoration(
                                    labelText: 'Add Custom Symptom',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addCustomSicknessType,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Notes Field
                    TextFormField(
                      controller: _additionalNotesController,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Book Appointment'),
                      ),
                    ),

                    // Appointment Cost Display
                    Text(
                        'Appointment Cost: RM${_appointmentCost.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 16),
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
