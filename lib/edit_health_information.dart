import 'package:flutter/material.dart';

class EditHealthInformationPage extends StatefulWidget {
  const EditHealthInformationPage({super.key});

  @override
  _EditHealthInformationPageState createState() =>
      _EditHealthInformationPageState();
}

class _EditHealthInformationPageState extends State<EditHealthInformationPage> {
  List<Map<String, String>> healthInformation = [
    {
      'medicalHistory': 'Diabetes',
      'allergies': 'Peanuts',
      'conditions': 'Asthma',
      'bloodType': 'O+',
      'maritalStatus': 'Single',
    },
    {
      'medicalHistory': 'Hypertension',
      'allergies': 'Dust',
      'conditions': 'None',
      'bloodType': 'A-',
      'maritalStatus': 'Married',
    },
  ];

  final List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];
  final List<String> maritalStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed'
  ];

  void _deleteHealthInfo(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Health Information'),
          content: const Text(
              'Are you sure you want to delete this health information?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  healthInformation.removeAt(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Health information deleted successfully')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _editHealthInfo(Map<String, String> info, int index) {
    final medicalHistoryController =
        TextEditingController(text: info['medicalHistory']);
    final allergiesController = TextEditingController(text: info['allergies']);
    final conditionsController =
        TextEditingController(text: info['conditions']);
    String? selectedBloodType = info['bloodType'];
    String? selectedMaritalStatus = info['maritalStatus'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Health Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: medicalHistoryController,
                  decoration:
                      const InputDecoration(labelText: 'Medical History'),
                ),
                TextField(
                  controller: allergiesController,
                  decoration: const InputDecoration(labelText: 'Allergies'),
                ),
                TextField(
                  controller: conditionsController,
                  decoration: const InputDecoration(labelText: 'Conditions'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedBloodType,
                  decoration: const InputDecoration(labelText: 'Blood Type'),
                  items: bloodTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBloodType = value;
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  value: selectedMaritalStatus,
                  decoration:
                      const InputDecoration(labelText: 'Marital Status'),
                  items: maritalStatuses
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMaritalStatus = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  healthInformation[index] = {
                    'medicalHistory': medicalHistoryController.text,
                    'allergies': allergiesController.text,
                    'conditions': conditionsController.text,
                    'bloodType': selectedBloodType ?? '',
                    'maritalStatus': selectedMaritalStatus ?? '',
                  };
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Health information updated successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _createNewHealthInfo() {
    final medicalHistoryController = TextEditingController();
    final allergiesController = TextEditingController();
    final conditionsController = TextEditingController();
    String? selectedBloodType;
    String? selectedMaritalStatus;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Health Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: medicalHistoryController,
                  decoration:
                      const InputDecoration(labelText: 'Medical History'),
                ),
                TextField(
                  controller: allergiesController,
                  decoration: const InputDecoration(labelText: 'Allergies'),
                ),
                TextField(
                  controller: conditionsController,
                  decoration: const InputDecoration(labelText: 'Conditions'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedBloodType,
                  decoration: const InputDecoration(labelText: 'Blood Type'),
                  items: bloodTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBloodType = value;
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  value: selectedMaritalStatus,
                  decoration:
                      const InputDecoration(labelText: 'Marital Status'),
                  items: maritalStatuses
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMaritalStatus = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  healthInformation.add({
                    'medicalHistory': medicalHistoryController.text,
                    'allergies': allergiesController.text,
                    'conditions': conditionsController.text,
                    'bloodType': selectedBloodType ?? '',
                    'maritalStatus': selectedMaritalStatus ?? '',
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Health information added successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Health Information'),
        backgroundColor: const Color(0xFF4CAF93),
      ),
      body: Container(
        color: Colors.grey[200],
        child: ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: healthInformation.length,
          itemBuilder: (context, index) {
            final info = healthInformation[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  'Medical History: ${info['medicalHistory']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Allergies: ${info['allergies']}'),
                    Text('Conditions: ${info['conditions']}'),
                    Text('Blood Type: ${info['bloodType']}'),
                    Text('Marital Status: ${info['maritalStatus']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editHealthInfo(info, index),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () => _deleteHealthInfo(index),
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewHealthInfo,
        backgroundColor: const Color(0xFF4CAF93),
        child: const Icon(Icons.add),
      ),
    );
  }
}
