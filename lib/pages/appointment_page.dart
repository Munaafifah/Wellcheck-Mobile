import 'package:flutter/material.dart';
import '../services/hospital_service.dart';
import '../models/hospital_model.dart';
import '../models/sickness_model.dart';
import '../models/appointment_model.dart';
import '../services/sickness_service.dart';
import '../services/appointment_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppointmentPage extends StatefulWidget {
  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  late Future<List<Hospital>> futureHospitals;
  final SicknessService _sicknessService = SicknessService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late Future<List<Sickness>> futureSicknesses;

  @override
  void initState() {
    super.initState();
    futureHospitals = HospitalService().fetchHospitals();
    futureSicknesses = _sicknessService.fetchSicknesses(); // Fetch sicknesses
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Hospital')),
      body: FutureBuilder<List<Hospital>>(
        future: futureHospitals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<Hospital> hospitals = snapshot.data!;
          return ListView.builder(
            itemCount: hospitals.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(hospitals[index].name),
                onTap: () {
                  // Load sicknesses only when the hospital is selected
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentFormScreen(
                        hospital: hospitals[index],
                        futureSicknesses:
                            futureSicknesses, // Pass sicknesses to AppointmentFormScreen
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class AppointmentFormScreen extends StatefulWidget {
  final Hospital hospital;
  final Future<List<Sickness>>
      futureSicknesses; // Accept sicknesses as a future

  AppointmentFormScreen(
      {required this.hospital, required this.futureSicknesses});

  @override
  _AppointmentFormScreenState createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();
  final TextEditingController _insuranceProviderController =
      TextEditingController();
  final TextEditingController _insurancePolicyNumberController =
      TextEditingController();

  final SicknessService _sicknessService = SicknessService();
  final AppointmentService _appointmentService = AppointmentService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  double _appointmentCost = 0.0;
  String? _selectedDuration;
  List<String> _selectedSicknessTypes = [];
  List<Sickness> _sicknesses = []; // Initialize the sickness list

  String get hospitalId => widget.hospital.id;

  @override
  void initState() {
    super.initState();
    _loadSicknesses(); // Load sicknesses when the screen initializes
  }

  Future<void> _loadSicknesses() async {
    try {
      // Assuming _sicknessService is defined elsewhere in your code
      _sicknesses = await _sicknessService.fetchSicknesses();
      setState(() {}); // Update UI after loading
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load sickness types: ${e.toString()}')),
      );
    }
  }

  void _calculateCost() {
    setState(() {
      _appointmentCost = 0.0; // Reset before recalculating
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Book Appointment at ${widget.hospital.name}'),
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
                  children: _createFormFields(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _createFormFields() {
    List<Widget> fields = [];
    final theme = Theme.of(context);

    for (var field in widget.hospital.formFields) {
      if (field.required) {
        switch (field.type) {
          case 'text':
            fields.add(
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: field.label,
                  prefixIcon: const Icon(Icons.text_fields),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your ${field.label}';
                  }
                  return null;
                },
              ),
            );
            
            break;



          case 'date':
            fields.add(
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: field.label,
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
                      _dateController.text =
                          "${_selectedDate!.toLocal()}".split(' ')[0];
                    });
                  }
                },
                validator: (value) {
                  return _selectedDate == null ? 'Please select a date' : null;
                },
              ),
            );
            break;

          case 'time':
            fields.add(
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: field.label,
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
                validator: (value) {
                  return _selectedTime == null ? 'Please select a time' : null;
                },
              ),
            );
            break;

          case 'dropdown':
            fields.add(
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: field.label,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: (field.options ?? []).map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value; // Adding this line
                  });
                },
                validator: (value) {
                  return value == null ? 'Please select a duration' : null;
                },
              ),
            );
            break;

                case 'insurance':
          // Insurance Provider Field
          fields.add(
            TextFormField(
              controller: _insuranceProviderController,
              decoration: InputDecoration(
                labelText: 'Insurance Provider (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
          fields.add(const SizedBox(height: 16));
          break;

        case 'policy':
          // Insurance Policy Number Field
          fields.add(
            TextFormField(
              controller: _insurancePolicyNumberController,
              decoration: InputDecoration(
                labelText: 'Insurance Policy Number (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
          fields.add(const SizedBox(height: 16));
          break;


          case 'multi-select':
            // Create a DropdownButton for selecting symptoms
            fields.add(
              DropdownButtonFormField<String>(
                value: null, // Initial selection is null
                decoration: InputDecoration(
                  labelText: field.label,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _sicknesses.map((sickness) {
                  return DropdownMenuItem<String>(
                    value: sickness.name,
                    child: Text(sickness.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null &&
                      !_selectedSicknessTypes.contains(value)) {
                    setState(() {
                      _selectedSicknessTypes.add(value); // Add selected symptom
                      _calculateCost(); // Update the cost
                    });
                  }
                },
                validator: (value) => _selectedSicknessTypes.isEmpty
                    ? 'Please select at least one symptom'
                    : null,
              ),
            );

            // Adding a space between fields
            fields.add(const SizedBox(height: 16));

            // Display the list of selected symptoms, if any
            if (_selectedSicknessTypes.isNotEmpty) {
              fields.add(
                Column(
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
                                _selectedSicknessTypes.removeAt(index);
                                _calculateCost(); // Recalculate cost after removal
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }
            fields.add(const SizedBox(
                height: 16)); // Ensure spacing after symptoms display
            break;
        }
      }
      fields.add(const SizedBox(height: 16)); // Add spacing between fields
    }


    // Add the submit button
    fields.add(
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Book Appointment'),
        ),
      ),
    );

    // Optionally display appointment cost
    fields.add(Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Text(
          'Estimated Cost: RM${_appointmentCost.toStringAsFixed(2)}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        )));

    return fields;
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedDuration == null ||
        _selectedSicknessTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please make sure all fields are filled.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: "auth_token");

      String sicknessTypesString = _selectedSicknessTypes.join(', ');

      if (token != null) {
        // Create an appointment instance using the Appointment model
        Appointment newAppointment = Appointment(
          appointmentId:
              '', // You may want to leave this blank for the API to generate.
          userId:
              '', // Set this to the current user's ID, likely from your auth token or storage
          doctorId: '', // If needed, you should provide this value
          hospitalId:
              hospitalId, // Ensure this value is passed from the UI to the model
          appointmentDate: _selectedDate!,
          appointmentTime: _selectedTime!,
          duration: _selectedDuration!,
          typeOfSickness: sicknessTypesString,
          additionalNotes: _additionalNotesController.text,
          email: _emailController.text,
          appointmentCost: _appointmentCost,
          statusPayment: "Not Paid",
          statusAppointment: "Not Approved",
          insuranceProvider: _insuranceProviderController.text,
          insurancePolicyNumber: _insurancePolicyNumberController.text,
        );

        // Call the appointment service to create the appointment
        await _appointmentService.createAppointment(
          token: token,
          appointmentDate: newAppointment.appointmentDate,
          appointmentTime: newAppointment.appointmentTime,
          duration: newAppointment.duration,
          typeOfSickness: newAppointment.typeOfSickness,
          additionalNotes: newAppointment.additionalNotes,
          email: newAppointment.email,
          hospitalId: hospitalId,
          appointmentCost: newAppointment.appointmentCost,
          statusPayment: newAppointment.statusPayment,
          statusAppointment: newAppointment.statusAppointment,
          insuranceProvider: newAppointment.insuranceProvider,
          insurancePolicyNumber: newAppointment.insurancePolicyNumber,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );

        _resetForm(); // Reset form fields after success
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book appointment: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  void _resetForm() {
    setState(() {
      _emailController.clear();
      _dateController.clear();
      _timeController.clear();
      _additionalNotesController.clear();
      _insuranceProviderController.clear();
      _insurancePolicyNumberController.clear();
      _selectedDate = null;
      _selectedTime = null;
      _selectedDuration = null;
      _selectedSicknessTypes.clear();
      _appointmentCost = 0.0;
    });
    _formKey.currentState?.reset();
  }
}
