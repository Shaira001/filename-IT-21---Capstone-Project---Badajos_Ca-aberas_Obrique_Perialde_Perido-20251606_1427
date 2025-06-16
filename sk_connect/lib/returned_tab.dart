import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sk_connect/borrow_request_class.dart';
import 'package:sk_connect/item_class.dart';

class ReturnedTab extends StatefulWidget {
  final List<BorrowRequest> requests;
  final List<Item> items;
  final Color primaryColor;
  final Color accentColor;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color returnedColor;

  const ReturnedTab({
    super.key,
    required this.requests,
    required this.items,
    required this.primaryColor,
    required this.accentColor,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.returnedColor,
  });

  @override
  State<ReturnedTab> createState() => _ReturnedTabState();
}

class _ReturnedTabState extends State<ReturnedTab> {
  // Cache for decoded images, keyed by item key
  final Map<String, Uint8List> _imageCache = {};

  Uint8List? _getImageBytes(Item item) {
    if (item.image.isEmpty) return null;

    // If already decoded and cached, return it
    if (_imageCache.containsKey(item.key)) {
      return _imageCache[item.key];
    }

    // Decode and cache the image bytes
    try {
      final bytes = base64Decode(item.image);
      _imageCache[item.key] = bytes;
      return bytes;
    } catch (e) {
      // Decoding failed, just return null to show placeholder
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final returnedRequests =
        widget.requests.where((r) => r.status == 'Returned').toList();

    if (returnedRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.assignment_return, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No returned items',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: returnedRequests.length,
      itemBuilder: (context, index) {
        final req = returnedRequests[index];
        final correspondingItem =
            widget.items.firstWhere((item) => item.key == req.itemKey);

        final imageBytes = _getImageBytes(correspondingItem);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.cardGradientStart, widget.cardGradientEnd],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    imageBytes != null
                        ? Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.assignment_return,
                              color: Colors.grey.shade400,
                            ),
                          ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            correspondingItem.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Returned on: ${formatDate(req.returnDate)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, color: widget.returnedColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String formatDate(dynamic date) {
    if (date == null) return '';
    DateTime dt;
    if (date is DateTime) {
      dt = date;
    } else {
      dt = DateTime.tryParse(date.toString()) ?? DateTime.now();
    }
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
