import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
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
  bool _hasError = false; // Track loading error state

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
          _hasError = false; // Reset error state on successful fetch
        });
      } catch (e) {
        setState(() {
          _hasError = true; // Set error state on failure
        });
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
            const SizedBox(height: 10),
            Expanded(
              child: _hasError // Check for error state
                  ? const Center(
                      child: Text(
                        "No Symptom List",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  : _prediction == null
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _prediction!.isEmpty
                          ? const Center(
                              child: Text(
                                "No Symptoms available",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            )
                          : _buildPredictionList(),
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
                  "Symptoms",
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
            "View your symptom list here",
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

  Widget _buildPredictionList() {
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
        itemCount: _prediction!.length,
        itemBuilder: (context, index) {
          final prediction = _prediction![index];
          return _buildPredictionCard(prediction);
        },
      ),
    );
  }

  Widget _buildPredictionCard(PredictionModel prediction) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Symptoms List:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF4CAF93),
              ),
            ),
            const SizedBox(height: 8),
            _buildNumberedList(prediction.symptomsList),
            const SizedBox(height: 16),
            Text(
              "Timestamp: ${_formatTimestamp(prediction.timestamp)}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberedList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        items.length,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            "${index + 1}. ${_formatSymptom(items[index])}",
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }

  String _formatSymptom(String symptom) {
    // Replace underscores with spaces and capitalize each word
    return symptom.split('_').map((word) {
      return word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : '';
    }).join(' ');
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) {
      return "Unknown time"; // Fallback for null timestamps
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toLocal());
  }
}
