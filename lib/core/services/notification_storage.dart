import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoredNotification {
  final String id;
  final String title;
  final String body;
  final String? type;
  final String? reportId;
  final String? newStatus;
  final DateTime receivedAt;
  final bool read;

  StoredNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.reportId,
    this.newStatus,
    required this.receivedAt,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'report_id': reportId,
        'new_status': newStatus,
        'received_at': receivedAt.toIso8601String(),
        'read': read,
      };

  factory StoredNotification.fromJson(Map<String, dynamic> json) {
    return StoredNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Update',
      body: json['body'] as String? ?? '',
      type: json['type'] as String?,
      reportId: json['report_id']?.toString(),
      newStatus: json['new_status'] as String?,
      receivedAt: DateTime.tryParse(json['received_at'] as String? ?? '') ?? DateTime.now(),
      read: json['read'] as bool? ?? false,
    );
  }

  StoredNotification copyWith({bool? read}) => StoredNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        reportId: reportId,
        newStatus: newStatus,
        receivedAt: receivedAt,
        read: read ?? this.read,
      );
}

class NotificationStorage {
  static const _key = 'stored_notifications';
  static const _lastSeenKey = 'notifications_last_seen_at';
  static const _maxItems = 50;

  static Future<DateTime> getLastSeenAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSeenKey);
    return DateTime.tryParse(raw ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static Future<void> markAllSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenKey, DateTime.now().toIso8601String());
    await markAllRead();
  }

  static Future<void> saveFromMessage(RemoteMessage message) async {
    final data = message.data;
    final title = message.notification?.title ?? data['title'] ?? 'CleanCity Update';
    final body = message.notification?.body ?? data['body'] ?? '';

    await save(
      StoredNotification(
        id: '${DateTime.now().millisecondsSinceEpoch}_${data['report_id'] ?? ''}',
        title: title,
        body: body,
        type: data['type'],
        reportId: data['report_id']?.toString(),
        newStatus: data['new_status'],
        receivedAt: DateTime.now(),
      ),
    );
  }

  static Future<void> save(StoredNotification notification) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAll();
    existing.insert(0, notification);
    final trimmed = existing.take(_maxItems).toList();
    await prefs.setString(_key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  static Future<List<StoredNotification>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => StoredNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<int> unreadCount() async {
    final all = await loadAll();
    return all.where((n) => !n.read).length;
  }

  static Future<void> markRead(String id) async {
    final all = await loadAll();
    final updated = all
        .map((n) => n.id == id ? n.copyWith(read: true) : n)
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(updated.map((e) => e.toJson()).toList()));
  }

  static Future<void> markAllRead() async {
    final all = await loadAll();
    final updated = all.map((n) => n.copyWith(read: true)).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(updated.map((e) => e.toJson()).toList()));
  }
}
