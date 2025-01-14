import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EditAppointmentPage extends StatefulWidget {
  final Appointment appointment;


  const EditAppointmentPage({super.key, required this.appointment});

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
  String? _selectedDuration;

  List<String> durationOptions = ['15', '30', '45', '60'];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.appointment.appointmentDate;
    selectedTime = widget.appointment.appointmentTime;
    dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(selectedDate));
    timeController =
        TextEditingController(text: widget.appointment.getFormattedTime());
    durationController =
        TextEditingController(text: widget.appointment.duration);
    typeOfSicknessController =
        TextEditingController(text: widget.appointment.typeOfSickness);
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    durationController.dispose();
    typeOfSicknessController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndUpdateAppointment() async {
    if (!_validateForm()) return;
    bool? confirm = await _showConfirmationDialog();
    if (confirm == true) {
      _updateAppointment();
    }
  }

  bool _validateForm() {
    if (dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        durationController.text.isEmpty ||
        typeOfSicknessController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
      return false;
    }
    return true;
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Update"),
          content:
              const Text("Are you sure you want to update this appointment?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
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

      await _appointmentService.updateAppointment(
        token,
        widget.appointment.appointmentId,
        selectedDate,
        selectedTime,
        durationController.text.trim(),
        typeOfSickness,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment updated successfully!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to update appointment: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF93)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF93), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF93), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF93), width: 2),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Appointment"),
        backgroundColor: const Color(0xFF4CAF93),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputField(
                controller: dateController,
                label: "Date",
                icon: Icons.calendar_today,
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
                      dateController.text =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildInputField(
                controller: timeController,
                label: "Time",
                icon: Icons.access_time,
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
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedDuration, // Maintain the selected duration
                decoration: InputDecoration(
                  labelText:
                      "Duration (minutes)", // The label text for the field
                  labelStyle: const TextStyle(
                    color: Color(
                        0xFF4CAF93), // Match the color scheme of other fields
                    fontWeight: FontWeight.bold, // Bold for emphasis
                  ),
                  hintText:
                      "Select Duration", // Provide a hint text for empty selection
                  hintStyle: const TextStyle(
                    color:
                        Color(0xFFB0B0B0), // Lighter gray color for hint text
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        12), // Round corners to match other fields
                    borderSide: const BorderSide(
                        color: Color(0xFF4CAF93),
                        width: 2), // Match border color
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // Round corners
                    borderSide: const BorderSide(
                        color: Color(0xFF4CAF93),
                        width: 1.5), // Consistent border thickness
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // Round corners
                    borderSide: const BorderSide(
                        color: Color(0xFF4CAF93),
                        width: 2), // Match focus state border color
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 12), // Same padding as other fields
                ),
                items: durationOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontSize:
                            16, // Match the font size with other fields for consistency
                        color: Colors
                            .black, // Black color for the text for better readability
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value; // Update the selected duration
                    durationController.text = value ??
                        ""; // Set controller text to the selected value
                  });
                },
                validator: (value) {
                  return value == null
                      ? 'Please select a duration'
                      : null; // Validation message for empty selection
                },
              ),
              
              const SizedBox(height: 20),
              _buildInputField(
                controller: typeOfSicknessController,
                label: "Type of Sickness",
                icon: Icons.medical_services,
                maxLines: 2,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : _confirmAndUpdateAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF93),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes",
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
