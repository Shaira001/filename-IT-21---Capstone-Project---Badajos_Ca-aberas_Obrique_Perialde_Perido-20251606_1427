import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'biometric_db_helper.dart';

enum SupportState {
  unknown,
  supported,
  unSupported,
}

class VerifyPinScreen extends StatefulWidget {
  final String storedPin;
  const VerifyPinScreen({Key? key, required this.storedPin}) : super(key: key);

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isVerifying = false;

  final LocalAuthentication _auth = LocalAuthentication();
  SupportState _supportState = SupportState.unknown;
  List<BiometricType>? _availableBiometrics;
  bool _biometricDisabled = false;

  @override
  void initState() {
    super.initState();
    _initChecks();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _initChecks() async {
    final dbFlag = await BiometricDBHelper.isBiometricEnabled();
    if (!dbFlag) {
      setState(() {
        _biometricDisabled = true;
        _supportState = SupportState.unSupported;
      });
      return;
    }
    

    bool isSupported = false;
    try {
      isSupported = await _auth.isDeviceSupported();
    } on PlatformException {
      isSupported = false;
    }
    if (!mounted) return;

    if (!isSupported) {
      await BiometricDBHelper.setBiometricEnabled(false);
      setState(() {
        _biometricDisabled = true;
        _supportState = SupportState.unSupported;
      });
      return;
    }

    List<BiometricType> biometrics = <BiometricType>[];
    try {
      biometrics = await _auth.getAvailableBiometrics();
    } on PlatformException {
      biometrics = <BiometricType>[];
    }
    if (!mounted) return;

    if (biometrics.isEmpty) {
      await BiometricDBHelper.setBiometricEnabled(false);
      setState(() {
        _biometricDisabled = true;
        _supportState = SupportState.unSupported;
      });
      return;
    }

    setState(() {
      _availableBiometrics = biometrics;
      _supportState = SupportState.supported;
      _biometricDisabled = false;
    });
  }

  Future<void> _verifyPinManually() async {
    final enteredPin = _pinController.text.trim();
    if (enteredPin.length != 4) {
      _showSnackBar('PIN must be exactly 4 digits.');
      return;
    }

    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    if (enteredPin == widget.storedPin) {
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Incorrect PIN. Logging out.');
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pop(context, false);
    }

    setState(() => _isVerifying = false);
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric error: $e');
    }
    if (!mounted) return;

    if (authenticated) {
      Navigator.pop(context, true);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canUseBiometric = !_biometricDisabled &&
        _supportState == SupportState.supported &&
        (_availableBiometrics?.isNotEmpty ?? false);

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB3E5FC), Color(0xFFD1C4E9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Enter Your PIN',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'For extra security, please confirm your identity.',
                                style: TextStyle(color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _pinController,
                                maxLength: 4,
                                obscureText: true,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(letterSpacing: 12, fontSize: 24),
                                decoration: InputDecoration(
                                  hintText: '',
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade200,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isVerifying ? null : _verifyPinManually,
                                  child: _isVerifying
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Verify PIN'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (canUseBiometric) ...[
                                Text('OR', style: TextStyle(color: Colors.grey.shade600)),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _authenticateWithBiometrics,
                                  icon: Icon(
                                    _availableBiometrics!.contains(BiometricType.face)
                                        ? Icons.face
                                        : Icons.fingerprint,
                                    color: Colors.purple,
                                  ),
                                  label: const Text('Use Biometrics'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.purple,
                                    side: const BorderSide(color: Colors.purple),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Text(
                                _supportState == SupportState.unknown
                                    ? 'Checking biometric support...'
                                    : _supportState == SupportState.unSupported
                                        ? 'Biometrics not supported'
                                        : '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
