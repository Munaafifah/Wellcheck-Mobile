import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../services/Healthstatus_service.dart';
import '../models/Healthstatus_model.dart';
import '../services/disease_precaution_service.dart';

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
  int _currentPage = 1;
  final int _itemsPerPage = 5;

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
          _filteredHealthstatus = healthstatus;
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
          _filteredHealthstatus?.remove(healthstatus);
        });
      } catch (e) {}
    }
  }

  void _filterHealthstatus(String query) {
    setState(() {
      _filteredHealthstatus = query.isEmpty
          ? _healthstatus
          : _healthstatus
              ?.where((h) =>
                  h.additionalnotes.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  void _goToPage(int page) => setState(() => _currentPage = page);

  int _getTotalPages() {
    if (_filteredHealthstatus == null || _filteredHealthstatus!.isEmpty)
      return 1;
    return (_filteredHealthstatus!.length / _itemsPerPage).ceil();
  }

  void _showHealthTips(HealthstatusModel healthstatus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final diseases = healthstatus.diagnosisList;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E7F68).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.health_and_safety,
                          color: Color(0xFF1E7F68), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Recommended Health Tips",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E7F68),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Symptoms row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 6,
                  children: healthstatus.additionalnotes
                      .split(', ')
                      .map(
                        (s) => Chip(
                          label: Text(s.replaceAll('_', ' '),
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor:
                              const Color(0xFF1E7F68).withOpacity(0.1),
                          labelStyle: const TextStyle(color: Color(0xFF1E7F68)),
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              // Tips list
              Expanded(
                child: diseases.isEmpty
                    ? const Center(
                        child: Text("No health tips available.",
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: diseases.length,
                        itemBuilder: (context, index) {
                          final disease = diseases[index];
                          final tips =
                              DiseasePrecautionService.getPrecautions(disease);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E7F68).withOpacity(0.05),
                              border: Border(
                                left: BorderSide(
                                  color: const Color(0xFF1E7F68),
                                  width: 4,
                                ),
                              ),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.shield,
                                          color: Color(0xFF1E7F68), size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Tip Group ${index + 1}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E7F68),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ...tips.map((tip) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 3),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text("• ",
                                                style: TextStyle(
                                                    color: Color(0xFF1E7F68))),
                                            Expanded(
                                              child: Text(tip,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black87)),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Note
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "System-generated tips. Consult a doctor for confirmation.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final visibleHealthstatus = _filteredHealthstatus?.sublist(
        startIndex, endIndex.clamp(0, _filteredHealthstatus!.length));

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF93), Color(0xFF379B7E), Color(0xFF1E7F68)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildHeader(),
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            Expanded(
              child: _hasError
                  ? const Center(
                      child: Text("No Health Status List",
                          style: TextStyle(color: Colors.white, fontSize: 16)))
                  : _filteredHealthstatus == null
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : _filteredHealthstatus!.isEmpty
                          ? const Center(
                              child: Text("No Health Status available",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)))
                          : _buildHealthstatusList(visibleHealthstatus),
            ),
            if (_getTotalPages() > 1) _buildPagination(),
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
          const Expanded(
            child: Column(
              children: [
                Text("Health Status",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Tap a record to view health tips",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 48),
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
          hintText: "Search symptoms...",
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildHealthstatusList(List<HealthstatusModel>? visibleHealthstatus) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        itemCount: visibleHealthstatus?.length ?? 0,
        itemBuilder: (context, index) {
          final healthstatus = visibleHealthstatus![index];
          return _buildHealthstatusCard(healthstatus);
        },
      ),
    );
  }

  Widget _buildHealthstatusCard(HealthstatusModel healthstatus) {
    final symptoms = healthstatus.additionalnotes.split(', ');
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showHealthTips(healthstatus),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E7F68).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medical_information,
                        color: Color(0xFF1E7F68), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(healthstatus.timestamp.toLocal()),
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E7F68).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.visibility,
                            size: 12, color: Color(0xFF1E7F68)),
                        SizedBox(width: 4),
                        Text("View Tips",
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1E7F68),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    onPressed: () => _deleteHealthstatus(healthstatus),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: symptoms
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E7F68).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    const Color(0xFF1E7F68).withOpacity(0.3)),
                          ),
                          child: Text(
                            s.replaceAll('_', ' '),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF1E7F68)),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_currentPage > 1)
            _pageBtn(Icons.arrow_back, () => _goToPage(_currentPage - 1)),
          const SizedBox(width: 8),
          for (int i = 1; i <= _getTotalPages(); i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => _goToPage(i),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(i.toString(),
                        style: TextStyle(
                            color: i == _currentPage
                                ? const Color(0xFF1E7F68)
                                : Colors.white,
                            fontWeight: i == _currentPage
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (_currentPage < _getTotalPages())
            _pageBtn(Icons.arrow_forward, () => _goToPage(_currentPage + 1)),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
