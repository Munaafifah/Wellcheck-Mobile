class Symptom {
  final String description;

  Symptom({required this.description});

  Map<String, dynamic> toJson() {
    return {
      'symptom': description,
    };
  }
}
