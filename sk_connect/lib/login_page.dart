import 'dart:async'; // Import for StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sk_connect/auth_helper.dart';
import 'package:sk_connect/client_class.dart';
import 'package:sk_connect/database_helper.dart';
import 'package:sk_connect/homepage.dart';
import 'package:sk_connect/resetpassword_page.dart';
import 'package:sk_connect/signup_page.dart';
import 'package:sk_connect/utils.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'biometric_db_helper.dart'; // Import the biometric helper

// Enum to define biometric support states on the device
enum SupportState {
  unknown,
  supported,
  unSupported,
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthHelper _authHelper = AuthHelper();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showPasswordInput = false;

  // Biometric authentication variables
  final LocalAuthentication _auth = LocalAuthentication();
  SupportState _deviceSupportState = SupportState.unknown;
  List<BiometricType>? _availableBiometrics;
  bool _isBiometricOptionAvailableOnDevice = false;
  bool _isGlobalBiometricEnabled = false;
  bool _isAuthenticatingBiometrics = false;
  bool _autoLoginAttempted = false;
  User? _currentFirebaseUser;
  StreamSubscription<User?>? _authStateSubscription;

  // Theme colors
  final Color _primaryColor = const Color(0xFF0A2463);
  final Color _accentColor = const Color(0xFF3E92CC);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _textColor = const Color(0xFF212529);
  final Color _errorColor = const Color(0xFFD62839);

  @override
  void initState() {
    super.initState();
    _initBiometricSupportStatus();
    _authStateSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentFirebaseUser = user;
        _prefillEmail();
        _showPasswordInput = false;
      });
      if (user != null && !_autoLoginAttempted) {
        _autoLoginCheck();
      } else if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isAuthenticatingBiometrics = false;
            _autoLoginAttempted = false;
          });
        }
      }
    });
  }

  void _prefillEmail() {
    if (_currentFirebaseUser != null && _currentFirebaseUser!.email != null) {
      _emailController.text = _currentFirebaseUser!.email!;
    } else {
      _emailController.clear();
    }
  }

  Future<void> _initBiometricSupportStatus() async {
    bool isSupported = false;
    try {
      isSupported = await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('Error checking device support for biometrics: $e');
      isSupported = false;
    }
    if (!mounted) return;

    if (!isSupported) {
      setState(() {
        _deviceSupportState = SupportState.unSupported;
        _isBiometricOptionAvailableOnDevice = false;
      });
      return;
    }

    List<BiometricType> biometrics = <BiometricType>[];
    try {
      biometrics = await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error getting available biometrics: $e');
      biometrics = <BiometricType>[];
    }
    if (!mounted) return;

    setState(() {
      _availableBiometrics = biometrics;
      _deviceSupportState =
          biometrics.isNotEmpty ? SupportState.supported : SupportState.unSupported;
      _isBiometricOptionAvailableOnDevice = biometrics.isNotEmpty;
    });
  }

  Future<void> _autoLoginCheck() async {
    if (_currentFirebaseUser == null || _autoLoginAttempted) return;
    _autoLoginAttempted = true;
    setState(() => _isLoading = true);
    try {
      await _currentFirebaseUser!.reload();
      if (!_currentFirebaseUser!.emailVerified) {
        _showMessage("Please verify your email before logging in.",
            isError: true);
        await FirebaseAuth.instance.signOut();
        return;
      }

      bool globalBiometricEnabled = await BiometricDBHelper.isBiometricEnabled();
      setState(() {
        _isGlobalBiometricEnabled = globalBiometricEnabled;
      });

      Client? client = await getClient(_currentFirebaseUser!.uid);
      if (client != null && mounted) {
        curClient = client;
        if (_isGlobalBiometricEnabled && _isBiometricOptionAvailableOnDevice) {
          await _authenticateWithBiometrics(navigateToHome: true);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomePage()),
          );
        }
      } else if (mounted) {
        _showMessage("User data not found. Please contact support.",
            isError: true);
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      debugPrint("Error during auto-login: $e");
      _showMessage(
          "Auto-login failed: An error occurred. Please try again or sign in manually.",
          isError: true);
      await FirebaseAuth.instance.signOut();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        _showMessage("Please enter both email and password", isError: true);
        return;
      }

      User? result = await _authHelper.login(email, password);
      if (result != null) {
        await result.reload();
        if (!result.emailVerified) {
          _showMessage("Please verify your email before logging in.",
              isError: true);
          await FirebaseAuth.instance.signOut();
          return;
        }

        final client = await getClient(result.uid);
        if (client != null && mounted) {
          curClient = client;
          _showMessage("Welcome back, ${client.firstname}!", isError: false);

          bool globalBiometricEnabled =
              await BiometricDBHelper.isBiometricEnabled();
          setState(() {
            _isGlobalBiometricEnabled = globalBiometricEnabled;
          });

          if (_isBiometricOptionAvailableOnDevice && !_isGlobalBiometricEnabled) {
            await _showBiometricOptInDialog();
          } else {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
              );
            }
          }
        } else if (mounted) {
          _showMessage("User data not found. Please contact support.",
              isError: true);
        }
      } else if (mounted) {
        _showMessage("Invalid email or password", isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showMessage("Login failed: ${_friendlyError(e)}", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showBiometricOptInDialog() async {
    final bool? enableBiometric = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Enable Biometric Login?'),
          content: const Text(
              'Do you want to enable Face ID/Fingerprint for faster future logins?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('No Thanks'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );

    if (enableBiometric == true) {
      await BiometricDBHelper.setBiometricEnabled(true);
      if (mounted) {
        setState(() {
          _isGlobalBiometricEnabled = true;
        });
      }
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    }
  }

  String _friendlyError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return "No account found with this email";
        case 'wrong-password':
          return "Incorrect password";
        case 'too-many-requests':
          return "Too many attempts. Try again later";
        case 'network-request-failed':
          return "Network error. Check your connection";
        case 'user-disabled':
          return "This account has been disabled.";
        default:
          return "Login failed. Please try again";
      }
    }
    return "An error occurred. Please try again";
  }

  Future<void> _authenticateWithBiometrics({bool navigateToHome = false}) async {
    if (!_isBiometricOptionAvailableOnDevice || !_isGlobalBiometricEnabled) {
      _showMessage("Biometric authentication is not set up or enabled for this app.",
          isError: true);
      if (navigateToHome && mounted && _currentFirebaseUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
      return;
    }

    setState(() => _isAuthenticatingBiometrics = true);
    bool authenticated = false;
    try {
      authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to sign in securely',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication failed due to platform error: $e');
      if (e.code == 'notAvailable' || e.code == 'notEnrolled' || e.code == 'PasscodeNotSet') {
        String errorMessage = "";
        if (e.code == 'notAvailable') {
          errorMessage = "Biometrics not set up on this device.";
        } else if (e.code == 'notEnrolled') {
          errorMessage =
              "No biometrics enrolled. Please set up Face ID/Fingerprint in device settings.";
        } else if (e.code == 'PasscodeNotSet') {
          errorMessage =
              "Device passcode not set. Please set up a passcode to use biometrics.";
        }
        _showMessage(errorMessage, isError: true);
        await BiometricDBHelper.setBiometricEnabled(false);
        if (mounted) {
          setState(() {
            _isGlobalBiometricEnabled = false;
          });
        }
      } else {
        _showMessage("Biometric authentication failed: ${e.message}", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isAuthenticatingBiometrics = false);
    }

    if (!mounted) return;

    if (authenticated) {
      _showMessage("Biometric authentication successful!", isError: false);
      if (navigateToHome) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    } else {
      _showMessage(
          "Biometric authentication cancelled or failed. Please use email/password.",
          isError: true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _showMessage(String message, {required bool isError}) {
    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = _currentFirebaseUser != null;
    final showBiometricOption =
        isLoggedIn && _isBiometricOptionAvailableOnDevice && _isGlobalBiometricEnabled;

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
            elevation: 0,
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
          bodySmall: GoogleFonts.poppins(
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
                child: Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_showPasswordInput)
                          Align(
                            alignment: Alignment.topLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showPasswordInput = false;
                                  _passwordController.clear();
                                });
                              },
                              icon: Icon(Icons.arrow_back, color: _primaryColor),
                              label: Text(
                                "Back",
                                style: TextStyle(color: _primaryColor),
                              ),
                            ),
                          ),
                        const SizedBox(height: 30),
                        Image.asset(
                          'assets/logo.png',
                          height: 180,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          isLoggedIn ? "Welcome back!" : "Sign in to continue",
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 30),
                        if (isLoggedIn && _currentFirebaseUser!.email != null) ...[
                          Text(
                            _currentFirebaseUser!.email!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                        ],
                        if (!isLoggedIn || _showPasswordInput) ...[
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon:
                                  Icon(Icons.email_outlined, color: _primaryColor),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            readOnly: isLoggedIn,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon:
                                  Icon(Icons.lock_outline, color: _primaryColor),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!isLoggedIn)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: (_isLoading || _isAuthenticatingBiometrics)
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ResetpasswordPage(),
                                          ),
                                        );
                                      },
                                child: Text(
                                  "Forgot password?",
                                  style: TextStyle(color: _accentColor),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  (_isLoading || _isAuthenticatingBiometrics)
                                      ? null
                                      : _login,
                              child: _isLoading && !_isAuthenticatingBiometrics
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text("Sign in"),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                        if (isLoggedIn && !_showPasswordInput) ...[
                          if (showBiometricOption) ...[
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed:
                                    (_isLoading || _isAuthenticatingBiometrics)
                                        ? null
                                        : () => _authenticateWithBiometrics(
                                            navigateToHome: true),
                                icon: _isAuthenticatingBiometrics
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.blue,
                                        ),
                                      )
                                    : Icon(
                                        _availableBiometrics?.contains(
                                                    BiometricType.face) ??
                                                false
                                            ? Icons.face
                                            : Icons.fingerprint,
                                        color: _accentColor,
                                      ),
                                label: Text(
                                  _isAuthenticatingBiometrics
                                      ? 'Authenticating...'
                                      : 'Sign in with Biometrics',
                                  style: TextStyle(color: _accentColor),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: _accentColor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed:
                                  (_isLoading || _isAuthenticatingBiometrics)
                                      ? null
                                      : () {
                                          setState(() {
                                            _showPasswordInput = true;
                                          });
                                        },
                              child: const Text("Continue with Password"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: BorderSide(color: _primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],

                        // <-- UPDATED SIGN-OUT BUTTON -->
                        if (isLoggedIn)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed:
                                  (_isLoading || _isAuthenticatingBiometrics)
                                      ? null
                                      : () async {
                                          // 1. Disable biometrics in DB
                                          await BiometricDBHelper.setBiometricEnabled(false);
                                          // 2. Update local state
                                          if (mounted) {
                                            setState(() {
                                              _isGlobalBiometricEnabled = false;
                                            });
                                          }
                                          // 3. Sign out
                                          await FirebaseAuth.instance.signOut();
                                          // 4. Notify user
                                          _showMessage(
                                            "You have been signed out and biometric login disabled.",
                                            isError: false,
                                          );
                                        },
                              child: const Text("Sign out"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _errorColor,
                                side: BorderSide(color: _errorColor),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        if (!isLoggedIn)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                              TextButton(
                                onPressed:
                                    (_isLoading || _isAuthenticatingBiometrics)
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => SignupPage(),
                                              ),
                                            );
                                          },
                                child: Text(
                                  "Sign up",
                                  style: TextStyle(color: _accentColor),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading || _isAuthenticatingBiometrics)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
