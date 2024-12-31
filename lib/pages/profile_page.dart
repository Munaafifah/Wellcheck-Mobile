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
    super.key,
    required this.userId,
    required this.token,
  });

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

  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController contactController;
  late TextEditingController emergencyContactController;
  late TextEditingController userIdController;
  late TextEditingController oldUserIdController;
  late TextEditingController oldPasswordController;

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final ProfileService _patientService = ProfileService();
  final Profile2Service _userService = Profile2Service();
  final _formKey = GlobalKey<FormState>();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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

  Future<void> fetchAndDisplayProfileImage() async {
    try {
      final imageBase64 =
          await _userService.fetchProfileImage(widget.userId, widget.token);
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

  Future<void> fetchProfiles() async {
    try {
      final patient =
          await _patientService.fetchPatient(widget.userId, widget.token);
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
        userId: isCredentialsValidated
            ? userIdController.text
            : userProfile?.userId,
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
          isEditing = false;
        });
      } else {
        showError('Failed to update some profile information');
      }
    } catch (e) {
      showError('Error updating profile');
    }
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        bool isVerified = await _userService.verifyPassword(
          widget.userId,
          _oldPasswordController.text,
          widget.token,
        );

        if (!isVerified) {
          showError('Current password is incorrect');
          return;
        }

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

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF379B7E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _showCredentialsDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Verify Credentials'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldUserIdController,
                decoration: InputDecoration(
                  labelText: 'Current User ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF379B7E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        suffixIcon: IconButton(
                          icon: Icon(_isOldPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() =>
                              _isOldPasswordVisible = !_isOldPasswordVisible),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Enter current password'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_isNewPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        suffixIcon: IconButton(
                          icon: Icon(_isNewPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() =>
                              _isNewPasswordVisible = !_isNewPasswordVisible),
                        ),
                      ),
                      validator: (value) => (value?.length ?? 0) < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() =>
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible),
                        ),
                      ),
                      validator: (value) => value != _newPasswordController.text
                          ? 'Passwords do not match'
                          : null,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF379B7E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4CAF93),
              Color(0xFF379B7E),
              Color(0xFF1E7F68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await fetchProfiles();
                  await fetchAndDisplayProfileImage();
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      topRight: Radius.circular(60),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildProfileImage(),
                        const SizedBox(height: 24),
                        _buildPersonalInformation(),
                        const SizedBox(height: 16),
                        _buildAccountInformation(),
                        const SizedBox(height: 16),
                        _buildChangePasswordButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  "Profile",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isEditing ? Icons.save : Icons.edit,
                  color: Colors.white,
                ),
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
          const SizedBox(height: 10),
          const Text(
            "Manage your personal information",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF379B7E),
              backgroundImage:
                  _selectedImage != null ? FileImage(_selectedImage!) : null,
              child: _selectedImage == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
          ),
          if (isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF379B7E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 20),
                  onPressed: isUploading ? null : _handleImagePick,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleImagePick() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
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
        _buildTextField(
          label: 'User ID',
          controller: userIdController,
          enabled: isEditing && isCredentialsValidated,
          icon: Icons.person_pin_outlined,
        ),
      ],
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
          color: Color(0xFF379B7E),
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
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFF379B7E)),
            prefixIcon: Icon(icon, color: const Color(0xFF379B7E)),
            border: InputBorder.none,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
          ),
        ),
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _showChangePasswordDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF379B7E),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        icon: const Icon(Icons.lock_outline, color: Colors.white),
        label: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Future<void> validateCredentials() async {
    if (oldUserIdController.text == userProfile?.userId &&
        oldPasswordController.text == userProfile?.password) {
      setState(() => isCredentialsValidated = true);
      showSuccess(
          'Credentials validated. You can now update your account information.');
    } else {
      showError('Invalid credentials. Please try again.');
    }
  }
}
