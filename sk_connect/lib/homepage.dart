import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sk_connect/Feedback_page.dart';
import 'package:sk_connect/announcements_page.dart';
import 'package:sk_connect/board_page.dart';
import 'package:sk_connect/chatlist_page.dart';

import 'package:sk_connect/inventory_page.dart';
import 'package:sk_connect/officials_page.dart';
import 'package:sk_connect/profile_page.dart';
import 'package:sk_connect/utils.dart';
import 'package:sk_connect/notificatin.dart';

import 'multifactor.dart';
import 'update.dart';
import 'editprofile.dart';
import 'package:sk_connect/auth_helper.dart';
import 'package:sk_connect/login_page.dart';
import 'biometric_db_helper.dart'; // Import the biometric_db_helper

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color _primaryColor = const Color(0xFF0A2463);
  final Color _accentColor = const Color(0xFF3E92CC);
  final Color _backgroundColor = const Color(0xFFF8F9FA);

  int _selectedIndex = 0;

  // Removed MPIN related controllers and flags
  // final TextEditingController _newPinController = TextEditingController();
  // final TextEditingController _confirmPinController = TextEditingController();
  // bool _isSettingPin = false;

  final String _installedVersion = '1.0.1';
  final DatabaseReference _versionRef = FirebaseDatabase.instance.ref().child('app_version');
  bool _versionChecked = false;

  @override
  void initState() {
    super.initState();
    // Removed MPIN check
    // _checkMpinForCurrentUser();
    _checkAppVersion();
  }

  // Removed MPIN check function
  // Future<void> _checkMpinForCurrentUser() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;

  //   final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  //   final snapshot = await docRef.get();

  //   final hasMpin = (snapshot.exists &&
  //       snapshot.data() != null &&
  //       snapshot.data()!.containsKey('mPin'));

  //   if (!hasMpin) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) => _showSetupPinDialog());
  //   }
  // }

  Future<void> _checkAppVersion() async {
    if (_versionChecked) return;
    _versionChecked = true;

    try {
      await Firebase.initializeApp();
    } catch (_) {}

    try {
      final snapshot = await _versionRef.get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final String latestVersion = data['latest_version']?.toString() ?? '';
        final String updateDetails = data['update_details']?.toString() ?? '';

        if (_installedVersion != latestVersion) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: Text('Update Available', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: _primaryColor)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Installed: $_installedVersion', style: GoogleFonts.poppins(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Latest: $latestVersion', style: GoogleFonts.poppins(fontSize: 14)),
                      const Divider(height: 20, thickness: 1),
                      Text('Details:', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(updateDetails.isNotEmpty ? updateDetails : 'No details provided.', style: GoogleFonts.poppins(fontSize: 14)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK', style: GoogleFonts.poppins(color: _accentColor)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdatePage()));
                      },
                      child: Text('Update Now', style: GoogleFonts.poppins()),
                    ),
                  ],
                );
              },
            );
          });
        }
      }
    } catch (_) {}
  }

  // Removed MPIN setup dialog function
  // Future<void> _showSetupPinDialog() async {
  //   _newPinController.clear();
  //   _confirmPinController.clear();

  //   await showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setStateDialog) {
  //           return AlertDialog(
  //             title: Text('Set up your 4-digit PIN', style: TextStyle(color: _primaryColor)),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 TextField(
  //                   controller: _newPinController,
  //                   keyboardType: TextInputType.number,
  //                   maxLength: 4,
  //                   obscureText: true,
  //                   decoration: InputDecoration(labelText: 'New PIN', counterText: '', prefixIcon: Icon(Icons.lock_outline, color: _primaryColor)),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 TextField(
  //                   controller: _confirmPinController,
  //                   keyboardType: TextInputType.number,
  //                   maxLength: 4,
  //                   obscureText: true,
  //                   decoration: InputDecoration(labelText: 'Confirm PIN', counterText: '', prefixIcon: Icon(Icons.lock_outline, color: _primaryColor)),
  //                 ),
  //                 if (_isSettingPin) const Padding(padding: EdgeInsets.only(top: 12), child: CircularProgressIndicator()),
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: _isSettingPin ? null : () {},
  //                 child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
  //               ),
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
  //                 onPressed: _isSettingPin
  //                     ? null
  //                     : () async {
  //                         final newPin = _newPinController.text.trim();
  //                         final confirmPin = _confirmPinController.text.trim();
  //                         if (newPin.length != 4 || confirmPin.length != 4) {
  //                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be exactly 4 digits.'), backgroundColor: Colors.redAccent));
  //                           return;
  //                         }
  //                         if (newPin != confirmPin) {
  //                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match.'), backgroundColor: Colors.redAccent));
  //                           return;
  //                         }
  //                         setStateDialog(() => _isSettingPin = true);
  //                         try {
  //                           final user = FirebaseAuth.instance.currentUser;
  //                           if (user == null) throw Exception('No authenticated user.');
  //                           final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  //                           await docRef.set({'mPin': newPin}, SetOptions(merge: true));
  //                           Navigator.of(context).pop();
  //                         } catch (e) {
  //                           setStateDialog(() => _isSettingPin = false);
  //                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to set PIN. ${e.toString()}'), backgroundColor: Colors.redAccent));
  //                         }
  //                       },
  //                 child: const Text('Save PIN'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const AnnouncementsPage(),
      if (curClient.isResident) const InventoryPage(),
      ChatList(),
      ProfilePage(client: curClient),
    ];

    final List<BottomNavigationBarItem> _navItems = [
      BottomNavigationBarItem(icon: _iconAsset("assets/announcement.png"), label: "Announcements"),
      if (curClient.isResident) BottomNavigationBarItem(icon: _iconAsset("assets/inventory.png"), label: "Inventory"),
      BottomNavigationBarItem(icon: _iconAsset("assets/message.png"), label: "Messages"),
      BottomNavigationBarItem(icon: _iconAsset("assets/account.png"), label: "Account"),
    ];

    if (_selectedIndex >= _pages.length) _selectedIndex = 0;

    return Theme(
      data: ThemeData(primaryColor: _primaryColor, colorScheme: ColorScheme.light(primary: _primaryColor, secondary: _accentColor)),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _selectedIndex != 0 ? null : _buildAppBar(),
        drawer: _buildDrawer(),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFF8F9FA), Color(0xFFE9F0F5)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: IndexedStack(index: _selectedIndex, children: _pages),
        ),
        bottomNavigationBar: _buildBottomNavBar(_navItems),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'SK Connect',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.black,
              shadows: [
                Shadow(
                  blurRadius: 2.0,
                  color: Colors.grey.withOpacity(0.2),
                  offset: const Offset(1.0, 1.0),
                ),
              ],
            ),
          ),
        ],
      ),
      // No changes needed here, as the app bar itself doesn't directly relate to MPIN.
    );
  }

  Widget _iconAsset(String path) {
    return SizedBox(height: 24, width: 24, child: Image.asset(path));
  }

  Widget _buildBottomNavBar(List<BottomNavigationBarItem> items) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.white.withOpacity(0.9)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: BottomNavigationBar(
        items: items,
        currentIndex: _selectedIndex,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white, _backgroundColor], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            _drawerItem(Icons.edit, 'Edit Profile', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(client: curClient)));
            }),
            _drawerItem(Icons.notifications, 'Notifications', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage()));
            }),
            _drawerItem(Icons.security, 'Multifactor Settings', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MultifactorPage()));
            }),
            _drawerItem(Icons.assignment_outlined, 'Full Disclosure Board', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BulletinBoardPage()));
            }),
            _drawerItem(Icons.people_outline, 'Officials', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficialsPage()));
            }),
            _drawerItem(Icons.feedback_outlined, 'Feedback', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackPage()));
            }),
            _drawerItem(Icons.system_update_alt, 'Update', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdatePage()));
            }),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: _primaryColor),
              title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  // Disable biometric login option for the current user
                  await BiometricDBHelper.setBiometricEnabled(false); // <--- Added this line
                  Navigator.pop(context); // Close drawer
                  await AuthHelper().logout();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryColor, _accentColor], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [_primaryColor, _accentColor]),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.transparent,
              backgroundImage: curClient.profilePicture.isNotEmpty ? MemoryImage(base64Decode(curClient.profilePicture)) : null,
              child: curClient.profilePicture.isEmpty ? const Icon(Icons.person, size: 30, color: Colors.white) : null,
            ),
          ),
          const SizedBox(height: 12),
          Text('${curClient.firstname} ${curClient.lastname}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(curClient.email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_primaryColor.withOpacity(0.1), _accentColor.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _primaryColor),
      ),
      title: Text(title, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}