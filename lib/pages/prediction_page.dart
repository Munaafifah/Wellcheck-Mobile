import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/prediction_service.dart';
import '../models/prediction_model.dart';

class PredictionPage extends StatefulWidget {
  final String userId;

  const PredictionPage({super.key, required this.userId});

  @override
  _PredictionPageState createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final PredictionService _predictionService = PredictionService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<PredictionModel>? _prediction;
  List<PredictionModel>? _filteredPrediction;
  String _selectedMonth = "";
  String _selectedYear = "";
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchPrediction();
  }

  void _fetchPrediction() async {
    final token = await _storage.read(key: "auth_token");
    if (token != null) {
      try {
        final prediction =
            await _predictionService.fetchPredictionById(widget.userId, token);
        setState(() {
          _prediction = prediction;
          _applyFilter();
        });
      } catch (e) {
        setState(() {
          _prediction = [];
          _filteredPrediction = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load predictions")),
        );
      }
    }
  }

  void _applyFilter() {
    _filteredPrediction = _prediction;

    if (_selectedYear.isNotEmpty) {
      _filteredPrediction = _filteredPrediction?.where((prediction) {
        final predictionDate = prediction.timestamp.toLocal();
        return predictionDate.year.toString() == _selectedYear;
      }).toList();
    }

    if (_selectedMonth.isNotEmpty) {
      _filteredPrediction = _filteredPrediction?.where((prediction) {
        final predictionDate = prediction.timestamp.toLocal();
        final month = predictionDate.month.toString().padLeft(2, '0');
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
          "Diagnoses Results",
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
              child: _filteredPrediction == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : _filteredPrediction!.isEmpty
                      ? const Center(
                          child: Text(
                            "No prediction found for the selected filter",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : _buildPredictionPager(),
            ),
          ],
        ),
      ),
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
    if (_prediction == null) return [];
    final years = _prediction!.map((p) => p.timestamp.year.toString()).toSet();
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

  Widget _buildPredictionPager() {
    final prediction = _filteredPrediction![_currentPage];
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
          Expanded(child: _buildPredictionCard(prediction)),
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
                  "Page ${_currentPage + 1} of ${_filteredPrediction!.length}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.arrow_forward, color: Color(0xFF4CAF93)),
                  onPressed: _currentPage < _filteredPrediction!.length - 1
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
              children: List.generate(_filteredPrediction!.length, (index) {
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

 Widget _buildPredictionCard(PredictionModel prediction) {
  return Container(
    height: 200, // Set desired height
    child: Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
              Text(
                "Time of Prediction: ${prediction.timestamp.toLocal().toString().split(' ')[0]}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 10),
            _buildSymptomsTable(prediction.symptomsList),
            const SizedBox(height: 10),
            _buildDiagnosisTable(prediction),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSymptomsTable(List<String> symptoms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Symptoms List",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF4CAF93),
          ),
        ),
        const SizedBox(height: 8),
        ...symptoms.map((symptom) {
          final formattedSymptom = symptom.replaceAll('_', ' ');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
                "• ${formattedSymptom[0].toUpperCase()}${formattedSymptom.substring(1).toLowerCase()}"),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDiagnosisTable(PredictionModel prediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Diagnosis and Probabilities",
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
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFF4CAF93)),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Diagnosis",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Probability (%)",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
            ...List.generate(prediction.diagnosisList.length, (index) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(prediction.diagnosisList[index]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        "${(prediction.probabilityList[index]).toStringAsFixed(2)}%"),
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "Please note that this is just a prediction and should not replace a doctor's diagnosis.\nAlways consult a medical professional for any health concerns.",
          style: TextStyle(
            fontSize: 10,
            fontStyle: FontStyle.italic,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
