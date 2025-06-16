import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Single toggle for all notifications
  bool _allNotificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(
              'Notification', // Updated title to 'Notification'
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            value: _allNotificationsEnabled,
            onChanged: (val) => setState(() => _allNotificationsEnabled = val),
            secondary: const Icon(Icons.notifications), // General notification icon
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _allNotificationsEnabled
                  ? 'You will receive all types of notifications (Announcements, Inventory Updates, Chat Messages).'
                  : 'You will not receive any notifications. Toggle the switch above to enable them.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
