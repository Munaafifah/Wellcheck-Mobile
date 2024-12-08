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
          _applyFilter(); // Apply the filter immediately after fetching
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
  if (_selectedMonth.isEmpty) {
    // Show all prescriptions if "All" is selected
    _filteredPrescriptions = _prescriptions;
  } else {
    // Filter prescriptions by the selected month
    _filteredPrescriptions = _prescriptions?.where((prescription) {
      final prescriptionDate = prescription.timestamp.toLocal();
      final month = prescriptionDate.month.toString().padLeft(2, '0'); // Ensure month is 2 digits (e.g., "01" for January)
      return month == _selectedMonth;
    }).toList();
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
            _buildHeader(context),
            const SizedBox(height: 10),
            _buildFilterDropdown(),
            Expanded(
              child: _filteredPrescriptions == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : _buildPrescriptionList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                  "Prescriptions",
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
            "View your medical prescriptions here",
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

  Widget _buildFilterDropdown() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: DropdownButtonFormField<String>(
      value: _selectedMonth.isEmpty ? null : _selectedMonth,
      hint: const Text("All", style: TextStyle(color: Colors.black)),
      items: [
        const DropdownMenuItem(value: "", child: Text("All")),
        ...List.generate(12, (index) {
          final month = (index + 1).toString().padLeft(2, '0'); // Ensure month is 2 digits
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
      decoration: InputDecoration(
        labelText: "Filter by Month",
        labelStyle: const TextStyle(color: Color.fromARGB(255, 137, 87, 146)),
        filled: true,
        fillColor: Colors.white, // Background color
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
          borderSide: const BorderSide(color:Color.fromARGB(255, 186, 151, 192)),
        ),
      ),
      dropdownColor: Colors.grey.shade200, // Dropdown menu background
    ),
  );
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


  Widget _buildPrescriptionList() {
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
        itemCount: _filteredPrescriptions!.length,
        itemBuilder: (context, index) {
          final prescription = _filteredPrescriptions![index];
          return _buildPrescriptionCard(prescription);
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Prescription ID: ${prescription.prescriptionId}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF4CAF93),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                  onPressed: () {
                    _showPrescriptionDetails(context, prescription);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
                "Diagnosis", prescription.diagnosisAilmentDescription),
            _buildDetailRow(
                "Description", prescription.prescriptionDescription),
            _buildDetailRow(
              "Date",
              "${prescription.timestamp.toLocal()}".split(' ')[0],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionDetails(
      BuildContext context, Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Prescription Details - ID: ${prescription.prescriptionId}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            border: TableBorder.all(
              color: Colors.black, // Table border color
              width: 1,
            ),
            children: [
              _buildTableRow(
                  "Diagnosis", prescription.diagnosisAilmentDescription),
              _buildTableRow("Doctor ID", prescription.doctorId),
              _buildTableRow("Medicines", prescription.medicineList.join(", ")),
              _buildTableRow(
                  "Description", prescription.prescriptionDescription),
              _buildTableRow(
                  "Date", "${prescription.timestamp.toLocal()}".split(' ')[0]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9), // Light green background for rows
        borderRadius: BorderRadius.circular(15), // Smooth rounded edges
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Text(
            "$title:",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF93),
              fontSize: 16,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Text(
            value,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ],
    );
  }

  
}
