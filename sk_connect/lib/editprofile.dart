import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sk_connect/auth_helper.dart'; // Assuming this provides curClient
import 'package:sk_connect/client_class.dart';
import 'package:sk_connect/database_helper.dart';
import 'package:sk_connect/utils.dart';

class EditProfilePage extends StatefulWidget {
  final Client client;

  const EditProfilePage({super.key, required this.client});

  @override
  State<EditProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<EditProfilePage> {
  String? _imageBase64;
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _genderController;
  late TextEditingController _birthdayController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current client values
    _firstNameController =
        TextEditingController(text: widget.client.firstname);
    _lastNameController =
        TextEditingController(text: widget.client.lastname);
    _emailController = TextEditingController(text: widget.client.email);
    _genderController = TextEditingController(text: widget.client.gender);
    _birthdayController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(widget.client.birthday),
    );
    _addressController =
        TextEditingController(text: widget.client.address);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _genderController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  void _saveProfile() {
    // Only validate the form fields that are editable.
    // The birthday field is now read-only, so its format isn't user-changeable here.
    if (!_formKey.currentState!.validate()) return;

    // No need to re-parse birthday as it's read-only.
    // The existing widget.client.birthday is used.

    setState(() {
      // Update profile picture if changed
      if (_imageBase64 != null) {
        widget.client.profilePicture = _imageBase64!;
      }
      // Update other fields
      widget.client.firstname = _firstNameController.text.trim();
      widget.client.lastname = _lastNameController.text.trim();
      widget.client.gender = _genderController.text.trim();
      // birthday is no longer updated from the text field directly
      widget.client.address = _addressController.text.trim();

      // Persist changes
      updateClient(widget.client);
      if (curClient.uid == widget.client.uid) {
        curClient = widget.client;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _changePassword() async {
    final _currentPwController = TextEditingController();
    final _newPwController = TextEditingController();
    final _confirmPwController = TextEditingController();
    final _pwFormKey = GlobalKey<FormState>();
    bool _isProcessing = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: Form(
              key: _pwFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current password
                  TextFormField(
                    controller: _currentPwController,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (val) =>
                        (val == null || val.trim().isEmpty)
                            ? 'Enter current password'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  // New password
                  TextFormField(
                    controller: _newPwController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_open),
                    ),
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Enter new password';
                      }
                      if (val.trim().length < 6) {
                        return 'At least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Confirm new password
                  TextFormField(
                    controller: _confirmPwController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock_open),
                    ),
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Confirm new password';
                      }
                      if (val.trim() != _newPwController.text.trim()) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  if (_isProcessing) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () async {
                        if (!_pwFormKey.currentState!.validate()) return;

                        setStateDialog(() => _isProcessing = true);

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            throw Exception('No authenticated user.');
                          }

                          final cred = EmailAuthProvider.credential(
                            email: user.email!,
                            password: _currentPwController.text.trim(),
                          );

                          // Reauthenticate
                          await user.reauthenticateWithCredential(cred);

                          // Update password
                          await user.updatePassword(_newPwController.text.trim());

                          setStateDialog(() => _isProcessing = false);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password changed successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          setStateDialog(() => _isProcessing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed: ${e.toString()}'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                child: const Text('SAVE'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0A2463);
    const Color secondaryColor = Color(0xFF3E92CC);
    const Color backgroundColor = Color(0xFFF8F9FA);

    return Theme(
      data: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: primaryColor,
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Profile Picture
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (curClient.uid == widget.client.uid) {
                              _pickImage();
                            }
                          },
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _imageBase64 != null
                                ? MemoryImage(base64Decode(_imageBase64!))
                                : (widget.client.profilePicture != null &&
                                        widget.client.profilePicture!
                                            .isNotEmpty)
                                    ? MemoryImage(base64Decode(
                                        widget.client.profilePicture!))
                                    : null,
                            child: (_imageBase64 == null &&
                                    (widget.client.profilePicture == null ||
                                        widget.client.profilePicture!.isEmpty))
                                ? Icon(Icons.person,
                                    size: 60, color: Colors.grey.shade400)
                                : null,
                          ),
                        ),
                      ),
                      if (curClient.uid == widget.client.uid)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 20, color: Colors.white),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Form fields
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // First Name
                      TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty)
                                ? 'First name is required'
                                : null,
                      ),
                      const SizedBox(height: 16),

                      // Last Name
                      TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty)
                                ? 'Last name is required'
                                : null,
                      ),
                      const SizedBox(height: 16),

                      // Email (read-only)
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gender
                      TextFormField(
                        controller: _genderController,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: const Icon(Icons.people_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty)
                                ? 'Gender is required'
                                : null,
                      ),
                      const SizedBox(height: 16),

                      // Birthday (YYYY-MM-DD) - NOW READ-ONLY
                      TextFormField(
                        controller: _birthdayController,
                        readOnly: true, // Make birthday field read-only
                        decoration: InputDecoration(
                          labelText: 'Birthday (YYYY-MM-DD)',
                          prefixIcon: const Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true, // Add filled background for read-only
                          fillColor: Colors.grey.shade200, // Light grey background
                        ),
                        // Remove validator for user input, as it's read-only
                        // The initial value should already be in the correct format
                      ),
                      const SizedBox(height: 16),

                      // Address (multiline)
                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          prefixIcon: const Icon(Icons.home_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty)
                                ? 'Address is required'
                                : null,
                      ),
                      const SizedBox(height: 30),

                      // Save Button
                      if (curClient.uid == widget.client.uid)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 74, 185, 46),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _saveProfile,
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Change Password Button
                      if (curClient.uid == widget.client.uid)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.vpn_key),
                            label: const Text('Change Password'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryColor,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _changePassword,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
