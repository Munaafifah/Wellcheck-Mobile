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
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load prediction")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prediction Details")),
      body: _prediction == null
          ? const Center(child: CircularProgressIndicator())
          : _prediction!.isEmpty
              ? const Center(child: Text("No predictions available"))
              : ListView.builder(
                  itemCount: _prediction!.length,
                  itemBuilder: (context, index) {
                    final prediction = _prediction![index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Symptoms List:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: prediction.symptomsList.map((symptom) {
                                final formattedSymptom =
                                    symptom.replaceAll('_', ' ');
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("•"), // Bullet point
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "${formattedSymptom[0].toUpperCase()}${formattedSymptom.substring(1).toLowerCase()}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Timestamp: ${prediction.timestamp.toLocal()}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Diagnosis and Probabilities:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Table(
                              border: TableBorder.all(),
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(1),
                              },
                              children: [
                                const TableRow(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        "Diagnosis",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        "Probability (%)",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ...List.generate(
                                    prediction.diagnosisList.length, (i) {
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child:
                                            Text(prediction.diagnosisList[i]),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "${(prediction.probabilityList[i]).toStringAsFixed(2)}%",
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
