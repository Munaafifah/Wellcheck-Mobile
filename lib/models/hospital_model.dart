// import 'dart:convert';
// import 'package:flutter/material.dart';

class Hospital {
  final String id;
  final String name;
  final List<HospitalFormField> formFields;

  Hospital({required this.id, required this.name, required this.formFields});

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['_id'],
      name: json['name'],
      formFields: (json['form_fields'] as List)
          .map((field) => HospitalFormField.fromJson(field))
          .toList(),
    );
  }
}

class HospitalFormField {
  final String label;
  final String type; // e.g., "text", "date", "dropdown"
  final bool required; // Whether this field is required
  final List<String>? options; 
  
  HospitalFormField({// Options for dropdowns or multi-selects
  required this.label,
    required this.type,
    this.required = false,
    this.options,
    
  });

  factory HospitalFormField.fromJson(Map<String, dynamic> json) {
    return HospitalFormField(
      label: json['label'],
      type: json['type'],
      required: json['required'] ?? false,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}