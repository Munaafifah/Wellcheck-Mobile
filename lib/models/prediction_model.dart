class PredictionModel {
  final String predictionID;
  final List<String> diagnosisList;
  final List<double> probabilityList;
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
      predictionID:
          json["predictionID"] ?? "unknown", // Default value if missing
      diagnosisList: List<String>.from(
          json["top_diseases"] ?? []), // Default to empty list if null
      probabilityList:
          List<double>.from((json["top_diseases"] ?? []).map((item) {
        return double.parse(item.split(':')[1].replaceAll("%", ""));
      })),
      symptomsList: List<String>.from(
          json["symptomsList"] ?? []), // Handle symptoms list safely
      timestamp: DateTime.tryParse(json["timestamp"] ?? "") ?? DateTime.now(),
    );
  }

  // toJson method to convert PredictionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      "predictionID": predictionID,
      "diagnosisList": diagnosisList,
      "probabilityList": probabilityList,
      "symptomsList": symptomsList,
      "timestamp": timestamp.toIso8601String(),
    };
  }
}
