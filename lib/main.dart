import 'package:flutter/material.dart';
import 'prescription.dart'; // For prescription-related functions
import 'symptom.dart'; // For symptom-related functions
import 'login_page.dart'; // Import login page
//import 'appointment_page.dart'; // Import appointment page
import 'viewListAppointment.dart';
import 'edit_health_information.dart'; // Import the edit health information page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WellCheck: Smart Health Monitoring System',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/login', // Set login as the initial route
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const MyHomePage(), // Dashboard route
        '/appointment': (context) => AppointmentsPage(), // Appointment route
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String patientName = "Muna Doe";
  final String patientAddress = "123 Health Ave";
  final String patientPhone = "+1 234 567 890";
  final String emergencyContact = "+1 987 654 321";
  final String patientImage = "https://via.placeholder.com/150";

  int _selectedIndex =
      0; // Track the selected index for the bottom navigation bar

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation based on the selected index
    switch (index) {
      case 0:
        // Dashboard
        Navigator.pushNamed(context, '/dashboard');
        break;
      case 1:
        // View History
        // Implement navigation to View History page
        break;
      case 2:
      // Navigate to Edit Health Information page
      case 3:
        // Health Condition
        Navigator.pushNamed(context, '/editHealthInfo');
        break;
      case 4:
        // Create Appointment
        Navigator.pushNamed(context, '/appointment');
        break;
      case 5:
        // Logout
        Navigator.pushNamed(context, '/login');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WellCheck: Smart Health Monitoring System'),
        backgroundColor: const Color(0xFF4CAF93),
      ),
      body: Container(
        color: Colors.grey[200], // Set the background color to soft green
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    NetworkImage(patientImage), // Display patient image
              ),
              const SizedBox(height: 10),
              Text(patientName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(patientAddress),
              Text(patientPhone),
              Text('Emergency Contact: $emergencyContact'),
              const SizedBox(height: 20), // Space between details and buttons
              ElevatedButton(
                onPressed: () {
                  PrescriptionUtils.fetchData(context); // Call the new method
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Button color
                ),
                child: const Text('View Prescription Details'),
              ),
              const SizedBox(height: 20), // Space between buttons
              ElevatedButton(
                onPressed: () {
                  SymptomUtils.showSymptomDialog(
                      context); // Call the new method
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Button color
                ),
                child: const Text('Send Daily Health Symptom'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF4CAF93),
        selectedItemColor:
            const Color(0xFF2E7D32), // Change the selected item color
        unselectedItemColor: const Color.fromARGB(255, 164, 219, 157),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'View History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Edit Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Health Information',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create Appointment', // New item for creating an appointment
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
