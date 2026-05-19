import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

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
      
      // 2. Get Token & Sync (if logged in)
      await uploadFcmToken();

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

  static Future<void> uploadFcmToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print("FCM Token: $token");
        await _syncTokenWithServer(token);
      }
    } catch (e) {
      print("Failed to get FCM token: $e");
    }
  }

  static Future<void> _syncTokenWithServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null) {
        print("FCM Sync: No auth token found, will sync upon user login.");
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ));

      final response = await dio.post('/user/update-token', data: {
        'fcm_token': token,
      });

      if (response.statusCode == 200) {
        print("FCM Token successfully synced with backend.");
      } else {
        print("FCM Sync non-200 response: ${response.statusCode}");
      }
    } catch (e) {
      print("Failed to sync FCM Token with server: $e");
    }
  }
}
