import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../features/notifications/data/notification_providers.dart';

/// App bar notification bell with live unread badge count.
class NotificationIconButton extends ConsumerStatefulWidget {
  final Color iconColor;

  const NotificationIconButton({
    super.key,
    this.iconColor = Colors.white,
  });

  @override
  ConsumerState<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends ConsumerState<NotificationIconButton> {
  @override
  void initState() {
    super.initState();
    NotificationService.refreshTick.addListener(_onRefresh);
  }

  @override
  void dispose() {
    NotificationService.refreshTick.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    ref.invalidate(notificationBadgeCountProvider);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(notificationBadgeCountProvider);
    final count = countAsync.when(
      data: (c) => c,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none_outlined, color: widget.iconColor),
          onPressed: () => context.push('/notifications'),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
