import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatePage extends StatefulWidget {
  const UpdatePage({Key? key}) : super(key: key);

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  final String _installedVersion = '1.0.1';
  final DatabaseReference _versionRef = FirebaseDatabase.instance.ref().child('app_version');

  String? _latestVersion;
  String? _updateDetails;
  String? _updateLink;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndCheckVersion();
  }

  Future<void> _initializeFirebaseAndCheckVersion() async {
    try {
      await Firebase.initializeApp();

      final snapshot = await _versionRef.get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _latestVersion = data['latest_version']?.toString() ?? '';
        _updateDetails = data['update_details']?.toString() ?? '';
        _updateLink = data['update_link']?.toString();
      } else {
        _errorMessage = 'Walang version info sa database.';
      }
    } catch (e) {
      _errorMessage = 'Error sa pagkuha ng version info: ${e.toString()}';
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _launchUpdateLink() async {
    if (_updateLink == null || _updateLink!.isEmpty) return;
    final Uri uri = Uri.parse(_updateLink!);

    try {
      if (Platform.isAndroid && uri.host.contains("play.google.com")) {
        // Use Chrome intent for Play Store links
        final chromeIntent = Uri.parse(
          'intent://${uri.host}${uri.path}?${uri.query}#Intent;scheme=${uri.scheme};package=com.android.chrome;end;',
        );

        final success = await launchUrl(
          chromeIntent,
          mode: LaunchMode.externalApplication,
        );

        if (success) return;
      }

      // Launch normally in browser
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot launch URL';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hindi ma-open ang update link: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_loading) {
      content = const CircularProgressIndicator();
    } else if (_errorMessage != null) {
      content = Text(
        _errorMessage!,
        style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 16),
        textAlign: TextAlign.center,
      );
    } else {
      if (_installedVersion == _latestVersion) {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text(
              'Updated na ang app!',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Version: $_installedVersion',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        );
      } else {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.system_update_alt, color: Colors.orangeAccent, size: 60),
            const SizedBox(height: 16),
            Text(
              'May bagong version!',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Installed: $_installedVersion',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              'Latest: $_latestVersion',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _updateDetails ?? 'Walang detalye para sa update.',
                style: GoogleFonts.poppins(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _launchUpdateLink,
              child: Text(
                'I-update Ngayon',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: content,
        ),
      ),
    );
  }
}
