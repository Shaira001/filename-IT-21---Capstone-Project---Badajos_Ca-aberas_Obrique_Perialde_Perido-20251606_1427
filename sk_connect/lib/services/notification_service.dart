// lib/auth_helper.dart (o kung nasaan man ang iyong PushNotifications class)

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:sk_connect/main.dart'; // Para ma-access ang navigatorKey
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth - ESSENTIAL FOR isUserLoggedIn()
import 'package:firebase_core/firebase_core.dart'; // Idagdag ito para sa _firebaseMessagingBackgroundHandler

class PushNotifications {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Reference sa Firestore instance
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Reference sa Firebase Auth instance - ITO ANG SUSI
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- BAGONG METHOD NA IDAGDAG ---
  static bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
  // --- KATAPUSAN NG BAGONG METHOD ---

  // Static method para sa background notification response handling
  @pragma('vm:entry-point')
  static void _onDidReceiveBackgroundNotificationResponse(NotificationResponse response) async {
    print('Background local notification tapped via static handler: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final Map<String, dynamic> dataFromPayload = jsonDecode(response.payload!);
        final String? notificationTitle = dataFromPayload['title'];
        final String? notificationBody = dataFromPayload['body'];

        // Mag-navigate lamang kung naka-log in ang user
        if (isUserLoggedIn()) { // Gamitin ang bagong-define na method
          final RemoteMessage dummyMessage = RemoteMessage(
            data: dataFromPayload,
            notification: notificationTitle != null && notificationBody != null
                ? RemoteNotification(title: notificationTitle, body: notificationBody)
                : null,
          );
          if (navigatorKey.currentState?.context != null) {
            navigatorKey.currentState!.pushNamed("/inbox", arguments: dummyMessage);
          } else {
            print('Warning: Navigator context not available for background local notification navigation.');
          }
        } else {
          print("Background local notification tapped, but user is logged out. Ignoring navigation.");
        }
      } catch (e) {
        print('Error decoding background local notification payload: $e');
      }
    }
  }

  /// I-save o i-update ang FCM token sa Firestore para sa kasalukuyang naka-log in na user.
  ///
  /// Kung walang user na naka-log in o walang token, walang mangyayari.
  static Future<void> saveTokenToFirestore() async {
    final User? user = _auth.currentUser; // Kumuha ng kasalukuyang naka-authenticate na user
    if (user == null) {
      print('Walang user na naka-log in. Hindi maaaring i-save ang FCM token sa Firestore.');
      return;
    }

    String? fcmToken = await _firebaseMessaging.getToken();

    if (fcmToken == null) {
      print('Ang FCM Token ay null. Hindi maaaring i-save sa Firestore.');
      return;
    }

    print('Sinusubukang i-save ang FCM Token: $fcmToken para sa User UID: ${user.uid}');

    try {
      DocumentReference userDocRef = _firestore.collection('users').doc(user.uid);

      await userDocRef.set({
        'fcmToken': fcmToken,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Gagamitin ang merge: true para lang i-update ang fcmToken at lastActive

      print('Matagumpay na na-save/na-update ang FCM Token sa Firestore para sa UID: ${user.uid}');
    } catch (e, stackTrace) { // Idagdag ang stackTrace para sa mas detalyadong logs
      print('Error sa pag-save ng FCM Token sa Firestore: $e');
      print('Stack Trace: $stackTrace');
    }
  }

  /// Tanggalin ang FCM token mula sa Firestore para sa kasalukuyang naka-log in na user.
  ///
  /// Ito ay dapat tawagin kapag nag-log out ang user.
  static Future<void> removeTokenFromFirestore() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      print('Walang user na naka-log in. Walang token na tatanggalin.');
      return;
    }

    print('Sinusubukang tanggalin ang FCM Token para sa User UID: ${user.uid}');

    try {
      DocumentReference userDocRef = _firestore.collection('users').doc(user.uid);

      // Tanggalin lang ang 'fcmToken' field, hindi ang buong dokumento
      await userDocRef.update({
        'fcmToken': FieldValue.delete(),
      });

      print('Matagumpay na natanggal ang FCM Token mula sa Firestore para sa UID: ${user.uid}');
    } catch (e, stackTrace) { // Idagdag ang stackTrace
      if (e is FirebaseException && e.code == 'not-found') {
        print('Hindi nahanap ang dokumento ng user para sa UID: ${user.uid}. Wala na ang token o hindi naimbak.');
      } else {
        print('Error sa pagtanggal ng FCM Token mula sa Firestore: $e');
        print('Stack Trace: $stackTrace');
      }
    }
  }

  /// Makinig sa mga pagbabago ng token at i-update ang Firestore.
  ///
  /// Tinitiyak nito na palaging up-to-date ang token sa Firestore
  /// hangga't naka-log in ang user.
  static void listenForTokenChanges() {
    _firebaseMessaging.onTokenRefresh.listen((fcmToken) {
      print('FCM Token refreshed: $fcmToken');
      // I-save lamang kung naka-log in ang user (upang maiwasan ang pag-save ng mga token para sa mga naka-log out na user)
      if (isUserLoggedIn()) { // Gamitin ang bagong-define na method
        saveTokenToFirestore();
      } else {
        print("Nag-refresh ang token ngunit naka-log out ang user. Hindi ini-save sa Firestore.");
      }
    }).onError((error, stackTrace) { // Idagdag ang stackTrace dito
      print('Error sa pakikinig sa token refresh: $error');
      print('Stack Trace: $stackTrace');
    });
  }

  /// I-initialize ang mga push notification.
  ///
  /// Hinihingi ang mga pahintulot sa notification at nagsisimula ng listener
  /// para sa mga pagbabago ng token.
  static Future<void> init() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Initial token save: Try to save the token immediately if a user is already logged in
    if (isUserLoggedIn()) {
      print('User already logged in during init. Attempting to save FCM token.');
      await saveTokenToFirestore();
    }


    // Sa ngayon, makinig sa mga pagbabago ng token na magche-check ng login status.
    listenForTokenChanges(); // Ito ay magti-trigger ng saveTokenToFirestore kung naka-log in
  }

  /// I-initialize ang local notifications (para sa mobile).
  static Future<void> localNotiInit() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        print('iOS foreground notification (legacy): $title, $body, $payload');
      },
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          debugPrint('notification payload: ${response.payload}');
          try {
            final Map<String, dynamic> dataFromPayload = jsonDecode(response.payload!);
            final String? notificationTitle = dataFromPayload['title'];
            final String? notificationBody = dataFromPayload['body'];

            // Mag-navigate lamang kung naka-log in ang user
            if (isUserLoggedIn()) { // Gamitin ang bagong-define na method
              if (navigatorKey.currentState?.context != null) {
                final RemoteMessage dummyMessage = RemoteMessage(
                  data: dataFromPayload,
                  notification: notificationTitle != null && notificationBody != null
                      ? RemoteNotification(title: notificationTitle, body: notificationBody)
                      : null,
                );
                navigatorKey.currentState!.pushNamed("/inbox", arguments: dummyMessage);
              } else {
                print('Error: navigatorKey.currentState?.context is null. Hindi maaaring mag-navigate mula sa local notification.');
              }
            } else {
              print("Local notification tapped, but user is logged out. Ignoring navigation.");
            }
          } catch (e, stackTrace) { // Idagdag ang stackTrace
            print('Error decoding notification payload or navigating: $e');
            print('Stack Trace: $stackTrace');
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Magpakita ng simpleng local notification.
  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    // Magpakita lamang ng local notification kung naka-log in ang user
    if (!isUserLoggedIn()) { // Gamitin ang bagong-define na method
      print("Sinubukang magpakita ng local notification, ngunit naka-log out ang user. Hindi ipapakita.");
      return;
    }

    Map<String, dynamic> combinedPayloadData;
    try {
      combinedPayloadData = jsonDecode(payload);
    } catch (e) {
      combinedPayloadData = {};
      print('Warning: Ang orihinal na payload ay hindi valid na JSON: $e');
    }

    combinedPayloadData['title'] = title;
    combinedPayloadData['body'] = body;

    final String finalPayload = jsonEncode(combinedPayloadData);

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'your_channel_id',
      'Your Channel Name',
      channelDescription: 'Description for your notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: finalPayload,
    );
  }
}

// Top-level function for handling background Firebase messages.
// This must be defined as a top-level function (outside any class).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Make sure Firebase is initialized in the background context
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');

  // You can show a local notification from here if desired
  // PushNotifications.showSimpleNotification(
  //   title: message.notification?.title ?? 'Background Message',
  //   body: message.notification?.body ?? 'You received a background message.',
  //   payload: jsonEncode(message.data),
  // );
}