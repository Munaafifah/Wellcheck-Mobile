import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/appointment_service.dart';
import '../services/sickness_service.dart';
import '../services/hospital_service.dart';
import '../models/sickness_model.dart';
import '../models/hospital_model.dart'; // Ensure this file exists and it's correctly defined

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
  final TextEditingController _insuranceProviderController =
      TextEditingController();
  final TextEditingController _insurancePolicyNumberController =
      TextEditingController();
  final TextEditingController _preferredLanguageController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final AppointmentService _appointmentService = AppointmentService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final SicknessService _sicknessService = SicknessService();
  final HospitalService _hospitalService = HospitalService();
  List<Sickness> _sicknesses = []; // Holds fetched sickness types
  bool _isLoading = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;
  String? _selectedHospital; // Selected hospital
  String? _registeredHospital;
  double _appointmentCost = 0.0;
  final List<String> _hospitals = ['Hospital A', 'Hospital B'];
  final List<String> _selectedSicknessTypes = [];
  List<Field> _dynamicFields = []; // Fields from the database

  @override
  void dispose() {
    _emailController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _additionalNotesController.dispose();
    _insuranceProviderController.dispose();
    _insurancePolicyNumberController.dispose();
    _preferredLanguageController.dispose();
    super.dispose();
  }

  void _calculateCost() {
    setState(() {
      _appointmentCost = 0.0;
      for (String sicknessName in _selectedSicknessTypes) {
        final sickness = _sicknesses.firstWhere(
          (s) => s.name == sicknessName,
          orElse: () =>
              Sickness(appointmentId: '', name: '', appointmentPrice: 0.0),
        );
        _appointmentCost += sickness.appointmentPrice; // Add to cost
      }
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        String sicknessTypesString = _selectedSicknessTypes.join(', ');
        await _appointmentService.createAppointment(
            token: token,
            appointmentDate: _selectedDate!,
            appointmentTime: _selectedTime!,
            duration: _selectedDuration!,
            registeredHospital: _registeredHospital,
            typeOfSickness: sicknessTypesString,
            additionalNotes: _additionalNotesController.text,
            email: _emailController.text,
            appointmentCost: _appointmentCost,
            statusPayment: "Not Paid",
            statusAppointment: "Not Approved",
            insuranceProvider: _insuranceProviderController.text,
            insurancePolicyNumber: _insurancePolicyNumberController.text,
            preferredLanguage: _preferredLanguageController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );

        // Reset form fields after successful submission
        _resetForm();
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

  // Resetting form fields
  void _resetForm() {
    setState(() {
      _emailController.clear();
      _dateController.clear();
      _timeController.clear();
      _additionalNotesController.clear();
      _insuranceProviderController.clear();
      _insurancePolicyNumberController.clear();
      _preferredLanguageController.clear();
      _selectedHospital = null;
      _selectedDate = null;
      _selectedTime = null;
      _selectedDuration = null;
      _selectedSicknessTypes.clear();
      _appointmentCost = 0.0;
      _dynamicFields.clear(); // Clear the dynamic fields
    });
    _formKey.currentState?.reset();
  }

  @override
  void initState() {
    super.initState();
    _loadSicknesses(); // Load sickness types
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

  // Loading dynamic fields based on selected hospital
  void _onHospitalSelected(String? selectedValue) async {
    if (selectedValue != null) {
      setState(() {
        _selectedHospital = selectedValue; // Store the selected hospital
      });
      await _loadDynamicFields(selectedValue); // Load fields from the database
    }
  }

  Future<void> _loadDynamicFields(String hospitalName) async {
    try {
      _dynamicFields =
          await _hospitalService.fetchFieldConfigurations(hospitalName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load fields: ${e.toString()}')),
      );
    }
    setState(() {});
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
                    // Hospital Selection Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedHospital,
                      decoration: InputDecoration(
                        labelText: 'Select Hospital',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _hospitals.map((hospital) {
                        return DropdownMenuItem(
                          value: hospital,
                          child: Text(hospital),
                        );
                      }).toList(),
                      onChanged: _onHospitalSelected,
                      validator: (value) =>
                          value == null ? 'Please select a hospital' : null,
                    ),
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

                    // Render dynamic fields based on selected hospital
                    ..._dynamicFields.map((field) => _buildDynamicField(field)),

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
                                color: Colors.white)
                            : const Text('Book Appointment'),
                      ),
                    ),

                    // Appointment Cost Display
                    Text(
                      'Appointment Cost: RM${_appointmentCost.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
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

  // Method for building dynamic fields
  Widget _buildDynamicField(Field field) {
    switch (field.type) {
      case 'date':
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label,
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                _selectedDate = date; // Assigning the selected date
                _dateController.text =
                    _selectedDate!.toLocal().toString().split(' ')[0];
              });
            }
          },
          validator: field.required
              ? (value) => _selectedDate == null ? 'Please select a date' : null
              : null,
        );

      case 'multi-select':
        return DropdownButtonFormField<String>(
          value: null, // No initial selection
          decoration: InputDecoration(
            labelText: field.label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: _sicknesses.map((sickness) {
            return DropdownMenuItem(
              value: sickness.name,
              child: Text(sickness.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null && !_selectedSicknessTypes.contains(value)) {
              setState(() {
                _selectedSicknessTypes.add(value); // Add selected symptom
                _calculateCost(); // Recalculate cost based on selected symptoms
              });
            }
          },

          validator: field.required && _selectedSicknessTypes.isEmpty
              ? (value) => 'Please select at least one symptom'
              : null,
        );

      case 'dropdown': // For duration selection
        return DropdownButtonFormField<String>(
          value: null, // No initial selection
          decoration: InputDecoration(
            labelText: field.label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: field.options?.map((opt) {
            return DropdownMenuItem(value: opt, child: Text('$opt minutes'));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDuration = value; // Update duration selection
            });
          },
          validator: field.required && _selectedDuration == null
              ? (value) => 'Please select a duration'
              : null,
        );

      case 'text':
        return TextFormField(
          decoration: InputDecoration(
            labelText: field.label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: field.required
              ? (value) =>
                  value == null || value.isEmpty ? 'Field is required' : null
              : null,
        );

      default:
        return Container(); // Handle unsupported types gracefully
    }
  }
}
