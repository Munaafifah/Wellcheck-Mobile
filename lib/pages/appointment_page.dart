import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/appointment_service.dart';
import '../services/sickness_service.dart';
import '../models/sickness_model.dart';
import 'hospitalA_page.dart';
import 'hospitalB_page.dart';

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
  final TextEditingController _insuranceProviderController =
      TextEditingController();
  final TextEditingController _insurancePolicyNumberController =
      TextEditingController();
  final TextEditingController _preferredLanguageController =
      TextEditingController();
  final bool _isTeleconsultation = false;

  bool _isLoading = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDuration;
  //String? _typeOfSickness;
  String? _selectedHospital;
  double _appointmentCost = 0.0;
  final List<String> _hospitals = ['Hospital A', 'Hospital B'];

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
            isTeleconsultation: _isTeleconsultation, // New field
            insuranceProvider: _insuranceProviderController.text, // New field
            insurancePolicyNumber:
                _insurancePolicyNumberController.text, // New field
            preferredLanguage: _preferredLanguageController.text // New field
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

  void _onHospitalSelected(String? selectedValue) {
    if (selectedValue != null) {
      switch (selectedValue) {
        case 'Hospital A':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    HospitalAPage()), // Ensure this matches class name
          );
          break;
        case 'Hospital B':
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    HospitalBPage()), // Ensure this matches class name
          );
          break;
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
