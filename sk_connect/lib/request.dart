import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sk_connect/borrow_request_class.dart';
import 'package:sk_connect/client_class.dart';
import 'package:sk_connect/database_helper.dart';
import 'package:sk_connect/item_class.dart';

class RequestsTab extends StatelessWidget {
  final List<BorrowRequest> requests;
  final List<Item> items;
  final Function(String) onCancelRequest;
  final Color pendingColor;
  final Color approvedColor;
  final Color rejectedColor;
  final Color primaryColor;
  final Color accentColor;
  final Color cardGradientStart;
  final Color cardGradientEnd;

  const RequestsTab({
    super.key,
    required this.requests,
    required this.items,
    required this.onCancelRequest,
    required this.pendingColor,
    required this.approvedColor,
    required this.rejectedColor,
    required this.primaryColor,
    required this.accentColor,
    required this.cardGradientStart,
    required this.cardGradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    final pendingRequests = requests.where((r) => r.status == 'Pending').toList();

    if (pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending_actions, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        return _RequestCard(
          request: pendingRequests[index],
          items: items,
          onCancelRequest: onCancelRequest,
          pendingColor: pendingColor,
          approvedColor: approvedColor,
          rejectedColor: rejectedColor,
          primaryColor: primaryColor,
          accentColor: accentColor,
          cardGradientStart: cardGradientStart,
          cardGradientEnd: cardGradientEnd,
        );
      },
    );
  }
}

class _RequestCard extends StatefulWidget {
  final BorrowRequest request;
  final List<Item> items;
  final Function(String) onCancelRequest;
  final Color pendingColor;
  final Color approvedColor;
  final Color rejectedColor;
  final Color primaryColor;
  final Color accentColor;
  final Color cardGradientStart;
  final Color cardGradientEnd;

  const _RequestCard({
    required this.request,
    required this.items,
    required this.onCancelRequest,
    required this.pendingColor,
    required this.approvedColor,
    required this.rejectedColor,
    required this.primaryColor,
    required this.accentColor,
    required this.cardGradientStart,
    required this.cardGradientEnd,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.items.firstWhere(
      (i) => i.key == widget.request.itemKey,
      orElse: () => Item(key: '', name: 'Unknown Item', image: '', totalQuantity: 0),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.cardGradientStart.withOpacity(0.95),
                widget.cardGradientEnd.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ExpansionTile(
            onExpansionChanged: (val) => setState(() => _isExpanded = val),
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            trailing: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: widget.primaryColor,
            ),
            title: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: item.image.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(item.image),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Icon(Icons.inventory_2_outlined,
                          color: Colors.grey.shade400, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: widget.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantity: ${widget.request.quantity}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              const Divider(thickness: 1.2),
              const SizedBox(height: 8),

              _buildDetailRow(
                Icons.calendar_today,
                DateFormat('MMMM d, yyyy').format(widget.request.timestamp),
              ),

              FutureBuilder<String>(
                future: _getBorrowerName(widget.request.requesterUid),
                builder: (context, snapshot) {
                  final nameText = snapshot.connectionState == ConnectionState.waiting
                      ? 'Loading...'
                      : snapshot.hasError
                          ? 'Error loading name'
                          : snapshot.data ?? 'Unknown';
                  return _buildDetailRow(Icons.person, nameText);
                },
              ),

              _buildDetailRow(Icons.description, widget.request.purpose),

              const SizedBox(height: 12),

              if (widget.request.controlNumbers.isNotEmpty) ...[
                Text(
                  'Control Numbers:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: widget.request.controlNumbers
                      .map((cn) => Chip(label: Text(cn)))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(widget.request.status),
                          _getStatusColor(widget.request.status).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(widget.request.status).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Text(
                      widget.request.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => widget.onCancelRequest(widget.request.key),
                    style: TextButton.styleFrom(
                      backgroundColor: widget.rejectedColor.withOpacity(0.1),
                      foregroundColor: widget.rejectedColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('CANCEL'),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: widget.accentColor.withOpacity(0.9)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getBorrowerName(String uid) async {
    try {
      final client = await getClient(uid);
      return client?.fullName ?? 'Unknown User';
    } catch (_) {
      return 'Error loading user';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return widget.pendingColor;
      case 'Approved':
        return widget.approvedColor;
      case 'Rejected':
        return widget.rejectedColor;
      default:
        return Colors.grey.shade600;
    }
  }
}
