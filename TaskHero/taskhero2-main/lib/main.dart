import 'package:flutter/material.dart';
import 'package:taskhero/child/childLoginPage.dart';
import 'services/conn.dart';
import 'child/child_main.dart';
import 'splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final navigatorKey = GlobalKey<NavigatorState>();
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print("title:${message.notification?.title}");
  print("Body:${message.notification?.body}");
  print("Payload:${message.data}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //runs on both mobile and chrome
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initSupabase();
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: SplashScreen(),
    );
  }
}
