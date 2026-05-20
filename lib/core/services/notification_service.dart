import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'firebase_background.dart';
import 'notification_storage.dart';

typedef NotificationTapCallback = void Function(String? reportId);

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier(0);
  /// Bumps when notifications are saved so badge widgets can rebuild.
  static final ValueNotifier<int> refreshTick = ValueNotifier(0);
  static NotificationTapCallback? onReportTap;

  static void _notifyListChanged() {
    refreshTick.value++;
  }

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    await uploadFcmToken();
    await _refreshUnreadCount();

    _messaging.onTokenRefresh.listen((token) async {
      await _syncTokenWithServer(token);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      await _persistAndNavigate(initial, fromTap: true);
    }
  }

  static Future<void> uploadFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _syncTokenWithServer(token);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  static Future<void> _syncTokenWithServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null) return;

      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ));

      await dio.post(ApiConstants.updateFcmToken, data: {'fcm_token': token});
    } catch (e) {
      debugPrint('Failed to sync FCM token: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await NotificationStorage.saveFromMessage(message);
    await _refreshUnreadCount();

    final title = message.notification?.title ?? 'Report update';
    final body = message.notification?.body ?? '';

    showSimpleNotification(
      Text(title),
      subtitle: Text(body),
      background: const Color(0xFF00482F),
      duration: const Duration(seconds: 4),
      leading: const Icon(Icons.notifications_active, color: Colors.white),
    );
  }

  static void _handleMessageOpened(RemoteMessage message) {
    _persistAndNavigate(message, fromTap: true);
  }

  static Future<void> _persistAndNavigate(RemoteMessage message, {bool fromTap = false}) async {
    await NotificationStorage.saveFromMessage(message);
    await _refreshUnreadCount();
    final reportId = message.data['report_id']?.toString();
    if (fromTap && reportId != null) {
      onReportTap?.call(reportId);
    }
  }

  static Future<void> _refreshUnreadCount() async {
    unreadCountNotifier.value = await NotificationStorage.unreadCount();
    _notifyListChanged();
  }

  static Future<void> refreshUnreadCount() => _refreshUnreadCount();
}
