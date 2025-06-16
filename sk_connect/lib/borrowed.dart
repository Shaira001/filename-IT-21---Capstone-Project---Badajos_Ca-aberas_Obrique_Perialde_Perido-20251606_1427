import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sk_connect/borrow_request_class.dart'; // Assuming this class exists
import 'package:sk_connect/item_class.dart'; // Assuming this class exists
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class BorrowedTab extends StatelessWidget {
  final List<BorrowRequest> requests;
  final List<Item> items;
  final Color primaryColor;
  final Color accentColor;
  final Color cardGradientStart;
  final Color cardGradientEnd;

  const BorrowedTab({
    super.key,
    required this.requests,
    required this.items,
    required this.primaryColor,
    required this.accentColor,
    required this.cardGradientStart,
    required this.cardGradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    // Filter to show only approved requests
    final approvedRequests = requests
        .where((r) => r.status.toLowerCase() == 'approved')
        .toList();

    if (approvedRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No approved borrowed items',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: approvedRequests.length,
      itemBuilder: (context, index) =>
          _buildExpandableCard(context, approvedRequests[index]),
    );
  }

  Widget _buildExpandableCard(BuildContext context, BorrowRequest request) {
    // Find the item associated with this borrow request
    final item = items.firstWhere(
      (i) => i.key == request.itemKey,
      orElse: () => Item(
        key: '',
        name: 'Unknown Item',
        image: '',
        totalQuantity: 0,
      ), // Provide a fallback Item
    );

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Theme(
          data: ThemeData().copyWith(
            dividerColor: Colors.transparent, // Hides the default divider
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.all(16),
            backgroundColor: cardGradientStart.withOpacity(0.05),
            collapsedBackgroundColor: cardGradientStart.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                // Item image or placeholder
                item.image.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(item.image),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.inventory,
                            color: Colors.grey.shade400),
                      ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Qty: ${request.quantity}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 4),
                      // Live countdown timer for return date
                      LiveCountdownTimer(returnDate: request.returnDate),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              Container(
                height: 200, // Fixed height for scrollable content
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full item image when expanded
                      if (item.image.isNotEmpty)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(item.image),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      SizedBox(height: 12),
                      // Borrower's name (fetched asynchronously)
                      FutureBuilder<String>(
                        future: _getBorrowerName(request.requesterUid),
                        builder: (context, snapshot) {
                          return _infoRow(Icons.person, 'Borrower',
                              snapshot.data ?? 'Loading...');
                        },
                      ),
                      _infoRow(Icons.info_outline, 'Purpose', request.purpose),
                      _infoRow(Icons.calendar_today, 'Borrowed on',
                          DateFormat('yMMMd').format(request.timestamp)),
                      _infoRow(Icons.schedule, 'Return by',
                          DateFormat('yMMMd').format(request.returnDate)),
                      SizedBox(height: 12),
                      Text(
                        'Control Numbers:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      // Display borrowed control numbers as chips
                      request.controlNumbers.isNotEmpty
                          ? Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: request.controlNumbers
                                  .map((cn) => Chip(
                                        label: Text(cn),
                                        backgroundColor:
                                            Colors.grey.shade200,
                                      ))
                                  .toList(),
                            )
                          : Text(
                              'No control numbers available.',
                              style: TextStyle(color: Colors.grey),
                            ),
                      SizedBox(height: 12),
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

  // Helper method to create an information row
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accentColor),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          Expanded(child: Text(value, style: TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  // Asynchronously fetches borrower's name from Firestore
  Future<String> _getBorrowerName(String uid) async {
    try {
      // Access the Firestore instance
      final docSnapshot = await FirebaseFirestore.instance
          .collection('clients') // Assuming your client data is in a 'clients' collection
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        // Assuming 'fullName' is the field in your client document
        return docSnapshot.data()?['fullName'] ?? 'Unknown User';
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching borrower name: $e'); // For debugging
      return 'Error loading user';
    }
  }
}

// Widget for a live countdown timer (remains unchanged)
class LiveCountdownTimer extends StatefulWidget {
  final DateTime returnDate;

  const LiveCountdownTimer({super.key, required this.returnDate});

  @override
  State<LiveCountdownTimer> createState() => _LiveCountdownTimerState();
}

class _LiveCountdownTimerState extends State<LiveCountdownTimer> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Update the timer every second
    _timer = Timer.periodic(Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Current time adjusted to UTC+8 (Philippines time)
    final now = DateTime.now().toUtc().add(Duration(hours: 8));
    final difference = widget.returnDate.difference(now);
    final overdue = difference.isNegative;
    final duration = overdue ? now.difference(widget.returnDate) : difference;

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final text = overdue
        ? 'Overdue: ${days}d ${hours}h ${minutes}m ${seconds}s'
        : 'Left: ${days}d ${hours}h ${minutes}m ${seconds}s';

    return Text(
      text,
      style: TextStyle(
        color: overdue ? Colors.red : Colors.green,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }
}