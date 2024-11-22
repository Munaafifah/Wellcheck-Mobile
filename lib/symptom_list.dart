import 'package:flutter/material.dart';
import 'symptom_service.dart';

class SymptomListPage extends StatefulWidget {
  const SymptomListPage({super.key});

  @override
  _SymptomListPageState createState() => _SymptomListPageState();
}

class _SymptomListPageState extends State<SymptomListPage> {
  List<Map<String, dynamic>> _symptoms = [];

  @override
  void initState() {
    super.initState();
    _fetchSymptoms();
  }

  Future<void> _fetchSymptoms() async {
    final symptoms = await SymptomService.getSymptoms();
    setState(() {
      _symptoms = symptoms;
    });
  }

  Future<void> _deleteSymptom(String id) async {
    bool success = await SymptomService.deleteSymptom(id);
    if (success) {
      setState(() {
        _symptoms.removeWhere((symptom) => symptom['_id'] == id);
      });
    }
  }

  Future<void> _editSymptom(String id, String newDescription) async {
    bool success = await SymptomService.editSymptom(id, newDescription);
    if (success) {
      _fetchSymptoms();
    }
  }

  void _showEditDialog(String id, String currentDescription) {
    TextEditingController controller =
        TextEditingController(text: currentDescription);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Symptom'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new description'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editSymptom(id, controller.text);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
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
        title: const Text('Your Symptoms'),
      ),
      body: ListView.builder(
        itemCount: _symptoms.length,
        itemBuilder: (context, index) {
          final symptom = _symptoms[index];
          return ListTile(
            title: Text(symptom['description']),
            subtitle:
                Text('Date: ${DateTime.parse(symptom['createdAt']).toLocal()}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showEditDialog(symptom['_id'], symptom['description']),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteSymptom(symptom['_id']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
