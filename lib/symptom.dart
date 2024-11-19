import 'package:flutter/material.dart';
import 'symptom_service.dart'; // Import the service

class SymptomUtils {
  static final TextEditingController _symptomController = TextEditingController();

  /// Displays a dialog to input daily health symptoms
  static void showSymptomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send Daily Health Symptom'),
          content: TextField(
            controller: _symptomController,
            decoration:
                const InputDecoration(hintText: "Enter your symptoms here"),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                String symptoms = _symptomController.text;
                _symptomController.clear();
                Navigator.of(context).pop(); // Close the dialog
                bool success = await SymptomService.sendSymptom(symptoms);

                // Show confirmation or error dialog
                if (success) {
                  showSymptomSubmittedDialog(context, symptoms);
                } else {
                  showErrorDialog(context, "Failed to send symptoms to the database.");
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  /// Displays a dialog confirming symptom submission
  static void showSymptomSubmittedDialog(BuildContext context, String symptoms) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Symptoms Submitted'),
          content: Text('Your symptoms: "$symptoms" have been submitted.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  /// Displays an error dialog
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}
