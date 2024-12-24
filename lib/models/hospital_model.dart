class Field {
  final String label;
  final String type; // e.g., date, multi-select, dropdown
  final List<String>? options; // Options for dropdowns
  final bool required;

  Field({
    required this.label,
    required this.type,
    this.options,
    required this.required,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    var optionsFromJson = json['options'] as List?;
    List<String>? options = optionsFromJson?.map((i) => i.toString()).toList();

    return Field(
      label: json['label'],
      type: json['type'],
      options: options,
      required: json['required'],
    );
  }
}