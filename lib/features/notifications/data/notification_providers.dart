import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_storage.dart';
import '../../reporting/data/report_providers.dart';
class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String status;
  final String? reportId;
  final DateTime time;
  final bool fromPush;
  final bool read;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    this.reportId,
    required this.time,
    this.fromPush = false,
    this.read = true,
  });
}

final storedNotificationsProvider = FutureProvider<List<StoredNotification>>((ref) async {
  return NotificationStorage.loadAll();
});

/// Merges push notifications with status history from the user's reports.
final appNotificationsProvider = FutureProvider<List<AppNotificationItem>>((ref) async {
  final stored = await ref.watch(storedNotificationsProvider.future);
  final myReports = await ref.watch(myReportsProvider.future);
  final lastSeen = await NotificationStorage.getLastSeenAt();

  final items = <AppNotificationItem>[];

  for (final n in stored) {
    items.add(AppNotificationItem(
      id: n.id,
      title: n.title,
      body: n.body,
      status: n.newStatus ?? 'update',
      reportId: n.reportId,
      time: n.receivedAt,
      fromPush: true,
      read: n.read,
    ));
  }

  for (final report in myReports) {
    for (final history in report.statusHistory) {
      final note = history.note ?? '';
      final isInitialSubmit = note.toLowerCase().contains('submitted');
      final isUnread = !isInitialSubmit && history.createdAt.isAfter(lastSeen);

      items.add(AppNotificationItem(
        id: 'history_${report.id}_${history.createdAt.millisecondsSinceEpoch}',
        title: 'Status update · ${report.category}',
        body: note.isNotEmpty
            ? note
            : 'Your report status changed to ${history.status.replaceAll('_', ' ')}.',
        status: history.status,
        reportId: report.id,
        time: history.createdAt,
        fromPush: false,
        read: !isUnread,
      ));
    }
  }

  items.sort((a, b) => b.time.compareTo(a.time));

  final seen = <String>{};
  return items.where((item) {
    final key = '${item.reportId}_${item.status}_${item.time.millisecondsSinceEpoch ~/ 60000}';
    if (seen.contains(key)) return false;
    seen.add(key);
    return true;
  }).toList();
});

/// Unread count for the notification bell badge.
final notificationBadgeCountProvider = FutureProvider<int>((ref) async {
  final items = await ref.watch(appNotificationsProvider.future);
  return items.where((n) => !n.read).length;
});

final activeReportsCountProvider = FutureProvider<int>((ref) async {
  final reports = await ref.watch(myReportsProvider.future);
  return reports.where((r) => r.status.toLowerCase() != 'resolved').length;
});
