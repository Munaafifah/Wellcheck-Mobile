import 'package:flutter/material.dart';
import 'mongodb_service.dart'; // Import the MongoDB service
import 'prescriptions_model.dart'; // Import the combined models file

class PrescriptionUtils {
  static Patient? patient;

  /// Fetches the patient data (with nested prescriptions) and shows the dialog
  static Future<void> fetchData(BuildContext context, String patientId) async {
    patient = await MongoDBService.fetchPatientData(patientId);
    if (patient != null && patient!.prescriptions.isNotEmpty) {
      showPrescriptionDialog(context, patient!.prescriptions.first); // Show the first prescription
    } else {
      showErrorDialog(context, "No prescription details available.");
    }
  }

  /// Displays the prescription details in a dialog
  static void showPrescriptionDialog(BuildContext context, Prescription prescription) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Doctor\'s Prescription Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Box for Patient Name and Contact
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Patient Information:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text('Name: ${patient!.name}'),
                        Text('Contact: ${patient!.contact}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Box for Doctor's Name and Diagnosis
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                        color: const Color.fromARGB(255, 135, 201, 137)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Doctor Information:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text('Assigned Doctor: ${patient!.assignedDoctor}'),
                      const SizedBox(height: 10),
                      const Text(
                        'Diagnosis:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(prescription.diagnosisAilmentDescription),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Medications Table
                Container(
                  width: 350.0,
                  padding: const EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5.0),
                    border: Border.all(
                        color: const Color.fromARGB(255, 135, 201, 137)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medications:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Table(
                        border: TableBorder.all(
                            color:
                                const Color.fromARGB(255, 135, 201, 137)),
                        columnWidths: const {
                          0: IntrinsicColumnWidth(),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                            ),
                            children: const [
                              Padding(
                                padding:
                                    EdgeInsets.only(left: 10.0, top: 5.0),
                                child: Text('No.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                              Padding(
                                padding: EdgeInsets.all(5.0),
                                child: Text('Medicine Name',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(5.0),
                                child: Text('Dosage',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          for (int i = 0; i < prescription.medicineList.length; i++)
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5.0), 
                                  child: Text('${i + 1}'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Text(prescription.medicineList[i].name),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Text(prescription.medicineList[i].dosage),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
