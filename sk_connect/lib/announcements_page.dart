import 'package:flutter/material.dart';
import 'database_helper.dart'; // Assuming this provides getAllAnnouncements
import 'announcement.dart'; // Assuming this defines the Announcement class
import 'dart:convert';
import 'package:intl/intl.dart';
import 'calendar_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'client_class.dart'; // Import the Client class
import 'dart:async'; // Import for StreamSubscription

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({Key? key}) : super(key: key);

  @override
  _AnnouncementsPageState createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  // Color scheme
  final Color _primaryColor = const Color(0xFF0A2463);
  final Color _accentColor = const Color(0xFF3E92CC);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _errorColor = const Color(0xFFD62839);
  final Color _ongoingColor = Colors.green;

  bool _isLoading = false;
  late Future<List<Announcement>> _announcementsFuture;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Client? _currentClient;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _clientSubscription; // Declare subscription

  @override
  void initState() {
    super.initState();
    _announcementsFuture = _loadAnnouncements();
    // Start listening for client data changes when the widget initializes.
    // This listener will handle subsequent real-time updates after the initial load.
    _listenForClientChanges();
  }

  @override
  void dispose() {
    _clientSubscription?.cancel(); // Cancel the subscription when the widget is disposed
    super.dispose();
  }

  // Method to set up real-time listener for client data
  void _listenForClientChanges() {
    if (_currentUser == null) {
      return; // No user logged in, no client to listen for
    }

    // Listen to changes in the current user's client document
    _clientSubscription = FirebaseFirestore.instance
        .collection('clients')
        .doc(_currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // If document exists, update _currentClient and trigger a rebuild
        setState(() {
          _currentClient = Client.fromJson(snapshot.data()!);
        });
      } else {
        // If document doesn't exist (e.g., user deleted their profile), clear _currentClient
        setState(() {
          _currentClient = null;
        });
      }
    }, onError: (error) {
      // Handle any errors that occur during listening
      _showMessage('Error loading client data: $error', isError: true);
    });
  }

  // Modified to explicitly load initial client data before announcements
  Future<List<Announcement>> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      // First, fetch the initial _currentClient data to ensure it's available
      if (_currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('clients')
            .doc(_currentUser.uid)
            .get();
        if (doc.exists) {
          _currentClient = Client.fromJson(doc.data()!);
        } else {
          _currentClient = null; // Explicitly set to null if no client document
        }
      } else {
        _currentClient = null; // No current user, so no client data
      }

      // Then, load the announcements
      return getAllAnnouncements();
    } catch (e) {
      _showMessage('Failed to load announcements or client data: $e', isError: true);
      return [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Calculates age based on birthday
  int _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  // Checks if the current user is already registered for an announcement
  Future<bool> _isRegistered(Announcement a) async {
    if (_currentUser == null) return false;
    final snap = await FirebaseFirestore.instance
        .collection('event_registrations')
        .where('announcementId', isEqualTo: a.id)
        .where('userId', isEqualTo: _currentUser.uid)
        .where('isPreRegistered', isEqualTo: true)
        .get();
    return snap.docs.isNotEmpty;
  }

  // Gets the count of pre-registered users for an announcement
  Future<int> _getCount(Announcement a) async {
    final snap = await FirebaseFirestore.instance
        .collection('event_registrations')
        .where('announcementId', isEqualTo: a.id)
        .where('isPreRegistered', isEqualTo: true)
        .get();
    return snap.docs.length;
  }

  // Toggles registration status for an announcement
  Future<void> _toggleRegistration(Announcement a, bool currentlyRegistered) async {
    if (_currentUser == null) {
      _showMessage('Please login first to register for events.', isError: true);
      return;
    }

    // Perform the age check here using the real-time updated _currentClient
    // This check is now robust as _currentClient is guaranteed to be initially loaded
    if (_currentClient != null && _calculateAge(_currentClient!.birthday) > 30) {
      _showMessage('Users over 30 cannot register for events.', isError: true);
      return;
    }

    final ref = FirebaseFirestore.instance.collection('event_registrations');
    try {
      final snap = await ref
          .where('announcementId', isEqualTo: a.id)
          .where('userId', isEqualTo: _currentUser.uid)
          .limit(1)
          .get();

      if (currentlyRegistered) {
        if (snap.docs.isNotEmpty) {
          // If already registered, update to false (cancel registration)
          await ref.doc(snap.docs.first.id).update({'isPreRegistered': false});
        }
        _showMessage('Registration cancelled.', isError: false);
      } else {
        if (snap.docs.isEmpty) {
          // If not registered, add a new registration document
          await ref.add({
            'announcementId': a.id,
            'title': a.title,
            'eventDate': Timestamp.fromDate(a.eventDate),
            'registeredAt': Timestamp.now(),
            'userId': _currentUser.uid,
            'isPreRegistered': true,
          });
        } else {
          // If a record exists but isPreRegistered is false, update it to true
          await ref.doc(snap.docs.first.id).update({
            'isPreRegistered': true,
            'registeredAt': Timestamp.now(),
          });
        }
        _showMessage('Pre-registered successfully!', isError: false);
      }
      // Refresh the UI to reflect registration changes
      setState(() {
        _announcementsFuture = _loadAnnouncements(); // Re-fetch announcements to update counts/registration
      });
    } catch (e) {
      _showMessage('Operation failed. Please try again. Error: $e', isError: true);
    }
  }

  // Shows a SnackBar message to the user
  void _showMessage(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _errorColor : _accentColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // Builds a simple card for general announcements
  Widget _buildSimpleCard(Announcement a) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ViewAnnouncementPage(announcement: a)),
      ),
      child: Container(
        width: 320,
        height: 140,
        margin: const EdgeInsets.only(right: 16, bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            if (a.image?.isNotEmpty ?? false)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Image.memory(
                  base64Decode(a.image!),
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: _accentColor),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d').format(a.eventDate),
                          style: TextStyle(color: _accentColor, fontSize: 10),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            minimumSize: const Size(60, 24),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ViewAnnouncementPage(announcement: a)),
                          ),
                          child: const Text('View', style: TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds an event card with registration functionality
  Widget _buildEventCard(Announcement a, {Duration? timeLeft}) {
    final now = DateTime.now();
    Widget badge;
    if (timeLeft == null || timeLeft.isNegative) { // Check if timeLeft is null or negative for "ONGOING"
      badge = Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _ongoingColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'ONGOING',
          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      final days = timeLeft.inDays;
      final hours = timeLeft.inHours % 24;
      final minutes = timeLeft.inMinutes % 60;
      badge = Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _errorColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${days}d ${hours}h ${minutes}m left',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      );
    }

    // Determine if the register button should be shown
    bool showRegisterButton = true;

    // IMPORTANT: Ensure _currentUser is logged in AND _currentClient data is available
    // before performing the age check. If not, the button should be hidden.
    if (_currentUser == null || _currentClient == null) {
      showRegisterButton = true;
    } else if (_calculateAge(_currentClient!.birthday) > 30) {
      // If user is logged in and client data is available, perform the age check.
      showRegisterButton = false; // Hide if user is over 30
    }

    // Also hide if the event is in the past
    if (a.eventDate.isBefore(now)) {
      showRegisterButton = false;
    }

    return FutureBuilder<bool>(
      future: _isRegistered(a), // Check registration status
      builder: (ctx, regSnap) {
        final isReg = regSnap.data ?? false;
        return FutureBuilder<int>(
          future: _getCount(a), // Get registered count
          builder: (ctx2, countSnap) {
            final count = countSnap.data ?? 0;
            return GestureDetector(
              onTap: () => Navigator.push(
                ctx2,
                MaterialPageRoute(builder: (_) => ViewAnnouncementPage(announcement: a)),
              ),
              child: Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16, bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (a.image?.isNotEmpty ?? false)
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.memory(base64Decode(a.image!), fit: BoxFit.cover),
                        ),
                      ),
                    Container(
                      color: _backgroundColor,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  a.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              badge, // Display the ONGOING or time left badge
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.people, size: 14, color: _accentColor),
                              const SizedBox(width: 4),
                              Text('$count', style: TextStyle(color: _accentColor, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: _accentColor),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM d, hh:mm').format(a.eventDate),
                                style: TextStyle(color: _accentColor, fontSize: 12),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(a.type, style: const TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Display register/cancel button if eligible
                          if (showRegisterButton)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: isReg ? _accentColor : Colors.white,
                                  backgroundColor: isReg ? Colors.white : _accentColor,
                                  side: isReg ? BorderSide(color: _accentColor) : BorderSide.none,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: isReg ? 0 : 2,
                                ),
                                onPressed: () => _toggleRegistration(a, isReg),
                                child: Text(isReg ? 'Cancel' : 'Pre-register'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Add a method to handle the refresh
  Future<void> _onRefresh() async {
    setState(() {
      _announcementsFuture = _loadAnnouncements(); // Reload announcements and client data
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formatted = DateFormat('EEEE, MMMM d, hh:mm').format(now);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER as white card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(formatted, style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.black54),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarPage())),
                  ),
                ],
              ),
            ),
            Expanded(
              // Wrap the ListView with RefreshIndicator
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: _primaryColor, // Customize refresh indicator color
                child: FutureBuilder<List<Announcement>>(
                  future: _announcementsFuture,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    final all = snap.data ?? [];
                    final events = all.where((a) => a.type == 'Event').toList();
                    final others = all.where((a) => a.type != 'Event').toList();
                    // Filter events for today (ongoing/starting today)
                    final todayEvents = events.where((a) => _sameDay(a.eventDate, now)).toList();
                    // Filter upcoming events (after today)
                    final upcoming = events.where((a) => a.eventDate.isAfter(now)).toList()
                      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

                    if (all.isEmpty && !_isLoading) {
                      return ListView( // Use ListView here so RefreshIndicator works even if there's no data
                        children: [
                          _empty('No announcements or events available.'),
                        ],
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        _section('Announcements', Icons.announcement),
                        others.isEmpty
                            ? _empty('Nothing to show')
                            : SizedBox(
                                height: 160,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: others.length,
                                  itemBuilder: (_, i) => _buildSimpleCard(others[i]),
                                ),
                              ),
                        const SizedBox(height: 24),
                        _section('Current Events', Icons.event_available),
                        todayEvents.isEmpty
                            ? _empty('No events today')
                            : SizedBox(
                                height: 330,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: todayEvents.length,
                                  itemBuilder: (_, i) => _buildEventCard(todayEvents[i], timeLeft: todayEvents[i].eventDate.difference(now)),
                                ),
                              ),
                        const SizedBox(height: 24),
                        _section('Upcoming Events', Icons.schedule),
                        upcoming.isEmpty
                            ? _empty('No upcoming events')
                            : SizedBox(
                                height: 350,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: upcoming.length,
                                  itemBuilder: (_, i) => _buildEventCard(upcoming[i], timeLeft: upcoming[i].eventDate.difference(now)),
                                ),
                              ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Display loading indicator if needed (can be removed since RefreshIndicator has its own)
            // if (_isLoading)
            //   Container(color: Colors.black38, child: const Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }

  // Helper to check if two DateTime objects are on the same day
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Helper to build a section header
  Widget _section(String title, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: _primaryColor),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: _primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  // Helper to display an empty message
  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text(msg, style: TextStyle(color: Colors.grey[600]))),
      );
}

// Separate widget for viewing detailed announcement
class ViewAnnouncementPage extends StatelessWidget {
  final Announcement announcement;

  const ViewAnnouncementPage({Key? key, required this.announcement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(announcement.title),
        backgroundColor: theme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (announcement.image?.isNotEmpty ?? false)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(base64Decode(announcement.image!), width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text(
              DateFormat('EEEE, MMMM d, hh:mm').format(announcement.eventDate),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(announcement.details ?? '', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}