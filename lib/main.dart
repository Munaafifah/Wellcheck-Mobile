import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  const MyApp({super.key});

  Future<String?> _checkAuth() async {
    return await _storage.read(key: "auth_token");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Health Support System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<String?>(
        future: _checkAuth(),
        builder: (context, snapshot) {
          // If session token exists, navigate to Dashboard
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data != null) {
              return const DashboardPage(userId: ""); // You may add logic to fetch userId if stored.
            } else {
              return const LoginPage();
            }
          }

          // Show loading while checking authentication
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
