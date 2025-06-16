import 'dart:convert'; // For jsonEncode, if you want to display raw data
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Make sure you have this package in your pubspec.yaml
import 'package:firebase_messaging/firebase_messaging.dart'; // Crucial for RemoteMessage type

class InboxPage extends StatelessWidget {
  // This field will hold the RemoteMessage that opened the InboxPage
  final RemoteMessage? message;

  // Constructor to accept the RemoteMessage.
  // It's nullable because the InboxPage might sometimes be opened without a notification (e.g., from a bottom navigation bar).
  const InboxPage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    // Extracting notification details safely
    final String notificationTitle = message?.notification?.title ?? 'No Title';
    final String notificationBody = message?.notification?.body ?? 'No Body';
    final Map<String, dynamic>? notificationData = message?.data;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inbox',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white), // Example styling
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white), // Set back button color
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Display content if a notification message was passed
              if (message != null) ...[
                Icon(
                  Icons.notifications_active,
                  size: 80,
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
                const SizedBox(height: 25),
                Text(
                  'Notification Details:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 15),
                Text(
                  'Title: "$notificationTitle"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Text(
                  'Body: "$notificationBody"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 15),
                if (notificationData != null && notificationData.isNotEmpty)
                  Column(
                    children: [
                      Text(
                        'Additional Data:',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      // Display raw data in a more readable format
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          jsonEncode(notificationData),
                          textAlign: TextAlign.left,
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
              ] else ...[
                // Default message if no notification message was passed
                Icon(
                  Icons.inbox,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 25),
                Text(
                  'No new notifications to display.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                const SizedBox(height: 10),
                Text(
                  'Notifications you tap on will appear here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}