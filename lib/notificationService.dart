import 'dart:async';
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
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  final Map<String, int> _municipalityHighFillCount = {};
  final Map<String, int> _municipalityFallenBinsCount = {};
  final Map<String, DateTime> _lastNotificationTimestamps = {};
  final Map<String, DateTime> _lastFallenBinNotificationTimestamps = {};
  static const int _minimumNotificationInterval = 2;

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
        navigatorKey.currentState?.pushNamed('/notif');
      },
    );

    _firestore.collection('bins').snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          _updateHighFillCount(change.doc);
          _checkAndSendNotifications();
        }
      });
    });

    _firestore.collection('bins').snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          _updateFallenBinsCount(change.doc);
          _checkAndSendFallenBinNotifications();
        }
      });
    });

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
          DocumentReference docRef = _firestore
              .collection('notifications')
              .doc(notificationData['notif_id']);
          DocumentSnapshot snapshot = await docRef.get();

          if (snapshot.exists) {
            await docRef.update({'sent': true});
          } else {
            print(
                'Document with notif_id ${notificationData['notif_id']} not found.');
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
    return currentUser != null &&
        notificationData['userUID'] == currentUser.uid;
  }

  void _processNotification(Map<String, dynamic> notificationData) {
    String title;

    print('Processing notification: $notificationData');

    switch (notificationData['type']) {
      case 'correct_route':
        title = 'Route completed Successfully !';
        break;
      case 'wrong_route':
        title = 'Route Divergence Detected !';
        break;
      case 'route_ready':
        title = 'Route is ready for collection !';
        break;
      case 'bin_fallen':
        title = 'Tilt movement detected !';
        break;
      default:
        title = 'no type';
        break;
    }
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
          await _firestore
              .collection('notifications')
              .doc(notificationData['notif_id'])
              .update({'sent': true});

          _queuedNotifications[userUID]!.remove(notificationData);
        }
      }
      print('All queued notifications sent.');
    } else {
      print('No queued notifications for current user.');
    }
  }

  void _updateHighFillCount(DocumentSnapshot binDoc) {
    final municipality = binDoc['municipality'];
    final fillingLevel = binDoc['filling_level'];

    if (fillingLevel > 70) {
      _municipalityHighFillCount[municipality] =
          (_municipalityHighFillCount[municipality] ?? 0) + 1;
    } else {
      _municipalityHighFillCount[municipality] =
          (_municipalityHighFillCount[municipality] ?? 0) - 1;
    }
  }
  void _checkAndSendNotifications() {
    _municipalityHighFillCount.keys.forEach((municipality) {
      final totalBins = _firestore
          .collection('bins')
          .where('municipality', isEqualTo: municipality)
          .get()
          .then((snapshot) => snapshot.size);
      final highFillBins = _municipalityHighFillCount[municipality] ?? 0;

      totalBins.then((value) {
        if (value > 0 && (highFillBins / value) > 0.5) {
          if (_lastNotificationTimestamps.containsKey(municipality)) {
            final timeSinceLastNotification =
            DateTime.now().difference(_lastNotificationTimestamps[municipality]!);
            if (timeSinceLastNotification.inMinutes >=
                _minimumNotificationInterval) {
              _sendNotificationForHighFillingBins(municipality);
              _lastNotificationTimestamps[municipality] = DateTime.now();
            } else {
              print(
                  'Notification already sent for $municipality within the last hour. Skipping.');
            }
          } else {
            _sendNotificationForHighFillingBins(municipality);
            _lastNotificationTimestamps[municipality] = DateTime.now();
          }
        }
      });
    });
  }

  void _updateFallenBinsCount(DocumentSnapshot binDoc) {
    final municipality = binDoc['municipality'];
    final isFallen = binDoc['tilt_status'] == 'fallen'; // Check if tilt_status is 'fallen'


    if (isFallen) {
      _municipalityFallenBinsCount[municipality] =
          (_municipalityFallenBinsCount[municipality] ?? 0) + 1;
    } else {
      _municipalityFallenBinsCount[municipality] =
          (_municipalityFallenBinsCount[municipality] ?? 0) - 1;
    }
  }
  void _checkAndSendFallenBinNotifications() {
    _municipalityFallenBinsCount.keys.forEach((municipality) {
      print('Checking fallen bins for municipality: $municipality');
      _firestore
          .collection('bins')
          .where('municipality', isEqualTo: municipality)
          .where('tilt_status', isEqualTo: 'fallen')
          .get()
          .then((snapshot) {
        print('Found ${snapshot.size} fallen bins for municipality: $municipality');
        snapshot.docs.forEach((binDoc) {
          final binId = binDoc.id;
          if (!_lastFallenBinNotificationTimestamps.containsKey(binId)) {
            print('Sending notification for fallen bin: $binId in municipality: $municipality');
            _sendNotificationForFallenBin(binId, municipality);
            _lastFallenBinNotificationTimestamps[binId] = DateTime.now();
          } else {
            print('Notification already sent for fallen bin: $binId in municipality: $municipality');
          }
        });
      }).catchError((error) {
        print('Error getting fallen bins for municipality: $municipality, Error: $error');
      });
    });
  }

  Future<void> _sendNotificationForFallenBin(String binId, String municipality) async {
    final employeeUID = await _getEmployeeUIDByMunicipality(municipality);
    if (employeeUID != null) {
      await createNotificationDocumentForFallenBin(employeeUID,binId);
    }
  }


  Future<void> _sendNotificationForHighFillingBins(String municipality) async {
    final employeeUID = await _getEmployeeUIDByMunicipality(municipality);
    if (employeeUID != null) {
      await createNotificationDocument(employeeUID);
    }
  }
  Future<String?> _getEmployeeUIDByMunicipality(String municipality) async {
    final QuerySnapshot employeesSnapshot = await _firestore
        .collection('employees')
        .where('municipality', isEqualTo: municipality)
        .get();

    if (employeesSnapshot.docs.isNotEmpty) {
      final employeeData = employeesSnapshot.docs.first.data() as Map<String, dynamic>;
      return employeeData['uid'] as String?; // Assuming 'uid' is the field containing the UID
    }

    return null;
  }
  Future<void> createNotificationDocument(String employeeUID) async {
    final CollectionReference notificationsCollection =
    FirebaseFirestore.instance.collection('notifications');
    final String notif_id = notificationsCollection.doc().id;

    await notificationsCollection.doc(notif_id).set({
      'notif_id': notif_id,
      'type': 'route_ready',
      'sent': false,
      'userUID': employeeUID,
      'timestamp': DateTime.now(),
      'adminRead': false,
      'appRead': false,
    });
  }
  Future<void> createNotificationDocumentForFallenBin(String employeeUID, String binId) async {
    final CollectionReference notificationsCollection =
    FirebaseFirestore.instance.collection('notifications');
    final String notif_id = notificationsCollection.doc().id;

    await notificationsCollection.doc(notif_id).set({
      'notif_id': notif_id,
      'type': 'bin_fallen',
      'sent': false,
      'userUID': employeeUID,
      'binId': binId,
      'timestamp': DateTime.now(),
      'adminRead': false,
      'appRead': false,
    });
  }
}
