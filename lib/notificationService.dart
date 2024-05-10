import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';


class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final Map<String, List<Map<String, dynamic>>> _queuedNotifications = {};
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> configureFirebaseMessaging(BuildContext context) async {
    print('Configuring Firebase Messaging...');

    // Listen for changes in the 'notifications' collection
    _firestore.collection('notifications').snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          final notificationData = change.doc.data();
          print('Received new notification: $notificationData');
          _showNotificationIfConnected(notificationData!);
        }
      });
    });

    // Check for queued notifications when the user logs in
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        print('User logged in. Sending queued notifications if any.');
        _sendQueuedNotifications(user.uid);
      }
    });

    // Set up callback for when notification is tapped
    _flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher'),
      ),
      // Handle notification tap when app is in the background
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('Notification tapped with payload: ${response.payload}');
        // Redirect to NotifsScreen when notification is tapped
        navigatorKey.currentState?.pushNamed('/notif');
      },
    );

    print('Firebase Messaging configured.');
  }

  Future<void> _showNotificationIfConnected(Map<String, dynamic> notificationData) async {
    print('Checking if notification should be shown: $notificationData');
    if (_auth.currentUser == null) {
      print('User not logged in. Queuing notification.');
      _queueNotification(notificationData);
    } else {
      if (_isCurrentUserNotification(notificationData)) {
        print('User logged in. Showing notification.');

        if (!notificationData['sent']) {
          _processNotification(notificationData);
          // Update the 'sent' field in the database using notif_id
          DocumentReference docRef = _firestore.collection('notifications').doc(notificationData['notif_id']);
          DocumentSnapshot snapshot = await docRef.get();

          if (snapshot.exists) {
            await docRef.update({'sent': true});
          } else {
            print('Document with notif_id ${notificationData['notif_id']} not found.');
            // Handle the case where the document is not found
          }
        } else {
          print('Notification already sent: $notificationData');
        }
      } else {
        print('Notification does not match current user. Ignoring.');
      }
    }
  }


  bool _isCurrentUserNotification(Map<String, dynamic> notificationData) {
    final currentUser = _auth.currentUser;
    return currentUser != null && notificationData['userUID'] == currentUser.uid;
  }

  void _processNotification(Map<String, dynamic> notificationData) {
    String title = notificationData['type'] == 'correct_route' ? 'Route completed Successfully' : 'Route Divergence Detected';
    Timestamp timestamp = notificationData['timestamp'];
    String body = DateFormat('yyyy-MM-dd – kk:mm').format(timestamp.toDate());

    print('Processing notification: $notificationData');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'route_notifs', // Replace with your channel ID
      'eco_route', // Replace with your channel name
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: 'ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _queueNotification(Map<String, dynamic> notificationData) async {
    final userUID = notificationData['userUID'];
    if (!_queuedNotifications.containsKey(userUID)) {
      _queuedNotifications[userUID] = [];
    }

    // Check if the notification is already queued
    bool isAlreadyQueued = _queuedNotifications[userUID]!.any((n) =>
    n['notif_id'] == notificationData['notif_id']);

    if (!isAlreadyQueued && !notificationData['sent']) {
      _queuedNotifications[userUID]!.add(notificationData);
      print('Notification queued: $notificationData');
    } else {
      print('Notification already queued or sent: $notificationData');
    }
  }

  Future<void> _sendQueuedNotifications(String userUID) async {
    if (_queuedNotifications.containsKey(userUID)) {
      final queuedNotifications =
      List<Map<String, dynamic>>.from(_queuedNotifications[userUID]!);
      for (var notificationData in queuedNotifications) {
        if (!notificationData['sent']) {
          print('Sending queued notification: $notificationData');
          _processNotification(notificationData);

          // Update the 'sent' field in the database
          await _firestore.collection('notifications').doc(notificationData['notif_id']).update({'sent': true});

          _queuedNotifications[userUID]!.remove(notificationData);
        }
      }
      print('All queued notifications sent.');
    } else {
      print('No queued notifications for current user.');
    }
  }


}
