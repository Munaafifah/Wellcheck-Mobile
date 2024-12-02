import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:session/models/symptom_model.dart';
import '../services/symptom_service.dart';

class SymptomPage extends StatefulWidget {
  const SymptomPage({super.key});

  @override
  _SymptomPageState createState() => _SymptomPageState();
}

class _SymptomPageState extends State<SymptomPage> {
  final TextEditingController _symptomController = TextEditingController();
  final SymptomService _symptomService = SymptomService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  void _submitSymptom() async {
    final symptomDescription = _symptomController.text;
    if (symptomDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a symptom")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        await _symptomService.addSymptom(token, symptomDescription);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Symptom added successfully")),
        );
        _symptomController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add symptom")),
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
            "Describe Your Symptoms",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildSymptomInput(),
          const SizedBox(height: 20),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSymptomInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _symptomController,
        decoration: InputDecoration(
          hintText: "Enter your symptoms here...",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.all(20),
        ),
        maxLines: 5,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF93)),
            ),
          )
        : ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF93),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: _submitSymptom,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text(
              "Submit Symptom",
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
      final symptoms = await _symptomService.fetchSymptoms(token, widget.userId);
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

    if (newDescription != null && newDescription.isNotEmpty) {
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
                          icon: const Icon(Icons.edit, color: Color(0xFF4CAF93)),
                          onPressed: () => _editSymptom(
                            symptom.symptomId,
                            symptom.symptomDescription,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteSymptomWithConfirmation(symptom.symptomId),
                        ),
                      ],
                    ),
                  ),
                );
              }
              )
            );
  }
}