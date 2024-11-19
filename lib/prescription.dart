import 'package:flutter/material.dart';
import 'mongodb_service.dart'; // Import the MongoDB service
import 'prescriptions_model.dart'; // Import the prescription model

class PrescriptionUtils {
  static Prescription? prescription;

  /// Fetches the prescription data and shows the appropriate dialog
  static Future<void> fetchData(BuildContext context) async {
    prescription = await MongoDBService.fetchPrescription();
    if (prescription != null) {
      showPrescriptionDialog(context);
    } else {
      showErrorDialog(context, "Failed to fetch prescription details.");
    }
  }

  /// Displays the prescription details in a dialog
  static void showPrescriptionDialog(BuildContext context) {
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
                // Box for Doctor's Name and Specialty
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
                          'Doctor Information:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text('Name: ${prescription!.doctorName}'),
                        Text('Specialty: ${prescription!.doctorSpecialty}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Box for Time of Prescription
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                        color: const Color.fromARGB(255, 135, 201, 137)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        'Time of Prescription:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 5),
                      Text(prescription!.time),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Box for Grouped Details: Prescriptions, Diagnosis, Medications
                Container(
                  width: 350.0,
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
                      // Prescription Notes Box
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
                              'Prescriptions:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(prescription!.notes),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Diagnosis Box
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
                              'Diagnosis:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(prescription!.diagnosis),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Medications Box with Table
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
                                    Padding(
                                      padding: EdgeInsets.all(5.0),
                                      child: Text('Frequency',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                for (int i = 0;
                                    i < prescription!.medicationsList.length;
                                    i++)
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text('${i + 1}'),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(prescription!
                                            .medicationsList[i].name),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(prescription!
                                            .medicationsList[i].dosage),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text(prescription!
                                            .medicationsList[i].frequency),
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
                const SizedBox(height: 20),
                // Pagination Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 1; i <= 5; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Logic to handle page change can be implemented here
                          },
                          child: Text('$i'),
                        ),
                      ),
                  ],
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
