import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/appointment_service.dart';
import '../models/appointment_model.dart';
import 'package:intl/intl.dart'; // For date formatting

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

class ViewAppointmentsPage extends StatefulWidget {
  final String userId;

  const ViewAppointmentsPage({super.key, required this.userId});

  @override
  _ViewAppointmentsPageState createState() => _ViewAppointmentsPageState();
}

class _ViewAppointmentsPageState extends State<ViewAppointmentsPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Appointment>? _appointments;
  List<Appointment>? _filteredAppointments;
  String? _selectedMonth;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        final appointments =
            await _appointmentService.fetchAppointments(token, widget.userId);
        setState(() {
          _appointments = appointments;
          _filteredAppointments = appointments;
        });
      } else {
        setState(() {
          _errorMessage = "Authentication token not found.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load appointments. Please try again.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    try {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        await _appointmentService.deleteAppointment(token, appointmentId);
        _fetchAppointments(); // Refresh the list after deletion
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete appointment: $e")),
      );
    }
  }

  Future<void> _editAppointment(String appointmentId, String newNotes) async {
    try {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        await _appointmentService.updateAppointment(
            token, appointmentId, newNotes);
        _fetchAppointments(); // Refresh the list after update
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update appointment: $e")),
      );
    }
  }

  void _filterAppointments(String? month) {
    if (month == null || month.isEmpty) {
      setState(() {
        _filteredAppointments = _appointments;
      });
    } else {
      setState(() {
        _filteredAppointments = _appointments!
            .where((appointment) =>
                appointment.appointmentDate.month.toString() == month)
            .toList();
      });
    }
  }

  Widget buildAppointmentCard(Appointment appointment) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text("Appointment - ${appointment.typeOfSickness}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: ${appointment.getFormattedDate()}"),
            Text("Time: ${appointment.getFormattedTime()}"),
            Text("Duration: ${appointment.duration} mins"),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Appointment - ${appointment.typeOfSickness}"),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("General Information",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Date: ${appointment.getFormattedDate()}"),
                          Text("Time: ${appointment.getFormattedTime()}"),
                          Text("Duration: ${appointment.duration} mins"),
                          const SizedBox(height: 16),
                          const Text("Details",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                              "Type of Sickness: ${appointment.typeOfSickness}"),
                          Text(
                              "Additional Notes: ${appointment.additionalNotes}"),
                          const SizedBox(height: 16),
                          const Text("Contact Information",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Email: ${appointment.email}"),
                          const SizedBox(height: 16),
                          const Text("Identifiers & Cost",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Doctor ID: ${appointment.doctorId}"),
                          Text("User ID: ${appointment.userId}"),
                          Text(
                              "Cost: RM${appointment.appointmentCost.toStringAsFixed(2)}"),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () {
                TextEditingController controller =
                    TextEditingController(text: appointment.additionalNotes);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Edit Notes"),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(labelText: "Notes"),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          _editAppointment(
                              appointment.appointmentId, controller.text);
                          Navigator.pop(context);
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteAppointment(appointment.appointmentId),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Appointments"),
        backgroundColor: const Color(0xFF4CAF93),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: DropdownButtonFormField<String>(
                        value: _selectedMonth,
                        items: const [
                          DropdownMenuItem(value: "", child: Text("All")),
                          DropdownMenuItem(value: "1", child: Text("January")),
                          DropdownMenuItem(value: "2", child: Text("February")),
                          DropdownMenuItem(value: "3", child: Text("March")),
                          DropdownMenuItem(value: "4", child: Text("April")),
                          DropdownMenuItem(value: "5", child: Text("May")),
                          DropdownMenuItem(value: "6", child: Text("June")),
                          DropdownMenuItem(value: "7", child: Text("July")),
                          DropdownMenuItem(value: "8", child: Text("August")),
                          DropdownMenuItem(
                              value: "9", child: Text("September")),
                          DropdownMenuItem(value: "10", child: Text("October")),
                          DropdownMenuItem(
                              value: "11", child: Text("November")),
                          DropdownMenuItem(
                              value: "12", child: Text("December")),
                        ],
                        onChanged: (value) {
                          _selectedMonth = value;
                          _filterAppointments(value);
                        },
                        decoration: InputDecoration(
                          labelText: "Filter by Month",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filteredAppointments == null ||
                              _filteredAppointments!.isEmpty
                          ? const Center(child: Text('No appointments found'))
                          : ListView.builder(
                              itemCount: _filteredAppointments!.length,
                              itemBuilder: (context, index) {
                                return buildAppointmentCard(
                                    _filteredAppointments![index]);
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const AppointmentPage()), // Replace with your page
          );
        },
        backgroundColor: const Color(0xFF4CAF93),
        child: const Icon(Icons.add),
      ),
    );
  }
}
