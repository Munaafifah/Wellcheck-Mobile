class PredictionModel {
  final String predictionID;
  final List<String> diagnosisList;
  List<double> probabilityList;
  List<String> symptomsList;
  final DateTime timestamp;
  final bool approved;
  final bool rejected;

  PredictionModel({
    required this.predictionID,
    required this.diagnosisList,
    required this.probabilityList,
    required this.symptomsList,
    required this.timestamp,
    this.approved = false,
    this.rejected = false,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      predictionID: json["predictionID"] ?? "unknown",
      diagnosisList: List<String>.from(
          json["top_diseases"] ?? json["diagnosisList"] ?? []),
      probabilityList: (json["probabilityList"] as List?)?.map((item) {
            if (item is double) return item;
            if (item is int) return item.toDouble();
            return double.tryParse(
                    item.toString().replaceAll("%", "").trim()) ??
                0.0;
          }).toList() ??
          [],
      symptomsList: List<String>.from(json["symptomsList"] ?? []),
      timestamp: DateTime.tryParse(json["timestamp"] ?? "") ?? DateTime.now(),
      approved: json["approved"] ?? false,
      rejected: json["rejected"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "predictionID": predictionID,
      "symptomsList": symptomsList,
      "diagnosisList": diagnosisList,
      "probabilityList": probabilityList
          .map((prob) => prob)
          .toList(), // ← just send raw double
      "timestamp": timestamp.toUtc().toIso8601String(),
      "approved": approved,
      "rejected": rejected,
    };
  }
}
