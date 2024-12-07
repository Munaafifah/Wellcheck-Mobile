import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:session/pages/appointment_page.dart';
import 'package:session/pages/login_page.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_model.dart';
import 'prescription_page.dart';
import 'symptom_page.dart';
import '../pages/viewAppointment_page.dart';

class DashboardPage extends StatefulWidget {
  final String userId;

  const DashboardPage({super.key, required this.userId});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _dashboardService = DashboardService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Patient? _patient;

  @override
  void initState() {
    super.initState();
    _fetchPatient();
  }

  void _fetchPatient() async {
    final token = await _storage.read(key: "auth_token");
    if (token != null) {
      final patient =
          await _dashboardService.fetchPatient(widget.userId, token);
      setState(() {
        _patient = patient;
      });
    }
  }

  // Logout Confirmation Function
  void _logout() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout Confirmation"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.deleteAll();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged out successfully")),
      );
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
              child: _patient == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _buildDashboardContent(),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Dashboard",
            style: TextStyle(color: Colors.white, fontSize: 30),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
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
          Text(
            "Welcome, ${_patient!.name}!",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildPatientDetails(),
          const SizedBox(height: 30),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildPatientDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow("Address", _patient!.address),
        _buildDetailRow("Contact", _patient!.contact),
        _buildDetailRow("Emergency Contact", _patient!.emergencyContact),
        _buildDetailRow("Assigned Doctor", _patient!.assignedDoctor),
      ],
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          "View Doctor's Prescription",
          Icons.medical_services,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PrescriptionPage(userId: widget.userId),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          "Add Symptom",
          Icons.add_circle_outline,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SymptomPage()),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          "View Symptoms",
          Icons.visibility_outlined,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewSymptomsPage(userId: widget.userId),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          "Appointments",
          Icons.calendar_today,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ViewAppointmentsPage(userId: widget.userId),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF93),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
