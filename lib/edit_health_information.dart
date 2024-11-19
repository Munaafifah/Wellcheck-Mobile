import 'package:flutter/material.dart';

class EditHealthInformationPage extends StatefulWidget {
  @override
  _EditHealthInformationPageState createState() =>
      _EditHealthInformationPageState();
}

class _EditHealthInformationPageState extends State<EditHealthInformationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to manage text input
  final TextEditingController _medicalHistoryController =
      TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _geneticInfoController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();

  void _saveHealthInformation() {
    if (_formKey.currentState!.validate()) {
      // Perform saving/updating logic (e.g., send data to MongoDB)
      final updatedData = {
        "medicalHistory": _medicalHistoryController.text.split(','),
        "allergies": _allergiesController.text.split(','),
        "conditions": _conditionsController.text.split(','),
        "geneticInformation": _geneticInfoController.text,
        "bloodType": _bloodTypeController.text,
      };

      // Placeholder logic for backend submission
      print("Updated Health Information: $updatedData");

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Health information updated successfully!')));

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
              TextFormField(
                controller: _bloodTypeController,
                decoration: const InputDecoration(
                  labelText: 'Blood Type',
                  hintText: 'Enter blood type (e.g., A+, O-, etc.)',
                ),
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
