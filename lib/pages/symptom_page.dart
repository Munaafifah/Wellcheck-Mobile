import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:session/models/symptom_model.dart';
import '../services/symptom_service.dart';
import 'package:dropdown_search/dropdown_search.dart';

class SymptomPage extends StatefulWidget {
  const SymptomPage({super.key});

  @override
  _SymptomPageState createState() => _SymptomPageState();
}

class _SymptomPageState extends State<SymptomPage> {
  final SymptomService _symptomService = SymptomService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<String> _selectedSymptoms = [];
  bool _isLoading = false;

  final List<String> _symptoms = [
    "Fever",
    "Cough",
    "Headache",
    "Fatigue",
    "Sore Throat",
    "Shortness of Breath",
    "Loss of Smell",
    "Loss of Taste",
    "Chest Pain",
    "Nausea",
    "Vomiting",
  ];

  void _addSymptom(String symptom) {
    if (!_selectedSymptoms.contains(symptom)) {
      setState(() {
        _selectedSymptoms.add(symptom);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$symptom is already added.")),
      );
    }
  }

  void _submitSymptoms() async {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one symptom.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        for (final symptom in _selectedSymptoms) {
          await _symptomService.addSymptom(token, symptom);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Symptoms submitted successfully")),
        );
        setState(() {
          _selectedSymptoms.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit symptoms")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4CAF93),
              Color(0xFF379B7E),
              Color(0xFF1E7F68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Text(
            "Add Symptom",
            style: TextStyle(color: Colors.white, fontSize: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Your Symptoms",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildSymptomDropdown(),
          const SizedBox(height: 20),
          _buildSelectedSymptomsList(),
          const SizedBox(height: 20),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSymptomDropdown() {
    return DropdownSearch<String>(
      items: _symptoms,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Search for a symptom...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Symptoms",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      onChanged: (symptom) {
        if (symptom != null) _addSymptom(symptom);
      },
    );
  }

  Widget _buildSelectedSymptomsList() {
    return Column(
      children: _selectedSymptoms
          .map((symptom) => ListTile(
                title: Text(symptom),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedSymptoms.remove(symptom);
                    });
                  },
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSubmitButton() {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF93)),
            ),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF93),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: _submitSymptoms,
            child: const Text(
              "Submit Symptoms",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          );
  }
}

class ViewSymptomsPage extends StatefulWidget {
  final String userId;

  const ViewSymptomsPage({super.key, required this.userId});

  @override
  _ViewSymptomsPageState createState() => _ViewSymptomsPageState();
}

class _ViewSymptomsPageState extends State<ViewSymptomsPage> {
  final SymptomService _symptomService = SymptomService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Symptom>? _symptoms;

  @override
  void initState() {
    super.initState();
    _fetchSymptoms();
  }

  void _fetchSymptoms() async {
    final token = await _storage.read(key: "auth_token");
    if (token != null) {
      final symptoms =
          await _symptomService.fetchSymptoms(token, widget.userId);
      setState(() {
        _symptoms = symptoms;
      });
    }
  }

  Future<void> _deleteSymptomWithConfirmation(String symptomId) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Symptom"),
        content: const Text("Are you sure you want to delete this symptom?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        await _symptomService.deleteSymptom(token, symptomId);
        _fetchSymptoms();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Symptom deleted successfully")),
          );
        }
      }
    }
  }

  Future<void> _editSymptom(String symptomId, String currentDescription) async {
    final TextEditingController controller =
        TextEditingController(text: currentDescription);

    String? newDescription = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Symptom"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Symptom Description",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (newDescription.isNotEmpty) {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        await _symptomService.updateSymptom(token, symptomId, newDescription);
        _fetchSymptoms();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Symptom updated successfully")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4CAF93),
              Color(0xFF379B7E),
              Color(0xFF1E7F68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            _buildHeader(),
            Expanded(
              child: _symptoms == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _buildSymptomsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Text(
            "Your Symptoms",
            style: TextStyle(color: Colors.white, fontSize: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsList() {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: _symptoms!.isEmpty
            ? const Center(
                child: Text(
                  "No symptoms recorded yet",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: _symptoms!.length,
                itemBuilder: (context, index) {
                  final symptom = _symptoms![index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        symptom.symptomDescription,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Recorded: ${symptom.timestamp}",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color(0xFF4CAF93)),
                            onPressed: () => _editSymptom(
                              symptom.symptomId,
                              symptom.symptomDescription,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSymptomWithConfirmation(
                                symptom.symptomId),
                          ),
                        ],
                      ),
                    ),
                  );
                }));
  }
}
