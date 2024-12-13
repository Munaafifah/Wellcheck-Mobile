import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/prescription_service.dart';
import '../models/prescription_model.dart';

class PrescriptionPage extends StatefulWidget {
  final String userId;

  const PrescriptionPage({super.key, required this.userId});

  @override
  _PrescriptionPageState createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Prescription>? _prescriptions;
  List<Prescription>? _filteredPrescriptions;
  String _selectedMonth = "";
  String _selectedYear = "";
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  void _fetchPrescriptions() async {
    final token = await _storage.read(key: "auth_token");
    if (token != null) {
      try {
        final prescriptions =
            await _prescriptionService.fetchPrescriptions(widget.userId, token);
        setState(() {
          _prescriptions = prescriptions;
          _applyFilter();
        });
      } catch (e) {
        setState(() {
          _prescriptions = [];
          _filteredPrescriptions = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("No prescription found for this patient.")),
        );
      }
    }
  }

  void _applyFilter() {
    _filteredPrescriptions = _prescriptions;

    if (_selectedYear.isNotEmpty) {
      _filteredPrescriptions = _filteredPrescriptions?.where((prescription) {
        final prescriptionDate = prescription.timestamp.toLocal();
        return prescriptionDate.year.toString() == _selectedYear;
      }).toList();
    }

    if (_selectedMonth.isNotEmpty) {
      _filteredPrescriptions = _filteredPrescriptions?.where((prescription) {
        final prescriptionDate = prescription.timestamp.toLocal();
        final month = prescriptionDate.month.toString().padLeft(2, '0');
        return month == _selectedMonth;
      }).toList();
    }

    _currentPage = 0; // Reset to the first page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF93),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "View Prescriptions",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
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
            const SizedBox(height: 10),
            _buildFilterDropdowns(),
            Expanded(
              child: _filteredPrescriptions == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : _filteredPrescriptions!.isEmpty
                      ? const Center(
                          child: Text(
                            "No prescription found for the selected filter",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : _buildPrescriptionPager(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF4CAF93),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: const Text(
        "View Prescriptions",
        style: TextStyle(color: Colors.black),
      ),
      centerTitle: true,
    );
  }

  Widget _buildFilterDropdowns() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Month Dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedMonth.isEmpty ? null : _selectedMonth,
              hint: const Text("Month", style: TextStyle(color: Colors.black)),
              items: [
                const DropdownMenuItem(value: "", child: Text("All Months")),
                ...List.generate(12, (index) {
                  final month = (index + 1).toString().padLeft(2, '0');
                  return DropdownMenuItem(
                    value: month,
                    child: Text(
                      _monthName(index + 1),
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMonth = value ?? "";
                  _applyFilter();
                });
              },
              decoration: _dropdownDecoration("Filter by Month"),
            ),
          ),
          const SizedBox(width: 8),
          // Year Dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedYear.isEmpty ? null : _selectedYear,
              hint: const Text("Year", style: TextStyle(color: Colors.black)),
              items: [
                const DropdownMenuItem(value: "", child: Text("All Years")),
                ..._getUniqueYears().map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child:
                        Text(year, style: const TextStyle(color: Colors.black)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedYear = value ?? "";
                  _applyFilter();
                });
              },
              decoration: _dropdownDecoration("Filter by Year"),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color.fromARGB(255, 137, 87, 146)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 186, 151, 192)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 186, 151, 192)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 186, 151, 192)),
      ),
    );
  }

  List<String> _getUniqueYears() {
    if (_prescriptions == null) return [];
    final years =
        _prescriptions!.map((p) => p.timestamp.year.toString()).toSet();
    return years.toList()..sort();
  }

  String _monthName(int month) {
    const monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return monthNames[month - 1];
  }

  Widget _buildPrescriptionPager() {
    final prescription = _filteredPrescriptions![_currentPage];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(60),
          topRight: Radius.circular(60),
        ),
      ),
      child: Column(
        children: [
          Expanded(child: _buildPrescriptionCard(prescription)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF4CAF93)),
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                        }
                      : null,
                ),
                Text(
                  "Page ${_currentPage + 1} of ${_filteredPrescriptions!.length}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.arrow_forward, color: Color(0xFF4CAF93)),
                  onPressed: _currentPage < _filteredPrescriptions!.length - 1
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_filteredPrescriptions!.length, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12), // Adds rounded corners
                      color: _currentPage == index
                          ? const Color(0xFF4CAF93) // Active page color
                          : Colors.grey.shade300, // Inactive page color
                    ),
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color:
                            _currentPage == index ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Doctor's Prescriptions & Diagnosis Ailments",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF4CAF93), // Dark green
              ),
            ),
            const SizedBox(height: 16),
            _buildSingleFieldTable(
              "Time of Prescription",
              "${prescription.timestamp.toLocal()}".split(' ')[0],
            ),
            const SizedBox(height: 10),
            _buildSingleFieldTable(
              "Prescription",
              prescription.prescriptionDescription,
            ),
            const SizedBox(height: 10),
            _buildSingleFieldTable(
              "Diagnosis Ailment",
              prescription.diagnosisAilmentDescription,
            ),
            const SizedBox(height: 10),
            _buildMedicineTable(prescription),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleFieldTable(String title, String value) {
    return Table(
      border: TableBorder.all(
        color: Colors.black,
        width: 1,
        //borderRadius: BorderRadius.circular(10),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.3),
        1: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            color: Color(0xFF4CAF93), // Light green for contrast
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicineTable(Prescription prescription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Medicine List",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF4CAF93),
          ),
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.black, width: 1),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(2),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFF4CAF93)),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("No",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Medicine",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Time",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
            ...List.generate(prescription.medicineList.length, (index) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${index + 1}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(prescription.medicineList[index]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        "${prescription.timestamp.toLocal()}".split(' ')[0]),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
}
