import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/appointment_service.dart';
import '../services/sickness_service.dart';
import '../models/sickness_model.dart';
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
  final SicknessService _sicknessService =
      SicknessService(); // Instance of your service
  List<Sickness> _sicknesses = []; // List to hold fetched sickness types

  bool _isLoading = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;
  //String? _typeOfSickness;
  double _appointmentCost = 0.0;

  final List<String> _selectedSicknessTypes = [];

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
      _appointmentCost = 0.0; // Reset before recalculating
      for (String sicknessName in _selectedSicknessTypes) {
        // Find the corresponding sickness object
        final sickness = _sicknesses.firstWhere(
          (s) => s.name == sicknessName,
          orElse: () => Sickness(
              appointmentId: '',
              name: '',
              appointmentPrice: 0.0), // Default if not found
        );
        _appointmentCost += sickness.appointmentPrice; // Add to cost
      }
    });
  }

  // void _addCustomSicknessType() {
  //   final customType = _customSicknessController.text.trim();
  //   if (customType.isNotEmpty) {
  //     setState(() {
  //       if (!_sicknessTypes.contains(customType)) {
  //         _sicknessTypes.add(customType);
  //       }
  //       _selectedSicknessTypes.add(customType);
  //       _customSicknessController.clear();
  //       _calculateCost(); // Recalculate cost
  //     });
  //   }
  // }

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
          statusAppointment: "Not Approved",
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
  void initState() {
    super.initState();
    _loadSicknesses(); // Call to load sickness types
  }

  Future<void> _loadSicknesses() async {
    try {
      _sicknesses = await _sicknessService.fetchSicknesses();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load sickness types: ${e.toString()}')),
      );
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
                    DropdownButtonFormField<String>(
                      value: null, // No initial selection
                      decoration: InputDecoration(
                        labelText: 'Select Symptom',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _sicknesses.map((sickness) {
                        return DropdownMenuItem(
                          value: sickness.name,
                          child: Text(sickness.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null &&
                            !_selectedSicknessTypes.contains(value)) {
                          setState(() {
                            _selectedSicknessTypes
                                .add(value); // Add selected symptom
                            _calculateCost(); // Recalculate cost
                          });
                        }
                      },
                      validator: (value) => _selectedSicknessTypes.isEmpty
                          ? 'Please select at least one symptom'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Selected Symptoms Display
                    _selectedSicknessTypes.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Selected Symptoms:',
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _selectedSicknessTypes.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(_selectedSicknessTypes[index]),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove_circle,
                                          color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          // Remove the symptom from the selected list
                                          _selectedSicknessTypes
                                              .removeAt(index);
                                          _calculateCost(); // Update the cost if necessary
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        : Container(),

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
