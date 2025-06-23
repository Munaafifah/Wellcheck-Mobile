import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:session/config.dart';
import '../services/login_service.dart';
import '../models/login_model.dart' hide LoginRequest;
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Updated login function with detailed debugging
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Create the request
      final request = LoginRequest(
        userId: _userIdController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print('=== LOGIN DEBUG INFO ===');
      print('User ID: ${request.userId}');
      print('Password length: ${request.password.length}');
      print('Config base URL: ${Config.baseUrl}');
      print('Full login URL: ${Config.baseUrl}/login');

      try {
        print('🔄 Calling LoginService...');
        final token = await LoginService().login(request);

        print('✅ Login successful! Token received: ${token != null}');

        if (token != null) {
          await _storage.write(key: "auth_token", value: token);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DashboardPage(userId: _userIdController.text),
            ),
          );
        } else {
          print('❌ Token is null');
          _showErrorDialog("Invalid credentials. Please try again.");
        }
      } catch (e) {
        print('💥 LOGIN ERROR CAUGHT:');
        print('Error type: ${e.runtimeType}');
        print('Error message: $e');
        print('Stack trace:');
        print(StackTrace.current);

        // Show more specific error message
        String errorMessage = "An unexpected error occurred. Please try again.";

        if (e.toString().contains('SocketException')) {
          errorMessage =
              "Cannot connect to server. Please check your internet connection.";
        } else if (e.toString().contains('TimeoutException')) {
          errorMessage = "Connection timeout. Please try again.";
        } else if (e.toString().contains('FormatException')) {
          errorMessage = "Server response error. Please try again.";
        }

        _showErrorDialog(errorMessage);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Login Error",
          style: TextStyle(color: Colors.red[700]),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF93), Color(0xFF379B7E), Color(0xFF1E7F68)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              _buildWelcomeText(),
              const SizedBox(height: 20),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Login",
            style: TextStyle(color: Colors.white, fontSize: 40),
          ),
          SizedBox(height: 10),
          Text(
            "Welcome to WellCheck",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(60),
          topRight: Radius.circular(60),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _userIdController,
                    hintText: 'Username',
                    icon: Icons.person,
                    isPassword: false,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    icon: Icons.lock,
                    isPassword: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator()
                : GestureDetector(
                    onTap: _login,
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 50),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: const Color(0xFF4CAF93),
                      ),
                      child: const Center(
                        child: Text(
                          "Login",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isPassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF4CAF93),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: const Color(0xFF4CAF93)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(10),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: const Color(0xFF4CAF93),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $hintText';
          }
          return null;
        },
      ),
    );
  }
}
