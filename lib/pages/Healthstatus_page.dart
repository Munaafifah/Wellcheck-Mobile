import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../services/Healthstatus_service.dart';
import '../models/Healthstatus_model.dart';

class HealthstatusPage extends StatefulWidget {
  final String userId;

  const HealthstatusPage({super.key, required this.userId});

  @override
  _HealthstatusPageState createState() => _HealthstatusPageState();
}

class _HealthstatusPageState extends State<HealthstatusPage> {
  final HealthstatusService _healthstatusService = HealthstatusService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<HealthstatusModel>? _healthstatus;
  List<HealthstatusModel>? _filteredHealthstatus;
  bool _hasError = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchHealthstatus();
  }

  void _fetchHealthstatus() async {
    final token = await _storage.read(key: "auth_token");
    if (token != null) {
      try {
        final healthstatus = await _healthstatusService.fetchHealthstatusById(
            widget.userId, token);
        setState(() {
          _healthstatus = healthstatus;
          _filteredHealthstatus = healthstatus; // Initialize filtered list
          _hasError = false;
        });
      } catch (e) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  Future<void> _deleteHealthstatus(HealthstatusModel healthstatus) async {
    final token = await _storage.read(key: "auth_token");
    if (token != null) {
      try {
        await _healthstatusService.deleteHealthstatus(
            widget.userId, healthstatus.healthstatusID, token);
        setState(() {
          _healthstatus?.remove(healthstatus);
          _filteredHealthstatus?.remove(healthstatus); // Update filtered list
        });
      } catch (e) {
        // Handle error
      }
    }
  }

  void _filterHealthstatus(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredHealthstatus = _healthstatus; // Show all if query is empty
      });
    } else {
      setState(() {
        _filteredHealthstatus = _healthstatus?.where((healthstatus) {
          return healthstatus.additionalnotes
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
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
            const SizedBox(height: 10),
            _buildSearchBar(), // Add the search bar
            Expanded(
              child: _hasError
                  ? const Center(
                      child: Text(
                        "No Health Status List",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  : _filteredHealthstatus == null
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _filteredHealthstatus!.isEmpty
                          ? const Center(
                              child: Text(
                                "No Health Status available",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            )
                          : _buildHealthstatusList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const Expanded(
                child: Text(
                  "Health Status",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "History of health status",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        onChanged: _filterHealthstatus,
        decoration: InputDecoration(
          hintText: "Enter keyword to search",
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildHealthstatusList() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(60),
          topRight: Radius.circular(60),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _filteredHealthstatus!.length,
        itemBuilder: (context, index) {
          final healthstatus = _filteredHealthstatus![index];
          return _buildHealthstatusCard(healthstatus);
        },
      ),
    );
  }

  Widget _buildHealthstatusCard(HealthstatusModel healthstatus) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Additional Notes: ${healthstatus.additionalnotes}",
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  "Doctor ID: ${healthstatus.doctorID}",
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                Text(
                  "Timestamp: ${_formatTimestamp(healthstatus.timestamp)}",
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteHealthstatus(healthstatus),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) {
      return "Unknown time";
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toLocal());
  }
}
