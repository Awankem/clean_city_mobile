import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // 2. Get Token
      String? token = await _messaging.getToken();
      if (token != null) {
        print("FCM Token: $token");
        // Sync token with server (Simplified example - in a real app, you'd get the auth token from storage)
        // await _syncTokenWithServer(token);
      }

      // 3. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        
        if (message.notification != null) {
          showSimpleNotification(
            Text(message.notification!.title ?? "Update"),
            subtitle: Text(message.notification!.body ?? ""),
            background: const Color(0xFF00482F),
            duration: const Duration(seconds: 4),
            leading: const Icon(Icons.notifications_active, color: Colors.white),
          );
        }
      });
    }
  }
}
