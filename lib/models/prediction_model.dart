class PredictionModel {
  final String predictionID;
  final List<String> diagnosisList;
  final List<int> probabilityList;
  final List<String> symptomsList;
  final DateTime timestamp;

  PredictionModel({
    required this.predictionID,
    required this.diagnosisList,
    required this.probabilityList,
    required this.symptomsList,
    required this.timestamp,
  });

  // Factory constructor to create an instance from a JSON map
  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      predictionID: json["predictionID"],
      diagnosisList: List<String>.from(json["diagnosisList"]),
      probabilityList: List<int>.from(json["probabilityList"]),
      symptomsList: List<String>.from(json["symptomsList"]),
      timestamp: DateTime.parse(json["timestamp"]),
    );
  }
}
