// lib/signup_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sk_connect/auth_helper.dart';
import 'package:sk_connect/client_class.dart';
import 'package:sk_connect/database_helper.dart'; // ← contains top‐level addClient(...)
import 'package:sk_connect/email_verification_page.dart';
import 'package:sk_connect/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // ← Para kunin ang purok options

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthHelper _authHelper = AuthHelper();
  // We no longer have a DatabaseHelper class—use top‐level addClient(...) instead.

  bool _isResident = false;
  bool _isLoading = false;
  DateTime? _selectedBirthday;
  String? _selectedGender;

  // Dropdown para sa Purok/Sitio
  List<String> _purokOptions = [];
  String? _selectedPurok;

  // Theme colors
  final Color _primaryColor = const Color(0xFF0A2463);
  final Color _accentColor = const Color(0xFF3E92CC);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _textColor = const Color(0xFF212529);
  final Color _errorColor = const Color(0xFFD62839);

  @override
  void initState() {
    super.initState();
    _fetchPurokOptions();
  }

  /// Kukunin ang listahan ng purok/sitio mula sa Realtime Database
  Future<void> _fetchPurokOptions() async {
    try {
      final DatabaseReference dbRef =
          FirebaseDatabase.instance.ref().child('puroks');
      final DataSnapshot snapshot = await dbRef.get();

      if (snapshot.exists) {
        final data = snapshot.value;
        List<String> tempList = [];

        if (data is Map) {
          // Halimbawa: { "purok1": "Purok 1", "purok2": "Purok 2", ... }
          data.forEach((key, value) {
            if (value is String) tempList.add(value);
          });
        } else if (data is List) {
          // Halimbawa: ["Purok 1", "Purok 2", ...]
          for (var item in data) {
            if (item is String) tempList.add(item);
          }
        }

        setState(() {
          _purokOptions = tempList;
        });
      }
    } catch (e) {
      debugPrint('Error fetching purok options: $e');
    }
  }

  Future<void> _signup() async {
    setState(() => _isLoading = true);

    try {
      final String email = _emailController.text.trim();
      final String fname = _fnameController.text.trim();
      final String lname = _lnameController.text.trim();
      final String password = _passwordController.text.trim();
      final String confirmPassword = _confirmPasswordController.text.trim();
      final String? purok = _selectedPurok;

      // Validasyon ng form
      if (!_validateForm(
          fname, lname, email, password, confirmPassword, purok)) {
        setState(() => _isLoading = false);
        return;
      }


      // Mag-sign up sa Firebase Auth
      User? user = await _authHelper.signUp(email, password);
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        // Bumuo ng bagong Client object kasama ang isResident
        Client client = Client(
          uid: user.uid,
          email: email,
          firstname: fname,
          lastname: lname,
          key: '',
          gender: _selectedGender!,
          birthday: _selectedBirthday!,
          profilePicture: '',
          address: '$purok, Poblacion, Taytay Palawan',
          isResident: _isResident, // ← ipasa dito ang checkbox value
        );

        // I-save sa Firestore gamit ang top‐level function:
        await addClient(client);

        _showMessage('Verification email sent to $email', isError: false);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const EmailVerificationPage(),
            ),
          );
        }
      }
    } catch (e) {
      _showMessage(_getUserFriendlyError(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateForm(
      String fname,
      String lname,
      String email,
      String password,
      String confirmPassword,
      String? purok) {
    // Build a list of missing fields
    String missingFields = '';
    if (fname.isEmpty) missingFields += '• First Name\n';
    if (lname.isEmpty) missingFields += '• Last Name\n';
    if (email.isEmpty) missingFields += '• Email\n';
    if (password.isEmpty) missingFields += '• Password\n';
    if (confirmPassword.isEmpty) missingFields += '• Confirm Password\n';
    if (_selectedBirthday == null) missingFields += '• Birthday\n';
    if (_selectedGender == null) missingFields += '• Gender\n';

 

    // If any required field is missing, show error
    if (missingFields.isNotEmpty) {
      _showMessage(
        'Please fill in all required fields:\n\n$missingFields',
        isError: true,
      );
      return false;
    }

    // Age check
    final int age = DateTime.now().year - _selectedBirthday!.year;
    if (age > 30 || age < 15) {
      _showMessage(
        'You must be between 15 and 30 years old to register',
        isError: true,
      );
      return false;
    }

    // Confirm passwords match
    if (password != confirmPassword) {
      _showMessage('Passwords do not match', isError: true);
      return false;
    }

    return true;
  }

  String _getUserFriendlyError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered';
        case 'invalid-email':
          return 'Please enter a valid email address';
        case 'weak-password':
          return 'Password should be at least 6 characters';
        case 'network-request-failed':
          return 'Network error. Check your connection';
        default:
          return 'Registration failed. Please try again';
      }
    }
    return 'An error occurred. Please try again';
  }

  Future<void> _pickBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textColor,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedBirthday = picked);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _errorColor : _accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: _primaryColor,
        colorScheme: ColorScheme.light(
          primary: _primaryColor,
          secondary: _accentColor,
          error: _errorColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryColor,
            side: BorderSide(color: _primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          headlineSmall: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
          bodyLarge: GoogleFonts.poppins(
            color: _textColor,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Create Account",
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Join SK Connect today",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 30),

                      // First Name
                      TextField(
                        controller: _fnameController,
                        decoration: InputDecoration(
                          labelText: "First Name",
                          prefixIcon:
                              Icon(Icons.person_outline, color: _primaryColor),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Last Name
                      TextField(
                        controller: _lnameController,
                        decoration: InputDecoration(
                          labelText: "Last Name",
                          prefixIcon:
                              Icon(Icons.person_outline, color: _primaryColor),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon:
                              Icon(Icons.email_outlined, color: _primaryColor),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Password
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon:
                              Icon(Icons.lock_outline, color: _primaryColor),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Confirm Password
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          prefixIcon:
                              Icon(Icons.lock_outline, color: _primaryColor),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Birthday Picker
                      GestureDetector(
                        onTap: _pickBirthday,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: _primaryColor, size: 20),
                              const SizedBox(width: 16),
                              Text(
                                _selectedBirthday == null
                                    ? "Select Birthday"
                                    : "${_selectedBirthday!.month}/${_selectedBirthday!.day}/${_selectedBirthday!.year}",
                                style: TextStyle(
                                  color: _selectedBirthday == null
                                      ? Colors.grey.shade600
                                      : _textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedBirthday != null)
                        if ((DateTime.now().year - _selectedBirthday!.year) >
                                30 ||
                            (DateTime.now().year - _selectedBirthday!.year) <
                                15)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              "You must be between 15 and 30 years old to register",
                              style:
                                  TextStyle(color: _errorColor, fontSize: 12),
                            ),
                          ),
                      const SizedBox(height: 15),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                              value: 'Female', child: Text('Female')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                        decoration: InputDecoration(
                          labelText: "Gender",
                          prefixIcon:
                              Icon(Icons.people_outline, color: _primaryColor),
                        ),
                        icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                      ),
                      const SizedBox(height: 15),

                      // Resident Checkbox
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            'Resident of Poblacion, Taytay Palawan?',
                            style: TextStyle(color: _textColor),
                          ),
                          value: _isResident,
                          onChanged: (bool? value) =>
                              setState(() => _isResident = value ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: _primaryColor,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Only show Purok dropdown if Resident is checked
                      if (_isResident) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedPurok,
                          items: _purokOptions
                              .map(
                                (purokName) => DropdownMenuItem(
                                  value: purokName,
                                  child: Text(purokName),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedPurok = value),
                          decoration: InputDecoration(
                            labelText: "Purok/Sitio",
                            prefixIcon: Icon(Icons.location_on_outlined,
                                color: _primaryColor),
                          ),
                          icon: Icon(Icons.arrow_drop_down,
                              color: _primaryColor),
                        ),
                        if (_purokOptions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              "Loading purok options...",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        const SizedBox(height: 30),
                      ] else
                        const SizedBox(height: 30),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signup,
                          child: const Text("Sign Up"),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("OR",
                                style: TextStyle(color: Colors.grey.shade600)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LoginPage()),
                                  );
                                },
                          child: const Text("Already have an account? Login"),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
