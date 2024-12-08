import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sickness_service.dart';
import '../models/sickness_model.dart'; // Ensure the correct import path

class SicknessList extends StatefulWidget {
  @override
  _SicknessListState createState() => _SicknessListState();
}

class SicknessService {
  static const String baseUrl = 'http://localhost:5000'; // Your API URL

  Future<List<Sickness>> fetchSicknesses() async {
    final response = await http.get(Uri.parse('$baseUrl/sickness'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Sickness.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch sicknesses: ${response.body}');
    }
  }
}

class _SicknessListState extends State<SicknessList> {
  final SicknessService _sicknessService = SicknessService(); // Instance of your service
  List<Sickness> _sicknesses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSicknesses();
  }

  Future<void> _loadSicknesses() async {
    try {
      _sicknesses = await _sicknessService.fetchSicknesses();
    } catch (e) {
      // Handle errors here (e.g., show a message to the user)
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _sicknesses.length,
      itemBuilder: (context, index) {
        final sickness = _sicknesses[index];
        return ListTile(
          title: Text(sickness.name),
          subtitle: Text('Price: RM${sickness.appointmentPrice.toStringAsFixed(2)}'),
        );
      },
    );
  }
}