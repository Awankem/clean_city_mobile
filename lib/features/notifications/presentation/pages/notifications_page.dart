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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: AppColors.onSurface,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await NotificationStorage.markAllSeen();
                      await NotificationService.refreshUnreadCount();
                      ref.invalidate(storedNotificationsProvider);
                      ref.invalidate(appNotificationsProvider);
                      ref.invalidate(notificationBadgeCountProvider);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: notificationsAsync.when(
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
                        const SizedBox(height: 8),

                        // Progress banner
                        activeCountAsync.when(
                          data: (count) => _buildProgressBanner(count),
                          loading: () => _buildProgressBanner(0),
                          error: (_, _) => _buildProgressBanner(0),
                        ),

                        const SizedBox(height: 20),

                        if (notifications.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 60,
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_none_outlined,
                                      size: 32,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No notifications yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'You\'ll be notified when an admin updates your report status.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.outline,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Text(
                              '${notifications.length} notification${notifications.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.outline,
                              ),
                            ),
                          ),
                          ...notifications.map(
                            (n) => _NotificationTile(
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
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBanner(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resolution Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 0
                      ? 'All your reports are resolved or none submitted yet.'
                      : 'You have $count active report${count == 1 ? '' : 's'} being addressed.',
                  style: const TextStyle(fontSize: 12, color: AppColors.outline, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification Tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusIconColor = ReportStatusUtils.color(item.status) == Colors.white
        ? ReportStatusUtils.badgeBackground(item.status)
        : ReportStatusUtils.color(item.status);
    final timeLabel = _formatTime(item.time);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.read
                ? AppColors.surfaceContainerHigh
                : AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ReportStatusUtils.badgeBackground(item.status),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                ReportStatusUtils.icon(item.status),
                color: statusIconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.read ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Body
                  Text(
                    item.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.outline,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Chips row
                  Row(
                    children: [
                      StatusBadge(status: item.status, compact: true),
                      if (item.reportId != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ReportFormatUtils.reportId(item.reportId!),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (!item.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
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
