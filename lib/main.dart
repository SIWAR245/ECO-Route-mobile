import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'notificationService.dart';
import 'Screens/Home/home_screen.dart';
import 'Screens/Notifications/Notifs.dart';
import 'Screens/Welcome/welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final NotificationService notificationService = NotificationService();

  runApp(MyApp(
    notificationService: notificationService,
  ));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  const MyApp({Key? key, required this.notificationService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    notificationService.configureFirebaseMessaging(context);

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      routes: {
        '/home': (context) => const HomeScreen(),
        '/notif': (context) => const NotifsScreen(),
      },
      debugShowCheckedModeBanner: false,
      home:  WelcomeScreen(),
    );
  }
}
