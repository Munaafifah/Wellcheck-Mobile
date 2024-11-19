import 'package:flutter/material.dart';

class EditHealthInformationPage extends StatefulWidget {
  @override
  _EditHealthInformationPageState createState() =>
      _EditHealthInformationPageState();
}

class _EditHealthInformationPageState extends State<EditHealthInformationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for other fields
  final TextEditingController _medicalHistoryController =
      TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _geneticInfoController = TextEditingController();

  // Dropdown options
  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];
  final List<String> _maritalStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed'
  ];

  // Selected values
  String? _selectedBloodType; // Holds the selected blood type
  String? _selectedMaritalStatus; // Holds the selected marital status

  void _saveHealthInformation() {
    if (_formKey.currentState!.validate()) {
      if (_selectedBloodType == null || _selectedMaritalStatus == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select all dropdown options!')),
        );
        return;
      }

      // Perform saving/updating logic (e.g., send data to MongoDB)
      final updatedData = {
        "medicalHistory": _medicalHistoryController.text.split(','),
        "allergies": _allergiesController.text.split(','),
        "conditions": _conditionsController.text.split(','),
        "geneticInformation": _geneticInfoController.text,
        "bloodType": _selectedBloodType,
        "maritalStatus": _selectedMaritalStatus,
      };

      // Placeholder logic for backend submission
      print("Updated Health Information: $updatedData");

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Health information updated successfully!')),
      );

      // Navigate back to the previous page
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Health Information'),
        backgroundColor: const Color(0xFF4CAF93),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _medicalHistoryController,
                decoration: const InputDecoration(
                  labelText: 'Medical History',
                  hintText: 'Enter medical history, separated by commas',
                ),
              ),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  hintText: 'Enter allergies, separated by commas',
                ),
              ),
              TextFormField(
                controller: _conditionsController,
                decoration: const InputDecoration(
                  labelText: 'Conditions',
                  hintText: 'Enter conditions, separated by commas',
                ),
              ),
              TextFormField(
                controller: _geneticInfoController,
                decoration: const InputDecoration(
                  labelText: 'Genetic Information',
                  hintText: 'Enter genetic information',
                ),
              ),
              const SizedBox(height: 20),
              // Dropdown for blood type
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Blood Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedBloodType,
                items: _bloodTypes.map((bloodType) {
                  return DropdownMenuItem<String>(
                    value: bloodType,
                    child: Text(bloodType),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBloodType = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a blood type' : null,
              ),
              const SizedBox(height: 20),
              // Dropdown for marital status
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Marital Status',
                  border: OutlineInputBorder(),
                ),
                value: _selectedMaritalStatus,
                items: _maritalStatuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMaritalStatus = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select marital status' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveHealthInformation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF93),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
