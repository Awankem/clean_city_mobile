import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/notification_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_format_utils.dart';
import '../../../../core/utils/report_status_utils.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/notification_providers.dart';
import '../../../reporting/data/report_providers.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationStorage.markAllSeen();
      await NotificationService.refreshUnreadCount();
      if (mounted) {
        ref.invalidate(storedNotificationsProvider);
        ref.invalidate(appNotificationsProvider);
        ref.invalidate(notificationBadgeCountProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(appNotificationsProvider);
    final activeCountAsync = ref.watch(activeReportsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'CleanCity',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationStorage.markAllSeen();
              await NotificationService.refreshUnreadCount();
              ref.invalidate(storedNotificationsProvider);
              ref.invalidate(appNotificationsProvider);
              ref.invalidate(notificationBadgeCountProvider);
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(myReportsProvider);
            ref.invalidate(storedNotificationsProvider);
            ref.invalidate(appNotificationsProvider);
            ref.invalidate(notificationBadgeCountProvider);
            await ref.read(appNotificationsProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Civic Clarity',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Notification Center',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Status updates on your environmental and infrastructure reports.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurface.withOpacity(0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                activeCountAsync.when(
                  data: (count) => _buildProgressBanner(count),
                  loading: () => _buildProgressBanner(0),
                  error: (_, __) => _buildProgressBanner(0),
                ),
                const SizedBox(height: 12),
                if (notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.notifications_none_outlined,
                              size: 48, color: AppColors.onSurface.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              color: AppColors.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You will be notified when an admin updates your report status.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurface.withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...notifications.map((n) => _NotificationTile(
                        item: n,
                        onTap: () async {
                          if (!n.read && n.fromPush) {
                            await NotificationStorage.markRead(n.id);
                            await NotificationService.refreshUnreadCount();
                            ref.invalidate(storedNotificationsProvider);
                            ref.invalidate(notificationBadgeCountProvider);
                          }
                          if (n.reportId != null && context.mounted) {
                            context.push('/report-detail/${n.reportId}');
                          }
                        },
                      )),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBanner(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resolution Progress',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  count == 0
                      ? 'All your reports are resolved or none submitted yet.'
                      : 'You have $count active report${count == 1 ? '' : 's'} being addressed.',
                  style: const TextStyle(fontSize: 12, color: AppColors.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconColor = ReportStatusUtils.badgeBackground(item.status);
    final timeLabel = _formatTime(item.time);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.read ? Colors.white : AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: item.read
              ? null
              : Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    ReportStatusUtils.icon(item.status),
                    color: ReportStatusUtils.color(item.status) == Colors.white
                        ? iconColor
                        : ReportStatusUtils.color(item.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurface.withOpacity(0.45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge(status: item.status, compact: true),
                if (item.reportId != null)
                  Text(
                    ReportFormatUtils.reportId(item.reportId!),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.body,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      return DateFormat('HH:mm').format(date);
    }
    if (now.difference(date).inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }
}
