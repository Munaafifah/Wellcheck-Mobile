import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../models/profile_model.dart';
import '../models/profile2_model.dart';
import '../services/profile_service.dart';
import '../services/profile2_service.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String token;

  const ProfilePage({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late PatientProfile? patientProfile;
  late UserProfile? userProfile;
  bool isLoading = true;
  bool isEditing = false;
  bool isPasswordVisible = false;
  bool isCredentialsValidated = false;
  bool isUploading = false;

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Text controllers
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController contactController;
  late TextEditingController emergencyContactController;
  late TextEditingController userIdController;
  late TextEditingController passwordController;
  late TextEditingController oldUserIdController;
  late TextEditingController oldPasswordController;

  final ProfileService _patientService = ProfileService();
  final Profile2Service _userService = Profile2Service();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    addressController = TextEditingController();
    contactController = TextEditingController();
    emergencyContactController = TextEditingController();
    userIdController = TextEditingController();
    passwordController = TextEditingController();
    oldUserIdController = TextEditingController();
    oldPasswordController = TextEditingController();
    fetchProfiles();
    fetchAndDisplayProfileImage();
  }

  // New method to fetch and display profile image
  Future<void> fetchAndDisplayProfileImage() async {
    try {
      final imageBase64 = await _userService.fetchProfileImage(widget.userId, widget.token);
      if (imageBase64 != null) {
        setState(() {
          _selectedImage = decodeBase64ToFile(imageBase64);
        });
      }
    } catch (e) {
      print("Error fetching profile image: $e");
      // Silently fail as this is not critical functionality
    }
  }

  // New method to decode Base64 to File
  File decodeBase64ToFile(String base64String) {
    try {
      final bytes = base64Decode(base64String.split(',').last);
      final file = File('${Directory.systemTemp.path}/profile_image.png');
      file.writeAsBytesSync(bytes);
      return file;
    } catch (e) {
      print("Error decoding base64 to file: $e");
      rethrow;
    }
  }

  Future<String> compressAndConvertToBase64(File file) async {
    try {
      final rawImage = img.decodeImage(await file.readAsBytes());
      
      if (rawImage == null) {
        throw Exception("Failed to decode image.");
      }

      final resizedImage = img.copyResize(rawImage, width: 300);
      final compressedImage = img.encodeJpg(resizedImage, quality: 80);
      String base64Image = base64Encode(compressedImage);
      print("Compressed Base64 Length: ${base64Image.length}");
      return base64Image;
    } catch (e) {
      throw Exception("Error during compression or encoding: $e");
    }
  }

  Future<void> fetchProfiles() async {
    try {
      final patient = await _patientService.fetchPatient(widget.userId, widget.token);
      final user = await _userService.fetchUser(widget.userId, widget.token);

      setState(() {
        patientProfile = patient;
        userProfile = user;
        isLoading = false;

        if (patient != null) {
          nameController.text = patient.name;
          addressController.text = patient.address;
          contactController.text = patient.contact;
          emergencyContactController.text = patient.emergencyContact;
        }
        if (user != null) {
          userIdController.text = user.userId ?? '';
          passwordController.text = user.password ?? '';
        }
      });
    } catch (e) {
      print("Error fetching profiles: $e");
      setState(() {
        isLoading = false;
      });
      showError('Failed to load profile data');
    }
  }

  Future<void> validateCredentials() async {
    if (oldUserIdController.text == userProfile?.userId &&
        oldPasswordController.text == userProfile?.password) {
      setState(() {
        isCredentialsValidated = true;
      });
      showSuccess('Credentials validated. You can now update your userId and password.');
    } else {
      showError('Invalid credentials. Please try again.');
    }
  }

  Future<void> updateProfiles() async {
    try {
      final updatedPatient = PatientProfile(
        name: nameController.text,
        address: addressController.text,
        contact: contactController.text,
        emergencyContact: emergencyContactController.text,
      );

      final updatedUser = UserProfile(
        userId: isCredentialsValidated ? userIdController.text : userProfile?.userId,
        password: isCredentialsValidated ? passwordController.text : userProfile?.password,
      );

      final patientSuccess = await _patientService.updatePatient(
        widget.userId,
        updatedPatient,
        widget.token,
      );

      final userSuccess = await _userService.updateUser(
        widget.userId,
        updatedUser,
        widget.token,
      );

      if (patientSuccess && userSuccess) {
        showSuccess('Profile updated successfully');
        setState(() {
          isCredentialsValidated = false;
          oldUserIdController.clear();
          oldPasswordController.clear();
        });
      }
    } catch (e) {
      print("Error updating profiles: $e");
      showError('Error updating profile');
    }
  }

  Future<void> pickImageAndUpload() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        isUploading = true;
      });

      try {
        final base64Image = await compressAndConvertToBase64(_selectedImage!);
        bool uploadSuccess = await _userService.uploadProfileImage(
          widget.userId, base64Image, widget.token);

        if (uploadSuccess) {
          showSuccess('Profile image uploaded successfully');
        } else {
          showError('Failed to upload profile image');
        }
      } catch (e) {
        print("Error uploading image: $e");
        showError('Error uploading image');
      } finally {
        setState(() {
          isUploading = false;
        });
      }
    } else {
      showError('No image selected');
    }
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _showCredentialsDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verify Credentials'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldUserIdController,
                  decoration: const InputDecoration(
                    labelText: 'Current User ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                validateCredentials();
                Navigator.pop(context);
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                updateProfiles();
              }
              setState(() {
                isEditing = !isEditing;
                if (!isEditing) {
                  isCredentialsValidated = false;
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchProfiles();
          await fetchAndDisplayProfileImage();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          _selectedImage != null ? FileImage(_selectedImage!) : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                    if (isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.blue),
                          onPressed: isUploading ? null : pickImageAndUpload,
                        ),
                      ),
                  ],
                ),
              ),
              if (isUploading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 24),
              _buildSectionTitle('Personal Information'),
              _buildProfileField(
                label: 'Name',
                controller: nameController,
                enabled: isEditing,
                icon: Icons.person_outline,
              ),
              _buildProfileField(
                label: 'Address',
                controller: addressController,
                enabled: isEditing,
                icon: Icons.location_on_outlined,
              ),
              _buildProfileField(
                label: 'Contact',
                controller: contactController,
                enabled: isEditing,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              _buildProfileField(
                label: 'Emergency Contact',
                controller: emergencyContactController,
                enabled: isEditing,
                icon: Icons.emergency_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Account Information'),
              if (isEditing && !isCredentialsValidated)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: _showCredentialsDialog,
                    child: const Text('Verify to Edit Account Information'),
                  ),
                ),
              _buildProfileField(
                label: 'User ID',
                controller: userIdController,
                enabled: isEditing && isCredentialsValidated,
                icon: Icons.person_pin_outlined,
              ),
              _buildPasswordField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: passwordController,
        enabled: isEditing && isCredentialsValidated,
        obscureText: !isPasswordVisible,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.blue,
            ),
            onPressed: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: isEditing && isCredentialsValidated ? Colors.white : Colors.grey[100],
        ),
      ),
    );
  }
}