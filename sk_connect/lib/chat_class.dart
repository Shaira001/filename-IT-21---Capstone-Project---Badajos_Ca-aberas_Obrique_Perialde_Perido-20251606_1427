import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  String key;
  List<String> holdersUid;
  String lastMessage;
  DateTime timestamp;
  List<Message> messages;
  bool hasRead;

  // Constructor
  Chat({
    required this.key,
    required this.holdersUid,
    required this.lastMessage,
    required this.timestamp,
    required this.messages,
    required this.hasRead,
  });

  // Named empty constructor
  Chat.empty()
      : key = '',
        holdersUid = [],
        lastMessage = '',
        timestamp = DateTime.now(),
        messages = [],
        hasRead = false;

  // Factory method to create Chat from Firestore DocumentSnapshot
  factory Chat.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Chat(
      key: doc.id,
      holdersUid: List<String>.from(data['holdersUid'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      messages: (data['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromMap(e))
              .toList() ??
          [],
      hasRead: data['hasRead'] ?? false,
    );
  }

  // Factory method to create a Chat object from JSON
  factory Chat.fromJson(Map<String, dynamic> data) {
    return Chat(
      key: data['key'] ?? '',
      holdersUid: (data['holdersUid'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      lastMessage: data['lastMessage'] ?? '',
      timestamp: (data['timestamp'] != null) ? DateTime.parse(data['timestamp']) : DateTime.now(),
      messages: (data['messages'] as List<dynamic>?)?.map((e) => Message.fromMap(e)).toList() ?? [],
      hasRead: data['hasRead'] ?? false,
    );
  }

  // Convert a Chat object to JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'holdersUid': holdersUid,
      'lastMessage': lastMessage,
      'timestamp': timestamp.toIso8601String(),
      'messages': messages.map((msg) => msg.toMap()).toList(),
      'hasRead': hasRead,
    };
  }
}

class Message {
  String text;
  String senderUid;
  DateTime timestamp;
  String? imageBase64;

  Message({
    required this.text,
    required this.senderUid,
    required this.timestamp,
    this.imageBase64,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderUid': senderUid,
      'timestamp': timestamp.toIso8601String(),
      if (imageBase64 != null) 'imageBase64': imageBase64,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      text: map['text'],
      senderUid: map['senderUid'],
      timestamp: DateTime.parse(map['timestamp']),
      imageBase64: map['imageBase64'],
    );
  }
}