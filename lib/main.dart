import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'pages/login_page.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      "pk_test_51QHKbcRoG6cEJt3PQM2JuszEE4FxQOpNLWy3iQIaGdLTa0is4BwCdPwRTQkEZb7n3zbqOD5r6y93Qa1PlOjvE4rQ00fppKrvBu";
  await Stripe.instance.applySettings();
  try {
    await Stripe.instance.applySettings();
    print('Stripe initialized successfully');
  } catch (e) {
    print('Stripe initialization failed: $e');
  }

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
            // Always navigate to LoginPage regardless of the token's existence
            return const LoginPage();
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
