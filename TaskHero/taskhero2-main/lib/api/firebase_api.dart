import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    // navigatorKey.currentState?.pushNamed(
    //--NotificationScreen.route,
    // --arguments: message,
    // );
  }

  Future initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        ); //ios?????/
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onMessage.listen((message) {
      print("Foreground message received");
      print(message.notification?.title);
    });
  }

  Future<void> initNotification(String userId, String table) async {
    await _firebaseMessaging.requestPermission();

    final token = await _firebaseMessaging.getToken();
    print("TOKEN: $token");

    if (token != null) {
      await supabase
          .from(table)
          .update({'fcm_token': token})
          .eq(table == 'child' ? 'child_id' : 'parent_id', userId);
    }

    initPushNotifications();
  }
}
