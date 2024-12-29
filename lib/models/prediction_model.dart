class PredictionModel {
  final String predictionID;
  final List<String> diagnosisList;
  List<double> probabilityList;
  List<String> symptomsList;
  final DateTime timestamp;

  PredictionModel({
    required this.predictionID,
    required this.diagnosisList,
    required this.probabilityList,
    required this.symptomsList,
    required this.timestamp,
  });

  // Factory constructor to create an instance from JSON
  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      predictionID: json["predictionID"] ?? "unknown",  // Default if missing
      diagnosisList: List<String>.from(json["top_diseases"] ?? []),  // Parse diseases
      probabilityList: (json["probabilityList"] as List?)?.map((item) {
        // Parse "83.00%" to double 83.0
        return double.tryParse(item.replaceAll("%", "")) ?? 0.0;
      }).toList() ?? [],  // Default to empty list if null
      symptomsList: List<String>.from(json["symptomsList"] ?? []),  // Symptoms list
      timestamp: DateTime.tryParse(json["timestamp"] ?? "") ?? DateTime.now(),  // Timestamp fallback
    );
  }

  // toJson method to convert PredictionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      "predictionID": predictionID,
      "diagnosisList": diagnosisList,
      "probabilityList": probabilityList.map((prob) => "$prob%").toList(),  // Reformat back to percentage string
      "symptomsList": symptomsList,
      "timestamp": timestamp.toIso8601String(),
    };
  }
}
