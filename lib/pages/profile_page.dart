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
  bool isChangingPassword = false;

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Text controllers for profile
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController contactController;
  late TextEditingController emergencyContactController;
  late TextEditingController userIdController;
  late TextEditingController oldUserIdController;
  late TextEditingController oldPasswordController;

  // Text controllers for password change
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final ProfileService _patientService = ProfileService();
  final Profile2Service _userService = Profile2Service();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    addressController = TextEditingController();
    contactController = TextEditingController();
    emergencyContactController = TextEditingController();
    userIdController = TextEditingController();
    oldUserIdController = TextEditingController();
    oldPasswordController = TextEditingController();
    fetchProfiles();
    fetchAndDisplayProfileImage();
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    contactController.dispose();
    emergencyContactController.dispose();
    userIdController.dispose();
    oldUserIdController.dispose();
    oldPasswordController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Image handling methods
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
    }
  }

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
      if (rawImage == null) throw Exception("Failed to decode image.");
      
      final resizedImage = img.copyResize(rawImage, width: 300);
      final compressedImage = img.encodeJpg(resizedImage, quality: 80);
      return base64Encode(compressedImage);
    } catch (e) {
      throw Exception("Error during compression or encoding: $e");
    }
  }

  // Profile management methods
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
        }
      });
    } catch (e) {
      setState(() => isLoading = false);
      showError('Failed to load profile data');
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
        password: userProfile?.password,
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
      } else {
        showError('Failed to update some profile information');
      }
    } catch (e) {
      showError('Error updating profile');
    }
  }

  // Password change methods
  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        // First verify current password
        bool isVerified = await _userService.verifyPassword(
          widget.userId,
          _oldPasswordController.text,
          widget.token,
        );

        if (!isVerified) {
          showError('Current password is incorrect');
          return;
        }

        // If verified, proceed with password update
        bool isSuccess = await _userService.updatePassword(
          widget.userId,
          _newPasswordController.text,
          widget.token,
        );

        if (isSuccess) {
          showSuccess('Password updated successfully');
          setState(() => isChangingPassword = false);
          _clearPasswordFields();
        } else {
          showError('Failed to update password');
        }
      } catch (e) {
        showError('Error updating password');
      }
    }
  }

  void _clearPasswordFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  // UI Feedback methods
  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Dialogs
  Future<void> _showCredentialsDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verify Credentials'),
          content: Column(
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

bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _showChangePasswordDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: !_isOldPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_isOldPasswordVisible ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _isOldPasswordVisible = !_isOldPasswordVisible),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Enter current password' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_isNewPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_isNewPasswordVisible ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                        ),
                      ),
                      validator: (value) => (value?.length ?? 0) < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        ),
                      ),
                      validator: (value) => value != _newPasswordController.text ? 'Passwords do not match' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _clearPasswordFields();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      _changePassword();
                    }
                  },
                  child: const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
              _buildProfileImage(),
              const SizedBox(height: 24),
              _buildPersonalInformation(),
              const SizedBox(height: 16),
              _buildAccountInformation(),
              const SizedBox(height: 16),
              _buildChangePasswordButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
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
                onPressed: isUploading ? null : () async {
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
                      showError('Error uploading image');
                    } finally {
                      setState(() => isUploading = false);
                    }
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Information'),
        _buildTextField(
          label: 'Name',
          controller: nameController,
          enabled: isEditing,
          icon: Icons.person_outline,
        ),
        _buildTextField(
          label: 'Address',
          controller: addressController,
          enabled: isEditing,
          icon: Icons.location_on_outlined,
        ),
        _buildTextField(
          label: 'Contact',
          controller: contactController,
          enabled: isEditing,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        _buildTextField(
          label: 'Emergency Contact',
          controller: emergencyContactController,
          enabled: isEditing,
          icon: Icons.emergency_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildAccountInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Account Information'),
        if (isEditing && !isCredentialsValidated)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: _showCredentialsDialog,
              child: const Text('Verify to Edit Account Information'),
            ),
          ),
        _buildTextField(
          label: 'User ID',
          controller: userIdController,
          enabled: isEditing && isCredentialsValidated,
          icon: Icons.person_pin_outlined,
        ),
      ],
    );
  }

  Widget _buildChangePasswordButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _showChangePasswordDialog(),
        icon: const Icon(Icons.lock_outline),
        label: const Text('Change Password'),
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

  Widget _buildTextField({
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

  Future<void> validateCredentials() async {
    if (oldUserIdController.text == userProfile?.userId &&
        oldPasswordController.text == userProfile?.password) {
      setState(() => isCredentialsValidated = true);
      showSuccess('Credentials validated. You can now update your account information.');
    } else {
      showError('Invalid credentials. Please try again.');
    }
  }
}