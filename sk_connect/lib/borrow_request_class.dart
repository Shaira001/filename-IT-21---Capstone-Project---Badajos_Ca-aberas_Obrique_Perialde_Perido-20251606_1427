// borrow_request_class.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowRequest {
  String key;
  String itemKey;
  int quantity;
  String purpose;
  String status;
  DateTime timestamp;
  DateTime returnDate;      // 🆕
  String requesterUid;
  String controlNumber;     // existing
  List<String> controlNumbers; // 🆕

  BorrowRequest({
    required this.key,
    required this.itemKey,
    required this.quantity,
    required this.purpose,
    required this.status,
    required this.timestamp,
    required this.returnDate,       // 🆕
    required this.requesterUid,
    required this.controlNumber,    // existing
    required this.controlNumbers,   // 🆕
  });

  factory BorrowRequest.fromJson(Map<String, dynamic> json) {
    return BorrowRequest(
      key:              json['key'] ?? '',
      itemKey:          json['itemKey'] ?? '',
      quantity:         json['quantity'] ?? 0,
      purpose:          json['purpose'] ?? '',
      status:           json['status'] ?? '',
      timestamp:        DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      returnDate:       DateTime.tryParse(json['returnDate'] ?? '') ?? DateTime.now(),       // 🆕
      requesterUid:     json['requesterUid'] ?? '',
      controlNumber:    json['controlNumber'] ?? '',                                         // existing
      controlNumbers:   List<String>.from(json['controlNumbers'] ?? []),                     // 🆕
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key':             key,
      'itemKey':         itemKey,
      'quantity':        quantity,
      'purpose':         purpose,
      'status':          status,
      'timestamp':       timestamp.toIso8601String(),
      'returnDate':      returnDate.toIso8601String(),    // 🆕
      'requesterUid':    requesterUid,
      'controlNumber':   controlNumber,                   // existing
      'controlNumbers':  controlNumbers,                  // 🆕
    };
  }

  Map<String, dynamic> toMap() => toJson(); // for Firestore helper
}
