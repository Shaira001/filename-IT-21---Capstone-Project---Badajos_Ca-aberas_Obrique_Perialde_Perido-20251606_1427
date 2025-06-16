import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sk_connect/Feedback_class.dart';
import 'package:sk_connect/announcement.dart';
import 'package:sk_connect/boardItem_class.dart';
import 'package:sk_connect/borrow_request_class.dart';
import 'package:sk_connect/chat_class.dart';
import 'package:sk_connect/client_class.dart';
import 'package:sk_connect/feeditem_class.dart';
import 'package:sk_connect/item_class.dart';
import 'package:sk_connect/official.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

// --------------------- CLIENT FUNCTIONS ---------------------

Future<void> addClient(Client client) async {
  try {
    await firestore.collection('Clients').add(client.toJson());
    print('Client added successfully');
  } catch (error) {
    print('Failed to add Client: $error');
  }
}





Future<void> updateClient(Client client) async {
  try {
    await firestore.collection('Clients').doc(client.key).update(client.toJson());
    print('Client updated successfully');
  } catch (error) {
    print('Failed to update Client: $error');
  }
}

Future<List<Client>> getAllClients() async {
  try {
    QuerySnapshot snapshot = await firestore.collection('Clients').get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return Client.fromJson(data);
    }).toList();
  } catch (error) {
    print('Failed to fetch Clients: $error');
    return [];
  }
}

Future<void> deleteClient(String clientID) async {
  try {
    await firestore.collection('Clients').doc(clientID).delete();
    print('Client deleted successfully');
  } catch (error) {
    print('Failed to delete Client: $error');
  }
}

Future<Client?> getClient(String uid) async {
  try {
    QuerySnapshot snapshot = await firestore
        .collection('Clients')
        .where('uid', isEqualTo: uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return Client.fromJson(data);
    }
  } catch (error) {
    print('Failed to get Client: $error');
  }
  return null;
}

// --------------------- ANNOUNCEMENT FUNCTIONS ---------------------

Future<void> addAnnouncement(Announcement announcement) async {
  try {
    await firestore.collection('Announcement').add(announcement.toJson());
    print('Announcement added successfully');
  } catch (error) {
    print('Failed to add announcement: $error');
  }
}

Future<void> updateAnnouncement(Announcement announcement) async {
  try {
    await firestore.collection('Announcement').doc(announcement.key).update(announcement.toJson());
    print('Announcement updated successfully');
  } catch (error) {
    print('Failed to update announcement: $error');
  }
}

Future<void> deleteAnnouncement(String announcementId) async {
  try {
    await firestore.collection('Announcement').doc(announcementId).delete();
    print('Announcement deleted successfully');
  } catch (error) {
    print('Failed to delete announcement: $error');
  }
}

Future<List<Announcement>> getAllAnnouncements() async {
  try {
    QuerySnapshot snapshot = await firestore.collection('Announcement').get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return Announcement.fromJson(data);
    }).toList();
  } catch (error) {
    print('Failed to fetch announcements: $error');
    return [];
  }
}

Stream<List<Announcement>> streamAllAnnouncements() {
  return firestore.collection('Announcement').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return Announcement.fromJson(data);
    }).toList();
  });
}



Future<String?> addChat(Chat chat) async {
  try {
    DocumentReference docRef = await firestore.collection('Chats').add(chat.toJson());
    await docRef.update({'key': docRef.id}); // Store Firestore-generated ID
    print('Chat added successfully with ID: ${docRef.id}');

    return docRef.id; // Return the generated ID
  } catch (error) {
    print('Failed to add Chat: $error');
    return null; // Return null if there was an error
  }
}

Future<void> updateChat(Chat chat) async {
  try {
    if (chat.key.isEmpty) {
      print('Error: Chat key is null');
      return;
    }
    await firestore.collection('Chats').doc(chat.key).update(chat.toJson());
    print('Chat updated successfully');
  } catch (error) {
    print('Failed to update Chat: $error');
  }
}

Stream<List<Chat>> getUserChatsStream(String userUid) {
  return firestore.collection('Chats')
      .where('holdersUid', arrayContains: userUid)
      .snapshots()
      .map((querySnapshot) {
        return querySnapshot.docs.map((doc) {
          return Chat.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'key': doc.id,
          });
        }).toList();
      });
}


Future<void> deleteChat(String chatID) async {
  try {
    await firestore.collection('Chats').doc(chatID).delete();
    print('Chat deleted successfully');
  } catch (error) {
    print('Failed to delete Chat: $error');
  }
}

Future<Chat?> getChat(String chatID) async {
  try {
    DocumentSnapshot doc = await firestore.collection('Chats').doc(chatID).get();
    if (doc.exists) {
      return Chat.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'key': doc.id,
      });
    }
  } catch (error) {
    print('Failed to fetch chat: $error');
  }
  return null;
}

Future<void> sendMessage(String chatID, Message message) async {
  try {
    DocumentReference chatRef = firestore.collection('Chats').doc(chatID);
    await chatRef.update({
      'messages': FieldValue.arrayUnion([message.toMap()]),
      'lastMessage': message.text,
      'timestamp': message.timestamp.toIso8601String(),
    });
    print('Message sent successfully');
  } catch (error) {
    print('Failed to send message: $error');
  }
}

Future<List<Message>> getMessages(String chatID) async {
  try {
    DocumentSnapshot doc = await firestore.collection('Chats').doc(chatID).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return (data['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromMap(e))
              .toList() ??
          [];
    }
  } catch (error) {
    print('Failed to fetch messages: $error');
  }
  return [];
}

Future<void> addItem(Item item) async {
  try {
    await firestore.collection('Item').add(item.toJson());
    print('Item added successfully');
  } catch (error) {
    print('Failed to add Item: $error');
  }
}

Future<void> updateItem(Item item) async {
  try {
    await firestore.collection('Item').doc(item.key).update(item.toJson());
    print('Item updated successfully');
  } catch (error) {
    print('Failed to update Item: $error');
  }
}

Future<void> deleteItem(String ItemId) async {
  try {
    await firestore.collection('Item').doc(ItemId).delete();
    print('Item deleted successfully');
  } catch (error) {
    print('Failed to delete Item: $error');
  }
}

Future<List<Item>> getAllItems() async {
  try {
    QuerySnapshot snapshot = await firestore.collection('Item').get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return Item.fromJson(data);
    }).toList();
  } catch (error) {
    print('Failed to fetch Items: $error');
    return [];
  }
}
Future<Item> getItemFromDatabase(String controlNumber) async {
    // Fetch item from Firebase or your database using control number
    final snapshot = await FirebaseFirestore.instance.collection('items')
        .where('controlNumber', isEqualTo: controlNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Item not found');
    }

    return Item.fromJson(snapshot.docs.first.data());
  }

  Future<void> updateItemInDatabase(Item item) async {
    // Update item in Firebase
    await FirebaseFirestore.instance.collection('items').doc(item.key).update({
      'status': item.status,
    });
  }

Future<Item?> getItem(String key) async {
  try {
    QuerySnapshot snapshot = await firestore
        .collection('Items')
        .where('key', isEqualTo: key)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return Item.fromJson(data);
    }
  } catch (error) {
    print('Failed to get Item: $error');
  }
  return null;
}

Future<void> addBorrowRequest(BorrowRequest borrowRequest) async {
  try {
    await firestore.collection('BorrowRequest').add(borrowRequest.toJson());
    print('BorrowRequest added successfully');
  } catch (error) {
    print('Failed to add BorrowRequest: $error');
  }
}

Future<BorrowRequest?> getBorrowRequest(String key) async {
  try {
    QuerySnapshot snapshot = await firestore
        .collection('BorrowRequests')
        .where('key', isEqualTo: key)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return BorrowRequest.fromJson(data);
    }
  } catch (error) {
    print('Failed to get BorrowRequest: $error');
  }
  return null;
}


Future<void> updateBorrowRequest(BorrowRequest borrowRequest) async {
  try {
    await firestore.collection('BorrowRequest').doc(borrowRequest.key).update(borrowRequest.toJson());
    print('BorrowRequest updated successfully');
  } catch (error) {
    print('Failed to update BorrowRequest: $error');
  }
}

Future<void> updateBorrowRequestStatus(BorrowRequest borrowRequest, String status) async {
  try {
    await firestore.collection('BorrowRequest').doc(borrowRequest.key).update({'status': status});
    print('BorrowRequest updated successfully');
  } catch (error) {
    print('Failed to update BorrowRequest: $error');
  }
}

Future<void> deleteBorrowRequest(String BorrowRequestId) async {
  try {
    await firestore.collection('BorrowRequest').doc(BorrowRequestId).delete();
    print('BorrowRequest deleted successfully');
  } catch (error) {
    print('Failed to delete BorrowRequest: $error');
  }
}

Future<List<BorrowRequest>> getAllBorrowRequests() async {
  try {
    QuerySnapshot snapshot = await firestore.collection('BorrowRequest').get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return BorrowRequest.fromJson(data);
    }).toList();
  } catch (error) {
    print('Failed to fetch BorrowRequests: $error');
    return [];
  }
}

Stream<List<BorrowRequest>> getBorrowRequestsByUidStream(String requesterUid) {
  return firestore
      .collection('BorrowRequest')
      .where('requesterUid', isEqualTo: requesterUid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['key'] = doc.id;
            return BorrowRequest.fromJson(data);
          }).toList());
}

Stream<List<Item>> getAllItemsStream() {
  return firestore.collection('Item').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['key'] = doc.id;
        return Item.fromJson(data);
      }).toList());
}


Future<List<BorrowRequest>> getBorrowRequestsByUid(String requesterUid) async {
  try {
    QuerySnapshot snapshot = await firestore
        .collection('BorrowRequest')
        .where('requesterUid', isEqualTo: requesterUid)
        .get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return BorrowRequest.fromJson(data);
    }).toList();
  } catch (error) {
    print('Failed to fetch BorrowRequests: $error');
    return [];
  }
}


Future<void> addBoardItem(BoardItem boardItem) async {
  try {
    await firestore.collection('BoardItems').add(boardItem.toJson());
    print('BoardItem added successfully');
  } catch (error) {
    print('Failed to add BoardItem: $error');
  }
}

Future<void> updateBoardItem(BoardItem boardItem) async {
  try {
    await firestore.collection('BoardItems').doc(boardItem.key).update(boardItem.toJson());
    print('BoardItem updated successfully');
  } catch (error) {
    print('Failed to update BoardItem: $error');
  }
}

Future<List<BoardItem>> getAllBoardItems() async {
  try {
    QuerySnapshot snapshot = await firestore.collection('BoardItems').get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return BoardItem.fromJson(data);
    }).toList();
  } catch (error) {
    print('Failed to fetch BoardItems: $error');
    return [];
  }
}

Future<void> deleteBoardItem(String boardItemID) async {
  try {
    await firestore.collection('BoardItems').doc(boardItemID).delete();
    print('BoardItem deleted successfully');
  } catch (error) {
    print('Failed to delete BoardItem: $error');
  }
}

Future<BoardItem?> getBoardItem(String uid) async {
  try {
    QuerySnapshot snapshot = await firestore
        .collection('BoardItems')
        .where('uid', isEqualTo: uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return BoardItem.fromJson(data);
    }
  } catch (error) {
    print('Failed to get BoardItem: $error');
  }
  return null;
}


Future<void> addFeedItem(FeedItem feedItem) async {
  try {
    await firestore.collection('FeedItem').add(feedItem.toJson());
    print('FeedItem added successfully');
  } catch (error) {
    print('Failed to add feedItem: $error');
  }
}

Future<void> updateFeedItem(FeedItem feedItem) async {
  try {
    await firestore.collection('FeedItem').doc(feedItem.key).update(feedItem.toJson());
    print('FeedItem updated successfully');
  } catch (error) {
    print('Failed to update feedItem: $error');
  }
}

Future<void> deleteFeedItem(String feedItemId) async {
  try {
    await firestore.collection('FeedItem').doc(feedItemId).delete();
    print('FeedItem deleted successfully');
  } catch (error) {
    print('Failed to delete feedItem: $error');
  }
}

Future<List<FeedItem>> getAllFeedItems() async {
  try {
    QuerySnapshot snapshot = await firestore.collection('FeedItem').get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return FeedItem.fromJson(data);
    }).toList();
  } catch (error) {
    print('Failed to fetch feedItems: $error');
    return [];
  }
}

Stream<List<FeedItem>> streamAllFeedItems() {
  try {
    return firestore.collection('FeedItem').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['key'] = doc.id;
        return FeedItem.fromJson(data);
      }).toList();
    });
  } catch (error) {
    print('Failed to stream feedItems: $error');
    return Stream.value([]);
  }
}


Future<void> addOfficial(Official official) async {
  try {
    await firestore.collection('Official').add(official.toJson());
    print('Official added successfully');
  } catch (error) {
    print('Failed to add official: $error');
  }
}

Future<void> updateOfficial(Official official) async {
  try {
    await firestore.collection('Official').doc(official.key).update(official.toJson());
    print('Official updated successfully');
  } catch (error) {
    print('Failed to update official: $error');
  }
}

Future<void> deleteOfficial(String officialId) async {
  try {
    await firestore.collection('Official').doc(officialId).delete();
    print('Official deleted successfully');
  } catch (error) {
    print('Failed to delete official: $error');
  }
}

Future<List<Official>> getAllOfficials() async {
  try {
    QuerySnapshot snapshot = await firestore.collection('Official').get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return Official.fromJson(data);
    }).toList();
  } catch (error) {
    print('Failed to fetch officials: $error');
    return [];
  }
}

Stream<List<Official>> streamAllOfficials() {
  try {
    return firestore.collection('Official').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['key'] = doc.id;
        return Official.fromJson(data);
      }).toList();
    });
  } catch (error) {
    print('Failed to stream officials: $error');
    return Stream.value([]);
  }
}


Future<void> addFeedback(Feedback feedback) async {
  try {
    await firestore.collection('Feedback').add(feedback.toJson());
    print('Feedback added successfully');
  } catch (error) {
    print('Failed to add feedback: $error');
  }
}

Future<void> updateFeedback(Feedback feedback) async {
  try {
    await firestore.collection('Feedback').doc(feedback.key).update(feedback.toJson());
    print('Feedback updated successfully');
  } catch (error) {
    print('Failed to update feedback: $error');
  }
}

Future<void> deleteFeedback(String feedbackId) async {
  try {
    await firestore.collection('Feedback').doc(feedbackId).delete();
    print('Feedback deleted successfully');
  } catch (error) {
    print('Failed to delete feedback: $error');
  }
}

Future<List<Feedback>> getAllFeedbacks() async {
  try {
    QuerySnapshot snapshot = await firestore.collection('Feedback').get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return Feedback.fromJson(data);
    }).toList();
  } catch (error) {
    print('Failed to fetch feedbacks: $error');
    return [];
  }
}


Stream<List<Feedback>> streamAllFeedbacks() {
  try {
    return firestore.collection('Feedback').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['key'] = doc.id;
        return Feedback.fromJson(data);
      }).toList();
    });
  } catch (error) {
    print('Failed to stream feedbacks: $error');
    return Stream.value([]);
  }
}


