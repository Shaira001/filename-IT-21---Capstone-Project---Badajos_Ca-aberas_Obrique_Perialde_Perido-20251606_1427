import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Still needed for general user context, though not directly for PIN removal
import 'package:cloud_firestore/cloud_firestore.dart'; // Still needed for general user context, though not directly for PIN removal
import 'package:sk_connect/biometric_db_helper.dart';

class MultifactorPage extends StatefulWidget {
  const MultifactorPage({Key? key}) : super(key: key);

  @override
  State<MultifactorPage> createState() => _MultifactorPageState();
}

class _MultifactorPageState extends State<MultifactorPage> {
  final Color _primaryColor = const Color(0xFF0A2463);
  final Color _accentColor = const Color(0xFF3E92CC);
  final Color _backgroundColor = const Color(0xFFF8F9FA);

  bool _biometricEnabled = false; // current toggle state

  @override
  void initState() {
    super.initState();
    _loadBiometricSetting();
  }

  /// Load toggle state from SQLite (exactly as before)
  Future<void> _loadBiometricSetting() async {
    final enabled = await BiometricDBHelper.isBiometricEnabled();
    setState(() {
      _biometricEnabled = enabled;
    });
  }

  /// Called when user toggles the switch. Writes to SQLite.
  Future<void> _onBiometricToggle(bool newValue) async {
    await BiometricDBHelper.setBiometricEnabled(newValue);
    setState(() {
      _biometricEnabled = newValue;
    });
  }

  // The _showChangePinDialog method has been removed.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Multifactor'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --------------- Biometric Toggle ---------------
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Icon(
                  _biometricEnabled ? Icons.fingerprint : Icons.fingerprint_outlined,
                  color: _primaryColor,
                ),
                title: const Text('Enable Biometric Login'),
                trailing: Switch(
                  value: _biometricEnabled,
                  activeColor: _accentColor, // thumb when ON
                  inactiveThumbColor: Colors.grey.shade700,
                  inactiveTrackColor: Colors.grey.shade400.withOpacity(0.5),
                  onChanged: (value) => _onBiometricToggle(value),
                ),
              ),
            ),
            // The SizedBox and the "Change mPin" Card have been removed.
          ],
        ),
      ),
    );
  }
}